module Deployinator::Views
  class LastPushes < Layout
    def pushes
      log_to_hash({
        :limit => @limit, :env => @dep_env, :stack => @stack,
        :no_global => true
      })
    end
  end
end
