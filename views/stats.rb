require 'json'
require 'time'

module Deployinator::Views
  class Stats < Layout
    def deploys
      @deploys ||= begin
        log_to_hash({
          :no_global => true, :env => "production",
          :no_limit => true
          # :limit => 200
        })
      end
    end
    
    def timings
      deploys
    end
    
    def per_day
      early_day = Time.now.strftime("%Y-%m-%d")
      stack_days = deploys.inject({}) do |h, deploy|
        if deploy[:time] && deploy[:stack]
          original_zone = ENV["TZ"]
          ENV["TZ"] = "US/Eastern"
          day = Date.parse(deploy[:time].localtime.strftime("%Y-%m-%d"))
          early_day = day if day.to_s < early_day.to_s
          ENV["TZ"] = original_zone
          h[deploy[:stack]] ||= {}
          h[deploy[:stack]][day] ||= 0
          h[deploy[:stack]][day] += 1
        end
        h
      end

      # fill in zero days
      day_seconds = 24 * 60 * 60
      (0..((Time.now - Time.parse(early_day.to_s)) / day_seconds).to_i).each do |days_ago|
        stack_days.keys.each do |stack|
          day = Date.parse((Time.now - (day_seconds * days_ago)).strftime("%Y-%m-%d"))
          stack_days[stack][day] ||= 0
        end
      end

      n = stack_days.keys.map do |stack|
        data = []
        json = []
        stack_days[stack].sort.reverse.each do |d,c|
          data << {:date => d, :count => c}
          json << [d.strftime("%s").to_i * 1000, c]
        end
        {:stack => stack, :data => data, :json => json.to_json}
      end
    end
  end
end
