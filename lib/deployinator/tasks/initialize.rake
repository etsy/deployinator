#
# Project Directory Initialization and new stack creation stubs
#

require 'erb'

TEMPLATE_PATH="#{File.dirname(__FILE__)}/../../../templates/"

namespace :deployinator do

  desc "Initialize the project root for your deployinator instance"
  task :init, :company do |t, args|
    if args[:company].nil?
      puts "You need to specify a company name for your classes"
      puts "for example: rake deployinator:init[Etsy]"
      exit 1
    end

    company = args[:company]
    mkdir_p("lib")

    template("#{TEMPLATE_PATH}app.rb.erb", "lib/app.rb", binding)
    template("#{TEMPLATE_PATH}config.ru.erb", "config.ru", binding)
  end

  desc "Create a new stack. usage: rake deployinator:new_stack[stack_name]"
  task :new_stack, :stack do |t, args|
    require 'mustache/sinatra'
    if args[:stack].nil?
      puts "You need to specify at least a stack name"
      puts "for example: rake deployinator:init[user_facing_site]"
      exit 1
    end

    stack = args[:stack]
    mustache_class = Mustache.classify(stack)
    user = args[:user]
    repo = args[:repository]

    if File.exists?("stacks/#{stack}.rb") then
      puts "Stack already exists!"
      exit 2
    end

    mkdir_p("stacks")
    mkdir_p("config")
    mkdir_p("log")
    mkdir_p("run_logs")
    mkdir_p("helpers")
    mkdir_p("views")
    mkdir_p("templates")

    template("#{TEMPLATE_PATH}stack.rb.erb", "stacks/#{stack}.rb", binding)
    template("#{TEMPLATE_PATH}helper.rb.erb", "helpers/#{stack}.rb", binding)
    template("#{TEMPLATE_PATH}view.rb.erb", "views/#{stack}.rb", binding)
    cp("#{TEMPLATE_PATH}template.mustache", "templates/#{stack}.mustache")
    touch("log/deployinator.log")
    touch("log/deployinator-timing.log")
    touch("log/development.log")
    touch("config/base.rb")
  end

  def template(source, target, scope)
    unless File.exist?(target) then
      erb = ERB.new(File.read(source))
      File.open(target, "w") do |f|
        f.puts erb.result(scope)
      end
    end
  end
end
