#!/bin/bash
#
#
#   This program is free software: you can redistribute it and/or modify
#   it under the terms of the GNU General Public License as published by
#   the Free Software Foundation, either version 3 of the License, or
#   (at your option) any later version.
#
#   This program is distributed in the hope that it will be useful,
#   but WITHOUT ANY WARRANTY; without even the implied warranty of
#   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#   GNU General Public License for more details.
#
#   You should have received a copy of the GNU General Public License
#   along with this program.  If not, see <http://www.gnu.org/licenses/>.
#

echo -e "***********************************************************************"
echo -e "* \e[31mWARNING:\e[0m                                                            *"
echo -e "* This program will try to install automatically Decidim and all      *"
echo -e "* related software. This includes Nginx, Passenger, Ruby and others.  *"
echo -e "* \e[33mUSE IT ONLY IN A FRESHLY INSTALLED UBUNTU 18.04 or 20.04 SYSTEM\e[0m         *"
echo -e "* No guarantee whatsoever that it won't break your system!            *"
echo -e "*                                                                     *"
echo -e "* (c) Ivan Vergés <ivan (at) platoniq.net>                            *"
echo -e "* https://github.com/Platoniq/decidim-install                         *"
echo -e "*                                                                     *"
echo -e "***********************************************************************"

########################################################
# Config vars & default values (use -h to view options)
########################################################

RUBY_VERSION="2.7.4"
DECIDIM_VERSION="0.26"
BUNDLER_VERSION="2.2.18"
RAILS_VERSION="6.0.4"
VERBOSE=
CONFIRM=1
STEPS=("check" "prepare" "rbenv" "gems" "decidim" "postgres" "create" "servers")
# default environment to be configured
ENVIRONMENT="production"

###################
# Function library
###################

# exit on fail (trap on some cases applies)
set -e

info() {
	echo -e "$1"
}

yellow() {
	echo -e "\e[33m$1\e[0m"
}

green() {
	echo -e "\e[32m$1\e[0m"
}

red() {
	echo -e "\e[31m$1\e[0m"
}

exit_help() {
	info "\nUsage:"
	info " $0 [OPTIONS] [FOLDER]\n"
	info "Installs Decidim into FOLDER and all necessary dependencies in Ubuntu 18.04\n"
	info "This script tries to be idempotent meaning that it can be run repeatedly"
	info "without breaking things or changing values in already configured steps\n"
	info "OPTIONS:"
	info " -h          Show this help"
	info " -f          Do not ask for confirmation to run the script"
	info " -v          Be verbose (when possible)"
	info " -r [ver]    Specify ruby version (default is $RUBY_VERSION)"
	info " -e [env]    Specify rails environment (default is $ENVIRONMENT)"
	info " -s [step]   Skip the step specified. Multiple steps can be"
	info "             specified with several -s options"
	info " -o [step]   Execute only the step specified. Multiple steps can be"
	info "             specified with several -o options"
	info " -u [email]  Specify Decidim system admin email"
	info " -p [pass]   Specify Decidim system admin password"
	info " -c          Install in Capistrano mode. releases and current will be used as suffix for the specified directory"
	info "\nValid steps are (in order of execution):"
	info " check     Checks if we are using Ubuntu 18.04"
	info " prepare   Updates system, configure timezone"
	info " rbenv     Installs ruby through rbenv"
	info " gems      Installs Ruby gems bundler and decidim"
	info " decidim   Installs Decidim into FOLDER and generates database credentials if necessary"
	info " postgres  Installs PostgreSQL and creates the user using the generated credentials"
	info " create    Creates the database and the first system admin user"
	info " servers   Configures Nginx, Passenger and ActiveJob"
	trap - EXIT
	exit
}

# Disables traps and exits immediately
# Used to trap INT and TERM signals
abort() {
	red "Aborted by the user!"
	trap - EXIT
	exit
}

# Checks the last command result on exit
# Used to trap the EXIT signal of this script
cleanup() {
	rv=$?
	if [ "$rv" -ne 0 ]; then
		red "Something went wrong! Aborting!"
		exit $rv
	else
		green "Finished successfully!"
	fi
}

step_check() {
	green "Checking current system..."
	if [ "$EUID" -eq 0 ]; then
		red "Please do not run this script as root"
		info "User a normal user with sudo permissions"
		info "sudo password will be asked when necessary"
		exit 1
	fi
	if [ $(awk -F= '/^ID=/{print $2}' /etc/os-release) != "ubuntu" ]; then
		red "Not an ubuntu system!"
		cat /etc/os-release
		exit 1
	fi
	version=$(awk -F= '/^VERSION_ID=/{print $2}' /etc/os-release)
	if [ "$version" != '"18.04"' ] && [ "$version" != '"20.04"' ]; then
		red "Only Ubuntu 18.04 or 20.04 are supported!"
		awk -F= '/^VERSION_ID=/{print $2}' /etc/os-release
		exit 1
	fi
	# TODO: check for system memory
}

step_prepare() {
	green "Updating system"
	sudo apt-get update
	sudo apt-get -y upgrade
	sudo apt-get -y autoremove
	green "Configuring timezone"
	sudo dpkg-reconfigure tzdata
	green "Installing necessary software"
	sudo apt-get -y install autoconf bison build-essential libssl-dev libyaml-dev \
		 libreadline6-dev zlib1g-dev libncurses5-dev libffi-dev libgdbm-dev
}

init_rbenv() {
	export PATH="$HOME/.rbenv/bin:$PATH"
	eval "$(rbenv init -)"
}

cd_folder(){
	if [ -z "$FOLDER" ]; then
		yellow "Please specify a folder to install Decidim"
		info "Runt $0 with -h to view options for this script"
		exit 0
	fi

	if [ -z "$CAPISTRANO" ]; then
		INSTALL_FOLDER=$FULLFOLDER
	else
		INSTALL_FOLDER=$FULLFOLDER/current
	fi

	if [ -d "$INSTALL_FOLDER" ]; then
		green "changing to working folder [$INSTALL_FOLDER] from [$PWD]"
		cd $INSTALL_FOLDER
	else
		red "Couldn't change to working folder! [$INSTALL_FOLDER]"
	fi
}

step_rbenv() {
	# pause EXIT trap
	trap - EXIT

	info "Installing rbenv"

	if [ -d "$HOME/.rbenv" ]; then
		yellow "$HOME/.rbenv already exists!"
	else
		info "Installing rbenv from GIT source"
		git clone https://github.com/rbenv/rbenv.git $HOME/.rbenv
	fi

	if grep -Fxq 'export PATH="$HOME/.rbenv/bin:$PATH"' "$HOME/.bashrc" ; then
		yellow "$HOME/.rbenv/bin already in PATH"
	else
		info "Installing $HOME/.rbenv/bin in PATH"
		echo 'export PATH="$HOME/.rbenv/bin:$PATH"' >> "$HOME/.bashrc"
	fi

	if grep -Fxq 'eval "$(rbenv init -)"' "$HOME/.bashrc" ; then
		yellow "rbenv init already in bashrc"
	else
		info "Installing rbenv init in bashrc"
		echo 'eval "$(rbenv init -)"' >> "$HOME/.bashrc"
	fi

	init_rbenv

	if rbenv version; then
		green "rbenv successfully installed"
	else
		red "Something went wrong installing rbenv."
		red "rbenv does not appear to be a bash function"
		info "You might want to perform this step manually"
		type rbenv
		exit 1
	fi

	# resume EXIT trap
	trap cleanup EXIT

	if [ -d "$HOME/.rbenv/plugins/ruby-build" ]; then
		yellow "$HOME/.rbenv/plugins/ruby-build already exists!"
	else
		info "Installing ruby-build from GIT source"
		git clone https://github.com/rbenv/ruby-build.git $HOME/.rbenv/plugins/ruby-build
	fi

	if rbenv install -l | grep -Fq "$RUBY_VERSION"; then
		green "Ruby $RUBY_VERSION rbenv available for installation"
	fi

	if [ $(rbenv global) == "$RUBY_VERSION" ]; then
		yellow "Ruby $RUBY_VERSION already installed"
	else
		info "Installing ruby $RUBY_VERSION, please be patient, it's going to be a while..."
		rbenv install "$RUBY_VERSION" -f $VERBOSE
		rbenv global "$RUBY_VERSION"
	fi

	if [[ $(ruby -v) == "ruby $RUBY_VERSION"* ]]; then
		green "$(ruby -v) installed successfully"
		info "It is recommended to logout and login again to activate .bashrc"
	fi
}

step_gems() {
	info "installing Yarn"
	curl -sS https://dl.yarnpkg.com/debian/pubkey.gpg | sudo apt-key add -
	echo "deb https://dl.yarnpkg.com/debian/ stable main" | sudo tee /etc/apt/sources.list.d/yarn.list
	sudo apt update
	sudo apt install --no-install-recommends yarn

	info "installing Node 16"
	curl -sL https://deb.nodesource.com/setup_16.x -o setup_16.sh
	chmod +x setup_16.sh
	sudo ./setup_16.sh

	info "Installing generator dependencies"
	sudo apt-get install -y nodejs imagemagick libpq-dev libicu-dev
	whereis node
	node --version
	init_rbenv

	info "Installing bundler"

	if [ -f "$HOME/.gemrc" ] ; then
		yellow "$HOME/.gemrc already created"
	else
		info "Creating $HOME/.gemrc"
		echo "gem: --no-document" > $HOME/.gemrc
	fi

	info "Installing bundler"
	gem install bundler --version $BUNDLER_VERSION

	if [[ $(gem env home) == *".rbenv/versions/$RUBY_VERSION/lib/ruby/gems/"* ]]; then
		green "Gems environment installed successfully"
	else
		red "gem home failed! $(gem env home)!"
		exit 1
	fi
	info "Installing Rails, version $RAILS_VERSION"
	gem install rails --version $RAILS_VERSION

	# Version 0.25 had a bug and do not limit the version o rails to 6.0 in the generator
	# Therefore, if rails 6.1 is installed it will fail
	set +e
	gem list -e rails --versions | grep 6.1 -q
	if [ "$?" -eq 0  ]; then
		red "Rails 6.1 is installed. Please uninstall this version before using this script"
		gem list -e rails
		exit 1
	fi
	set -e

	info "Installing Decidim gem"
	gem install decidim -v $DECIDIM_VERSION
}

FOLDER=
CONF_SECRET=
CONF_DATABASE=
CONF_DB_USER=decidim_app
CONF_DB_PASS=$(head /dev/urandom | tr -dc A-Za-z0-9 | head -c 13 ; echo '')
CONF_DB_HOST=localhost
CONF_DB_NAME=decidim_prod
DECIDIM_EMAIL=
DECIDIM_PASS=
CAPISTRANO=
step_decidim() {
	if [ -z "$FOLDER" ]; then
		yellow "Please specify a folder to install Decidim"
		info "Runt $0 with -h to view options for this script"
		exit 0
	fi

	init_rbenv

	if [ -z "$CAPISTRANO" ]; then
		INSTALL_FOLDER=$FOLDER
	else
		INSTALL_FOLDER=$FOLDER/releases/initial
	fi

	green "Installing Decidim in $INSTALL_FOLDER"
	if [ -d "$INSTALL_FOLDER" ]; then
		yellow "$INSTALL_FOLDER already exists, trying to install gems anyway"
	else
		decidim "$INSTALL_FOLDER"
		sed -i 's/    config.load_defaults 6.1/    config.load_defaults 6.0/' $INSTALL_FOLDER/config/application.rb
	fi

	if [ ! -z "$CAPISTRANO" ]; then
		green "Applying Capistrano enabled modifications..."
		info "Creating Capistrano directories"
		mkdir -p $FOLDER/shared/config
		mkdir -p $FOLDER/shared/log
		mkdir -p $FOLDER/shared/public/uploads
		if [ ! -L "$FOLDER/current" ]; then
			info "Symlink to Capistrano current version"
			ln -s releases/initial $FOLDER/current
		else
			yellow "Capistrano current version already linked"
		fi

		if [ ! -L "$INSTALL_FOLDER/config/application.yml" ]; then
			info "Creating application.yml file and Symlink to shared folder"
			touch "$FOLDER/shared/config/application.yml"
			ln -s $(realpath $FOLDER/shared/config/application.yml) "$INSTALL_FOLDER/config/application.yml"
		else
			yellow "application.yml is already a Symlink"
		fi
		if [ ! -L "$INSTALL_FOLDER/log" ]; then
			info "Moving logs to shared folder and Symlink it"
			mv "$INSTALL_FOLDER/log" "$FOLDER/shared/"
			ln -s $(realpath $FOLDER/shared/log) "$INSTALL_FOLDER/log"
		else
			yellow "log is already a Symlink"
		fi
		if [ ! -L "$INSTALL_FOLDER/public/uploads" ]; then
			info "Moving uploads to shared folder and Symlink it"
			if [ -d "$INSTALL_FOLDER/public/uploads" ]; then
				mv "$INSTALL_FOLDER/public/uploads" "$FOLDER/shared/public/"
			else
				mkdir -p "$INSTALL_FOLDER/public/uploads"
			fi
			ln -s $(realpath $FOLDER/shared/public/uploads) "$INSTALL_FOLDER/public/uploads"
		else
			yellow "uploads is already a Symlink"
		fi
	fi

	cd_folder

	if grep -FA1 'BUNDLED WITH' Gemfile.lock | grep -Fq "1.17.3" ; then
		yellow "Removing current Gemfile.lock file to use a more modern bundler"
		rm -f Gemfile.lock
	fi

	if grep -Fq 'gem "figaro"' Gemfile ; then
		info "Gem figaro already installed"
	else
		bundle add figaro --skip-install
	fi
	if grep -Fq 'gem "passenger"' Gemfile ; then
		info "Gem passenger already installed"
	else
		bundle add passenger --group $ENVIRONMENT --skip-install
	fi
	if grep -Fq 'gem "delayed_job_active_record"' Gemfile ; then
		info "Gem delayed_job_active_record already installed"
	else
		bundle add delayed_job_active_record --group $ENVIRONMENT --skip-install
	fi
	if grep -Fq 'gem "daemons"' Gemfile ; then
		info "Gem daemons already installed"
	else
		bundle add daemons --group $ENVIRONMENT --skip-install
	fi
	if grep -Fq 'gem "whenever"' Gemfile ; then
		info "Gem whenever already installed"
	else
		echo 'gem "whenever", require: false' >> Gemfile
	fi

	if [ ! -z "$CAPISTRANO" ]; then
		if grep -Fq 'gem "capistrano"' Gemfile ; then
			info "Gem capistrano already installed"
		else
			bundle add capistrano --group development --skip-install
			bundle add capistrano-rbenv --group development --skip-install
			bundle add capistrano-bundler --group development --skip-install
			bundle add capistrano-passenger --group development --skip-install
			bundle add capistrano-rails --group development --skip-install
		fi
	fi

	bundle install

	if [ -f "./config/schedule.rb" ]; then
		yellow "config/schedule.rb already present"
	else
	  cat > ./config/schedule.rb <<EOL
env :PATH, ENV['PATH']

every :sunday, at: '5:00 am' do
  rake "decidim:delete_data_portability_files"
end

every :sunday, at: '4:00 am' do
  rake "decidim:open_data:export"
end

every 1.day, at: '3:00 am' do
  rake "decidim:metrics:all"
end
EOL

	fi
	if [ -f "./config/application.yml" ]; then
		yellow "config/application.yml already present"
	else
		green "Creating config/application.yml with automatic values"
		touch ./config/application.yml
	fi

	if grep -Fq '/config/application.yml' ./.gitignore ; then
		yellow "application.yml already in .gitignore"
	else
		green "Adding application.yml to .gitignore"
		echo -e "\n\n# Do not track secrets in GIT" >> ./.gitignore
		echo "/config/application.yml" >> ./.gitignore
	fi

	if ! grep -Fq 'SECRET_KEY_BASE:' ./config/application.yml ; then
		echo "SECRET_KEY_BASE: $(rake secret)" >> ./config/application.yml
	fi
	CONF_SECRET=$(awk '/SECRET_KEY_BASE\:/{print $2}' config/application.yml)

	if ! grep -Fq 'DATABASE_URL:' ./config/application.yml ; then
		echo "DATABASE_URL: postgres://$CONF_DB_USER:$CONF_DB_PASS@$CONF_DB_HOST/$CONF_DB_NAME" >> ./config/application.yml
	fi


	if grep -Fq '# config.force_ssl = true' ./config/initializers/decidim.rb ; then
		red "Disabling SSL by default!!!"
		red "NOTE: you should configure SSL in Nginx and then reenable 'config.force_ssl = true' in the file 'config/initializers/decidim.rb' again"
		yellow "You may follow this instructions for that: https://certbot.eff.org/lets-encrypt/snap-nginx"
		sed -i 's/# config.force_ssl = true/config.force_ssl = false/' ./config/initializers/decidim.rb
	fi
}

get_conf_vars() {
	cd_folder
	init_rbenv

	CONF_DATABASE=$(awk '/DATABASE_URL:/{print $2}' config/application.yml)
	re="postgres\:\/\/(.+):(.+)@(.+)/(.+)"
	if [[ "$CONF_DATABASE" =~ $re ]]; then
		CONF_DB_USER="${BASH_REMATCH[1]}";
		CONF_DB_PASS="${BASH_REMATCH[2]}";
		CONF_DB_HOST="${BASH_REMATCH[3]}";
		CONF_DB_NAME="${BASH_REMATCH[4]}";
	fi

	if [ -z "$CONF_DB_USER" ]; then
		red "Couldn't extract database user from config/application.yml!"
		exit 1
	fi
	if [ -z "$CONF_DB_PASS" ]; then
		red "Couldn't extract database password from config/application.yml!"
		exit 1
	fi
	if [ -z "$CONF_DB_HOST" ]; then
		red "Couldn't extract database host from config/application.yml!"
		exit 1
	fi
	if [ -z "$CONF_DB_NAME" ]; then
		red "Couldn't extract database name from config/application.yml!"
		exit 1
	fi
}

step_postgres() {
	get_conf_vars

	green "Installing PostgreSQL"
	sudo apt-get -y install postgresql
	echo "Starting PostgreSQL"
	sudo systemctl start postgresql.service

	if sudo -u postgres psql -tAc "SELECT 1 FROM pg_roles WHERE rolname='$CONF_DB_USER'" | grep -q 1 ; then
		yellow "User $CONF_DB_USER already exists in postgresql"
	else
		info "Creating user $CONF_DB_USER"
		sudo -u postgres psql -c "CREATE USER $CONF_DB_USER WITH SUPERUSER CREATEDB NOCREATEROLE PASSWORD '$CONF_DB_PASS'"
	fi
}

step_create(){
	get_conf_vars

	green "Database creation and migration"

	bin/rails db:create RAILS_ENV=$ENVIRONMENT
	bin/rails db:migrate RAILS_ENV=$ENVIRONMENT

	info "Ensure yarn is working"
	yarn add rails-ujs
	yarn install

	info "Fixing config/application.rb"
	yellow "This shouldn't be necessary but there was a bug in 0.25 version https://github.com/decidim/decidim/issues/8395"
	if grep -Fq 'action_cable/engine' ./config/application.rb ; then
		yellow "require action_cable already done"
	else
		green "adding require action_cable"
		sed -i 's/require "decidim\/rails"/require "decidim\/rails"\nrequire "action_cable\/engine"/' config/application.rb
	fi
	if grep -Fq 'Rails.autoloaders' ./config/application.rb ; then
		yellow "Autoloaders ignore already done"
	else
		green "adding autoloaders ignore"
		echo 'Rails.autoloaders.main.ignore(Gem::Specification.find_by_name("decidim-core").gem_dir + "/app/packs")' >> config/application.rb
	fi

	if [ "production" == "$ENVIRONMENT" ]; then
		green "Asset compiling in production mode"
		bin/rails assets:precompile RAILS_ENV=$ENVIRONMENT
	else
		yellow "Skipping asset compiling in $ENVIRONMENT mode"
	fi

	local email="$DECIDIM_EMAIL"
	local pass="$DECIDIM_PASS"
	if [ -z "$email" ]; then
		read -p "Introduce your system admin email: " email
		green "Using email [$email]"
	else
		yellow "Using email [$email] from options"
	fi
	if [ -z "$pass" ]; then
		read -p "Introduce your system admin password: " pass
	else
		yellow "Using password from options"
	fi

	info "Checking availability..."
	if $(bin/rails runner -e $ENVIRONMENT "puts Decidim::System::Admin.exists?(email: '$email')") == "true"; then
		yellow "System admin with email [$email] already exists!"
	else
		info "Creating system admin with email [$email]"
		bin/rails runner -e $ENVIRONMENT "Decidim::System::Admin.new(email: '$email', password: '$pass', password_confirmation: '$pass').save!"
	fi
}

step_servers(){
	if [ "production" != "$ENVIRONMENT" ]; then
		red "servers step is only available in production mode"
		exit
	fi
	cd_folder
	init_rbenv

	green "Installing Nginx"
	sudo apt-get -y install nginx

	if [ -f /etc/apt/sources.list.d/passenger.list ]; then
		yellow "Passenger repositories already installed"
	else
		green "Installing Passenger repositories"
		sudo apt-get install -y dirmngr gnupg
		sudo apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv-keys 561F9B9CAC40B2F7
		sudo apt-get install -y apt-transport-https ca-certificates
		sudo sh -c 'echo deb https://oss-binaries.phusionpassenger.com/apt/passenger $(lsb_release -cs) main > /etc/apt/sources.list.d/passenger.list'
		sudo apt-get update
	fi

	green "Installing Passenger"
	sudo apt-get install -y libnginx-mod-http-passenger

	green "Activating Passenger"
	if [ ! -f /etc/nginx/modules-enabled/50-mod-http-passenger.conf ]; then
		sudo ln -s /usr/share/nginx/modules-available/mod-http-passenger.load /etc/nginx/modules-enabled/50-mod-http-passenger.conf
	fi

	green "Validating Installation"
	if ! passenger-config validate-install --auto | grep -Fq $(gem env gemdir); then
		red "Passenger seems is not using gem's folder!"
		passenger-config validate-install --auto
		exit 1
	fi

	if grep -Fq "passenger_ruby $HOME/.rbenv/shims/ruby;" /etc/nginx/conf.d/mod-http-passenger.conf; then
		yellow "Passenger pointing correctly to rbenv environment in /etc/nginx/sites-enabled/decidim.conf"
	else
		green "recreating mod-http-passenger.conf to point to rbenv environment"
		sudo sed -i '/^passenger_ruby/c\passenger_ruby $HOME/.rbenv/shims/ruby;' /etc/nginx/conf.d/mod-http-passenger.conf
	fi

	if [ -x bin/delayed_job ]; then
		yellow "delayed_job binary already installed"
	else
		green "installing delayed_job binary and migrations"
		bin/rails generate delayed_job:active_record
		bin/rake db:migrate
	fi

	if [ -x bin/delayed_job_cron.sh ]; then
		yellow "Delayed job cron script already exists in $FOLDER/bin/"
	else
		green "Creating a job cron script in $FOLDER/bin"
		cat > bin/delayed_job_cron.sh <<EOL
#!/bin/bash

export PATH="\$HOME/.rbenv/bin:\$PATH"
eval "\$(rbenv init -)"
APP_PATH=\$(dirname \$(dirname \$(realpath \$0)))

if ! [ -s \$APP_PATH/tmp/pids/delayed_job.pid ]; then
  RAILS_ENV=production \$APP_PATH/bin/delayed_job start
fi
EOL
		chmod +x bin/delayed_job_cron.sh
	fi

	if crontab -l | grep -Fq "delayed_job_cron.sh"; then
		yellow "delayed_job_cron.sh already in crontab"
	else
		current_crontab=
		if crontab -l; then
			current_crontab=$(crontab -l)
		fi
		green "Adding delayed_job_cron.sh to crontab to ensure it's up"
		($current_crontab && echo "*/5 * * * * $PWD/bin/delayed_job_cron.sh") | crontab -
	fi

	info "Delayed job status..."
	bin/delayed_job_cron.sh
	RAILS_ENV=production bin/delayed_job status

	if [ -z "$CAPISTRANO" ]; then
		info "Updating whenever crontab"
		bundle exec whenever --update-crontab
	else
		yellow "In Capistrano mode, Whenever has not been added to the Crontab"
		yellow "Usually Capistrano does that every release"
		yellow "If you still want to manually add whenever to the crontab just execute:"
		info ""
		info "bundle exec whenever --update-crontab"
		info ""
	fi

	if [ -f /etc/nginx/sites-enabled/decidim.conf ]; then
		yellow "decidim.conf Nginx file already configured in /etc/nginx/sites-enabled/decidim.conf"
	else
		green "Creating decidim.conf Nginx file"
		sudo tee /etc/nginx/sites-enabled/decidim.conf <<EOL
server {
    listen 80 default_server;
    listen [::]:80 ipv6only=on default_server;

    server_name _ default_server;
    client_max_body_size 32M;

    passenger_enabled on;
    passenger_ruby $HOME/.rbenv/shims/ruby;

    rails_env    production;
    root         $PWD/public;
}
EOL
		info "Nginx configuration generated in /etc/nginx/sites-enabled/decidim.conf"

		if [ -f /etc/nginx/sites-enabled/default ]; then
			green "removing default file from sites-enabled"
			sudo rm /etc/nginx/sites-enabled/default
		fi
	fi

	sudo nginx -t
	sudo service nginx restart

	info "Current crontab is:"
	info $(crontab -l)

	if [ ! -z "$CAPISTRANO" ]; then
		yellow "You've installed Decidim in Capistrano mode, you're not done!"
		yellow "You still need to configure your computer locally and add the necessary"
		yellow "Capfile and others in order to deploy using it."
		yellow "You can check the guide at https://platoniq.github.io/decidim-install/advanced-deploy/ for more info"
	fi

	green "Servers installed successfully, you should be able to reach Decidim website in one of these IP addresses:"
	info "$(hostname -I)"
}


SKIP=()
ONLY=()
install() {
	if [[ "${ONLY[@]}" ]]; then
		SKIP=()
		for step in "${STEPS[@]}"; do
			if [[ " ${ONLY[*]} " != *" $step "* ]]; then
				SKIP+=("$step")
			fi
		done
		echo ${SKIP[@]}
	fi
	for i in "${!STEPS[@]}"; do
		step=${STEPS[i]}
		if [[ " ${SKIP[*]} " == *" $step "* ]]; then
			red "Skipping step $i: $step"
		else
			yellow "Step $i: $step "
			"step_$step"
		fi
	done
}

main() {
	trap cleanup EXIT
	trap abort INT TERM
	install
	exit
}

confirm() {
	while true; do
	    read -p "Do you wish to continue? [y/N]" yn
	    case $yn in
	        [Yy]* ) main; break;;
	        [Nn]* ) exit;;
	        * ) abort;;
	    esac
	done
}

while getopts fhr:e:vs:o:u:p:c option; do
	case "${option}" in
		f ) yellow "No asking for confirmation"; CONFIRM=0;;
		h ) exit_help;;
		v ) VERBOSE="-v";;
		r ) RUBY_VERSION="$OPTARG";;
		e ) ENVIRONMENT="$OPTARG";;
		s ) SKIP+=("$OPTARG");;
		o ) ONLY+=("$OPTARG");;
		u ) DECIDIM_EMAIL="$OPTARG";;
		p ) DECIDIM_PASS="$OPTARG";;
		c ) CAPISTRANO=1;;
	esac
done
shift $(($OPTIND - 1))
FOLDER="$1"
FULLFOLDER=$(realpath $FOLDER)

if [ "$CONFIRM" == "1" ]; then
	confirm
else
	main
fi
