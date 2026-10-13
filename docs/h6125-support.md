# H6125 candidate support

## Request and known context

Issue [#117](https://github.com/teh-hippo/ha-govee-led-ble/issues/117) asks for the H6125 RGBIC strip.  The exact-model Experimental profile is a prerelease candidate awaiting owner qualification.  Installation and promotion follow [CONTRIBUTING.md](../CONTRIBUTING.md).

Public reports show more than one controller generation under this SKU.  A 2020 boot log of hardware 1.00.04 and software 1.04.08 shows the older layout: legacy `0x0b` static colour, `aa a2` segment pages and a one-byte brightness register (the log writes `0xfe` and reads `0x14`).  A 2021 report lists pact 1/1, hardware 1.00.04, software 1.07.01 and fifty ICs, which is the generation this candidate targets.  No identified capture exists for pact 1 on that firmware, and the owner has not yet reported pact, hardware or firmware.

## Research findings

Evidence is Android Govee 7.6.01 app behaviour and public device logs, not official-app BLE captures.  Class names are those of the `com.govee` package.

| Surface | Evidence | Disposition |
| --- | --- | --- |
| Identity | `ihoment_H6125_*` advertisement name; shared advertisement parser supplies pact | Four standard name prefixes; manual addition remains available |
| Admitted generation | `dreamcolorlightv1/pact/Support` registers pact 1/1, 1/2, 10/1 and 10/2; `supportMultiNewMusic4Ble` needs software 1.07.00; `OldDreamColorUtil` routes software 1.03.01 and later to the DreamColor screens | Pact 1 (codes 1 and 2 share the screen), software 1.07.00 or newer, three-part hardware 1.00.03 to 1.xx.xx; everything else is power only |
| Brightness register | `Support.getBrightnessRange` with `NumUtil.calculateProgress` and `calculatePercent`; `BrightnessController`; the boot log writes `0xfe` and reads `0x14` | Register range 6 to 254 below hardware 1.00.04 and 20 to 254 from 1.00.04, written through the outbound transform |
| Static colour, Kelvin, segments | `SubModeColorV2`, `BulbStringColorControllerV2`, `BulbGroupColorV2`; same classes as the H6102 DreamColor route | Shared H617A command frames, shared fifteen-segment pages, `aa 05 01` mode query |
| Scenes | Exact-SKU catalogue; `SubModeScenes` selector and shared A3 scene bodies | 240 scenes through the shared native route; no authored scene rows |
| Music selector | `SubModeMusicV2` writes submode `0x11` with effects `0x10` to `0x13` and per-effect settings | Wire layout in `h6125_wire_write.ksy` and `h6125_status_reply.ksy` |
| Music companions | RGBIC `MusicMode.d` producers shared with H6102; the Govee app lists fifty ICs; `MultipleController4Music` uploads the companion, then the selector follows | Shared `h6099_music_parameters` encoder with `physical_ic_count=50`; upload before selector with acknowledgement |
| Type04 effects | `MultipleDiyController` command type 02 over A1; `Diy.e` roster | `a1_diy_selector=0xfe`, shared Type04 body, H6102 family roster |

## Candidate support scope

Qualified devices expose power, brightness, RGB, Kelvin, fifteen segment colours and brightness, 240 scenes, eleven music modes with their companions, and Effect Studio Single and Multi effects.  Other generations keep power and identity only.

Painted, Advanced and Workshop effects, authored scene editing, the legacy `0x0b` layout, `aa a2` pages and pact 10 controllers remain unavailable until identified captures exist.  Catalogue data does not prove transport.

## Model-specific changes and owner checks

| Obligation | Owner | Runnable evidence |
| --- | --- | --- |
| Pact and revision gate, register range | `const.device_profile`, `coordinator._resolve_device_profile` | `tests/test_const.py`, `tests/test_coordinator.py` |
| Register and music wire frames | `h6125_wire_write.ksy`, `generated_protocol_adapter.h6125_outbound_transform` | `tests/test_h6125_capabilities.py`, `tests/test_kaitai_protocol.py` |
| Readback | `h6125_status_reply.ksy`, `music_protocol`, coordinator brightness decode | `tests/test_h6125_capabilities.py`, `tests/test_coordinator.py` |
| Type04 over A1 | `ModelProfile.a1_diy_selector`, `effect_commands`, `transport.fragment_a1_02` | `tests/test_h6125_capabilities.py`, `tests/test_transport.py` |

The owner should install the prerelease, restart Home Assistant and export diagnostics after each step.

1. **Identity**: complete setup and report the BLE prefix, software, hardware and pact shown in diagnostics.  Stop if the profile stays power only.
2. **Power and brightness**: toggle power, then set 1%, 10%, 50% and 100%.  Record the visible level and whether readback agrees.  A rejected `aa 04` frame means the register range assumption is wrong.
3. **Colour**: set red, green, blue, then 2700 K, 5000 K and 6500 K.
4. **Segments**: set segments 1, 8 and 15 to distinct colours and levels, then refresh.  `aa a2` frames identify an older generation.
5. **Scenes**: apply one selector-only scene, one type 1 scene and one type 2 scene.
6. **Music**: select each mode, change Rhythm style and a fixed colour, and report whether the strip follows sound.
7. **Effects**: apply one Single and one Multi effect from Effect Studio.
8. **Handoff and restoration**: control the strip in the Govee app, close it, command it from Home Assistant, then restore the original state.

Tests establish software boundaries, not hardware compatibility.
