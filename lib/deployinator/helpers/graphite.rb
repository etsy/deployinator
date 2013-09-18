module Deployinator
  module Helpers
    module GraphiteHelpers
    require 'socket'
      def graphite_plot(logString)
        if Deployinator.graphite_host
          s = TCPSocket.new(Deployinator.graphite_host,Deployinator.graphite_port || 2003)
          s.write "#{logString} #{Time.now.to_i}\n"
          s.close
        end
      end
    end
  end
end
