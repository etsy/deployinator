module Deployinator
  module Version
    extend self

    def get_build(ver)
      (ver || "")[/^([^-]+)/]
    end

    def get_version(host)
      host = "#{host}.etsy.com" if host.match(/[A-Za-z]/)
      host_url = "http://#{host}/"
      `curl -s #{host_url}version.txt`.chomp
    end
  end
end
