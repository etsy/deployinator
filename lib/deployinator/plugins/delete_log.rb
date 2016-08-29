require 'deployinator/plugin'
require 'deployinator/helpers'

=begin
This plugin enables deploys to optionally delete the log file they just generated.

Add the plugin to the stack as you normally would (either globally, or for that stack specifically).
And modify the return hash of the deploy method to include a truthy value for :should_delete_log

A great usecase for this functionality is with a 'cron deploy'. Imagine you have a deploy that
spins up every minute and checks whether it needs to actually perform an action or not. The vast majority
of the time, the deploy has nothing to do and generates an empty log. In those cases, you KNOW that the deploy
has nothing to do. So you tell the plugin to delete the log as not to clutter your Deployinator host with
thousands of empty log files as compared to only a few with actual actions.
=end

module Deployinator
  class DeleteLog < Plugin
    include Helpers

    def run(event, state)
      case event
      when :log_file_retired
        deploy = state[:deploy_instance]
        filename = state[:filename]

        if state[:should_delete_log] and not filename.to_s.empty?
          output = File.delete(
            RUN_LOG_PATH + filename,
          )

          #we set the filename to nil so that any subsequent log_and_stream's
          #don't accidentally recreate the log we were asked to delete
          deploy.filename = nil
        end
      end
    end
  end
end
