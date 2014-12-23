module Deployinator::Views
  class LogTable < Layout

    self.template_file = "#{File.dirname(__FILE__)}/../templates/log_table.mustache"
    
    def log_lines
      @params = @params.inject({}) {|p,(k,v)| p[k.intern] = v; p }
      # this on is called from /log
      log_to_hash({:no_limit => true, :page => 1}.merge(@params))
    end

    def dashboards?
      false
    end

    def show_counts?
      @params[:show_counts] == "true"
    end

    def prev_page
      return unless @params && @params[:page]
      page = @params[:page].to_i
      if page && page > 1
        page - 1 
      else
        false
      end
    end

    def next_page
      page = @params[:page] ? @params[:page].to_i : 1
      page + 1
    end
  end
end
