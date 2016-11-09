require "rubygems"
require "bundler"
Bundler.setup

require 'deployinator'

$LOAD_PATH.unshift Deployinator.root unless $LOAD_PATH.include? Deployinator.root
$LOAD_PATH.unshift Deployinator.root("lib") unless $LOAD_PATH.include? Deployinator.root("lib")

require 'deployinator/config'

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

require "deployinator/helpers"
require "deployinator/views/layout"
require "deployinator/views/index"
require "deployinator/helpers/view"
require "deployinator/app"

class Mustache
  include Deployinator::Helpers,
    Deployinator::Helpers::ViewHelpers
end

# Ruby 1.8.6 is teh LAMEZ0Rz
unless Symbol.method_defined?(:to_proc)
  class Symbol
    def to_proc
      Proc.new { |obj, *args| obj.send(self, *args) }
    end
  end
end

unless String.method_defined?(:start_with?)
  class String
    def start_with?(str)
      self.index(str) == 0
    end
  end
end
