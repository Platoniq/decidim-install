---
layout: default
title: Updating Decidim between version
nav_order: 4
---

Updating Decidim
================

Because Decidim is a gem in our system, to update it we will have to edit our `Gemfile` and specify the new version number.

To keep our system up to date, we can visit the page https://github.com/decidim/decidim/releases and compare with our `Gemfile`. See if the lines specifying the gem called "decidim-something" are followed by the number corresponding to the latest release:


```ruby
gem "decidim", "0.15.1"
gem "decidim-conferences", "0.15.1"
gem "decidim-consultations", "0.15.1"
gem "decidim-initiatives", "0.15.1"

gem "decidim-dev", "0.15.1"
```

For example, if the latest release is 0.16 we could decide to update.

To update, usually requires only to change the old version number on these gems to the new one. For instance, previous example should be:

```ruby
gem "decidim", "0.16"
gem "decidim-conferences", "0.16"
gem "decidim-consultations", "0.16"
gem "decidim-initiatives", "0.16"

gem "decidim-dev", "0.16"
```

After doing that, you need to execute these commands:

```bash
bundle update decidim
bin/rails decidim:upgrade
bin/rails db:migrate
```

In theory, that would be all. However, you need to be careful in certain situations, specially if your copy of Decidim has many code modifications. I'd recommend to always test the upgrade in a separate machine with the same configuration (If using Digitalocean you can create an snapshot of the server, tested the update, and then remove it, similar process on other providers).

### Recommendations

1. Make a full backup of the database before updating, just in case something unexpected happens.
1. If you are more than update away. Always update from one version to the immediately next one and then repeat the process until you are up to date.
1. Always check the instructions for a certain version upgrade in https://github.com/decidim/decidim/releases. Some releases require to perform certain actions as they may change some database structures. Follow that instructions if you are affected.
1. Check also the file https://github.com/decidim/decidim/blob/master/CHANGELOG.md It may have relevant information for updates between versions.