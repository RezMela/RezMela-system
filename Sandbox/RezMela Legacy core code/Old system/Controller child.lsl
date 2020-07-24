//Controller Child
//Copyright (C) 2012 by Rameshsharma Ramloll
//This file is subject to the terms and conditions defined in
//file 'LICENSE.txt', which is part of this source code package.


default
{
	state_entry()
	{

	}

	touch_start(integer total_number)
	{
		integer i = 0;
		for(; i<total_number; ++i){
			llMessageLinked(LINK_ROOT, 0, llDetectedName(i)+"%"+(string)llDetectedTouchPos(i)+"%"+(string)llDetectedTouchNormal(i)+"%"+(string)llGetRot(),"" );
		}
	}
}
