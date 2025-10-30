
/*
    Portal: Anomaly vscript file
    Made by Laveig

    This one is exclusevily for showcasing the panels.
    Basically, 
*/

printl("presentation.nut - Executed")

DoIncludeScript("pcapture-lib-40beta/PCapture-Lib", getroottable()) //pcapture (give me a reason to use strata trace over pcap)

/*
    TODO (high-prioity todos are marked with *):
    - Add a check for panel's height (to avoid stucking in tight areas)
    - Make the cube saver deploy the exact cube saved (hint: pcap hud)
    - Make the cube saver go through cubes when pressing arrow keys
    - Add a thing where shooting a turret with another turret explodes the turret being shot
*/

//
// Global vars (used everywhere in the code)
//

radio <- Entities.FindByName(null, "radio");    // Radio (shows whether the function is active);
arm64 <- Entities.FindByName(null, "arm_64");   // The 'ghost' arm, that shows which panel gets activated;
ignoreEntities <- [arm64, radio]                // For the trace, we need to ignore these entities.

distance <- 64  // initial distance

if (radio == null) {    // pcapture freaked out when the radio went missing lmao
    ignoreEntities = [arm64]
}

ignoreEntities2 <- TracePlus.Settings.new({     // Another setting, makes the trace ignore classes.
    ignoreClasses = ArrayEx("func_brush", "prop_button", "prop_floor_button", "trigger_multiple", "prop_physics", "prop_weighted_cube", "prop_static")
})                                              // Note that this setting is PCAPTURE ONLY and WILL NOT WORK ON STRATA TRACES (that's why strata trace sucks)

hitEntityName <- ""     // Yeah this variable is used globally
lastArm <- "arm_tp2"    // Simular to hitEntityName, but it saves the name of the already deployed arm
 
/*
    Functions below are called by player inputs.

    Note that the cluster ends when another one of these huge comments appear
*/
armModeType <- 0
function callPrearmFunctions() {
    if (armMode == true && ghosting == true) {

        if (armModeType == 0) {
            // Arm mode type: classic
            Predeployer()
            return
        }
        if (armModeType == 1) {
            // Arm mode type: rotate
            Predeployer2()
            return
        }
        if (armModeType == 2) {
            // Arm mode type: cube sucker
            cubePresuck()
            return
        }
        if (armModeType == 3) {
            // Arm mode: faith
            preDeployFaith()
        }
    }
}
function callArmFunctions() {
    if (armMode == true) {

        if (armModeType == 0) {
            deployTheArm()
            return
        }
        if (armModeType == 1) {
            deployAngled()
            return
        }
        if (armModeType == 2) {
            cubeSucker()
            return
        }
        if (armModeType == 3) {
            deployFaith()
            return
        }
    }
}
function callAdjArmFunctions() {
    if (armMode == true) {

        if (armModeType == 0) {
            // Arm mode type: classic
            deployAdjust()
            return
        }
        if (armModeType == 1) {
            // Arm mode type: rotate
            deployAngleFront()
            return
        }
        if (armModeType == 2) {
            // Arm mode type: cube saver
            return
        }
    }
}
function callDeadjArmFunctions() {
    if (armMode == true) {

        if (armModeType == 0) {
            deployDeadjust()
            return
        }
        if (armModeType == 1) {
            deployAngleBack()
            return
        }
        if (armModeType == 2) {
            return
        }
    }
}
function toggleArmModesForw() {
    armModeType = armModeType + 1
    if (armModeType > 3) {
        armModeType = 3
    }
    printl(" === Appended the arm type to " + armModeType)

    if (armModeType == 1) {
        if (arm_angled_front == true) {
            EntFire("arm_64", "setanimation", "90deg_cornerfront_idle") // uhm huh
        }
        if (arm_angled_front == false) {
            EntFire("arm_64", "setanimation", "90deg_cornerback_idle") // uhm huh
        }
    }
}
function toggleArmModesBack() {
    armModeType = armModeType - 1
    if (armModeType < 0) {
        armModeType = 0
    }
    printl(" === Decreased the arm type to " + armModeType)

    if (armModeType == 0) {
        EntFire("arm_64", "setanimation", distance + "_idle") // uhm huh
        return
    }
    if (armModeType == 1) {
        if (arm_angled_front == true) {
            EntFire("arm_64", "setanimation", "90deg_cornerfront_idle") // uhm huh
        }
        if (arm_angled_front == false) {
            EntFire("arm_64", "setanimation", "90deg_cornerback_idle") // uhm huh
        }
    }
}

armMode <- false    // literally
function toggleArming() {
    armMode = !armMode  // Toggles modes everytime the function is called

    if (armMode == true) {
        printl("Arm modes active")
        EntFire("radio", "enable")
        EntFire("timerelay1a", "fireuser1")
        EntFire("timerelay1b", "enable")
    }
    if (armMode == false) {
        printl("Arm modes inactive")
        EntFire("radio", "disable")
        EntFire("timerelay1b", "disable")
        retrieveArm64(true)
    }
}

/*
    Functions below make all the panel rise.
    Use it to debug panels.
    
    arms_open - floor
    arms_open2 - ceiling
    arms_open3 - wall
*/

arms_amount <- 1
arms_amount2 <- 1
arms_amount3 <- 1
arms_limit <- 500

function arms_open() {
    EntFire("arm-floor"+arms_amount, "SetAnimation", "64_out_straight")
    arms_amount = arms_amount + 1
    if (arms_amount > arms_limit ) {
        EntFire("arm-floor_tile_timer2", "Disable")
    }
}
function arms_close() {
    arms_amount = arms_limit
    local arms_delay = 0
    while (arms_amount != 0) {
        EntFire("arm-floor"+arms_amount, "SetAnimation", "64_in_straight", arms_delay)
        arms_amount = arms_amount - 1
        arms_delay = arms_delay + 0.01
    }
}
function arms_open2() {
    EntFire("arm-ceiling"+arms_amount2, "SetAnimation", "64_out_straight")
    arms_amount2 = arms_amount2 + 1
    if (arms_amount2 > arms_limit) {
        EntFire("arm-ceiling_tile_timer2", "Disable")
    }
}
function arms_close2() {
    arms_amount2 = arms_limit
    local arms_delay = 0
    while (arms_amount2 != 0) {
        EntFire("arm-ceiling"+arms_amount2, "SetAnimation", "64_in_straight", arms_delay)
        arms_amount2 = arms_amount2 - 1
        arms_delay = arms_delay + 0.01
    }
}
function arms_open3() {
    EntFire("arm-wall"+arms_amount3, "SetAnimation", "64_out_straight")
    arms_amount3 = arms_amount3 + 1
    if (arms_amount3 > arms_limit) {
        EntFire("arm-wall_tile_timer2", "Disable")
    }
}
function arms_close3() {
    arms_amount3 = arms_limit
    local arms_delay = 0
    while (arms_amount3 != 0) {
        EntFire("arm-wall"+arms_amount3, "SetAnimation", "64_in_straight", arms_delay)
        arms_amount3 = arms_amount3 - 1
        arms_delay = arms_delay + 0.01
    }
}

/*
    Functions below are for the first arm mode type.

    They make arms deploy straight up (or down).
    The distance is controllable.
*/

function Predeployer() {   // Finds the specific arm and teleports the ghost arm to it

    if (arm64 == null) {
        printl("arm_64 not found!") // in which case you should kill the mapper, it's him who forgor to add it;
        retrieveArm64(true)          // teleports the arm out of bounds
        return
    }

    local player = GetPlayerEx()
    local traceResult = TracePlus.FromEyes.Bbox(9999, player, ignoreEntities, ignoreEntities2) // <--- THE TRACE

    if (!traceResult.DidHit()) { // if we didn't hit anything (in 9999 units :skull:)
        printl("didn't hit anything")
        retrieveArm64(true)
        return
    }
    if (traceResult.DidHitWorld()) { // If we hit worldspawn
        printl("not an arm (world)")
        retrieveArm64(true)
        return
    }
 
    local hitEntity = traceResult.GetEntity()           // table
    local hitEntityPrefix = hitEntity.GetNamePrefix()   // prefix (obsolete?)
    hitEntityName = hitEntity.GetName()                 // full name

    if (hitEntityPrefix != "arm-") {
        printl("not an arm (" + hitEntityName + ")")
        retrieveArm64(true)
        return
    }     

    local armOrigin = hitEntity.GetOrigin(); // position of the arm we hit by the trace
    local armAngles = hitEntity.GetAngles(); // angles of the arm we hit by the trace

    arm64.SetOrigin(armOrigin);                             // here we teleport the ghost arm to the actual arm!
    arm64.SetAngles(armAngles.x, armAngles.y, armAngles.z); // and set the angles! (splitting xyz cuz vectors dont work for some reason)

    print("Teleported arm_64 to " + hitEntityName + ";")
    print(" Pos: " + armOrigin + ";")
    printl(" Angles: " + armAngles + ".")

    return hitEntityName    // check deployTheArm()
}

function deployAdjust() {     // every time this function is called,
    distance = distance + 64  // it increases the distance by 64

    EntFire("arm_64", "setanimation", distance + "_idle")
    if (distance >= 192) {                                        // if the distance is 192 or higher,
        distance = 192                                            //
        EntFire("arm_64", "setanimation", distance + "_idle_03")  // we add 03 at the end of the animation name
        printl("Distance: " + distance)
        return
    }
    if (distance == 96) {   // when increasing from 32 it gives 96
        distance = 64
        EntFire("arm_64", "setanimation", distance + "_idle")
        printl("Distance: " + distance)
        return
    }
    printl("Distance: " + distance)
    EntFire("arm_64", "setanimation", distance + "_idle")
}
function deployDeadjust() {   // every time this function is called,
    distance = distance - 64  // it decreases the distance by 64

    if (distance == 0) {    // if the distance is zero we set it back to 32
        distance = 32
        EntFire("arm_64", "setanimation", distance + "_idle")
        printl("Distance: " + distance)
        return
    }
    if (distance < 0) {     // same for below zero
        distance = 32       // TODO: '<=' operator exists
        EntFire("arm_64", "setanimation", distance + "_idle")
        printl("Distance: " + distance)
        return
    }
    EntFire("arm_64", "setanimation", distance + "_idle")
    printl("Distance: " + distance)
}

function deployTheArm(deployTime = 1) {
    if (armMode == true && armModeType == 0) {
        local hitEntityName = Predeployer()
        if (distance == 192) {
            distance = 224  // THERE IS NO 192 ANIMATION WTF
        }

        EntFire(hitEntityName, "SetAnimation", distance + "_out_straight")

        if (lastArm != hitEntityName) { EntFire(lastArm, "SetAnimation", distance + "_in_straight", deployTime) }

        lastArm = hitEntityName // saving the last used arm should be after the exec

        if (distance == 224) {
            distance = 192  // so yeah I have to set it back everytime. it also looks ugly in game
                            // it also breaks the adjuster lmao.
        }
        printl("Deploying the arm")
    }
}

callrelay <- false      // required to delay
function retrieveArm64(callrelay) {
    if (callrelay == true) {
        EntFire("retrievearm64relay", "Trigger")
    }
    if (callrelay == false) {
        Entities.FindByName(null, "arm_64").SetOrigin(Entities.FindByName(null, "arm_tp").GetOrigin());
        Entities.FindByName(null, "arm_sucker1").SetOrigin(Entities.FindByName(null, "arm_tp").GetOrigin());
        Entities.FindByName(null, "arm_sucker2").SetOrigin(Entities.FindByName(null, "arm_tp").GetOrigin());
        Entities.FindByName(null, "arm_sucker3").SetOrigin(Entities.FindByName(null, "arm_tp").GetOrigin());
    }
    // this whole function is a bugfix
    // where the arm had a chance to stay at its position
    // rather than teleporting away
}

/*
    Functions below are for the second arm mode type.

    Simular to the first one,
    except there are only two types of "height" (cornerfront and cornerback).
*/

function Predeployer2() {
    
    if (arm64 == null) {
        printl("arm_64 not found!") // in which case I will fire the mapper, it's him who forgor to add the instance.
        return
    }

    local player = GetPlayerEx()
    local traceResult = TracePlus.FromEyes.Bbox(9999, player, ignoreEntities, ignoreEntities2) // <--- THE TRACE
    
    if (!traceResult.DidHit()) { // if we didn't hit anything (in 9999 units :skull:)
        printl("didn't hit anything")
        retrieveArm64(true)
        return
    }
    if (traceResult.DidHitWorld()) { // If we hit worldspawn
        printl("not an arm (world)")
        retrieveArm64(true)
        return
    }
 
    local hitEntity = traceResult.GetEntity()          
    local hitEntityPrefix = hitEntity.GetNamePrefix()   
    hitEntityName = hitEntity.GetName()                 

    if (hitEntityPrefix != "arm-") {
        printl("not an arm (" + hitEntityName + ")")
        retrieveArm64(true)
        return
    }     

    local armOrigin = hitEntity.GetOrigin()
    local armAngles = hitEntity.GetAngles()

    arm64.SetOrigin(armOrigin);                            
    arm64.SetAngles(armAngles.x, armAngles.y, armAngles.z); 

    print("Teleported arm_64 to " + hitEntityName + ";")
    print(" Pos: " + armOrigin + ";")
    print(" Angles: " + armAngles + ".")

    return hitEntityName    // check deployAngled()
}

arm_angled_front <- true
function deployAngleFront() {

    arm_angled_front = true
    EntFire("arm_64", "setanimation", "90deg_cornerfront_idle") 
    printl("Arm angled frontwards")
}
function deployAngleBack() {   // I DONT EVEN NEED 'IF' LMFAO
    
    arm_angled_front = false
    EntFire("arm_64", "setanimation", "90deg_cornerback_idle") 
    printl("Arm angled backwards")
}

function deployAngled(deployTime = 1) {  // deploy time was nesessary when panels had to close after some time,
                                        // but when in 1x1 mode, it just a delay before closing the previous panel
    local hitEntityName = Predeployer2()

    if (arm_angled_front == true) {
        EntFire(hitEntityName, "setanimation", "90deg_out_cornerfront") 
        EntFire(lastArm, "setanimation", "90deg_in_cornerfront", deployTime)
    }
    if (arm_angled_front == false) {
        EntFire(hitEntityName, "setanimation", "90deg_out_cornerback")
        EntFire(lastArm, "setanimation", "90deg_in_cornerback", deployTime) 
    }
    lastArm = hitEntityName
    printl("Deploying the arm")
}



/*
    Functions below are for the third arm mode type.
    It creates a 2x2 hole where player can drop a cube
    to retreive it later on.

    Now the solution is not the best,
    but it's better than building 7 traces every 0.05 seconds anyway.

    It still may be laggy af.
*/


// Finds neighbor props (check cubeSucker() below)
function Find2x2Square(centerArm) {

    printl("Selected prop: " + centerArm.GetName())
    printl("Searching for nearby panels...")

    local neighbors = []
    local centerOrigin = centerArm.GetOrigin()
    local neighborCycles = 4    // amount of cycles to do
    local neighborCycleCurrent = 0

    // First panel (left-top)
    local ignoredName = "arm_sucker1"
    local neighborOrigin = Vector(centerOrigin.x + 64, centerOrigin.y, centerOrigin.z)
    local neighborProp1 = null

    while (neighborCycleCurrent != neighborCycles) {
        neighborProp1 = Entities.FindByClassnameWithin(null, "prop_dynamic", neighborOrigin, 1)
        if (neighborProp1.GetName().find("arm-floor") != null || neighborProp1.GetName().find("arm-ceiling") != null) {
            neighbors.append(neighborProp1)
            printl("Found panel 1: " + neighborProp1.GetName())
            break
        }
    }
    if (neighborCycleCurrent == neighborCycles - 1) {
        printl("Didn't find panel 1!")
        return null
    }
    neighborCycleCurrent = 0

    // Second panel (right-bottom)
    local ignoredName = "arm_sucker2"
    local neighborOrigin = Vector(centerOrigin.x, centerOrigin.y - 64, centerOrigin.z)
    local neighborProp2 = null

    while (neighborCycleCurrent != neighborCycles) {
        neighborProp2 = Entities.FindByClassnameWithin(null, "prop_dynamic", neighborOrigin, 1)
        if (neighborProp2.GetName().find("arm-floor") != null || neighborProp2.GetName().find("arm-ceiling") != null) {
            neighbors.append(neighborProp2)
            printl("Found panel 2: " + neighborProp2.GetName())
            break
        }
    }
    if (neighborCycleCurrent == neighborCycles - 1) {
        printl("Didn't find panel 2!")
        return null
    }
    neighborCycleCurrent = 0

    // Third panel (right-top)
    local ignoredName = "arm_sucker3"
    local neighborOrigin2 = Vector(neighborOrigin.x + 64, neighborOrigin.y, neighborOrigin.z)
    local neighborProp3 = null

    while (neighborCycleCurrent != neighborCycles) {
        neighborProp3 = Entities.FindByClassnameWithin(null, "prop_dynamic", neighborOrigin2, 1)
        if (neighborProp3.GetName().find("arm-floor") != null || neighborProp3.GetName().find("arm-ceiling") != null) {
            neighbors.append(neighborProp3)
            printl("Found panel 3: " + neighborProp3.GetName())
            break
        }
    }
    if (neighborCycleCurrent == neighborCycles - 1) {
        printl("Didn't find panel 3!")
        return null
    }

    printl("End of searching.")
    return neighbors
}

cubes_saved <- 0
neighbors_globvar <- null
neighbors_are_floor <- true
hitEntityName_globvar <- null
function cubeSucker() { // Opens the cubesucker.

    // the old ones needed to be closed first
    if (neighbors_globvar != null) {
        if (neighbors_are_floor = false) {
            EntFire(hitEntityName_globvar, "setanimation", "90deg_in_cornerfront")
            EntFire(neighbors_globvar[0].GetName(), "setanimation", "90deg_in_cornerback")
            EntFire(neighbors_globvar[1].GetName(), "setanimation", "90deg_in_cornerfront")
            EntFire(neighbors_globvar[2].GetName(), "setanimation", "90deg_in_cornerback")
        }
        if (neighbors_are_floor = true) {
                EntFire(hitEntityName_globvar, "setanimation", "90deg_in_cornerback")
                EntFire(neighbors_globvar[0].GetName(), "setanimation", "90deg_in_cornerfront")
                EntFire(neighbors_globvar[1].GetName(), "setanimation", "90deg_in_cornerback")
                EntFire(neighbors_globvar[2].GetName(), "setanimation", "90deg_in_cornerfront")
        }
    }

    printl(" === Attempt to open the cubesucker.")

    local traceResult = TracePlus.FromEyes.Bbox(9999, player, ignoreEntities, ignoreEntities2) // <--- THE TRACE

    if (!traceResult.DidHit()) { // if we didn't hit anything (in 9999 units :skull:)
        printl("didn't hit anything")
        retrieveArm64(true)
        return
    }
    if (traceResult.DidHitWorld()) { // If we hit worldspawn
        printl("not an arm (world)")
        retrieveArm64(true)
        return
    }

    local hitEntity = traceResult.GetEntity()
    local hitEntityPrefix = hitEntity.GetNamePrefix()
    if (hitEntityPrefix != "arm-") {
        printl("not an arm (" + hitEntityName + ")")
        retrieveArm64(true)
        return
    }

    local hitEntityYaw = hitEntity.GetAngles().y
    local hitEntityName = hitEntity.GetName()
    hitEntityName_globvar = hitEntityName
    
    local neighbors = Find2x2Square(hitEntity)
    neighbors_globvar = neighbors

    if (neighbors == []) {
        printl("Unable to create the cube sucker!")
        return
    }

    if (hitEntityYaw < 90) {
        neighbors_are_floor = true
        EntFire(hitEntityName, "setanimation", "90deg_out_cornerback")
        EntFire(neighbors[0].GetName(), "setanimation", "90deg_out_cornerfront")
        EntFire(neighbors[1].GetName(), "setanimation", "90deg_out_cornerback")
        EntFire(neighbors[2].GetName(), "setanimation", "90deg_out_cornerfront")
    }
    if (hitEntityYaw > 90) {
        neighbors_are_floor = false
        EntFire(hitEntityName, "setanimation", "90deg_out_cornerfront")
        EntFire(neighbors[0].GetName(), "setanimation", "90deg_out_cornerback")
        EntFire(neighbors[1].GetName(), "setanimation", "90deg_out_cornerfront")
        EntFire(neighbors[2].GetName(), "setanimation", "90deg_out_cornerback")
    }

    if (hitEntityName.find("arm-floor") != null) {
        printl(" === Cubesucker mode: in. Awaiting cube.")
        Entities.FindByName(null, "trigger_sucker").SetOrigin(  Vector(hitEntity.GetOrigin().x, hitEntity.GetOrigin().y, hitEntity.GetOrigin().z - 120) )
        return
    }
    if (hitEntityName.find("arm-ceiling") != null) {
        if (cubes_saved <= 0) {
            printl(" === Cubesucker mode: out. /nNOT ENOUGH CUBES!")

            if (hitEntityYaw > 90) {
                neighbors_are_floor = false
                EntFire(hitEntityName, "setanimation", "90deg_in_cornerfront", 1.5)
                EntFire(neighbors[0].GetName(), "setanimation", "90deg_in_cornerback", 1.5)
                EntFire(neighbors[1].GetName(), "setanimation", "90deg_in_cornerfront", 1.5)
                EntFire(neighbors[2].GetName(), "setanimation", "90deg_in_cornerback", 1.5)
            }
            else if (hitEntityYaw < 90) {
                neighbors_are_floor = true
                EntFire(hitEntityName, "setanimation", "90deg_in_cornerback", 1.5)
                EntFire(neighbors[0].GetName(), "setanimation", "90deg_in_cornerfront", 1.5)
                EntFire(neighbors[1].GetName(), "setanimation", "90deg_in_cornerback", 1.5)
                EntFire(neighbors[2].GetName(), "setanimation", "90deg_in_cornerfront", 1.5)
            }
            return
        }
        printl(" === Cubesucker mode: out. \nDispencing cube.")

        local cubeMaker = Entities.FindByClassname(null, "env_entity_maker")    
        local cubeNewOrigin = Vector(hitEntity.GetOrigin().x, hitEntity.GetOrigin().y, hitEntity.GetOrigin().z + 200)
        cubeMaker.SpawnEntityAtLocation(cubeNewOrigin, Vector(0, 0, 0))
        cubes_saved--

        if (hitEntityYaw > 90) {
            EntFire(hitEntityName, "setanimation", "90deg_in_cornerfront", 2)
            EntFire(neighbors[0].GetName(), "setanimation", "90deg_in_cornerback", 2)
            EntFire(neighbors[1].GetName(), "setanimation", "90deg_in_cornerfront", 2)
            EntFire(neighbors[2].GetName(), "setanimation", "90deg_in_cornerback", 2)
        }
        else if (hitEntityYaw < 90) {
            EntFire(hitEntityName, "setanimation", "90deg_in_cornerback", 2)
            EntFire(neighbors[0].GetName(), "setanimation", "90deg_in_cornerfront", 2)
            EntFire(neighbors[1].GetName(), "setanimation", "90deg_in_cornerback", 2)
            EntFire(neighbors[2].GetName(), "setanimation", "90deg_in_cornerfront", 2)
        }
        return
    }
}

function cubePresuck() {    // teleports the 'ghost' arms (some throw-catchers are missing for optimisation)

    local traceResult = TracePlus.FromEyes.Bbox(9999, player, ignoreEntities, ignoreEntities2) // <--- THE TRACE

    if (!traceResult.DidHit()) { // if we didn't hit anything (in 9999 units :skull:)
        printl("didn't hit anything")
        retrieveArm64(true)
        return
    }
    if (traceResult.DidHitWorld()) { // If we hit worldspawn
        printl("not an arm (world)")
        retrieveArm64(true)
        return
    }

    local hitEntity = traceResult.GetEntity()
    local hitEntityAngles = hitEntity.GetAngles()

    local neighbors = Find2x2Square(hitEntity)

    arm64.SetOrigin(hitEntity.GetOrigin())
    arm64.SetAngles(hitEntityAngles.x, hitEntityAngles.y, hitEntityAngles.z)

    EntFire("arm_64", "setanimation", "90deg_cornerback_idle")
    EntFire("arm_sucker3", "setanimation", "90deg_cornerfront_idle")

    arm64.SetOrigin(hitEntity.GetOrigin())
    // Entities.FindByName(null, "arm_sucker1").SetOrigin(neighbors[0].GetOrigin())     // P2CE DEVS ARE IDIOTS
    // Entities.FindByName(null, "arm_sucker2").SetOrigin(neighbors[1].GetOrigin())     // WHY DID THEY LIMIT THE EXECUTION TIME???
    // Entities.FindByName(null, "arm_sucker3").SetOrigin(neighbors[2].GetOrigin())     // THE SCRIPT LITERALLY BREAKS WHEN I UNCOMMENT THIS!!!

    printl("Arms teleported. Awaiting cubeSucker().")

}

function onTouchTrigger() { // basically !activator, ignore this function
    local trigger = caller
    if (trigger == null || !trigger.IsValid()) return
    local triggerActivator = null
    local triggerOrigin = trigger.GetOrigin()
    local triggerSize = trigger.GetBoundingMaxs().x * 2
    local ent = null
    while (ent = Entities.FindInSphere(ent, triggerOrigin, triggerSize)) {
        if (ent == trigger || ent.GetClassname() != "prop_weighted_cube") continue
        local entOrigin = ent.GetOrigin()
        if (abs(entOrigin.x - triggerOrigin.x) < triggerSize && abs(entOrigin.y - triggerOrigin.y) < triggerSize) {
            triggerActivator = ent
            break } }
    if (triggerActivator != null && triggerActivator.IsValid()) {
        cubeSucked(triggerActivator) }
}

function cubeSucked(cube) {
    printl(" === Cube sucker sucked the cube. Closing the arms")
    printl("Cube: " + cube)
    Entities.FindByName(null, "trigger_sucker").SetOrigin(Entities.FindByName(null, "arm_tp2").GetOrigin())
    EntFire(cube.GetName(), "silentdissolve")
    cubes_saved++

    EntFire(hitEntityName_globvar, "setanimation", "90deg_in_cornerback")
    EntFire(neighbors_globvar[0].GetName(), "setanimation", "90deg_in_cornerfront")
    EntFire(neighbors_globvar[1].GetName(), "setanimation", "90deg_in_cornerback")
    EntFire(neighbors_globvar[2].GetName(), "setanimation", "90deg_in_cornerfront")

    hitEntityName_globvar = null    // when opening another cube sucker, the previous panels flicker
    neighbors_globvar = null        // by resetting these I make them flick no more
}


/*
    Functions below are for the fourth arm mode type.

    They create a target and a catapult beneath the player,
    but only if there is a panel.
    The panel basically acts as a faith plate.

    Since we can already move downwards,
    this mode lets the player move upwards.
*/

function preDeployFaith() { // Purely visual. Absolutely useless.

    local launchDir = GetPlayerEx().EyeAngles().x + " " + GetPlayerEx().EyeAngles().y + " " +  GetPlayerEx().EyeAngles().z
    printl("Looking dir:" + launchDir)

}

function deployFaith() {

    local playerPos = player.GetOrigin()
    local arm_faith = Entities.FindByClassnameWithin(null, "prop_dynamic", playerPos, 50)
    local arm_faith_name = arm_faith.GetName()
    printl("Faith arm: " + arm_faith_name)
    printl( arm_faith_name.find("arm-") ) // debug
    if ( arm_faith_name.find("arm-") == null ) return

    EntFire(arm_faith_name, "setanimation", "64_in_straight")

    local catapult = TeleportCatapult()
    EntFireByHandle(catapult, "Enable")
    EntFireByHandle(catapult, "Disable", "", 1)

}

launch_distance <- "600"  // lower value = less fun
function TeleportCatapult() {   // teleports the catapult to the player

    local player = Entities.FindByClassname(null, "player")
    if (player == null || !player.IsValid())
    {
        printl("Player not found wtf")
        return null
    }

    local playerPos = player.GetOrigin()
    local catapult = Entities.FindByName(null, "panel_catapult")

    local launchDir = GetPlayerEx().EyeAngles().x + " " + GetPlayerEx().EyeAngles().y + " " +  GetPlayerEx().EyeAngles().z
    catapult.__KeyValueFromString("playerSpeed", launch_distance) // I really don't want to change anything in hammer...
    catapult.__KeyValueFromString("launchdirection", launchDir)

    catapult.SetOrigin( Vector(playerPos.x, playerPos.y, playerPos.z) )

    return catapult
}

function CreateCatapultAtPlayer() { // Creates a catapult at the player position. OBSOLETE

    local player = Entities.FindByClassname(null, "player")
    if (player == null || !player.IsValid())
    {
        printl("Player not found wtf")
        return null
    }

    // The target is being teleported to hitpos in the function above
    local catapultTarget = Entities.FindByName(null, "catapult_target")
    if (catapultTarget == null || !catapultTarget.IsValid())
    {
        printl("CATAPULT TARGET IS MISSING")
        return null
    }
    
    local playerPos = player.GetOrigin()

    // Now we create the damn catapult
    local catapult = Entities.CreateByClassname("trigger_catapult")
    if (catapult == null)
    {   // in rare case if P2CE moment appears
        printl("UNABLE TO CREATE A CATAPULT")
        return null
    }
    
    catapult.SetOrigin(playerPos + Vector(0, 0, 50))    // player's origin
    catapult.SetSize(Vector(-100, -100, 0), Vector(100, 100, 100))  // 200 units wide (not like if this matters but anyways)

    catapult.__KeyValueFromString("target", "catapult_target")
    catapult.__KeyValueFromString("playerSpeed", "1200") 
    catapult.__KeyValueFromString("physicsSpeed", "0")  // easy way to prevent the catapult from colliding with phys objects
    catapult.__KeyValueFromString("directionEntity", "catapult_target")
    catapult.__KeyValueFromString("launchTarget", "catapult_target")
    catapult.__KeyValueFromString("Enabled", "1")   // just in case

    EntFireByHandle(catapult, "Enable", "", 0.1, null, null)    // PLEASE WORK U DAMMIT

    
                                                                // alright seems like we can't create triggers at runtime. 
                                                                // that's sad and ugly.

    
    printl("Catapult successfully created!\nEven though it is not supported. Expect issues.")
    return catapult
}


/*
    Other functions
*/

function findIndicator(hitEntity) { // A small function for indicators
    hitEntityOrigin = hitEntity.GetOrigin()
    indicator = Entities.FindByClassnameWithin(null, "prop_dynamic", hitEntityOrigin, 15)
    if (indicator.GetName().Find("ind-") != null) {
        return indicator
    }
    return null
}

ghosting <- true
function setGhosting(ghosting) {   // Toggles the ghost arm (as well as the lag it produces)
    
    if (ghosting == true) {
        printl("\n\nEnabled the ghost arm.\nNotice the lag. Yeah, that's all by this arm, that does a lot of things every 0.09 seconds.\n\n")
        EntFire("arm_64", "Enable")
    }
    if (ghosting == false) {
        printl("\n\nDisabled the ghost arm.\nThis is a small optimisation that prevents lag and improves fps.\n\n")
        EntFire("arm_64", "Disable")
    }
}

function vectorToString(victor) return (victor.x + " " + victor.y + " " + victor.z)