# The Unbroken Sky implementation plan

Version 1.1 • Prepared 27 October 2026 • First session 28 October 2026

## Outcome and constraints

Build an original, offline, single player 2D fantasy adventure for Android, developed by Cacious with assistance and as little cash expenditure as practical. Prove the opening before committing to full production. This document plans actual development; it does not claim implementation, installation, testing or publication has already happened.

The complete prose story is narrative/FULL_STORY.md. The game adaptation is narrative/FINAL_SCRIPT.md. The prose follows the shared-containment ending. The game also includes an alternate central-seat ending. No additional plot, online system or commercial service is required to complete the first game.

Five compact map spaces, three player forms, one reusable husk family, one anchor-based final confrontation, a small portrait cast, four reconverging choice points and two endings define the planned full scope. It remains substantial for a beginner working alone. There is no credible full release date until a playable slice establishes the owner's available time and production speed.

## Tomorrow and the following four sessions

Dates below are intended working sessions, not automatic appointments or guaranteed completion dates. If setup takes longer, move the remaining sessions rather than skipping their acceptance criteria.

| Intended date | Work | Finish line |
| --- | --- | --- |
| Wednesday 28 October | Setup, input, first well room | Walk to basket, collect pin, repair pump, see black-water reveal; or record the exact setup blocker if the computer cannot yet run the project |
| Thursday 29 October | Dialogue and local save | Read SC02 without timed text; close and reopen safely; no duplicate pin or broken pump state |
| Friday 30 October | One enemy and readable danger | Dodge and interrupt one husk in a test room; defeat reloads without a payment or story penalty |
| Saturday 31 October | Eagle greybox | Transform and traverse three forgiving perch links; reliably return to human on landing |
| Sunday 1 November | Assemble and observe | Connect the well, short road and flight tests; watch one player attempt them without coaching; note revisions |

This first week is an ambitious prototype target, contingent on experience, working hours and hardware. If any date slips, keep the scope fixed and revise dates. The first coherent slice need not contain all of Act One.

## First session sequence

Start by checking development computer OS, memory and graphics support; installed tools; programming experience; a target Android phone; and time available per session. Ask only what cannot be inspected or inferred. Confirm these before choosing version-specific instructions.

Use the current stable Godot 4 version that runs comfortably on the development machine, GDScript, and the Compatibility renderer. The official sources in research/R14 cover licensing and requirements; verify the version installed. If hardware proves unsuitable, revisit this choice before committing to implementation. Keep the narrative documents intact.

1. Install or open the engine, create an engine folder, and run an empty scene.
2. Create a flat well yard with collision walls and labelled placeholders. Use a 960 by 540 baseline design canvas with scalable UI; validate on real screen ratios later.
3. Add the human player and desktop movement, then one interact action. Do not begin with final artwork.
4. Add the tool basket, a collectable lever pin, the pump and Sena's dialogue trigger.
5. Implement the well sequence: collect pin, repair pump, clear first water, dark second water, whisper caption, Mera's intervention, exit enabled.
6. Run from a clean start twice. Check the player cannot collect the pin twice, leave before the reveal, or become trapped in dialogue.
7. Save the project and write a short progress note with the next concrete task. If time remains, begin large text support; eagle flight is a stretch goal only after the room works.

Definition of done for Day One: an executable desktop scene with the complete SC02 interaction, or an explicitly documented environment blocker. A folder, installed editor, static mockup or story file alone is not the playable milestone.

## Full project milestones

Milestones are dependencies, not promised dates. Each has a review gate. Fix the failed gate or deliberately change scope before moving on.

### M0 Development environment

Inputs: computer, current project documents, official engine and export tools as needed. Tasks: create the engine folder, version control or equivalent reliable local history, and backups. Record exact engine and export versions. Keep secrets and signing credentials outside distributed archives.

Acceptance: blank project runs; project can be restored from backup; engine version recorded. Android export is attempted early when the phone and SDK are available, not deferred until final production.

### M1 Well scene

Scenes: SC02 with the short SC01 prologue optional until the interaction works. Systems: human movement, collision, interact prompts, dialogue, one local objective. Use placeholder shapes and text.

Acceptance: a new player identifies what to do; pump sequence completes in order; dialogue exits cleanly; restart resets correctly. See the Day One criteria above.

### M2 Core controls and accessibility

Tasks: touchscreen movement and large action buttons; desktop equivalents; adjustable text speed and instant text; speaker labels; pause; sound captions; reduced flashing. Touch movement must not obstruct the dialogue advance area. Decide fixed versus floating stick from an observed trial, not a preference assumed for everyone.

Acceptance: perform essential actions on the selected phone without accidental dialogue clicks; essential threats remain understandable muted; large text is readable without clipping. Save/checkpoint work begins here.

### M3 Combat and eagle prototype

Tasks: one husk with clear windup, strike and recovery; one player attack and dodge; simple health and a checkpoint reset; one reusable hazard area. No equipment economy. Eagle uses explicit takeoff and landing areas, not unrestricted open-world flight.

Acceptance: a player can read and avoid the husk's strike; repeated defeat does not block progress; eagle cannot land out of bounds or remain airborne in a dialogue state. An assist option widens landing areas. Flight feels worthwhile before more animals are added.

### M4 Opening slice

Scenes: SC01 through SC10, using abbreviated travel where needed. Spaces: Red Hollow, a short Ash Road, Reed Gate. Tasks: integrate first water choice, uncanny crossing, keeper discovery, eagle reveal, bypass repair and news of Mera's detention. Companions appear at conversation points; they do not need combat pathfinding.

Acceptance: the opening has a clear objective, playable tension and a resolution to the water errand. Testers can explain who Tavo is, what he wanted and why he continues. Measure frame timing and memory on the actual target phone. Record reading and play duration rather than advertising an unmeasured length.

Decision gate: continue, revise controls/story delivery, or reduce scope. Do not fund a long campaign merely because friends praise the premise.

### M5 Narrative engine and saves

Tasks: make a small data-driven conversation format, central state store, objective tracker and local versioned save. Support conditionals and explicit side effects. Do not create a general-purpose visual scripting editor.

Recommended dialogue record fields: stable line_id, scene_id, speaker, text, next_id, conditions, effects, optional choice records. Each choice has visible text, consequence preview where needed, effects and next_id. Stable identifiers survive wording edits. Use a plain JSON source first, generated or typed from the signed-off script. Syntax and missing targets must fail validation before runtime.

Acceptance: choice can be saved/reloaded, all destinations exist, repeated interaction does not duplicate effects, old/missing/corrupt save recovers safely. Store original choices separately from later repairs so epilogue consequences survive.

### M6 Archive and relationships

Scenes: SC11 through SC19. Spaces: reuse Ash Road at night; archive courtyard and a small archive interior treated as parts of one map space. Tasks: protected hearing, records puzzle, memory viewpoint reveal, mother conversation, letter, Orun's offer, Daru's bargain. Introduce consented hyena form for one low passage and physical scent trail.

Acceptance: players distinguish memory impressions from corroborated facts; survivors' names are not required to unlock cooperation; Sena has decisions of her own; no scene requires an unbuilt cinematic. Check every major reveal against its earlier clue.

### M7 Preparation and final chamber

Scenes: SC20 through SC24. Tasks: visible prerequisite board, repairs for each incomplete policy, three separate relay interactions, constrained final confrontation, final choice and second confirmation. Use the state specification as the rule source.

Acceptance: the exclusive deal invalidates joint control until repaired; public exposure requires survivor protection; private evidence has a protected publication route; repeated relay use cannot increase the count. Every path can return from the final threshold until confirmation. No time pressure on the reading-heavy final choice.

### M8 Endings and epilogues

Scenes: SC25A, SC25B and SC26. Tasks: author both endings exactly enough that each feels complete; conditional relationship and policy lines; native eagle retained and borrowed hyena removed on shared release. Use the same maps with changed props and portraits.

Acceptance: all final states load a valid ending; the original choices remain acknowledged; refusing immediate forgiveness does not secretly disqualify the shared ending. Credits do not claim unperformed consultation or licensing.

### M9 Coherent presentation

Tasks: replace the placeholders only after core play and story work. Choose one small coherent style. Prioritise player silhouette, interactables, readable hazards, map navigation and portraits. Keep source, licence, credit and modification notes for every outside asset.

Acceptance: no essential element relies on colour alone; text does not overlap controls; portraits and speech labels remain readable on varied ratios; camera effects can be reduced. No real sacred designs are assigned to the invented husks.

### M10 Complete-device testing

Tasks: clean install, offline full run, suspend/resume, save/reload, storage shortage handling, touch testing, performance and thermal observations on the selected phones. Use a range of ordinary available phones when possible; no purchasing a device fleet is assumed.

Acceptance: full story completable offline without account creation; no progression blockers; final choice reversible until confirmed; main content readable at large text. Stable 30 fps is an initial target to test, not a claim already achieved. Record download/install sizes and test duration.

### M11 Release decision

Tasks: local story/cultural review where possible; comprehension and play tests beyond close friends; pricing experiments only after the complete opening works; platform-specific release requirements checked at that time. Keep the first store launch private/test-only until publication is separately authorised.

Acceptance: feedback supports a concrete release scope; asset notices and rating answers are accurate; real distribution costs are known; no unsupported claims of authenticity or guaranteed revenue. A complete story unlock after a free opening remains a hypothesis, not a mandatory business model.

## Proposed engineering structure

Inside engine/, use scenes/ for reusable components and maps, scripts/ for systems, data/dialogue/ for text, assets/ for art and sound, and tests/ for meaningful state validation. Avoid creating all this before M0; it is a guide for implementation.

Core components: PlayerController, InteractionTarget, DialogueRunner, NarrativeState, SaveManager, ObjectiveTracker, HuskEnemy, FlightLink and FormController. Keep the narrative state independent of the engine scene tree where practical so it can be exercised without loading maps. Form transitions must restore collision, input and camera state on landing, scene change and reload.

One persistent state owner handles flags. Dialogue reads and writes through named operations. Maps do not keep private copies of ending conditions. Automatic checkpoints occur after scenes and before major choices. Do not add cloud saves, user accounts or a backend.

## Minimum asset budget by production milestone

| Asset group | Opening slice | Full planned game |
| --- | --- | --- |
| Player forms | Human and eagle | Human, eagle, borrowed hyena |
| World spaces | Three small spaces | Five, with archive interiors and courtyard sharing a set |
| Enemy systems | One husk; one water hazard | Same husk family, water hazard and anchor confrontation |
| Dialogue portraits | Text-only initially | Eight central recurring roles, small roles optional |
| Cinematic method | In-engine staging or still image | Same method, no bespoke video requirement |
| Sound | Original or licensed placeholders; captions | A restrained licensed/original set; no full voice cast assumed |

No fixed cash total is reliable until existing equipment and distribution choices are known. Tomorrow's software and placeholder-art spend should be zero if the available hardware works. Data, electricity, time and backups still have costs. Purchases, commissions and external publication remain separate concrete decisions.

## Testing that matters

During prototypes: verify movement/collision, pump ordering, dialogue exit, checkpoint recovery and form transitions. Once branching exists: validate every narrative identifier and prerequisite, then exercise the cases in CHOICES_AND_STATE.md. Before release: complete both endings on actual devices and test every repair path at least once.

Use short observed sessions. Ask what the player thought happened, what they wanted to do next and whom they trusted. Do not explain the intended meaning before they answer. Plot complexity should be adjusted from comprehension rather than defended as sophistication. No research can guarantee a mind-blowing effect or a profitable game.

## Scope control

When work expands, reduce decorative content before core clarity. Cut extra enemy variants before the first readable enemy; optional lore before the main letter scene; map size before reliable flight; voiced dialogue before large text and captions. Preserve both endings only if their state logic can be tested. If a release becomes just an opening chapter, state that explicitly and revise its promise before charging for it.

Do not add multiplayer, an open world, console support, crafting trees, seasons or paid randomness until the small game's quality and audience response justify separate projects.

## Daily closing note

End each session by recording: the build that runs, the device tested, what changed, a screenshot or short clip if useful, the main failure, and the next task. Keep a restorable backup. The next session should begin by running the last working build before editing.

No reminder, calendar event or future autonomous work has been scheduled. The first session begins when the owner returns to work on 28 October 2026.
