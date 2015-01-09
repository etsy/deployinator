# Deployinator

TODO: Write a gem description
This gem is the core of Deployinator. Here are the steps to get it running for your application.

## Installation
- Create a folder for your project. `mkdir testStacks`

- Add this line to your application's Gemfile:

    `gem 'deployinator'`

- And then execute:
```sh
    $ bundle install --path vendor/bundle
```
inside your project directory.

Or install it yourself as:

```sh
    $ gem install deployinator
```

## Usage

Run the following command:
```sh
    $ echo "require 'deployinator'\nload 'deployinator/tasks/initialize.rake' " > Rakefile
```
This will create a rake file and set it up with some includes for deployinator tasks.
Next, you can initialize the project by running:
```sh
    $ bundle exec rake 'deployinator:init[Company]'
```
where Company is the name of your company/organization with an uppercase first letter.
Now you are ready to build your first stack. 
A *stack* is a collection of code, the initialization and the teardown steps involved in getting it running. 
Let's create our first stack by running:
```sh
    $ bundle exec rake 'deployinator:new_stack[stack]'
```
where stack is the name of your stack. 

The commands run by the rake tasks are logged to stderr.

Our deployinator stack is now ready. Run the following command to set up the right bundler requires before getting started.
```sh
    $ echo "require 'rubygems'\nrequire 'bundler'\n\nBundler.require\n" >> config.ru
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


### Hacking on the plugin
If you find issues with the plugin, or would like to play around with it, you can check it out from git and start hacking on it. 
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
