require 'deployinator/version'
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

    # Hostname where deployinator runs
    attr_accessor :hostname

    # Default username for passwordless ssh
    attr_accessor :default_user

    # Bug or issue tracker - proc that takes the issue id as an argument
    # ex: Deployinator.issue_tracker = proc {|issue| "http://foo/browse/#{issue}"}
    attr_accessor :issue_tracker

    # a hash for context specifics settings (test,dev,production) of deployinator itself
    attr_accessor :app_context

    attr_accessor :git_sha_length

    # is a log file defined?
    def log_file?
      log_file
    end

    # Running environment for deployinator
    # This is taken from RACK_ENV or RAILS_ENV
    # *note* this is different from deployinator's concept of stacks/environments
    def env
      ENV["RACK_ENV"] || ENV["RAILS_ENV"] || "development"
    end

    # Base root path
    # Takes an optional argument of a string or array and returns the path(s)
    # From the root of deployinator
    def root(path = nil)
      base = File.expand_path(File.dirname(__FILE__))
      path ? File.join(base, path) : base
    end

    # Gets all the stack files in the stack directory
    def get_stack_files
      Dir[Deployinator.root(["stacks", "*.rb"])]
    end

    # Gets all the stack names without the .rb extension
    def get_stacks
      self.get_stack_files.sort.map do |file|
        File.basename(file, ".rb")
      end
    end
  end
end
