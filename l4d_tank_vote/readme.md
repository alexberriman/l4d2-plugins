#L4D2 Tank Vote Control
Competitive L4D2 has come a long way in the last few years. In previous-generation configs, tank selection was handled by the game's inbuilt lottery system, whereby tickets were awarded based on how much damage a player had inflicted to the other team. Later plugins saw the tanks rotated pseudo-randomly throughout the team, with each player having an equal chance of being given tank  before then being removed from the available tank selection pool. This therefore saw each player receive a tank at some point in the game.

This plugin takes that process one step further. By building on the [l4d2 tank control](https://github.com/alexberriman/l4d2-plugins/tree/master/l4d_tank_control) plugin, teams are able to vote in advance on which player should be awarded a specific tank. 

## How it works
On ready up, players are able to see the tank percentage via the ```sm_tank``` command. In a competitive game, some players may be better suited in playing a specific kind of tank than other players. Some common uses cases may include:

* **An easy tank with a high wipe rate** - it may be deemed a waste if it was randomly awarded to one of your better tanks. A different player may feel more comfortable playing the easier tanks.
* **Rock tanks** - some players may feel more comfortable playing a tank long than others and may want to nominate themselves to play rock tank.
* **Room tanks** - some players may have long/short arms (this can be a particular issue on ping), and may either opt to play or not play a tank in a small room. 

In the above use cases, I'm of the opinion that it's unfair the player selected to become tank ultimately comes down to a pseudo-random decision. 

### Voting on a player to become tank
You can only vote on a player to become tank **during ready-up**. Once ready up is over, if any votes have been collected (even a single vote), an infected player will be automatically queued to become tank (and therefore you only really need one player setting the tank each round, though multiple players can vote if required). 

To vote for a player, use the ```sm_tankvote``` command. You can either invoke ```sm_tankvote``` by itself and have it render a vote menu (you will need to hide the ready up menu beforehand with ```sm_hide```), or you can target a specific player with:

* ```sm_tankvote player_name``` or
* ```sm_tankvote #userid```

Where you can retrieve the user id for a player from console with ```status``` (you may opt to do this when a player has special chars in their name). 

## Recommendations
This plugin adds a bit more strategy to the game, but there are still areas it can be improved on (namely by leveraging other plugins).

* **Outputting tanks at game start** - If teams know where each tank will spawn at the start of the game, or at all times (for instance, an ```sm_tankspawns``` command which outputs spawns for each map), they'd be able to more intelligently decide who should become tank and when (though voting should still be done on a per round basis in the event a team doesn't reach tank).

* **Omitting from PUGs/mixes** - this plugin can cause issues in pugs for a few reasons. It only really works if a team is able to unanimously (generally 3/1 or 4/0) decide on who will become tank. In pugs, its likely the plugin may be abused with everybody either voting for themselves, or voting to troll (deliberately giving a player bad tank, etc.). What's more, it raises the possibility of players opting to only play certain tanks. I think it's important that players should practice playing all different kind of tanks, and having the option to vote on match day.

## Frequently asked questions
#### What's to stop one player voting on themselves to become tank each round?
That's actually impossible. This plugin simply removes the random element from the tank control plugin. Once a player has become tank, they're removed from the tank pool (and thus you're unable to vote for them) until all players have become tank. 