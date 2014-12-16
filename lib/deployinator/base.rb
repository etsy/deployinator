require "rubygems"
require "bundler"
Bundler.setup

require "socket"
require 'pony'

require 'sinatra/base'
require "mustache/sinatra"

# Silence mustache warnings
module Mustache::Sinatra::Helpers
  def warn(msg); nil; end
end

# ruby Std lib
require 'open3'
require 'benchmark'
require 'net/http'
require 'open-uri'
require 'uri'
require 'time'
require 'json'
require 'resolv'

require "deployinator"
require "deployinator/helpers"

class Mustache
  include Deployinator::Helpers
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
