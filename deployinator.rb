# = Deployinator
#
# This is the main entry point for all things in the Deployination.
module Deployinator
  
  # = Config settings
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

    # is a log file defined?
    def log_file?
      log_file
    end

    # Running environment for deployinator
    # This is taken from RACK_ENV or RAILS_ENV
    # *note* this is different from deployinator's concept of stacks/environments
    def env
      ENV["RACK_ENV"] || ENV["RAILS_ENV"] || "test"
    end

    # Base root path
    # Takes an optional argument of a string or array and returns the path(s)
    # From the root of deployinator
    def root(path = nil)
      base = File.expand_path(File.dirname(__FILE__))
      path ? File.join(base, path) : base
    end
  end
end