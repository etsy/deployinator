module Deployinator::Views
  class StackDown < Layout
    self.template_file = "#{File.dirname(__FILE__)}/../templates/stack_down.mustache"

    def additional_header_html
      <<-EOS
        #{super}
        <link rel="stylesheet" href="/css/maintenance.css" type="text/css" media="screen">
      EOS
    end

    def stack_info
      @stack_info
    end
  end
end
