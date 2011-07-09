= DotA Replay Parser

DotA Replay Parser (DRP) is a parsing tool to pull various bits of information from a Warcraft 3 replay file, specificially of a DotA game.

== Authors

* Justin Cossutti ( justin.cossutti@gmail.com )
* Tim Sjoberg

== Features

Displays end game statistics that include:

* Hero Kills / Deaths / Assists
* Creep Kills / Denies / Neutrals
* End game gold
* End game Inventory
* POTM Arrow Accuracy
* Pudge Hook Accuracy

* Tries to automatically determine the winning side.
* Counts and groups various actions by players.
* Generates time ordered lists of player’s obtained items and learned skills.
* Displays colored chat
* An easily updatably XML database of Items, Skills and Heroes.


== Installation

Simply build the Gem

	rake build

and add the following to your Gemfile:

	gem "dota_replay_parser"


== Note

This parser is far from complete. Many parts of the port have been excluded that were either irrelevant to DotA, or are still to be added in. 

You use this gem as is and at your own risk. There are bound to be bugs, you have been warned.


== Contributing

Feel free to fork this project and send in patches, but remember to please credit the parties involved.


== Credits

* Julas - {Original PHP DotA parser}[http://w3rep.sourceforge.net/]
* rush4hire - DotA port of Jula's parser
* esby - 6.56 XML data file
* {Tedi Rachmadi}[http://tedirachmadi.web.id/] - Modified Jula's parser (codenamed Reshine)
* Seven - {Reshine modification and additional XML data files}[http://www.playdota.com/forums/2471/php-dota-replay-parser-cdp/]