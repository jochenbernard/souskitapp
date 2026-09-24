// The recipes are for trying the app where no folder can be picked, which only a debug build offers.
#if DEBUG

extension MockRecipes {
    /// Nothing at all.
    static let empty = ""

    /// The header of the vinaigrette with no steps under it.
    static let headerOnly = """
    ---
    title: Vinaigrette
    yield: [125 ml]
    prep-time: 5 min
    tags: [sauce, classic, french]
    allergens: [mustard]
    ---
    """

    /// The steps of the vinaigrette with no header over them.
    static let stepsOnly = """
    Whisk @{1 tsp} dijon mustard@ into @{2 tbsp} red wine vinegar@ with
    @{1/4 tsp} salt@:staple until the salt dissolves.

    Beat in @{6 tbsp} olive oil@ a little at a time until it thickens, then season
    with @black pepper@:staple.
    """

    /// A header no closing fence ends, which takes the steps under it into the header.
    static let unterminatedHeader = """
    ---
    title: Vinaigrette
    yield: [125 ml]
    prep-time: 5 min
    tags: [sauce, classic, french]
    allergens: [mustard]

    Whisk @{1 tsp} dijon mustard@ into @{2 tbsp} red wine vinegar@ with
    @{1/4 tsp} salt@:staple until the salt dissolves.

    Beat in @{6 tbsp} olive oil@ a little at a time until it thickens, then season
    with @black pepper@:staple.
    """

    /// Header lines, spans, and groups the parser and the validation both object to, from souskit's tests.
    static let malformed = """
    ---
    title: Vinaigrette
    stray line
    chef: Camille
    chef: Bruno
    : Camille
    tags: [french]
    tags: [quick]
    servings: 3,2
    yield: [6 servings, 0 g]
    ---

    Fry @garlic and warm a #casserole.

    Sift @{200 g flour

    Spread the >bechamel on top.

    Add @{3,2 kg} flour@.

    Add @{200 g}@ now.

    ## Filling
    Stir in the >rouille> and the >bechamel>.

    ## Rouille
    Stir in the >filling>.

    ## filling
    Brown it.
    """

    /// Amounts, timers, flags, and escapes in the forms souskit's tests write them in.
    static let unusualAnnotations = ##"""
    ---
    yield: [6 servings, 3.2 kg]
    ---

    Sift @{200 g} flour@, mix @{1 1/2 tbsp} flour@, add @{1/2 tbsp} caster sugar@, and pour
    @{2 fl oz} milk@.

    Add @{1-2 tbsp} olive oil@, @{0.5-1.5 tbsp} milk@, @{1/2-1 tbsp} cream@, and
    @{½-1¼ tbsp} flour@.

    Add @{a pinch} salt@, loosen with @{-2 tbsp} beef stock@, and add @{\##u{0663} g} caster sugar@
    and @{\##u{FF13} g} caster sugar@.

    Add @{0} eggs@, whisk @{3} eggs@, add @{>500 g} flour@, and use @{2/4} lemon@.

    Add @{} salt@ and @{   } salt@, and stir in @{ =1 tsp} saffron@.

    Hold for ~1 h 30 min 15 s~, prove for ~1 h 20-30 min~, chill ~overnight~, rest
    ~about 40 min~, and wait ~40~ and check.

    Weigh it down with @{500 g} baking beans@:non-food, scatter @cayenne@:optional and
    @thyme@? over the top, add @beef stock@:homemade, and season with @salt@:staple.

    Add a \@ symbol, use a \# symbol, write a \{ brace, wait \~40 min, and reduce by
    \>half. Note the path C:\Users, then add @garlic@.
    """##

    /// The ten examples as one recipe, each under a heading of its own, for a long name and a long list.
    static let everyExample = """
    ---
    title: Boeuf Bourguignon, Bouillabaisse, Brioche, Crepes, Croque Monsieur, Gratin Dauphinois, \
    Madeleines, Moules Marinieres, Quiche Lorraine, and Vinaigrette
    ---

    ## Boeuf Bourguignon
    Cut @{1.2 kg} beef@ into large cubes and pat them dry. Brown @{150 g} lardons@ in a
    #casserole# for ~5 min~ until the fat runs, lift them out, then brown the beef in
    batches in the rendered fat over high heat.

    Return the beef and the lardons, dust them with @{2 tbsp} flour@, and stir over the
    heat for ~3 min~. Add @{3 cloves} garlic@ and @{2 sprigs} thyme@, pour over
    @{750 ml} red wine@ and @{500 ml} beef stock@, and bring it to a simmer.

    Cover the pot and braise at 150C for ~3 h~, until the beef gives to a fork.

    Fry @{250 g} pearl onions@ and @{250 g} button mushrooms@ in @{30 g} butter@ in a
    #frying pan# for ~20 min~ until browned, fold them through, and season with
    @salt@:staple and @black pepper@:staple.

    ## Bouillabaisse

    ## Court-Bouillon
    Soften @{2} fennel bulbs@, @{2} onions@, and @{4 cloves} garlic@ in
    @{4 tbsp} olive oil@ in a #stockpot# for ~10 min~. Add @{800 g} tomatoes@,
    @{=1 tsp} saffron@, and @{1 strip} orange zest@, pour in @{2 l} fish stock@, and
    simmer for ~30-35 min~.

    ## Rouille
    Pound @{3 cloves} garlic@ with @{1/2 tsp} salt@:staple and @{1/4 tsp} cayenne@ in
    a #mortar#, work in @{1} egg yolk@, then beat in @{100 ml} olive oil@ drop by
    drop. Thicken it with @{50 g} breadcrumbs@ soaked in a little court-bouillon.

    ## Assemble
    Poach @{1.5 kg} rockfish@ in the >court-bouillon> for ~8-10 min~ until it flakes,
    ladle it into #soup bowls# with a #ladle#, and serve the >rouille> with @croutons@.

    ## Brioche
    Mix @{500 g} flour@, @{60 g} caster sugar@, @{10 g} salt@:staple, and
    @{=10 g} yeast@ in a #mixing bowl#, add @{6} eggs@ and @{60 ml} milk@, and work
    the dough until it pulls away clean.

    Beat @{250 g} butter@ in a piece at a time, then bring the dough together and
    refrigerate it ~overnight~ (or up to ~2 days~).

    The next day, shape it into a #loaf tin# buttered with @{10 g} butter@, prove it
    until puffy, about ~2-3 h~, then bake at 180C for ~45-55 min~, tenting it with
    @foil@:non-food once it is deep brown, until it sounds hollow underneath.

    ## Crepes
    Whisk @{200 g} flour@ into a batter with @{4} eggs@, @{500 ml} milk@,
    @{50 g} melted butter@, and @{1/2 tsp} salt@:staple, then rest it ~1 h~.

    Wipe a #crepe pan# with @{10 g} butter@ over medium heat, ladle in a thin layer,
    and cook each crepe for ~1 min~ a side until lacy and gold.

    ## Croque Monsieur
    Butter @{8 slices} pain de mie@ with @{40 g} butter@ and toast them in a
    #frying pan# for ~2-3 min~ a side, then set them aside.

    Spread four slices with half of >{400 g} bechamel>, layer on @{200 g} ham@ and
    half of @{200 g} gruyere@, and close each one with a second slice.

    Sit them in a #baking dish#, spread the rest of the bechamel over the tops,
    scatter on the rest of the gruyere, and grill for ~5-8 min~ until bubbling.

    ## Gratin Dauphinois
    Rub a #gratin dish# with @{1 clove} garlic@, butter it with @{20 g} butter@, and
    heat the oven to 150C.

    Peel @{1.2 kg} potatoes@ and slice them 3 mm thick on a #mandoline#, then bring
    them to a simmer in @{500 ml} cream@ and @{300 ml} milk@ in a #heavy pot# with
    @salt@:staple, @black pepper@:staple, and @{1/4 tsp} nutmeg@.

    Tip everything into the dish, level the top, and bake for ~1 h 30 min~ until the
    potatoes are tender and the top is deep gold. Rest it ~15 min~ before serving.

    ## Madeleines
    Whisk @{2} eggs@ with @{100 g} caster sugar@ until pale, then fold in
    @{100 g} flour@ sifted with @{1 tsp} baking powder@ and the zest of @{1} lemon@.

    Fold in @{100 g} melted butter@, chill the batter ~1 h~, then spoon it into a
    #madeleine tin# buttered with @{10 g} butter@ and bake at 200C for ~8-10 min~.

    ## Moules Marinieres
    Scrub @{2 kg} mussels@ under cold water, pull away the beards, and discard any
    that stay open when tapped.

    Soften @{2} shallots@ and @{2 cloves} garlic@ in @{50 g} butter@ in a #heavy pot#
    for ~3 min~ without browning them.

    Pour in @{300 ml} white wine@, tip in the mussels, cover the pot, and steam them
    over high heat for ~4-5 min~, shaking it once, until they open. Discard any that
    stayed shut.

    Lift them into bowls with a #slotted spoon#, stir @cream@? into the liquor, season
    it with @black pepper@:staple, and pour it over. Scatter with @parsley@.

    ## Quiche Lorraine

    ## Pastry
    Rub @{125 g} butter@ into @{250 g} flour@ with @{1/2 tsp} salt@:staple in a
    #mixing bowl# until it looks like breadcrumbs, bind it with @{3 tbsp} water@, and
    rest the dough in the fridge for ~30 min~.

    ## Filling
    Fry @{200 g} lardons@ in a #frying pan# over medium heat for ~5-6 min~ until the
    fat runs, drain them, and stir them through @{4} eggs@ beaten with
    @{300 ml} cream@, @{1/4 tsp} nutmeg@, and @black pepper@:staple.

    ## Assemble
    Roll the >pastry> out and line a 24 cm #tart tin#. Cover it with @parchment@:non-food,
    fill it with @{500 g} baking beans@:non-food, and bake it blind at 190C for ~15 min~.
    Lift them out, pour in the >filling>, scatter over @{50 g} gruyere@?, and bake at
    180C for ~35 min~ until just set.

    ## Vinaigrette
    Whisk @{1 tsp} dijon mustard@ into @{2 tbsp} red wine vinegar@ with
    @{1/4 tsp} salt@:staple until the salt dissolves.

    Beat in @{6 tbsp} olive oil@ a little at a time until it thickens, then season
    with @black pepper@:staple.
    """

    /// The vinaigrette with timers a few seconds long, for watching a timer run out and go off.
    static let shortTimers = """
    ---
    title: Vinaigrette
    yield: [125 ml]
    prep-time: 5 min
    tags: [sauce, classic, french]
    allergens: [mustard]
    ---

    Whisk @{1 tsp} dijon mustard@ into @{2 tbsp} red wine vinegar@ with
    @{1/4 tsp} salt@:staple for ~5 s~ until the salt dissolves.

    Beat in @{6 tbsp} olive oil@ a little at a time for ~10 sec~ until it thickens,
    then let it stand ~1 min 5 s~ and season with @black pepper@:staple.
    """
}

#endif
