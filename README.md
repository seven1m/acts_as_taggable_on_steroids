# acts_as_taggable_on_steroids

This plugin is based on acts\_as\_taggable by DHH but includes extras such as tests, smarter tag assignment, and tag cloud calculations.

This particular fork ([seven1m/acts_as_taggable_on_steroids](https://github.com/seven1m/acts_as_taggable_on_steroids)) was made to add support for Ruby 2.1 and Rails 4.x. I haven't yet tested with Rails 4.1 but intend to do so soon.

Original repo was by [Jonathan Viney](jonathan.viney@gmail.com).

## Installation

Add the following to your Gemfile:

```ruby
gem 'acts_as_taggable_on_steroids', github: 'seven1m/acts_as_taggable_on_steroids'
bundle install
rails generate acts_as_taggable_migration
rake db:migrate
```

## Usage

### Basic tagging

Let's suppose users have many posts and we want those posts to have tags. The first step is to add `acts_as_taggable` to the Post class:

```ruby
class Post < ActiveRecord::Base
  acts_as_taggable

  belongs_to :user
end
```

We can now use the tagging methods provided by acts\_as\_taggable, `#tag_list` and `#tag_list=`. Both these methods work like regular attribute accessors.

```ruby
p = Post.first
p.tag_list # []
p.tag_list = "Funny, Silly"
p.save
p.tag_list # ["Funny", "Silly"]
```

You can also add or remove arrays of tags.

```ruby
p.tag_list.add("Great", "Awful")
p.tag_list.remove("Funny")
```

In your views you should use something like the following:

```
<%= f.label :tag_list %>
<%= f.text_field :tag_list, :size => 80 %>
```

### Finding tagged objects

To retrieve objects tagged with a certain tag, use `find_tagged_with`.

```ruby
Post.find_tagged_with('Funny, Silly')
```

By default, `find_tagged_with` will find objects that have any of the given tags. To find only objects that are tagged with all the given tags, use `match_all`.

```ruby
Post.find_tagged_with('Funny, Silly', match_all: true)
```

See ActiveRecord::Acts::Taggable::InstanceMethods for more methods and options.

### Tag cloud calculations

To construct tag clouds, the frequency of each tag needs to be calculated.  Because we specified `acts_as_taggable` on the `Post` class, we can get a calculation of all the tag counts by using `Post.tag_counts`. But what if we wanted a tag count for an single user's posts? To achieve this we call `tag_counts` on the association:

```ruby
User.first.posts.tag_counts
```

A helper is included to assist with generating tag clouds. Include it in your helper file:

```ruby
module ApplicationHelper
  include TagsHelper
end
```

You can also use the `counts` method on `Tag` to get the counts for all tags in the database.

```ruby
Tag.counts
```

Here is an example that generates a tag cloud.

Controller:

```ruby
class PostController < ApplicationController
  def tag_cloud
    @tags = Post.tag_counts
  end
end
```

View:

```
  <% tag_cloud @tags, %w(css1 css2 css3 css4) do |tag, css_class| %>
    <%= link_to tag.name, tag, class: css_class %>
  <% end %>
```

CSS:

```
.css1 { font-size: 1.0em; }
.css2 { font-size: 1.2em; }
.css3 { font-size: 1.4em; }
.css4 { font-size: 1.6em; }
```

### Caching

It is useful to cache the list of tags to reduce the number of queries executed. To do this,
add a column named `cached_tag_list` to the model which is being tagged. The column should be long enough to hold
the full tag list and must have a default value of null, not an empty string.

```ruby
class CachePostTagList < ActiveRecord::Migration
  def self.up
    add_column :posts, :cached_tag_list, :string
  end
end

class Post < ActiveRecord::Base
  acts_as_taggable

  # The caching column defaults to cached_tag_list, but can be changed:
  #
  # set_cached_tag_list_column_name "my_caching_column_name"
end
```

The details of the caching are handled for you. Just continue to use the `tag_list` accessor as you normally would.  Note that the cached tag list will not be updated if you directly create Tagging objects or manually append to the `tags` or `taggings` associations. To update the cached tag list you should call `save_cached_tag_list` manually.

### Delimiter

If you want to change the delimiter used to parse and present tags, set `TagList.delimiter`. For example, to use spaces instead of commas, add the following to config/environment.rb:

```ruby
TagList.delimiter = " "
```

### Unused tags

Set `Tag.destroy_unused` to remove tags when they are no longer being used to tag any objects. Defaults to false.

```ruby
Tag.destroy_unused = true
```

## Bugs?

This fork was made by [Tim Morgan](https://github.com/seven1m), but I don't maintain it beyond what is needed for my own project.

If you find a bug, please fork the repo and fix it.
