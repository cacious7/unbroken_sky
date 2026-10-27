# The Unbroken Sky launch plan

Version 1.0 • 27 October 2026 • Supersedes the release sequencing in IMPLEMENTATION_PLAN.md; its systems, acceptance criteria and scope controls still apply.

## The decision

Ship **Chapter One (Act One, SC01–SC10) as a free Android game**, built in **Godot 4**, on Google Play, with a direct APK and a PC build on itch.io. Target a public Play release in **about 12 weeks (mid-to-late January 2027)**. Build Chapters Two and Three afterwards, guided by what real players do.

The full three-act game stays the goal. It is not the first release. A solo developer who tries to finish 26 scenes, three forms and two endings before anyone plays will be working for a year or more with no feedback. One finished chapter puts the game in players' hands within weeks.

## Why these choices

### Mobile first, Android only

- Most Zambian phones run Android. iOS would cost US$99 a year and needs a Mac to build, so it waits until the game has an audience.
- People download and install games. Nobody needs to open a website to play. This answers the concern about playing in a browser.
- Mobile data is expensive, so a small download is a feature. Target **under 80 MB installed** and measure it every build.
- It has to run offline on ordinary phones. There are no accounts and no server.

### Godot 4, not Unreal or Unity

| | Godot 4 | Unity | Unreal 5 |
| --- | --- | --- | --- |
| Fit for a 2D story game | Excellent: 2D is a first-class engine | Good | Poor: built for high-end 3D |
| Editor download | About 100 MB, no installer | Several GB plus a hub and account | Tens of GB, plus the Android toolchain |
| Smallest Android build | About 25–40 MB | Larger | Usually well over 100 MB |
| PC needed | Runs on modest laptops | Mid-range | Strong GPU, lots of RAM and disk |
| Cost and licence | Free, MIT, no royalties | Free tier with licence terms | Free, then 5% royalty above US$1M |
| Learning curve | GDScript is close to Python | C# | C++ / Blueprints, steep |

Unreal is the right engine for a 3D team with strong hardware. For one person making a 2D narrative game that must download cheaply over Zambian mobile data, it is the wrong tool. Godot was already the recommendation in research/R14. This plan confirms it.

### Episodic release, free first chapter

- Act One already ends on a cliffhanger: "The water reached home before the truth did."
- A free chapter makes trying the game risk-free, which matters before anyone knows the game.
- Each later chapter is a new release moment you can announce.
- Payment comes later, if at all. Before planning a paid unlock, check that Google Play supports merchant payouts to a Zambian account and that local players can pay through Play (card, mobile money or carrier billing). Do not build a business model on an unverified payment route.

### Worldwide reach costs almost nothing extra

Google Play compatibility comes first. The same Godot project also exports a **web build** (playable in any browser, no install), Windows and Linux. The Compatibility renderer is required for web export, so it serves both cheap phones and browsers. Keep all text in data files from the start so translation later is an import, not a rewrite. English first.

| Channel | Role | Cost | When |
| --- | --- | --- | --- |
| Google Play | Primary; Zambia and Android worldwide | US$25 once | Closed test week 6, public week 12 |
| itch.io (web + APK + Windows) | Global indie audience; playable in browser; early public feedback | Free | Public web demo from week 4–5 |
| Newgrounds, Game Jolt | Free web portals with active communities | Free | Launch week |
| CrazyGames, Poki | Very large web traffic, revenue share; they prefer quick loads and short sessions, so acceptance is not guaranteed | Free to submit | After launch, if web build loads fast |
| Steam | Large PC audience | US$100 per game | After Chapter One proves interest |
| Samsung Galaxy Store | Secondary Android store, relevant given Samsung's share of Zambian phones | Free | Optional after Play launch |

Web build rules: keep it small (target under 40 MB), keep the single-threaded web export so it runs on itch.io without special server headers, and test touch input in mobile browsers too.

## Chapter One scope (locked)

In: SC01–SC10 exactly as scripted. Three spaces: Red Hollow, Ash Road, Reed Gate. Human and eagle forms. One husk enemy (strike, dodge, interrupt). One water-figure encounter. Choice C1 with its three outcomes. Local save with checkpoints. Touch controls. Text-only dialogue with still portraits. Captions. Large text. End card: "Chapter Two coming. Tell us what you thought" with a feedback link.

Out until Chapter One ships: hyena form, archive, branching beyond C1, endings, voice acting, cutscene video, analytics SDKs, ads, in-app purchases, iOS, cloud saves.

If a week slips, cut polish, not scenes, and keep the dates honest. If something still has to go, the shared repair mini-game in SC03 C can become a short staged sequence.

## The 12-week plan

Assumes about **15–20 focused hours per week**. With less time, stretch the weeks and keep the order.

| Week | Dates (2026–27) | Build | Finish line |
| --- | --- | --- | --- |
| 1 | 28 Oct – 3 Nov | Setup and the well room (FIRST_BUILD_PLAN.md) | SC02 playable on desktop **and installed on your own Android phone**. Google Play developer account registration started. |
| 2 | 4 – 10 Nov | Core systems | Dialogue runner reading JSON, save/load, touch joystick and action buttons, settings (text size, text speed). |
| 3 | 11 – 17 Nov | Combat and flight | One husk you can read and beat; eagle perch-to-perch flight with wide landing zones. Both tested on the phone. |
| 4 | 18 – 24 Nov | Greybox SC01–SC05 | Prologue through Ash Road playable in shapes. **First APK sent by WhatsApp to 5 people.** Watch at least two of them play. |
| 5 | 25 Nov – 1 Dec | Greybox SC06–SC10 | All of Act One playable start to finish in placeholder art. C1 choice saved and remembered. |
| 6 | 2 – 8 Dec | Fix what testers hit, lock art style | Biggest confusion points fixed. One art style chosen and one finished test scene. **Google Play closed test opens with at least 12 testers** (starts the 14-day clock). |
| 7–8 | 9 – 22 Dec | Art pass | Tavo and eagle sprites, husk, three spaces, portraits for Tavo, Mera, Sena, Daru, Nali, Veya, Eren, Kesi, Orun. Updated builds pushed to testers. |
| 9 | 23 – 29 Dec | Sound and feel | Ambient loops, effect sounds, captions for every important sound. Screen shake and flash can be turned down. |
| 10 | 30 Dec – 5 Jan | Device and release hardening | Clean install, offline run, suspend/resume, low storage, 2–3 different cheap phones. Download size recorded. |
| 11 | 6 – 12 Jan | Store preparation | Icon, 4–8 screenshots, short trailer (screen recording is fine), description, content rating questionnaire, privacy policy page. Apply for production access. |
| 12 | 13 – 19 Jan | **Launch** | Chapter One live on Google Play (free) and itch.io (Android APK + Windows). Announcement on WhatsApp groups, Facebook, TikTok clips of the eagle sequence. |

Weeks 7–9 run over the holidays. If that time is unavailable, move everything after week 6 later and keep the closed test running.

## Google Play: plan around these rules

As of my last check (confirm each one when you register, because Google changes them):

- A personal developer account costs a **one-time US$25** and needs identity verification. Verification can take days, so start it in week 1.
- **New personal accounts must run a closed test with at least 12 opted-in testers for 14 days in a row** before they can apply to publish publicly. This is why the closed test starts in week 6, not week 11. Testers need a Google account and an Android phone, and must stay opted in for the whole 14 days. Ways to reach 12 without knowing 12 testers personally:
  - **Tester exchanges:** r/AndroidClosedTesting, r/TestersCommunity and similar Discord groups, where developers test each other's apps to meet this rule. Join in week 4 and help others first, so testers are ready by week 6.
  - **Players from the itch.io web demo** who ask to try the Android version.
  - **Organisation account instead:** the rule applies to personal accounts only. A registered business (PACRA) plus a free D-U-N-S number avoids it, but the number can take days to weeks to arrive. Decide in week 1.
  - Recruit about 15–20 to allow for drop-outs.
- Apps must target a recent Android API level and support 16 KB memory pages. Use the current stable Godot 4 release and its current Android export template, which handle both.
- You need a privacy policy URL even if you collect nothing. A one-page statement on a free site is enough: "This game collects no personal data."
- Keep the upload signing keystore **outside the project folder and outside OneDrive sync**, with a backup. Losing it means you can never update the game.

## Getting players and learning from them

- **Weeks 4–6:** sideload by WhatsApp to people you can watch playing. Don't explain anything first. Afterwards ask three questions: What were you trying to do? Who did you trust? Would you play Chapter Two?
- **Closed test:** use the Play Console tester feedback and a short Google Form linked from the end card.
- **After launch:** measure without an analytics SDK. Use Play Console installs and uninstalls, ratings, form responses and the number of people asking for Chapter Two. Add privacy-respecting analytics only if those signals aren't enough.
- **Marketing that costs nothing:** short vertical clips from the game (the black-water reveal, the water figure, the first flight) on TikTok, Instagram and Facebook. Post progress publicly from week 4, because a devlog builds an audience before launch. Zambian tech and creative communities, university groups and local media like a "Zambian-made game" story.

## After launch: decision gate (late January 2027)

| Signal | Action |
| --- | --- |
| Players finish Chapter One and ask for more | Build Chapter Two (SC11–SC18, adds hyena and the archive) on the same 8–10 week rhythm. Look at payment options now. |
| Players drop off early | Fix the opening first: controls, pacing, clarity. Ship 1.1 before writing new content. |
| Strong interest outside Zambia | Prioritise itch.io/PC presence and a first translation (French or Portuguese for regional reach, chosen from where the players are). |
| Little interest anywhere | Treat it as a successful learning release. Revisit hook, art and marketing before investing in Chapter Two. |

## Development computer (checked 27 October 2026)

Windows 10 Pro, Intel Core i5-6500 (4 cores), 16 GB RAM, Intel HD Graphics 530 (integrated), about 289 GB free on C: and 297 GB on D:. Git and VS Code are installed. Godot, Java and the Android SDK are not installed yet.

This confirms the engine choice. Integrated HD 530 graphics are far below what the Unreal 5 editor expects, but enough for a Godot 2D project. Use the **Compatibility renderer**. Its OpenGL-based rendering is also the safest choice for cheap Android phones. Week 1 installs: Godot 4 (current stable, standard build), OpenJDK 17, and the Android SDK command-line tools (or Android Studio, if you prefer a guided installer).

## Information still needed (first session, 28 October)

1. Test phone model and Android version.
2. Programming experience, if any.
3. Realistic hours per week.
4. Twelve people who could join the closed test.

## What stays true from the earlier documents

Narrative canon, the choice state specification, cultural boundaries in the research register, accessibility commitments and the "no punitive retention mechanics" rule are unchanged. This plan changes only **what ships first and when**.
