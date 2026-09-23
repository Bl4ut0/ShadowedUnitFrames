# WoW Forever port: technical notes

This is the cumulative technical record for the Forever port of Shadowed Unit Frames, from **RC1 through RC6**. RC6 is built from NoSelph's packaged v4.6.7 release and includes every earlier Forever change; users install RC6 alone. The [README](README.md) covers installation and the user-facing feature list. This page records the reported problems, their causes, the implementation, and what still needs testing.

The upstream [Forever support request #150](https://github.com/NoSelph/ShadowedUnitFrames/issues/150) asks for a port and for profile import/export between Retail and Forever. The errors below came from the test chat; they were **not filed as numbered GitHub issues**. Commit links identify the corresponding code changes.

## Reported problems and candidate history

| Candidate | Evidence from the test chat or audit | Change |
| --- | --- | --- |
| [RC1](https://github.com/Bl4ut0/ShadowedUnitFrames/commit/b26ac0a) | Initial port for issue #150; no crash report yet. | Added interface 16001, a Forever client gate, Classic range and dispel spell choices, and restricted-value guards. |
| [RC2](https://github.com/Bl4ut0/ShadowedUnitFrames/commit/928ecd5) | `ShadowedUnitFrames.lua:12: bad argument #2 to 'tonumber' (number expected, got string)` on startup. Later nil-call errors in `units.lua` and `movers.lua` were cascades because the core file stopped loading. | Read only the fourth `GetBuildInfo()` result before converting it. |
| [RC3](https://github.com/Bl4ut0/ShadowedUnitFrames/commit/455a18f) | `RestrictedExecution.lua:79: attempt to call a nil value`, reached from `modules/units.lua:45` during the pet-battle driver setup; also `ShadowedUnitFrames.lua:1232: attempt to index local 'frame' (a nil value)` while hiding Blizzard frames. | Skipped SUF's pet-battle restricted wrapper on Forever and tolerated Blizzard frame globals that are absent there. |
| [RC4](https://github.com/Bl4ut0/ShadowedUnitFrames/commit/3dffba0) | Compatibility audit found a `GetSpecialization()` path that can fail on Forever. No separate user stack was retained for this candidate. | Avoided the Retail specialization call in Forever visibility logic. |
| [RC5](https://github.com/Bl4ut0/ShadowedUnitFrames/commit/ea751a3) | Broader audit of Retail-only assumptions, prompted by the repeated test failures. This was a preventive pass, not a single reported stack. | Gated unsupported frames, widgets, indicators, events, and options; added Classic combo-point and loot handling; protected imported profiles. |
| [RC6](https://github.com/Bl4ut0/ShadowedUnitFrames/commit/73c0283) | A second `RestrictedExecution.lua:79` error, this time through `RegisterStateDriver` at `Units:LoadGroupHeader` while creating the party header on Sep 23. | Removed the remaining SUF-authored restricted snippets from Forever group and boss frame paths while retaining those frames. |

RC3 and RC4 were intermediate revisions folded into later packages; they do not have separate GitHub release pages. The table describes the development sequence, not six packages that must be installed in order.

## Client detection and startup (RC1–RC2)

Forever reports the Mainline project ID and exposes modern restricted UI APIs, but its class and spell data follow Classic. The project ID alone would therefore select the wrong gameplay paths. [`ShadowedUnitFrames.lua`](ShadowedUnitFrames.lua) marks interfaces from 16000 through 19999 as Forever, using the **fourth return value** of `GetBuildInfo()`. The [main addon TOC](ShadowedUnitFrames.toc) and [options addon TOC](options/ShadowedUF_Options.toc) both include 16001.

RC1 passed `select(4, GetBuildInfo())` directly into `tonumber`. Lua can pass *all* values from a final function call, so `tonumber` received an unwanted second string argument as its base. The resulting startup error prevented the core module API from being defined; the later `units.lua` and `movers.lua` nil calls in that same report were consequences of the first failure. RC2 assigns the fourth result to one local variable, then calls `tonumber(interfaceVersion)`.

The Forever gate is shared by frame loading, module registration, indicators, options, and visibility. The gated Retail features and saved settings remain available on Retail; shared secret-value guards apply on both clients.

## Classic gameplay data with restricted UI values (RC1 and RC5)

| Area | Technical change | Reason or limit |
| --- | --- | --- |
| [Range](modules/range.lua) | Forever uses a separate list of Classic spell IDs, resolves only available spell names, chooses friendly/hostile spells through SUF's secret-aware reaction helper, and refreshes choices on `SPELLS_CHANGED`. | The Retail spell list and `PLAYER_SPECIALIZATION_CHANGED` event do not match Forever's spells and progression. The Forever path skips `UnitPhaseReason`. |
| [Dispel and cure](modules/units.lua) | A Forever spell-ID table drives which debuff types the player's class can remove; `SPELLS_CHANGED` refreshes known cures. | Modern aura restrictions remain, but Retail's dispel spell IDs are not suitable for this client. |
| [Threat and reaction](ShadowedUnitFrames.lua) | `GetReadableThreatSituation` uses `pcall` and checks `issecretvalue` before health coloring or threat highlighting compares the result. Reaction checks avoid branching on secret friend/enemy booleans. | Addon Lua cannot compare a secret threat value with `3`. Aggro coloring or highlighting may be absent when the state is secret. See [health](modules/health.lua) and [highlight](modules/highlight.lua). |
| [Combo points](modules/combopoints.lua) | Forever reads `GetComboPoints("player", "target")`, uses `MAX_COMBO_POINTS`, and updates on `PLAYER_TARGET_CHANGED`. The `cpoints` tag uses the same Classic API. | Retail's player power route can miss target-based Classic combo points. See [tags](modules/tags.lua). |
| [Master loot and indicators](modules/indicators.lua) | Forever uses `GetLootMethod()` and compares with `"master"`; missing summon or group APIs are guarded. | Retail's `C_PartyInfo.GetLootMethod` and `Enum.LootMethod` assumptions are not reliable on Forever. |

These are compatibility choices based on the available client code and reported failures. In-game checks are still needed for class-specific spells, threat presentation, and unusual group states.

## Missing Blizzard UI and Retail-only systems (RC3–RC5)

The RC3 nil-frame error came from SUF assuming every Retail Blizzard frame global exists. The hide helpers now skip missing frames, and boss-frame access checks that the frame and its nested content exist. RC5 also handles the older party-frame layout when `PartyFrame.PartyMemberFramePool` is unavailable and guards compact raid manager functions. See [`ShadowedUnitFrames.lua`](ShadowedUnitFrames.lua).

[`ShadowUF.foreverUnsupported`](ShadowedUnitFrames.lua) is the central RC5 gate:

| Disabled on Forever | Effect |
| --- | --- |
| Dedicated arena and battleground opponent units, including pet, target, and target-of-target variants | SUF does not create or offer these opponent frames. Normal player, target, party, and raid frames still load in PvP. |
| Alternate power and Retail class bars: arcane charges, chi, essence, holy power, priest/shaman secondary mana, DK runes, soul shards, stagger | These SUF widgets are not registered. Classic combo points, shaman totems, and the druid mana bar remain. |
| Arena spec, dungeon role, pet battle, phase, and quest-boss indicators | The unsupported indicators are not enabled or offered in Forever options. |
| Vehicle switching and pet-battle wrapper | SUF does not swap unit frames to vehicle units or run the Retail pet-battle hide driver on Forever. |
| Empowered-cast and phase events; Retail-only resource tags | Their event subscriptions and tag choices are omitted where the client paths do not apply. Ordinary cast bars and other tags remain. |

This list describes **SUF compatibility gates**; it does not establish whether Forever has an equivalent game mechanic. RC5 applies the gates at module registration, unit loading, unlock/test mode, and options construction. An imported Retail profile cannot re-enable unsupported unit frames through its saved visibility settings. If an active frame was anchored to a now-disabled frame, the layout uses `UIParent` as the runtime anchor without rewriting the saved position. Options omit unsupported controls. See [units](modules/units.lua), [layout](modules/layout.lua), [movers](modules/movers.lua), and [options](options/config.lua).

RC5 also avoids the Retail `CanHearthAndResurrectFromArea` assumption in zone logic, skips Forever subscriptions to `UNIT_PHASE` and arena-opponent events, and does not register empowered-cast events. RC4 specifically guarded `GetSpecialization()` in unit visibility. The original Retail behavior remains available when the same code runs on Retail.

Issue #150 also asks about moving profiles between clients. **Preserving saved settings and guarding imported Retail values is implemented; full profile export/import compatibility has not been verified in game.** That needs a separate test with representative Retail and Forever profiles.

## Restricted execution and secure frames (RC3 and RC6)

Two test reports reached the same Blizzard error line from different SUF callers. In the installed Forever client, `Blizzard_RestrictedAddOnEnvironment/RestrictedExecution.lua` calls `loadstring_untainted` at line 79 to compile a restricted closure; the reported call finds that function nil. This is why editing a state-driver conditional alone cannot resolve either report.

### RC3: pet-battle wrapper

At addon load, SUF's Retail pet-battle wrapper installed a `WrapScript` handler, then registered a `petbattle` state driver. Its first update reached the restricted compiler at `modules/units.lua:45`. Forever now leaves the wrapper visible and skips both the custom script and its driver. The Retail pet-battle path is retained in [`modules/units.lua`](modules/units.lua).

### RC6: party header and related paths

The later report followed this path:

```text
LoadGroupHeader("party")
  -> RegisterStateDriver(party monitor, "raidmonitor", ...)
  -> state-raidmonitor attribute changes
  -> SUF's wrapped OnAttributeChanged script runs
  -> Blizzard CallRestrictedClosure / BuildRestrictedClosure
  -> RestrictedExecution.lua:79 calls loadstring_untainted(...)
```

The audit then covered the other SUF snippets reachable on Forever: raid and split-raid visibility monitors; `initialConfigFunction` on party, raid, split-raid, and raid-pet children; boss/zone child and header wrappers; and the group-child secure click-cast registration. [`modules/units.lua`](modules/units.lua) now uses these paths:

- Blizzard's `SecureGroupHeaderTemplate` and `SecureGroupPetHeaderTemplate` still create group children. SUF leaves `initialConfigFunction` unset on Forever. In the installed client, `SetupUnitButtonConfiguration` calls a restricted closure only when it has a string configuration. SUF initializes new children in ordinary addon Lua outside combat, applies their size, processes the current `unit` attribute, and reruns the stock header update once for spacing. `PLAYER_REGEN_ENABLED` retries children created during combat.
- Party and raid headers use Blizzard's direct `visibility` state driver instead of SUF's wrapped monitor. Party `hideAnyRaid` hides when `raid1` exists; `hideSemiRaid` hides when `raid6` exists. Raid `hideSemiRaid` shows the raid header when `raid6` exists. The direct driver uses Blizzard's built-in show/hide path; disabled or replaced split headers have their driver unregistered.
- Boss buttons use `RegisterUnitWatch(button, false)` for direct existence-based show/hide. Normal `OnShow`/`OnHide` hooks update their containing header's size outside combat, with a retry after combat.
- Group children remain secure unit buttons. Forever registers them through SUF's normal `ClickCastFrames` path; the Retail `ClickCastHeader` snippet path remains on Retail. Custom Clique bindings on group buttons need an in-game check.

The dedicated arena and battleground opponent frames are gated off on Forever, so their Retail-only secure wrappers are not reached. RC6 did not remove party, raid, raid-pet, or boss frames.

## Validation status and remaining checks

All 40 addon Lua files parsed for RC6. The packaged RC6 ZIP was checked against the source, and all 173 installed files matched that ZIP. These checks establish syntax and package consistency; they do **not** establish that the frames work in every game state.

In-game validation remains for party-to-raid changes, split-raid layouts, raid pets, boss visibility and sizing, frame clicks and Clique bindings, and roster changes during combat. A newly created group child may finish SUF initialization after combat; boss header bounds may also catch up then. Test a clean profile and an imported Retail profile. If `RestrictedExecution.lua:79` appears again, report the **full new stack** because its SUF caller may differ from the RC3 and RC6 reports.

## Release, source branches, and bug reports

Use the attached [RC6 release ZIP](https://github.com/Bl4ut0/ShadowedUnitFrames/releases/tag/v4.6.7-Forever-RC6), which contains both addon directories and bundled libraries. GitHub's generated source ZIP lacks the bundled libraries. The fork's `forever-release` branch holds this documentation, the README, issue template, and packaging script. The [upstream draft PR #151](https://github.com/NoSelph/ShadowedUnitFrames/pull/151) uses the code-only `forever` branch so fork-specific release files are not included upstream.

[Report a Forever bug in this fork](https://github.com/Bl4ut0/ShadowedUnitFrames/issues/new?template=bug_report.md). Include the RC version, client build/interface, full Lua stack, steps to reproduce, affected frame, combat state, profile origin, and other enabled addons. Link a new report to [upstream issue #150](https://github.com/NoSelph/ShadowedUnitFrames/issues/150) only when it concerns the broader support or profile question; use this fork's tracker for RC defects.

To build a new candidate from the release branch, start with NoSelph's packaged v4.6.7 ZIP:

```powershell
./scripts/package-forever.ps1 -BaseArchive ./v4.6.7-midnight.zip -OutputArchive ./v4.6.7-Forever-RC6.zip
```
