Deployinator.log_file = "test.log"

Deployinator.issue_tracker = proc do |issue|
  "https://github.com/example/repo/issues/#{issue}"
end