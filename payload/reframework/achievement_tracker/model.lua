local I=dofile("reframework/achievement_tracker/i18n.lua")
local t=I.translator("en")
-- 纯 Lua 数据模型：进度始终来自本次快照，不累加、不写入存档。
local M={}
function M.group(items, source)
    local count,seen=0,{}
    for _,item in ipairs(items) do
        assert(not seen[item.id],t("重复收集项：")..item.id)
        seen[item.id]=true
        if item.complete then count=count+1 end
    end
    return {count=count,total=#items,items=items,source=source}
end
function M.build(catalog, raw)
    local language=raw.language or "en";local t=I.translator(language)
    local state={language=language,status=raw.status,rows={},by_id={},unlocked=0,error=raw.error}
    if raw.status~="ready" then return state end
    for i,entry in ipairs(catalog) do
        local value=assert(raw.achievements[i],t("缺少成就读取结果"))
        assert(type(value.unlocked)=="boolean",t("未知解锁状态"))
        local row={id=entry.id,index=i,language=language,name=language=="zh" and entry.name or entry.english_name,description=language=="zh" and entry.description or entry.english_description,chinese_name=entry.name,english_name=entry.english_name,
            group=entry.group,unlocked=value.unlocked,items={},source=t("条件型成就；游戏没有提供累计数量。")}
        if row.unlocked then state.unlocked=state.unlocked+1 end
        if i>=37 then row.map_note=t("此成就记录战斗操作或事件条件，没有固定收集位置。")
        elseif i==1 then row.map_note=t("请选择下方具体成就查看定位方式。")
        elseif i>=2 and i<=14 then row.map_note=t("剧情首领请使用游戏主线任务图标前往。")
        elseif i==25 then row.map_note=t("此成就要求指定难度通关，沿游戏主线任务推进。")
        elseif i==26 or i==27 then row.map_note=t("在游戏的首领再战菜单完成挑战，没有额外地图收集点。")
        elseif i==28 or i==29 then row.map_note=t("在破魔镜的能力菜单解锁；使用游戏现有破魔镜图标。")
        elseif i==30 or i==31 then row.map_note=t("在破魔镜中强化装备；使用游戏现有破魔镜图标。")
        elseif i==35 or i==36 then row.map_note=t("前往御守设施制作、强化；使用游戏现有设施图标。奉纳点来自救助狛犬，可在狛犬成就中逐只定位。")
        elseif i==20 or i==21 then row.map_note=t("救援目标取决于随机遭遇和任务阶段；地图提供候选事件的搜索范围。")
        elseif i==19 then row.map_note=t("目标在清水寺；取消只看缺失条目，可查看已解锁挑战的位置。") end
        local specific=raw.groups[i]
        if specific then
            assert(specific.count>=0 and specific.total>0,t("无效收集统计"))
            row.count,row.total,row.items,row.source=specific.count,specific.total,specific.items or {},specific.source
        elseif value.count>=0 and value.target>0 then
            row.count,row.total=value.count,value.target
            row.single_event=i>=50
            row.source=row.single_event and t("本次事件计数，可归零；需一次达成，不能累计。") or t("游戏原生成就计数。")
        end
        state.rows[#state.rows+1]=row;state.by_id[row.id]=row
    end
    local all=state.rows[1]
    all.count=state.unlocked-(all.unlocked and 1 or 0);all.total=#catalog-1
    all.source=t("其余成就的游戏内解锁标志。")
    return state
end
function M.label(row)
    local t=I.translator(row.language)
    local flag=row.unlocked and t("已解锁") or t("未解锁")
    if row.count then return flag.." · "..(row.single_event and t("本次 ") or "")..row.count.."/"..row.total end
    return flag..t(" · 条件达成型")
end
function M.filter(state, group, unfinished, search)
    local found={};search=(search or ""):lower()
    for _,row in ipairs(state.rows) do
        local hay=(row.name.." "..row.description.." "..row.english_name.." "..row.chinese_name.." "..row.id):lower()
        if (group==1 or row.group==group) and (not unfinished or not row.unlocked) and (search=="" or hay:find(search,1,true)) then found[#found+1]=row end
    end
    return found
end
function M.items(row, missing)
    local items={}
    for _,item in ipairs(row and row.items or {}) do if not missing or not item.complete then items[#items+1]=item end end
    return items
end
function M.find_item(row,id)
    for _,item in ipairs(row and row.items or {}) do if item.id==id then return item end end
end
return M
