# LootTracker
Tracks loot in World of Warcraft 1.12

## Changes in this fork
- Added functionality to work when on group loot for logging loot
- Added in sorting by rarity for exporting
- Added a search box to search the current RaidID/loot list for items of interest
- **Added new function to browse item loot instances by Player name with associated button to search for the player of interest**
- **Added search via item specifically (can put in RaidID search bar Item:Gauntlets and it will show all instances through all raids by that string. Returns all instances where an item with the word Gauntlets was looted in every saved instance.**
- **Export by player name**

### You can import your own GP Cost / DKP Cost
Just edit the table in the file LootTrackerGP.lua / You need the itemid and the price
itemid can be found at http://db.vanillagaming.org/?item=22630

### in action
![Loot Tracker](http://i.imgur.com/2qmbKss.jpg "Loot Tracker")

### Main Window empty
![Main Window](http://i.imgur.com/F8FXaB0.jpg "Main Window")

### Options Menu
Set your desired tracking level and export options

![Options](http://i.imgur.com/3yPSkCj.jpg "Options")

### Item Edit 
Right Click on the item to edit it
Set Offspec (half price) or dissenchant (no gp)

![Item edit](http://i.imgur.com/1zmQS4r.jpg "Item edit")

### Basic Export
![Export](http://i.imgur.com/Qf9ECzS.jpg "Export")

### Detailed Export
export with timestamp and gp price
use CTRL+C to copy all and paste it on your guilds homepage

![Detailed Export](http://i.imgur.com/ZG8POmH.jpg "Detailed Export")

### console help
![Console](http://i.imgur.com/y8UHMWs.jpg "Console")
