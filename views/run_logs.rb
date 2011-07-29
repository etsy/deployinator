module Deployinator::Views
  class RunLogs < Layout
    def files
      glob = Deployinator::Helpers::RUN_LOG_PATH + "*.html"
      Dir.glob(glob).sort.reverse[0..300].map do |f|
        {
          :name => File.basename(f),
          :time => Time.at(f[/(\d{8,})/].to_i)
        }
      end
    end
  end
end
