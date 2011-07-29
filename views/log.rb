module Deployinator::Views
  class Log < Layout
    # def log_lines
    #   last_time = 0
    #   log_entries(:all => true).map do |ll|
    #     fields = ll.split("|")
    #     r = {
    #       :timestamp => fields[0],
    #       :last_time => last_time,
    #       :env       => fields[1],
    #       :who       => fields[2],
    #       :msg       => fields[3],
    #       :old       => fields[3] && fields[3][/old[\s:]*(\d+)/, 1],
    #       :new       => fields[3] && fields[3][/new[\s:]*(\d+)/, 1]
    #     }
    #     last_time = fields[0]
    #     r
    #   end
    # end
    
    def log_lines
      @params = @params.inject({}) {|p,(k,v)| p[k.intern] = v; p }
      log_to_hash({:no_limit => true}.merge(@params))
    end
  end
end
