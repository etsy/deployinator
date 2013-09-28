#!/usr/bin/env php
<?php

if (count($argv) < 2) { die("usage: $argv[0] r1 r2 path-to-repo\n"); }
$r1 = $argv[1];
$r2 = $argv[2];
$repo_path = (isset($argv[3])) ? $argv[3] : "./.git";
$should_email = (isset($argv[4]));

putenv("GIT_DIR=$repo_path");

$commits = array();
$patches = array();
$files = array();
$subject = "";

$git_commits = explode(chr(0) . "\n", trim(`git log --format="%h|%an|%ae|%at|%ai|%s|%b|%x00" $r1..$r2`));
foreach ($git_commits as $g_commit) {
  $pieces = explode("|", $g_commit);
  $commit = array(
    "sha1" => $pieces[0],
    "author" => "$pieces[1] <$pieces[2]>",
    "timestamp" => $pieces[4],
    "subject" => $pieces[5],
    "message" => $pieces[6],
  );

  $commits[] = $commit;
  $subject .= "[$pieces[0]] $pieces[2] - $pieces[5] ";
}

$git_files = trim(`git diff --stat=90,80 $r1..$r2`);
$files = explode("\n", $git_files);

$git_diff = trim(`git diff $r1..$r2`);

$diff_pattern = <<<EOF
/
diff\s\-\-git\sa(?P<name>[^\s]+)\sb[^\\n]+\\n

# extended status header lines
(?:new\sfile\smode\s(?P<new_file_mode>\d+)\\n)?
(?:old\smode\s(?P<old_mode>\d+)\\n)?
(?:new\smode\s(?P<new_mode>\d+)\\n)?
(?:deleted\sfile\smode\s(?P<deleted_file_mode>\d+)\\n)?
(?:copy\sfrom\s(?P<copy_from>\w+)\\n)?
(?:copy\sto\s(?P<copy_to>\w+)\\n)?
(?:rename\sfrom\s(?P<rename_from>\w+)\\n)?
(?:rename\sto\s(?P<rename_to>\w+)\\n)?

index\s(?P<oldsha>[\w]+)\.\.(?P<newsha>[\w]+)(?:\s(?P<mode>\d+))?\\n
(?P<patch>
\-\-\-\sa?(?P<oldname>[^\\n]+)\\n
\+\+\+\sb?(?P<newname>[^\\n]+)\\n
.+?
)(?=$|diff)
/sx
EOF;

if (preg_match_all($diff_pattern, $git_diff, $matches, PREG_SET_ORDER)) {
  foreach ($matches as $patch) {
    $patch["file"] = $patch["name"];

    $patches[] = $patch;
  }
}

# try to find repo name
preg_match("|/opt/github/repositories/(.*).git|", $repo_path, $repo_match);
$repo = isset($repo_match[1]) ? $repo_match[1] : null;

ob_start();

include "template_compare.php";

$output = ob_get_contents();
ob_end_clean();

echo $output;