require 'deployinator'
require './views/etsy-layout'
module Deployinator::Views
  class Maintenance < Layout
    def additional_header_html
      <<-EOS
        #{super}
        <link rel="stylesheet" href="/css/maintenance.css" type="text/css" media="screen">
      EOS
    end
  end
end
