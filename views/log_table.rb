module Deployinator::Views
  class LogTable < Layout
    def log_lines
      @params = @params.inject({}) {|p,(k,v)| p[k.intern] = v; p }
      log_to_hash({:no_limit => true}.merge(@params))
    end
    
    def show_counts?
      @params[:show_counts] == "true"
    end
  end
end
