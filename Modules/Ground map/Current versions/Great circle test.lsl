
// Converts metres to degrees lon or lat (not both, ie no diagonals)
float Metres2Degrees(integer IsLongitude, float Metres, float Latitude) {
	if (IsLongitude) {
		float Km1Deg = GreatCircleKm(Latitude, 0.0, Latitude, 1.0);    // km in 1 degree of arc
        float M1Deg = Km1Deg * 1000.0;	// m in 1 degree of arc
        return Metres / M1Deg;
	}
	else {		// latitude - constant distance
		return Metres / 111111.111111111;
	}
}
// Returns distance in km between two points on the Earth's surface
float GreatCircleKm(float Lat1, float Lon1, float Lat2, float Lon2) {
	// Based on great circle calculation here:
	// http://dotnet-snippets.com/snippet/calculate-distance-between-gps-coordinates/677
	float Circumference = 40000.0; // Earth's circumference at the equator in km
	//Calculate radians
	float Lat1R = Lat1 * DEG_TO_RAD;
	float Lon1R = Lon1 * DEG_TO_RAD;
	float Lat2R = Lat2 * DEG_TO_RAD;
	float Lon2R = Lon2 * DEG_TO_RAD;

	float LonDiff = llFabs(Lon1R - Lon2R);

	if (LonDiff > PI) {
		LonDiff = 2.0 * PI - LonDiff;
	}

	float Angle = llAcos(
		llSin(Lat2R) * llSin(Lat1R) +
		llCos(Lat2R) * llCos(Lat1R) * llCos(LonDiff)
		);
	float Distance = Circumference * Angle / (2.0 * PI);
	return Distance;
}
default
{
	state_entry()
	{
		float Km = GreatCircleKm(
			53.7703, 0.4,
			53.7703, 0.0
			);
		llOwnerSay("Distance = " + (string)Km);
		float Deg = Metres2Degrees(TRUE, 26.267693 * 1000, 53.7703);
		llOwnerSay("Degrees = " + (string)Deg);
	}
}



//Public Function CalculateMetres(XorY As String, Metres As Long, Latitude As Double) As Double
//' Returns the approximate "distance" in degrees
//Dim Km As Double
//Dim M As Double
//    Select Case UCase(XorY)
//    Case "X"  ' longitude - varies with latitude
//        Km = GreatCircle(Latitude, 0, Latitude, 1, gsKilometers)    ' 1 degree of arc
//        M = Km / 1000   ' M = metres per degree longitude
//        CalculateMetres = Metres / M / 1000000
//    Case "Y"  ' latitude - constant
//        CalculateMetres = Metres / 111111.111111111
//    End Select
//End Function
