// Individual player stats!!!
/datum/stats
    var/highestscore 		= 0 //This is the overall contribution made to round score
    var/plasmashipped		= 0 //How much plasma has been sent to centcom?
    var/stuffshipped		= 0 //How many centcom orders have cargo fulfilled?
    var/stuffforwarded		= 0 //How many cargo forwards have been fulfilled?
    var/stuffnotforwarded	= 0 //How many cargo forwards have not been fulfilled?
    var/stuffharvested		= 0 //How many harvests have hydroponics done (per crop)?
    var/oremined			= 0 //How many chunks of ore were smelted
    var/eventsendured		= 0 //How many random events did we endure?
    var/maxpower			= 0 //Most watts in grid on any of the world's powergrids.
    var/kills   			= 0 //Amount of total kills
    var/deadsilicon			= 0 //Amount of total silicon kills
    var/deadai      		= 0 //Amount of total AI kills
    var/mess				= 0 //How much messes on the floor were made
    var/litter				= 0 //How much trash was made
    var/meals				= 0 //How much food was actively cooked
    var/slimes				= 0 //How many slimes were harvested
    var/artifacts			= 0 //How many large artifacts were analyzed and activated
    var/disease_good		= 0 //How many unique diseases affected living mobs of cumulated danger <3
    //var/disease_vaccine		= null //Which many vaccine antibody isolated
    //var/disease_vaccine_score= 0 //the associated score
    var/disease_extracted	= 0 //Score based on the unique extracted effects
    var/disease_effects		= 0 //Score based on the unique extracted effects
    var/disease_bad			= 0 //How many unique diseases affected living mobs of cumulated danger >= 3
    var/disease_most		= null //Most spread disease
    var/disease_most_count	= 0 //Most spread disease
    var/turfssingulod		= 0 //Amount of turfs eaten by singularities we created.

    var/foodeaten			= 0 //How much food was consumed
    var/clownabuse			= 0 //How many times a clown was punched, struck or otherwise maligned
    var/slips				= 0 //How many times we have slipped during this round
    var/gunsfired			= 0 //Gun bullets fired successfully
    var/hangmanrecord		= 0 //Most correct letter guesses from Curse of the Hangman
    var/richestcash			= 0
    var/biggestshoalcash	= 0
    var/dmgestdamage		= 0
    var/explosions			= 0 //How many explosions we caused total
    var/largeexplosions		= 0 // >1 devastation range
    var/largest_TTV			= 0 //The largest Tank Transfer Valve explosion we achieved
    var/deadpets			= 0 //Only counts 'special' simple_mobs, like Ian, Poly, Runtime, Sasha etc
    var/buttbotfarts		= 0 //Messages mimicked by buttbots we created.
    var/shardstouched		= 0 //+1 for each pair of shards that bump into eachother.
    var/kudzugrowth			= 0 //Amount of kudzu tiles successfully grown, even if they were later eradicated.
    var/nukedefuse			= 9999 //Lowest seconds the nuke had left when it was defused.
    var/tobacco				= 0 //Amount of cigarettes, pipes, cigars, etc. lit
    var/lawchanges			= 0 //Amount of AI modules used.
    var/syndiphrases		= 0 //Amount of times a syndicate code phrase was used
    var/syndisponses		= 0 //Amount of times a syndicate code response was used
    var/time				= 0
    var/totaltransfer		= 0
    var/turfsonfire			= 0

    var/list/datum/achievement/achievements