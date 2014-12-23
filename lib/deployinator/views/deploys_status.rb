require 'deployinator/helpers/deploy'
require 'json'

module Deployinator::Views
  class DeploysStatus < Layout
    include Deployinator::Helpers::DeployHelpers
    
    self.template_file = "#{File.dirname(__FILE__)}/../templates/deploys_status.mustache"

    def current_deploys
      ret = []
      JSON.parse(get_list_of_deploys.to_json).each do |deploy|
        ret << { "stack" => deploy['stack'], "stage" => deploy['stage'] }
      end
      if (ret.length>0)
        ret
      else
        { "stack" => "alcohol", "stage" => "consuming" }
      end
    end
  end
end
