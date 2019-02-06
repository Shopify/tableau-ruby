# TableauRuby

Unofficial Tableau API Ruby client

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'tableau_ruby'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install tableau_ruby

## Usage

### Setup

``` ruby
require 'rubygems'
require 'tableau_ruby'

Tableau.configure do |config|
	# Required
	config.host = 'https://your-url-here.com'
	config.admin_name = 'your-admin-username'
	config.admin_password = 'your-admin-password'
	# Optional
	config.user_name = 'user-to-act-on-behalf-of'
	config.content_url = 'defaults-to-empty-string'
end

@client = Tableau::Client.new

# Alternatively pass the information as a hash

@client = Tableau::Client.new(
	host: 'https://your-url-here.com',
	admin_name: 'your-admin-password',
	admin_password: 'your-admin-password'
)

@site = @client.sites.find_by(name: 'Default')['site']

@user = Tableau::User.new(@client, @client.users.find_by(site_id: @site['id'], name: 'user-name')['user'])
@user.workbooks

```

### Sites
``` ruby

# By default the request does not include projects in the results
# add them by including include_projects: true
@sites = client.sites.all(include_projects: true)

@site = client.sites.find_by(id: 'site-id') # also try :name and :url
@site = client.sites.create(name: 'Site Name')
@site = client.sites.update(id: 'site-id')
@site = client.sites.delete(id: 'site-id')

```

### Projects
``` ruby

@projects = @client.projects.all()

@project = client.projects.create(name: 'Project Name', site_id: 'project-site-id')
@project = client.projects.update(id: 'project-id', site_id: 'project-site-id')
@project = client.projects.delete(id: 'project-id', site_id: 'project-site-id')

```

### Users
``` ruby

@users = client.users.all(site_id: 'site-id')

@user = client.users.find_by(name: 'user-name', site_id: 'site-id')
@user = client.users.create(name: 'new user', site_id: 'site-id')
@user = client.users.delete(id: 'user-id', site_id: 'site-id')

```

### Workbooks
``` ruby

@workbooks = client.workbooks.all(site_id: 'site-id')
@workbooks = client.workbooks.all(site_id: 'site-id', is_owner: boolean, page_size: 'page-size', page_number: 'page-number')

@workbook = client.workbooks.find(id: 'workbook-id', site_id: 'site-id', include_views: true)

@workbook_image = client.workbooks.preview_image(id: 'workbook-id', site_id: 'site-id') # returns the binary image data.

```

### Tests

After bundling the tests can be run by calling `bundle exec rake test`.You must set the following environment variables for the tests to run successfully:

``` bash
TABLEAU_URL
TABLEAU_ADMIN_USER
TABLEAU_ADMIN_PASSWORD
TABLEAU_DEFAULT_SITE
```

ex.
``` bash
TABLEAU_URL="http://tab" TABLEAU_ADMIN_USER="admin" TABLEAU_ADMIN_PASSWORD="password" TABLEAU_DEFAULT_SITE="default" b rake test
```

## TODO
* inherit site_id from client object to avoid having to pass site_id
* consolidate parameter checking
* error responses
* make self documenting

## Contributing

1. Fork it ( https://github.com/[my-github-username]/tableau_ruby/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request
