I didnt notice the all the gamepasses were already owned because I owned the game. So I thought all those earnings are free players. Problem:
1. I didn't notice it, making purchasing it may not give enough satisfaction to players. Maybe something like a toggleable billboardgui on player? risk of clutter.
2. The cup value calculated and showned in src\shared\ReactComponents\PlayersCup.luau is not up to date, maybe need a Utils function for this to make the calculations uniform. Another place that uses this is in src\server\Services\CustomersService.luau
3. Since it may be a lot slower without, next step i think is to halve all configurations costs. Risk making it unbalanced but maybe not.

---

45 minutes resulted in level 6 seems fine, but but from minute to minute, but i think some moments could be less lengthy, the minute to minute progression is a bit stale i think?

---

I think there may be a lack of motivation or incentive to get players play.

Speaking of it, there is a leaderboard, for customers served. Thinking of adding daily version of it.

Motivations, cannot be overwhelming, i need to reveal one by one, like currently making and serving cups in first tutorial, building is in level 3. maybe i can list them later and pace them out, and do interactive components for each like src\shared\ReactComponents\Tutorial.luau and src\shared\ReactComponents\ShopTutorial.luau

An example that needs this is the Cashier or the Register placeable. I forgot to buy them and focused on upgrades and worker.

Another is upgrades, upgrades were already in my mind when started playing, but maybe another player would lack the goal so

So ones i remembered was this. Tutorial, ShopTutorial, Register?Worker?Upgrades?Expansion?
The last 4 I dont have an order in mind.
Are there more I havent touched on?

And later ones that couldnt be reached under one session should be more emphasised better as a goal

---

Speaking of worker, they are slower than an average moderately acclamated player (or i assume a player is), therefore when there are only one worker, They will automatically take order every customer onwards, leaving no chance for player to take them when players have quality and speed better than current worker.

---

Continuing with cashiers, I thought that it could be an unlockable, meaning instead of buying manually they'll receive it automatically either when buying a worker or leveling up. Thinking about this is a bit complex.

---

And as is said in playsession1.readeable.md, there are walls in stations (teabag) and plot expansion. I am not sure if that is okay or not

---

if total spent is 8471 currently, then i would assume half or less than that if i play without passes. need to do something with that.

Also I need to be able to disable my player's gamepasses in stats. Since i toggled playtesting in PlayerDataService, I dont need to do care about disabling and reenabling it

---

Any logger improvement is allowed.