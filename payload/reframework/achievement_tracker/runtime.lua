local I=dofile("reframework/achievement_tracker/i18n.lua")
local t=I.translator("en")
-- 运行时边界：只调用已验证的读取接口；只向上层返回 Lua 值。
local R={}
local type_cache={}
local function td(name)
    if not type_cache[name] then type_cache[name]=assert(sdk.find_type_definition(name),t("缺少类型：")..name) end
    return type_cache[name]
end
local function enum(name,key) return assert(td(name):get_field(key),t("缺少枚举：")..key):get_data(nil) end
local function singleton(name) return assert(sdk.get_managed_singleton(name),t("对象未就绪：")..name) end
local function list_each(list,limit,fn)
    local n=list:get_field("_size");assert(n>=0 and n<=limit,t("列表超出已验证范围"))
    local array=list:get_field("_items")
    for i=0,n-1 do fn(array:get_element(i),i) end
end
local function array_each(array,limit,fn)
    local n=array:get_size();assert(n<=limit,t("资源超出已验证范围"))
    for i=0,n-1 do fn(array:get_element(i),i) end
end
function R.stable()
    local flow=sdk.get_managed_singleton("app.GameFlowManager")
    return flow~=nil and flow:call("get_IsIngameStable")==true
end
function R.new(model,catalog,hints,language)
    assert(language,"Language adapter required")
    local function t(key) return I.translator(language.locale)(key) end
    local function message(guid) return language.message(guid) end
    local function item_name(_,id) return language.item_name(id) end
    assert(sdk.get_tdb_version()==82,t("此版本仅验证过 TDB 82，请更新适配器。"))
    local self={}
    local positions=dofile("reframework/achievement_tracker/location_catalog.lua")
    local item_keys={}
    for _,f in ipairs(td("app.ItemEnum.ID_Fixed"):get_fields()) do if f:is_static() then item_keys[f:get_data(nil)]=f:get_name() end end
    local function item_targets(ids,ih)
        local targets,seen={},{}
        for _,id in ipairs(ids) do
            for _,guid in ipairs(positions.items[item_keys[id]] or {}) do
                if not seen[guid] then targets[#targets+1]={guid=guid,name=item_name(ih,id)};seen[guid]=true end
            end
        end
        return targets
    end
    local achievement_ids={}
    for i,entry in ipairs(catalog) do
        achievement_ids[i]={fixed=enum("app.AchievementEnum.ID_Fixed",entry.id),ordinal=enum("app.AchievementEnum.ID",entry.id)}
    end
    -- 对高频公共接口核对返回类型，未知版本不猜地址。
    for _,spec in ipairs({{"getAchievementCount","System.Int32"},{"getAchievementTargetCount","System.Int32"},{"getAchievementUnlockFlag","System.Boolean"}}) do
        local m=assert(td("app.SaveDataHelper_Achievement"):get_method(spec[1]))
        assert(m:get_return_type():get_full_name()==spec[2] and not m:is_static(),t("成就接口契约不符"))
    end
    function self.read()
        language.refresh()
        if not R.stable() then return {status="waiting",language=language.locale} end
        local helper=singleton("app.SaveDataManager"):get_field("_Helper")
        local ah,ih=helper:get_field("_Achievement"),helper:get_field("_Item")
        local settings=singleton("app.VariousDataManager"):get_field("_Setting")
        local raw={status="ready",language=language.locale,achievements={},groups={}}
        for i,ids in ipairs(achievement_ids) do
            raw.achievements[i]={count=ah:call("getAchievementCount",ids.fixed),target=ah:call("getAchievementTargetCount",ids.fixed),unlocked=ah:call("getAchievementUnlockFlag",ids.ordinal)}
        end
        local boss_book=td("app.GUI031200"):get_method("getEmBookDataByBookId"):call(nil,enum("app.EmBookID.ID_Fixed","EmBook_010_00"))
        local boss_name=message(boss_book:get_field("_EmName"))
        raw.groups[19]=model.group({{id="boss:kiyomizu",name=boss_name,complete=raw.achievements[19].unlocked,
            map_targets={{guid=positions.boss,name=boss_name}}}},t("敌人的配置出生位置；完成标志按成就解锁状态，不代表当前周目敌人是否仍在。"))
        local rescues={};local rescue_seen={}
        for i,entry in ipairs(positions.rescues) do
            if not rescue_seen[entry.guid] then
            rescue_seen[entry.guid]=true
            rescues[#rescues+1]={id="rescue:"..entry.key,name=t("救援遭遇点 ")..i,complete=false,reference=true,
                map_targets={{guid=entry.guid,name=t("救援遭遇点 ")..i}},map_note=t("这是可能发生救援的配置位置，不保证本次出现。触发受剧情、随机生成和场景状态影响；完成数量以游戏原生计数为准。")}
            end
        end
        raw.groups[20]={count=raw.achievements[20].count,total=raw.achievements[20].target,items=rescues,source=t("游戏原生救援计数；下方为候选遭遇地点，不是 30 名固定居民的完成清单。")}
        local merchant_search={};local merchant_seen={}
        for _,entry in ipairs(positions.rescues) do
            if entry.key:match("^NpcRes100_") and not merchant_seen[entry.guid] then
                merchant_seen[entry.guid]=true
                merchant_search[#merchant_search+1]={id="merchant-search:"..entry.key,name=t("商人搜寻参考点 ")..(#merchant_search+1),complete=false,reference=true,
                    map_targets={{guid=entry.guid,name=t("救援搜索范围")}},map_note=t("商人属于随机救援事件，没有保证出现的专属坐标。这里标注洛东救援事件的搜索范围，也会遇到普通居民；请以现场触发为准。")}
            end
        end
        raw.groups[21]={count=raw.achievements[21].unlocked and 1 or 0,total=1,items=merchant_search,source=t("成就解锁状态；地图地点为随机救援的搜索参考，不代表必定出现商人。")}
        local books={}
        for i=0,31 do
            local key=string.format("EmBook_%03d_00",i)
            local row=td("app.GUI031200"):get_method("getEmBookDataByBookId"):call(nil,enum("app.EmBookID.ID_Fixed",key))
            if row then
                local id=row:get_field("_Open1st_ItemID"):get_field("_Value")
                local hint=hints[key]
                books[#books+1]={id=key,item_id=id,name=t("幻魔杂记【")..message(row:get_field("_EmName"))..t("】"),complete=ih:call("getItemCountOfId",id)>0,
                    location=hint and t(hint.location),detail=hint and t(hint.detail),source=hint and t(hint.source),
                    map_targets={{guid=assert(positions.books[key]),name=t("幻魔杂记【")..message(row:get_field("_EmName"))..t("】")}}}
            end
        end
        raw.groups[24]=model.group(books,t("当前存档实际持有的幻魔杂记。"))
        local dogs={};local dogkeys={}
        for key in pairs(positions.dogs) do dogkeys[#dogkeys+1]=key end;table.sort(dogkeys)
        for _,key in ipairs(dogkeys) do
            local stage,num=key:match("^STAGE(%d+)_(%d+)$")
            local stage_name=message(singleton("app.EnvironmentManager"):call("getStageNameID",enum("app.EnvDef.StageID","Stage"..stage)))
            local name=stage_name..t(" · 狛犬 ")..(tonumber(num)+1)
            dogs[#dogs+1]={id="dog:"..key,name=name,complete=helper:get_field("_Mystery"):call("isReleased(app.MysteryDef.SUB_ID_Fixed)",enum("app.MysteryDef.SUB_ID_Fixed",key)),map_targets={{guid=positions.dogs[key],name=name}},native_object=true}
        end
        -- 清单来自随包静态配置；完成状态直接读取存档，不依赖转场时重建的 MysteryManager 数组。
        raw.groups[23]=model.group(dogs,t("当前存档逐只救助状态；编号按游戏配置顺序，不是攻略编号。"))
        raw.groups[22]={count=math.min(raw.groups[23].count,1),total=1,items=dogs,source=raw.groups[23].source}
        local sk=helper:get_field("_SkillTree")
        local groups={}
        for index,key in ipairs({"_CacheBasicSkillNodeIdList","_CacheOniSkillNodeIdList"}) do
            local list=sk:get_field(key);local n=list:call("get_Count");assert(n<=128)
            local count=0
            for i=0,n-1 do if sk:call("isActivated(System.Guid)",list:call("get_Item",i)) then count=count+1 end end
            groups[index]={id=key,name=index==1 and t("基本能力") or t("特殊能力"),complete=count==n and n>0,count=count,total=n}
        end
        local skill_items={}
        for _,g in ipairs(groups) do
            skill_items[#skill_items+1]={id=g.id,name=g.name.." "..g.count.."/"..g.total,complete=g.complete,
                map_targets=item_targets({enum("app.ItemEnum.ID_Fixed","PLGROWTH_002"),enum("app.ItemEnum.ID_Fixed","PLGROWTH_003")},ih),
                map_note=t("能力仍在破魔镜中解锁、强化。下方提供力石、鬼石的固定拾取点；可能包含已拾取地点，也可能从其他奖励获得。")}
        end
        raw.groups[29]={count=groups[1].count+groups[2].count,total=groups[1].total+groups[2].total,items=skill_items,source=t("游戏要求的能力节点；基本能力与特殊能力分别统计。")}
        raw.groups[28]={count=(groups[1].complete or groups[2].complete) and 1 or 0,total=1,items=skill_items,source=t("任意一类全部完成即可；下方显示两类节点数量。")}
        local gear={}
        local gear_stages=settings:get_field("_GrowthParam_PL000"):get_field("_BaseGrowthParamData"):get_field("_EnhancementStageDataList")
        assert(gear_stages:get_size()==enum("app.SaveDataHelper_EnhancementParam.CATEGORY","MAX"),t("装备材料类别数量不符"))
        for i,key in ipairs({"WEAPON","ARMOR","GAUNTLET"}) do
            local category=enum("app.SaveDataHelper_EnhancementParam.CATEGORY",key)
            local resource_ids,seen={},{}
            array_each(gear_stages:get_element(category):get_field("_EnhancementStageDataList"),64,function(stage)
                array_each(stage:get_field("_Resources"),32,function(resource)
                    array_each(resource:get_field("_NeedItems"),32,function(item)
                        local id=item:get_field("_ItemId"):get_field("_Value")
                        if not seen[id] then resource_ids[#resource_ids+1]=id;seen[id]=true end
                    end)
                end)
            end)
            gear[#gear+1]={id=key,name=({t("武器"),t("防具"),t("笼手")})[i],complete=helper:get_field("_Enhancement"):call("checkLastLvActivated",category),
                map_targets=item_targets(resource_ids,ih),map_note=t("材料需求来自此类装备的强化配方。下方为固定拾取点，可能包含已拾取地点；实际强化请使用破魔镜菜单。")}
        end
        raw.groups[31]=model.group(gear,t("已强化至最高阶段的装备类别。"))
        raw.groups[30]={count=raw.achievements[30].unlocked and 1 or 0,total=1,items=gear,source=t("本成就只需强化一次；下方展示三类装备的最高阶段状态及材料参考点。")}
        local bags={};local maxbags=ih:get_field("_CacheLvMaxMedicineBagIdList")
        assert(maxbags:call("get_Count")<=32)
        for i=0,maxbags:call("get_Count")-1 do
            local id=maxbags:call("get_Item",i)
            local resource_ids,seen={},{}
            local bagdata=settings:get_field("_ItemAdditionalParam"):get_field("_MedicineBagList")
            array_each(bagdata,64,function(stage)
                local cursor=stage;local belongs=false
                for depth=1,16 do
                    if cursor:get_field("_Id"):get_field("_Value")==id then belongs=true;break end
                    cursor=settings:get_field("_ItemAdditionalParam"):call("getMedicineBagParam",cursor:get_field("_NextId"):get_field("_Value"))
                    if not cursor then break end
                end
                if belongs then for _,field in ipairs({"_UnlockResourceList","_MakeResourceList"}) do array_each(stage:get_field(field),32,function(resource)
                    local rid=resource:get_field("_Id"):get_field("_Value")
                    if not seen[rid] then resource_ids[#resource_ids+1]=rid;seen[rid]=true end
                end) end end
            end)
            bags[#bags+1]={id=tostring(id),name=item_name(ih,id),complete=ih:call("existActivatedMedicineBag",id),map_targets=item_targets(resource_ids,ih),
                map_note=t("下方列出制作、强化材料的固定拾取点，可能包含已拾取地点；材料还可能来自掉落、奖励或商店。制作与强化请使用游戏的鬼灯袋设施图标。")}
        end
        raw.groups[34]=model.group(bags,t("当前存档已解锁的最高阶段鬼灯袋；不受剩余使用次数影响。"))
        raw.groups[33]={count=math.min(raw.groups[34].count,1),total=1,items=bags,source=raw.groups[34].source}
        local amulet_helper=helper:get_field("_Amulet")
        local levels={}
        list_each(amulet_helper:get_field("_OwningAmulets"),128,function(a)
            local series=a:get_field("<SeriesId>k__BackingField")
            levels[series]=math.max(levels[series] or 0,a:get_field("<Level>k__BackingField"))
        end)
        local dlc=td("app.SaveDataHelper_Amulet"):get_field("_AmuletSeriesId2ExyraContentIdList"):get_data(nil)
        local series_map={};local series_order={}
        array_each(settings:get_field("_GrowthParam_PL000"):get_field("_BaseGrowthParamData"):get_field("_AmuletDataList"):get_field("_AmuletDatas"),300,function(a)
            local id=a:call("get_SeriesId")
            if a:get_field("_IsInGame") and not dlc:call("ContainsKey",id) then
                if not series_map[id] then series_order[#series_order+1]=id;series_map[id]={level=0} end
                if a:get_field("_Level")>series_map[id].level then series_map[id]={level=a:get_field("_Level"),name=message(a:get_field("_AmuletName"):get_field("_MsgGuid"))} end
            end
        end)
        local amulets={}
        for _,id in ipairs(series_order) do
            local entry=series_map[id];local level=levels[id] or 0
            amulets[#amulets+1]={id=tostring(id),name=entry.name.." "..level.."/"..entry.level,complete=level>=entry.level}
        end
        raw.groups[36]=model.group(amulets,t("当前存档最高等级御守；按游戏的额外内容列表排除 DLC。"))
        raw.groups[35]={count=math.min(raw.groups[36].count,1),total=1,items=amulets,source=raw.groups[36].source}
        local weapons={}
        for _,key in ipairs({"PLSKILL_00","PLSKILL_01","PLSKILL_02","PLSKILL_03","PLSKILL_04","PLSKILL_05","event_trial_04"}) do
            local id=enum("app.ItemEnum.ID_Fixed",key)
            weapons[#weapons+1]={id=key,name=item_name(ih,id),complete=ih:call("getItemCountOfId",id)>0,map_targets=item_targets({id},ih)}
            if key=="PLSKILL_02" then
                weapons[#weapons].map_targets=nil;weapons[#weapons].map_mode="native"
                weapons[#weapons].map_note=t("此武具位于任务的独立场景中，该场景不在普通地图内；请使用游戏任务追踪进入。")
            end
        end
        raw.groups[32]=model.group(weapons,t("当前持有的 6 件鬼之武具及鬼之刚弓。"))
        local story=singleton("app.StoryManager")
        local mission_names={}
        for _,f in ipairs(td("app.MissionDef.ID_Fixed"):get_fields()) do
            if f:is_static() then
                local ordinary=td("app.MissionDef.ID"):get_field(f:get_name())
                if ordinary then mission_names[f:get_data(nil)]={ordinal=ordinary:get_data(nil),key=f:get_name()} end
            end
        end
        local character,sub={},{}
        array_each(story:get_field("_MissionListData"):get_field("_DataList"),256,function(row)
            local fixed=row:get_field("_MissionID"):get_field("_Value")
            local id=mission_names[fixed]
            if id then
                local category=story:call("getMissionType",id.ordinal)
                local target=category==enum("app.MissionDef.MISSION_TYPE","CHARACTER_MISSION") and character or (category==enum("app.MissionDef.MISSION_TYPE","SUB_MISSION") and sub)
                if target then
                    local name=message(story:call("getMissionName",id.ordinal))
                    -- 已验证资源含两个没有名称的废弃支线；菜单也不展示。
                    if name and name~="" then target[#target+1]={id=id.key,name=name,complete=story:call("checkMissionClearFlag(app.MissionDef.ID_Fixed)",fixed),map_mode="native",map_note=t("此任务使用游戏原生任务图标，请在游戏任务列表中追踪。已完成或尚未触发的任务可能没有图标。")} end
                end
            end
        end)
        raw.groups[16]=model.group(character,t("当前周目京都奇谭完成标志；新周目可重置，成就解锁会保留。"))
        raw.groups[18]=model.group(sub,t("当前周目一树之荫完成标志；新周目可重置，成就解锁会保留。"))
        raw.groups[15]={count=math.min(raw.groups[16].count,1),total=1,items=character,source=raw.groups[16].source}
        raw.groups[17]={count=math.min(raw.groups[18].count,1),total=1,items=sub,source=raw.groups[18].source}
        return raw
    end
    return self
end
return R
