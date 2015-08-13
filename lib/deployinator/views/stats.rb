require 'json'
require 'time'

module Deployinator::Views
  class Stats < Layout

    self.template_file = "#{File.dirname(__FILE__)}/../templates/stats.mustache"

    @@ignored_stacks = Deployinator.stats_ignored_stacks

    def deploys
      @deploys ||= begin
        log_to_hash({
          :no_global => false,
          :stack => Deployinator.stats_included_stacks,
          :env => "production|search|prod",
          :extragrep => Deployinator.stats_extra_grep,
          :no_limit => true,
          :limit => 10000
        })
       end
        # note that the stack param will help but will send bring back extra lines that matched
    end

    def timings
      deploys
    end

    def per_day
      original_zone = ENV["TZ"]
      ENV["TZ"] = "US/Eastern"

      early_day = Time.now.strftime("%Y-%m-%d")
      stack_days = deploys.inject({}) do |h, deploy|
        if deploy[:time] && deploy[:stack]
          if @@ignored_stacks.include?(deploy[:stack])
            # puts "SKIPPING " + deploy[:stack]
            # something breaks if you just next here so don't
          else
            day = Date.parse(deploy[:time].localtime.strftime("%Y-%m-%d"))
            early_day = day if day.to_s < early_day.to_s
            h[deploy[:stack]] ||= {}
            h[deploy[:stack]][day] ||= 0
            h[deploy[:stack]][day] += 1
          end
        end
        h
      end

      # fill in zero days
      day_seconds = 24 * 60 * 60
      (0..((Time.now - Time.parse(early_day.to_s)) / day_seconds).to_i).each do |days_ago|
        stack_days.keys.each do |stack|

          next if @@ignored_stacks.include?(stack)
          day = Date.parse((Time.now - (day_seconds * days_ago)).strftime("%Y-%m-%d"))
          stack_days[stack][day] ||= 0
        end
      end

      n = stack_days.keys.map do |stack|
        next if @@ignored_stacks.include?(stack)

        data = []
        json = []
        stack_days[stack].sort.reverse.each do |d,c|
          data << {:date => d, :count => c}
          json << [d.strftime("%s").to_i * 1000, c]
        end
        {:stack => stack, :data => data, :json => json.to_json}
      end

      ENV["TZ"] = original_zone

      n
    end
  end
end
