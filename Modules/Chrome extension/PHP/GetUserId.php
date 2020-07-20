<?php

/* 
	Format of user IDs file entry is <grid>|<uname>|<id>| (note trailing fs for grepping)
*/
	function makeid() {
		$letter1 = chr(rand(65, 90));	// A-Z
		$number = rand(10000, 99999);	// five-digit number
		$letter2 = chr(rand(65, 90));	// A-Z
		return($letter1 . $number . $letter2);		// X99999X
	}
	function grepfile($filename, $searchstring) {
		$handle = fopen($filename, 'r');
		$retval = FALSE; // until proven otherwise
		while (($buffer = fgets($handle)) !== false) {
			if (strpos($buffer, $searchstring) !== false) {
				$retval = TRUE;
				break;
			}      
		}
		fclose($handle);
		return($retval);
	}
	$grid = $_GET['grid'];
	$userName = $_GET['uname'];
	$userId = "";
	$userIdsFilename = 'UserIds.txt';
	$lockFilename = 'Lock.txt';
	
	$lf = fopen($lockFilename, "w+");
	flock($lf, LOCK_EX);
	fwrite($lf, $userId);
	
	if (file_exists($userIdsFilename)) {
		$lines = file($userIdsFilename);
		foreach ($lines as $line_num => $line) {
			$parts = explode("|", $line);
			if ($parts[0] == $grid && $parts[1] == $userName) {
				$userId = $parts[2];
			}
		}
	}
	# write back if necessary
	if ($userId == "") {	// if the ID wasn't found, we make one
		do {
			$userId = makeid();
		} while (grepfile($userIdsFilename, "|" . $userId . "|"));	// keep trying if it exists already
		$line = $grid . "|" . $userName . "|" . $userId . "|" . "\n";
		file_put_contents($userIdsFilename, $line, FILE_APPEND);
	}
	flock($lf, LOCK_UN);
	fclose($lf);
	
	echo $userId . "\n";
?>
