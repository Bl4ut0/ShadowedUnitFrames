# Shadowed Unit Frames for WoW Forever

This branch adapts NoSelph's Midnight version of SUF to the WoW Forever 1.60 client. Forever reports the Mainline project ID and exposes modern restricted UI APIs, while using Classic spell and class behavior. The port therefore keeps NoSelph's secret-safe frame and aura work and changes gameplay data only when the client reports a 16xxx interface.

The current candidate targets interface 16001. It uses Classic range, dispel, and combo-point data and guards threat values that become secret in restricted content. A restricted threat indicator may remain hidden because addon Lua cannot compare a secret threat state.

## Client-specific features

The 16xxx client gate disables Retail arena and battleground-opponent unit frames; vehicle swapping; pet-battle, arena-spec, phasing, quest-boss, and dungeon-role indicators; empowered-cast events; and Retail-only class resource bars. Their code and saved profile values remain available on Retail. Forever retains player, target, pet, party, raid, boss, and other supported frames, including the Classic shaman totem bar and druid mana bar. Unsupported resource tags are hidden from the tag picker.

The gate applies when frames and modules are registered, when units are loaded, and in unlock/test mode. Imported Retail profiles cannot reactivate unsupported frames through zone visibility settings. Anchors pointing at those frames resolve to the screen on Forever without changing their saved positions. The options pages omit unsupported controls.

The prior loadstring_untainted error came from the pet-battle state driver and that driver is disabled on Forever. Party and raid headers still use secure group code; test those in game because their behavior cannot be verified by source inspection alone.

## Install for testing

Use the release asset ZIP, which contains `ShadowedUnitFrames` and `ShadowedUF_Options` with bundled libraries. Extract both directories into the Forever client's `Interface/AddOns` directory. The GitHub-generated source ZIP does not contain bundled libraries.

Test with a clean SUF profile first. Check player and target frames, party and raid frames, health and power bars, names and percentages, buffs and debuffs, cast bars, clicks, configuration, and combat transitions. Report the exact error text and which unit frame was visible when it occurred.

## Package a candidate

From the repository root, with NoSelph's packaged v4.6.7 ZIP downloaded:

```powershell
./scripts/package-forever.ps1 -BaseArchive ./v4.6.7-midnight.zip -OutputArchive ./v4.6.7-Forever-RC5.zip
```

The script overlays the tracked source from this branch onto NoSelph's library-complete release. The source and options addons are packaged as two top-level directories.
