module Deployinator
  module Helpers
    module DshHelpers
      def dsh_fanout
        @dsh_fanout || 30
      end

      def run_dsh(groups, cmd, &block)
        groups = [groups] unless groups.is_a?(Array)
        dsh_groups = groups.map {|group| "-g #{group} "}
        run_cmd %Q{ssh #{Deployinator.default_user}@#{deploy1_host} dsh #{dsh_groups} -r ssh -F #{dsh_fanout} "#{cmd}"}, &block
      end

      def run_single_dsh(cmd, host="web0041")
        run_cmd %Q{ssh #{Deployinator.default_user}@#{deploy1_host} dsh -m #{host} "#{cmd}"}
      end
      
      def qa_hosts_for(group)
        @qa_hosts_for ||= {}
        @qa_hosts_for[group] ||= begin
          hosts = `ssh #{Deployinator.default_user}@#{qa_deploy_host} cat /home/#{Deployinator.default_user}/.dsh/group/#{group}`.chomp
          hosts.split("\n").join(",")
        end
      end

      def hosts_for(group)
        @hosts_for ||= {}
        @hosts_for[group] ||= begin
          hosts = `ssh #{Deployinator.default_user}@#{deploy1_host} cat /home/#{Deployinator.default_user}/.dsh/group/#{group}`.chomp
          hosts.split("\n").join(",")
        end
      end
    end
  end
end
