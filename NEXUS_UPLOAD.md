# Nexus Mods 上传说明 · 0.4.0

推荐上传文件：OnimushaAchievementTracker-0.4.0-Nexus.zip。该包根目录直接包含 reframework，玩家将其合并到 OnimushaWotS.exe 所在目录即可。不要上传开发备份包、work 目录、游戏 DLL、存档或诊断 JSON。

## 页面设置

- 游戏分区：Onimusha: Way of the Sword（onimushawayofthesword）。
- 页面标题：All Achievement Map Markers | 全成就图标指引。
- 版本：0.4.0。
- 文件类型：Main Files。
- 标签：User Interface、Quality of Life、Utilities for Players；按 Nexus 当前生成式 AI 规则勾选 AI-Generated Content（代码／界面／翻译）及 AI Media（页面文案）。
- 语言：English、Chinese；如页面允许区分，则标注 Simplified Chinese。繁体中文游戏设置也使用本 Mod 简体中文界面。
- 前置依赖：适用于本游戏的 REFramework。可关联 https://www.nexusmods.com/onimushawayofthesword/mods/54 ，并保留 https://github.com/praydog/REFramework-nightly/releases 作为作者更新入口。
- 兼容范围：Windows Steam 正式版，已验证 build 24769601、TDB 82。不要标为所有旧版本、试玩版或所有平台兼容。
- 安装方式：Manual download。Vortex 自动部署未验证，不标注已支持。
- 截图：建议使用当前 0.4.0 的中文面板、英文面板及地图圆环各一张，避免使用旧版地图名称错误的截图。

Nexus 官方建议将必要的其他 Mod 加入 Requirements，让下载者能看到依赖提示：[作者最佳实践](https://help.nexusmods.com/article/136-best-practices-for-mod-authors)。

## 可复制的英文摘要

Track all 52 achievements, missing collectibles and recipe material locations with a gold ring on the game map. Follows the game's text language: Chinese or English, with English fallback for all other languages. Read-only game access; requires REFramework.

## 可复制的中文摘要

显示全部 52 项成就的解锁状态、适用计数和收集清单，用地图金色圆环定位所选目标及配方材料。跟随游戏文字语言显示中文或英文，其他语言默认英文。仅读取游戏数据，需要 REFramework。

## 可复制的英文正文

All Achievement Map Markers adds an in-game achievement panel and a small HUD, plus a gold tracking ring on the regular game map.

Features:
- Unlock flags and available counters for all 52 achievements.
- Bundled coordinates for all 23 Genma Notes and all 36 dogs.
- Weapon, Hozuki pouch, equipment-upgrade and ability-material location references.
- The special Byakue encounter at Kiyomizu-dera and possible rescue encounter locations.
- Native quest icons are reused instead of duplicated. A matching active native dog icon suppresses the extra ring.
- Map rings follow zoom and pan and preserve your own map markers.
- Chinese and English UI, names, descriptions and map labels. Both Chinese game options use Simplified Chinese; all other languages fall back to English. The tracker follows text language, independently of voice language.
- No save edits, achievement unlocking, item spawning or gameplay-state writes.

Installation:
1. Install a REFramework build compatible with Onimusha: Way of the Sword.
2. Open the game folder containing OnimushaWotS.exe.
3. Merge the archive's reframework folder into that folder.
4. Load a save. If the game is already running, reset REFramework scripts or restart it.

No extra font download, PowerShell or Python is needed. The archive includes an OFL-licensed font and its license. REFramework itself is not bundled.

Controls:
Insert opens the panel. F8 toggles the HUD. Select an achievement and an entry; use the location dropdown for materials with multiple spots. Enable map tracking, close the Insert menu, then open the target area and floor.

Limits:
Material pickups may already be looted, and drops, shops and quest rewards are additional sources. Rescue locations are possible encounters, not guaranteed spawns or a list of 30 fixed citizens. Wind-Whipper is in a quest scene with no regular map and uses native quest tracking. One cloth pickup is outside regular-map coverage; the panel reports that limitation. Combat counters, difficulty requirements and menu challenges have no invented map positions.

Tested on Windows Steam full-game build 24769601 with TDB 82. Other builds, the demo, Vortex deployment and controller navigation are unverified. Not every location has been visited individually.

Credits:
REFramework by praydog. Onimusha Tracker Sans is a renamed static instance of Noto Sans SC, distributed under SIL OFL 1.1 with its original copyright and license. Game configuration was read using REE-Lib; no game resource files or extraction tools are bundled. Guide credits and troubleshooting instructions are in README_EN.md.

## 可复制的中文正文

本 Mod 提供游戏内成就面板、小面板和普通地图上的金色追踪圆环。支持全部 52 项成就的解锁标志和适用计数，收录全部 23 本幻魔杂记、36 只狛犬，以及武具、鬼灯袋配方、装备与能力成长材料的固定位置。清水寺百秽和随机救援提供对应实例或候选地点。

跟随游戏“文字语言”显示中英文：简体及繁体中文设置均使用本 Mod 简体中文界面，其他语言默认英文；不受语音语言影响。切换后会随下一次刷新更新，保留选择与偏好。

需要适用于本游戏的 REFramework。将安装包根目录的 reframework 文件夹合并到 OnimushaWotS.exe 所在目录，然后加载存档。正在运行时可 Reset scripts 或重启。自带可分发的开源字体，无需 PowerShell、Python 或额外安装中文字体。

Insert 打开面板，F8 控制小面板。选择成就、条目与材料地点，启用地图追踪，关闭 Insert 菜单后在对应区域和楼层查看圆环。任务已有原生图标时不重复标注；狛犬原生图标启用时也不重复画环。圆环随地图缩放和移动，不改变玩家手动标记。

材料点可能已被拾取，且不涵盖掉落、商店或奖励等所有途径。随机救援点不保证事件或商人出现。两刃【风卷】位于没有普通地图的独立任务场景；一处棉织物拾取点也不在普通地图覆盖范围，界面会说明。战斗计数和难度通关等条件不会生成虚构位置。

已验证 Windows Steam 正式版 build 24769601、TDB 82。其他版本、试玩版、Vortex 和手柄导航未验证，也未逐点走访全部位置。Mod 仅读取游戏数据，不修改存档、成就、物品或任务状态。

## 权限与内容检查

代码的修改、转载和署名规则由你在 Nexus 页面决定；不要将第三方字体声明为自己独占的作品。自带字体始终遵循 OFL 1.1，应保留其版权、许可及修改说明。页面若设置“禁止转载”等限制，请明确该限制不覆盖 OFL 字体已有的授权。

包内不含微软雅黑、dinput8.dll、其他 Mod、游戏原始资源、账号信息或个人偏好。Nexus 要求上传者拥有必要的分发权限；仅署名不能替代授权：[文件提交规则](https://help.nexusmods.com/article/28-file-submission-guidelines)。本包字体授权及出处见 THIRD_PARTY_NOTICES.md。

发布顺序：先提交并推送源码、核对远端 main 与本地 HEAD，再从该提交构建 Nexus 主文件。归档中的 BUILD_INFO.json 记录来源提交。上传后核对页面上的文件名、版本、Requirements 和安装步骤；实际发布地址及核验结果由发布记录另行保存。

参考同游戏发布页：[Onimusha FOV](https://www.nexusmods.com/onimushawayofthesword/mods/35)、[Auto Absorb Souls](https://www.nexusmods.com/onimushawayofthesword/mods/65)。安装说明采用根目录合并 reframework 的方式，前置依赖在 Requirements 中单独关联。

## 开发说明 / Development disclosure

代码和中英文说明由 Codex 辅助生成，经过自动回归及用户实机验收；验证范围与限制已列明。/ Code and bilingual documentation were generated with Codex and checked with automated regression tests and user in-game validation. The tested scope and remaining limitations are documented above.
