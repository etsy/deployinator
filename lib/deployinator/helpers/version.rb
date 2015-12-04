module Deployinator
  module Helpers
    module VersionHelpers
      # Public: wrapper function to get the short SHA of a revision. The function
      # checks retrieves the part of the string before the first dash. If the part
      # is a valid default git short rev, i.e. alphanumeric and length 7 it is
      # returned. For an invalid rev, nil is returned.
      #
      # ver - String representing the revision
      #
      # Returns the short SHA consisting of the alphanumerics until the first dash
      # or nil for an invalid version string
      def get_build(ver)
        # return the short sha of the rev
        the_sha = (ver || "")[/^([^-]+)/]
        # check that we have a default git SHA
        val = /^[a-zA-Z0-9]{7,}$/.match the_sha
        val.nil? ? nil : the_sha
      end
      module_function :get_build

      # Public: function to get the current software version running on a host
      #
      # host - String of the hostname to check
      #
      # Returns the full version of the current software running on the host
      def get_version(host)
        host_url = "https://#{host}/"
        get_version_by_url("#{host_url}version.txt")
      end
      module_function :get_version

      # Public: function to fetch a version string from a URL. The version string
      # is validated to have a valid format. The function calls a lower level
      # implementation method for actually getting the version.
      #
      # url - String representing where to get the version from
      #
      # Returns the version string or nil if the format is invalid
      def get_version_by_url(url)
        version = curl_get_url(url)
        val = /^[a-zA-Z0-9]{7,}-[0-9]{8}-[0-9]{6}-UTC$/.match version
        val.nil? ? nil : version.chomp
      end
      module_function :get_version_by_url

      # Public: this helper function wraps the actual call to get the contents of a
      # version file. This helps with reducing code duplication and also stubbing
      # out the actual call for unit testing.
      #
      # url - String representing the complete URL to query
      #
      # Returns the contents of the URL resource
      def curl_get_url(url)
        with_timeout 2, "getting version via curl from #{url}" do
          `curl -s #{url}`
        end
      end
      module_function :curl_get_url
    end
  end
end
