#
# Project Directory Initialization and new stack creation stubs
#

require 'erb'

if defined?(ENV['TEMPLATE_PATH'])
  template_list = [ "app.rb.erb", "config.ru.erb", "helper.rb.erb",
                  "stack.rb.erb", "template.mustache", "view.rb.erb" ]

  custom_templates = ENV['TEMPLATE_PATH']

  #Prevent accidents / annoyances
  custom_templates << '/' unless custom_templates.end_with?('/')

  # Test for core templates in custom path
  template_list.each do |template|
    if File.exist?("#{custom_templates}#{template}")
    else
      puts "#{custom_templates}#{template} is missing."
      puts "This is a required template."
      exit 1
    end
  end

  TEMPLATE_PATH="#{custom_templates}"
else
  TEMPLATE_PATH="#{File.dirname(__FILE__)}/../../../templates/"
end

namespace :deployinator do

  desc "Initialize the project root for your deployinator instance"
  task :init, :company do |t, args|
    if args[:company].nil?
      puts "You need to specify a company name for your classes."
      puts "for example: rake deployinator:init[Etsy]"
      exit 1
    end

    company = args[:company]
    company[0] = company[0].capitalize
    mkdir_p("lib")
    mkdir_p("stacks")
    mkdir_p("config")
    mkdir_p("log")
    mkdir_p("run_logs")
    mkdir_p("helpers")
    mkdir_p("views")
    mkdir_p("templates")

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
    # Enfore underscore and no camelcase
    stack = stack.gsub(/([A-Z]+)([A-Z][a-z])/,'\1_\2').
       gsub(/([a-z\d])([A-Z])/,'\1_\2').
       tr("-", "_").
       downcase
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
