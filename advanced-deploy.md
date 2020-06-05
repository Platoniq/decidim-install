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

Now, enter your application directory and add your first commit:

```
cd ~/decidim-app
git add .
git commit -m "Initial Decidim installation"
```

Now you need and external repository that will act as a backup and to move files to your own computer. You can use Github, Gitlab, Bitbucket, or any other similar provider (you can even use your own servers if you want).

So, let's say you are using Github, just create an account there and initialize a new repository called, for instance, `decidim-my-app` (call it something meaningful to you).

After creating your repository, Github will present you with a bunch of instructions, we are interested in the ones with this type of content:

```bash
git remote add origin git@github.com:YourUser/decidim-my-app.git
git push -u origin master
```

Which is exactly what you need to execute after the previous initial commit. This will upload all your file to Github and you are ready to move you operations to your computer.


#### Local actions

Now is the time to install Ruby and GIT in your computer as any further operation will be done there only.
As this depends heavily on your operative system, you should look up a little what's the best way in your particular case.

If you are using Ubuntu for instance, you can follow the firsts steps of the installation guide to install the `rbenv` ruby manager. Refer to their repository for information:

https://github.com/rbenv/rbenv

You also need to install GIT, again, the method vary but it should be a quite straightforward process. Check the official page for information:

https://git-scm.com/book/en/v2/Getting-Started-Installing-Git





