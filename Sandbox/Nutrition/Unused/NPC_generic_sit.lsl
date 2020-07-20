string animation;
integer NPC_CONTROL_CHANNEL = -72;
integer visibility_of_pose_ball = 1; //1 visible at all times
key sitting_av;

set_view()
{

	rotation sitRot = (rotation) llList2String(llGetLinkPrimitiveParams(LINK_THIS,[PRIM_ROT_LOCAL]),0);
	llSetCameraEyeOffset(<0, 1, -2>);
	llSetCameraAtOffset(<0, 1, 1>);
}

default
{
	state_entry()
	{
		llSitTarget(<-0.066414,1.003784,-0.718956>, <0.729190,0.099855,-0.108789,-0.668189>);
	}

	touch(integer i){
		llSay (0, "Link Number: "+(string)llGetLinkNumber());
		llSay(0, (string)llDetectedName(0)+"%"+(string)llGetLinkKey(llGetLinkNumber()));
		llRegionSay(NPC_CONTROL_CHANNEL, (string)llDetectedName(0)+"%"+(string)llGetLinkKey(llGetLinkNumber()));

	}

	changed(integer change)
	{
		if (change & CHANGED_LINK)
		{


			if (llAvatarOnSitTarget() != NULL_KEY)
			{
				sitting_av = llAvatarOnSitTarget();
				llRequestPermissions(llAvatarOnSitTarget(), PERMISSION_TRIGGER_ANIMATION);

			}
			else
			{
				integer perm=llGetPermissions();
				if ((perm & PERMISSION_TRIGGER_ANIMATION) && llStringLength(animation)>0)
					llStopAnimation(animation);
				if (visibility_of_pose_ball == 0) llSetAlpha(1.0, ALL_SIDES);
				animation="";
				if (osIsNpc(sitting_av)== 1){
					osNpcMoveToTarget(sitting_av,llGetPos(), OS_NPC_NO_FLY); //Hack to prevent NPC from flying off when unsitting, this is/was a bug in opensim. Justin may have fixed it.
					llSetTimerEvent(3);
				}

			}
		}
	}

	timer(){

		osNpcStopMoveToTarget(sitting_av);
		llSetTimerEvent(0);
	}

	run_time_permissions(integer perm)
	{
		if (perm & PERMISSION_TRIGGER_ANIMATION)
		{
			llStopAnimation("sit");
			animation=llGetInventoryName(INVENTORY_ANIMATION,0);
			llStartAnimation(animation);
			if (visibility_of_pose_ball == 0)  llSetAlpha(0.0, ALL_SIDES);
			llSetText("",<0,0,0>,0.0);
		}
	}

	on_rez(integer i){
		set_view();
	}
}