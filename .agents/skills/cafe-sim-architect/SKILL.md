---
name: cafe-sim-architect
description: >-
  Master game designer and technical consultant for first-person (FPS) and casual restaurant,
  coffee shop, bar, and diner simulation games. Combines mechanics from hits like Burger Shop,
  Cook, Serve, Delicious!, and Supermarket Simulator with realistic coffee and cocktail crafting,
  comedic slapstick interactions, and complete 3D asset catalogs for Godot.
---

# Café, Bar & Dirty-Sandwiches Sim Architect

A specialized skill for designing, architecting, and balancing hybrid first-person (FPS) and casual restaurant simulation games. Bridges fast-paced conveyor and assembly-line time-management loops (inspired by Burger Shop, Overcooked, and Cook, Serve, Delicious!) with authentic beverage and diner preparation, slapstick physics interactions, and Godot 3D engine workflows.

---

## When to Use

Activate this skill when:
- Designing first-person or hybrid restaurant, bar, coffee shop, or diner simulation games.
- Structuring beverage crafting systems (espresso, steamed milk, nitro, craft cocktails, boozy milkshakes).
- Incorporating greasy diner and fast-food ("dirty sandwiches", griddle smash burgers, fryers) mechanics.
- Designing physical first-person comedic physics (carrying trays, throwing drinks, shooting coffee into customer faces, ragdoll customer reactions).
- Planning 3D asset lists, Node hierarchies, and state machines for Godot.

---

## 1. The FPS Tactile & Slapstick Interaction Loop

### Two Hand Interaction Modes
1. **Serve Mode (Gentle):**
   - Place drink or food plate on the counter, customer table, or directly inside an order pickup area (`OrderPickup` `Area3D`).
   - Triggers polite NPC reaction, order recipe similarity check, tip calculation, and satisfaction score.
2. **Projectile / Throw Mode (Slapstick):**
   - Hold secondary action / charge impulse to fling full coffee mugs, cocktail glasses, or food trays directly across the room or into customer faces.

### Customer Reaction Matrix
- **Hot Coffee Hit:** NPC screams, patience drops to 0, face gets stained with coffee-splat texture/decal, leaves an angry 1-star review.
- **Alcohol / Shake Hit:** Intoxicated patrons cheer, laugh, or stumble; sober/rushed customers get disgusted and walk out.
- **Glass Shatter Physics:** Dropped or hurled glassware creates physics debris and puddles that must be mopped or swept up.

---

## 2. Conveyor & Time-Management Pacing (The Burger Shop Heritage)

- **The Supply Loop:** Instead of static shelves, dynamic items circulate on an automated conveyor track (`Path3D` + `PathFollow3D`), pneumatic chutes, or under-counter lazy susans.
- **Customer Patience Meters:** Visual star/bar meters with escalating urgency audio cues.
- **Patience Boosters:** Handing impatient customers a warm cookie, chocolate pastry, or glass of ice water pauses their patience decay.
- **Day-to-Night Phase Transitions:**
  - **Day Shift (Coffee & Shakes):** Fast pace, rushed commuter NPCs, high volume, precision timing (grind $\rightarrow$ tamp $\rightarrow$ steam).
  - **Night Shift (Cocktails & Nightlife):** Dim ambient lighting, neon glow, craft mixology, higher margins, unruly intoxicated patrons.

---

## 3. In-Game Recipe Directory

### Coffee & Shakes
- **Espresso / Americano:** Grind beans $\rightarrow$ Tamp portafilter $\rightarrow$ Pull extraction $\rightarrow$ Top with hot water (if Americano).
- **Flat White / Latte:** Espresso base $\rightarrow$ Steam milk wand (microfoam timing) $\rightarrow$ Pour art.
- **Caramel Macchiato:** Espresso base $\rightarrow$ Steamed milk $\rightarrow$ Caramel syrup drizzle pump.
- **Vanilla Shake:** 3 scoops vanilla gelato $\rightarrow$ Milk splash $\rightarrow$ Vanilla syrup $\rightarrow$ Blender pulse $\rightarrow$ Tall glass $\rightarrow$ Whipped cream rosette $\rightarrow$ Cherry.

### Cocktails & Coffee-Liquor Hybrids
- **Espresso Martini:** Shaker tin $\rightarrow$ Ice $\rightarrow$ Vodka $\rightarrow$ Coffee Liqueur $\rightarrow$ Fresh hot espresso $\rightarrow$ Hard shake QTE $\rightarrow$ Strain into Coupe glass $\rightarrow$ 3 coffee beans.
- **Smoked Carajillo:** Rocks glass $\rightarrow$ Single clear ice sphere $\rightarrow$ Licor 43 $\rightarrow$ Espresso poured slowly over bar spoon (density layer check) $\rightarrow$ Glass cloche smoke trap.
- **Irish Coffee:** Footed glass $\rightarrow$ Irish Whiskey $\rightarrow$ Brown sugar syrup $\rightarrow$ Hot filtered coffee $\rightarrow$ Cold heavy cream layer floated over spoon.
- **Bourbon Caramel Shake (Boozy):** Bourbon whiskey $\rightarrow$ Salted caramel syrup $\rightarrow$ Custard base $\rightarrow$ Blend $\rightarrow$ Chocolate drizzle rim.
- **White Russian Nitro:** Vodka $\rightarrow$ Kahlúa $\rightarrow$ Nitro Cold Brew $\rightarrow$ Sweet cream floated on top.

### Fast-Food & Diner ("Dirty-Sandwiches") Station
- **Smash Burger:** Beef ball placed on hot flat-top $\rightarrow$ Heavy metal press slam $\rightarrow$ Flip $\rightarrow$ Melted American cheese $\rightarrow$ Toasted potato bun $\rightarrow$ House sauce squirt.
- **Loaded Crispy Fries:** Drop basket in fryer vat $\rightarrow$ Buzzer ding $\rightarrow$ Toss with salt $\rightarrow$ Paper sleeve scoop $\rightarrow$ Cheese sauce pump.

---

## 4. Master 3D Object & Appliance Catalog

### Appliances & Stations
- Commercial dual-group espresso machine with functional pressure gauges and steam wands.
- Coffee bean grinder with hopper and knock-box for used grounds.
- Bar blender with removable glass jug.
- Double-vat deep fryer with removable wire mesh baskets.
- Flat-top griddle with grease trap and exhaust hood.
- Dual-draft tap tower (beer and nitro cold brew).
- Ice well with clear ice spheres and metal scoop.
- Speed rail liquor shelf with spirit and syrup bottles.

### Handheld Props & Glassware
- **Glassware:** Demitasse cups, ceramic latte mugs, coupe glasses, rocks tumblers, tall milkshake fountain glasses, takeaway paper cups.
- **Bar tools:** Boston shaker set, Hawthorne strainer, jigger measure, bar spoon, blowtorch.
- **Kitchen tools:** Burger smash weight, flat metal spatula, condiment squirt bottles, fry scoop.
- **Cleaning tools:** Bar rag, push broom, sink spray nozzle, trash compactor.

---

## 5. Godot Engine Architecture Guidelines

- **Player Controller (`CharacterBody3D`):**
  - First-person head bob, raycast interactor (`DragRaycast`), and hand socket (`ItemSocket3D`).
  - Supports dual input: primary action (use/interact/place) and secondary action (charge and launch projectile).
- **Drink State Resource (`DrinkState.gd`):**
  - Pure data container tracking ingredients, liquid volumes, temperature, shake status, and garnish list.
- **Order & Customer System (`Customer3D.gd`):**
  - Uses `Area3D` for interaction hitboxes and collision detection for airborne thrown items.
  - State machine: `SEATED` $\rightarrow$ `WAITING` $\rightarrow$ `IMPATIENT` $\rightarrow$ `EATING/DRINKING` $\rightarrow$ `LEAVING` with a separate `HIT_BY_PROJECTILE` ragdoll branch.
- **Optimization for Web & Telegram:**
  - Low-poly stylized geometry using single texture atlases to minimize draw calls.
  - Lightweight CPU particle systems for steam, grease smoke, and drink splashes.

