<?php

ini_set("include_path", '/home/handylff/php:' . ini_get("include_path") );
function callCurl($url, $data)
{
    $ch = curl_init();
	curl_setopt($ch, CURLOPT_URL, $url); 
    curl_setopt($ch, CURLOPT_POST, false);
    //curl_setopt($ch, CURLOPT_POSTFIELDS, http_build_query($data));
	//curl_setopt($ch, CURLOPT_HEADER, true);
	curl_setopt($ch, CURLOPT_HEADER, false);
    //curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
	//curl_setopt( $ch, CURLOPT_USERAGENT, "Mozilla/1.22 (compatible; MSIE 10.0; Windows 3.1)");
	//curl_setopt($ch, CURLOPT_PORT, 9000);
    $response = curl_exec($ch);
	if ($response == false) echo "CURL exec failed";
    curl_close($ch);
    return $response;
}
function cURLcheckBasicFunctions() 
{ 
  if( !function_exists("curl_init") && 
      !function_exists("curl_setopt") && 
      !function_exists("curl_exec") && 
      !function_exists("curl_close") ) return false; 
  else return true; 
} 
	echo "Started";
	if( !cURLcheckBasicFunctions() ) {
		echo "UNAVAILABLE: cURL Basic Functions";
		exit;
	}		
	$gridId = $_GET['gid'];
	$objectUserName = $_GET['uname'];
	$objectsFilename = 'Objectsfile'.$gridId.'.txt';
	$found_user = false;
	$lines = file($objectsFilename);
	# Split each line up to search for this user's data
	foreach ($lines as $line_num => $line) {
		$parts = explode("|", $line);
		$findpos = array_search($objectUserName, $parts);	# is it a line for the same object?
		if ($findpos !== false) {		
			$url = $parts[ $findpos - 1 ];
				$ret = "nothing";
			$call = $url . "?test=abc";
			//$call = "http://www.google.co.uk/";
			echo "\ncall=" . $call . "\n";
			// file_get_contents works for google
			// http_get doesn't
			// the curl stuff works for google (when set up properly)
			
			$ret = callCurl($call, "xyz");
			
			//$ret = file_get_contents($call);
			//$ret = http_get($call, array("timeout"=>1), $info);
			//$ret = http_get($call);
			echo "\nPHP received: " . $ret;
			$found_user = true;
		} 
	}
	if ($found_user == false) echo "\nNot logged in\n";
	http_response_code(200);
?>
