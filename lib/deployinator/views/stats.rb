require 'json'
require 'time'
require './views/etsy-layout'

module Deployinator::Views
  class Stats < EtsyLayout

    @@get_these_stacks = ['web', 'photos', 'blog', 'search', 'xsearch', 'supergrep', 'graphite' ]
    @@ignore_these_stacks = ['webs','LOG MESSAGE', 'deploy', 'api', 'imagestorage' , 'storque', 'atlas' ]

    def deploys
      @deploys ||= begin
        log_to_hash({
          :no_global => false,
          :stack => @@get_these_stacks,
          :env => "production|search|prod",
          :extragrep => "Production deploy",
          :no_limit => true,
          :limit => 10000
        })
       end
        # note that the stack param will help but will send bring back extra lines that matched
    end

    def configs
      # around the start of 2012 config became its own stack (web_config)
      # we when looking for config deploys we want to check old (web) and new
      # (web_config) for charting. MAYHEM-357
       @configs ||= begin
        log_to_hash({
          :env => "config",
          :extragrep => "CONFIG PRODUCTION Deploy",
          :no_limit => false,
          :limit => 10000,
          :no_global => true,
          :stack => [ "web" , "web_config" ]
        })
      end
    end

    def timings
      deploys
    end

    def per_day
      # smush the config array into the deploy array
      # and goose the stack to appear as a config stack
      foo = configs.inject({}) do |h, cfg|
        cfg[:stack] = cfg[:env].downcase
        deploys.push(cfg)
      end

      original_zone = ENV["TZ"]
      ENV["TZ"] = "US/Eastern"

      early_day = Time.now.strftime("%Y-%m-%d")
      stack_days = deploys.inject({}) do |h, deploy|
        if deploy[:time] && deploy[:stack]
          if @@ignore_these_stacks.include?(deploy[:stack])
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

          next if @@ignore_these_stacks.include?(stack)
          day = Date.parse((Time.now - (day_seconds * days_ago)).strftime("%Y-%m-%d"))
          stack_days[stack][day] ||= 0
        end
      end

      n = stack_days.keys.map do |stack|
        next if @@ignore_these_stacks.include?(stack)

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