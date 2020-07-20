<?php

	$userId = $_GET['uid'];

	$bookmarksFilename = 'Bookmarks.txt';
	
	$lockFilename = 'Lock.txt';
	
	$lf = fopen($lockFilename, "w+");
	flock($lf, LOCK_EX);
	fwrite($lf, $userId);
	
	$lines = file($bookmarksFilename);
	if (file_exists($bookmarksFilename)) {	
		$file_changed = false;
		# Split each line up to search for our own data (so we can drop it and append the new)
		$data = array();
		foreach ($lines as $line_num => $line) {
			$parts = explode("|", $line);
			if ($parts[0] == $userId) {
				echo $line . "\n";
				$file_changed = true;
					
			} else {
				array_push($data, $line);
			} 
		}
		# write back
		if ($file_changed) {
			file_put_contents($bookmarksFilename, $data, LOCK_EX);
		}
	}
	flock($lf, LOCK_UN);
	fclose($lf);	
	exit(200);
?>
