module Deployinator::Views
  class Log < Layout

    self.template_file = "#{File.dirname(__FILE__)}/../templates/log.mustache"
    
    def log_lines
      @params = @params.inject({}) {|p,(k,v)| p[k.intern] = v; p }
      puts @params
      log_to_hash({:no_limit => true}.merge(@params))
    end
  end
end
