require "rubygems"
require "bundler"
Bundler.setup

base_dir = File.dirname(File.dirname(__FILE__))
$LOAD_PATH.unshift base_dir unless $LOAD_PATH.include? base_dir

require 'deployinator'

$LOAD_PATH.unshift Deployinator.root unless $LOAD_PATH.include? Deployinator.root
$LOAD_PATH.unshift Deployinator.root("lib") unless $LOAD_PATH.include? Deployinator.root('lib')

require 'pony'
require 'sinatra/base'
require 'mustache/sinatra'
require 'open4'

# Silence mustache warnings
module Mustache::Sinatra::Helpers
  def warn(msg); nil; end
end

# The magic of the helpers
ENV['DEPLOYINATOR_HELPER_PATH'] ||= Deployinator.root('helpers')
internal_helpers_dir = Deployinator.root(['lib', 'deployinator', 'helpers'])
(ENV['DEPLOYINATOR_HELPER_PATH'].split(':') + [internal_helpers_dir]).map do |helper_dir|
  Dir["#{helper_dir}/*.rb"].each do |file|
    require file
    the_mod = Deployinator::Helpers.const_get(Mustache.classify(File.basename(file, ".rb") + "Helpers"))
    Deployinator::Helpers.send(:include, the_mod)
    Deployinator::Helpers.send(:extend, the_mod)
  end
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
require_relative 'app'
require_relative 'helpers'
require_relative 'version'
require_relative 'svn'
require_relative 'stream'

require_relative 'views/layout'

# The magic of the stacks
ENV['DEPLOYINATOR_STACK_PATH'] ||= Deployinator.root(['stacks'])
ENV['DEPLOYINATOR_STACK_PATH'].split(':').map do |stack_dir|
  Dir["#{stack_dir}/*.rb"].each do |file|
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
end

require_relative 'views/view_helpers'

class Mustache
  include Deployinator::Helpers
  include Deployinator::Views::ViewHelpers
end

module Deployinator
  class Stream
    include Deployinator::Helpers
  end
end

# = Configuration settings

# Base config.
# Override in config/<environment>.rb
Deployinator.log_file = Deployinator.root(["log", "#{Deployinator.env}.log"])
Deployinator.domain = "myawesome.com"

Pony.options = {
  :to => "user@#{Deployinator.domain}"
}

# Load in the current environment and override settings
begin
  require Deployinator.root(["config", Deployinator.env])
rescue LoadError
end

# Ruby 1.8.6 is teh LAMEZ0Rz
unless Symbol.respond_to?(:to_proc)
  class Symbol
    def to_proc
      Proc.new { |obj, *args| obj.send(self, *args) }
    end
  end
end

unless String.respond_to?(:start_with?)
  class String
    def start_with?(str)
      self.index(str) == 0
    end
  end
end

