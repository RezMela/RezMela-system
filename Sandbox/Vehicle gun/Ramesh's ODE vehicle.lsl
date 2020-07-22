// Very simple vehicle script, mod for OpenSim & ODE & VEHICLE code

integer Private = 0;    // Change to 1 to prevent others riding.

vector Sitpos = <0.35,0,0.35>;
vector SitrotV = <0,-20,0>;
rotation Sitrot;
integer tt;
key oldagent;
key agent;
float forward_power = 13; //Power used to go forward (1 to 30)
float reverse_power = -8; //Power ued to go reverse (-1 to -30)
float turning_ratio = 1.5; //How sharply the vehicle turns. Less is more sharply. (.1 to 10)
integer turncount;
string Wheeldir = "WC";
string NewWheeldir = "WC";
string Wheelrot = "S";
string NewWheelrot = "S";
integer scount;
float Speed;
integer Run;
integer oldn;
string sit_message = "Ride"; //Sit message
string not_owner_message = "You are not the owner of this vehicle, but you can copy it and have your own to test in this sim. It will not work in other Open Sim Regions."; //Not owner message



lookAtMe( integer perms )
{
	if ( perms & PERMISSION_CONTROL_CAMERA )
	{
		vector currentPos = llGetPos();
		vector camPos = currentPos+<-20,0,0>;
		llClearCameraParams(); // reset camera to default
		llSetCameraParams([
			CAMERA_ACTIVE, 1, // 1 is active, 0 is inactive
			CAMERA_BEHINDNESS_ANGLE, 30.0, // (0 to 180) degrees
			CAMERA_BEHINDNESS_LAG, 0.0, // (0 to 3) seconds
			CAMERA_DISTANCE, 10.0, // ( 0.5 to 10) meters
			//CAMERA_FOCUS, <0,0,5>, // region relative position
			CAMERA_FOCUS_LAG, 0.05 , // (0 to 3) seconds
			CAMERA_FOCUS_LOCKED, FALSE, // (TRUE or FALSE)
			CAMERA_FOCUS_THRESHOLD, 0.0, // (0 to 4) meters
			CAMERA_PITCH, 10.0, // (-45 to 80) degrees
			// CAMERA_POSITION, camPos, // region relative position
			CAMERA_POSITION_LAG, 0.0, // (0 to 3) seconds
			CAMERA_POSITION_LOCKED, FALSE, // (TRUE or FALSE)
			CAMERA_POSITION_THRESHOLD, 0.0, // (0 to 4) meters
			CAMERA_FOCUS_OFFSET, <-8.0, 0.0, 8.0> // <-10,-10,-10> to <10,10,10> meters
				]);
	}
}

setVehicle()
{
	//car
	llSetVehicleType(VEHICLE_TYPE_CAR);
	llSetVehicleFloatParam(VEHICLE_ANGULAR_DEFLECTION_EFFICIENCY, 0.2);
	llSetVehicleFloatParam(VEHICLE_LINEAR_DEFLECTION_EFFICIENCY, 0.80);
	llSetVehicleFloatParam(VEHICLE_ANGULAR_DEFLECTION_TIMESCALE, 0.10);
	llSetVehicleFloatParam(VEHICLE_LINEAR_DEFLECTION_TIMESCALE, 0.10);
	llSetVehicleFloatParam(VEHICLE_LINEAR_MOTOR_TIMESCALE, 1.0);
	llSetVehicleFloatParam(VEHICLE_LINEAR_MOTOR_DECAY_TIMESCALE, 0.1);
	llSetVehicleFloatParam(VEHICLE_ANGULAR_MOTOR_TIMESCALE, 0.1);
	llSetVehicleFloatParam(VEHICLE_ANGULAR_MOTOR_DECAY_TIMESCALE, 0.1);
	llSetVehicleVectorParam(VEHICLE_LINEAR_FRICTION_TIMESCALE, <10.0, 2.0, 1000.0>);
	llSetVehicleVectorParam(VEHICLE_ANGULAR_FRICTION_TIMESCALE, <0.1, 0.1, 0.1>);
	llSetVehicleFloatParam(VEHICLE_VERTICAL_ATTRACTION_EFFICIENCY, 0.1);
	llSetVehicleFloatParam(VEHICLE_VERTICAL_ATTRACTION_TIMESCALE, 5.0);

}
Init()
{
	Sound(0);
	llSetStatus(STATUS_PHYSICS, FALSE);
	vector here = llGetPos();
	//    float h = llGround(<0,0,0>) + 0.52;
	vector rotv = llRot2Euler(llGetRot());
	rotation rot = llEuler2Rot(<0,0,rotv.z>);
	//  llSetPos(<here.x, here.y,h>);
	llSetRot(rot);
	Sitrot = llEuler2Rot(DEG_TO_RAD * SitrotV);
	llSetVehicleType(VEHICLE_TYPE_NONE);
	llMessageLinked(LINK_ALL_OTHERS, 0, "S", NULL_KEY);     // wheels stop
	llMessageLinked(LINK_ALL_OTHERS, 0, "WC", NULL_KEY);     // wheels straight
	Run = 0;
	llClearCameraParams();
	llSitTarget(<3.6,0.8,1.6>, <0.000000,0.190843,0.000000,-0.981621>);
}

SetMaterial()
{
	llSetPrimitiveParams([PRIM_MATERIAL, PRIM_MATERIAL_GLASS]);
	llMessageLinked(LINK_ALL_OTHERS, 0, "SetMat", NULL_KEY);    // Tell daughter pims on ground to be glass
}

Sound(integer n)
{
	if(n != oldn)
	{
		oldn = n;
		if(n == 2)
		{
			llStopSound();
			llLoopSound("RUNNING",1);
		}
		else if(n == 1)
		{
			llStopSound();
			llLoopSound("IDLE",1);
		}
		else
		{
			llStopSound();
		}
	}
}

default
{
	state_entry()
	{
		Init();
		llSetSitText(sit_message);
		llStopSound();
	}

	on_rez(integer rn)
	{

	}

	touch( integer i){

	}
	changed(integer change)
	{
		if ((change & CHANGED_LINK) == CHANGED_LINK)
		{
			agent = llAvatarOnSitTarget();
			if (agent != NULL_KEY)
			{
				if( (agent != llGetOwner()) && (Private == 1) )
				{
					llSay(0, not_owner_message);
					llUnSit(agent);
					// not functional   llPushObject(agent, <0,0,50>, ZERO_VECTOR, FALSE);
				}
				else // if (agent == llGetOwner()) //so that everyone can drive
				{
					//llOwnerSay("I am in crazy zone here!");
					llSetStatus(STATUS_PHANTOM, FALSE);
					oldagent = agent;
					setVehicle();
					SetMaterial();
					llSleep(.4);
					llSetStatus(STATUS_PHYSICS, TRUE);
					llSleep(.1);
					Run = 1;
					llSetTimerEvent(0.3);
					llRequestPermissions(agent, PERMISSION_TRIGGER_ANIMATION | PERMISSION_TAKE_CONTROLS |PERMISSION_CONTROL_CAMERA);
					llPlaySound("START",1);
				}
			}
			else
			{

				Init();
				llSetStatus(STATUS_PHANTOM, TRUE);
				llSleep(.4);
				llReleaseControls();
				llMessageLinked(LINK_ALL_OTHERS, 0, "S", NULL_KEY);
				Run = 0;
				llPlaySound("CLOSE",1);
				llStopSound();

			}
		}
	}

	run_time_permissions(integer perm)
	{
		if (perm)
		{
			llTakeControls(CONTROL_FWD | CONTROL_BACK | CONTROL_DOWN | CONTROL_UP | CONTROL_RIGHT |
				CONTROL_LEFT | CONTROL_ROT_RIGHT | CONTROL_ROT_LEFT, TRUE, FALSE);
			lookAtMe(perm);

		}
	}

	control(key id, integer level, integer edge)
	{
		integer reverse=1;
		vector angular_motor;

		//get current speed
		vector vel = llGetVel();
		Speed = llVecMag(vel);
		//llOwnerSay((string)Speed);
		//car controls
		if(level & CONTROL_FWD)
		{
			llSetVehicleVectorParam(VEHICLE_LINEAR_FRICTION_TIMESCALE, <10.0, 2.0, 1000.0>);
			llSetVehicleVectorParam(VEHICLE_LINEAR_MOTOR_DIRECTION, <forward_power,0,0>);
			reverse=1;
			NewWheelrot = "F";
		}
		if(level & CONTROL_BACK)
		{
			llSetVehicleVectorParam(VEHICLE_LINEAR_FRICTION_TIMESCALE, <10.0, 2.0, 1000.0>);
			llSetVehicleVectorParam(VEHICLE_LINEAR_MOTOR_DIRECTION, <reverse_power,0,0>);
			reverse = -1;
			NewWheelrot = "R";
		}

		if(level & (CONTROL_RIGHT|CONTROL_ROT_RIGHT))
		{
			angular_motor.z -= Speed / turning_ratio * reverse;
			NewWheeldir = "WR";
			turncount = 10;
		}

		if(level & CONTROL_DOWN)
		{
			llSetVehicleVectorParam(VEHICLE_LINEAR_MOTOR_DIRECTION, <0,0,-1>);
		}
		if(level & (CONTROL_LEFT|CONTROL_ROT_LEFT))
		{
			angular_motor.z += Speed / turning_ratio * reverse;
			NewWheeldir = "WL";
			turncount = 10;
		}

		llSetVehicleVectorParam(VEHICLE_ANGULAR_MOTOR_DIRECTION, angular_motor);
		if(turncount > 0)
		{
			turncount--;
		}
		if(turncount == 1)
		{
			NewWheeldir = "WC";
		}
		if(Wheeldir != NewWheeldir){
			Wheeldir = NewWheeldir;
			llMessageLinked(LINK_ALL_OTHERS, 0, Wheeldir, NULL_KEY);
		}
		if(Wheelrot != NewWheelrot){
			Wheelrot = NewWheelrot;
			llMessageLinked(LINK_ALL_OTHERS, 0, Wheelrot, NULL_KEY);
		}
	} //end control

	timer(){
		if(Run == 1){
			vector vel = llGetVel();
			Speed = llVecMag(vel);

			if(Speed > 2.0)
			{
				Sound(2);
			}
			else if(Speed > 0.0)
			{
				llSetVehicleVectorParam(VEHICLE_LINEAR_FRICTION_TIMESCALE, <1.0, 2.0, 1000.0>);
				llSetVehicleVectorParam(VEHICLE_LINEAR_MOTOR_DIRECTION, <0,0,0>);
				llMessageLinked(LINK_ALL_OTHERS, 0, "S", NULL_KEY);
				Sound(1);
				Wheelrot = "S";
			}
			llSetTimerEvent(0.3);          // If restarted timer() appears to keep working
		}else{
				llSetTimerEvent(0.0);
		}
	}

} //end default