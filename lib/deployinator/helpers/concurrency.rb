require 'celluloid'
require 'celluloid/autostart'

module Deployinator
  module Helpers
    module ConcurrencyHelpers
      extend Celluloid
      # Hash of future objects that have been instantiated so far
      @@futures = {}
      # Public: run block of code in parallel
      #
      # Returns Handle to future object created
      def run_parallel(name, &block)
        name = name.to_sym
        if reference_taken? name
          raise DuplicateReferenceError, "Name #{name} already taken for future."
        end
        log_and_stream '</br>Queueing  execution of future: ' + name.to_s + '</br>'
        @@futures[name] = Celluloid::Future.new do
          # Set filename for thread
          runlog_filename(name)
          # setting up separate logger
          log_and_stream '</br>Starting execution of future: ' + name.to_s + '</br>'
          block.call
        end
        @@futures[name]
      end



      
      # Public: check if the reference name for future is taken
      #
      # Returns boolean 
      def reference_taken?(name)
        return @@futures.has_key?(name)
      end
      
      # Public: returns the value of the code block execution
      # This also sends all the logged data in stream back to main 
      # log file and removes the temporary log file created for the thread
      # Returns the return value of the last line executed in block 
      def get_value(future, timeout=nil)
        if @filename
          file_path = "#{RUN_LOG_PATH}" + runlog_thread_filename(future)
          return_value = @@futures[future.to_sym].value(timeout)
          log_and_stream File.read(file_path) 
          File.delete(file_path) if File.exists?(file_path)
          return_value
        else
          @@futures[future.to_sym].value 
        end
      end
      
      # Public: returns the values of the specified futures
      #
      # Returns hash of values
      def get_values(*futures)
        value_hash = {}
        futures.each do |future|
          value_hash[future] = get_value(future)
        end
        value_hash
      end

      class DuplicateReferenceError < StandardError
      end
    end
  end
end
