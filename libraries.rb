require "rubygems"
require "bundler"
Bundler.setup

module Deployinator
  class << self
    # File to log to
    attr_accessor :log_file
    
    # Your company domain name
    attr_accessor :domain

    # New Relic logging of deploys
    attr_accessor :new_relic_options

    # Hostname where deployinator runs
    attr_accessor :hostname

    # Devbot url (announce over irc)
    attr_accessor :devbot_url

    # Graphite host
    attr_accessor :graphite_host

    # Graphite port
    attr_accessor :graphite_port

    # Github host (if you're using Github::FI)
    attr_accessor :github_host

    # Default svn repo path for unspecified repos
    attr_accessor :svn_default_repo

    # Default username for passwordless ssh
    attr_accessor :default_user

    # IRC Log host for irc topics
    attr_accessor :irc_log_host

    # Bug or issue tracker - proc that takes the issue id as an argument
    # ex: Deployinator.issue_tracker = proc {|issue| "http://foo/browse/#{issue}"}
    attr_accessor :issue_tracker

    def log_file?
      log_file
    end

    def env
      ENV["RACK_ENV"] || ENV["RAILS_ENV"] || "development"
    end

    # Base root path
    def root(path = nil)
      base = File.expand_path(File.dirname(__FILE__))
      path ? File.join(base, path) : base
    end
  end
end

$LOAD_PATH.unshift Deployinator.root unless $LOAD_PATH.include? Deployinator.root
$LOAD_PATH.unshift Deployinator.root("lib") unless $LOAD_PATH.include? Deployinator.root("lib")

require 'pony'
require 'sinatra/base'
require 'mustache/sinatra'

# Silence mustache warnings
module Mustache::Sinatra::Helpers
  def warn(msg); nil; end
end

# The magic of the helpers
Dir[Deployinator.root(["helpers", "*.rb"])].each do |file|
  require file
  require file
  the_mod = Deployinator::Helpers.const_get(Mustache.classify(File.basename(file, ".rb") + "Helpers"))
  Deployinator::Helpers.send(:include, the_mod)
  Deployinator::Helpers.send(:extend, the_mod)
end

# ruby Std lib
require 'open3'
require 'benchmark'
require 'net/http'
require 'open-uri'
require 'uri'
require 'time'
require 'json'

# deployinator libs
require 'helpers'
require 'deployinator'
require 'version'
require 'svn'
require 'stream'

require 'views/layout'

# The magic of the stacks
Dir[Deployinator.root(["stacks", "*.rb"])].each do |file|
  require file
  klass = Mustache.classify(File.basename(file, ".rb"))
  the_mod = Deployinator::Stacks.const_get(klass)
  Deployinator::Helpers.send(:include, the_mod)
  Deployinator::Helpers.send(:extend, the_mod)

  # Hackery... all stacks should have a view class that inheriets
  # from "Layout". This is so we MAY but don't HAVE to define views/stack.rb
  Deployinator::Views.class_eval <<-EOF
    class #{klass} < Layout
    end
  EOF
end

require 'views/view_helpers'

class Mustache
  include Deployinator::Helpers
  include Deployinator::Views::ViewHelpers
end

module Deployinator
  class Stream
    include Deployinator::Helpers
  end
end

# Configuration settings
require Deployinator.root(["config", Deployinator.env])