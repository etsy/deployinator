module Deployinator
  module Helpers
    # Public: helper methods to stack tailer
    module StackTailHelpers
      # This is used to make sure the front end javascript loaded matches the 
      # same backend code for the deployinator tailer. Increment this only if
      # you make protocol changes for the tailer
      #
      # Version format: Stack Tailer 1.X - meme name
      # History: 1.0 - All Your Base
      #   Introduced versions
      STACK_TAIL_VERSION = "Stack Tailer 1.0 - All Your Base"

      # So deployinator can get at this
      def stack_tail_version
        STACK_TAIL_VERSION
      end

      # This is so the tailer can access this method without having to send()
      # the method into scope. If there is a better way to do this please let
      # me know
      def self.get_stack_tail_version
        STACK_TAIL_VERSION
      end

      # Returns the websocket port for the stack tailer
      def stack_tail_websocket_port
        Deployinator.app_context['stack_tailer_port']
      end
    end
  end
end
