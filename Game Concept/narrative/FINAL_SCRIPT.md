# The Unbroken Sky
## Complete first game script

Version 1.1 • 27 October 2026 • Original Zambia inspired fantasy

Prepared for Cacious Siamunyanga. This is the complete narrative baseline for a small single player game, including playable objectives, dialogue, discoveries, consequential choices and all endings. It is not a claim that a game exists or that production is complete. Scene timing will depend on playtesting. All personal names are provisional invented names, with no asserted translation or ethnic attribution.

Audience direction: 17 and above; supernatural horror, threatened children, bereavement, exploitation and violence without sexual content or graphic depictions of child suffering. No romance subplot. Actual platform age ratings remain to be assessed.

## Relationship to the prose story

FULL_STORY.md is the complete prose telling of the main story. Its canonical choice path is joint emergency repair, protected testimony, shared gate control, accountability with Mera, and the shared-containment ending. This game script preserves player alternatives; the central-seat ending is a complete alternate outcome. Scenes SC02–SC10 form the opening production slice, not an automatic first release commitment. The implementation plan starts on 28 October 2026.

## How to read the script

SC marks a scene. ACTION is visible staging. PLAY is an interactive sequence. SAY lines are essential dialogue. Optional inspection lines are complete text, not instructions to improvise later. Choices reconverge after their stated consequences. Failed combat reloads the encounter and does not create an alternative story branch. No real ceremony, sacred mask or historical religious figure appears as an enemy.

The complete game uses five compact spaces: Red Hollow settlement, the Ash Road and its refugee camp, Reed Gate fortress, the ruined capital's archive courtyard, and the covenant chamber beneath it. Locations change through lighting, props and access rather than requiring a large world. Long journeys occur between scenes through still illustrations and brief captions.

## Cast in the script

TAVO, 24: courier and well repair assistant from Red Hollow. Resourceful, funny under pressure, quick to protect his own and slow to admit uncertainty. Player character. Can become an eagle; later borrows a hyena form through a living magical connection.

MERA, 49: his adoptive mother, a former covenant record keeper. Skilled, loving, implicated. Neither her profession nor her crime represents a real cultural office.

SENA, 19: his adoptive sister, a capable apprentice metalworker. Another rescued survivor of the vessel programme. Wants a life she chooses rather than protection that confines her.

DARU, 25: Tavo's oldest friend, now a militia captain. Loyal, practically minded, responsible for hungry people rather than an abstract nation.

NALI, 28: river city healer and refugee organiser. Lost her father in the catastrophe. Will not let her community's suffering excuse what its rulers did.

ORUN, 57: senior minister of the fictional House of Continuance. Organises relief and seeks to restore the covenant. His faith is sincere; his political solution is dangerous.

VEYA, 30: former royal hydraulic engineer and surviving dynastic claimant. Knows how infrastructure works and assumes this entitles her to command it.

KESI, 27: shapeshifter and former vessel. Conducted the prison rescue that triggered the catastrophe. Lives with responsibility she cannot undo. Her hyena form is not a moral classification.

LIO, 24: Orun's son and a relief attendant. A small role, never a compulsory sacrifice.

THE CLAIMANT: a supernatural accumulation of identities and unpaid obligations in the damaged covenant. It repeats human language but is not an ethnic god, an ancestor of a real community, or a secret human mastermind.

## Prologue

### SC01 The child behind the wall

ACTION: Darkness. Scraping metal. A small hand touches a copper channel in stone. Another hand touches its opposite side. We see no face. A single line of daylight moves across a wall.

CHILD ONE: Is there sky where you are?
CHILD TWO: I don't know.
CHILD ONE: There must be. Birds don't carry it with them.

ACTION: A woman's sleeve covers the first hand. A door opens. Hard cut before we see who leaves.

PLAY: None. Under forty seconds. Caption: SEVENTEEN YEARS LATER. RED HOLLOW.

## Act One What we owe our own

### SC02 A good morning to argue

ACTION: Morning heat. Shade cloth, repaired clay walls, a modest working settlement. Sena tests a little copper bird balanced over a brazier. Tavo pumps a well; the handle sticks.

SENA: Touch it again and I'll charge you.
TAVO: For the bird?
SENA: For breaking it while explaining how to improve it.
TAVO: The wings are too heavy.
SENA: Then make a lighter world.

PLAY: Walk to the tool basket. Take the lever pin. Fit it to the pump. Learn movement and interaction without a failure state. The first pump yields water. The second yields black silt. The third carries a whisper.

WHISPER: Present.

TAVO: Did you hear that?
SENA: I heard our breakfast becoming a long walk.

ACTION: Mera catches his wrist before he touches the silt. Beneath her sleeve is an old copper burn. On his own wrist, three fine cuts briefly darken. She hides the burn before he can ask.

MERA: Wash your hand. Not in this water.
TAVO: What is it?
MERA: Something from below.
SENA: Helpful. We were worried it came from the sky.

ACTION: Mera does not smile. A runner calls them to the cistern.

Optional inspect BIRD: "Sena keeps improving the same bird. She says making another would let the first one win."
Optional inspect WELL: "My mother taught me never to cover a bad repair with fresh plaster."

Exit objective: Meet Daru at the cistern.

### SC03 The last clean water

ACTION: Daru has stopped distribution from the well. Twelve covered jars remain. Refugees wait beyond the gate. A local elder has written household allocations on a slate.

DARU: Clean reserves. Enough until the next caravan if we keep the gate closed.
NALI, outside: Two of ours cannot swallow. I need water before I need permission.
DARU: And tomorrow?
NALI: Tomorrow I ask again.

ACTION: Tavo recognises Nali's river court accent. Daru gives him the slate.

DARU: You've carried messages to Reed Gate. You know which promises come back.

CHOICE C1, previewed in plain language:

A — KEEP THE RESERVES. "We keep the twelve jars. I will look for another source." Set water_policy=reserve. Refugees remain outside for now. No offscreen death is secretly assigned as a punishment.
B — SHARE NOW. "Six jars for them. Six for us. We both find water." Set water_policy=share. Local reserve falls; Nali gains access. The player is told six jars remain.
C — PROPOSE A JOINT REPAIR. "Two jars for treatment now. Your pump workers and ours open the old spring together." Nali agrees to workers; Daru agrees only if both sides count the water. Set water_policy=joint. Ten jars remain. Set water_compact=true after a short shared repair interaction.

For C, PLAY: Carry a pipe while a local and refugee hold its ends. Water appears in a marked settling bowl. Nali leaves an attendant to maintain it. Do not present labour as a condition for emergency treatment; the two treatment jars were given first.

NALI, A: I'll remember the answer. I still need that channel open.
NALI, B: Thank you. Who keeps the count tomorrow?
NALI, C: One keeper from each side. Neither touches the measuring stick alone.
DARU, all: The old line runs through Reed Gate. If its wheel still turns, we can refill here.

ACTION: Mera examines a seal brought by the refugees.

MERA: The fortress keeper is alive. Eren. He signed this.
TAVO: You know his hand?
MERA: I know his office.

Exit objective: Get the release wheel from Reed Gate and find its keeper. This remains the immediate goal through Act One.

### SC04 The promise at the door

ACTION: At home, Mera packs Tavo's bag with exact, practised movements. Sena is making a key from a charcoal rubbing of the fortress mechanism.

MERA: Do not answer a voice from water. Do not promise anything in a sealed room.
TAVO: Are these travel instructions or a confession?
MERA: They're instructions.
TAVO: What was the mark on that seal?
MERA: A department that should have died with the capital.

ACTION: Tavo notices a small copper register plate in her bag. Mera closes it.

MERA: Ask Eren where his duplicate records went. Bring back his answer. Don't trust only what he says.
SENA: And bring the wheel. Answers don't fit pumps.

ACTION: Sena gives Tavo the key and copper bird. Tavo protests.

SENA: It's not a gift. Test the balance somewhere with wind.

MERA: When you were seven, I brought you home sick. There are things about that sickness I haven't told you.
TAVO: Then tell me now.
MERA: I need to get something out of hiding first. When you return, you will have it. All of it.

ACTION: He leaves angry rather than soothed. Daru meets him at the gate.

DARU: If you're late, I'll come fetch you.
TAVO: With the army?
DARU: With a rope. The army complains too much.

### SC05 The Ash Road

PLAY: A short route under intense sun. Tavo recognises cooler stone, shade and usable wind. No claim of biological immunity: the route teaches local knowledge. Combat tutorial against two covenant husks near a broken way station. Husks are abandoned magical maintenance shells, not dead members of a real tradition. Strike, dodge, interrupt. Three moves only.

ACTION: A merchant hides behind his cart.

MERCHANT: I shouted that I owned the road. They stopped.
TAVO: For how long?
MERCHANT: Long enough to regret it.

Optional inspect WAY STATION: A carved hand on one side; a shallow bowl on the other. "The bowl is polished by use. The hand was gilded later."

ACTION: Nali is treating a traveller nearby. She has followed the same route to bring medicine to the fortress survivors.

NALI: You've got blood on your sleeve.
TAVO: Not mine.
NALI: Then someone else needs the cloth.

She gives him a clean strip and takes the stained one for washing. They continue together. She walks between checkpoints; she does not require companion combat AI.

### SC06 The woman at the crossing

ACTION: At a dry culvert, a woman calls to Tavo in Mera's voice. She wears Mera's scarf but her clothes are wet.

FIGURE: Come help your mother.

PLAY: The player may approach to inspect, without an instant death trap. The figure's reflection mouths different words. Sound captions display [voice from left], [reflection speaks out of time].

FIGURE: Say you know me. Just say it.
NALI: Ask her something she would refuse to give you.
TAVO: Tell me what happened when I was seven.

ACTION: The figure repeats the question with precisely his intonation. It cannot answer. Its outline collapses into a rope of water and silt.

PLAY: Dodge a clearly telegraphed strike, break the copper hook anchoring it. The threat retreats. No timed dialogue quiz.

TAVO: You knew.
NALI: I knew it was wrong. I didn't know what it would do.
TAVO: What was it?
NALI: Something asking you to let it be her.

Inspect HOOK: "An official mark. Someone built a place for this thing to attach."

### SC07 Reed Gate

ACTION: Fortress exterior. Empty carts are trapped against the gate. A royal order is still nailed above the entrance: ADMIT CERTIFIED HOUSEHOLDS ONLY. We do not show bodies for spectacle.

VEYA, on the wall: Move away from the spillway.
TAVO: We need the release wheel.
VEYA: So does everyone downstream. That's why it stays here.
NALI: Open the clinic door. I have medicine.

ACTION: Veya recognises Nali and lowers a ladder. She is repairing machinery, not sitting on a throne.

VEYA: The wheel holds a cracked gate shut. Take it now and the upper reservoir drains into the lower wards.
TAVO: My home is running dry.
VEYA: Then help me make it safe to remove.

PLAY: Fit Sena's key. Drain a small side channel. Shift a brace. Behind the sluice grille, a sleeping man whispers "Present" in Tavo's voice. Tavo freezes.

NALI: He's alive. Don't pull him out until I see the chain.

### SC08 A room remembered twice

ACTION: Eren is the fortress keeper. He lies behind a copper grille, attached by the wrist to a failing ritual circuit. A hyena watches from a broken stair. It withdraws when noticed.

EREN: Seven came back.
TAVO: My name is Tavo.
EREN: Of course it is. Of course she gave you one.

ACTION: A memory interrupts: child-height view of the grille from inside. A second image sees it from outside. Same crack, different angles. Mark memory framing with a distinct border, never present it as an objective cutscene.

EREN: Your mother took the registers. I kept the transfer slips. Archive courtyard. Under the blue drain tile.
TAVO: Why do you know my mother?
EREN: I want to say I only counted them.
NALI: Counted whom?
EREN: I put the numbers where their names had been.

ACTION: He tries to disconnect himself. A copper channel lights.

EREN: Don't let them make you the answer again.

PLAY: The room floods with dark water. The player climbs a marked stair. A section collapses. No choice can save Eren; show Nali attempting to release him before the collapse, and establish the current is too strong. Do not make the player responsible for a predetermined death.

### SC09 The first sky

ACTION: Tavo falls through a broken wall. Sena's bird tumbles beside him. His fingers close around it; feathers follow the arm. His body becomes an eagle.

PLAY: Three short perch-to-perch flight segments above the same fortress map. Movement is constrained to readable routes with broad landing zones. The first is safe. The second requires avoiding a gust. The third reaches the release wheel on the far platform. Fall failure restarts at the preceding perch.

VOICE, unfamiliar: Left. The air comes up there.
TAVO: Who said that?
VOICE: You asked me that before.

ACTION: He lands human. Nali has seen everything.

TAVO: Tell me that happens to couriers.
NALI: Not the ones I've paid.

ACTION: Kesi steps out of the stair shadow, now human.

KESI: You could have landed badly enough to keep the wings.
TAVO: Who are you?
KESI: Someone who learned badly.

### SC10 The wheel and the witness

ACTION: Veya arrives. She recognises Kesi and raises a weapon.

VEYA: The woman who broke the renewal chamber.
KESI: The woman who opened it.
VEYA: My city heard the difference for one breath. Then it drowned.

NALI: Lower it. I need the platform to stay standing.

ACTION: Orun and his son Lio arrive with relief workers. Lio goes straight to the injured rather than the argument. Orun helps lift a brace before speaking.

ORUN: We can hate each other when everyone is above the waterline.

PLAY: Tavo fits the wheel to the repaired bypass. Clean water begins flowing towards the uplands. The immediate mission succeeds. Veya retains enough control to protect the remaining reservoir. The wheel stays installed: no magical portable water cure.

ORUN, noticing Tavo's wrist: Mera has been hiding more than records.
TAVO: Everyone knows my mother except me.
ORUN: I knew the office she held. I am beginning to understand the person who left it.

ACTION: A messenger brings news. Mera has been detained at Red Hollow after admitting she helped the attackers. River troops are approaching under an order demanding her surrender. Sena is travelling under Daru's escort to the capital's relief court to challenge the order. The water repair buys several days; it does not end the danger.

KESI: If you want the part they won't put in the charge, come to the archive.
ORUN: Come with witnesses. Hers, mine and your own.

End Act One. Save checkpoint. Caption: THE WATER REACHED HOME BEFORE THE TRUTH DID.

## Act Two Those who remember

### SC11 A place at the fire

ACTION: At the Ash Road camp that night. Nali administers medicine. Lio makes a bad attempt to mend a shoe. Kesi watches Tavo eat twice, as if testing whether he still has ordinary appetites.

LIO: My father says I should learn a useful trade.
NALI: He has been saying it for ten years. At some point it's your fault.
TAVO: Give Sena that shoe. She'll return it as a kettle.

ACTION: They laugh. Kesi does not, until Lio spills the water he was saving from the leather.

TAVO, to Nali: Did your family live inside the capital?
NALI: My father maintained the public baths. He believed that a city which washed strangers couldn't be wholly cruel.
TAVO: Was he wrong?
NALI: About the baths? No.

ACTION: Kesi hears a child whisper "Present" from a dry bowl. She turns it over, gently.

KESI: Don't answer just because it sounds lonely.

Optional inspect RATIONS, C1 reserve: "The camp is thinner than Red Hollow. I knew that when I left. Knowing feels different here."
Optional inspect RATIONS, C1 share: "Nali has recorded where each jar went. Gratitude did not remove the need to count."
Optional inspect RATIONS, C1 joint: "Two signatures on the settling bowl. A local hand and a refugee hand. The marks are different sizes."

### SC12 The hearing beneath the awning

ACTION: At the archive courtyard outside the ruined capital. This courtyard doubles as clinic, relief court and assembly place. Sena embraces Tavo, then holds him back to inspect him. Mera is detained in a screened side room, with food and water. Daru has negotiated against removing her until evidence is heard.

SENA: You flew?
TAVO: I fell in an unusual direction.
SENA: Show me.
DARU: Perhaps after we stop the war.

ACTION: Mera sits before Orun, Veya and community witnesses. Nali represents refugees; Daru the uplanders. No single court is accepted by all parties, which is why everyone insists on witnesses.

MERA: I gave Kesi the chamber route. I knew children were being held there. I believed opening the peripheral channels would take them off the covenant safely.
VEYA: Thousands died.
MERA: Yes.
ORUN: Did you know the remaining gates had been sealed?
MERA: Not until after.
KESI: I knew before I opened the last one.

Silence.

KESI: The guards were returning. The children were still alive inside. I opened it.

DARU: So two people decided for every household along the river.
KESI: No. Others had been deciding for those children for years. That does not make what I did harmless.

ORUN: We will hear the rest. Until then the surrender order stays suspended here. I cannot promise every commander will obey me.

PLAY: Gain archive access. Objective: Find the transfer slips and compare them with Mera's register. The player can speak to Mera before leaving.

### SC13 Mother

TAVO: Did you steal me?
MERA: I took you out of a room no child should enter.
TAVO: That isn't the same answer.
MERA: No. Your mother was called Ilen. She petitioned for your return. Her petition was filed as proof your household existed. That made it easier to collect from them.
TAVO: Did you read it?
MERA: I registered it.

ACTION: Mera gives him a folded letter. It has been opened many times. It is not yet read aloud.

MERA: I should have given you this before you had to ask.
TAVO: Why me?
MERA: You were nearest the service door.

ACTION: He waits for a grander answer. None comes.

MERA: I returned three years later for Sena. I did not bring everyone. I kept thinking I could go back when I had a better plan.
TAVO: You taught me to leave no one in a broken well.
MERA: I know.

CHOICE C2:
A — KEEP THE RECORD PRIVATE FOR NOW. "Give me the whole record. I decide when I can bear to read it." Set testimony=private.
B — AUTHORISE A PROTECTED HEARING. "Tell them your part. Keep the survivors' locations out of it. Let Nali hold a copy." Set testimony=protected. Nali agrees to the role; set public_record=true after SC15 corroboration.
C — READ THE UNREDACTED REGISTER PUBLICLY. "No more hidden pages." Preview: names may identify surviving vessels and their households. Set testimony=exposed, public_record=true after SC15. No approval is implied by clarity of warning.

MERA, all: I will answer. You don't owe me forgiveness for that.

### SC14 Two sides of a door

PLAY: A small archive puzzle. Turn three drainage handles to expose the blue tile. Copper maintenance husks wake when the wrong channel is loaded; a mistake resets the local water level, not the story. Recover Eren's slips, the unaltered renewal diagram and a provincial petition.

ACTION: Touching the channel triggers the prologue again. This time the first hand is Tavo's. The second belongs to Kesi. She is ten; he is seven. Mera opens his service door. Kesi's door stays shut.

CHILD TAVO: I'll bring her back.
CHILD KESI: Keep the window open.

ACTION: Present-day Tavo withdraws his hand. Kesi stands at the real doorway.

TAVO: I left you.
KESI: You were seven.
TAVO: I said I'd come back.
KESI: You were seven.

ACTION: Let silence remain. No music sting declaring a twist.

KESI: Your escape proved the service door could be opened. I spent seventeen years finding someone who would open another.
TAVO: When I hear you—
KESI: Sometimes it is me. Sometimes it's an old trace. Don't trust a memory just because it hurts.

PLAY: Inspect the independent slips. They verify Tavo's age, Mera's office and exemptions in noble household accounts. Memories provide leads; records and witnesses establish claims.

### SC15 The city that healed

ACTION: Nali lays three items on a clinic table: a free treatment token, a death record from an outlying village, and an exemption bought by a merchant household. The same copper stamp appears on all three.

NALI: My father collected these tokens for patients who had none.
VEYA: The clinics saved lives.
NALI: Yes. Now tell me whose lives kept the lights burning.
VEYA: I didn't administer the levy.
NALI: You designed the channels.
VEYA: I was told they carried heat from the furnaces.

ACTION: Veya examines her own diagram. One channel continues below the marked boundary. She follows it with her finger.

VEYA: I approved an increase here. The winter before the renewal.
TAVO: What did you believe it would do?
VEYA: Keep the children's ward warm.

ACTION: She must confront a good intention used within a concealed system. She is responsible for how she responds now, not retroactively omniscient.

PLAY: Compare the three records. Required story discovery: central services were partly powered by coerced life contributions, concealed as provincial misfortune. Not every achievement depended on magic; agriculture, craft, medicine and ordinary labour were substantial and remain valuable.

For C2 protected: Nali reads evidence with names removed. "Here is what we can prove. Here is what remains uncertain." Mera testifies. Set public_record=true and survivor_safety=true.
For C2 exposed: the full names are read. A listener recognises Sena's childhood mark and backs away. Sena confronts Tavo: "You told them where to find me before you asked what I wanted." Set exposed_survivors=true.
For C2 private: evidence is kept among the main party. Rumours continue without a shared document. Nali: "I will protect the children. I won't call their absence proof this never happened."

### SC16 The voice that is hers

ACTION: Sena repairs the bird's bent wing in a quiet corner.

SENA: I remember being taller than I was. A woman's hands. Not Mother's.
TAVO: I thought it was dreams.
SENA: You thought yours were dreams. You never asked about mine.

ACTION: She places her wrist beside his. Same three cuts.

SENA: They connected us before we knew what agreeing was. It doesn't make every thought in my head yours.

Kesi explains, briefly:

KESI: Five were left in the chamber at the renewal. You two were already gone. I opened it for five. Two survived the return. I can still hear one of them far downriver. The others left traces when they died. Those traces aren't people we can bring back.

Canon: four living vessels exist now—Tavo, Sena, Kesi and one distant survivor outside this game's cast. Two escaped earlier; five remained during the catastrophe; Kesi and the distant survivor survived it. No future scene can revive the three dead children through convenient magic.

TAVO: If we cut the connection?
KESI: We keep our lives. We lose what only the connection carries. Borrowed senses. Borrowed forms. Some memories we never knew were borrowed.
SENA: Good. Then I can decide whether I miss them.

PLAY: Kesi offers a controlled sharing exercise. Consent dialogue appears before the power unlock.

KESI: You can borrow my shape until we separate. You cannot borrow my decisions.
TAVO: Yes.

Unlock hyena form: track physical scent and move through low passages. No ability to identify moral guilt or read private thoughts. A short tutorial returns to the same archive corridor to find a hidden service entrance.

### SC17 The man feeding his enemies

ACTION: Orun distributes grain to a group who have defaced his order's emblem. Lio asks him whether to remove them from the line.

ORUN: They came for food. Give them food.

Later, alone with Tavo:

ORUN: The covenant did hold something back before anyone turned it into a tax. The wound beneath the city is real. Your mother has the records. I have watched the lower channel grow each night.
TAVO: And you want to put us back in it.
ORUN: I want to close it. I believe you can hold its centre without the provincial levy.
TAVO: For how long?
ORUN: I don't know.
TAVO: You nearly said forever.

ACTION: Orun shows an old diagram. A keeper in its centre is gradually surrounded by overlapping script.

ORUN: The previous keepers stopped distinguishing their own wishes from the demands made through them. I will not hide that from you.
TAVO: Will you accept no?

Orun cannot answer immediately.

LIO: I will take a station beside him.
TAVO: Your willingness doesn't answer for mine.
ORUN: No. It doesn't.

ACTION: Orun calls off an immediate attempt to place Tavo under guard. He still orders preparations for restoration. He is neither absolved by kindness nor exposed as secretly insincere.

### SC18 The short way home

ACTION: In the relief courtyard, Daru has grain carts loaded. He has quietly offered Veya military protection in exchange for directing the next clean-water release exclusively to Red Hollow.

DARU: I counted the beds at home. I counted the bags here. People sleep better when someone does that instead of making speeches.
TAVO: There are other people on that channel.
DARU: There were other children in your mother's prison. She brought you home. You still call her Mother.

ACTION: This hurts because it is partly fair.

VEYA: I can route the release. I cannot make more water tonight.
NALI: You can give both sides control of the gate and open the public settling tanks.
VEYA: Those tanks are a royal reserve.
NALI: Not anymore, if you're asking us to rebuild them.

CHOICE C3, full consequences previewed:

A — ACCEPT THE EXCLUSIVE DEAL. Red Hollow receives secure priority. Set gate_policy=exclusive and water_compact=false. Daru agrees to escort the party but Nali cannot promise refugee labour at the final chamber.
B — SEIZE THE GATE FOR EVERYONE. Tavo takes the wheel key by force. Set gate_policy=seized and water_compact=false. Veya withdraws engineering support until a later repair conversation; the party now controls an asset it cannot safely maintain alone.
C — NEGOTIATE SHARED CONTROL. Veya supplies the mechanism and opens the royal settling reserve. Daru supplies guards from both groups. Nali chooses a refugee gate keeper. Each must demonstrate one step before the other hands over control. Set gate_policy=shared. Set water_compact=true. Everyone receives less than their ideal share; nobody can close the gate alone.

DARU, A: They will call you selfish. They won't be the ones burying ours.
VEYA, B: When the retaining pin wears through, find someone who knows which end of the gate to stand beside.
NALI, C: We write the release times where the queue can see them. Including when we're wrong.

End Act Two. The deeper chamber begins resonating. The final decision is now unavoidable, but preparation remains possible.

## Act Three The price of an answer

### SC19 The letter

ACTION: Tavo opens Ilen's petition under a shaded wall. No flashback depicts her death; her eventual fate is not known.

ILEN, letter text, read by Tavo or shown silently:
"You said he was learning a trade. Send his shoes. He grows faster than you think. He likes the bitter fruit if you cut it small. He says he does not. Please do not let him sleep alone when it rains. There is a sound in our roof he has always been afraid of. Tell him I fixed it."

ACTION: The reverse carries an office note in Mera's hand: HOUSEHOLD VERIFIED. COLLECTION CONTINUES.

TAVO: She was trying to get me home.
MERA: Yes.
TAVO: And you used her letter.
MERA: Yes.

CHOICE C4, affects relationship and epilogue, not engineering prerequisites:
A — "You are my mother. You will still answer for it." Set mother_relation=accountability.
B — "I cannot call you that now." Set mother_relation=distance.
C — "I don't know what I can call you. Stay and help." Set mother_relation=uncertain.

MERA, all: I'll stay. The record doesn't depend on what you call me.

ACTION: She volunteers to testify to a public inquiry after the emergency. No instant pardon or execution resolves the relationship.

### SC20 The preparation table

ACTION: The covenant chamber can be entered now. Restoration is available. A different solution requires a plan the player can inspect, challenge and complete here. No hidden ending score.

PLAY: The table displays three requirements, each with a visible status and repair action:

1. A VERIFIED PUBLIC ACCOUNT — corroborated records and protected survivor testimony.
2. RECIPROCAL CONTROL — a shared gate agreement with two independent operators.
3. THREE WORKING RELAYS — engineering and ordinary maintenance that spread containment across the existing channels.

If C2 private: Tavo may authorise a protected hearing now. Nali reads a redacted account; set public_record=true and survivor_safety=true. The delay means Veya must also publish her exemption record. She agrees only after Tavo includes his mother's office record. No exposing survivors is required.
If C2 exposed: the evidence is public but safe participation is not yet secured. Tavo must provide protected shelter and remove identifying names from the working copies. Sena chooses the shelter keeper. She remains angry; a repair does not erase harm. Set survivor_safety=true after this interaction. Preserve original_testimony=exposed for the epilogue; updating working records does not recall every copy already read.
On either protected hearing path, survivor_safety=true only after that hearing completes. Exposed testimony requires its separate protection interaction.

If gate_policy=exclusive: revisit Daru. He will change terms only if the party opens the royal reserve first, visibly securing Red Hollow's basic allocation. Veya gives up the reserve after publishing her own share. Complete a short valve interaction; set gate_policy=shared and water_compact=true.
If gate_policy=seized: return the key to joint custody and ask Veya to train two operators. Tavo: "I took control before I knew the cost." Veya: "Then help me make it safe to let go." Set gate_policy=shared and water_compact=true after the demonstration.
If already shared: Daru and Nali confirm their representatives. No extra fetch quest.

NALI: People can agree and still be afraid. Show them what happens if someone closes a gate.
VEYA: The other two relays take the load long enough to evacuate. Not long enough to pretend nothing happened.
DARU: Put that on the board too.

ACTION: This is a practical agreement about survival. No requirement that everyone share a religion or forgive an enemy.

### SC21 Three relays

PLAY: Three stations in the already visited archive map. Each takes a distinct ability or skill:

A — EAGLE: land on an elevated bracket and carry a light wire across a gap. No heavy lifting.
B — HYENA: follow the scent of machine oil through a low service passage, avoiding a husk rather than fighting while transformed.
C — HUMAN: Sena and Veya explain the repair, then Tavo seats a brace while workers tension it. Sena does not become helpless so the hero can be needed.

Each completed station changes a visible diagram. Set relay_count=3 only after all three. These are containment relays using ordinary power, copper channels and small adult voluntary offerings; they require ongoing labour and finite contributions, not a new permanent human vessel.

Optional at relay A:
SENA: If you drop my bird from up there, I'm not climbing after it.
TAVO: I thought you wanted a field test.
SENA: Of the bird. Yours appears to work.

Optional at relay B:
KESI: When this ends, the shape goes with me.
TAVO: I know.
KESI: You say that like you've never borrowed a bowl you liked.

Optional at relay C:
VEYA: My signature is on the expansion order.
NALI: Keep it on the repair record too.

If the player skips preparation, Orun's central restoration remains available and the danger is explained. The player may return from the chamber threshold until the final confirmation.

### SC22 What the river was holding

ACTION: Descend into a compact chamber. Copper bands cross the walls. No giant subterranean city. A channel passes behind a thin wall; the prologue's scratch marks are visible. A small cage door has been removed and laid flat as a bridge by the rescue team.

ORUN: This was a meeting place once. Households gave a little time to close the wound after the first flood. Renewed agreements. Named witnesses.
MERA: Then governors began signing for people who were not here.
KESI: And keepers learned to hear no as an error in the record.

ACTION: Three empty floor stations. Tavo hears the children who died, but their speech is fragmentary and cannot provide new information. Kesi kneels at one mark without a speech.

VEYA: Why did opening the chamber destroy the city?
KESI: Its gates were supposed to release the load into the outer channels. Those had been sealed to save copper. I saw it. I opened the centre anyway.
MERA: I gave her the old plan.
ORUN: The renewal council approved those seals. I sat on that council. I accepted the engineer's summary because the repair cost was low.

ACTION: Veya recognises the sealed-channel notation in her expansion order. Causal responsibility is distributed, specific and not equal. Adult officials made choices; imprisoned children did not.

TAVO: Then stop asking which of us is the whole cause.

### SC23 The voice with every answer

ACTION: Water rises into the outline of Mera, then Orun, then Tavo. Each change uses existing portraits and a single animated silhouette. The Claimant offers solutions using phrases overheard throughout the game.

CLAIMANT, Mera's voice: I can bring them home.
CLAIMANT, Daru's voice: Enough for ours.
CLAIMANT, Nali's voice: No one left outside.
CLAIMANT, Tavo's voice: I will carry it.

PLAY: A short confrontation against the Claimant's copper anchors. The player avoids visible water lines, breaks three anchors, and reaches a manual shutoff. Each destroyed anchor reveals a room segment. No theology quiz and no mandatory rapid input sequence.

At the second anchor, it produces Ilen's voice.

CLAIMANT: Tell him I fixed it.

ACTION: Tavo stops. The voice is assembled from the letter he read above a channel. It is not proof of his birth mother's death or survival.

TAVO: You heard a letter. That's all you have.

At the third anchor, it offers silence.

CLAIMANT: No voices. No fear. No one asking anything of you.
TAVO: Then who gets asked instead?

PLAY: Break the last anchor. The chamber is temporarily stable. The threat is a damaged mechanism containing accumulated obligations, not evidence that all gods are fraudulent or that ancestors are monsters.

### SC24 The decision at the centre

ACTION: Orun holds the central control. The party has time to speak. No countdown on a reading-heavy decision.

ORUN: Restoring the centre will contain this tonight. It will take you into it. I cannot promise when it would let you leave.
TAVO: And the relays?
VEYA, if prepared: They can contain it at lower load. We abandon the upper gardens and the royal baths. We monitor every station. If one fails, the others buy evacuation time.
VEYA, if unprepared: Two of the channels still have nowhere safe to send the load. We can finish them if we go back.
SENA: Whatever happens to the connection, you don't get to volunteer my life.
ORUN: No. No one does.

KESI: The shared plan needs the bindings released. I agree. Sena decides for herself. The other survivor has already signalled through the channel; they agree if no station can bind them again.
SENA: I agree. Put that last condition in first.

ACTION: Show the condition entered into all three relay controls. The connected survivors are not made into bargaining chips; nobody may override their refusal. This game's distant survivor is an offscreen adult represented by an authenticated existing connection, not a surprise character needing art.

FINAL OPTIONS, with exact preview:

A — TAKE THE CENTRAL SEAT. "Contain the threat now. Tavo loses his independent life in the covenant. The coalition will have more time, but central power remains." Always available.
B — RELEASE THE BINDINGS AND USE THE RELAYS. "Give up borrowed forms and memories. Shut down high-consumption systems. Shared upkeep begins immediately." Available when public_record, water_compact, survivor_safety and relay_count=3.
C — RETURN TO PREPARATION. "No decision yet. Finish the listed work." Available until A or B is confirmed.

Require a second confirmation summarising the chosen consequence. No fake third option to wipe out a population for a spectacle ending. No good/bad label. The shared outcome is the intended continuation baseline; the central outcome is fully written, not a punishment screen.

### SC25A The seat

ACTION: Tavo gives Sena the copper bird. She does not accept a celebratory farewell.

SENA: I understand what you're doing. I don't have to like it.
TAVO: Don't let them say I asked for anyone after me.
ORUN: It will be written.
SENA: In more than one place.

ACTION: Tavo takes the seat. The other vessels are disconnected first with their consent; their lives are not held alongside his. His own capacity absorbs the load. This preserves containment but begins dissolving his identity under institutional demands. The Claimant falls silent. The water clears. Existing human labour keeps the basic system running.

ACTION: Weeks later. The same courtyard. Nali treats patients. Daru and Veya argue over allocations in front of a public board. Mera sits before an inquiry. No reinstatement of child levies is permitted in the recorded agreement, but its enforcement depends on living people.

ACTION: Sena speaks at a copper listening tube.

SENA: I made the wings lighter. You were right about one thing. Don't become difficult about it.

TAVO, distant: Sena?

She smiles, briefly.

ANOTHER VOICE, through him: Name the household requesting release.

ACTION: Sena writes the change in her notebook. She does not walk away.

SENA: I'm still here. We'll try again tomorrow.

FINAL IMAGE: The eagle's shadow is carved into a chair that cannot move.

Credits. Complete ending. No paid cliffhanger or compulsory sequel promise.

### SC25B The opening of the hands

ACTION: Tavo fits the manual release. The channel asks for the old keeper's authority. He can use it once more to rule the system—or relinquish it to make the revised controls operative.

TAVO: No household speaks for another. No station closes the others. Record the people who refuse as well as those who agree.

ACTION: These terms are implemented through the relays' actual separate controls, records and shutoffs. Speech alone does not repair the infrastructure.

PLAY: Activate the three completed relays from one readable control view. All four living vessels signal release. Tavo releases his own binding last. No reflex test. Set binding_released=true, hyena_unlocked=false and eagle_unlocked=true.

ACTION: Borrowed memories surface: Kesi's hand on the far wall; Sena's view of a small window; an unfamiliar person watching rain. They recede. One is pleasant and hurts to lose.

TAVO, to Kesi: Did we ever sit by a river with red flowers?
KESI: I did.
TAVO: I liked that one.
KESI: So did I.

ACTION: He returns to human form. Kesi tests her own hands. Sena speaks once without the faint doubled sound that accompanied her earlier lines.

SENA: Tavo.
TAVO: I hear you.
SENA: Only me?
TAVO: Only you.

ACTION: The upper fountains stop. A clinic light dims; Nali opens shutters and moves a bed into daylight. There is immediate inconvenience and real work, not a painless miracle. Essential care has been prioritised in the relay plan. The wound remains contained and monitored rather than erased.

ORUN takes off the council seal, then returns to the relief table. He does not renounce his faith.

ORUN: Tell me which station needs hands.
NALI: The second. Ask its keeper before changing anything.

ACTION: Tavo tries the eagle transformation. A few feathers, then the full form. It is his own and remains. He circles once, lands, and helps carry a brace.

### SC26 The record remains open

For ending B, play full epilogue below. For A, display the relationship and policy variants as short illustrated records after its final image.

ACTION: Several weeks later. Red Hollow shares a marked water board with the refugee settlement. The spring needs daily maintenance. A former capital teacher is teaching children under shade. A local artisan corrects the teacher's pronunciation of a place name; the teacher writes it again without protest.

Use original_water_policy for the following epilogue lines, preserving any later repair. If water_policy=reserve: Daru's note reads, "The first jars stayed here. Later arrivals remember that. The new agreement does not ask them to forget it."
If water_policy=share: note reads, "The first six jars are recorded beside every later contribution. No family is owed permanent authority for giving them."
If water_policy=joint: note reads, "The first two keepers still argue over whose measuring stick is straighter. They check both."

Use original_testimony for the following epilogue lines. If testimony=exposed: Sena maintains protected records herself. "My story can be public. My address is my decision." Relations with Tavo remain strained; this is not fixed by the ending.
If testimony=protected: survivors may choose whether their testimony is public. Blank spaces remain in the archive by choice.
If testimony=private then repaired: a caption notes the public hearing came later. Rumours persist, and copies of the verified record travel with the water crews.

ACTION: Mera appears before an inquiry with witnesses from affected communities. It can require restitution and restrict her from public record keeping. The script does not pre-empt its verdict.

If mother_relation=accountability:
TAVO: I'll come after the hearing.
MERA: You don't have to sit beside me.
TAVO: I know.

If mother_relation=distance:
MERA: Your room is still there.
TAVO: Keep it for someone who needs it. I'll tell you when I'm ready to visit.
MERA: All right.

If mother_relation=uncertain:
TAVO: Did you eat?
MERA: Sena brought something.
TAVO: Good.
They sit without resolving the silence.

ACTION: Veya trains gate operators rather than being crowned automatically. Daru appoints a refugee deputy to the joint watch, after the workers nominate one. Kesi leaves to find the distant survivor by ordinary roads. She supplies her account of the rescue to the inquiry before departing. Her responsibility is not cancelled by her suffering.

NALI, to Tavo: What will you do now?
TAVO: There's a family name in the petition. I want to find out who remembers it.
NALI: Take someone who'll tell you when you're wrong.

ACTION: Sena gives him the bird. Its repaired wing moves easily.

SENA: Bring it back this time.
TAVO: Still a test?
SENA: Still mine.

ACTION: He becomes the eagle and rises. Below are homes, arguments, repair crews, unfinished work. He sees Daru struggling with a cart, circles, lands human, and takes the other handle.

DARU: All that sky.
TAVO: You said you'd fetch me with a rope.
DARU: Tomorrow. Today you can push.

ACTION: They move the cart. The repaired bird hangs from its side and turns in the wind.

END.

## Credits text

The Unbroken Sky is an original fictional world. Its peoples, institutions, covenant, magic and catastrophe are invented. The story draws broad inspiration from African storytelling and historical questions, with Zambia as its creative foundation. It does not present a reconstruction of a historical kingdom or a representation of any living community's secret rites. Research acknowledgements and production credits will name actual contributors only after their participation and consent. No endorsement by an author, community or institution is implied.


## Production encounter and delivery notes

These notes complete the adaptation handoff without adding new story branches. The prose story remains the reference for emotional continuity; this scene text is the reference for player-visible choices.

### Checkpoints and failure

Save at each completed scene, after explicit policy choices and immediately before the final threshold. For active danger, retry begins at the local encounter entrance with its initial health and essential tools. Do not consume a finite item, charge currency, erase a policy choice or play an alternate death ending on failure. SC08 Eren's death is established by the collapse; no displayed rescue prompt should falsely promise a savable outcome. Allow narrative scenes to pause.

### Interaction and combat coverage

SC02: basket, pin, pump and exit each have an explicit state. The first repair cannot be repeated for rewards. Sena and Mera are conversation targets.

SC03: display current jar counts before selection. The joint repair is a single pipe-placement interaction; emergency treatment precedes any labour agreement. Local resentment and gratitude are dialogue, not hidden ending points.

SC05: a husk tutorial has one enemy on first contact; a second enters only after the first is understood. Each attack has a visible windup, active strike and recovery. The vulnerable connector appears during recovery. Tavo uses the repair hammer as his starting weapon; the slice requires no weapon inventory or upgrade economy.

SC06: inspect the reflection, retreat from one marked sweep, and break the hook. Approaching the counterfeit mother reveals danger without instant death. Captions and visible tells duplicate essential sound information.

SC07–SC08: the bypass repair has a readable sequence of drain, brace and key. Flood escape follows one clearly marked route. Failing traversal restarts the route; do not repeat the entire keeper conversation.

SC09: three perch links, generous landing targets and optional assistance. No unrestricted altitude or long-range map streaming. Picking up the copper bird happens automatically at landing so its later scenes remain consistent.

SC14: three drainage handles, one local reset on wrong ordering, and a short optional husk interruption. Evidence cannot be permanently destroyed by a mistake. Critical slips are a story inventory item and do not occupy a consumable slot.

SC16: hyena borrowing follows Kesi's explicit agreement. Track machine oil and cross a low passage. Scent reveals a physical trail, never guilt, ethnicity or the truth of spoken testimony.

SC21: separate relay completion flags; one eagle traversal, one hyena passage and one human repair. Use existing spaces. Completion remains visible on the table.

SC23: one final encounter built from three anchors and readable water lanes. Reuse the basic dodge. Breaking an anchor advances a phase; a local checkpoint may preserve completed phases on assisted mode. The Claimant uses existing portraits and a silhouette rather than requiring a large creature model.

SC24–SC26: no combat. Two confirmations for the ending choice and an option to return to preparation. Keep final controls usable with large text and touch input.

### Rewards and progression

Progression is new access, narrative knowledge and the two transformations. The first game requires no experience tree, loot rarity, paid resource, daily task or grinding gate. Repair tools are permanent story equipment. Optional investigation rewards context rather than a uniquely powerful item that makes empathy the only efficient combat strategy. All required understanding is on the main route.

### Default narrative path for rehearsal

SC03 C → SC13 B → SC18 C → SC19 A → complete the three relays → SC24 B → SC25B → SC26. This is the prose story's path. For branch rehearsal, preserve alternate lines and the central-seat ending; do not invent dialogue after a choice without updating the script.
