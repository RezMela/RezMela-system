// Object child prim

default {
	on_rez(integer start_param)	{
		llCollisionFilter("BulletDummy", NULL_KEY, TRUE);		
		llPassCollisions(TRUE);
	}
}

// Object child prim