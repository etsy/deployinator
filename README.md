# Deployinator

This gem is the core of Deployinator. Here are the steps to get it running for your application.

## Installation

This demo assumes you are using bundler to install deployinator. If you aren't
you can skip the bundler steps.

- Create a folder for your project. `mkdir test_stacks`

- Add this line to your application's Gemfile:

```ruby
    source 'https://rubygems.org'
    gem 'deployinator'
 ```

- And then execute:
```sh
    $ bundle install --path vendor/bundle
```
inside your project directory. 

Run the following command:
```sh
    $ echo "require 'deployinator'\nload 'deployinator/tasks/initialize.rake' " > Rakefile
```
This will create a rake file and set it up to make deployinator's initialization
tasks available to you.

## Usage

Next, you can initialize the project by running:
```sh
    $ bundle exec rake 'deployinator:init[Company]'
```
where Company is the name of your company/organization with an uppercase first letter.
Now you are ready to build your first stack. 
A *stack* is a collection of code, the initialization and the teardown steps involved in getting it running. 
Let's create our first stack by running:
```sh
    $ bundle exec rake 'deployinator:new_stack[test_stack]'
```
where test_stack is the name of your stack. Make sure this is all lowercase and underscore escaped.

The commands run by the rake tasks are logged to stderr.

Our deployinator stack is now ready. 
If you are using bundler add the following to the top of the config.ru that
shipped with deployinator
```ruby
    require 'rubygems'
    require 'bundler'
    Bundler.require
```
We need a server to run our Sinatra application. For the purpose of this demo, we will use [shotgun](https://github.com/rtomayko/shotgun). Let's install shotgun as a global gem and we are ready to roll!
```sh
    $ gem install shotgun
```
Note: You might need `sudo` to install shotgun. 
Start the server by running:

```sh
    $ shotgun --host localhost -p 7777 config.ru
```
The host could be localhost or the dns name (or ip address of the server you are using). You can set any port you want that's not in use using the `-p` flag.
Fire it up and load the page. You should see deployinator running!

You will probably want a robust server like apache to handle production traffic. 

### Deploying a test stack
- The `config/base.rb` file is the base config for the application.
```ruby                                                                                                         
# where is deployinator installed?
Deployinator.app_context['test_stack_config'] = {
   :prod_host               => "localhost",
   :checkout_path           => "/tmp/deployinator_dev/"
 }
Deployinator.git_info_for_stack = {
    :test_stack => {
        :user => "etsy",
        :repository => "DeployinatorGem"
    }
}
```

Edit the stacks/test_stack.rb file to include the GitHelpers:
```ruby
    include Deployinator::Helpers::GitHelpers
```

Next, edit the helpers/test_stack.rb file. You can delete the test_stack_head_build function since you are using the GitHelpers and that is automatically taken care of for you
Create the folder for the local checkout.

### Hacking on the gem
If you find issues with the gem, or would like to play around with it, you can check it out from git and start hacking on it. 
First tell bundle to use your local copy instead by running:
```sh
    $ bundle config local.deployinator /path/to/DeployinatorGem
```
Next, on every code change, you can install from the checked out gem by running
```sh
    $ bundle install --no-deployment && bundle install --deployment
```







## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
