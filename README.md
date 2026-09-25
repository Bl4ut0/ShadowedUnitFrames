# Shadowed Unit Frames for WoW Forever

An unofficial fork of [NoSelph's Shadowed Unit Frames](https://github.com/NoSelph/ShadowedUnitFrames), adapted from v4.6.7 for the WoW Forever 1.60 client. **RC7 is a test candidate** for interface 16001. It restores SUF's Battleground opponent frames; Arena frames remain disabled. Retail behavior and saved profile settings remain in the code.

## Download and install RC7

Download [v4.6.7-Forever-RC7.zip](https://github.com/Bl4ut0/ShadowedUnitFrames/releases/download/v4.6.7-Forever-RC7/v4.6.7-Forever-RC7.zip) from the [RC7 release](https://github.com/Bl4ut0/ShadowedUnitFrames/releases/tag/v4.6.7-Forever-RC7). Extract both top-level folders, ShadowedUnitFrames and ShadowedUF_Options, into the Forever client's Interface/AddOns directory. Remove or replace older copies of those folders, then restart the client or use /reload.

**Use the attached ZIP.** GitHub's automatically generated Source code ZIP does not include the bundled libraries needed by the addon.

ZIP SHA256: `6d6adbf549239e41816b8b0e9248088e0f9a4cf18710b84365bdc6173347a943`

## Cumulative candidate history

**RC7 is cumulative.** It is built from NoSelph's packaged v4.6.7 release and includes every Forever change introduced from RC1 through RC7. Install RC7 by itself; you do not need to install earlier candidates first. RC3 and RC4 were intermediate revisions folded into later packages, so they do not have separate GitHub release pages.

| Candidate | Change carried forward into RC7 |
| --- | --- |
| RC1 | Initial Forever interface support, Classic range and dispel spell candidates, and protection from restricted threat values. |
| RC2 | Corrected build detection so the addon finishes startup instead of passing multiple GetBuildInfo results to tonumber. |
| RC3 | Disabled the incompatible pet-battle secure state driver and guarded Blizzard unit frames absent from Forever. |
| RC4 | Avoided the Retail specialization API that fails on Forever. |
| RC5 | Gated unsupported Retail frames, modules, indicators, and options; added Classic combo-point and master-loot handling; kept imported Retail profiles from re-enabling unsupported frames. |
| RC6 | Removed the remaining Forever paths into SUF's custom secure snippets for party, raid, raid-pet, and boss frames while retaining those frames and Retail implementations. |
| RC7 | Restored Battleground opponent frames and their options using Forever's `arenaN` flag-carrier unit tokens. Arena match frames remain gated; live Battleground validation is pending. |

## What changed from upstream v4.6.7

| Area | Forever behavior |
| --- | --- |
| Client detection | Detects Forever by its 16xxx interface version and adds 16001 to both addon TOCs. |
| Classic gameplay data | Uses Classic spell candidates for range checks, Classic combo points, and compatible dispel and master-loot information. |
| Restricted values | Avoids Lua comparisons of secret threat, unit, and reaction values. A threat indicator may be hidden when its value is secret. |
| Blizzard UI differences | Tolerates Blizzard frames missing from Forever and avoids Retail specialization calls that fail on this client. |
| Group and boss frames | RC6 avoids addon secure snippets that Forever cannot compile. Blizzard's stock group headers create party, raid, and raid-pet buttons; SUF initializes them afterward. Party and raid use direct visibility drivers, and boss buttons use stock unit watches. |
| Battleground frames | RC7 restores the four Battleground opponent frames and their options using the arenaN unit tokens used for flag carriers. Arena match frames remain gated. |
| Profiles and options | Unsupported controls are hidden on Forever. Imported Retail profiles cannot reactivate unsupported units; anchors to those units fall back to the screen without rewriting saved positions. |
| Retail | The original Retail implementations and saved settings remain available when running on Retail. |

The [technical notes](FOREVER.md) document the reported errors and implementation across RC1–RC7, including the RC6 fix for `RestrictedExecution.lua:79` during party-header creation.

## Features currently disabled on Forever

These are compatibility gates in this fork. They do not establish that Forever has no equivalent game mechanic.

- SUF's dedicated Arena opponent frames, including pet, target, and target-of-target variants. Battleground opponent frames are available in RC7; their live match behavior still needs validation.
- Vehicle unit swapping and pet-battle frame behavior.
- Retail resource widgets: alternate encounter power, arcane charges, chi, essence, holy power, priest/shaman secondary mana, DK runes, soul shards, and stagger. Classic combo points, shaman totems, and the druid mana bar remain.
- Arena spec, dungeon role, phase/other-party, quest-boss, and pet-battle indicators. Common indicators such as raid target, ready status, class, and leader remain.
- Empowered-cast events and six matching Retail resource tags. Ordinary cast bars and other tags remain.

The main remaining frame omission is Arena opponents. The alternate encounter power bar and vehicle swapping are also disabled pending checks that Forever has corresponding mechanics.

## RC7 test status

All 50 tracked addon Lua files parse, and the RC7 ZIP is checked against the installed files. Live Battleground opponent updates and possible overlap with Blizzard's flag-carrier UI still need a match test. Party and raid formation, raid pets, boss visibility, custom click-casts, combat transitions, and imported profiles also need in-game validation. On Forever, group buttons use SUF's normal click-cast registration instead of its restricted header snippet. Boss header dimensions may update after combat when boss visibility changes during combat.

## Report a bug

[Open a WoW Forever bug report](https://github.com/Bl4ut0/ShadowedUnitFrames/issues/new?template=bug_report.md) in **this fork's GitHub Issues**. You can also [browse existing reports](https://github.com/Bl4ut0/ShadowedUnitFrames/issues) before filing a duplicate.

Include the RC version, Forever build/interface number, the full Lua error and stack if present, steps to reproduce, the unit frame and content type involved, your class, whether it happens with a clean SUF profile, and other enabled addons. Screenshots or a short recording help with layout problems. Please report Forever-specific problems here rather than on the original project's issue tracker.

## Source and attribution

This is an unofficial Forever port of [NoSelph's SUF project](https://github.com/NoSelph/ShadowedUnitFrames). The Forever compatibility code is in [upstream PR #151](https://github.com/NoSelph/ShadowedUnitFrames/pull/151). This fork's release README, issue template, technical notes, and packaging script live on the fork-only release branch. For upstream code contributions, use the code-only `forever` branch as the pull-request head; the default `forever-release` branch also contains fork-owned release files.
