```
_________               ______                _____                 _____
______  /_____ ________ ___  /______ _____  _____(_)_______ ______ ___  /_______ ________
_  __  / _  _ \___  __ \__  / _  __ \__  / / /__  / __  __ \_  __ `/_  __/_  __ \__  ___/
/ /_/ /  /  __/__  /_/ /_  /  / /_/ /_  /_/ / _  /  _  / / // /_/ / / /_  / /_/ /_  / 
\__,_/   \___/ _  .___/ /_/   \____/ _\__, /  /_/   /_/ /_/ \__,_/  \__/  \____/ /_/ 
                /_/                   /____/             Deploy with style!
```

Deployinator - Deploy code like Etsy
====================================

Deployinator is a deployment framework extracted from Etsy. We've been using it since late 2009 / early 2010. This has been revamped into a ruby gem.

## Installation

This demo assumes you are using bundler to install deployinator. If you aren't
you can skip the bundler steps.

- Create a folder for your project. `mkdir test_stacks`

- Add this line to your application's Gemfile:

```ruby
    source 'https://rubygems.org'
    gem 'deployinator', :git => 'git@github.com:etsy/DeployinatorGem.git', :branch => 'master'
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

Create a binstub for the run log tailing backend:
```sh
    bundle install --binstubs deployinator
```

## Usage

Next, you can initialize the project by running:
```sh
    $ bundle exec rake 'deployinator:init[Company]'
```
where Company is the name of your company/organization with an uppercase first letter.
Now you are ready to build your first stack. 
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

Edit the stacks/test_stack.rb file to look like this (adding git version bumping and checkout)
```ruby
require 'helpers/test_stack'
module Deployinator
  module Stacks
    class TestStackDeploy < Deployinator::Deploy
        include Deployinator::Helpers::TestStackHelpers,
            Deployinator::Helpers::GitHelpers

      def test_stack_production(options={})
        # save old version for announcement
        old_version = test_stack_production_version

        # Clone and update copy of git repository
        git_freshen_or_clone(stack, "ssh #{Deployinator.app_context['test_stack_info'][:prod_host]}", stack_config[:checkout_path], "master")

        # bump version
        version = git_bump_version(stack, checkout_path, "ssh #{Deployinator.app_context['test_stack_info'][:prod_host]}", checkout_path)

        # Write the sha1s of the different versions out to the logs for safe keeping.
        log_and_stream "Updating application to #{version} from #{old_version}"

        # log the deploy
        log_and_shout :old_build => get_build(old_version), :build => get_build(version)
      end
    end
  end
end
```

Next, edit the helpers/test_stack.rb file. You can delete the test_stack_head_build function since you are using the GitHelpers and that is automatically taken care of for you. Here is the final version:

```ruby
module Deployinator
  module Helpers
    module TestStackHelpers
      def test_stack_production_version
        %x{ssh #{Deployinator.app_context["test_stack_config"][:prod_host]} cat #{Deployinator.app_context[test_stack_config"][:checkout_path]}/#{stack}/version.txt}
      end
    end
  end
end
```

Create the folder that will contain the checkout if it doesn't exist already
(one level above your checkout destination)

- Run the tailer as a background service:
```sh
    ./bin/deployinator-tailer.rb &
```

### Customizing your stack

A stack can be customized so that you have flexibility over the different environments within it (which correspond to buttons) and the methods that correspond to each button press.

By default, you will see a button called "deploy _stackname_" where _stackname_ is the stack defined in the rake command. In your helpers file, you can add a function called _stackname_\_environments that returns an array of hashes.  Each hash will correspond to a new environment, or button. For example if your stack is called web, you can define a function like so in helpers/web.rb to define qa and production environments within your web stack:

      def web_environments
        [
          {
            :name            => "qa",
            :method          => "qa_rsync",
            :current_version => qa_version,
            :current_build   => current_qa_build,
            :next_build      => next_qa_build
          },
          {
            :name            => "production",
            :method          => "prod_rsync",
            :current_version => prod_version,
            :current_build   => current_prod_build,
            :next_build      => next_prod_build
          }
        ]
      end

The keys of each hash describe what you will be pushing for that environment:

* __:name__ - name of the environment
* __:method__ - method name (string) that gets invoked when you press the button (this is defined in the stack)
* __:current_version__ - method that returns the version that is currently deployed in this environment (defined in the helper)
* __:current_build__ - method that returns the build that is currently deployed (usually inferred from the version, also defined in the helper)
* __:next_build__ - method that returns the next build that is about to be deployed (defined in the helper)

### Useful helper methods
There are a few helpers built in that you can use after creating a new stack to assist you

#### run_cmd

Shell out to run a command line program.
Includes timing information streams and logs the output of the command.

For example you could wrap your capistrano deploy:

    run_cmd %Q{cap deploy}


#### log_and_stream 

Output information to the log file, and the streaming output handler.
The real time output console renders HTML so you should use markup here.

    log_and_stream "starting deploy<br>"

#### log_and_shout

Output an announcement message with build related information.  
Also includes hooks for Email.

    log_and_shout({
        :old_build  => old_build,
        :build      => build,
        :send_email => true
    });

The supported keys for log_and_shout are:

* __:env__ - the environment that is being pushed
* __:user__ - the user that pushed
* __:start__ - the start time of the push (if provided the command will log timing output)
* __:end__ - the end time of the push (defaults to "now")
* __:old_build__ - the existing version to be replaced
* __:build__ - the new version to be pushed
* __:send_email__ - true if you want it to email the announcement (make sure to define settings in config)

## Hacking on the gem
If you find issues with the gem, or would like to play around with it, you can check it out from git and start hacking on it. 
First tell bundler to use your local copy instead by running:
```sh
    $ bundle config local.deployinator /path/to/DeployinatorGem
```
Next, on every code change, you can install from the checked out gem by running (you will want to make commits to the gem to update the sha in the Gemfile.lock)
```sh
    $ bundle install --no-deployment && bundle install --deployment
```

### Plugins
TODO: Write this

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
