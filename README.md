Installing Decidim
==================

A easy guide to install [Decidim](https://github.com/decidim/decidim), which is a participatory democracy framework created in Ruby on Rails.

It's a very interesting piece of software but it may be challenging to install it if you are not familiar with the internals.

Here I'll make a step-by-step guide on how to install it on production into a machine with Ubuntu 18.04.

I've made this guide because it can be quite challenging to install Decidim in production (as there's currently not much official documentation covering this). This guide also covers some common problems you may face during the process.

Start here:

1. [Installing Decidim on Ubuntu 18.04](decidim-bionic.md)<br>This will guide you to the process of install Decidim in a clean machine and getting it up an running.
1. [Minimal configuration of Decidim](basic-config.md)<br>This part is to configure the 3 extra aspects required run Decidim appropriately. Configure Email sending, SSL security in your server and OAuth authentication.
1. [Installing in Amazon AWS with ElasticBeanstalk](decidim-aws.md)<br>An alternative guide to install Decidim in Amazon AWS. This is a Heroku-like PaaS deployment sistem. It auto-scales servers if needed and it may be a little cheaper than heroku.

Feel free to create issues or pull requests if you encounter errors or want to make improvements in this guide!


### Official resources

- [Decidim official documentation](https://decidim.org/docs/), Happy to say that this guide is linked there!

- [Decidim source code](https://github.com/decidim/decidim), There's additional documentation here (dive into the `docs/` folder).

- [Edu Decidim](https://edu.decidim.org/) Community using Decidim with resources to successfully use Decidim.

- [Meta Decidim](https://meta.decidim.org) Community using Decidim to make decisions about the software itself.

@Author<br>
Ivan Vergés<br>
Twitter @ivanverges

@Thanks to<br>
Robert Garrigós for testing and point improvements to this guide, Guillem Marpons and the rest of the Decidim team for their encouragement and support.

@License<br>
AGPL 3.0
