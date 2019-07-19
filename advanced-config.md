---
layout: default
title: Advanced config & tricks
nav_order: 5
---

Advanced configuration of Decidim
=================================

Once deployed our instance of Decidim some we may want to change some settings (for instance, the available languages in a organization). As I found many aspect under-documented or missing at all, here are some options that may interest you to update/change your Decidim instance.

Change the available languages of an organization
-------------------------------------------------

When you first create and organization, they make you choose the available languages for it (through the `/system/` url). However, when you access that url to edit the organization, the language selector is not available anymore. Here is a way to update that locales manually:

First, be sure that your initializer file has all the locales you want:

Edit the file `config/initializers/decidim.rb` and be sure to include all the necessary locales:

```ruby
...
# Change these lines to set your preferred locales
  config.default_locale = :en
  config.available_locales = [:en, :ca, :es, :fr, :pt]
..
```

Then you need to access the rails console and update the organization locales manually.

Access to your rails console with the command:

```
cd ~/your-decidim-path
bin/rails c
```

You should view something like this:

 ```
Loading development environment (Rails 5.2.1)
irb(main):001:0>
 ```

Then you need to select your organization. If you have only one organization you can just run the command:

```ruby
irb(main):001:0> o=Decidim::Organization.find(1)
```

By doing this we've fetched from the database the first item in the table `organizations` and assigned to the variable `o`. Now we can check our current locales:

```ruby
irb(main):002:0> o.available_locales
=> ["en", "ca", "es"]
irb(main):003:0>
```

We can add more locales by doing this:

```ruby
irb(main):004:0> o.available_locales += ["fr", "pt"]
=> ["en", "ca", "es", "pt", "fr"]
irb(main):005:0>
```

or just overwrite them:

```ruby
irb(main):005:0> o.available_locales = ["en", "ca", "es", "pt", "fr"]
=> ["en", "ca", "es", "pt", "fr"]
irb(main):006:0>
```

Then we need to save them by executing the command `o.save!`:

```ruby
irb(main):006:0> o.save!
   (24.1ms)  BEGIN
  Decidim::Organization Exists (15.5ms)  SELECT  1 AS one FROM "decidim_organizations" WHERE "decidim_organizations"."name" = $1 AND "decidim_organizations"."id" != $2 LIMIT $3  [["name", "Hayes LLC"], ["id", 1], ["LIMIT", 1]]
  Decidim::Organization Exists (1.8ms)  SELECT  1 AS one FROM "decidim_organizations" WHERE "decidim_organizations"."host" = $1 AND "decidim_organizations"."id" != $2 LIMIT $3  [["host", "localhost"], ["id", 1], ["LIMIT", 1]]
   (0.7ms)  COMMIT
=> true
irb(main):007:0>
```

Done! your new locales should be available in your URL.

> **NOTE:** It's difficult to **remove** languages as some content is cached in some places once generated. Removing languages can lead easily to generation of 500 errors.