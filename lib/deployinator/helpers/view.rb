module Deployinator
  module Helpers
    module ViewHelpers

      def username
        @username
      end

      def groups
        @groups.join(", ")
      end

      def my_url
        "http://#{@host}"
      end

      # TODO: assimilate with plugin
      def logout_url
        raise_event(:logout_url)
      end

      def my_entries
        log_entries(:stack => stack)
      end

      def log_lines
        log_to_hash(:stack => stack)
      end

      def log_to_hash(opts={})
        times = {}
        last_time = 0
        l = log_entries(opts).map do |ll|
          fields = ll.split("|")
          times[fields[1]] ||= []
          times[fields[1]] << fields[0]

          env = fields[1]

          utc_time = Time.parse(fields[0] + "UTC")
          {
            :timestamp => fields[0],
            :time      => utc_time,
            :time_secs => utc_time.to_i,
            :env       => env,
            :who       => fields[2],
            :msg       => hyperlink(fields[3]),
            :old       => fields[3] && fields[3][/old[\s:]*(\w+)/, 1],
            :new       => fields[3] && fields[3][/new[\s:]*(\w+)/, 1],
            :stack     => fields[4],
            :run_log_url => (fields.length < 6) ? false : fields[5],
            :diff_url => true,
            :from_timestamp      => utc_time.to_i - 1800, # + half hour before
            :until_timestamp     => utc_time.to_i + 1800, # + half hour after
            :diff_method => 'diff'
          }
        end
        times.each { |e,t| t.shift }
        l
      end
    end
  end
end
