module Deployinator
  class Plugin
    def run(event, state)
      raise "Plugin: #{self.class} does not implement run method"
    end
  end
end
