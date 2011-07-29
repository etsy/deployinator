module Deployinator
  module Helpers
    module GitHelpers
      def git_bump_version(stack, version_dir, extra_cmd="sh -c")
        ts = Time.now.strftime("%Y%m%d-%H%M%S-%Z")
        # hack for now - need to talk to Matthew for a better way to do this
        #sha1 = %x{#{extra_cmd} cd #{checkout_root}/#{stack} && git fetch origin && git rev-parse --short refs/remotes/origin/master}
        sha1 = log_and_stream(%Q{#{extra_cmd} 'cd #{checkout_root}/#{stack} && git rev-parse --short HEAD'})
        sha1 = %x{#{extra_cmd} 'cd #{checkout_root}/#{stack} && git rev-parse --short HEAD'}
        version = "#{sha1.chomp}-#{ts}"

        log_and_stream "Setting #{version_dir}version.txt to #{version}"

        run_cmd %Q{#{extra_cmd} 'cd #{checkout_root}/#{stack} && echo #{version} > #{version_dir}version.txt'}
      end

      def git_freshen_clone(stack, extra_cmd="sh -c")
        run_cmd %Q{#{extra_cmd} 'cd #{checkout_root}/#{stack} && git fetch && git reset --hard origin/master'}
        yield "#{checkout_root}/#{stack}" if block_given?
      end

      def github_clone(stack, extra_cmd="sh -c")
        git_clone(stack, git_url(stack), extra_cmd)
      end

      def git_clone(stack, repo_url, extra_cmd="sh -c")
        run_cmd %Q{#{extra_cmd} 'cd #{checkout_root} && git clone #{repo_url} #{stack}'}
      end

      def git_url(stack, protocol="git")
        stack = stack.intern
        stack_git_meth = stack.to_s + "_git_repo_url"
        return self.send(stack_git_meth) if self.respond_to?(stack_git_meth)

        repo = github_info_for_stack[stack][:repository]
        repo += ".git" if protocol == "http"
        "#{protocol}://#{github_host}/#{github_info_for_stack[stack][:user]}/#{repo}"
      end

      def github_host
        Deployinator.github_host
      end

      def github_url
        "http://#{github_host}/"
      end

      def github_info_for_stack
        {
          :photos     => {:user => "Engineering", :repository => "Photos"},
          :blog       => {:user => "Engineering", :repository => "Blog"},
          :b2         => {:user => "Engineering", :repository => "Blog"},
          :web        => {:user => "Engineering", :repository => "Web"},
          :config     => {:user => "Engineering", :repository => "Web"},
          :dashboards => {:user => "Engineering", :repository => "Dashboards"},
          :search     => {:user => "Engineering", :repository => "Search"}
        }
      end
    end
  end
end
