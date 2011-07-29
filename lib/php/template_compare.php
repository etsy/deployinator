<!DOCTYPE html>
<html>
<head>
<title>Compare</title>
<meta http-equiv="content-type" content="text/html; charset=utf-8">
</head>
<style>
/*
del, ins, span { outline: 1px solid black; }
*/
</style>
<body style="font-family: helvetica,arial,sans-serif; font-size: 12px;">
<section>
<!-- extra -->
</section>
<section>
<? foreach ($commits as $commit): ?>
<div style="border: 1px solid #ccc; background: #eee; margin-bottom: 10px;">
<h3 style="background: #8F9CA8; color: white; margin: 0; padding: 5px;">
<p style='margin: 0;'>
<strong>Commit:</strong> <a style="color: #dfd;" target="_new" href="<? echo $viewer_url ?>/commit/<? echo $commit["sha1"]?>"><? echo $commit["sha1"] ?></a>
</p>
<p style='margin: 0;'>
<strong>Author:</strong> <? echo htmlentities($commit["author"]) ?> 
</p>
<p style='margin: 0;'>
<strong>Date:</strong> <? echo $commit["timestamp"] ?>
</p>
</h3>
<p style="background: white; padding: 5px; margin: 5px;">
<? echo htmlentities($commit["subject"]) ?><br>
<? echo htmlentities($commit["message"]) ?>
</p>
</div>
<? endforeach; ?>
</section>

<section style="margin-bottom: 10px">
<ul>
<? foreach ($files as $file): ?>
<li><? echo $file ?></li>
<? endforeach; ?>
</ul>
</section>

<section>
<? foreach ($patches as $patch):?>
<div style="border: 1px solid #ccc; background: #eee; margin-bottom: 10px;">
<h3 style="background: #8F9CA8; color: white; margin: 0; padding: 5px;"><? echo $patch["file"] ?></h3>
<pre style="margin: 5px; padding: 5px; overflow: auto; white-space: pre-wrap; font-family: 'Menlo', 'Andale Mono','Courier New',monospace; font-size: 11px;">
<? 
$last_tag = "";
foreach (explode("\n", $patch["patch"]) as $line) {
  $style = "";
  $tag = "";

  if (substr($line, 0, 3) == "@@ " || substr($line, 0, 4) == "--- " || substr($line, 0, 4) == "+++ ") {
    $tag = "small";
    $style = "background: white; color: #ccc; display: block; padding: 2px 5px 0 5px; margin-bottom: 4px;";
  } else {
    switch (substr($line, 0, 1)) {
    case "-";
      $tag = "del";
      $style = "display: block; text-decoration: none; padding: 2px 5px 0 5px; margin: 0; background: #fdd";
      break;
    case "+":
      $tag = "ins";
      $style = "display: block; text-decoration: none; padding: 2px 5px 0 5px; background: #dfd;";
      break;
    default:
      $tag = "span";
      $style = "display: block;";
    }
  }
  if ($last_tag && $last_tag != $tag) { echo "</$last_tag>"; }
  if ($last_tag != $tag) { echo "<$tag style=\"$style\">"; }
  echo htmlentities($line) . "\n";
  $last_tag = $tag;
}
?>
</pre>
</div>
<? endforeach; ?>
</section>
</body>
</html>
