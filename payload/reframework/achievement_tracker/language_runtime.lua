-- 唯一的游戏语言边界。仅读取文字资源语言，不写入游戏语言或语音设置。
local I=dofile("reframework/achievement_tracker/i18n.lua")
local R={}
function R.new(read_language)
    local enum=assert(sdk.find_type_definition("via.Language"))
    local names={}
    for _,field in ipairs(enum:get_fields()) do
        if field:is_static() then names[field:get_data(nil)]=field:get_name() end
    end
    local values={zh=enum:get_field("SimplelifiedChinese"):get_data(nil),en=enum:get_field("English"):get_data(nil)}
    local get_language=assert(sdk.find_type_definition("app.savedata.cOptionParam"):get_method("getTextLanguage"))
    assert(not get_language:is_static() and get_language:get_return_type():get_full_name()=="via.Language")
    local get_message
    for _,method in ipairs(sdk.find_type_definition("via.gui.message"):get_methods()) do
        local params=method:get_param_types()
        if method:get_name()=="get" and #params==2 and params[1]:get_full_name()=="System.Guid" and params[2]:get_full_name()=="via.Language" then
            assert(method:is_static() and method:get_return_type():get_full_name()=="System.String")
            get_message=method;break
        end
    end
    assert(get_message,"Missing localized message reader")
    local item_data=assert(sdk.find_type_definition("app.ItemUtil"):get_method("getData"))
    assert(item_data:is_static() and item_data:get_return_type():get_full_name()=="app.user_data.ItemData.cData")
    local read=read_language or function()
        local manager=assert(sdk.get_managed_singleton("app.SaveDataManager"),"Save options are not ready")
        local options=manager:call("get_SystemSaveData"):get_field("_Option")
        return get_language:call(options)
    end
    local self={locale="en"};local messages,items={},{}
    function self.refresh()
        local current=read()
        self.game_language=names[current] or "Unknown"
        local locale=I.select(self.game_language)
        if locale~=self.locale then messages,items={},{} end
        self.locale=locale
    end
    function self.message(guid)
        local key=guid:call("ToString")
        if messages[key]==nil then messages[key]=get_message:call(nil,guid,values[self.locale]) end
        return messages[key]
    end
    function self.item_name(id)
        if not items[id] then
            local data=assert(item_data:call(nil,id),"Missing item data: "..id)
            items[id]=assert(self.message(data:get_field("_NameGuid")),"Missing item name: "..id)
        end
        return items[id]
    end
    self.refresh()
    return self
end
return R
