# Narrative state and branch specification

This is an implementation specification, not executable code. Script source is narrative/FINAL_SCRIPT.md. All state is local; no server, account or monetisation service is required.

## State

| Field | Initial | Legal values or range |
| --- | --- | --- |
| scene_id | SC01 | SC01 through SC26, with SC25A or SC25B |
| water_policy | unset | reserve, share, joint |
| testimony | unset | private, protected, exposed |
| gate_policy | unset | exclusive, seized, shared |
| mother_relation | unset | accountability, distance, uncertain |
| water_compact | false | Boolean |
| public_record | false | Boolean |
| survivor_safety | false | Boolean |
| relay_count | 0 | Integer 0 through 3, derived from three distinct relay flags |
| eagle_unlocked | false | Boolean |
| hyena_unlocked | false | Boolean |
| binding_released | false | Boolean |
| ending | unset | central, shared |

Use separate relay_a, relay_b, relay_c Booleans to prevent incrementing the same relay repeatedly. Save the chosen policies and any later repairs separately so the epilogue remembers the original action. In particular, original_testimony=exposed remains even after survivor_safety is repaired. Keep relationship choices separate from practical preparation. No hidden empathy score.

## Transitions

SC03 joint sets water_compact once the joint maintenance demonstration finishes. Other policies leave it false. SC15 protected sets public_record and survivor_safety. Exposed sets public_record, leaves survivor_safety false, and records exposed_survivors. Private leaves both false until the protected hearing in SC20. SC18 shared sets water_compact true. Exclusive or seized invalidates current joint control even if SC03 was joint: set water_compact=false, because a later exclusive diversion supersedes the earlier agreement. SC20 can repair all practical prerequisites on every path.

SC09 unlocks native eagle. SC16 unlocks borrowed hyena only after consent. SC25B sets binding_released=true and hyena_unlocked=false, leaving eagle_unlocked=true. SC25A removes both animal controls because the playable epilogue no longer uses Tavo, not because he gains another form.

Shared ending availability:

`public_record AND survivor_safety AND water_compact AND relay_a AND relay_b AND relay_c`

Display the unmet requirements and their scene locations. At SC24, the player may inspect previews or return. Persist the final ending only after a second explicit confirmation. No ending is selected by combat failure or impatience.

## Branch economy

Four choices have three initial responses each. They reconverge in the same scene and alter specified lines, props or preparation tasks. There are two complete end sequences and three mother relationship variants. The project does not contain 81 separately authored campaigns.

All practical mistakes have repair paths. Repair carries acknowledgement, work and sometimes continuing resentment. It does not erase the original record. Every player can reach either ending; players who pursue the shared ending must do its observable work.

## Game theory design notes

This is qualitative design informed by collective action research, not a mathematical proof of optimal behaviour and not a player psychology guarantee.

- SC03: uncertain future supply and unequal immediate need. One-off generosity helps now but does not automatically establish governance.
- SC18: an exclusive bargain is attractive to Red Hollow and damaging downstream. Seizing a control creates a maintenance dependency. Shared custody reduces the risk of unilateral defection.
- SC20: credible commitments require assets and actions, not just stated trust. Opening the reserve precedes reassignment of control. Parties can observe compliance.
- SC21: distributed relays create redundancy but require continuing monitoring, labour and limits. Cooperation is neither free nor culturally uniform.
- SC24: concentration reduces coordination burden now but concentrates future coercion. Distribution sacrifices high consumption to reduce dependence on one body and one authority.

The intended emotional lesson emerges from outcomes and characters. Do not display a lesson score, label a population as irrational, or reward coercive speech choices with uniquely superior loot.

## Review cases before implementation signoff

1. Validate water_policy against reserve, share and joint. Malformed saved values must reset safely or produce a recoverable validation message.
2. Reserve → private → exclusive → no repairs: central available, shared unavailable, return available.
3. Joint → protected → shared → all relays: shared available.
4. Joint → protected → exclusive: shared unavailable until control repaired, despite initial joint agreement.
5. Exposed → shared → relays: shared unavailable until survivor protection completed.
6. Any original choice → all SC20 repairs → relays: shared available, original epilogue consequences retained.
7. Any mother relationship: no change to ending prerequisites.
8. Repeating a relay: relay_count never exceeds three.
9. Shared release: no hyena afterwards; eagle remains.
10. Final cancellation: no ending persisted until confirmed. Reload before choice preserves agency.
11. Large text and mute mode: threat locations and timing remain intelligible through visual and caption cues.
12. Combat defeat: no permanent narrative consequence or resource payment to retry.

These are planned acceptance cases. They have not been run in a game because the engine project has not yet been built.
