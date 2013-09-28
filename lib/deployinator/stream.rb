module Deployinator
  class Stream
    def initialize(app)
      @app = app
    end

    def call(env)
      dup._call(env)
    end

    def _call(env)
      status, headers, response = @app.call(env)
      if has_method?(env)
        init(env)
        @method = method(env)
        @arguments = (arguments(env) || {}).merge(:env => env)
        headers = {
          'Content-Type' => "text/html",
          'Cache-Control' => "private, max-age=0"
        }
        response = self
      end
      [status, headers, response]
    end

    def each(&block)
      tpl = open(Deployinator.root(['templates', 'stream.mustache']))
      before, after = tpl.read.split(/\{\{\s*yield\s*\}\}/)
      yield " " * 1024
      yield before

      set_block(&block)
      before_stream(@arguments)

      begin
        puts "calling #{@method} with #{@arguments.inspect}"
        output = self.send(@method, @arguments)
      rescue Exception => e
        yield "Exception!! #{e.message} / #{e.backtrace.inspect}"
        puts "Exception!! #{e.message} / #{e.backtrace.inspect}"
      end

      yield after
      after_stream(@arguments, output)
    end

    def method(env)
      env["method"]
    end

    def arguments(env)
      env["arguments"]
    end

    def has_method?(env)
      method(env)
    end
  end
end
