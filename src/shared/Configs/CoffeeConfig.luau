return {
	-- Base ingredients (order matters for instruction generation: earlier = removed last)
	-- config Ingredients can be put into an empty cup. While ones without cannot be used as a sole ingredient
	-- Normal Ingredients
	--#region
	{
		Id = "espresso",
		DisplayName = "Espresso",
		Ingredients = { "espresso" },
		ItemTip = [[A concentrated shot of coffee made by forcing pressurized hot water through finely-ground beans. It has a layer of "crema" (golden-brown foam) on top.]],
	},
	{
		Id = "water",
		DisplayName = "Water",
		Ingredients = { "water" },
		ItemTip = [[Clean, sterile, and hot drinking water.]],
	},
	{
		Id = "milk",
		DisplayName = "Milk",
		Ingredients = { "milk" },
		ItemTip = [[Freshly milked from local farm cows.]],
	},
	{
		Id = "foam",
		DisplayName = "Foam",
		ItemTip = [[Velvety, aerated milk.]],
	},
	{
		Id = "chocolate",
		DisplayName = "Chocolate Powder",
		ItemTip = [[Rich cocoa powder for a sweet, chocolaty kick.]],
	},
	{
		Id = "icecream",
		DisplayName = "Ice Cream",
		Ingredients = { "icecream" },
		ItemTip = [[Sweet, creamy, and frozen vanilla goodness.]],
	},
	{
		Id = "teabag",
		DisplayName = "Tea Bag",
		ItemTip = [[A carefully measured pouch of dried tea leaves.]],
	},
	{
		Id = "matchapowder",
		DisplayName = "Matcha Powder",
		Ingredients = { "matchapowder" },
		ItemTip = [[Finely ground powder of specially grown green tea leaves.]],
	},
	{
		Id = "boba",
		DisplayName = "Boba Pearls",
		ItemTip = [[Chewy tapioca pearls sweetened with brown sugar.]],
	},
	{
		Id = "carbonator",
		DisplayName = "Carbonator",
		ItemTip = [[Adds bubbly carbonation to any liquid.]],
	},
	{
		Id = "lemon",
		DisplayName = "Lemon Slice",
		Ingredients = { "lemon" },
		ItemTip = [[A freshly cut slice of zesty citrus.]],
	},
	{
		Id = "ice",
		DisplayName = "Ice",
		Ingredients = { "ice" },
		ItemTip = [[Frozen water cubes to chill your beverages.]],
	},
	{
		Id = "cookies",
		DisplayName = "Cookies",
		ItemTip = [[Crunchy baked treats perfect for crumbling or dunking.]],
	},
	--#endregion

	-- Exotic Ingredients
	--#region
	{
		Id = "daybloom",
		DisplayName = "Daybloom",
		ItemTip = [[A vibrant yellow flower that blooms brightly in the sunlight.]],
	},
	{
		Id = "blinkroot",
		DisplayName = "Blinkroot",
		ItemTip = [[A dull root that occasionally emits a faint, pulsing glow.]],
	},
	{
		Id = "luckyclover",
		DisplayName = "Lucky Clover",
		ItemTip = [[A rare four-leaf clover said to bring good fortune.]],
	},
	{
		Id = "moonglow",
		DisplayName = "Moonglow",
		ItemTip = [[A mystical blue flower that only opens at night.]],
	},
	{
		Id = "glowshroom",
		DisplayName = "Glowing Mushroom",
		ItemTip = [[A luminescent mushroom emitting a vibrant blue light.]],
	},
	{
		Id = "spiralaloe",
		DisplayName = "Spiral Aloe",
		ItemTip = [[A uniquely structured succulent with a striking spiral pattern.]],
	},
	{
		Id = "bloodthorn",
		DisplayName = "Bloodthorn",
		ItemTip = [[A crimson plant known for its sharp thorns and distinct hue.]],
	},
	{
		Id = "waterberry",
		DisplayName = "Waterberry",
		ItemTip = [[A juicy, aquatic berry that bursts with refreshing flavor.]],
	},
	{
		Id = "fireblossom",
		DisplayName = "Fireblossom",
		ItemTip = [[A fiery flower that thrives in extreme heat.]],
	},
	--#endregion

	-- Drinks
	{
		Id = "icedwater",
		DisplayName = "Iced Water",
		Ingredients = { "ice", "water" },
		ItemTip = [[Chilled, refreshing hydration.]],
	},
	{
		Id = "milkywater",
		DisplayName = "Milky Water",
		Ingredients = { "milk", "water" },
		ItemTip = [[A heavily diluted, milky concoction.]],
	},
	{
		Id = "icedmilkywater",
		DisplayName = "Iced Milky Water",
		Ingredients = { "ice", "milk", "water" },
		ItemTip = [[Cold and mildly creamy hydration.]],
	},
	{
		Id = "icedmilk",
		DisplayName = "Iced Milk",
		Ingredients = { "ice", "milk" },
		ItemTip = [[A simple, chilled glass of farm-fresh milk.]],
	},
	{
		Id = "icedespresso",
		DisplayName = "Iced Espresso",
		Ingredients = { "ice", "espresso" },
		ItemTip = [[A cold, concentrated jolt of caffeine.]],
	},
	{
		Id = "americano",
		DisplayName = "Americano",
		Ingredients = { "espresso", "water" },
		ItemTip = [[Espresso diluted with hot water for a smooth finish.]],
	},
	{
		Id = "icedamericano",
		DisplayName = "Iced Americano",
		Ingredients = { "ice", "espresso", "water" },
		ItemTip = [[A chilled, smooth blend of espresso and water.]],
	},
	{
		Id = "fizzyamericano",
		DisplayName = "Fizzy Americano",
		Ingredients = { "ice", "espresso", "water", "carbonator" },
		ItemTip = [[A sparkling twist on the classic Americano.]],
	},
	{
		Id = "fizzybloodthornamericano",
		DisplayName = "Fizzy Bloodthorn Americano",
		Ingredients = { "ice", "espresso", "bloodthorn", "water", "carbonator" },
		ItemTip = [[An edgy, sparkling coffee infused with sharp crimson notes.]],
	},

	{
		Id = "latte",
		DisplayName = "Latte",
		Ingredients = { "espresso", "milk" },
		ItemTip = [[Smooth espresso balanced with steamed milk.]],
	},
	{
		Id = "icedlatte",
		DisplayName = "Iced Latte",
		Ingredients = { "espresso", "milk", "ice" },
		ItemTip = [[Chilled espresso mixed with cold milk.]],
	},

	{
		Id = "macchiato",
		DisplayName = "Macchiato",
		Ingredients = { "espresso", "foam" },
		ItemTip = [[A bold espresso 'marked' with a dollop of foam.]],
	},
	{
		Id = "icedmacchiato",
		DisplayName = "Iced Macchiato",
		Ingredients = { "espresso", "foam", "ice" },
		ItemTip = [[A cold espresso topped with velvety foam.]],
	},

	{
		Id = "waterberryicecream",
		DisplayName = "Waterberry Ice Cream",
		Ingredients = { "waterberry", "icecream" },
		ItemTip = [[Sweet ice cream swirled with juicy aquatic berries.]],
	},
	{
		Id = "nightseamocktail",
		DisplayName = "Night Sea Mocktail",
		Ingredients = { "waterberry", "moonglow", "water", "carbonator", "ice", "lemon" },
	},
	{
		Id = "moonsoda",
		DisplayName = "Full Moon Soda",
		Ingredients = { "moonglow", "water", "carbonator", "ice", "lemon" },
	},
	{
		Id = "cappuccino",
		DisplayName = "Cappuccino",
		Ingredients = { "espresso", "milk", "foam" },
		ItemTip = [[Equal parts espresso, steamed milk, and rich foam.]],
	},
	{
		Id = "icedcappuccino",
		DisplayName = "Iced Cappuccino",
		Ingredients = { "espresso", "milk", "foam", "ice" },
		ItemTip = [[A refreshing, chilled blend of espresso, milk, and foam.]],
	},

	{
		Id = "affogato",
		DisplayName = "Affogato",
		Ingredients = { "espresso", "icecream" },
		ItemTip = [[A scoop of creamy ice cream "drowned" in hot espresso.]],
	},
	{
		Id = "frappuccino",
		DisplayName = "Frappuccino",
		Ingredients = { "espresso", "milk", "icecream" },
		ItemTip = [[A thick, blended treat of espresso, milk, and ice cream.]],
	},

	{
		Id = "mocha",
		DisplayName = "Mocha",
		Ingredients = { "espresso", "milk", "chocolate" },
		ItemTip = [[A comforting blend of espresso, hot milk, and rich chocolate.]],
	},
	{
		Id = "icedmocha",
		DisplayName = "Iced Mocha",
		Ingredients = { "espresso", "milk", "chocolate", "ice" },
		ItemTip = [[A cold, sweet mix of coffee, milk, and chocolate.]],
	},

	{
		Id = "tea",
		DisplayName = "Tea",
		Ingredients = { "water", "teabag" },
		ItemTip = [[A warm, comforting cup of freshly steeped tea.]],
	},
	{
		Id = "icedtea",
		DisplayName = "Iced Tea",
		Ingredients = { "water", "teabag", "ice" },
		ItemTip = [[Crisp, cold tea served over ice.]],
	},
	{
		Id = "daybloomtea",
		DisplayName = "Hot Daybloom Tea",
		Ingredients = { "water", "teabag", "daybloom" },
		ItemTip = [[A bright, sunny tea infused with Daybloom flowers.]],
	},
	{
		Id = "iceddaybloomtea",
		DisplayName = "Iced Daybloom Tea",
		Ingredients = { "water", "teabag", "ice", "daybloom" },
	},

	{
		Id = "matcha",
		DisplayName = "Matcha",
		Ingredients = { "matchapowder", "water" },
		ItemTip = [[A traditional, earthy green tea brew.]],
	},
	{
		Id = "icedmatcha",
		DisplayName = "Iced Matcha",
		Ingredients = { "matchapowder", "water", "ice" },
	},
	{
		Id = "matchalatte",
		DisplayName = "Matcha Latte",
		Ingredients = { "water", "matchapowder", "milk" },
		ItemTip = [[Earthy matcha powder whisked into creamy milk.]],
	},
	{
		Id = "icedmatchalatte",
		DisplayName = "Iced Matcha Latte",
		Ingredients = { "water", "matchapowder", "milk", "ice" },
	},
	{
		Id = "lemonmatcha",
		DisplayName = "Lemon Matcha",
		Ingredients = { "water", "matchapowder", "lemon", "ice" },
	},
	{
		Id = "oceanlatte",
		DisplayName = "Ocean Latte",
		Ingredients = { "espresso", "waterberry", "milk", "ice" },
	},
	{
		Id = "luckymatcha",
		DisplayName = "Lucky Matcha",
		Ingredients = { "water", "matchapowder", "luckyclover" },
	},
	{
		Id = "icedluckymatcha",
		DisplayName = "Iced Lucky Matcha",
		Ingredients = { "water", "matchapowder", "luckyclover", "ice" },
	},

	{
		Id = "bubbletea",
		DisplayName = "Bubble Tea",
		Ingredients = { "water", "teabag", "ice", "boba" },
		ItemTip = [[Classic iced tea loaded with chewy boba pearls.]],
	},
	{
		Id = "milktea",
		DisplayName = "Hot Milk Tea",
		Ingredients = { "water", "teabag", "milk" },
		ItemTip = [[A comforting, warm blend of tea and milk.]],
	},
	{
		Id = "icedmilktea",
		DisplayName = "Iced Milk Tea",
		Ingredients = { "water", "teabag", "milk", "ice" },
		ItemTip = [[Chilled, sweet tea blended with creamy milk.]],
	},
	{
		Id = "bobamilktea",
		DisplayName = "Boba Milk Tea",
		Ingredients = { "water", "teabag", "milk", "ice", "boba" },
		ItemTip = [[The iconic iced milk tea with chewy tapioca pearls.]],
	},
	{
		Id = "bobamoonlittea",
		DisplayName = "Moonlit Boba Tea",
		Ingredients = { "water", "teabag", "milk", "ice", "boba", "moonglow" },
	},
	{
		Id = "bobastarlittea",
		DisplayName = "Starlit Boba Tea",
		Ingredients = { "water", "teabag", "milk", "ice", "boba", "moonglow", "glowshroom" },
	},
	{
		Id = "lemontea",
		DisplayName = "Hot Lemon Tea",
		Ingredients = { "water", "teabag", "lemon" },
		ItemTip = [[Warm tea with a bright, zesty citrus kick.]],
	},
	{
		Id = "sparklingtea",
		DisplayName = "Sparkling Tea",
		Ingredients = { "water", "teabag", "carbonator", "ice" },
		ItemTip = [[Bubbly, iced tea for a refreshing fizz.]],
	},

	{
		Id = "soda",
		DisplayName = "Soda",
		Ingredients = { "water", "carbonator" },
		ItemTip = [[Simple, unflavored sparkling water.]],
	},
	{
		Id = "icedsoda",
		DisplayName = "Iced Soda",
		Ingredients = { "water", "carbonator", "ice" },
		ItemTip = [[Crisp and cold sparkling hydration.]],
	},
	{
		Id = "lemonsoda",
		DisplayName = "Lemon Soda",
		Ingredients = { "water", "lemon", "ice", "carbonator" },
		ItemTip = [[Fizzy, zesty citrus refreshment.]],
	},
	{
		Id = "zestybroot",
		DisplayName = "Zesty B' Root",
		Ingredients = { "water", "lemon", "ice", "carbonator", "blinkroot" },
		ItemTip = [[An energizing, sparkling lemon brew with a pulsing Blinkroot kick.]],
	},

	{
		Id = "hotchocolate",
		DisplayName = "Hot Chocolate",
		Ingredients = { "milk", "chocolate" },
		ItemTip = [[Warm, creamy, and deeply chocolaty.]],
	},
	{
		Id = "icedchocolate",
		DisplayName = "Iced Chocolate",
		Ingredients = { "milk", "chocolate", "ice" },
		ItemTip = [[A cold, sweet chocolate milk treat.]],
	},

	{
		Id = "lemonade",
		DisplayName = "Lemonade",
		Ingredients = { "water", "lemon" },
		ItemTip = [[Classic, sweet and sour citrus refreshment.]],
	},
	{
		Id = "icedlemonade",
		DisplayName = "Iced Lemonade",
		Ingredients = { "water", "lemon", "ice" },
		ItemTip = [[Chilled, zesty lemonade perfect for a hot day.]],
	},
	{
		Id = "icelemontea",
		DisplayName = "Ice Lemon Tea",
		Ingredients = { "ice", "lemon", "water", "teabag" },
		ItemTip = [[Cold tea brightened with a slice of fresh lemon.]],
	},

	-- New Combinations
	{
		Id = "dirtymatcha",
		DisplayName = "Dirty Matcha",
		Ingredients = { "matchapowder", "water", "milk", "espresso" },
		ItemTip = [[A creamy matcha latte spiked with a shot of bold espresso.]],
	},
	{
		Id = "iceddirtymatcha",
		DisplayName = "Iced Dirty Matcha",
		Ingredients = { "matchapowder", "water", "milk", "espresso", "ice" },
		ItemTip = [[Chilled matcha and milk with a cold espresso kick.]],
	},

	{
		Id = "matchaaffogato",
		DisplayName = "Matcha Affogato",
		Ingredients = { "matchapowder", "water", "icecream" },
		ItemTip = [[Earthy matcha poured over sweet, creamy ice cream.]],
	},
	{
		Id = "milkshake",
		DisplayName = "Milk Shake",
		Ingredients = { "milk", "icecream" },
		ItemTip = [[A classic, thick blend of milk and ice cream.]],
	},
	{
		Id = "cookiesncream",
		DisplayName = "Cookies n Cream",
		Ingredients = { "icecream", "cookies" },
		ItemTip = [[Sweet ice cream packed with crunchy cookie pieces.]],
	},
	{
		Id = "cookiesncreammilkshake",
		DisplayName = "Cookies n Cream Milk Shake",
		Ingredients = { "milk", "icecream", "cookies" },
		ItemTip = [[A drinkable treat of blended cookies, milk, and ice cream.]],
	},
	{
		Id = "matchamilkshake",
		DisplayName = "Matcha Milk Shake",
		Ingredients = { "milk", "icecream", "matchapowder" },
		ItemTip = [[A creamy, thick shake with an earthy green tea twist.]],
	},
	{
		Id = "rootbeerfloat",
		DisplayName = "Root Beer Float",
		Ingredients = { "water", "carbonator", "icecream" },
		ItemTip = [[Fizzy soda topped with a generous scoop of ice cream.]],
	},
	{
		Id = "mochafrappuccino",
		DisplayName = "Mocha Frappuccino",
		Ingredients = { "espresso", "milk", "chocolate", "icecream" },
		ItemTip = [[A blended, icy treat of chocolate, coffee, and milk.]],
	},
	{
		Id = "matchafrappuccino",
		DisplayName = "Matcha Frappuccino",
		Ingredients = { "espresso", "milk", "matchapowder", "icecream" },
		ItemTip = [[A thick, blended matcha and ice cream delight.]],
	},
	{
		Id = "volcafrappuccino",
		DisplayName = "Volcha Frappuccino",
		Ingredients = { "espresso", "milk", "chocolate", "icecream", "fireblossom" },
		ItemTip = [[A spicy, fiery chocolate and coffee blend.]],
	},
	{
		Id = "sundae",
		DisplayName = "Sundae",
		Ingredients = { "foam", "icecream" },
		ItemTip = [[A scoop of ice cream topped with velvety foam.]],
	},
	{
		Id = "sunkensundae",
		DisplayName = "Sunken Sundae",
		Ingredients = { "foam", "icecream", "waterberry" },
		ItemTip = [[A sweet ice cream treat bursting with juicy Waterberries.]],
	},
	{
		Id = "deepsleepsundae",
		DisplayName = "Deep Sleep Sundae",
		Ingredients = { "foam", "icecream", "waterberry", "moonglow" },
		ItemTip = [[A mystical, calming sundae infused with Moonglow and Waterberry.]],
	},
}
