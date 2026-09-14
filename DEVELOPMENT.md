# 开发与发布

源码在 payload/reframework 下。入口组织 runtime、controller、model、view 和地图适配器；language_runtime 负责游戏文字语言契约，i18n 负责中文／英文选择。沿用已验收的模块边界，发布整理不改动运行时行为。

## 测试

Python 3 安装 tests/requirements.txt 后运行：

```powershell
python -m pip install -r tests/requirements.txt
python tests/test_tracker.py
```

纯逻辑与字体检查不能代替游戏内验收。变更运行时 Lua、字体或坐标表后，应重新验证加载存档、真实文字语言切换、地图定位和错误状态，并更新验证记录及文件校验。不得以旧哈希给新代码背书。

## 打包

先提交并推送，通过 git ls-remote 核对 main 的完整 SHA，然后：

```powershell
python scripts/build_release.py --output-dir dist
```

构建器只读取干净工作树 HEAD 中的文件，核对已验收 payload 清单，并生成确定性 ZIP。安装包包含 reframework、必要说明、校验清单和记录 Git 提交的 BUILD_INFO.json；不包含测试、安装器、诊断探针、个人设置、游戏 DLL 或原始资源。

0.4.0 的发布整理仅修改文档和开发工具。15 个运行时文件必须与中文→英文→中文实机验收后的文件校验.json 完全一致。完整测试范围与未验证项目见验证记录.md。

仓库保留静态位置表；其来源为游戏配置的只读解析及运行时交叉核对。原始游戏资源及本机诊断日志不公开分发。字体许可与来源见 THIRD_PARTY_NOTICES.md。


## 0.4.3 输入修复

沿用现有 MVC，hotkeys.lua 只处理键码和按下沿；controller 管理菜单重开；view 显示设置，autorun 读取 REFramework 输入。没有调用游戏输入、剧情或存档写接口。

- 默认不自动弹出主面板；游戏等待或转场时关闭交互面板。再次主动打开 REFramework 菜单时可恢复窗口。
- HUD 快捷键支持点击后直接按键录入（Esc 取消）、禁用、恢复 F8、独立 JSON 持久化；旧配置默认 F8。
- 编辑框架菜单时不触发 HUD 快捷键；初次载入、换绑和关闭菜单后仍按住的按键必须释放后再触发。
- Insert 由 REFramework 控制；此补丁只修复关闭追踪窗口后无法随框架菜单重新打开的问题。框架菜单本身打不开需要另查框架配置/加载情况。
- 新周目开场无法扫描尚未复现，不能列作已修复。需要确认设备、关闭框架菜单是否恢复，并在相同开场存档对比原版与候选行为。
- 自动测试通过：状态转换、换绑、禁用、长按、旧配置、语言与字体、完整既有回归。用户确认重载恢复正常并授权先发布；首关扫描及手柄验证边界见验证记录.md。
