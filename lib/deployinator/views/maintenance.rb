module Deployinator::Views
  class Maintenance < Layout
    self.template_file = "#{File.dirname(__FILE__)}/../templates/maintenance.mustache"
    def additional_header_html
      <<-EOS
        #{super}
        <link rel="stylesheet" href="/css/maintenance.css" type="text/css" media="screen">
      EOS
    end

    def maintenance_contact
      Deployinator.maintenance_contact
    end
  end
end
