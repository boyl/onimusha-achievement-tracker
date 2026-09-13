# All Achievement Map Markers | 全成就图标指引

版本 0.4.1。支持 Windows Steam 正式版；已验证 build 24769601、REFramework TDB 82。英文说明见 README_EN.md。

显示 52 项成就的解锁状态、适用的进度和逐项清单，在游戏普通地图上用金色圆环标出所选目标。游戏存档、成就状态和玩家手动标记均不修改。

## 自动语言

读取游戏当前的**文字语言设置**，不读取 Windows 地区，也不依据语音语言。简体中文和繁体中文选项均显示本 Mod 的简体中文文本；英文显示英文；日文、法文等其他语言及未知语言默认显示英文。

菜单、成就名称与条件、物品、任务、地图名称和定位提示均支持中英文。物品、任务和地图名称按选定的中文或英文直接读取游戏资源，其他游戏语言不会混入回退的英文界面。游戏实际应用语言更改后，追踪器下一次刷新会更新文本，保留已选成就、位置和偏好。成就名称支持中英文交叉搜索。

## 安装

1. 安装适用于本游戏的 [REFramework](https://www.nexusmods.com/onimushawayofthesword/mods/54)。也可查看作者的 [nightly 发布页](https://github.com/praydog/REFramework-nightly/releases)。需要支持本游戏的版本，并非任意旧版 DLL 都适用。
2. 在 Steam 中右键游戏 → 管理 → 浏览本地文件。
3. 将 Nexus 安装包根目录的 **reframework 文件夹**合并到 OnimushaWotS.exe 所在目录，允许覆盖本 Mod 的同名文件。
4. 启动游戏并加载存档。已在运行时，执行 REFramework 的 Reset scripts 或重启游戏。

Nexus 包无需 PowerShell、Python、单独下载字体或其他收集类 Mod。包内不包含 REFramework 的 dinput8.dll；已有的其他 Mod 文件不会被本包覆盖。Vortex 自动部署尚未验证，请按上述方法手动安装。

开发备份包额外提供安装与卸载脚本；脚本需要 PowerShell 7，可以使用 -GamePath 指定任意 Steam 库。Nexus 包不需要这些脚本。

## 使用

- **Insert**：打开 REFramework 和成就追踪面板；关闭菜单后查看地图圆环。
- **F8**：显示或隐藏追踪小面板。
- 选择成就，再选择条目；有多个材料点时，用位置下拉框选择地点。
- 查看已完成内容时，取消“只看未解锁成就”及“只看缺失／未完成条目”。
- 勾选“在游戏地图上追踪所选位置”，打开对应区域及楼层的普通地图。
- 圆环在视野外时缩小或移动地图。圆环跟随缩放与移动；关闭地图或取消追踪后隐藏。

字号可选 18、22、26，并可调整小面板位置。支持鼠标及键盘 Tab 导航；手柄等效导航未验证。

## 定位覆盖

| 内容 | 行为 |
|---|---|
| 幻魔杂记 | 全部 23 本固定坐标，不用逐区采集坐标 |
| 狛犬 | 全部 36 只的位置与逐只救助状态；已有启用的原生图标时不重复画环 |
| 鬼之武具 | 6 件普通地图位置；两刃【风卷】位于无普通地图的独立任务场景，面板说明使用原生任务追踪 |
| 鬼灯袋及装备强化 | 按各自制作、强化配方列出固定材料拾取点 |
| 能力成长 | 力石、鬼石固定拾取点；在破魔镜中解锁能力 |
| 算你狠 | 清水寺任务完成后生成的特殊百秽实例；本版修正旧版误选地下研究所同类敌人的问题 |
| 居民救援 | 33 个候选遭遇点，完成数量仍按游戏原生的 30 次救援统计 |
| 商人救援 | 洛东 28 个搜索参考点，不能保证刷新商人 |
| 京都奇谭、一树之荫、主线 | 使用原生任务图标，不重复添加任务圆环 |
| 御守、设施及非地点条件 | 指明原生设施或菜单入口；战斗计数、难度通关等显示条件与适用计数 |

普通宝箱图标不说明内容，因此仍为所选杂记、武具或材料画环。材料点可能已经拾取，也可能有掉落、奖励和商店等其他获取途径；不把材料库存当作宝箱完成标志。随机救援受剧情与生成规则影响，候选地点不保证事件出现。

一处棉织物配置点不在普通地图覆盖范围内，涉及防具和两类鬼灯袋；面板明确提示未覆盖数量，不把该点投影到其他地图。

“预置 11 本坐标”是 0.2.0 的限制，已在后续版本移除。现在全部 23 本均随包提供。旧位置缓存保留但不再读取或写入。

## 更新、卸载与排查

更新：用新版 reframework 文件夹合并覆盖，然后重载脚本或重启。偏好保存在 reframework/data/onimusha_achievement_tracker_config.json，安装包不携带个人偏好或存档。

手动卸载：关闭游戏，移除 reframework/autorun/onimusha_achievement_tracker.lua、reframework/achievement_tracker 文件夹和 reframework/fonts/onimusha_tracker_sans.ttf。上述文件夹为本 Mod 专用；保留其他 Mod 及 reframework/data。旧版专用字体 onimusha_tracker_zh.ttc 不再使用，可保留或单独移除。

查看 reframework/data/onimusha_achievement_tracker_status.json 中的 version、status、language、game_language、error、ui_error 和 map。接口不匹配时显示错误，不猜测内存地址。字体报错时检查是否一并复制 fonts 文件夹。若界面空白，确认已加载存档，并查看 REFramework 的 Script Generated 标签。

其他游戏版本、试玩版、非 Steam 运行时、其他分辨率外观及手柄导航不在已验证范围内。没有逐点实地走访所有位置，也没有修改存档来模拟收集；详见验证记录.md。

## 字体与来源

自带字体由 [Noto Sans SC](https://github.com/google/fonts/tree/main/ofl/notosanssc) 制作为 400 字重静态字体，并更名为 Onimusha Tracker Sans。按 SIL Open Font License 1.1 分发；完整版权与许可随包保留在 reframework/achievement_tracker/licenses/NotoSansSC-OFL.txt。无需安装微软雅黑，包内不包含微软字体。

原生位置由本机游戏配置只读提取，并与运行时 GUID、物品 ID、坐标及地图身份核对。包内不分发游戏原始资源、其他 Mod 或资源解析工具。开发使用 [REE-Lib](https://github.com/kagenocookie/RE-Engine-Lib)，接口参考 [REFramework 文档](https://refdocs.praydog.com/api/sdk.html)。

地标摘要参考 [PowerPyx 杂记位置](https://www.powerpyx.com/onimusha-way-of-the-sword-all-genma-notes-locations/) 和 [游民星空攻略](https://www.gamersky.com/handbook/202609/2202897.shtml)；随机救援规则参考 [PowerPyx 成就指南](https://www.powerpyx.com/onimusha-way-of-the-sword-trophy-guide-roadmap/)。

## Source / 源码

https://github.com/boyl/onimusha-achievement-tracker

## 0.4.1 更新

- 修复传送或完成居民救援后读取暂停、圆环消失的问题。
- 救助居民可选择显示当前地图全部候选地点。
- 幻魔杂记可选择显示当前地图全部位置，并遵循缺失筛选。
- 地图光标靠近圆环时显示对应名称，移开恢复当前追踪名称。
- 修正错误状态误显示 0/52 和等待读档的提示。

新选项默认关闭，各自保存；按 Insert 在对应成就中开启。升级覆盖 reframework 文件夹后重启游戏或执行一次 Reset scripts。无需删除原有设置。
