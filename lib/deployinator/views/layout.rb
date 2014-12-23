
require 'deployinator/helpers/git'
require 'deployinator/helpers/stack-tail'

module Deployinator
  module Views
    class Layout < Mustache
      include Deployinator::Helpers::GitHelpers, 
        Deployinator::Helpers::StackTailHelpers

      self.template_file = File.expand_path("../templates/layout.mustache")

      def set_stack(stack)
        @stack = stack
      end

      def disabled_override
        @disabled_override
      end
    end
  end
end
