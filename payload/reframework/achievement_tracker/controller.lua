local I=dofile("reframework/achievement_tracker/i18n.lua")
local t=I.translator("en")
local K=dofile("reframework/achievement_tracker/hotkeys.lua")
local C={}
local defaults={selected="ACHIEVEMENT_024",item="",location="",group=1,unfinished=true,missing=true,hud=true,hud_key=119,map_tracking=true,rescue_all=false,books_all=false,hud_x=98,hud_y=12,font_size=22}
function C.new(model,load,save)
    local self={state={status="waiting",rows={},by_id={},unlocked=0},config={},search="",panel=false,page=1,dirty=false}
    local ok,stored=pcall(load)
    if not ok then self.settings_error=t("设置读取失败：")..tostring(stored) end
    stored=ok and type(stored)=="table" and stored or {}
    for key,value in pairs(defaults) do
        if type(stored[key])==type(value) then self.config[key]=stored[key]
        else self.config[key]=value end
    end
    self.key_capture=K.capture()
    local c=self.config
    if not K.valid(c.hud_key) then c.hud_key=119 end
    local function t(key) return I.translator(self.state.language)(key) end
    if not c.selected:match("^ACHIEVEMENT_%d%d%d$") then c.selected=defaults.selected end
    if c.group<1 or c.group>4 or c.group%1~=0 then c.group=1 end
    c.hud_x=math.max(0,math.min(100,c.hud_x));c.hud_y=math.max(0,math.min(100,c.hud_y))
    if c.font_size~=18 and c.font_size~=22 and c.font_size~=26 then c.font_size=22 end
    function self.change(key,value)
        if c[key]==value then return end
        c[key]=value;self.dirty=true
        if key=="group" or key=="unfinished" then self.page=1 end
    end
    function self.persist()
        if not self.dirty then return end
        local success,err=pcall(save,c)
        self.settings_error=not success and t("设置保存失败：")..tostring(err) or nil
        self.dirty=false
    end
    function self.accept(state)
        self.state=state
        if state.status~="ready" then return end
        if not state.by_id[c.selected] then self.change("selected",defaults.selected) end
        local row=state.by_id[c.selected]
        local current=model.find_item(row,c.item)
        if not current or (c.missing and current.complete) then
            local items=model.items(row,c.missing)
            self.change("item",items[1] and items[1].id or "")
        end
    end
    function self.select(id)
        self.change("selected",id);self.change("item","")
        self.accept(self.state)
    end
    -- 重载交接只在同一进程的紧邻加载中有效，读取后由入口立即消费。
    function self.restore_reset(value,clock,wall)
        if type(value)~="table" or type(value.panel)~="boolean" or type(value.clock)~="number" or type(value.wall)~="number" then return end
        local elapsed=clock-value.clock
        local age=wall-value.wall
        if elapsed<0 or elapsed>30 or age<0 or age>30 or math.abs(elapsed-age)>2 then return end
        self.panel=value.panel
    end
    function self.reset_snapshot(clock,wall)
        return {panel=self.panel,clock=clock,wall=wall}
    end
    local previous_menu=nil
    local previous_status="waiting"
    function self.menu_state(open)
        if open and previous_menu==false and self.state.status=="ready" then self.panel=true end
        -- 首次读取前的 waiting 不覆盖重载恢复值；实际进入转场仍收起窗口。
        if self.state.status=="waiting" and previous_status~="waiting" then self.panel=false end
        previous_status=self.state.status
        previous_menu=open
    end
    function self.visible() return model.filter(self.state,c.group,c.unfinished,self.search) end
    function self.selected() return self.state.by_id[c.selected] end
    function self.selected_item() return model.find_item(self.selected(),c.item) end
    return self
end
return C
