# Changelog

## v1.4.0 (2026-09-20)

- Added support for WoW Forever (Interface 16001): weapon skill levels are
  read straight from the skill line there, in every client language.
- WoW Forever rules, taken from the beta client's data: rogues can train
  one-handed axes, and shamans are pointed to a weapon master for
  two-handed axes and maces (the talent no longer exists there).
- Weapon master cities and prices on WoW Forever are the Classic ones for
  now - the beta client does not contain trainer data. Please report any
  weapon master that teaches something different.
- Classic Era and TBC Anniversary behave exactly as before.

## v1.3.0 (2026-08-16)

- Added Russian (ruRU) translation for all tooltip lines and options.

## v1.2.1 (2026-07-24)

- Maintenance release: release notes now come from a curated changelog
  instead of raw commit output. No in-game changes.

## v1.2.0 (2026-07-22)

- Fixed known one-handed weapons showing as trainable.
- Covered all client locales.

## v1.1.2 (2026-07-22)

- Bumped Interface to 11509 for Classic Era 1.15.9.

## v1.1.1 (2026-07-21)

- Added the CurseForge project ID to the TOCs.
- Fixed skill-scan event suppression.
- Internal: headless test suite.

## v1.1.0 (2026-07-21)

- Show training cost and level requirement on trainable weapons.

## v1.0.0 (2026-07-21)

- Initial release: weapon skill training hints on weapon tooltips for
  Classic Era.
