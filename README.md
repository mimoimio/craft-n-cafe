Add:
1. Roofs. In the current system there isnt already
a roof placement. And it doesnt feel like a cafe yet.
I will implement the spatial stuff along with it.
2. Game feels. Customer spawn sound, added ingredient, get cup, trash cup, serve customer sound. New order animation. Cup in hand label.


Fixes:
Customers.luau, a react customer state cycle renderer and handler.
1. All customers clustered into only one when they should occupy their own individual spot.
2. Customers already queued onto a counter will move to another specific counter if added or removed and then order taken. Make their first counter as their final position. Maybe save in grid relative to plot.

Conflicts.
1. Failing to move to a counter because there is none placed will make the customer character to just stand at the entrance and order. This will cluster and makes the proximity prompts overlap and usually impossible to tend and serve. So should customer spawn when no counter?
2. That brings to, cafe capscity. Max customers at once. Should it rely on the number of counters placed?
3. Similarly to the drinks player serve. If customer hasnt placed any station, and tend a customer, if we make customer only order ones that has station placed, that would make it none. What should happen there? What if you dont make customer only order placed ones?

That brings to, 
Things to plan:
1. Progression. Best thing is slowly revealing what player can do. Like building after they done and serve set number of customers. Like a feature unlock.
2. Ingredients available. This is also about the customers orders previously. Should by level and unlocked ingredients. But also placed stations should it?
3. Routines: quests. Daily rewards. Hourly roulettes. External trigger, action, variable rewards, investment