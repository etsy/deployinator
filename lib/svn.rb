require 'time'

module SVN
  extend self
  
  URL  = "Svn url"
  USER = "deployinator-user"
  PASS = "password"
  
  def rev_times_path
    "/tmp/svn_rev_times.txt"
  end
  
  def time_from_file(rev)
    line = %x{grep "^#{rev}^" #{rev_times_path} 2>/dev/null}.chomp
    return nil if line.empty?
    line.split("^")[1]
  end
  
  def save_time_to_file(rev, time)
    %x{echo "#{rev}^#{time}" >> #{rev_times_path}} unless time.empty?
  end
  
  def time_of_rev(rev, ssh_cmd="ssh #{Deployinator.default_user}@host")
    unless time = time_from_file(rev)
      cmd = "#{ssh_cmd} svn info --no-auth-cache -r #{rev} #{URL} --username=#{USER} --password=#{PASS} --xml"
      time = %x{#{cmd}}[/<date>(.*)<\/date>/, 1]
      save_time_to_file(rev, time)
    end
    Time.parse(time)
  end
  
  def version_of(path, ssh_cmd="")
    svn_info(path, ssh_cmd)[/Revision: (\d+)/, 1].to_i
  end
  
  def svn_info(path, ssh_cmd)
    if ssh_cmd[/qa-deploy/]
      %x{#{ssh_cmd} 'cd #{path} && svn info'}
    else
      %x{#{ssh_cmd} svn info #{path}}
    end
  end

  def diff(path, ssh_cmd="")
      %x{#{ssh_cmd} svn diff #{path}}
  end

  def diff_no_context(path, ssh_cmd="")
      %x{#{ssh_cmd} svn diff --diff-cmd diff -x --unified=0 #{path}}
  end
  
  def checkout(path, to_dir="/tmp", ssh_cmd="")
    %x{#{ssh_cmd} svn checkout --no-auth-cache --username=#{USER} --password=#{PASS} #{path} #{to_dir}}
  end
  
  def update(to_dir="/tmp", ssh_cmd="")
    %x{#{ssh_cmd} svn update --no-auth-cache --username=#{USER} --password=#{PASS} #{to_dir}}
  end
  
  def checkin(message, from_dir="/tmp", ssh_cmd="", command_only=false)
    message = message.gsub(/'/, "\'")
    cmd = "#{ssh_cmd} cd #{from_dir} && svn ci --username=#{USER} --password=#{PASS} -m '#{message}' 2>&1"
    command_only ? cmd : %x{#{cmd}}
  end
  
  def export(path, ssh_cmd="")
    %x{#{ssh_cmd} svn cat --no-auth-cache --username=#{USER} --password=#{PASS} #{path}}
  end
end
