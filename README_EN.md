# All Achievement Map Markers | 全成就图标指引

Version 0.4.1. Windows Steam full game. Tested with build 24769601 and REFramework TDB 82. Chinese instructions: README.md.

Track unlock flags, available achievement counters and individual collection entries across all 52 achievements. Select a target to place a gold ring on the regular game map. The mod reads game data without changing saves, achievements or your manual map markers.

## Language

The tracker follows the game's **text language setting**, not Windows settings or voice language. Both Chinese options use the mod's Simplified Chinese interface. English uses English. Every other language, including Japanese and French, defaults to English.

Menus, achievement names and descriptions, items, quests, map labels and tracking notes are localized. Native names are read explicitly in Chinese or English, so unsupported game languages do not leak into the English fallback. Once the game applies a language change, the next tracker refresh updates the text while retaining your selection and preferences. Search supports both Chinese and English achievement names.

## Requirements and installation

1. Install a build of [REFramework for this game](https://www.nexusmods.com/onimushawayofthesword/mods/54). The author's [nightly releases](https://github.com/praydog/REFramework-nightly/releases) are another source. Use a build that supports this game, not an arbitrary older DLL.
2. In Steam, right-click the game → Manage → Browse local files.
3. Merge the **reframework** folder at the root of the Nexus archive into the folder containing **OnimushaWotS.exe**. Allow replacement of this mod's matching files.
4. Launch the game and load a save. If it is already running, use REFramework's **Reset scripts** or restart the game.

The Nexus archive needs no PowerShell, Python, separately installed fonts or other collection mods. It does not include dinput8.dll or overwrite other mods. Vortex deployment has not been verified; use manual installation above. The separate development backup includes optional PowerShell 7 installation scripts; they are not needed for the Nexus package.

## Controls

- **Insert** opens REFramework and the tracker. Close this menu to see the map ring.
- **F8** toggles the small HUD.
- Pick an achievement, then an entry. For materials with several locations, use the location dropdown.
- Disable the locked-only and missing-only filters to inspect completed entries.
- Enable map tracking and open the target region and floor. Zoom out or pan if the target is offscreen.
- The ring follows zoom and pan. Closing the map or disabling tracking hides it.

Font sizes: 18, 22 or 26. HUD position is adjustable. Mouse and keyboard Tab navigation are available; controller navigation is unverified.

## Coverage

- All **23 Genma Notes** have bundled coordinates; no visits are needed to collect location data.
- All **36 dogs** have individual rescue status and locations. An enabled matching native dog icon suppresses the extra ring.
- Six weapon entries have regular map locations. **Wind-Whipper** is in a separate quest scene without a regular map; use the native quest tracker as explained in the panel.
- Hozuki pouches and equipment show fixed material pickups matched to their own crafting and upgrade recipes. Abilities offer Power Stone and Oni Stone pickup references.
- **Serves You Right** points to the special Byakue encounter at Kiyomizu-dera. This version fixes the previous selection of an enemy of the same type in the Underground Laboratory.
- Citizen rescues have **33 candidate locations** while progress retains the native **30-rescue** requirement. Merchant rescue offers **28 search references** in Eastern Kyoto, not guaranteed merchant spawns.
- Quests with native quest icons use those icons. Amulets and crafting explain the native facility or menu. Combat, difficulty and event achievements show conditions or available counters rather than invented locations.

Generic chest icons do not identify their contents, so selected notes, weapons and materials still receive a ring. Material locations may already be looted and do not cover every drop, shop or quest reward. Inventory amounts are not treated as chest completion flags. Random rescues depend on story progress and spawn rules; visiting a ring does not guarantee an encounter.

One cloth pickup is outside regular-map coverage and affects armor and two pouch material lists. The panel reports unmapped locations instead of drawing them on the wrong map.

The old “11 preloaded note coordinates” limit belonged to version 0.2.0. All 23 are now bundled. The old location-cache file is retained but no longer read or written.

## Updating, removal and troubleshooting

Update by merging the new reframework folder, then reset scripts or restart. Preferences are stored in reframework/data/onimusha_achievement_tracker_config.json. Downloads never contain the author's personal settings or save data.

To uninstall manually, close the game and remove reframework/autorun/onimusha_achievement_tracker.lua, this mod's dedicated reframework/achievement_tracker folder, and reframework/fonts/onimusha_tracker_sans.ttf. Preserve other mods and reframework/data. The old onimusha_tracker_zh.ttc font is unused and can be kept or removed separately.

Diagnostics: reframework/data/onimusha_achievement_tracker_status.json records version, status, language, game_language, error, ui_error and map. A mismatched game interface pauses reading with an error. For a font error, ensure the fonts folder was copied too. Load a save before checking progress; look under REFramework's Script Generated tab if the panel is hidden.

Other game builds, the demo, non-Steam runtimes, appearance at other resolutions, and controller navigation have not been verified. Locations have not all been visited individually. No save edits were used to simulate collection.

## Font and credits

The included **Onimusha Tracker Sans** is a renamed, static weight-400 instance of [Noto Sans SC](https://github.com/google/fonts/tree/main/ofl/notosanssc). It is distributed under the **SIL Open Font License 1.1**, with the original copyright and license in reframework/achievement_tracker/licenses/NotoSansSC-OFL.txt. No Microsoft font or Windows Chinese font installation is required.

Locations are derived from game configuration and checked against native GUIDs, item IDs, coordinates and map identity. The archive contains no original game resource files, other mods, or extraction-tool binaries. Development used [REE-Lib](https://github.com/kagenocookie/RE-Engine-Lib) and the [REFramework API documentation](https://refdocs.praydog.com/api/sdk.html).

Landmark summaries reference [PowerPyx](https://www.powerpyx.com/onimusha-way-of-the-sword-all-genma-notes-locations/) and [Gamersky](https://www.gamersky.com/handbook/202609/2202897.shtml). Rescue behavior references the [PowerPyx achievement guide](https://www.powerpyx.com/onimusha-way-of-the-sword-trophy-guide-roadmap/).

## Source / 源码

https://github.com/boyl/onimusha-achievement-tracker

## 0.4.1 changes

- Fixed tracker reads pausing and map rings disappearing after fast travel or resident rescue events.
- Added optional all-location rings for resident rescue candidates and Genma books on the current map and floor. Book markers follow the missing-items filter.
- Hover the game map cursor near a ring to inspect its name; moving away restores the selected target label.
- Fixed misleading 0/52 and waiting-for-save messages after read errors.

Both options default to off and are saved independently. Press Insert to enable them under the relevant achievement. To update, overwrite the reframework folder and restart the game or use Reset scripts once. Keep your existing settings.
