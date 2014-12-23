require 'deployinator/helpers/git'
require 'deployinator/helpers/stack-tail'

module Deployinator
  module Views
    class Layout < Mustache
      include Deployinator::Helpers::GitHelpers, 
        Deployinator::Helpers::StackTailHelpers,
        Deployinator::Helpers::VersionHelpers

      @@internal_partials = ["log", "log_table", "generic_single_push", "scroll_control"]

      self.template_file = "#{File.dirname(__FILE__)}/../templates/layout.mustache"

      def self.partial(name)
        if @@internal_partials.include?(name.to_s)
          File.read("#{File.dirname(__FILE__)}/../templates/#{name.to_s}.mustache")
        else
          super
        end
      end

      def set_stack(stack)
        @stack = stack
      end

      def disabled_override
        @disabled_override
      end
    end
  end
end
