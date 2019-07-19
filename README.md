Installing Decidim
==================

> Check the formatted guide!
> 👉 [https://platoniq.github.io/decidim-install/](https://platoniq.github.io/decidim-install/)


A easy guide to install [Decidim](https://github.com/decidim/decidim), which is a participatory democracy framework created in Ruby on Rails.

It's a very interesting piece of software but it may be challenging to install it if you are not familiar with the internals.

Here I'll make a step-by-step guide on how to install it on production into a machine with Ubuntu 18.04.

I've made this guide because it can be quite challenging to install Decidim in production (as there's currently not much official documentation covering this). This guide also covers some common problems you may face during the process.

Start here:

1. [Installing Decidim on Ubuntu 18.04](decidim-bionic.md)<br>This will guide you to the process of install Decidim in a clean machine and getting it up an running.
1. [Minimal configuration of Decidim](basic-config.md)<br>This part is to configure the 3 extra aspects required run Decidim appropriately. Configure Email sending, SSL security in your server and OAuth authentication.
1. [Installing in Amazon AWS with ElasticBeanstalk](decidim-aws.md)<br>An alternative guide to install Decidim in Amazon AWS. This is a Heroku-like PaaS deployment system. It auto-scales servers if needed and it may be a little cheaper than heroku.
1. [Decidim update guide](decidim-update.md)<br>Check this to upgrade Decidim to a new version.
1. [Advanced config & tricks](advanced-config.md)<br>A work in progress file to document some common issues and how to solve it (feel free to ask in the issues).

Feel free to create issues or pull requests if you encounter errors or want to make improvements in this guide!


### Official resources

- [Decidim official documentation](https://decidim.org/docs/), Happy to say that this guide is linked there!

- [Decidim source code](https://github.com/decidim/decidim), There's additional documentation here (dive into the `docs/` folder).

- [Edu Decidim](https://edu.decidim.org/) Community using Decidim with resources to successfully use Decidim.

- [Meta Decidim](https://meta.decidim.org) Community using Decidim to make decisions about the software itself.

### Questions?

Feel free to [check the issues](https://github.com/Platoniq/decidim-install/issues) or [open a new one](https://github.com/Platoniq/decidim-install/issues/new) if you have questions or something is wrong. Pull-request are always wellcome.

Also, [give me a start](https://github.com/Platoniq/decidim-install) if you liked it!

<a class="github-button" href="https://github.com/Platoniq/decidim-install" data-icon="octicon-star" data-size="large" data-show-count="true" aria-label="Star Platoniq/decidim-install on GitHub">Star</a>

### Credits

![Platoniq logo](assets/platoniq-logo.png)

**@Author**<br>
Ivan Vergés<br>
Twitter [@ivanverges](https://twitter.com/ivanverges)

**@Thanks to**<br>
Robert Garrigós and the rest of testers that point many improvements and fixes to this guide, Guillem Marpons and the rest of the Decidim team for their encouragement and support.

**@License**<br>
AGPL 3.0
