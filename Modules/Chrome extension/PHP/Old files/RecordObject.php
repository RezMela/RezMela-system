<?php

	$gridId = $_GET['gid'];
	$objectId = $_GET['oid'];
	$objectUserName = $_GET['uname'];

	$objectsFilename = 'Objectsfile'.$gridId.'.txt';
	$lockFilename = 'Lock'.$gridId.'.txt';
	# don't forget lock file stuff

	$lines = file($objectsFilename);
	
	# Split each line up to search for our own data (so we can drop it and append the new)
	$data = array();
	foreach ($lines as $line_num => $line) {
		$parts = explode("|", $line);
		$keepthisline = true;		# by default, we're going to keep the line in the data
		$findpos = array_search($objectId, $parts);	# is it a line for the same object?
		/* gotcha alert:
		we have to use '!== false' to test for successful search because PHP is 
		silly (mixup between 0 index and false return value). 
		*/
		if ($findpos !== false) {		
			$keepthisline = false;
		} elseif ($objectUserId != "") { # if not, and we're logging in, is it a line for the same user?
			$findpos = array_search($objectUserId, $parts);
			if ($findpos !== false) {
				$keepthisline = false;
			}
		}
		if ($keepthisline) { # if it's nothing to do with our data, we don't need to drop it
			array_push($data, $line);
		} 
	}
	# If there is a user name, add us to the data
	if ($objectUserName != "") {
		echo "\nLogged in " . $objectUserName;
		$newline = implode("|", array($objectId, $objectUserName));
		$data[] = $newline . "\n";	 # append new line to end of data
	} else {
		echo "\nLogged out";
	}
	

	# write back
	file_put_contents($objectsFilename, $data, LOCK_EX);
	/*
	echo "\nData written:";
	#var_dump($data);
	foreach ($data as $line_num => $line) {
		echo "\n" . $line_num . ": " . $line;
	}
	$reread = file($objectsFilename);
	echo "\nwill read as " . count($reread) . " lines";
	*/
?>
