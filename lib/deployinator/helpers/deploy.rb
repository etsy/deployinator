module Deployinator
  module Helpers
    # Public: helper methods to interact with deploy processes
    module DeployHelpers

        # Public: get a list of all currently running deploys
        #
        # Returns an array of hashes of the form {:stack => stackname, :stage
        # => stagename}
        def get_list_of_deploys
          ret = []
          raw = `pgrep -d, -l -f Deployinator`.strip.split(",")
          raw.each do |deploy|
            deploy = deploy.strip
            if deploy =~ /Deployinator - deploy (\S+?):(\S+?)$/
              ret << {:stack => $1, :stage => $2}
            end
          end
          ret
        end


        # Public: stop a running deploy indentified by stack and stage
        #
        # Parameters:
        #   stack - name of the stack
        #   stage - name of the stage
        #
        # Returns true if the deploy was stopped and false on error
        def stop_deploy(stack, stage)
          if deployname = get_deploy_process_title(stack,stage)
            return system("pkill -f '#{deployname}'")
          end
          false
        end

        # Public: get the activity status of the deploy for a certain stack
        # and stage
        #
        # Parameters:
        #   stack - name of the stack
        #   stage - name of the stage
        #
        # Returns true for a running deploy or false for a deploy that
        # is not running
        def is_deploy_active?(stack, stage)
          if deployname = get_deploy_process_title(stack,stage)
            return system("pgrep -c '#{deployname}'")
          end
          false
        end

        # Public: get the process title for the deployment process of a
        # specific stage in a stack
        #
        # Parameters:
        #   stack - name of the stack
        #   stage - name of the stage
        #
        # Returns the title as a string or nil on error
        def get_deploy_process_title(stack=nil, stage=nil)
          return nil if (stack.nil? or stage.nil?)
          "Deployinator - deploy #{stack}:#{stage}"
        end

    end
  end
end
