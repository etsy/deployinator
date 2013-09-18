require 'views/stats'

module Deployinator::Views
  class StatsLag < Stats
    # [
    #   {
    #     :stack => "web",
    #     :data  => [[34321, 20], [34323, 10]]
    #   }
    # ]
    def time_to_deploy
      d_times = deploys[0..400].inject({}) do |h, deploy|
        if deploy[:new] && deploy[:stack] && deploy[:time] && !github_info_for_stack.key?(deploy[:stack].intern)
          h[deploy[:stack]] ||= []
          h[deploy[:stack]] << [deploy[:new].to_i, deploy[:time] - SVN.time_of_rev(deploy[:new])]
        end
        h
      end
      d_times.map { |key, timings| {:stack => key, :data => timings.to_json} }
    end
  end
end
