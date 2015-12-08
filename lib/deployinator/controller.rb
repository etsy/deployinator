require 'deployinator'
require 'deployinator/helpers'
require 'deployinator/helpers/version'
require "deployinator/helpers/plugin"

module Deployinator

  # Public: this class represents the Deploy object with all the properties
  # the different helper and stack methods need to do the deploy. It is
  # basically an almost empty class and gets all of its functionality by the
  # modules it includes/extends based on the stack we are deploying.
  class Deploy
    include Deployinator::Helpers,
      Deployinator::Helpers::VersionHelpers,
      Deployinator::Helpers::PluginHelpers

    # Public: initialize the deploy class with instance variables that are
    # needed by the deploy methods, runlog helpers and all that
    #
    # Params:
    #   args - hash which at least has the following fields:
    #          { :username => "name of the person that is deploying",
    #            :stack => "the name of the stack to deploy",
    #            :stage => "stage of the stack to deploy"
    #          }
    #
    # Returns the runlog filename
    def initialize(args)
      @deploy_start_time = Time.now.to_i
      @start_time = Time.now.to_i
      @username = args[:username]
      @groups = args[:groups]
      @host     = `hostname -s`
      @stack = args[:stack]
      @method = args[:method]
      @filename = "#{@deploy_start_time}-#{@username}-#{args[:method]}.html"
      @deploy_time = Time.now.to_i

      # This gets the runlog output on the console; is used by log_and_stream
      @block = args[:block] || Proc.new do |output|
        $stdout.write output.gsub!(/(<[^>]*>)|\n|\t/m) {" "}
        $stdout.write "\n"
      end
    end

    def get_filename
      @filename
    end

    def get_deploy_time
      @deploy_time
    end
  end

  # Public: the main Controller class knows how to extract options from the
  # options argument it gets passed from its run method and then prepares the
  # Deploy class to be ready to deploy.
  class Controller

    # Public: get the correct method name for the stage to deploy. This allows us to
    # call things princess and prod even though the methods in the stacks have crazy
    # names.
    #
    # Params:
    #   stack - the name of the stack to deploy
    #   stage - the stage of the stack to deploy
    #
    # Returns the name of the deploy method as a String which then can be sent
    # to the Deploy class
    def stage_to_method(stack, stage)
      "#{stack}_#{stage}"
    end

    # Public: run the actual deploy from the given parameters
    #
    # Params:
    #   options - hash that includes at least the following fields:
    #             { :username => "name of the user that is deploying",
    #               :stack => "name of the stack to deploy",
    #               :stage => "name of the stage of the stack to deploy"
    #             }
    #
    # Returns nothing
    def run(options)
      options[:method] = stage_to_method(options[:stack], options[:stage])
      if options[:method].nil?
        raise "No method defined for me to call: #{options[:stack]}, #{options[:stage]}"
      end

      # config pus needs :env populated here
      options[:env] = {
        :username => options[:username]
      }

      if Deployinator.get_stacks.include?(options[:stack])
        require "stacks/#{options[:stack]}"
        klass = "#{Mustache.classify(options[:stack])}Deploy"
        deploy_class = Deployinator::Stacks.const_get("#{klass}")
      else
        raise "No such stack #{options[:stack]}"
      end

      deploy_instance = deploy_class.new(options)
      deploy_instance.register_plugins(options[:stack])

      locked = deploy_instance.lock_pushes(options[:stack], options[:username], options[:method])

      unless locked
        return deploy_instance
      end

      @start_time = Time.now
      deploy_instance.log_and_stream "Push started at #{@start_time.to_i}\n"
      deploy_instance.log_and_stream "Calling #{options[:method]}\n";
      deploy_instance.link_stack_logfile(deploy_instance.get_filename, options[:stack])

      deploy_instance.raise_event(:deploy_start)

      begin
        state = deploy_instance.send(options[:method], options)
      rescue Exception => e
        deploy_instance.log_error("There was an exception during this deploy. Aborted!", e)
        deploy_instance.raise_event(:deploy_error, {:exception => e})
      end

      if state.nil? || !state.is_a?(Hash)
        state = {}
      end
      deploy_instance.raise_event(:deploy_end, state)

      if options[:method].match(/config_push/)
        env = options[:method].match(/prod/) ? "production" : "princess"
      elsif options[:method].match(/force_builda/)
        env = "force asset rebuild"
      else
        env = options[:method][/(dev|qa|production|princess|prod|webs|stage|config)/i, 1] || "other"
        env = "production" if env.match(/prod|webs/)
      end

      # display a message that the deploy is done and call the JavaScript
      # deploy done function
      msg = "<h4>#{env.to_s.upcase} deploy in #{options[:stack]} stack complete</h4>"
      deploy_instance.log_and_stream(msg+"<p class='output'>")
      deploy_instance.log_and_stream("<script id='deploy-done'>window.deploy_done('#{msg}', '#{options[:stage]}');</script>")

      deploy_instance.unlock_pushes(options[:stack])
      deploy_instance.move_stack_logfile(options[:stack])

      return deploy_instance
    end
  end
end
