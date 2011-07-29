module Deployinator
  module Helpers
    module DemoHelpers
      def log_host
        "sh -c"
      end

      def log_path
        "#{`pwd`.chomp}/log/deployinator.log"
      end

      def timing_log_path
        "#{`pwd`.chomp}/log/deployinator-timing.log"
      end

      def auth_url
        "http://your-sso-url/"
      end
    end
  end
end
