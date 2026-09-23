# WoW Forever compatibility: RC6 technical notes

This page explains the Forever-specific changes in [Shadowed Unit Frames](README.md), especially the reported party-header error. RC6 is a cumulative candidate: it includes the Forever changes from RC1 through RC6. It targets interface 16001 and starts from NoSelph's packaged v4.6.7 release.

## Why `RestrictedExecution.lua:79` failed

The reported stack ends in `Units:LoadGroupHeader` while creating the party header. The relevant path in [`modules/units.lua`](modules/units.lua) was:

```text
LoadGroupHeader("party")
  -> RegisterStateDriver(party monitor, "raidmonitor", ...)
  -> state-raidmonitor attribute changes
  -> SUF's wrapped OnAttributeChanged script runs
  -> Blizzard CallRestrictedClosure / BuildRestrictedClosure
  -> RestrictedExecution.lua:79 calls loadstring_untainted(...)
```

In the reported Forever client, `loadstring_untainted` is nil at that call, so Blizzard's restricted executor raises “attempt to call a nil value.” The state driver is the trigger; the failure happens when its update reaches SUF's **custom restricted script**. Changing the driver's conditional text alone would leave the compilation problem in place.

An audit found other SUF paths that would reach the same compiler: the `initialConfigFunction` string on party, raid, split-raid, and raid-pet headers; SUF's wrapped raid visibility monitors; the boss/zone child and header wrappers; and the secure click-cast registration inside the group-child snippet. RC6 handles the related paths together so fixing the first party error does not simply expose the next one.

## How RC6 keeps group frames

Forever still uses Blizzard's `SecureGroupHeaderTemplate` and `SecureGroupPetHeaderTemplate` to create party, raid, split-raid, and raid-pet buttons. In the installed Forever client's `SecureGroupHeaders.lua`, `SetupUnitButtonConfiguration` runs `initialConfigFunction` only when it receives a string. On Forever, SUF leaves that attribute unset, so Blizzard creates the children without compiling SUF's snippet.

SUF then finishes each new child in normal addon Lua, **outside combat**:

1. A hook after Blizzard's group-header update finds new `childN` buttons.
2. SUF applies the configured width, height, and scale, creates its unit display, and processes the child's current `unit` attribute.
3. SUF requests one more stock header update so spacing and bounds use the new button size. A guard prevents that update from recursively initializing the same children.
4. If a child appeared while combat prevented initialization, `PLAYER_REGEN_ENABLED` retries it after combat.

The children remain secure unit buttons. SUF does not run its old `secureInitializeUnit` string on Forever; on Retail, the original `initialConfigFunction` and header-driven click-cast path remain. Forever registers group buttons through SUF's normal `ClickCastFrames` path instead. Custom click-cast behavior on those buttons still needs an in-game check.

### Party and raid visibility

The old party and raid monitors used `WrapScript("OnAttributeChanged", ...)` to show or hide a header after a `raidmonitor` state change. Forever instead registers a direct Blizzard `visibility` state driver **on the header**. The installed client's state-driver code handles `state-visibility` with its own `Show()` and `Hide()` calls, without compiling an addon script.

| SUF option | Forever driver behavior |
| --- | --- |
| Hide party in any raid | Hide when `raid1` exists; show otherwise. |
| Hide party only in a larger raid | Hide when `raid6` exists; show otherwise. |
| Show raid only in a larger raid | Show when `raid6` exists; hide otherwise. |

The same raid rule applies to active split-raid headers. SUF removes a driver's registration when its header is disabled or replaced by another raid layout. Other group attributes, such as whether party members appear in raid frames, still use Blizzard's stock header behavior.

### Boss buttons and other secure paths

Boss buttons use Blizzard's direct `RegisterUnitWatch(button, false)` show/hide behavior on Forever. Normal `OnShow` and `OnHide` hooks recalculate the containing header's dimensions outside combat, with another update after combat. This replaces SUF's restricted child and header wrappers. The dedicated arena and battleground opponent frames are disabled on Forever, so their Retail-only wrappers are not reached.

The pet-battle wrapper and vehicle-swap secure path are also gated off for Forever. Retail keeps those implementations. The RC6 audit covers the SUF-authored restricted snippets reachable through these Forever frame paths.

## Other Forever compatibility changes in RC1–RC5

Forever reports a 16xxx interface version despite using the Mainline project ID. SUF therefore selects Forever behavior from the fourth `GetBuildInfo()` result. The early candidates added Classic-compatible range, dispel, combo-point, and master-loot data; guarded secret threat and unit values; and avoided Blizzard frames and specialization APIs missing on Forever. RC5 also prevented imported Retail profiles from re-enabling unsupported units and removed their controls from Forever options. [The README](README.md#cumulative-candidate-history) lists each candidate separately.

The Forever gate currently disables SUF's dedicated arena and battleground opponent frames; vehicle swapping; pet-battle behavior; Retail-only class resource bars and alternate power; several Retail indicators; and empowered-cast events. Player, target, pet, party, raid, raid-pet, and boss frames remain available. These feature gates apply only on Forever; their code and saved settings remain for Retail. [The README](README.md#features-currently-disabled-on-forever) gives the user-facing list and impact.

## Verification and remaining limits

The addon Lua was parsed, and the RC6 release ZIP and installed files were compared. Source inspection confirms the reported call path and that the Forever branches avoid the identified SUF snippets. **The group-header fix still needs in-game validation.** In particular:

- Form a party, grow it into a raid, and test both raid layouts and raid pets.
- Toggle the two party hiding options and the raid size option; check that switching layouts does not leave an old header visible.
- Check boss appearance, disappearance, header spacing, and frame clicks.
- Repeat group changes and boss visibility changes during combat. A newly created group button may be incomplete until combat ends; boss header bounds may also catch up after combat.
- Test ordinary and custom click-casts on party and raid buttons, with and without Clique.

These are test limits, not confirmed failures. If the same `RestrictedExecution.lua:79` error returns, include the **new full stack** so its next caller can be identified.

## Download and report bugs

Install the attached ZIP from the [RC6 release](https://github.com/Bl4ut0/ShadowedUnitFrames/releases/tag/v4.6.7-Forever-RC6). It contains both addon directories and bundled libraries. GitHub's automatically generated source ZIP does not include those libraries.

[Open a Forever bug report](https://github.com/Bl4ut0/ShadowedUnitFrames/issues/new?template=bug_report.md) in this fork. Include the RC version, client build and interface number, the full Lua error and stack, reproduction steps, affected unit frame, combat state, and other enabled addons.

To build a candidate from the fork-only release branch, supply NoSelph's packaged v4.6.7 ZIP:

```powershell
./scripts/package-forever.ps1 -BaseArchive ./v4.6.7-midnight.zip -OutputArchive ./v4.6.7-Forever-RC6.zip
```

The script overlays this branch's tracked source onto the library-complete upstream package. The [upstream draft PR](https://github.com/NoSelph/ShadowedUnitFrames/pull/151) contains the compatibility code; this technical note, release README, issue template, and packaging script stay on the fork's `forever-release` branch.
