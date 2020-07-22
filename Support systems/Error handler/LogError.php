<?php
    ini_set( 'display_errors', 1 );
    error_reporting( E_ALL );
	$data = $_GET['data'];
	$args = explode("|", $data);
	$address = $args[0];
	$subject = $args[1];
	$body = $args[2];
	mail($address, $subject, $body, "From:ErrorLogger@rezmela.net");
	echo "Error recorded. " . $address;
?>