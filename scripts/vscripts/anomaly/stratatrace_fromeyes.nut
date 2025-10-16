/*
	Portal: Anomaly vscript file
	Made by Laveig

	This one upgrades strata's trace by adding some missing functions
*/


// Right now I am commiting a sin. Do not copy paste code like that.

macros["GetEyeEndpos"] <- function(player, distance) {
    if(typeof player != "pcapEntity") 
        player = entLib.FromEntity(player)
    return player.EyePosition() + player.EyeForwardVector() * distance
}
StrataTracePlus["FromEyes"]["Bbox"] <- function(distance, player, ignoreEntities = null, settings = TracePlus.defaultSettings) {
    // Calculates the start and end positions of the trace
    local startPos = player.EyePosition()
    local endPos = macros.GetEyeEndpos(player, distance)

    ignoreEntities = TracePlus.Settings.UpdateIgnoreEntities(ignoreEntities, player)

    // Performs the strata trace and return the trace result
	return TraceLineEx(startPos, endPos, int, null, int)
}

// end of code lmao
