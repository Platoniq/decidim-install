---
layout: default
title: Advanced deploy with Capistrano
nav_order: 6
---

Advanced deploy with Capistrano
===============================


In this guide, we've explained how to install Decidim directly in the server. That's fine to start, but in terms of maintainability it is not very scalable.

In here we will use [GIT](https://git-scm.com/) and [Capistrano](https://capistranorb.com/) have a nice record of all our changes in our app. This will allow to make changes and safely revert them in case of need.

This means, that we won't be working on the remote server directly any more, the workflow now will be to do all the changes locally and then execute capistrano to let them do all the work for you:

```ascii
In Your computer:
   change files 👉 commit in GIT 👉 Deploy in Capistrano
In the server:
                                             👇
                                      Upload changes to server
                                      Run migrations
                                             👇
                                      Reload the server to point
                                      the new installation

 ```


### Preparation

We will assume that the current installation is being done either following the [Ubuntu guide](decidim-bionic.md) or using the [automated script](script/README.md).

If your case is a little different, you'll need to adapt some of the steps. Some of the steps will be performed in your computer and others in the server (in order to bring the files to you).

#### Server actions

The first we need to do, is to use some version control software to allow to track any change in our installation and move it between places. We'll use GIT and Github as a remote repository.

First, log in the server, ensure that you have git installed:

```bash
ssh decidim@my-decidim.org
sudo apt install git
```

Now, go to your installation and make sure that your `.gitignore` file includes the file `config/application.yml` which contains sensitive data and we won't to track in GIT.

Check with:

```
grep "application.yml" ~/decidim-app/.gitignore
```

Execute this if not found:

```
echo "/config/application.yml" >> ~/decidim-app/.gitignore
```

The next action is to prepare the directory structure for the deployment with Capistrano. Until now, we've just used a single folder with the application. Any changes are made there and if something goes wrong... , well it can turn quickly into a mess. 

The way Capistrano deals with deployments (and many other tools) is to separate application releases in different folders with some shared content between them (ie: configuration files or user uploads). Then creates a symbolic link to the last release and restarts the server. This way, if something goes wrong is very easy to simply point the server back to a previous release with minimal downtime.

Let's get to it then, we will create a new deployment folder, for instance `app-deploy` and, in it, a config folder in which we will copy our configuration files:

```bash
mkdir -p ~/app-deploy/shared/config
mkdir -p ~/app-deploy/shared/public
mkdir -p ~/app-deploy/shared/log
cp ~/decidim-app/config/application.yml ~/app-deploy/shared/config/
cp ~/decidim-app/config/database.yml ~/app-deploy/shared/config/
```

Now, we will create the uploads and logs folder and move our stuff there:

```bash
mv ~/decidim-app/public/uploads ~/app-deploy/shared/public/
mv ~/decidim-app/log ~/app-deploy/shared/
```

In case we don't want to break our current server just yet, we will add some temporary symlinks to the moved directories in the old system:

```bash
ln -s ~/app-deploy/shared/public/uploads ~/decidim-app/public/uploads
ln -s ~/app-deploy/shared/log ~/decidim-app/log
```

Finally, we will prepare the server to look a the new directory, to start we will point the `current` release to our old `decidim-app` directory. Then, after the first Capistrano deploy, this will change automatically.

First, create a symlink to our current installation:

```bash
ln -s ~/decidim-app ~/app-deploy/current
```

We need to reconfigure where nignx will look for files, assuming we've followed the "Ubuntu 18.04" guide, edit `decidim.conf` Nginx file:

```
sudo nano /etc/nginx/nginx/sites-enabled/decidim.conf
```

Change the line with

```
root         /home/decidim/decidim-app/public;
```

with:
 
```
root         /home/decidim/app-deploy/current/public;
```

Let's check the file is correct with the command:

```bash
sudo nginx -t
```

It should respond something like this:

```
nginx: the configuration file /etc/nginx/nginx.conf syntax is ok
nginx: configuration file /etc/nginx/nginx.conf test is successful
```

Then, restart Nginx:

```
sudo service nginx restart
```

Here, if you have any other scripts that deal with the former route (`~/decidim-app`), you should edit them to point to the new deployment path (`~/app-deploy/current/`).

If you have followe the "Ubuntu 18.04" guide or used the Automated script, you should look and edit the crontab:

```bash
crontab -e
```

Change any reference to the path `~/decidim-app` for `/app-deploy/current` and ensure to kill the old instance of ActiveJob with this command:

```bash
kill -9 $(cat ~/decidim-test/tmp/pids/delayed_job.pid)
```

At this point, we are ready to move the rest of the action to our computer. From now on, we won't make changes directly in the server anymore.

#### Local actions

Now is the time to install Ruby and GIT in your computer as any further operation will be done there only.
As this depends heavily on your operative system, you should look up a little what's the best way in your particular case.

If you are using Ubuntu for instance, you can follow the firsts steps of the installation guide to install the `rbenv` ruby manager. Refer to their repository for information:

https://github.com/rbenv/rbenv

You also need to install GIT, again, the method vary but it should be a quite straightforward process. Check the official page for information:

https://git-scm.com/book/en/v2/Getting-Started-Installing-Git

So, from now on we'll assume you have both ruby (with gems) and git configured in your local computer.

Now, we will move the content from the server to our computer with this command:

```bash
mkdir decidim-my-app 
cd decidim-my-app
sudo scp -r decidim@myserver.org:decidim-app .
```

Now that we have the code on our computer, we need to start tracking it by making "commit" in the GIT history. We'll start with our first commit:

```
git add .
git commit -m "Initial Decidim installation"
```

At this, you have the code in your own computer, in the next steps we will add Capistrano to our project and then we will use it to mange the server updates for us.

However, we still need to have a remote repository for GIT, this is a way to centralize our code in an external server, capistrano will use it to download the changes and deploy the application.

You can use [Github](https://github.com/), [Gitlab](https://gitlab.com), [Bitbucket](https://bitbucket.org/), or any other similar provider (you can even use your own servers if you want).

So, let's say you are using Github, just create an account there and initialize a new repository called, for instance, `decidim-my-app` (call it something meaningful to you).

After creating your repository, Github will present you with a bunch of instructions, we are interested in the ones with this type of content:

```bash
git remote add origin git@github.com:YourUser/decidim-my-app.git
git push -u origin master
```

Which is exactly what you need to execute after the previous initial commit. This will upload all your file to Github and you are ready to move you continue with Capistrano.


First, install Capistrano globally by executing:

```bash
gem install capistrano
```

If you have succeeded, you should be able to run the next command and get the version of Capistrano installed:

```bash
cap --version
Capistrano Version: 3.14.0 (Rake Version: 13.0.1)
```

Then, modify the `Gemfile` with and editor of your choice (try [VSCode](https://code.visualstudio.com/) if unsure). And add the "capistrano" lines in the `:development` section:

```ruby
...
group :development do
  gem "letter_opener_web", "~> 1.3"
  gem "listen", "~> 3.1"
  gem "spring", "~> 2.0"
  gem "spring-watcher-listen", "~> 2.0"
  gem "web-console", "~> 3.5"

  gem 'capistrano'
  gem 'capistrano-rbenv'
  gem 'capistrano-bundler'
  gem 'capistrano-passenger', '>= 0.1.1'
  gem 'capistrano-rails'
end
...
```

Then bundle locally:

```bash
bundle update
```

Now, as matter of security, add these lines into the file `.gitignore`:

```
# Ignore deploy secrets
/config/deploy.rb
/config/deploy/*
/Capfile
```

You can now create a new commit with git with the changes:

```bash
git add .
git commit -m "Add capistrano gems"
git push
```

Nice and tidy!, Now is the time to configure Capistrano to let it now about our server. We will start by generating the first automated configuration with the command:

```bash
cap install
```

This will generate some files, the most important are:

```
Capfile
config/deploy.rb
config/production.rb
```

We need to modify these files, let's start with `Capfile`, We should uncomment or add the next lines:

```
require "capistrano/rbenv"
require "capistrano/bundler"
require "capistrano/rails/assets"
require "capistrano/rails/migrations"
require "capistrano/passenger"
require "whenever/capistrano"
```

**Note**: The `rbenv` depends on how you've installed ruby in your system. Check that in the [official documentation](https://capistranorb.com/) if you are not using rbenv.

Next is to edit the `config/production.rb` file, we will indicate the servers we are using there (in our case is only one). Let's add these lines in it at the end of the file:

```ruby
role :app, %w{decidim@myserver.org}
role :web, %w{decidim@myserver.org}
role :db,  %w{decidim@myserver.org}
``` 

Last, is to configure the file `config/deploy.rb`.
In this file we need to add (or in some cases uncomment) several lines, be careful, some might change according to your system:


```ruby
set :rbenv_type, :user # or :system, depends on your rbenv setup
set :rbenv_ruby, '2.6.6'

set :application, "decidim-my-app"
set :repo_url, "https://github.com/YourUser/decidim-my-app.git"

set :linked_files, fetch(:linked_files, []).push('config/application.yml')
set :linked_dirs, fetch(:linked_dirs, []).push('log', 'tmp/pids', 'tmp/cache', 'tmp/sockets', 'vendor/bundle', 'public/system', 'public/uploads')

set :passenger_restart_command, '/usr/bin/passenger-config restart-app'

# This will use system configure bundle path, 
# it is safe to remove if you want your gems 
# in the folder ~/app-deploy/shared/bundle
set :bundle_path, nil
set :bundle_without, nil
set :bundle_flags, nil

# Default branch is :master
# ask :branch, `git rev-parse --abbrev-ref HEAD`.chomp

# Default deploy_to directory is /var/www/my_app_name
set :deploy_to, "/home/decidim/app-deploy"

```

We've done, if everything is correct we should be able to make our first deploy with Capistrano with the command:

```
cap production deploy
```

The output will look like (it will take a while):

```
00:00 git:wrapper
      01 mkdir -p /tmp
    ✔ 01 decidim@myserver.org 0.137s
      Uploading /tmp/git-ssh-decidim-my-app-decidim.sh 100.0%
      02 chmod 700 /tmp/git-ssh-decidim-my-app-decidim.sh
    ✔ 02 decidim@myserver.org 0.153s
00:00 git:check
      01 git ls-remote https://github.com/YourUser/decidim-my-app.git HEAD
      01 1305546c96c556b6eaacdf9c2a6c952d4e64e092	HEAD
    ✔ 01 decidim@myserver.org 0.677s
00:01 deploy:check:directories
...
...
...
INFO [b0236541] Finished in 0.130 seconds with exit status 0 (successful).
```

### Conclusion

Using an automated tool to deploy your applications is a step forward in terms of maintainability and security. Of course, this is the very basic start point. From this you can use this to split tasks between servers (for instance database in one server and code in another).

Make sure that you read the Capistrano guide to know how to deal with rollbacks for instance:

https://capistranorb.com/documentation/getting-started/rollbacks/

