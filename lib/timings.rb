class Module
  def alias_method_chain(target, feature)
    # Strip out punctuation on predicates or bang methods since
    # e.g. target?_without_feature is not a valid method name.
    aliased_target, punctuation = target.to_s.sub(/([?!=])$/, ''), $1
    yield(aliased_target, punctuation) if block_given?
    
    with_method, without_method = "#{aliased_target}_with_#{feature}#{punctuation}", "#{aliased_target}_without_#{feature}#{punctuation}"
    
    alias_method without_method, target
    alias_method target, with_method
    
    case
      when public_method_defined?(without_method)
        public target
      when protected_method_defined?(without_method)
        protected target
      when private_method_defined?(without_method)
        private target
    end
  end
end

timed_methods = []

require 'views/web'
require 'version'

timed_methods << [Deployinator::App::Views::ViewHelpers, ["log_lines", "head_build"]]
timed_methods << [Deployinator::App::Views::Web, ["push_topic", "head_build"]]
timed_methods << [Version, ["get_version"]]
timed_methods << [Deployinator::Helpers, [
  "stack_production_version", "stack_qa_version"
]]

timed_methods.each do |obj, meths|
  meths.each do |meth|
    obj.instance_eval do
      define_method "#{meth}_with_timing" do |*opts|
        start = Time.now
        retval = self.send("#{meth}_without_timing", *opts)
        time_taken = "%0.4f" % (Time.now - start)
        puts "Timing for #{obj}.#{meth}(#{opts.join(",")}): #{time_taken}"
        return retval
      end
      alias_method_chain meth, :timing
    end
  end
end

module Deployinator
  class Timing
    def initialize(app)
      @app = app
    end
    
    def call(env)
      dup._call(env)
    end
    
    def _call(env)
      start = Time.now
      status, headers, response = @app.call(env)
      puts "Total time for #{env['REQUEST_URI']}: #{Time.now - start}\n\n"
      [status, headers, response]
    end
  end
end
