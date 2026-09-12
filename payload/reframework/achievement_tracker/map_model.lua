-- 纯 Lua：地图身份、坐标换算及可见范围，不持有游戏对象。
local M={}
function M.physical(point,origin,unit)
    local sx,sy=unit.x-origin.x,unit.y-origin.y
    assert(sx>0 and sy>0,"地图坐标比例无效")
    return {x=(point.x-origin.x)/sx,y=(point.y-origin.y)/sy}
end
function M.visible(point,minimum,maximum,padding)
    return point.x>=minimum.x+padding and point.x<=maximum.x-padding
       and point.y>=minimum.y+padding and point.y<=maximum.y-padding
end
function M.matches(point,fields)
    for _,field in ipairs(fields) do
        if point.area==field.area and point.floor==field.floor then return true end
    end
    return false
end
function M.valid(point)
    if type(point)~="table" or type(point.area_key)~="string" or type(point.floor_key)~="string" then return false end
    for _,key in ipairs({"x","y","z"}) do
        local n=point[key]
        if type(n)~="number" or n~=n or math.abs(n)>1000000 then return false end
    end
    return true
end
return M
