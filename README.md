# WeaponTips

**Can I use this weapon? Can I learn it — and who teaches it?**

WeaponTips is a lightweight tooltip addon for WoW Classic Era / Hardcore,
TBC Classic (Anniversary) **and** the WoW Forever beta. Every weapon
tooltip gets one clear,
color-coded answer — especially handy on low-level characters, when half
the loot is a weapon type you've never held before:

- <span style="color:#66e666">**Green**</span> — <span style="color:#66e666">*"You can use this weapon (57/150)."*</span> You have the weapon
  skill, shown with your current and maximum skill level.
- <span style="color:#ffd100">**Yellow**</span> — <span style="color:#ffd100">*"Can be trained in: Ironforge, Darnassus"*</span>. Your class can
  learn this weapon type but hasn't yet — the line lists exactly the
  cities of **your faction** whose weapon master teaches it, plus the
  training cost and level requirement (polearms: 1g, from level 20 —
  everything else 10s, no level). No more guessing which capital to
  fly to, or when.
- <span style="color:#ff5959">**Red**</span> — <span style="color:#ff5959">*"Your class cannot use this type of weapon."*</span> Your class can
  never learn it: need or greed with a clear conscience.

Works everywhere a weapon tooltip shows: bags, loot, vendors, the auction
house, chat links and compare tooltips.

## Knows its trainers

The weapon master data is faction-aware and per weapon type — swords in
Stormwind and Undercity, guns in Ironforge and Thunder Bluff, staves in
Darnassus and Orgrimmar, and so on. On TBC realms the Silvermoon City and
Exodar weapon masters are included automatically.

The special cases are handled too:

- **Shamans** looking at a two-handed axe or mace are told it requires
  the *'Two-Handed Axes and Maces'* talent — no weapon master teaches
  those, and no addon should send you on that trip. (On WoW Forever the
  talent is gone: shamans get the weapon master cities like everyone
  else.)
- **Wands** are never trained: the classes that can use them start with
  the skill, so wands simply show <span style="color:#66e666">green</span> or <span style="color:#ff5959">red</span>.
- Fishing poles and novelty "weapons" are left alone.

## Always in sync

Your known skills are read straight from the game's skill window data —
no manual sync, no cache to build. Learn a new weapon skill or gain a
skill point and the tooltip is correct the next time you hover a weapon.

## Configuration

Settings -> Options -> AddOns -> WeaponTips, or simply `/weapontips`.
Each of the three lines (<span style="color:#66e666">green</span> / <span style="color:#ffd100">yellow</span> / <span style="color:#ff5959">red</span>) can be toggled
independently.

## Data & compatibility

- Runs on **Classic Era 1.15** (including Hardcore and Anniversary
  realms), **TBC Classic Anniversary 2.5** and **WoW Forever 1.60** from
  one codebase — the right data loads automatically per client.
- **WoW Forever is still in beta.** Class rules come straight from the
  beta client's data (rogues can train one-handed axes there). Weapon
  master cities and prices are not part of the client data, so the
  Classic values are shown until the beta proves otherwise — if a
  Forever weapon master teaches something different, please report it.
- Fully locale-safe by design: weapon types are matched by item subclass
  ID, known skills via the proficiency spells' own localized names, and
  trainer cities display as localized map names — it works identically
  on every client language.
- Class rules match the client: no rogue axes on Classic and TBC, no
  druid polearms — those came years later, and WeaponTips won't send you
  to a trainer who can't help you.
- Tiny footprint: no libraries, no minimap button, nothing until a
  weapon tooltip appears.

## Limitations & Roadmap

- The addon's own lines are translated for **German, French, Spanish
  (EU and Latin America), Brazilian Portuguese and Russian**; other
  locales see English. Corrections from native speakers are very welcome!
- The <span style="color:#ffd100">yellow</span> line names the cities, not the exact NPC — weapon masters
  are easy to find via the city guards ("Weapon Master"). Naming the NPC
  and district is on the list.

Spotted a weapon type with a wrong city or class rule? Please report it
with your class, faction and the weapon — the data tables are tiny and
easy to fix.

---

Enjoying WeaponTips? You can support development on
[PayPal](https://paypal.me/adrianh91) — never expected, always
appreciated.
