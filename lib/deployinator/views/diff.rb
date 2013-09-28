module Deployinator::Views
  class Diff < Layout
    def paths
      @paths
    end

    def r1
      @r1
    end
    
    def r2
      @r2
    end
    
    %w[date1 date2].each do |d|
      define_method "#{d}_raw" do
        instance_variable_get("@#{d}") || Time.gmdate
      end
      
      define_method "#{d}_timestamp" do
        send("#{d}_raw").to_i
      end

      define_method "#{d}" do
        send("#{d}_raw").strftime("%Y-%m-%d %H:%M:%S")
      end
    end
  end
end
