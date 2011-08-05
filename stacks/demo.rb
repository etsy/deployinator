module Deployinator
  module Stacks
    module Demo
      def demo_git_repo_url
        "git://github.com/etsy/statsd.git"
      end

      def demo_git_checkout_path
        "#{checkout_root}/#{stack}"
      end

      def checkout_root
        "/tmp"
      end

      def demo_production_version
        %x{cat #{demo_git_checkout_path}/version.txt}
      end

      def demo_production_build
        Version.get_build(demo_production_version)
      end

      def demo_head_build
        %x{git ls-remote #{demo_git_repo_url} HEAD | cut -c1-7}.chomp
      end

      def demo_production(options={})
        old_build = Version.get_build(demo_production_version)

        git_cmd = old_build ? :git_freshen_clone : :github_clone
        send(git_cmd, stack, "sh -c")

        git_bump_version stack, ""
        
        build = demo_head_build

        run_cmd %Q{echo "ssh host do_something"}

        log_and_stream "Done!<br>"

        # log this deploy / timing
        log_and_shout(:old_build => old_build, :build => build, :send_email => true)
      end
    end
  end
end
