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


