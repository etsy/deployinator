module Deployinator
  module Helpers
    module GraphiteHelpers
      def graphite_plot(logString)
        g = Graphite.new
        g.host = Deployinator.graphite_host
        g.port = Deployinator.graphite_port || 2003
        g.push_to_graphite do |graphite|
          graphite.puts "#{logString} #{g.time_now}"
        end unless g.host.nil?
      end
    end
  end
end
