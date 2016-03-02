<pre>
_________               ______                _____                 _____
______  /_____ ________ ___  /______ _____  _____(_)_______ ______ ___  /_______ ________
_  __  / _  _ \___  __ \__  / _  __ \__  / / /__  / __  __ \_  __ `/_  __/_  __ \__  ___/
/ /_/ /  /  __/__  /_/ /_  /  / /_/ /_  /_/ / _  /  _  / / // /_/ / / /_  / /_/ /_  /
\__,_/   \___/ _  .___/ /_/   \____/ _\__, /  /_/   /_/ /_/ \__,_/  \__/  \____/ /_/
                /_/                   /____/             Deploy with style!
</pre>

Deployinator - Deploy code like Etsy
====================================

Deployinator is a deployment framework extracted from Etsy. We've been using it since late 2009 / early 2010. This has been revamped into a ruby gem.

**Table of Contents**

- [Stacks](#stacks)
- [Installation](#installation)
- [Usage](#usage)
  - [Example Stack](#example-stack)
  - [Customizing your stack](#customizing-your-stack)
  - [Useful helper methods](#useful-helper-methods)
  - [Plugins](#plugins)
  - [Template Hooks](#template-hooks)
- [Hacking on the gem](#hacking-on-the-gem)
  - [Contributing](#contributing)

## Stacks
Deployments are grouped by "stacks". You might have a "web" and "search" stack.

Each of those stacks might have different deployment environments, such as "staging" or "production".

You can map a button to each of these environments,  to create multi-stage pushes within each stack.

## Installation

This demo assumes you are using bundler to install deployinator. If you aren't
you can skip the bundler steps.

- Create a directory for your project. `mkdir test_stacks`

- Create a Gemfile for bundler:

```ruby
    source 'https://rubygems.org'
    gem 'etsy-deployinator', :git => 'https://github.com/etsy/deployinator.git', :branch => 'master', :require => 'deployinator'
```

- Install all required gems with bundler:

```sh
    $ bundle install --path vendor/bundle
```

- Run the following command to make deployinator gem's rake tasks available to you:

```sh
    $ echo "require 'deployinator'\nload 'deployinator/tasks/initialize.rake' " > Rakefile
```

- Create a binstub for the deploy log tailing backend:

```sh
    bundle binstub etsy-deployinator
```

- Initialize the project directory by running the following command replacing ___Company___ with the name of your company/organization. This must start with a capital letter.

```sh
    $ bundle exec rake 'deployinator:init[Company]'
```

- If you are using bundler add the following to the top of the config.ru that
shipped with deployinator
```ruby
    require 'rubygems'
    require 'bundler'
    Bundler.require
```

- Run the tailer as a background service (using whatever init flavor you like)

```sh
    ./bin/deployinator-tailer.rb &
```


## Usage


### Example Stack
- Use the deployinator rake task to create the stub for your stack. Replace
___test_stack___ with the name of your stack. This should be all lowercase with
underscores but if you forget the rake task will convert from camelcase for you. The commands run by the rake tasks are logged to stderr.

```sh
    $ bundle exec rake 'deployinator:new_stack[test_stack]'
```

- We need a server to run our Sinatra application. For the purpose of this demo, we will use [shotgun](https://github.com/rtomayko/shotgun). Let's install shotgun into our bundle. Add the following to your Gemfile:

```ruby
    gem 'shotgun'
```

- Now update your bundler:

```sh
    bundle install --path vendor/bundle --no-deployment && bundle install --path vendor/bundle --deployment
```

- Start the server by running:
  - The host could be localhost or the dns name (or ip address of the server you are using). You can set any port you want that's not in use using the `-p` flag.

```sh
    $ bundle exec shotgun --host localhost -p 7777 config.ru
```

- You will probably want a robust server like apache to handle production traffic.

- The `config/base.rb` file is the base config for the application. Replace all
occurences of ___test_stack___ with the name you chose above. Also the example
below uses a git repository of http://github.com/etsy/deployinator, feel free to
replace this with your specific repository

```ruby
Deployinator.app_context['test_stack_config'] = {
   :prod_host               => "localhost",
   :checkout_path           => "/tmp/deployinator_dev/"
 }
Deployinator.git_info_for_stack = {
    :test_stack => {
        :user => "etsy",
        :repository => "deployinator"
    }
}
```

- Edit the stacks/test_stack.rb file to look like this (adding git version bumping and checkout)

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

- Next, edit the helpers/test_stack.rb file. You can delete the test_stack_head_build function since you are using the GitHelpers and that is automatically taken care of for you. Here is the final version:

```ruby
module Deployinator
  module Helpers
    module TestStackHelpers
      def test_stack_production_version
        %x{ssh #{Deployinator.app_context["test_stack_config"][:prod_host]} cat #{Deployinator.app_context["test_stack_config"][:checkout_path]}/#{stack}/version.txt}
      end
    end
  end
end
```

- Create the directory that will contain the checkout if it doesn't exist already
(defined in `config/base.rb`)

- Load up deployinator and deploy your stack!

### Customizing your stack

A stack can be customized so that you have flexibility over the different environments within it (which correspond to buttons) and the methods that correspond to each button press.

By default, you will see a button called "deploy _stackname_" where _stackname_ is the stack defined in the rake command. In your helpers file, you can add a function called _stackname_\_environments that returns an array of hashes.  Each hash will correspond to a new environment, or button. For example if your stack is called web, you can define a function like so in helpers/web.rb to define qa and production environments within your web stack:

      def web_environments
        [
          {
            :name            => "qa",
            :method          => "qa_rsync",
            :current_version => proc{send(:qa_version)},
            :current_build   => proc{send(:current_qa_build)},
            :next_build      => proc{send(:next_qa_build)}
          },
          {
            :name            => "production",
            :method          => "prod_rsync",
            :current_version => proc{send(:prod_version)},
            :current_build   => proc{send(:current_prod_build)},
            :next_build      => proc{send(:next_prod_build)}
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

### Plugins
Deployinator provides various entry points to execute plugins without having to
modify the gem code. Here is a list of current pluggable events:

- __:logout_url__ for defining your own authentications logout url
- __:deploy_start__ for any actions to be performed at the start of a deploy
- __:deploy_end__ for any actions to be performed at the end of a deploy
- __:deploy_error__ for any actions to be performed when an error occurs during a
deploy
- __:run_command_start__ for any actions to be performed at the start of a run_cmd
call
- __:run_command_end__ for any actions to be performed at the end of a run_cmd call
- __:run_command_error__ for any actions to be performed when an error occurs during a
run_cmd call
- __:timeout__ for any actions to be performed when a with_timeout calls times out
- __:announce__ for any actions to be performed when announcing a deploy (IRC
        integration)
- __:diff__ for generating diff links
- __:timing_log__ for sending timing log information to anywhere besides the log
file (Graphite for example)
- __:auth__ for handling auth however you please

To create a plugin simply create a new class (example from our code) that
defined a run method taking event and state. __event__ is a symbol from the
table above and __state__ is a hash of state data which varies from event to
event

```ruby
require 'deployinator/plugin'
require 'helpers/etsy'
require 'deployinator/helpers'

module Deployinator
  class GraphitePlugin < Plugin
    include Deployinator::Helpers::EtsyHelpers,
      Deployinator::Helpers

    def run(event, state)
      case event
      when :run_command_end
        unless state[:timing_metric].nil?
          graphite_timing "deploylong.#{state[:stack]}.#{state[:timing_metric]}", "#{state[:time]}", state[:start_time].to_i
        end
      when :timing_log
        graphite_timing("deploylong.#{state[:stack]}.#{state[:type]}", "#{state[:duration]}", state[:timestamp])
      end
      return nil
    end
  end
end
```

Then simply require your plugin in `lib/app.rb` and add it to your
`config/base.rb` like this:

```ruby
Deployinator.global_plugins = []
Deployinator.global_plugins << "GraphitePlugin"
```

You can also configure plugins to only apply to a single stack like this:

```ruby
Deployinator.stack_plugins = {}
Deployinator.stack_plugins["test_stack"] << "TestStackPlugin"
```

### Template Hooks
Since the main layout page is contained within the gem, there are tags provided
to allow you to add things to it in the header and body. List of points:

- __tailer_loading_message__ To customize the default deploy tailer loading
message
- __additional_header_html__ Additional html to add to the header
- __additional_body_top_html__ Additional html to add to the top of the body
- __additional_body_bottom_html__ Additional html to add to the bottom of the body

To set these simple override the methods in your view class. For example:

```ruby
     def additional_bottom_body_html
       '<script src="/js/check_push_status.js"></script>'
     end
```

This can be done on a global layout that extends the gem's default layout or on
a stack by stack basis in their own view.

### Maintenance mode
Deployinator has a setting for maintenance mode, which is mostly useful if you
have major changes that affect all stacks and you want to make sure no deploys
are going on while you make the change. In order to enable it, you have to set
`Deployinator.maintenance_mode = true`. This will make all pages for anyone
not in `Deployinator.admin_groups` go to `/maintenance`. As a Deployinator
admin you can then still deploy stacks and use the app.

On the maintenance page Deployinator will show the value of
`Deployinator.maintenance_contact` as the place to get help in case you need
any or are confused about maintenance mode.

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

### Stats dashboard
The `/stats` page pulls from `log/deployinator.log` to show a graph of deployments per day for each stack over time. By default, it shows all stacks. To blacklist or whitelist certain stacks, update `config/base.rb` with:
```rb
  Deployinator.stats_included_stacks = ['my_whitelisted_stack', 'another_whitelisted_stack']
  Deployinator.stats_ignored_stacks = ['my_stack_to_ignore', 'another_stack_to_ignore']
  Deployinator.stats_extra_grep = 'Production deploy' # filter out log entries matching this string
```

Whitelisting stacks or applying a custom extra grep can help speed up graph rendering when you have a large log file.

If at some point you change the name of a stack, you can group the old log entries with the new by adding the following to `config/base.rb`:

```rb
 Deployinator.stats_renamed_stacks = [
   {
     :previous_stack => {
       :stack => [ "old_stack_name" ]
     },
     :new_name => "new_stack_name"
   }
 ]
```


### Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
