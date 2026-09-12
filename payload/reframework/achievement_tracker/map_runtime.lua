local I=dofile("reframework/achievement_tracker/i18n.lua")
local t=I.translator("en")
-- 地图边界：原生关卡物品配置 -> 杂记 ID -> 当前地图投影。
-- 不改变游戏图标、手动地图标记或存档。仅缓存已验证的静态坐标。
local R={}
local base="reframework/achievement_tracker/"
local geometry=dofile(base.."map_model.lua")
local types={}
local function td(name)
    if not types[name] then types[name]=assert(sdk.find_type_definition(name),t("缺少地图类型：")..name) end
    return types[name]
end
local function native(o,t,m,...) return sdk.call_native_func(o,td(t),m,...) end
local function enum(type_name,key) return assert(td(type_name):get_field(key),t("缺少地图枚举：")..key):get_data(nil) end
local function reverse(t)
    local out={}
    for _,f in ipairs(td(t):get_fields()) do if f:is_static() then out[tostring(f:get_data(nil))]=f:get_name() end end
    return out
end
local function each(array,limit,fn)
    local n=array:get_size();assert(n<=limit,t("地图资源超过已验证范围"))
    for i=0,n-1 do fn(array:get_element(i),i) end
end
function R.new(c,language)
    assert(language,"Language adapter required")
    local function t(key) return I.translator(c.state.language)(key) end
    local function message(guid) return language.message(guid) end
    local prepared_language
    local self={state={status="closed"},metrics={frames=0},points={}}
    local catalog=dofile(base.."location_catalog.lua")
    local area_names,area_keys,floor_keys,locations
    local function prepare()
        area_keys=reverse("app.EnvDef.AreaID_Fixed");floor_keys=reverse("app.EnvDef.FIELD_ORDER_Fixed")
        area_names,locations={},{}
        local stage_keys=reverse("app.EnvDef.StageID_Fixed")
        local env=sdk.get_managed_singleton("app.EnvironmentManager")
        local maps=sdk.get_managed_singleton("app.VariousDataManager"):get_field("_Setting"):get_field("_MapData"):get_field("_Datas")
        each(maps,32,function(map)
            local map_name=message(map:get_field("_MapName"))
            each(map:get_field("_Areas"),64,function(area,index)
                local stage_key=stage_keys[tostring(area:get_field("_StageID"):get_field("_Value"))]
                local stage_name=message(env:call("getStageNameID",enum("app.EnvDef.StageID",stage_key)))
                local name=message(area:get_field("_AreaName"))
                if not name or name=="" then name=stage_name end
                local label=map_name and map_name~="" and map_name~=name and map_name.." · "..name or name
                each(area:get_field("_AreaFields"),128,function(field)
                    local aid=tostring(field:get_field("_AreaID"):get_field("_Value"))
                    local floor=tostring(field:get_field("_Floor"):get_field("_Value"))
                    area_names[aid]=stage_name
                    locations[aid..":"..floor]={label=label,index=index}
                end)
            end)
        end)
    end
    local function resolve(guid)
        if self.points[guid] then return self.points[guid] end
        local p=assert(catalog.points[guid],t("缺少定位条目：")..guid)
        local aid=p.area and tonumber(p.area) or enum("app.EnvDef.AreaID_Fixed",p.area_key)
        local fid=p.floor and tonumber(p.floor) or sdk.get_managed_singleton("app.EnvironmentManager"):get_field("_EnvInfoManager"):call("getFieldOrder",aid,Vector3f.new(p.x,p.y,p.z))
        local area,floor=tostring(aid),tostring(fid)
        local where=locations[area..":"..floor]
        if not where then return nil end
        local point={id=guid,guid=guid,x=p.x,y=p.y,z=p.z,area=area,floor=floor,label=where.label,kind=p.kind}
        self.points[guid]=point
        return point
    end
    local function has_native_icon(gui,guid)
        local found=false
        each(gui:get_field("_IconBase"),2048,function(icon)
            if found or not icon or not icon:call("get_IsEnable") then return end
            local parent=icon:get_type_definition();local object=false
            for depth=1,8 do
                if not parent then break end
                if parent:get_full_name()=="app.GUI060000.cObjectIconBase" then object=true;break end
                parent=parent:get_parent_type()
            end
            if object then
                local data=icon:call("get_ObjectData"):get_field("_MapObjectData")
                if data and data:call("get_MainID"):call("ToString")==guid then found=true end
            end
        end)
        return found
    end
    function self.reset()
        self.state={status="closed"};c.map_targets={};c.map_unmapped=0
    end
    function self.update()
        self.metrics.frames=self.metrics.frames+1
        local item=c.selected_item();local row=c.selected()
        self.state={status="closed"};c.map_targets={};c.map_unmapped=0
        if c.state.status~="ready" or not sdk.get_managed_singleton("app.GameFlowManager"):call("get_IsIngameStable") then self.reset();return end
        if prepared_language~=c.state.language then
            self.points={};prepare();prepared_language=c.state.language
        end
        if item and item.map_mode=="native" then self.state={status="native",note=item.map_note};return end
        if not item or not item.map_targets or #item.map_targets==0 then
            self.state={status="non_spatial",note=(item and item.map_note) or (row and row.map_note) or t("此项尚未建立固定位置对应。")};return
        end
        for _,entry in ipairs(item.map_targets) do
            local p=resolve(entry.guid)
            if p then c.map_targets[#c.map_targets+1]={guid=entry.guid,name=entry.name,label=p.label,point=p} end
        end
        c.map_unmapped=#item.map_targets-#c.map_targets
        local selected
        for _,entry in ipairs(c.map_targets) do if entry.guid==c.config.location then selected=entry;break end end
        if not selected then selected=c.map_targets[1];if selected then c.change("location",selected.guid) end end
        if not selected then self.state={status="unknown",note=t("已找到物件，但该位置尚未匹配到游戏地图。")};return end
        local target=selected.point
        self.state={status="closed",label=target.label,known=true,note=item.map_note}
        if not c.config.map_tracking then self.state.status="disabled";return end
        local gui=sdk.get_managed_singleton("app.GUIManager"):call("getGUI",enum("app.GUIID.ID","UI060000"))
        if not gui or gui:call("get_IsClosedState") or not gui:get_field("_IsEnableMap") then return end
        self.state.open=true
        local area=gui:get_field("CurrentMapArea"):get_field("_MapArea")
        local fields={}
        each(area:get_field("_AreaFields"),128,function(field)
            fields[#fields+1]={area=tostring(field:get_field("_AreaID"):get_field("_Value")),floor=tostring(field:get_field("_Floor"):get_field("_Value"))}
        end)
        if not geometry.matches(target,fields) then self.state.status="other_area";return end
        local native_gui=gui:get_field("_GUI")
        local origin=native(native_gui,"via.gui.GUI","getPhysicalToVirtualMousePos",td("via.Point"):get_field("Zero"):get_data(nil))
        local unit=native(native_gui,"via.gui.GUI","getPhysicalToVirtualMousePos",td("via.Point"):get_field("One"):get_data(nil))
        local map=gui:call("getMapPosFromWorldPos",Vector3f.new(target.x,target.y,target.z))
        local screen=gui:call("getScreenPosFromMapPos",map)
        local pixel=geometry.physical(screen,origin,unit)
        local minimum=geometry.physical(gui:get_field("_CursorMoveLimitMin"),origin,unit)
        local maximum=geometry.physical(gui:get_field("_CursorMoveLimitMax"),origin,unit)
        self.state.bounds={minimum=minimum,maximum=maximum}
        self.state.id=item.id;self.state.name=item.name;self.state.x=pixel.x;self.state.y=pixel.y
        self.state.status=geometry.visible(pixel,minimum,maximum,20) and "visible" or "offscreen"
        if item.native_object and has_native_icon(gui,target.guid) then self.state.status="native_object";return end
        self.state.name=selected.name
        self.state.complete=item.complete and not item.map_note
    end
    return self
end
return R
