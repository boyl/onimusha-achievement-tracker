local I=dofile("reframework/achievement_tracker/i18n.lua")
local t=I.translator("en")
local V={}
-- 宽度来自实际字体测量；UTF-8 字符边界换行不会拆坏中文。
function V.wrap(text,width,measure)
    local lines,line={},""
    for _,code in utf8.codes(text or "") do
        local char=utf8.char(code)
        if char=="\n" then lines[#lines+1]=line;line=""
        elseif line~="" and measure(line..char)>width then lines[#lines+1]=line;line=char
        else line=line..char end
    end
    if line~="" then lines[#lines+1]=line end
    return lines
end
function V.new(model,c)
    local function t(key) return I.translator(c.state.language)(key) end
    local self={metrics={frames=0,panel_frames=0,hud_frames=0},fonts={}}
    for _,size in ipairs({18,22,26}) do
        self.fonts[size]=assert(imgui.load_font("onimusha_tracker_sans.ttf",size,{0x20,0x024F,0x2000,0x206F,0x3000,0x30FF,0x3400,0x9FFF,0xFF00,0xFFEF,0}),t("中文字体未加载：请重新安装 Mod。"))
    end
    local function width() return math.max(100,imgui.get_window_size().x-40) end
    local function text(value,color)
        for _,line in ipairs(V.wrap(value,width(),function(s) return imgui.calc_text_size(s).x end)) do
            if color then imgui.text_colored(line,color) else imgui.text(line) end
        end
    end
    local function check(label,key)
        local changed,value=imgui.checkbox(label,c.config[key])
        if changed then c.change(key,value);c.accept(c.state) end
    end
    local function map_status()
        local s=c.map_state or {status="closed"}
        local labels={disabled=t("地图追踪已关闭。"),unknown=s.note or t("该条目尚未匹配到游戏地图。"),native=s.note,native_object=t("目标已有游戏原生图标，不重复添加圆环。"),non_spatial=s.note,visible=t("金色圆环：当前所选位置。"),offscreen=t("目标在当前视野外；请缩小或移动地图。"),other_area=t("目标地图／楼层：")..(s.label or t("未知")),closed=s.known and t("打开地图定位：")..(s.label or "") or t("正在准备定位信息。"),error=t("地图定位暂停；可在菜单中重新读取。")}
        text((s.multi and s.status=="visible" and (s.books and t("圆环显示当前筛选范围内的杂记；名称标注当前所选位置。") or t("圆环表示当前地图候选地点；名称标注当前所选位置。"))) or labels[s.status] or t("正在定位…"),s.status=="visible" and 0xFF8DDB9D or 0xFFB8BFCC)
        if s.error then text(s.error,0xFFFF8E8E) end
    end
    local function status()
        if c.state.status=="ready" then return true end
        text(c.state.status=="error" and t("读取暂停，请重试。") or t("等待读档／场景切换；暂不显示旧进度。"),0xFFFFC46B)
        if c.state.error then text(c.state.error) end
        if imgui.button(t("重新读取")) then c.retry=true end
        return false
    end
    local function progress(row)
        text(row.name,0xFFFFD28A)
        text(model.label(row),row.unlocked and 0xFF8DDB9D or 0xFFF0EEE8)
        if row.count then imgui.progress_bar(math.max(0,math.min(1,row.count/row.total)),{width(),18},"") end
    end
    local function detail(row)
        progress(row);text(row.description);text(row.source,0xFFB8BFCC)
        if row.id=="ACHIEVEMENT_020" then
            check(t("显示当前地图全部候选地点"),"rescue_all")
        elseif row.id=="ACHIEVEMENT_024" then
            check(t("显示当前地图全部杂记位置"),"books_all")
        end
        if row.unlocked and row.count and row.count<row.total then text(t("成就解锁已保留；下方数量反映当前存档或本次事件。"),0xFFFFC46B) end
        if #row.items>0 then
            check(t("只看缺失／未完成条目"),"missing")
            local entries=model.items(row,c.config.missing)
            if #entries==0 then text(t("当前范围内已全部完成。"),0xFF8DDB9D);return end
            local labels,index={},1
            for i,item in ipairs(entries) do labels[i]=(item.reference and t("[参考地点] ") or item.complete and t("[已完成] ") or t("[缺失] "))..item.name;if item.id==c.config.item then index=i end end
            imgui.set_next_item_width(width())
            local changed,new=imgui.combo("##collection_item",index,labels)
            if changed then c.change("item",entries[new].id);index=new end
            if imgui.button(t("上一项")) then index=((index-2)%#entries)+1;c.change("item",entries[index].id) end
            imgui.same_line()
            if imgui.button(t("下一项")) then index=(index%#entries)+1;c.change("item",entries[index].id) end
            imgui.same_line();imgui.text(index.." / "..#entries)
            local item=entries[index]
            text(item.name,0xFFFFD28A)
            if item.location then
                text(item.location);text(item.detail,0xFFB8BFCC)
                text(t("位置来源：")..item.source..t("（链接见说明文件）"),0xFFB8BFCC)
            end
            if item.map_note and item.map_mode~="native" then text(item.map_note,0xFFB8BFCC) end
            if item.map_targets and #item.map_targets>0 then
                check(t("在游戏地图上追踪所选位置"),"map_tracking")
                local targets=c.map_targets or {}
                if (c.map_unmapped or 0)>0 then text(t("另有 ")..c.map_unmapped..t(" 处配置点位于普通地图未覆盖的场景。"),0xFFB8BFCC) end
                if #targets>1 then
                    local labels,index={},1
                    for i,target in ipairs(targets) do
                        labels[i]=target.name.." · "..target.label.." ("..i.."/"..#targets..")"
                        if target.guid==c.config.location then index=i end
                    end
                    imgui.set_next_item_width(width())
                    local changed,value=imgui.combo("##target_location",index,labels)
                    if changed then c.change("location",targets[value].guid) end
                end
            end
            map_status()
        else text(row.map_note or t("此成就没有可逐项定位的收集清单。"),0xFFB8BFCC) end
    end
    local function panel()
        if c.state.status=="ready" then text(t("成就进度 · ")..c.state.unlocked..t(" / 52 已解锁"),0xFFFFD28A) end
        text(t("选择成就与条目，查看定位方式。Insert 关闭菜单；F8 显示／隐藏小面板。"),0xFFB8BFCC)
        if not status() then return end
        local changed,value=imgui.combo(t("分类"),c.config.group,{t("全部"),t("收集与成长"),t("战斗技巧"),t("剧情与挑战")})
        if changed then c.change("group",value) end
        check(t("只看未解锁成就"),"unfinished")
        imgui.same_line();check(t("显示追踪小面板"),"hud")
        imgui.set_next_item_width(width()-90)
        changed,value=imgui.input_text(t("搜索"),c.search)
        if changed then c.search=value;c.page=1 end
        local rows=c.visible()
        if #rows==0 then
            text(t("没有匹配的成就。"))
            if imgui.button(t("清除筛选")) then c.search="";c.change("group",1);c.change("unfinished",false);c.page=1 end
        else
            local labels,index={},1
            for i,row in ipairs(rows) do labels[i]=row.name.."  "..model.label(row);if row.id==c.config.selected then index=i end end
            imgui.set_next_item_width(width())
            changed,value=imgui.combo("##achievement",index,labels)
            if changed then c.select(rows[value].id) end
            -- 筛选不会悄悄改变追踪对象；明确提供切换入口。
            local selected_visible=false
            for _,row in ipairs(rows) do if row.id==c.config.selected then selected_visible=true end end
            if not selected_visible then
                text(t("当前追踪项不在筛选结果中。"),0xFFFFC46B)
                if imgui.button(t("追踪筛选结果的第一项")) then c.select(rows[1].id) end
            end
        end
        imgui.spacing()
        local row=c.selected()
        if row then detail(row) end
        imgui.spacing()
        if imgui.collapsing_header(t("显示设置与帮助")) then
            local sizes={18,22,26};local ix=c.config.font_size==18 and 1 or c.config.font_size==22 and 2 or 3
            changed,value=imgui.combo(t("字号"),ix,{t("小 (18)"),t("中 (22)"),t("大 (26)")})
            if changed then c.change("font_size",sizes[value]) end
            for _,spec in ipairs({{t("小面板横向位置"),"hud_x"},{t("小面板纵向位置"),"hud_y"}}) do
                changed,value=imgui.slider_int(spec[1],c.config[spec[2]],0,100)
                if changed then c.change(spec[2],value) end
            end
            text(t("支持中文、英文名称或成就编号搜索。鼠标选择，Tab 切换控件；手柄操作尚未验证。"))
            text(t("23 本杂记、36 只狛犬及武具、材料、清水寺百秽的位置来自游戏关卡配置，无需到现场采集坐标。有多个材料地点时，在位置列表中选择。"))
            text(t("救援条目标为参考地点，表示候选遭遇位置，不保证本次出现；商人没有保证刷新的专属位置。"))
            text(t("已有任务图标的任务使用游戏原生追踪；狛犬原生图标可用时不重复画环。普通宝箱图标不区分内容，仍用圆环标明选中的收集目标。"))
            text(t("地图标记跟随缩放和移动；切换条目替换标记。关闭地图或取消地图追踪后隐藏，不改变手动地图标记。"))
            text(t("仅读取游戏数据；设置保存在独立 JSON 中。"))
            if imgui.button(t("立即刷新")) then c.retry=true end
        end
        if c.settings_error then text(c.settings_error,0xFFFF8E8E) end
    end
    local function hud()
        local row=c.selected()
        if c.state.status=="error" then text(t("读取暂停，请重试。"),0xFFFFC46B);return end
        if c.state.status~="ready" or not row then text(t("成就追踪 · 等待读档"),0xFFB8BFCC);return end
        progress(row)
        local item=c.selected_item()
        if item then text(item.name);if item.location then text(item.location,0xFFB8BFCC) end;map_status() else text(row.map_note or t("此成就没有固定收集位置。"),0xFFB8BFCC) end
        text(t("Insert 菜单  ·  F8 隐藏"),0xFF9FA9B8)
    end
    local function window(name,open,flags,size,pos,body,position_condition)
        imgui.set_next_window_size(size,1)
        imgui.set_next_window_pos(pos,position_condition or 1,{0,0})
        local remains=imgui.begin_window(name,open,flags)
        local cjk=imgui.calc_text_size(t("幻魔杂记"))
        local question=imgui.calc_text_size("????")
        self.metrics.window_font={chinese_width=cjk.x,height=cjk.y,fallback_width=question.x,handle=tostring(self.fonts[c.config.font_size])}
        local ok,err=xpcall(body,debug.traceback)
        imgui.end_window()
        if not ok then error(err) end
        return remains
    end
    function self.draw(menu_open)
        local display=imgui.get_display_size()
        local size=c.config.font_size
        imgui.push_font(self.fonts[size])
        local ok,err=xpcall(function()
            self.metrics.frames=self.metrics.frames+1
            self.metrics.screen={width=display.x,height=display.y}
            local measured=imgui.calc_text_size(t("幻魔杂记 鵺兽 蛊饲 15/23"))
            self.metrics.font={size=size,width=measured.x,height=measured.y,loaded=true}
            assert(measured.x>0 and measured.y>0,t("字体测量无效"))
            if menu_open and c.panel then
                local w=math.min(760,display.x-40);local h=math.min(900,display.y-40)
                -- 首次居中；之后允许拖动标题栏，较小窗口使用原生滚动。
                c.panel=window(t("成就与收集追踪###OnimushaTracker"),true,2|256,{w,h},{(display.x-w)/2,(display.y-h)/2},panel,2)
                self.metrics.panel_frames=self.metrics.panel_frames+1
            elseif c.config.hud then
                local w=math.min(size*20,display.x-24)
                local item=c.selected_item();local lines=0
                for _,value in ipairs({item and item.name or "",item and item.location or ""}) do
                    lines=lines+#V.wrap(value,w-40,function(s)return imgui.calc_text_size(s).x end)
                end
                local h=math.min(display.y-24,(lines+8)*(size+5)+35)
                local x=12+(display.x-w-24)*c.config.hud_x/100
                local y=12+(display.y-h-24)*c.config.hud_y/100
                window("###OnimushaTrackerHUD",nil,1|2|4|8|32|256|512|4096|65536|131072,{w,h},{x,y},hud)
                self.metrics.hud_frames=self.metrics.hud_frames+1
            end
            local s=c.map_state
            self.metrics.marker_visible=false
            if not menu_open and c.config.map_tracking and s and s.status=="visible" then
                for _,marker in ipairs(s.markers or {s}) do
                local multi=s.multi
                local s=marker
                local color=0xFF50DFFF
                draw.filled_circle(s.x,s.y,5,color,20)
                draw.outline_circle(s.x,s.y,14,color,40)
                draw.line(s.x-20,s.y,s.x-15,s.y,color)
                draw.line(s.x+15,s.y,s.x+20,s.y,color)
                draw.line(s.x,s.y-20,s.x,s.y-15,color)
                draw.line(s.x,s.y+15,s.x,s.y+20,color)
                if not multi or s.show_label then
                local label=(s.focused and t("查看 · ") or t("追踪 · "))..s.name..(s.complete and t("（已收集）") or "")
                local measured_label=imgui.calc_text_size(label)
                local w=measured_label.x+28;local h=measured_label.y+18
                local x=math.max(s.bounds.minimum.x,math.min(s.x+24,s.bounds.maximum.x-w))
                local y=math.max(s.bounds.minimum.y,math.min(s.y+22,s.bounds.maximum.y-h))
                window("###OnimushaTrackerMapLabel",nil,1|2|4|8|32|256|512|4096|65536|131072,{w,h},{x,y},function()imgui.text_colored(label,color)end)
                end
                end
                self.metrics.marker_visible=true;self.metrics.marker_frames=(self.metrics.marker_frames or 0)+1
            end
        end,debug.traceback)
        imgui.pop_font()
        if not ok then error(err) end
    end
    function self.menu()
        imgui.push_font(self.fonts[c.config.font_size])
        if imgui.button(t("打开成就与收集追踪")) then c.panel=true end
        imgui.pop_font()
    end
    return self
end
return V
