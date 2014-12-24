require 'deployinator'
# Load in the current environment and override settings
begin
  require Deployinator.root(["config", "base"])
  require Deployinator.root(["config", Deployinator.env])
rescue LoadError
end
