-- 鬼武者：剑之道 成就与收集追踪 0.4.3
local base="reframework/achievement_tracker/"
local model=dofile(base.."model.lua")
local catalog=dofile(base.."catalog.lua")
local runtime_module=dofile(base.."runtime.lua")
local control=dofile(base.."controller.lua").new(model,function()return json.load_file("onimusha_achievement_tracker_config.json")end,function(v)assert(json.dump_file("onimusha_achievement_tracker_config.json",v),"无法写入设置文件")end)
local reset_file="onimusha_achievement_tracker_reset.json"
local reset_ok,reset_state=pcall(json.load_file,reset_file)
if reset_ok and reset_state then
    control.restore_reset(reset_state,os.clock(),os.time())
    assert(json.dump_file(reset_file,{}),"无法消费重载界面状态")
end
local view,runtime,map,language
local initial_ok,initial_error=pcall(function()
    language=dofile(base.."language_runtime.lua").new()
    runtime=runtime_module.new(model,catalog,dofile(base.."hints.lua"),language)
    view=dofile(base.."view.lua").new(model,control)
    map=dofile(base.."map_runtime.lua").new(control,language)
end)
local generation=(_G.onimusha_achievement_tracker_generation or 0)+1
_G.onimusha_achievement_tracker_generation=generation
local alive=function()return _G.onimusha_achievement_tracker_generation==generation end
local last_read,last_write=0,0
local hotkey=dofile(base.."hotkeys.lua").new()
local error_state=not initial_ok and tostring(initial_error) or nil
local ui_error,map_error=nil,nil
local statistics={version="0.4.3",generation=generation,refreshes=0,errors=0,writes_to_game=0}
local function report()
    local rows={}
    for _,row in ipairs(control.state.rows) do rows[#rows+1]={id=row.id,count=row.count,total=row.total,unlocked=row.unlocked} end
    statistics.status=control.state.status;statistics.error=error_state;statistics.ui_error=ui_error
    statistics.metrics=view and view.metrics or nil;statistics.rows=rows;statistics.updated_at=os.time()
    statistics.language=language and language.locale;statistics.game_language=language and language.game_language
    statistics.selected=control.config.selected;statistics.selected_item=control.config.item
    statistics.map=control.map_state;statistics.map_metrics=map and map.metrics
    statistics.missing_books=model.items(control.state.by_id.ACHIEVEMENT_024,true)
    assert(json.dump_file("onimusha_achievement_tracker_status.json",statistics),"无法写入状态文件")
end
re.on_frame(function()
    if not alive() then return end
    local now=os.clock()
    local menu_open=reframework:is_drawing_ui()
    control.menu_state(menu_open)
    if not menu_open or not control.panel then control.key_capture.cancel() end
    local binding=control.key_capture.update(function(code)return reframework:is_key_down(code)end)
    if binding then control.change("hud_key",binding) end
    local key=control.config.hud_key
    if hotkey.update(key,key~=0 and reframework:is_key_down(key),menu_open) then control.change("hud",not control.config.hud) end
    if control.retry then
        if not initial_ok then
            initial_ok,initial_error=pcall(function()
                language=dofile(base.."language_runtime.lua").new()
    runtime=runtime_module.new(model,catalog,dofile(base.."hints.lua"),language)
                view=dofile(base.."view.lua").new(model,control)
                map=dofile(base.."map_runtime.lua").new(control,language)
            end)
        end
        error_state=not initial_ok and tostring(initial_error) or nil
        control.retry=false;last_read=0
        if map then map.reset();map_error=nil end
    end
    if now-last_read>=1 then
        last_read=now
        if not error_state then
            local start=os.clock()
            local ok,state=pcall(function()return model.build(catalog,runtime.read())end)
            if ok then control.accept(state);statistics.refreshes=statistics.refreshes+1
            else error_state=tostring(state);statistics.errors=statistics.errors+1;control.accept(model.build(catalog,{status="error",language=language and language.locale,error=error_state}));log.error("[Onimusha Tracker] "..error_state) end
            statistics.read_ms=(os.clock()-start)*1000
        else control.accept(model.build(catalog,{status="error",language=language and language.locale,error=error_state})) end
    end
    if map and not map_error then
        local ok,err=pcall(map.update)
        if ok then control.map_state=map.state
        else map_error=tostring(err);map.reset();control.map_state={status="error",error=map_error};log.error("[Onimusha Tracker Map] "..map_error) end
    end
    if view and not ui_error then
        local ok,err=pcall(view.draw,menu_open)
        if not ok then ui_error=tostring(err);log.error("[Onimusha Tracker UI] "..ui_error) end
    end
    control.persist()
    if now-last_write>=5 then last_write=now;local ok,err=pcall(report);if not ok then log.error("[Onimusha Tracker report] "..tostring(err)) end end
end)
re.on_draw_ui(function()
    if not alive() then return end
    if view and not ui_error then view.menu()
    else
        imgui.text("Onimusha Tracker: "..tostring(ui_error or error_state))
        if imgui.button("Retry tracker") then ui_error=nil;control.retry=true end
    end
end)
re.on_script_reset(function()
    if alive() then
        assert(json.dump_file(reset_file,control.reset_snapshot(os.clock(),os.time())),"无法保存重载界面状态")
    end
end)
re.on_config_save(function()if alive() then control.dirty=true;control.persist() end end)
report()
