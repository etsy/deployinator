module Deployinator::Views
  class RunLogs < Layout

    self.template_file = "#{File.dirname(__FILE__)}/../templates/run_logs.mustache"

    PER_PAGE = 30

    # Internal: determines what the next page number is.
    #
    # Returns the next page number
    def next_page
      page = get_page
      num_run_logs = get_run_logs.count
      return (page+1)*PER_PAGE < num_run_logs ? page + 1 : false
    end


    # Internal: fetches the run_log files to be displayed in a list view
    #
    # Returns an array of hashes with name, time keys
    def files
      page = get_page
      offset = PER_PAGE * page
      get_run_logs(:limit => PER_PAGE, :offset => offset)
    end

    def get_page
      @params['page'].to_i || 0
    end

  end
end
