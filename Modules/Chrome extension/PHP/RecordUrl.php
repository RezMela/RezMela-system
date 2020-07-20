<?php
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
	$userId = $_GET['uid'];
	$bookMark = $_GET['url'];
	$description = $_GET['desc'];
	$titlecolor = $_GET['tcol'];
	$covercolor = $_GET['ccol'];
	$userIdsFilename = 'UserIds.txt';	
	$bookmarksFilename = 'Bookmarks.txt';
	$lockFilename = 'Lock.txt';
	
	$lf = fopen($lockFilename, "w+");
	flock($lf, LOCK_EX);
	fwrite($lf, $userId);
		
	if (grepfile($userIdsFilename, $userId)) {	// If it's a valid user id, process, otherwise ignore
		$bookmarkEntry = $userId . "|" . $bookMark . "|" . $description . "|" . $titlecolor . "|" . $covercolor . "\n";
		file_put_contents($bookmarksFilename, $bookmarkEntry, FILE_APPEND);
	}
	
	flock($lf, LOCK_UN);
	fclose($lf);	
	http_response_code(200);
?>
