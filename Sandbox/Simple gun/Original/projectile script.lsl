//============================================================================
// Myriad_Lite_Bullet-v0.0.4-20120130.lsl
// Copyright (c) 2012 By Allen Kerensky (OSG/SL)
// The Myriad RPG System was designed, written, and illustrated by Ashok Desai
// Myriad RPG licensed under the Creative Commons Attribution 2.0 UK: England and Wales
// http://creativecommons.org/licenses/by/2.0/uk/
// Myriad Lite software Copyright (c) 2011-2012 by Allen Kerensky (OSG/SL)
// Baroun's Adventure Machine Copyright (c) 2008-2011 by Baroun Tardis (SL)
// Myriad Lite and Baroun's Adventure Machine licensed under the
// Creative Commons Attribution-Share Alike-Non-Commercial 3.0 Unported
// http://creativecommons.org/licenses/by-nc-sa/3.0/
// You must agree to the terms of this license before making any use of this software.
// If you do not agree to this license, simply delete these materials.
// There is no warranty, express or implied, for your use of these materials.
//============================================================================
// Davada Gallant (John Girard), WWIIOLers
// Retrieved 2011-04-30 from http://wiki.secondlife.com/wiki/Bullet
// Copyright (c) 2009 Linden Research, Inc. Licensed under Creative Commons Attribution-Share Alike 3.0 (CC-BY-SA 3.0)
// Adapted to OSSL by Allen Kerensky (SL/OSG)
// Includes Keknehv's Particle Script v1.2

//============================================================================
// MESSAGE FORMAT REFERENCE
//============================================================================
// CHANMYRIAD IN - RPEVENT|str event message
// CHANPLAYER OUT - DEPRECATED - TOHIT|str attackdice|key who/whatwashit|key bulletowner|str bulletname 
// CHANPLAYER OUT - RANGEDCOMBAT|str attackdice|key who/whatwashit|key bulletowner|str bulletname 

//============================================================================ 
// Bullet Configuration
//============================================================================
string RICOCHET = "puff of smoke";  // puff-of-smoke texture to show on bullet hits/ricochets - put this texture in bullet prim
float  BOUYANCY = 1.0;      // how buoyant is the bullet for physics
float  TIMEOUT  = 20.0;     // control timer to force bullet to die

// Myriad config
integer MINDAMAGE = 1; // minimum valid damage value for weapon
integer MAXDAMAGE = 5; // maximum valid damage value for weapon
integer DAMAGE = 1; // default how much damage do you want this weapon to cause? can be overriden on rez!
string DIV = "|"; // divider between parts of Myriad API messages
integer CHANMYRIAD = -999; // channel to send Myriad RP events to

//============================================================================
// GLOBAL SETUP()
//============================================================================
SETUP(integer type) {
    if ( llGetStatus(STATUS_PHYSICS) == FALSE ) { // is the bullet a physics object?
        llSetStatus(STATUS_PHYSICS, TRUE); // if not, make it one
    }
    llSetStatus(STATUS_DIE_AT_EDGE, TRUE); // set bullet to die if it crosses a region edge
    llSetPrimitiveParams([PRIM_TEMP_ON_REZ,TRUE]); // set bullet to be temp-on-rez to cleanup and not count against prim limits
    llSetBuoyancy(BOUYANCY); // make bullet float so it flies
    if ( type >= MINDAMAGE && type <= MAXDAMAGE ) { // is the damage value passed on rez valid?
        DAMAGE = type; // yes it is, override bullet default
    }
    llSetDamage((float)DAMAGE); // set the Linden Lab Combat System damage value to the same as Myriad damage class
    llSetTimerEvent(TIMEOUT); // start the timeout timer to try to force bullet to die too
}

//============================================================================
// Keknehv's Particle Script v1.2
//============================================================================
// Retrieved 2011-04-30 from http://lslwiki.net/lslwiki/wakka.php?wakka=LibraryKeknehvParticles
// 1.0 -- 5/30/05
// 1.1 -- 6/17/05
// 1.2 -- 9/22/05 (Forgot PSYS_SRC_MAX_AGE)
//     This script may be used in anything you choose, including and not limited to commercial products. 
//     Just copy the MakeParticles() function; it will function without any other variables in a different script
//         ( You can, of course, rename MakeParticles() to something else, such as StartFlames() )
MAKEPARTICLES(string texture) {
    if ( texture == "" || texture == NULL_KEY ) { // no texture set, no reason to show particles
        llParticleSystem([ ]); // shut off any particles that were somehow running
        return; // exit early since we're not going to show more particles without a texture to show
    }
    // This is the function that actually starts the particle system.    
    llParticleSystem([                   //KPSv1.0  
    PSYS_PART_FLAGS , 0 //Comment out any of the following masks to deactivate them
    //| PSYS_PART_BOUNCE_MASK           //Bounce on object's z-axis
    | PSYS_PART_WIND_MASK             //Particles are moved by wind
    | PSYS_PART_INTERP_COLOR_MASK       //Colors fade from start to end
    | PSYS_PART_INTERP_SCALE_MASK       //Scale fades from beginning to end
    //| PSYS_PART_FOLLOW_SRC_MASK         //Particles follow the emitter
    //| PSYS_PART_FOLLOW_VELOCITY_MASK    //Particles are created at the velocity of the emitter
    //| PSYS_PART_TARGET_POS_MASK       //Particles follow the target
    | PSYS_PART_EMISSIVE_MASK           //Particles are self-lit (glow)
    //| PSYS_PART_TARGET_LINEAR_MASK    //Undocumented--Sends particles in straight line?
    //,PSYS_SRC_TARGET_KEY , NULL_KEY,   //Key of the target for the particles to head towards
    //Choose one of these as a pattern:
    //PSYS_SRC_PATTERN_DROP                 Particles start at emitter with no velocity
    //PSYS_SRC_PATTERN_EXPLODE              Particles explode from the emitter
    //PSYS_SRC_PATTERN_ANGLE                Particles are emitted in a 2-D angle
    //PSYS_SRC_PATTERN_ANGLE_CONE           Particles are emitted in a 3-D cone
    //PSYS_SRC_PATTERN_ANGLE_CONE_EMPTY     Particles are emitted everywhere except for a 3-D cone
    ,PSYS_SRC_PATTERN,           PSYS_SRC_PATTERN_EXPLODE
    ,PSYS_SRC_TEXTURE,           texture            //UUID of the desired particle texture, or inventory name
    ,PSYS_SRC_MAX_AGE,           1.0                //Time, in seconds, for particles to be emitted. 0 = forever
    ,PSYS_PART_MAX_AGE,          5.0                //Lifetime, in seconds, that a particle lasts
    ,PSYS_SRC_BURST_RATE,        0.02               //How long, in seconds, between each emission
    ,PSYS_SRC_BURST_PART_COUNT,  1                  //Number of particles per emission
    ,PSYS_SRC_BURST_RADIUS,      0.01                //Radius of emission
    ,PSYS_SRC_BURST_SPEED_MIN,   0.01                //Minimum speed of an emitted particle
    ,PSYS_SRC_BURST_SPEED_MAX,   1.0                //Maximum speed of an emitted particle
    ,PSYS_SRC_ACCEL,             <0.05,0.05,0.05>     //Acceleration of particles each second
    ,PSYS_PART_START_COLOR,      <1.0,1.0,1.0>      //Starting RGB color
    ,PSYS_PART_END_COLOR,        <0.5,0.5,0.5>      //Ending RGB color, if INTERP_COLOR_MASK is on 
    ,PSYS_PART_START_ALPHA,      0.9                //Starting transparency, 1 is opaque, 0 is transparent.
    ,PSYS_PART_END_ALPHA,        0.0                //Ending transparency
    ,PSYS_PART_START_SCALE,      <0.5,0.5,0.0>      //Starting particle size
    ,PSYS_PART_END_SCALE,        <1.0,1.0,0.0>      //Ending particle size, if INTERP_SCALE_MASK is on
    ,PSYS_SRC_ANGLE_BEGIN,       PI                 //Inner angle for ANGLE patterns
    ,PSYS_SRC_ANGLE_END,         PI                 //Outer angle for ANGLE patterns
    ,PSYS_SRC_OMEGA,             <0.0,0.0,0.0>       //Rotation of ANGLE patterns, similar to llTargetOmega()
    ]);
}
//============================================================================
// GLOBAL DIE()
// This kludge is to try very hard to force bullets to eventually die on OpenSims.
// Requested by Lani Global (OSgrid)
//============================================================================
DIE() {
    while ( TRUE == TRUE ) { // this will always be true, forming an infinite loop
        llDie(); // just keep trying to die, forever... one will eventually work!
    }
}

//============================================================================
// STATE DEFAULT - where the program starts
//============================================================================
default {
    //------------------------------------------------------------------------
    // STATE_ENTRY - called if bullet rezzed onto the ground
    //------------------------------------------------------------------------
    state_entry() {
        SETUP(DAMAGE); // sets default damage value - may be overridden on rez
    }
    
    //------------------------------------------------------------------------
    // ON_REZ - called when bullet is rezzed by firearm
    //------------------------------------------------------------------------
    on_rez(integer start_param) {
        SETUP(start_param); // pass any start param to setup as a request to set a custom damage value, if valid, it will be used
    }
    
    //------------------------------------------------------------------------
    // COLLISION_START - we just hit an object or avatar
    //------------------------------------------------------------------------
    collision_start(integer collisions) {
        while(collisions--) { // step through each collision event counting down
            // calculate the dynamic channel of who/what we hit
           // integer dynchan = (integer)("0x"+llGetSubString((string)llGetOwner(),0,6));
            // send a ranged combat check to the HUD of the shooter
            // hitting with a bullet is not an automatic "you hit for damage"
            // instead it triggers the shooter to make a ranged combat skill check against their victim
            // if the skill check succeeds, THEN the shot is applied against the victim's armor 
           // llRegionSay(dynchan,"RANGEDCOMBAT"+DIV+(string)DAMAGE+DIV+(string)llDetectedKey(collisions)+DIV+(string)llGetOwner()+DIV+llGetObjectName());
            
            key who = llDetectedKey(collisions); // get the key of what or who we hit
            osNpcPlayAnimation(who, "fall");
            // llGetObjectDetails returns avatar key as "owner" of the avatar itself
            // so if key of what we hit matches owner's key, we hit an avatar themselves rather than someone's object
           // key owner = llList2Key(llGetObjectDetails(who,[OBJECT_OWNER]),0); // get the owner of the key of what we hit

          //  if ( who == owner ) { // so, did we hit an actual avatar?
                // yes, so as a basic anti-cheat, let's announce to the region that someone is being shot at by someone else
                //llRegionSay(CHANMYRIAD,"RPEVENT"+DIV+llKey2Name(llGetOwner())+" shot at "+llDetectedName(collisions)+"!");
          //  }
        }
        // TODO Shrapnel?
        // TODO Through and through?
        MAKEPARTICLES(RICOCHET); // show the bullet impact
        DIE(); // jump to infinite die loop to cleanup this bullet
    }
    
    //------------------------------------------------------------------------
    // LAND_COLLISION - what to do if bullet hits the ground
    //------------------------------------------------------------------------
    land_collision_start( vector collisions) {
        collisions = <0,0,0>; // LSLINT
        MAKEPARTICLES(RICOCHET); // show the poof of smoke from the ricochet, movie style
        DIE(); // jump to the infinite die loop to clean up this bullet
    }    
    
    //------------------------------------------------------------------------
    // TIMER - trigger bullet to die after a given time, if all else fails
    //------------------------------------------------------------------------
    timer() {
        DIE(); // timer expired, jump to infinite die loop to cleanup this bullet
    }
}
//============================================================================
// END
//============================================================================
