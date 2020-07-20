float MERCATOR_RANGE = 256;

float pixelOriginX;
float pixelOriginY;
float pixelsPerLonDegree;
float pixelsPerLonRadian;

MercatorInit() {
	pixelOriginX = MERCATOR_RANGE / 2;
	pixelOriginY = MERCATOR_RANGE / 2;
	pixelsPerLonDegree = MERCATOR_RANGE / 360;
	pixelsPerLonRadian = MERCATOR_RANGE / (TWO_PI);
}
list fromLatLngToPoint(float Lat, float Lon) {
	float PointX = 0.0;
	float PointY = 0.0;
	float originX = pixelOriginX;
	float originY = pixelOriginY;
	PointX = originX + (Lon * pixelsPerLonDegree);
	float sinY = llSin(Lat * DEG_TO_RAD);
	if (sinY < -0.9999) sinY = -0.9999;
	else if (sinY > 0.9999) sinY = 0.9999;
	PointY = originY + (0.5 * llLog((1.0 + sinY) / (1.0 - sinY)) * -pixelsPerLonRadian);
	return [ PointY, PointX ];
}
list fromPointToLatLng(float PointY, float PointX) {
	float Lat;
	float Lon;
	float originX = pixelOriginX;
	float originY = pixelOriginY;
	Lon  = (PointX - originX) / pixelsPerLonDegree;
	float latRadians = (PointY - originY) / -pixelsPerLonRadian;

	// var lat = radiansToDegrees(2 * Math.atan(Math.exp(latRadians)) – Math.PI / 2);
	Lat = RAD_TO_DEG * (2.0 * llAtan2(Exp(latRadians), 1) - PI_BY_TWO);
	return [ Lat, Lon ];
}
float Exp(float N) {
	return llPow(2.718281828459045, N);
}
default {
	state_entry() {
		llOwnerSay((string)Exp(1));
		MercatorInit();
		//list YX = fromLatLngToPoint(53.770098, -0.365013);
		float Lon = llFrand(180) - 90;
		float Lat;
		for (Lat = -80; Lat <= 80; Lat += 20) {
			list YX = fromLatLngToPoint(Lat, Lon);
			//llOwnerSay(llList2CSV(YX));
			float Y = llList2Float(YX, 0);
			float X = llList2Float(YX, 1);
			list LatLon = fromPointToLatLng(Y, X);
			llOwnerSay("B:" + llList2CSV([ Lat, Lon ]));
			llOwnerSay("A:" + llList2CSV(LatLon));		// should give 53.770098, -0.365013
		}
	}
}