# Play first: mobile direction

27 October 2026. This gameplay adaptation supersedes the original scene delivery, while keeping the characters, water crisis, choices, revelations and Act One destination. The prose story remains the narrative baseline. Earlier opening and dialogue drafts are preserved in design-history/2026-10-27.

## What the player should feel

Act, notice a response, try something else. A repair should physically change the machine; danger should move and make a sound before anyone explains it. Conversations should come from what people want right now. Sena is trying to hold a failing pump together, Mera is frightened of recognition, Daru is counting dwindling supplies, and Nali needs water for actual patients. Give them short, incomplete, situation-specific speech. Save speeches for moments where somebody has earned the room.

The opening promise is practical action interrupted by something uncanny. The action-first lesson taken from the user's Call of Duty reference is immediate involvement, audible activity, readable stakes and a quick escalation. The game keeps its own setting and repair, combat and shapeshifting mechanics.

## Implemented in this pass

- New games begin in SC02 with movement available, a spraying pump and Sena working beside it. SC01 is retained for old saves and future memory staging, rather than blocking the new-game path.
- The basket and pump have visible cues. Two timed taps fit the pin. Misses cost no health or progress and widen the window. Closing a touch gesture returns controls only after release. Walking speed rises from 150 to 190 units/second.
- Clear water becomes black on the second pull. The whisper leads to short shots of Tavo's cuts and Mera's burn, instead of paragraphs describing them. Focused scenes hide objectives and interaction prompts, allow pause and offer a skip button.
- Ambient lines run during movement, combat and interactions. A new interaction can interrupt a bark. Combat starts before its short spoken cue; the three instruction paragraphs are removed. Choices wait for the player; spoken responses after selection advance automatically.
- SC02?SC10 have a shorter dialogue pass. Posted orders and optional inspections remain manual reading. Plot-critical information formerly buried in narration is spoken by characters. This is an adaptation, not a wholesale deletion of narration without replacement.
- The cistern shows the actual jar count and the carried/installed pipe. The spring fills after repair. The gate brace visibly changes position.
- The flight scene uses an animated human figure instead of a billboard. A brief scale transition replaces the text-only transformation; the wind voice plays during flight. Nali and Kesi are visible on landing.
- The existing character rig gains face forms, corrected hair placement, stronger clothing coverage and bone-attached wrist clues. Head detail is merged into one mesh to limit added draw calls. These are improved prototype characters, not finished closeup character art.
- Character clips can be dropped into engine/assets/voices as LINE_ID.ogg or .wav. Playback ends advance ambient/cinematic lines; missing clips use short subtitle timings. No recorded performances are included yet. Voice acting, lip sync and final pronunciation remain production work.

## Delivery contract

| Delivery | Player controls | Reading and pacing |
| --- | --- | --- |
| Ambient bark | Movement, combat and object interactions remain available | One short subtitle; no tap needed; can be interrupted |
| Focused scene | Movement and gameplay taps are blocked | Auto-paced clips/subtitles, authored shots, pause and skip |
| Choice | Movement blocked; buttons own the decision | Never times out or selects automatically; concise consequences |
| Readable object | Movement blocked until dismissed | Deliberate player request: orders, letters, optional inspections |

Silent stage entries describe a real camera/animation/sound beat; their stage labels never appear as player text. Voice duration owns spoken timing when an asset exists. Without a recording, durations are an approximation for testing and must be tuned on a phone.

## Chapter pacing review

| Section | Playable activity now | Next production improvement |
| --- | --- | --- |
| Well yard | Move, collect, time the repair, pump; uncover the threat | Better hand contact and final character assets |
| Cistern | Inspect supply, make a consequential allocation, carry/fit the pipe | Animate actual handoffs and both repair partners |
| Home | Collect useful equipment between short exchanges | Proper prop handoff and bag animation |
| Ash Road | Dodge, interrupt, strike; a harmless practice lunge, flanking approaches, a second husk from behind with a ring cue | Phone check of the ring cue size and practice-lunge timing with an uncoached player |
| Culvert | Inspect the false reflection, challenge it, evade/attack water | Animated reflection mismatch and collapse of the mimic |
| Reed Gate | Drain, brace, unlock | Visible reservoir motion, valve and lock animation |
| Keeper room | Focused revelation, then a moving flood escape | Better keeper staging and child-height memory cuts |
| First flight | Transform, steer, use lift, land | Authored feather/body transformation rather than scale transition |
| Wheel platform | Fit the wheel and learn the immediate personal stakes | Animate the wheel, water route and messenger arrival |

Do not call the whole game redesigned or polished on the strength of this pass. Several chapter encounters still use prototype staging. The table is the production queue, and each missing action should be implemented before removing the last cue that makes it understandable.

## Mobile playtest gates (targets, not measured results)

Control available within two seconds of starting a new game. First useful action within ten seconds, first repair within roughly 30?45 seconds, first uncanny event within a minute for an uncoached player. Individual detail shots around one second. Routine speech should not interrupt play. Only consequential choices and requested documents should require reading. Essential dialogue should remain understandable muted.

Test on the actual target phone: thumb reach, UI at the largest font size, readable silhouettes, camera return after skip, touch release ownership, app suspend/resume, and sustained frame time. Aim for 60 fps where supported and a stable 30 fps floor on the agreed minimum device; neither is established by desktop tests. Keep a close camera far enough away that prototype geometry does not undermine the scene. Shorten or replace the shot if it does.

For engagement, build mastery, readable feedback, surprising discoveries and consequences that change the visible world. Avoid repetitive chores, arbitrary countdowns, punishment for experimentation or retention tricks. A short repair challenge is only one ingredient; phone playtests decide whether it is fun.

## Validation of this pass

The headless chapter suite passes with zero failures, including native dialogue touches, the final repair gesture, forgiving misses, ambient interaction, cinematic pause/skip, missing voice fallback and choices that wait indefinitely. Desktop renders were inspected for the opening, repair, wrist and burn shots, face framing, transformation and landing. The Android debug APK was exported, signed and verified at engine/build/android/unbroken_sky_debug.apk. Use New game to see the revised opening; an existing save continues from its saved scene. No phone frame-rate or uncoached-player pacing result is claimed.

## Visual pass: stairs, fall and eagle

The later visual pass replaces the keeper room's flat stair markers with ten-tread flights, raised landings, handrails, retaining walls, a broken exit and additional lighting. Character height and tap projection use the same elevations, including the narrow paths around collision barriers. Flood height increases with the escape route.

The collapse drops Tavo and masonry; the next scene continues an accelerating full-size fall of roughly eight metres, then switches form in a feather burst. The mobile renderer uses explicit visibility at the switch rather than unsupported per-instance fading. This replaces the earlier shrinking-body transition. The fall can still be skipped safely.

The eagle has sculpted wing surfaces, individual flight feathers, articulated wrists, fan tail, hooked bill, eyes and talons; feet tuck and wings fold on perches. Flight scenery adds stone textures, arcades, battlements, water ripples, lighter goal rings and wind particles without floating location labels. The tool basket, satchel, doorway and copper bird receive recognisable geometry. Short input-safe room fades cover scene replacement.

The geometry remains stylised procedural prototype art. The form switch is staged rather than a continuous anatomical morph. Desktop screenshots and functional checks cover these changes; frame rate and small-screen readability still require testing on the target phone.

The debug title screen includes Test: stair escape (starts after the keeper conversation) and Test: eagle flight (includes the fall). Both use the separate test-room save so the visual changes can be reviewed quickly without advancing the story save.

## Responsive world and flight course, 28 October 2026

The village now has a terrain backdrop, worn paths, wind-driven shade cloth and plants, and sand footsteps with small dust puffs. The player uses a jogging animation at full travel speed. Chickens flee nearby movement, steer clear of the existing solid footprints and return to pecking. The copper bird spins when used, and the pump handle visibly strokes or jams. These reactions do not open dialogue or add compulsory chores.

Flight has two optional cyan wind gates per leg. A forward crossing restores wing strength and gives a brief speed boost, chime and wind trail. A central pass gives a stronger reward. Swept gate checks work across long frames; reverse passes and repeated collection in one attempt do not score. A retry rearms only the current leg and removes its temporary boost. The counter is per leg, so loading a later checkpoint does not leave an impossible six-gate goal. Main-story progress still depends only on reaching the perches.

Ruins now block flight. Swept collision checks use oriented wall and arch blocks so an open arch remains open; the source perch gives enough clearance to take off. A collision returns to the last perch. Random scenery stays clear of the main route and the authored arcades. This creates optional steering practice while preserving the safe first glide and flight-assist settings.

Validation includes the original chapter suite, reactive chickens and toy interaction, upward-facing terrain, one-time gate rewards, reverse rejection, boost/retry state, solid ruin collision and clear arch openings. Desktop renders cover the village, gate approach, reward and largest text setting. These changes need uncoached playtesting to establish whether they are enjoyable; no phone frame-rate result is claimed.
