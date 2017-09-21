module Deployinator
  module Helpers
    module PluginHelpers
      attr_accessor :plugins
      @plugins = []

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
        ret = nil
        unless plugins.nil? then
          @plugins.each do |plugin|
            begin
              new_ret = plugin.run(event, state)
              if ret.nil? then
                ret = new_ret
              end
            rescue => e
              raise "Error running plugin #{plugin.class.name} with exception #{e.to_s}"
            end
          end
        end
        ret
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
