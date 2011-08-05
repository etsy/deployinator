module Deployinator
  module Views
    module ViewHelpers
      include Version

      HEADER_URL_EXCLUDE_STACKS = %w[web stats atlas api]

      def push_order
        %w[production]
      end

      def username
        @username
      end

      def groups
        @groups.join(", ")
      end

      def my_url
        "http://#{@host}"
      end

      def logout_url
        "http://#{auth_url}?logout=true&return=#{my_url}"
      end

      def current_stack_url
        if (stack)
          destination = (!HEADER_URL_EXCLUDE_STACKS.include?stack) ? stack : ""
        else
          destination = ""
        end
        "http://#{@host}/#{destination}"
      end

      def allowed_to_push_to_prod?
        @groups.include?("deploy-prod")
      end

      def my_entries
        log_entries(:stack => stack)
      end

      def last_prod_time
        last_prod = my_entries.find {|f| f.match(/\|PRODUCTION|LIST\|/)} || ""
        last_prod[/(\d{4}-\d{2}-\d{2}\s\d{2}:\d{2}:\d{2})/, 1]
      end

      def log_lines
        log_to_hash(:stack => stack)
      end

      def viewvc_dir
        diff_paths_for_stack[stack.intern]
      end

      def irc_topic(channel)
        return "" if @local
        `ssh #{Deployinator.irc_log_host} cat /tmp/#{channel}.topic`.chomp
      end
    end
  end
end
