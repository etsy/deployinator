module Deployinator
  module Helpers
    module PluginHelpers
      attr_accessor :plugins

      def self.included(klass)
        @plugins = []
      end

      def register_plugins(stack)
        @plugins = []
        global_plugins = Deployinator.global_plugins
        unless global_plugins.nil? then 
          Deployinator.global_plugins.each do |klass|
            @plugins << Deployinator.const_get("#{klass}").new
          end
        end

        unless Deployinator.stack_plugins.nil? || Deployinator.stack_plugins[stack].nil? then
          Deployinator.stack_plugins[stack].each do |klass|
            @plugins << Deployinator.const_get("#{klass}").new
          end
        end
      end

      def notify_plugins(event, state)
        unless plugins.nil? then
          @plugins.each do |plugin|
            begin
              plugin.run(event, state)
            rescue => e
              raise "Error running plugin #{plugin} with exception #{e.to_s}"
            end
          end
        end
      end

      def raise_event(event, extra_state = {})
        state = extra_state
        state[:username] = @username
        state[:stack] = @stack
        state[:stage] = @method
        state[:timestamp] = Time.now.to_i
        notify_plugins(event, state)
      end
    end
  end
end
