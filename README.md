<pre>  
                  _________               ______                _____                 _____
                  ______  /_____ ________ ___  /______ _____  _____(_)_______ ______ ___  /_______ ________
                  _  __  / _  _ \___  __ \__  / _  __ \__  / / /__  / __  __ \_  __ `/_  __/_  __ \__  ___/
                  / /_/ /  /  __/__  /_/ /_  /  / /_/ /_  /_/ / _  /  _  / / // /_/ / / /_  / /_/ /_  / 
                  \__,_/   \___/ _  .___/ /_/   \____/ _\__, /  /_/   /_/ /_/ \__,_/  \__/  \____/ /_/ 
                                 /_/                   /____/             Deploy with style!
</pre>  

Stacks
======

Deployments are grouped by "stacks". You might have a "web" and "search" stack.

Each of those stacks might have different deployment environments, such as "staging" or "production". 

You can map a button to each of these environments,  to create multi-stage pushes within each stack. 


Install
=======

Deployinator is a standard [Rack][1] app (mostly [Sinatra][2]).
Point your rack-capable web server at the `config.ru`, and it should mostly work. All dependencies are managed with [bundler][3], so a `bundle install` should get your gems set up.

It has been tested with ruby 1.8.6, 1.8.7 and 1.9.2. For local development, you can use [Pow!](http://pow.cx/). Assuming you are using OSX, you'd want to do the following:

* `curl get.pow.cx | sh`
* `cd ~/.pow`
* `ln -s /path/to/deployinator`
* `cd /path/to/deployinator`
* `bundle install`
* `echo "export HTTP_X_USERNAME=$USER\nexport HTTP_X_GROUPS=foo" > .powenv`
* visit [deployinator.dev](http://deployinator.dev) in your browser

If you are using RVM you may need to echo the ruby version like so:

* `echo "rvm ruby-1.9.3-head" > .rvmrc`

You may want to tell Pow to restart before each request for development:

* `touch ./tmp/always_restart.txt`


Authentication
================

At Etsy, we use an internal SSO similar to [GodAuth][4], which sets http headers that are checked in deployinator.

This code is abstractable, and will be made more generic soon.

There are a list of urls that don't require authentication, those are currently defined at the top of `helpers.rb` but should be either set in a config, or maybe a sinatra plugin?


Creating a new stack
====================

To create a new stack, run the rake task "new_stack"

    STACK=my_blog rake new_stack


Configuration
=============

Configuration settings live in config/*.rb. For example, your config/development.rb might look like this:

```
Deployinator.log_file = Deployinator.root(["log", "development.log"])
Deployinator.domain = "awesomeco.com"
Deployinator.hostname = "deployinator.dev"
Deployinator.graphite_host = "localhost"
Deployinator.github_host = "github.com"
Deployinator.default_user = "joboblee"
Deployinator.devbot_url = "http://botserver/bot/announce"

Deployinator.new_relic_options = {
  :apikey => "12345",
  :appid  => "4567"
}

Pony.options = {
  :via         => :smtp,
  :from        => "deployinator@#{Deployinator.domain}",
  :headers     => {"List-ID" => "deploy-announce"},
  :to          => "joboblee@#{Deployinator.domain}",
  :via_options => {
    :address              => 'smtp.gmail.com',
    :port                 => '587',
    :enable_starttls_auto => true,
    :user_name            => 'gmailuser@gmail.com',
    :password             => 'gmail-password',
    :authentication       => :plain,
    :domain               => Deployinator.domain
  }
}

```


Helpers
-------------

There are a few helpers built in that you can use after creating a new stack to assist you

## run_cmd

Shell out to run a command line program.
Includes timing information streams and logs the output of the command.

For example you could wrap your capistrano deploy:

    run_cmd %Q{cap deploy}


## log_and_stream 

Output information to the log file, and the streaming output handler.
The real time output console renders HTML so you should use markup here.

    log_and_stream "starting deploy<br>"

## log_and_shout

Output an announcement message with build related information.  
Also includes hooks for Email and IRC.

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
* __:irc_channels__ - comma separated list of IRC channels
* __:send_email__ - true if you want it to email the announcement (make sure to define settings in config)

### IRC bot announcements

The IRC bot works by Deployinator issuing a POST request with the announcement to your internal web page, which should in turn initiate the bot communication. The page must accept at least a _message_ parameter which deployinator populates.

For example you should define devbot in the config to be a url

http://mybot/announce

which accepts a POST request with the _message_ key and _channels_ key.  The _channels_ values are supplied from the __:irc_channels__ parameter passed to log\_and\_shout. 
Its up to you to implement what happens with the _message_ and _channels_ POST request parameters, so you can plug in more than just IRC bot communication here.



[1]: http://rack.rubyforge.org/
[2]: http://www.sinatrarb.com/
[3]: http://gembundler.com/
[4]: https://github.com/exflickr/GodAuth

