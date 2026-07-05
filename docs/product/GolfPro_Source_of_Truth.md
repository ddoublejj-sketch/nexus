# Golf Pro - Roblox Build Source of Truth

Version: 1.0
Date: 2026-07-05
Audience: Codex, Roblox engineers, Rojo maintainers, UI designers, 3D/world builders, QA, and LiveOps
Primary objective: provide a build-ready source of truth for a Roblox golf game called **Golf Pro**.

---

## 0. Non-negotiable instruction to Codex

Treat this document as the product and engineering source of truth for Golf Pro. The existing Rojo, Obsidian, command, and project scaffolding systems are assumed to already exist and should not be rebuilt unless explicitly requested. Codex should build gameplay systems, data models, UI, course tooling, server services, and first playable course content according to this spec.

Core rules:

1. Build **server-authoritative golf**. The client can request shots and render predictions, but the server validates, simulates, scores, and persists the round.
2. Build courses as **data-driven CourseSpecs**, not as hardcoded one-off maps.
3. Build clubs as **data-driven ClubSpecs**, not as individual scripts.
4. Build the first course as a licensing-safe, premium championship-style course unless explicit licenses are later provided for exact real-world names, layouts, imagery, trademarks, and course likenesses.
5. Do not import, trace, export, screenshot, reconstruct, or otherwise derive Roblox course assets from Google Earth, Google Maps satellite imagery, Street View, Masters, PGA, Augusta National, or other protected sources unless a license has been obtained and documented in the CourseSpec.
6. A new course should display **Course Record: 0 / Unclaimed** until the first valid ranked completion. Internally, records must be stored as `nil` / `UNSET`, not as an actual zero-stroke score.
7. Every ranked score and course record must be auditable from server-side shot logs.
8. Ship the MVP with cosmetic-only monetization and cosmetic/trophy tournament rewards. Do not ship cash, Robux, entry-fee, or wager-style tournament prizes until legal and Roblox-policy review is complete.

---

## 1. Product vision

Golf Pro is a competitive, social, premium-feeling golf game inside Roblox. The fantasy is simple: players feel like they are stepping onto famous championship-style golf courses with friends, using a full set of clubs, making real shot decisions, and chasing course records.

The game should feel more like a legitimate golf simulation adapted for Roblox than a toy minigolf experience. It should support casual players with clean UI, forgiving early tuning, and fast modes, while also supporting serious competition through ranked 18-hole rounds, scramble formats, verified leaderboards, and course records.

The core product promise:

> Play high-quality golf on premium championship-style courses in Roblox, compete with friends, and become the record holder for a course.

### 1.1 Target players

Primary players:

- Roblox sports players who want a polished, competitive golf experience.
- Groups of friends who want private golf matches and 2v2 scramble.
- Competitive players who want leaderboard and course-record status.
- Streamers and creators who can host live golf events.

Secondary players:

- Casual players who want a relaxed golf course social experience.
- Players who enjoy cosmetics, bags, balls, trails, club appearances, and progression.

### 1.2 Design pillars

1. **Real golf feel, Roblox accessibility.** The player should think about club, lie, wind, distance, slope, green speed, and accuracy, but the actual swing input must be learnable on keyboard, mobile, controller, and console.
2. **Records matter.** Every course launches unclaimed. The first valid player sets the first record. Records become more competitive as the community improves.
3. **Friends matter.** Golf Pro must support private party rounds, 2v2 scramble, and tournament-friendly formats from the start.
4. **Courses are content.** The course pipeline must support adding many courses over time without rewriting gameplay systems.
5. **Fair competition.** Ranked rounds must be server-authoritative, auditable, and protected against client tampering.
6. **No IP landmines.** Real-world course authenticity is desirable, but exact real-world names, layouts, and imagery require documented rights. The default path is fictional premium courses inspired by broad golf design principles.

---

## 2. Legal, platform, and IP guardrails

This section is intentionally strict because it affects whether the game can safely publish, monetize, and scale.

### 2.1 Real-course strategy

Golf Pro should support two course categories:

| Category | Description | Allowed for MVP? | Notes |
|---|---|---:|---|
| `fictional_premium` | Original course with championship feel, inspired by broad golf architecture patterns but not copied from a real course. | Yes | Default launch path. |
| `licensed_real` | Exact or near-exact real-world course built from licensed references and with rights to use name, layout, and likeness. | Only after documentation | Requires legal review and signed rights. |
| `unlicensed_real_like` | A course marketed as a real course, copied from real maps, or named after real protected marks. | No | Do not build or publish. |

Every CourseSpec must include:

```lua
legal = {
    category = "fictional_premium", -- or "licensed_real"
    approvedNameUsage = false,
    approvedLayoutUsage = false,
    approvedImageryUsage = false,
    sourceNotes = "Original design. No Google imagery, no protected tournament/course branding."
}
```

### 2.2 Naming policy

Do not use the following in the MVP unless licenses are acquired:

- Augusta National
- The Masters
- Masters Tournament
- PGA Tour
- PGA Championship
- FedExCup
- Green Jacket
- Any official course logo, tournament logo, course crest, sponsor logo, broadcast package, or real club brand

MVP course naming should be fictional and premium:

- Pinebrook National
- Magnolia Pines
- Azalea Ridge
- Cypress Hollow
- Royal Sandstone
- Blackwater Links
- Palmetto Trace

Avoid marketing copy like "play Augusta" or "Masters simulator." Safer phrasing:

- "Championship-style golf courses"
- "Premium tournament-inspired layouts"
- "Realistic golf strategy in Roblox"
- "Original courses with professional-level challenge"

### 2.3 Mapping and imagery policy

Codex and builders must not use Google Earth or Google Maps satellite imagery as a direct construction source for Roblox course assets. Do not export screenshots, trace fairway outlines, reconstruct 3D geometry, or build similar content from Google Earth output.

Approved reference paths:

1. **Licensed course data from the course owner, architect, or authorized provider.** Best path for exact real-world courses.
2. **Paid/licensed geospatial data** with explicit commercial game-use rights.
3. **USGS/public elevation and land data** where public domain or otherwise compatible.
4. **OpenStreetMap data** only if attribution and ODbL obligations are satisfied and the data is suitable for the use case.
5. **Original designer-created CourseSpecs** based on golf principles, not copying protected layouts.
6. **Player surveying or original GPS capture** only if access and rights permit it.

Google products may be used for casual visual understanding only if such use is permitted, but they must not be the source of the shipped course geometry, textures, meshes, or marketing materials.

### 2.4 Prize and tournament policy

MVP tournaments should use non-cash and non-Robux rewards:

- Trophy badge
- Winner title
- Cosmetic ball trail
- Cosmetic bag tag
- Profile banner
- Hall of Champions listing

Do not ship:

- Cash prize tournaments
- Robux prize tournaments
- Paid entry tournaments with prizes
- Wagers, betting, side pots, loot-box style outcomes, chance-based prizes, or any mechanism where users risk Robux or value for an uncertain return

A later prize system can be designed behind a feature flag, but it must stay disabled until reviewed. Tournament code should support a `prizePolicy` object, but default to cosmetic-only.

```lua
prizePolicy = {
    type = "cosmetic_only",
    cashEnabled = false,
    robuxEnabled = false,
    entryFeeEnabled = false,
    legalApprovalId = nil
}
```

---

## 3. MVP definition

### 3.1 MVP goal

Ship one polished playable course, one practice range, complete swing mechanics, multiplayer private rounds, 2v2 scramble, server-side scoring, course records, and leaderboards.

### 3.2 MVP included scope

The MVP includes:

- Main menu / clubhouse lobby.
- Practice range.
- One 18-hole premium fictional course.
- Full 14-club set.
- Realistic shot system with power, accuracy, lie, club, wind, and green speed.
- Stroke play solo and private multiplayer.
- 2v2 scramble.
- 9-hole and 18-hole options.
- Course records.
- Leaderboards by course, tee, mode, ruleset, and physics version.
- Player profiles, stats, best rounds, and cosmetics inventory.
- Ranked/unranked distinction.
- Basic cosmetics: ball skin, bag skin, trail, title.
- Server-authoritative anti-cheat validation.
- Mobile, keyboard/mouse, and controller support.
- Analytics events for balancing and retention.

### 3.3 MVP excluded scope

Do not include in MVP:

- Exact unlicensed real-world courses.
- Cash prizes or Robux prizes.
- Branded real golf clubs or real manufacturers.
- Complex club stat monetization or pay-to-win upgrades.
- Spectator broadcast tools beyond basic watch/follow camera.
- Course editor for players.
- Fully asynchronous multi-day tours unless time permits after MVP.
- Weather systems beyond wind and simple lighting presets.

---

## 4. Core game loops

### 4.1 First-time player loop

1. Player joins Golf Pro.
2. Main menu opens with Play, Practice, Courses, Leaderboards, Locker, Settings.
3. First-time tutorial prompts player to go to the practice range.
4. Player learns aim, club selection, power bar, accuracy bar, putting.
5. Player completes a 3-hole starter challenge.
6. Player unlocks casual course play.
7. Player sees the course record board and understands the chase.

### 4.2 Standard play loop

1. Player selects course, mode, tee, and round length.
2. Player enters lobby or reserved match server.
3. Server loads CourseSpec and initializes RoundState.
4. Player plays each hole with full scoring.
5. Scorecard updates after every hole.
6. On completion, server validates ranked eligibility.
7. Server persists round, stats, XP, cosmetics progression, leaderboards, and possible course record.
8. Results screen shows score, to-par, best holes, longest drive, GIR, fairways hit, putts, and course-record status.

### 4.3 Course-record loop

1. New course launches with display state: `Course Record: 0 / Unclaimed`.
2. First valid ranked 18-hole completion sets the record.
3. Record holder receives a title and course banner mention.
4. Future lower scores replace the record.
5. Tied scores do not replace the existing holder unless a configured tie-breaker says otherwise. MVP tie rule: earliest verified record remains.
6. Every record update creates a permanent audit entry.

### 4.4 Social loop

1. Player invites friends.
2. Party selects casual stroke play, 2v2 scramble, or private practice.
3. Party loads into reserved server.
4. Players compete, chat, emote, spectate shots, and compare scorecards.
5. Players rematch or switch course.

---

## 5. Game modes

### 5.1 Practice Range

Purpose: teach shot mechanics and let players test clubs.

Features:

- Infinite balls.
- Distance markers at 50, 100, 150, 200, 250, 300 yards.
- Club selector.
- Wind toggle for unranked practice.
- Shot stats panel: carry, roll, total distance, launch, offline yards, lie penalty.
- Putting green with slope tutorial.

### 5.2 Solo Stroke Play

Player completes 9 or 18 holes. Ranked available only for 18 holes on official ranked settings.

Ranked conditions:

- Official tee set.
- Official pin set.
- Official wind preset or deterministic daily wind.
- No mulligans.
- No admin commands.
- No debug teleports.
- No assists beyond allowed UI.
- Full round completed on current physics version.

### 5.3 Private Friends Stroke Play

2 to 4 players in a private reserved server. Can be ranked only if all ranked conditions are met and the mode is allowed. MVP should default private friend rounds to unranked unless the player explicitly selects ranked.

### 5.4 2v2 Scramble

Teams of two. Each player on the team hits from the selected team ball position. Team records one score per hole.

Rules:

1. Both teammates tee off.
2. Team selects one ball.
3. Both teammates hit next shot from selected ball location.
4. Repeat until holed.
5. Team score increments by one stroke per team shot cycle, not per individual shot.
6. If selection timer expires, server auto-selects best valid ball by heuristic: holed ball first, green in regulation value, distance to pin, lie quality, penalty status.

Ranked 2v2 scramble records must be stored separately from solo records.

### 5.5 Tournament Events

MVP tournament events are leaderboard windows, not cash prize events.

Supported later:

- Daily challenge course.
- Weekend open.
- Club championship.
- Invitational/private code event.
- Creator-hosted event.

Tournament config:

```lua
TournamentConfig = {
    id = "weekend_open_001",
    courseId = "course_pinebrook_v1",
    mode = "solo_stroke_18",
    startsAtUnix = 0,
    endsAtUnix = 0,
    maxAttempts = 3,
    ranked = true,
    prizePolicy = {
        type = "cosmetic_only",
        cashEnabled = false,
        robuxEnabled = false,
        entryFeeEnabled = false
    }
}
```

---

## 6. Controls and swing mechanics

### 6.1 Input design

Golf Pro should support keyboard/mouse, mobile touch, and controller.

Default swing system: **3-click precision bar**.

1. First click/tap/press starts backswing.
2. Second click sets power.
3. Third click sets accuracy/impact timing.

Why 3-click:

- Familiar golf-game pattern.
- Works on all platforms.
- Skill-based without being too hard.
- Easy for server validation.
- Allows competitive mastery.

Optional later: analog stick swing mode.

### 6.2 Shot phases

Each shot moves through these phases:

1. `PreShot`: player selects club, shot type, aim, and spin.
2. `PowerSet`: player commits power.
3. `AccuracySet`: player commits accuracy.
4. `ServerValidate`: server validates club, lie, aim, timing, and turn state.
5. `Simulate`: server computes ball result and/or server-owned ball physics.
6. `Replicate`: clients see ball flight, camera, tracer, roll, and final lie.
7. `ScoreUpdate`: server updates stroke count and next turn.

### 6.3 ShotIntent payload

Client sends intent, never final ball position.

```lua
ShotIntent = {
    roundId = "string",
    holeIndex = 1,
    playerUserId = 0,
    clubId = "driver",
    shotType = "normal", -- normal, punch, flop, chip, putt
    aimYawDeg = 0,
    aimPitchDeg = 0,
    power01 = 0.0,
    accuracy01 = 0.0,
    spin01 = 0.0,
    drawFade01 = 0.0,
    clientShotNonce = "string",
    clientTimestamp = 0
}
```

Server validation checks:

- Player is in this round.
- It is player's/team's turn.
- Ball is not already moving.
- Club is allowed from current lie.
- Power and accuracy values are within expected bar result ranges.
- Aim direction is not impossible based on player/camera constraints.
- Shot rate is not spammed.
- Player has not already submitted a shot with this nonce.

### 6.4 Ball simulation approach

MVP should use a deterministic server-side shot solver for ranked scoring, with a visual ball object following the server result. This is preferred over relying entirely on Roblox physics because course records need consistency and auditability.

Server computes:

- Launch vector.
- Carry distance.
- Dispersion.
- Wind effect.
- Elevation/slope effect.
- Surface bounce.
- Roll distance.
- Final lie.
- Penalties.

Visual implementation options:

1. **Deterministic path + visual tween/projectile:** best for ranked consistency.
2. **Server-owned physics ball:** more organic, harder to audit.
3. **Hybrid:** deterministic target with physics-like visuals.

Use hybrid for MVP:

- Server computes official final result.
- Server sends key path points.
- Client renders ball path and tracer.
- Server places authoritative ball at final resting spot.

### 6.5 Shot formula targets

These are not final tuning constants, but they define system behavior.

```lua
effectivePower = Curve(power01) -- low skill floor, high skill ceiling
baseCarry = ClubSpec.maxCarryYards * effectivePower
lieMultiplier = LieSpec[currentLie].carryMultiplier
accuracyErrorYards = AccuracyToDispersion(accuracy01, ClubSpec.dispersion)
windOffset = WindModel(ballFlightTime, windVector, shotHeight)
elevationAdjustment = ElevationModel(startY, landingY, clubTrajectory)
carryYards = baseCarry * lieMultiplier + elevationAdjustment
lateralOffsetYards = accuracyErrorYards + windOffset.x + shotShapeOffset
rollYards = SurfaceRoll(surfaceType, landingAngle, greenSpeed, slope)
```

### 6.6 Putting

Putting uses the same input structure but different physics:

- Club forced to putter on green unless player chooses chip from fringe.
- Power range is short, based on distance to hole and slope.
- UI shows green slope arrows or beads.
- Green speeds vary by course and ranked condition.
- Cup capture radius should be forgiving enough for Roblox scale but not random.

Cup rules:

- Ball is holed when it enters cup capture zone below maximum capture speed.
- If ball crosses cup too fast, lip-out animation may play and ball continues.
- MVP can simplify lip-outs but should still prevent unrealistic high-speed hole-outs.

---

## 7. Full 14-club set

### 7.1 Club philosophy

All players begin with a complete functional set of 14 clubs. Monetization should be cosmetic by default. Club skins may change appearance, sound, trail, and feel, but ranked stat advantages should be avoided.

### 7.2 Default ClubSpec

Canonical units are yards. Convert to studs only in rendering/simulation adapters.

| Slot | Club | Max Carry | Loft Feel | Dispersion | Use Case |
|---:|---|---:|---|---:|---|
| 1 | Driver | 285 | Low | High | Maximum tee distance |
| 2 | 3 Wood | 250 | Low-mid | Medium-high | Tee or long fairway |
| 3 | 5 Wood | 230 | Mid | Medium | Long approach |
| 4 | 4 Hybrid | 215 | Mid | Medium | Controlled long shot |
| 5 | 5 Iron | 195 | Mid | Medium | Long iron |
| 6 | 6 Iron | 180 | Mid | Medium-low | Approach |
| 7 | 7 Iron | 165 | Mid-high | Medium-low | Approach |
| 8 | 8 Iron | 150 | High | Low-medium | Approach |
| 9 | 9 Iron | 135 | High | Low-medium | Short approach |
| 10 | Pitching Wedge | 120 | High | Low | Short approach |
| 11 | Gap Wedge | 105 | High | Low | Controlled wedge |
| 12 | Sand Wedge | 85 | High | Low | Bunker/short shot |
| 13 | Lob Wedge | 65 | Very high | Low | Flop/short green |
| 14 | Putter | 40 | Ground | Very low | Putting |

Example data:

```lua
ClubSpec = {
    id = "driver",
    displayName = "Driver",
    category = "wood",
    maxCarryYards = 285,
    minCarryYards = 120,
    loftDeg = 10.5,
    baseDispersionYards = 18,
    mishitPenalty = 0.28,
    spinBias = 0.15,
    rollBias = 0.85,
    allowedShotTypes = {"normal", "punch"},
    rankedStatProfile = "default_v1"
}
```

### 7.3 Shot types

| Shot Type | Available From | Description | Tradeoff |
|---|---|---|---|
| Normal | Most clubs/lies | Standard trajectory | Balanced |
| Punch | Woods/irons | Lower flight | Less wind, more roll |
| Flop | Wedges | High soft shot | Hard timing, short range |
| Chip | Wedges/short irons | Low short shot | More roll |
| Putt | Green/fringe | Ground roll | Slope sensitive |

---

## 8. Course system

### 8.1 Canonical units and scale

Course data is authored in yards. Roblox rendering converts yards to studs through `CourseScale`.

MVP recommended:

```lua
CourseUnits = {
    canonical = "yards",
    studsPerYard = 1.0, -- can be tuned without changing authored course data
    verticalExaggeration = 1.0
}
```

Do not store official gameplay distances in studs. Store in yards and derive studs at runtime.

### 8.2 CourseSpec structure

```lua
CourseSpec = {
    id = "course_pinebrook_v1",
    displayName = "Pinebrook National",
    shortName = "Pinebrook",
    version = "1.0.0",
    legal = {
        category = "fictional_premium",
        approvedNameUsage = false,
        approvedLayoutUsage = false,
        approvedImageryUsage = false,
        sourceNotes = "Original championship-style course. No protected real-world layout or imagery."
    },
    rankedEligible = true,
    physicsVersion = "golf_physics_v1",
    par = 72,
    yardage = 7275,
    defaultTeeSet = "championship",
    defaultPinSet = "sunday",
    environment = {
        biome = "southern_pines",
        greenSpeed = 12.0,
        fairwayFirmness = 0.65,
        roughPenalty = 0.78,
        bunkerPenalty = 0.62,
        defaultWindProfile = "ranked_daily_v1"
    },
    holes = {}
}
```

### 8.3 HoleSpec structure

```lua
HoleSpec = {
    index = 1,
    displayName = "Opening Draw",
    par = 4,
    handicap = 7,
    teeBoxes = {
        championship = { position = Vector3.new(0, 0, 0), yardage = 410 },
        member = { position = Vector3.new(20, 0, 30), yardage = 365 }
    },
    green = {
        center = Vector3.new(410, 0, 0),
        radiusYards = 18,
        firmness = 0.55,
        slopeMapId = "h01_green_slope_v1",
        pinPositions = {
            sunday = Vector3.new(407, 0, -5),
            easy = Vector3.new(398, 0, 7)
        }
    },
    zones = {
        fairwayPolygons = {},
        roughPolygons = {},
        deepRoughPolygons = {},
        bunkerPolygons = {},
        waterPolygons = {},
        outOfBoundsPolygons = {},
        cartPathSplines = {}
    },
    cameras = {
        tee = { yaw = 0, pitch = -8, distance = 26 },
        approach = { yaw = 0, pitch = -10, distance = 22 },
        green = { yaw = 180, pitch = -12, distance = 18 }
    }
}
```

### 8.4 Surface zones

Every point where a ball can land must resolve to exactly one lie/surface:

| Priority | Surface | Effect |
|---:|---|---|
| 1 | Holed | Ends hole |
| 2 | Water | Penalty/drop |
| 3 | OutOfBounds | Penalty/re-hit or drop |
| 4 | Bunker | Carry and spin penalty |
| 5 | Green | Putting enabled |
| 6 | Fringe | Putt/chip enabled |
| 7 | Fairway | Ideal lie |
| 8 | Rough | Carry penalty and dispersion increase |
| 9 | DeepRough | Larger penalty |
| 10 | NativeArea | Severe penalty |
| 11 | DefaultRough | Fallback |

Zone resolution must be server-side. Client can show the current lie, but server owns the result.

### 8.5 Hazards and penalties

MVP penalty rules:

- Water: +1 stroke, drop at nearest configured drop zone or previous crossing point.
- Out of bounds: +1 stroke, re-hit from previous position or nearest configured drop zone depending on ruleset.
- Unplayable: optional +1 stroke manual drop, unranked in MVP unless rules are fully implemented.
- Lost ball is not needed for MVP because the server always knows the ball.

### 8.6 First course: Pinebrook National

Pinebrook National is the MVP course. It is an original championship-style 18-hole course designed to evoke premium tournament golf without copying an unlicensed real-world course.

Theme:

- Southern pines, rolling elevation, white sand bunkers, bright flowers, clean fairways, fast greens.
- High-stakes back nine.
- Signature short par 3 over water.
- Risk/reward par 5s.
- Dramatic 18th finishing hole uphill toward clubhouse.

Important legal note: Pinebrook National must not use protected course names, exact hole routing, exact fairway shapes, exact green complexes, real logos, or satellite-derived geometry from any real course.

#### Pinebrook National hole list

| Hole | Par | Championship Yards | Design Intent |
|---:|---:|---:|---|
| 1 | 4 | 410 | Gentle dogleg right opener; forgiving fairway, guarded green. |
| 2 | 5 | 575 | Reachable in two for aggressive players; creek short of green. |
| 3 | 4 | 365 | Short positional par 4; bunkers punish driver. |
| 4 | 3 | 205 | Long par 3 to raised green; bailout left. |
| 5 | 4 | 455 | Demanding tee shot through pines; sloped fairway. |
| 6 | 3 | 180 | Elevated tee; wind-exposed green. |
| 7 | 4 | 440 | Narrow landing zone; deep rough both sides. |
| 8 | 5 | 545 | Risk/reward second over water; eagle chance. |
| 9 | 4 | 450 | Uphill approach to clubhouse turn. |
| 10 | 4 | 430 | Downhill tee shot; approach from sidehill lie. |
| 11 | 4 | 500 | Hardest hole; water near green, long approach. |
| 12 | 3 | 155 | Signature short iron over creek to shallow green. |
| 13 | 5 | 520 | Sweeping dogleg; bold second can reach green. |
| 14 | 4 | 440 | No bunkers; severe green contours create challenge. |
| 15 | 5 | 530 | Water short of green; classic go-for-it decision. |
| 16 | 3 | 170 | Pond left; Sunday pin near water. |
| 17 | 4 | 445 | Tree-lined par 4; accuracy test. |
| 18 | 4 | 505 | Uphill finishing hole; bunkers frame final approach. |

Total: Par 72, 7,275 yards.

---

## 9. World and place architecture

### 9.1 Roblox places

Recommended universe structure:

1. `GolfPro_Hub` - main menu, clubhouse, locker, leaderboards, practice range entry.
2. `GolfPro_Practice` - dedicated practice range, optional if not in hub.
3. `GolfPro_CourseTemplate` - place used for all course rounds, loading CourseSpec by ID.
4. Later: dedicated high-performance course places if needed for memory/performance.

MVP can implement hub and course in one place if simpler, but reserved match servers are strongly recommended for private rounds and 2v2 scramble.

### 9.2 Reserved servers

Each multiplayer round should run in a reserved/private server:

- Keeps parties together.
- Reduces interference.
- Makes score validation cleaner.
- Allows per-round CourseSpec and ruleset loading.
- Supports tournaments and private matches later.

### 9.3 Server capacity

MVP target:

- Solo: 1 player per reserved round server or shared solo server if optimized.
- Private stroke play: 2-4 players.
- 2v2 scramble: exactly 4 players.
- Spectators: off by default, later 2-10 depending on performance.

### 9.4 Streaming and terrain

Course worlds are large. Use:

- StreamingEnabled.
- Hole chunk folders.
- Low-poly distant props.
- One active ball per player/team.
- Server-only collision zones for hazards.
- Simplified collision for decorative objects.
- Client-side decorative foliage where possible.

---

## 10. User interface and HUD

### 10.1 Main menu

Main menu buttons:

- Play
- Practice
- Courses
- Friends / Party
- Leaderboards
- Locker
- Tournaments
- Settings
- Credits / Sources / Attributions

### 10.2 Play flow UI

Player selects:

1. Mode: Practice, Solo, Friends, 2v2 Scramble, Tournament.
2. Course.
3. Round length: 3, 9, 18. Ranked records only for official 18-hole rules unless configured otherwise.
4. Tee set.
5. Pin set.
6. Ranked or casual.

### 10.3 In-round HUD

Required HUD elements:

- Hole number.
- Par.
- Distance to pin.
- Player/team score.
- Score to par.
- Current stroke.
- Lie/surface.
- Wind speed and direction.
- Elevation difference to pin.
- Selected club.
- Club carry estimate.
- Shot type.
- Aim reticle / landing estimate.
- Swing power bar.
- Swing accuracy bar.
- Mini scorecard.
- Turn indicator.
- Team selection UI for scramble.
- Course record banner when relevant.

### 10.4 Hit bar UX

Power bar:

- Horizontal or semicircular meter.
- Shows safe zone and perfect zone.
- Club-specific speed; driver harder, wedge easier.
- Mobile: tap to start, tap to set power, tap to set accuracy.
- Controller: A / RT input support.

Accuracy bar:

- Center perfect impact zone.
- Miss left/right creates draw/fade/push/pull depending club and shot type.
- Rough/bunker narrows perfect zone.
- High-pressure tournament shots can visually intensify but must not secretly change ranked physics unless configured.

### 10.5 Scorecard UI

Scorecard rows:

- Hole numbers 1-18.
- Par.
- Yardage.
- Player/team strokes.
- To-par total.
- Front nine, back nine, total.

Use golf score visual conventions if desired:

- Birdie, eagle, bogey labels.
- Do not rely only on color; include text/icons for accessibility.

### 10.6 Results screen

Show:

- Final score and to-par.
- Rank on course leaderboard.
- Whether course record was set, tied, or missed.
- Best hole.
- Worst hole.
- Fairways hit.
- Greens in regulation.
- Putts.
- Longest drive.
- XP and cosmetics progress.
- Rematch / Return to clubhouse / Share result.

### 10.7 Locker UI

Categories:

- Ball skins.
- Ball trails.
- Bags.
- Club appearance sets.
- Titles.
- Emotes.
- Profile banners.

No real golf brand names in MVP.

---

## 11. Backend services

### 11.1 Service list

| Service | Server/Client | Purpose |
|---|---|---|
| `ProfileService` | Server | Load/save player profile and inventory. |
| `CourseService` | Shared + Server | Load, validate, and expose CourseSpecs. |
| `ClubService` | Shared + Server | Load, validate, and expose ClubSpecs. |
| `PartyService` | Server | Friend parties and invites. |
| `MatchmakingService` | Server | Queues, private matches, 2v2 scramble matching. |
| `RoundService` | Server | Round lifecycle and state machine. |
| `ShotService` | Server | Shot validation and simulation. |
| `ScoreService` | Server | Stroke, penalty, scorecard, team scoring. |
| `LeaderboardService` | Server | Ordered leaderboard writes and reads. |
| `RecordService` | Server | Course record compare-and-set logic. |
| `TournamentService` | Server | Scheduled event configs and tournament leaderboards. |
| `EconomyService` | Server | Cosmetic unlocks and purchases. |
| `LockerService` | Server + Client | Equipment display and selection. |
| `AnalyticsService` | Server + Client | Gameplay funnel and tuning events. |
| `ModerationService` | Server | Names, party safety, user reports hooks. |
| `NetworkService` | Shared | Remote definitions and payload validation. |

### 11.2 State machine

Round states:

```lua
RoundState = "Initializing"
    -> "WaitingForPlayers"
    -> "CourseLoading"
    -> "PreRound"
    -> "HoleIntro"
    -> "AwaitingShot"
    -> "ShotInProgress"
    -> "BallAtRest"
    -> "HoleComplete"
    -> "RoundComplete"
    -> "PersistingResults"
    -> "ResultsShown"
    -> "Closed"
```

Invalid state transitions should be rejected and logged.

### 11.3 Networking principle

Client may send:

- UI selections.
- Party actions.
- Matchmaking requests.
- Shot intents.
- Scramble ball selection votes.
- Cosmetic selections.

Client may not send:

- Final score.
- Final ball position.
- Course record claims.
- Currency grants.
- Inventory grants.
- Round completion status.

---

## 12. Data model and persistence

### 12.1 ProfileData

```lua
ProfileData = {
    schemaVersion = 1,
    userId = 0,
    createdAt = 0,
    lastLoginAt = 0,
    xp = 0,
    level = 1,
    stats = {
        roundsStarted = 0,
        roundsCompleted = 0,
        rankedRoundsCompleted = 0,
        bestScoreToPar = nil,
        holesInOne = 0,
        eagles = 0,
        birdies = 0,
        pars = 0,
        bogeysOrWorse = 0,
        longestDriveYards = 0,
        fairwaysHit = 0,
        greensInRegulation = 0,
        putts = 0
    },
    inventory = {
        ballSkins = {"default_ball"},
        ballTrails = {},
        bags = {"default_bag"},
        clubSkins = {"default_clubs"},
        titles = {},
        banners = {}
    },
    equipped = {
        ballSkin = "default_ball",
        ballTrail = nil,
        bag = "default_bag",
        clubSkin = "default_clubs",
        title = nil,
        banner = nil
    },
    courseBest = {
        -- [courseRulesKey] = { grossScore = 72, toPar = 0, completedAt = 0, roundId = "" }
    }
}
```

### 12.2 RoundData

```lua
RoundData = {
    roundId = "uuid",
    courseId = "course_pinebrook_v1",
    courseVersion = "1.0.0",
    physicsVersion = "golf_physics_v1",
    mode = "solo_stroke_18",
    ranked = true,
    rulesetId = "ranked_v1",
    teeSet = "championship",
    pinSet = "sunday",
    windProfile = "ranked_daily_v1",
    startedAt = 0,
    completedAt = 0,
    players = {0},
    teams = nil,
    scorecards = {},
    shotCount = 0,
    validationFlags = {},
    auditKey = "round_audit_uuid"
}
```

### 12.3 ShotRecord

Every ranked shot must be auditable.

```lua
ShotRecord = {
    shotIndex = 1,
    holeIndex = 1,
    playerUserId = 0,
    teamId = nil,
    from = { x = 0, y = 0, z = 0, lie = "fairway" },
    intent = {},
    serverComputed = {
        carryYards = 0,
        totalYards = 0,
        lateralOffsetYards = 0,
        finalPosition = { x = 0, y = 0, z = 0 },
        finalLie = "fairway",
        penaltyStrokes = 0,
        holed = false
    },
    serverTimestamp = 0,
    validation = {
        accepted = true,
        flags = {}
    }
}
```

### 12.4 Course record data

```lua
CourseRecord = {
    key = "course_pinebrook_v1:solo_stroke_18:championship:sunday:golf_physics_v1",
    courseId = "course_pinebrook_v1",
    mode = "solo_stroke_18",
    teeSet = "championship",
    pinSet = "sunday",
    physicsVersion = "golf_physics_v1",
    grossScore = 68,
    toPar = -4,
    holderUserId = 0,
    holderDisplayNameSnapshot = "Player",
    roundId = "uuid",
    setAtUnix = 0,
    verified = true
}
```

Display rule:

- If `CourseRecord` does not exist: show `Course Record: 0 / Unclaimed`.
- If exists: show `Course Record: 68 (-4), held by Player`.

### 12.5 Data stores

Recommended logical stores:

| Store | Type | Purpose |
|---|---|---|
| `GP_Profile_v1` | DataStore | Player profile. |
| `GP_RoundAudit_v1` | DataStore | Ranked round shot logs. |
| `GP_CourseRecord_v1` | DataStore | Canonical course record details. |
| `GP_PlayerBestByCourse_v1` | DataStore | Player best scores by course/ruleset. |
| `GP_TournamentConfig_v1` | DataStore | Tournament definitions if not static config. |
| `GP_TournamentEntry_v1` | DataStore | Tournament attempt records. |
| `GP_LB_CourseBestScore_v1` | OrderedDataStore | Global best score leaderboard. |
| `GP_LB_Tournament_v1` | OrderedDataStore | Tournament leaderboard. |

### 12.6 Leaderboard score packing

Golf scores are lower-is-better. Ordered leaderboards should store a sortable integer.

```lua
packedScore = grossScore * 1000000 + math.min(roundSeconds, 999999)
```

Lower packed score wins. If two players shoot the same gross score, faster completion ranks higher in leaderboard display, but course-record tie rule remains earliest verified record unless changed later.

### 12.7 Record update algorithm

Use atomic update logic.

```lua
function TryUpdateCourseRecord(newRecord)
    -- Pseudocode only
    DataStore:UpdateAsync(newRecord.key, function(current)
        if current == nil then
            return newRecord
        end
        if newRecord.grossScore < current.grossScore then
            return newRecord
        end
        if newRecord.grossScore == current.grossScore then
            -- MVP: tie does not replace existing holder
            return current
        end
        return current
    end)
end
```

After record update, write leaderboard entry and audit entry. If leaderboard write fails after record update, enqueue retry. Never trust client for record claims.

---

## 13. Matchmaking and parties

### 13.1 Party requirements

Party features:

- Invite friend by Roblox user/friend list where available.
- Invite by party code.
- Party leader selects mode/course.
- Party members ready up.
- Party leader can start if requirements met.

### 13.2 2v2 scramble setup

Options:

- Party of 4 splits into teams manually.
- Party of 2 queues against another party of 2.
- Solo queue fills teams later, not MVP priority.

### 13.3 Matchmaking data

Use an in-memory queue for live matching and persistent data only for completed results. Queue entry:

```lua
QueueEntry = {
    partyId = "uuid",
    leaderUserId = 0,
    playerUserIds = {0, 0},
    desiredMode = "scramble_2v2",
    courseId = "course_pinebrook_v1",
    skillBucket = 0,
    enqueuedAtUnix = 0
}
```

### 13.4 Reconnects

MVP reconnect policy:

- If player disconnects in casual mode, allow reconnect if round server still exists.
- If player disconnects in ranked solo, mark round as abandoned unless reconnect is implemented robustly.
- If player disconnects in 2v2 scramble, team can continue after timeout in casual; ranked team match becomes invalid unless reconnect returns within configured time.

---

## 14. Scoring rules

### 14.1 Stroke play scoring

Each player has strokes per hole. Penalties add strokes. Total score is gross strokes. To-par is gross score minus course par for completed holes.

Terms:

- Ace: hole in one.
- Albatross: -3.
- Eagle: -2.
- Birdie: -1.
- Par: 0.
- Bogey: +1.
- Double: +2.

### 14.2 Scramble scoring

Team score increments once per selected team shot cycle.

Example:

1. Player A and B tee off. Team stroke count = 1.
2. Team selects Player A ball.
3. Player A and B hit second shots from selected ball. Team stroke count = 2.
4. Continue.

### 14.3 Ranked validity

A completed round is ranked-valid only if:

- CourseSpec says `rankedEligible = true`.
- Course version, physics version, tee set, pin set, and wind profile match ranked config.
- Server validation flags do not include severe exploit/error flags.
- Round was completed without admin/dev interventions.
- All shot records exist and pass validation.
- Player did not forfeit, abandon, or disconnect beyond policy.

---

## 15. Anti-cheat and competitive integrity

### 15.1 Server authority

Server owns:

- Round state.
- Turn state.
- Ball position.
- Ball lie.
- Stroke count.
- Penalties.
- Shot result.
- Record updates.
- Inventory and rewards.

### 15.2 Client prediction

Client can show predicted aim/carry, but predicted visuals are advisory. The UI should label uncertain elements subtly through design, not text clutter. For example, aim marker can widen with rough/wind to communicate dispersion.

### 15.3 Exploit detection

Flag cases:

- Shot intent sent out of turn.
- Impossible club from lie.
- Power/accuracy outside allowed bar output.
- Remote spam.
- Ball final position mismatch.
- Sudden profile stat changes not caused by server.
- Score lower than theoretical minimum without matching shot logs.
- Round completed too fast for mode.

### 15.4 Leaderboard quarantine

If a round has suspicious flags but not enough evidence to discard, store it as `pendingReview` and do not update course records until verified.

```lua
validationFlags = {
    severity = "none", -- none, warning, suspicious, invalid
    codes = {}
}
```

---

## 16. Monetization and economy

### 16.1 Monetization principle

Golf Pro should not become pay-to-win. Ranked gameplay should be based on skill, not purchased club stats.

Allowed MVP monetization:

- Cosmetic ball skins.
- Ball trails.
- Club visual skins.
- Bags.
- Profile titles.
- Profile banners.
- Private match convenience features if compliant.
- Course access monetization only if it does not fragment the core player base too early.

Avoid in MVP:

- Paid extra distance.
- Paid accuracy boosts in ranked.
- Paid wind reduction in ranked.
- Random paid loot boxes.
- Gambling-style packs.

### 16.2 Cosmetic rarity

Rarity can exist for presentation:

- Common
- Rare
- Epic
- Legendary
- Record Holder
- Tournament Champion

Do not tie rarity to ranked performance advantages.

### 16.3 Progression

Players earn XP from:

- Completing holes.
- Completing rounds.
- First ranked completion on a course.
- Beating personal best.
- Achievements like first birdie, first eagle, first ace.

XP should not alter ranked club stats.

---

## 17. Live events and tournaments

### 17.1 MVP events

- Weekend Open: best 18-hole ranked score during event window.
- Daily Pin Challenge: 9-hole unranked challenge.
- First Record Race: when a new course launches, first valid completion receives Founding Record Holder title.

### 17.2 Event UI

Tournament screen shows:

- Event name.
- Course.
- Rules.
- Start and end time.
- Attempts used / max attempts.
- Leaderboard.
- Cosmetic rewards.
- Eligibility notes.

### 17.3 Future prize system

Future cash/Robux prize support must be behind `FeatureFlags.PrizeTournamentsEnabled = false` by default. Do not expose or market this until platform and legal signoff.

---

## 18. Asset and art direction

### 18.1 Visual style

Premium but Roblox-readable:

- Lush grass, clear fairway/rough distinction.
- Clean water shaders.
- Bright bunkers.
- Readable green contours.
- Professional clubhouse aesthetic.
- Low-noise UI, polished sports broadcast feel.

### 18.2 Course props

Allowed fictional assets:

- Generic clubhouse.
- Generic scoreboards.
- Generic tee markers.
- Generic flags.
- Generic sponsor-free banners.
- Pine trees, flowers, bridges, paths, water, rocks.

Avoid:

- Real course logos.
- Real tournament colors/logos if distinctive.
- Real brand billboards.
- Exact recognizable holes unless licensed.

### 18.3 Audio

Required audio:

- Club strike sounds by club category.
- Ball landing on fairway/rough/green/bunker/water.
- Crowd/reactive ambience for tournament events.
- UI selection sounds.
- Record-set fanfare.

No copyrighted broadcast music or real tournament audio.

---

## 19. Technical project structure

Assuming Rojo project structure, use this logical layout.

```text
src/
  ReplicatedStorage/
    GolfPro/
      Shared/
        Constants.lua
        Types.lua
        Signal.lua
        Maid.lua
        Result.lua
      Network/
        Remotes.lua
        PayloadValidators.lua
      Config/
        FeatureFlags.lua
        RankedRules.lua
        EconomyConfig.lua
      Courses/
        CourseRegistry.lua
        course_pinebrook_v1.lua
      Clubs/
        ClubRegistry.lua
        default_club_set_v1.lua
      Simulation/
        ShotMath.lua
        WindModel.lua
        LieModel.lua
        GreenModel.lua
        SurfaceResolver.lua
      UI/
        ViewModels/
        Formatters.lua
  ServerScriptService/
    GolfProServer/
      Bootstrap.server.lua
      Services/
        ProfileService.lua
        CourseService.lua
        ClubService.lua
        PartyService.lua
        MatchmakingService.lua
        RoundService.lua
        ShotService.lua
        ScoreService.lua
        LeaderboardService.lua
        RecordService.lua
        TournamentService.lua
        EconomyService.lua
        AnalyticsService.lua
        ModerationService.lua
      Data/
        DataStoreKeys.lua
        ProfileSchema.lua
        RoundAuditSchema.lua
      Admin/
        ExistingCommandBridge.lua
  StarterPlayer/
    StarterPlayerScripts/
      GolfProClient/
        Bootstrap.client.lua
        Controllers/
          MenuController.lua
          HUDController.lua
          SwingController.lua
          CameraController.lua
          CourseRenderController.lua
          BallRenderController.lua
          PartyController.lua
          LockerController.lua
          LeaderboardController.lua
        Input/
          InputMapper.lua
          MobileInput.lua
          ControllerInput.lua
  StarterGui/
    GolfProGui/
      MainMenu/
      HUD/
      Scorecard/
      Locker/
      Leaderboards/
      Tournament/
  Workspace/
    GolfProRuntime/
      CourseRoot/
      Balls/
      ActivePlayers/
```

### 19.1 Coding standards

- Use typed Luau where possible.
- Keep CourseSpec/ClubSpec as pure data modules.
- Keep shot math deterministic and unit tested.
- Never write DataStore code directly inside UI/controllers.
- Keep remotes centralized in `Network/Remotes.lua`.
- Every remote handler validates payload and player state.
- Feature flags wrap incomplete or risky systems.

---

## 20. Remote API source of truth

### 20.1 Client to server remotes

| Remote | Payload | Notes |
|---|---|---|
| `RequestCreateParty` | `{}` | Creates party with caller as leader. |
| `RequestInviteToParty` | `{ targetUserId }` | Server validates friend/privacy constraints. |
| `RequestJoinPartyCode` | `{ code }` | Join by code. |
| `RequestLeaveParty` | `{}` | Leave party. |
| `RequestQueue` | `{ mode, courseId, teeSet, pinSet, ranked }` | Queue or start private match. |
| `RequestStartPrivateRound` | `{ mode, courseId, teeSet, pinSet, ranked }` | Party leader only. |
| `SubmitShotIntent` | `ShotIntent` | Server validates and simulates. |
| `RequestScrambleBallVote` | `{ roundId, holeIndex, shotCycle, selectedBallId }` | Team members only. |
| `RequestForfeitRound` | `{ roundId }` | Ends or flags round. |
| `RequestEquipCosmetic` | `{ slot, itemId }` | Server validates ownership. |
| `RequestLeaderboardPage` | `{ leaderboardKey, cursor }` | Rate-limited. |

### 20.2 Server to client remotes

| Remote | Payload | Notes |
|---|---|---|
| `PartyUpdated` | `PartyState` | Party UI update. |
| `MatchFound` | `MatchInfo` | Teleport/reserved server info. |
| `RoundStateUpdated` | `RoundStateSnapshot` | Current state. |
| `HoleStarted` | `HoleSnapshot` | Hole intro. |
| `ShotAccepted` | `{ shotId }` | Client can lock input. |
| `ShotRejected` | `{ reasonCode }` | Show friendly error. |
| `BallPath` | `BallPathPayload` | Visual ball flight. |
| `BallAtRest` | `BallState` | Official next lie. |
| `ScorecardUpdated` | `ScorecardState` | UI refresh. |
| `CourseRecordUpdated` | `CourseRecord` | Fanfare/banner. |
| `RoundCompleted` | `RoundResults` | Results screen. |
| `InventoryUpdated` | `InventoryState` | Locker refresh. |

---

## 21. Course building pipeline

### 21.1 High-level pipeline

1. **Course concept approval.** Decide fictional or licensed real.
2. **Source audit.** Document allowed sources in CourseSpec legal block.
3. **Routing plan.** Define hole order, par, yardage, tee, fairway, green, hazards.
4. **2D layout.** Author fairway/rough/green/hazard polygons in local yard coordinates.
5. **Elevation plan.** Add terrain height map or simplified elevation splines.
6. **Surface zones.** Assign surface types and priority.
7. **Gameplay validation.** Simulate expected club choices and scoring difficulty.
8. **World art pass.** Terrain, trees, water, bunkers, bridges, clubhouse.
9. **Collision pass.** Simplify collision and test ball landing.
10. **Optimization pass.** Streaming, LOD, memory, mobile performance.
11. **Ranked certification.** Lock CourseSpec version, physics version, pin/tee sets.
12. **Release.** Course record starts unclaimed.

### 21.2 CourseSpec versioning

Any gameplay-affecting change requires a new version:

- Green contour changed.
- Yardage changed.
- Hazard changed.
- Surface polygon changed.
- Wind/ranked condition changed.
- Physics version changed.

Cosmetic-only changes do not require leaderboard reset unless they affect gameplay readability.

### 21.3 Course record versioning

Course records are keyed by:

```text
courseId + courseVersion + mode + teeSet + pinSet + rulesetId + physicsVersion
```

If a course is modified materially, old records remain archived and new records start unclaimed.

---

## 22. Analytics

Track events:

- `menu_opened`
- `tutorial_started`
- `tutorial_completed`
- `practice_shot_hit`
- `round_started`
- `hole_started`
- `shot_hit`
- `hole_completed`
- `round_abandoned`
- `round_completed`
- `ranked_round_completed`
- `course_record_set`
- `course_record_beaten`
- `party_created`
- `scramble_match_started`
- `cosmetic_equipped`
- `purchase_started`
- `purchase_completed`

Important tuning metrics:

- Average score by hole.
- Abandon rate by hole.
- Putts per green.
- Fairway hit percentage.
- Greens in regulation.
- Average round duration.
- Shot dispersion by club.
- Mobile vs desktop performance.

---

## 23. QA and testing

### 23.1 Unit tests

Test:

- ClubSpec validation.
- CourseSpec validation.
- SurfaceResolver priority.
- ShotMath carry and dispersion bounds.
- WindModel deterministic output.
- ScoreService stroke and penalty calculations.
- RecordService compare-and-set logic.
- Leaderboard packing.
- Remote payload validators.

### 23.2 Integration tests

Test:

- Start solo round.
- Complete hole.
- Complete 18-hole round.
- Update player profile.
- Set first course record.
- Beat course record.
- Tie course record.
- Reject invalid client score claim.
- Reject out-of-turn shot.
- Complete 2v2 scramble hole.
- Scramble ball vote timeout.
- Matchmaking reserved server handoff.

### 23.3 Manual acceptance tests

Before MVP release:

- New player can learn swing in under 3 minutes.
- Player can complete 3 holes without help.
- 18-hole round completes without server errors.
- Course record starts as `0 / Unclaimed` and updates after first valid ranked round.
- A lower later score replaces the record.
- A tie does not replace the record.
- Scramble team score increments correctly.
- Mobile controls are playable.
- Controller controls are playable.
- No real protected names/logos appear in UI, art, assets, metadata, or marketing text.
- No unlicensed map imagery is included in assets.

---

## 24. Performance targets

MVP targets:

- 60 FPS on desktop where possible.
- 30 FPS minimum on target mobile devices.
- Server round state stable for 4-player scramble.
- Ball shot calculation under 50 ms server-side.
- UI input latency feels immediate through client prediction.
- Course memory within Roblox limits with StreamingEnabled.

Optimization rules:

- Only active ball needs high-frequency updates.
- Use simple collision for foliage and decorations.
- Use terrain/material zones rather than thousands of tiny parts where possible.
- Merge decorative meshes by hole chunk.
- Avoid excessive RemoteEvent spam during ball flight; send path points instead of every physics frame.

---

## 25. Accessibility and platform support

Required:

- Keyboard/mouse.
- Touch controls.
- Controller controls.
- Adjustable UI scale.
- Color-independent score labels.
- Camera sensitivity settings.
- Sound volume categories.
- Reduced motion setting for ball trail/camera shake.
- Clear text for wind, distance, and lie.

---

## 26. Implementation phases

### Phase 0 - Project integration

Deliverables:

- Confirm Rojo tree.
- Add GolfPro folders/modules.
- Add FeatureFlags.
- Add remotes registry.
- Add basic test runner hooks.

### Phase 1 - Core data and simulation

Deliverables:

- ClubSpec registry.
- CourseSpec registry.
- Pinebrook National stub CourseSpec.
- ShotMath module.
- SurfaceResolver module.
- LieModel, WindModel, GreenModel.
- Unit tests.

### Phase 2 - Playable practice range

Deliverables:

- Practice range map.
- SwingController.
- HUDController basics.
- Server ShotService.
- Visual ball path.
- Club selector.
- Shot stats panel.

### Phase 3 - Round system

Deliverables:

- RoundService state machine.
- ScoreService.
- 3-hole debug route.
- Hole intro and scorecard.
- Hole completion.

### Phase 4 - Full 18-hole first course

Deliverables:

- Pinebrook National CourseSpec complete.
- Terrain and surface zones.
- Basic art pass for all 18 holes.
- Course flyover/cameras.
- Optimization pass.

### Phase 4.5 - Ball and club presentation

Deliverables:

- Visible golf ball model driven by authoritative `BallPath` and `BallAtRest` remotes.
- Shot tracer, landing marker, and optional shot-follow camera.
- Visible generic club model attached to the player's hand.
- Club visual swaps when the selected ClubSpec changes.
- Procedural swing/strike presentation synced to 3-click swing timing.
- No branded club designs, paid stat changes, or client-owned official shot results.

### Phase 5 - Multiplayer and scramble

Deliverables:

- PartyService.
- Reserved server match start.
- Friend private rounds.
- 2v2 scramble team logic.
- Scramble ball selection UI.

### Phase 6 - Persistence, leaderboards, records

Deliverables:

- Profile persistence.
- Round audit logs.
- Course record service.
- Ordered leaderboards.
- Results screen.
- Record-set celebration.

### Phase 7 - Locker and monetization

Deliverables:

- Cosmetic inventory.
- Equip cosmetics.
- Cosmetic-only shop hooks.
- No pay-to-win stat changes.

### Phase 8 - Tournaments and LiveOps MVP

Deliverables:

- Tournament config data.
- Weekend Open leaderboard window.
- Cosmetic rewards.
- Event UI.
- Prize system remains cosmetic-only.

### Phase 9 - Polish and launch QA

Deliverables:

- Mobile/controller polish.
- Audio pass.
- UI polish.
- Analytics dashboard events.
- Exploit testing.
- IP/content audit.
- Launch checklist complete.

---

## 27. Codex ticket backlog

### GP-001: Shared types and constants

Create `Types.lua`, `Constants.lua`, and core enum definitions for surfaces, modes, shot types, states, clubs, and leaderboard keys.

Acceptance:

- All core systems import types/constants from shared modules.
- No duplicated string enums across services.

### GP-002: Club registry

Create `default_club_set_v1.lua` and `ClubRegistry.lua`.

Acceptance:

- 14 clubs load successfully.
- Validation catches missing fields.
- Server can query club by ID.

### GP-003: Course registry and CourseSpec validator

Create `CourseRegistry.lua`, Pinebrook stub, and validation utilities.

Acceptance:

- CourseSpec loads by ID.
- Legal block required.
- Holes, par, yardage, tees, pins, and zones validate.

### GP-004: ShotMath deterministic solver

Build deterministic solver for carry, dispersion, wind, lie, roll, final position.

Acceptance:

- Same inputs produce same output.
- Output is bounded by club and lie specs.
- Unit tests pass for every club.

### GP-005: SurfaceResolver

Given final position and HoleSpec zones, return lie/surface.

Acceptance:

- Priority order works.
- Hazards override fairway/rough.
- Default rough fallback works.

### GP-006: SwingController and HUD hit bar

Build 3-click swing UI.

Acceptance:

- Works with mouse, touch, and controller.
- Produces power01 and accuracy01.
- Does not submit shot if UI canceled.

### GP-007: ShotService remote validation

Implement `SubmitShotIntent` server handler.

Acceptance:

- Rejects invalid turn.
- Rejects invalid club.
- Rejects remote spam.
- Calls ShotMath and replicates BallPath.

### GP-008: RoundService state machine

Build round lifecycle.

Acceptance:

- Solo round can start, play holes, complete.
- Invalid transitions rejected.
- Round snapshots replicate to client.

### GP-009: ScoreService

Implement strokes, penalties, hole completion, scorecard.

Acceptance:

- Stroke play scores correctly.
- Water and OOB penalties work.
- Scorecard updates after holes.

### GP-010: Pinebrook 3-hole vertical slice

Build holes 1-3 with surfaces and basic art.

Acceptance:

- Playable start to finish.
- Server resolves fairway/rough/green/bunker/water.
- UI distances and lies update.

### GP-011: Pinebrook full 18

Complete all 18 holes.

Acceptance:

- Full round playable.
- Par and yardage match CourseSpec.
- No protected real-world IP appears.

### GP-011A: Ball and club presentation

Implement the visual golf layer that sits on top of the existing server-owned shot system.

Acceptance:

- Player sees an actual ball before and after each shot.
- `BallPath` renders visible ball flight, tracer, landing marker, and shot camera feedback.
- Selected club appears in the player's hand and swaps when the selected ClubSpec changes.
- Swing/strike presentation is synced to the 3-click swing flow without changing ranked shot math.
- Visuals remain cosmetic/client-side; server remains authoritative for final ball position and scoring.

### GP-012: PartyService

Implement party create/invite/join/leave/ready.

Acceptance:

- Party state replicates.
- Leader can configure private round.
- Non-leader cannot start without permission.

### GP-013: 2v2 Scramble

Implement teams, team strokes, ball selection, vote/timeout.

Acceptance:

- Both players hit from selected ball.
- Team score increments by shot cycle.
- Auto-selection works on timeout.

### GP-014: Persistence

Implement profile load/save and basic stats.

Acceptance:

- Data survives session.
- Profile schema migrations supported.
- Failures handled safely.

### GP-015: Course records

Implement RecordService.

Acceptance:

- Course displays `0 / Unclaimed` when no record.
- First valid ranked completion sets record.
- Lower score beats record.
- Tie does not replace.
- Record update is server-only.

### GP-016: Leaderboards

Implement leaderboard pages.

Acceptance:

- Best scores show by course/mode/ruleset.
- Lower score ranks higher.
- Player's own rank can be displayed.

### GP-017: Results screen

Implement round completion UI.

Acceptance:

- Shows final score, stats, leaderboard result, and record outcome.

### GP-018: Locker and cosmetics

Implement inventory/equipped cosmetics.

Acceptance:

- Player can equip owned cosmetics.
- Cosmetic changes replicate.
- No ranked stat changes from cosmetics.

### GP-019: Tournament MVP

Implement scheduled leaderboard event with cosmetic rewards.

Acceptance:

- Event leaderboard works.
- Attempts are tracked.
- Prize policy is cosmetic-only.

### GP-020: Launch audit

Build script/manual checklist to scan course names, assets, UI strings, and metadata for disallowed protected references.

Acceptance:

- No disallowed real-world brands/tournament/course names in published build.
- CourseSpec legal blocks are complete.

---

## 28. Definition of done for MVP

Golf Pro MVP is done when:

1. A new player can join, practice, and play at least one complete 18-hole round.
2. Pinebrook National is fully playable from tee to green on all 18 holes.
3. Solo stroke play and private friend stroke play work.
4. 2v2 scramble works.
5. Full 14-club set works.
6. HUD, swing bar, scorecard, and results screen are polished enough for public testing.
7. Server owns shot results, scoring, records, and persistence.
8. Course record starts unclaimed and updates correctly.
9. Leaderboards show valid ranked scores.
10. Player profiles persist stats and cosmetics.
11. Monetization is cosmetic-only and non-pay-to-win.
12. No unlicensed real-world course names, protected marks, logos, or copied imagery are present.
13. The game passes exploit tests for common remote tampering.
14. The game runs acceptably on target desktop and mobile devices.
15. Analytics events are implemented for core funnels and tuning.

---

## 29. Future expansion roadmap

After MVP:

1. More fictional championship courses.
2. Licensed real-world courses if rights are acquired.
3. Ranked seasons.
4. Clubhouses / player social spaces.
5. Spectator mode.
6. Creator-hosted events.
7. Broadcast overlays.
8. Skill rating / handicap system.
9. Cross-server tournament finals.
10. Course creator tools for internal designers.
11. Weather presets.
12. Caddies / AI shot advice for unranked play.
13. Licensed brand partnerships if desired.

---

## 30. Source references used for this spec

These references inform the compliance and technical guardrails. Review them again before launch because platform terms can change.

- Roblox Terms of Use, effective May 19, 2026: https://en.help.roblox.com/hc/en-us/articles/115004647846-Roblox-Terms-of-Use
- Roblox Community Standards: https://about.roblox.com/community-standards
- Roblox Advertising Standards, updated June 5, 2026: https://en.help.roblox.com/hc/en-us/articles/13722260778260-Advertising-Standards
- Roblox Data Stores documentation: https://create.roblox.com/docs/cloud-services/data-stores
- Roblox Memory Stores documentation: https://create.roblox.com/docs/cloud-services/memory-stores
- Roblox Teleport documentation: https://create.roblox.com/docs/projects/teleport
- Google Earth Additional Terms, last modified June 4, 2025: https://www.google.com/help/terms_maps-earth/
- Google Geo Guidelines for Maps, Earth, and Street View: https://about.google/brand-resource-center/products-and-services/geo-guidelines/
- OpenStreetMap Foundation License FAQ: https://osmfoundation.org/wiki/Licence/Licence_and_Legal_FAQ
- USGS The National Map / data download resources: https://www.usgs.gov/tools/download-data-maps-national-map

---

## 31. Final build instruction

Codex should begin with Phase 0 through Phase 3 immediately: create the shared data/types, ClubSpec registry, CourseSpec registry, deterministic shot math, SurfaceResolver, SwingController, ShotService, RoundService, ScoreService, and a 3-hole Pinebrook National vertical slice. Do not wait for exact real-world course data. The system must be ready to accept licensed real CourseSpecs later, but the MVP should ship with original fictional premium courses.
