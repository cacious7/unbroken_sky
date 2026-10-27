# First build plan

First development session: 28 October 2026. This is a task plan, not a scheduled reminder or a promise of an automatic future session.

## What exists today

A complete prose story, a complete game script, narrative canon, research register, choices specification and this development handoff. The full milestone plan is IMPLEMENTATION_PLAN.md. There is no playable game, installed engine, generated artwork, registered company, published store listing or paid service in this package. Those are not prerequisites for starting the first scene.

## Tool choice

Recommended starting tool: the current stable Godot 4 release supported by the development computer, using GDScript and the Compatibility renderer. Verify the installed version before writing version-specific code. Godot's official licence and requirements are in research/R14. No paid assets or subscriptions are required for the prototype. Paid distribution and assets may introduce later costs; no exact fee is assumed here.

We have not established the owner's computer specifications, coding experience or test phone model. Obtain these at the start of development, then adjust installation and export instructions. Do not delay a desktop blockout for a perfect hardware survey. If the computer cannot run the proposed editor comfortably, revisit the tool choice before investing in it.

## Tomorrow's finish line

A single room containing Tavo, Sena, a pump, a tool basket and an exit. The player can move, interact, pick up a pin, fix the pump and trigger the black-water reveal from SC02. The dialogue can be read without internet access. Restarting returns to a usable state. This is the first proof of the project, not an attempt to build the full script in a day.

Stretch goal only if the room works: one test eagle transformation between two perches on a separate greybox. Do not add the complete fortress, NPC schedules or a crafting economy.

## Ordered work

1. Confirm hardware and experience. Download/install the engine through its official source if needed; create the engine project under this project root. Keep the narrative folder intact.
2. Set a landscape baseline viewport, initially 960 by 540 as a design canvas, with scalable UI. It is a starting layout, not a device compatibility guarantee.
3. Build a flat coloured room with collision boundaries. Use geometric placeholder art and labelled interaction points.
4. Add walking and interaction. Desktop keys first for quick iteration, then one touch control layout. Avoid multiple gesture systems.
5. Add a small dialogue box with speaker name, continue button, adjustable text speed and instant-text option. No autoplay timer.
6. Implement the SC02 state sequence: pin absent → pin collected → pump repaired → water first clear → water dark → Mera arrives → exit enabled.
7. Save after the scene completes. Use a local versioned save format. A bad or missing save must start safely rather than crash.
8. Run through the scene without explaining it to one other person. Ask what they are trying to do and what changed. Record confusion before revising prose.
9. If a test phone and export environment are ready, install an offline Android build and test readability, touch reach and heat. Otherwise record Android export as unfinished, without claiming a mobile-ready result.
10. Back up the working project and note the next concrete task.

## Scope after the first room

Milestone A: scene readability, movement and interaction. Milestone B: the short Ash Road encounter with one husk. Milestone C: a greybox fortress with constrained eagle flight. These combine into a short opening slice. Only after this works should the full script's archive, branching choices, hyena form and endings enter production.

Five map spaces and around a dozen speaking roles are an upper bound for this first game, not a minimal weekend build. Narrative ambition still costs time in UI, animation, testing and iteration. If the slice is too expensive, preserve the script and reduce release scope explicitly rather than quietly labelling an unfinished ending complete.

## Art and sound approach

Use a restrained top-down 2D view. Flat shapes or a coherent low-resolution style are both acceptable; select one after the greybox. Human Tavo and eagle are the only player sprites needed for the first slice. Use still character portraits or text-only dialogue. No lip sync, full voice acting, procedural cities, open-world flight or cinematics requiring custom video.

For the whole small game, plan reusable walk cycles for three player forms, one husk enemy family, an anchor-based final encounter, five map spaces and a small portrait cast. A reused map can change with props and lighting. Do not solve atmosphere with enormous texture downloads. Maintain a third-party asset register with source, licence, credit and modification notes before importing an asset.

Sound should support, not carry alone, essential information. Caption whispers and directional threats. No real ceremonial recording or modern song is assumed free to use. Placeholder silence is preferable to unlicensed music.

## Performance and access targets to test

Offline core play, no required account, resumable scenes and short playable segments. Aim for a stable 30 frames per second on a selected modest test phone, then adjust scope based on measurement. Treat small download size as a constraint to measure, not a figure already achieved. Support large text, speaker labels, reduced flashes, readable contrast, captions and pausing in narrative scenes. Constrained flight should have generous landing zones and an assist setting.

## Commercial hypothesis

Prototype and initial audience tests are free. Later test a free opening with a clearly priced complete story unlock. This remains a hypothesis, not a validated revenue model. Avoid energy timers, paid retries, streak penalties and random paid rewards. Evaluate chapter completion, voluntary return, referrals, comprehension and actual purchase interest, with consent and minimal data collection. No analytics service needs to be integrated tomorrow.

## Excluded until evidence warrants them

Online multiplayer, battle royale, console release, cloud saves, account systems, open-world simulation, real-money economies, loot boxes, several playable heroes, full voice casting and several dozen animal forms. The script supplies a world that can grow without requiring these for its first complete story.
