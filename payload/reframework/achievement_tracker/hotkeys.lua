-- 纯 Lua 按键状态；不拦截或改写游戏输入。
local K={options={{code=0,name="Disabled"}}}
for i=1,24 do K.options[#K.options+1]={code=111+i,name="F"..i} end
for i=48,57 do K.options[#K.options+1]={code=i,name=string.char(i)} end
for i=65,90 do K.options[#K.options+1]={code=i,name=string.char(i)} end
for _,key in ipairs({{36,"Home"},{35,"End"},{33,"Page Up"},{34,"Page Down"},{45,"Insert"},{46,"Delete"}}) do
    K.options[#K.options+1]={code=key[1],name=key[2]}
end
function K.valid(code)
    if code==0 then return true end
    if type(code)~="number" or code%1~=0 or code<8 or code>254 then return false end
    -- Esc 用于取消；修饰键及 Windows 键不能单独绑定，鼠标点击不录入。
    return code~=27 and code~=16 and code~=17 and code~=18 and code~=91 and code~=92 and code~=93 and not (code>=160 and code<=165)
end
function K.name(code)
    for _,key in ipairs(K.options) do if key.code==code then return key.name end end
    local names={[8]="Backspace",[9]="Tab",[13]="Enter",[20]="Caps Lock",[32]="Space",[37]="Left",[38]="Up",[39]="Right",[40]="Down",[144]="Num Lock",[145]="Scroll Lock",[186]=";",[187]="=",[188]=",",[189]="-",[190]=".",[191]="/",[192]="`",[219]="[",[220]="Backslash",[221]="]",[222]="'"}
    if code>=96 and code<=105 then return "Numpad "..(code-96) end
    return names[code] or string.format("VK 0x%02X",code)
end
function K.new()
    local self={previous=nil,code=nil}
    function self.update(code,down,blocked)
        -- 新载入或换绑时先等待释放，避免把正在按住的键当成新操作。
        if self.code~=code then self.code=code;self.previous=down;return false end
        local pressed=down and not self.previous
        self.previous=down
        return code~=0 and pressed and not blocked
    end
    return self
end
function K.capture()
    local self={active=false,previous={}}
    function self.begin(read)
        self.previous={}
        for code=8,254 do self.previous[code]=read(code) end
        self.active=true
    end
    function self.cancel() self.active=false end
    function self.update(read)
        if not self.active then return nil end
        local escape=read(27)
        if escape and not self.previous[27] then self.cancel();return nil end
        local chosen
        for code=8,254 do
            local down=read(code)
            if down and not self.previous[code] and K.valid(code) and not chosen then chosen=code end
            self.previous[code]=down
        end
        if chosen then self.cancel() end
        return chosen
    end
    return self
end
return K
