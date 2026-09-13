"""使用 Lua 5.4 验证快照语义、筛选、偏好和实测文字换行。"""
import json, os, pathlib, sys, re
sys.stdout.reconfigure(encoding='utf-8')
from lupa.lua54 import LuaRuntime
from fontTools.ttLib import TTFont
root=pathlib.Path(__file__).resolve().parents[1]/'payload/reframework/achievement_tracker'
rt=LuaRuntime(unpack_returned_tuples=True)
rt.globals().dofile=lambda p:rt.execute((root.parents[1]/p).read_text(encoding='utf-8'))
def module(name):return rt.execute((root/(name+'.lua')).read_text(encoding='utf-8'))
rt.globals().model=module('model');rt.globals().catalog=module('catalog')
rt.globals().Controller=module('controller');rt.globals().View=module('view')
rt.execute('''
local function snapshot(complete)
    local raw={status="ready",language="zh",achievements={},groups={}}
    for i=1,52 do raw.achievements[i]={unlocked=false,count=-1,target=0} end
    raw.achievements[50]={unlocked=true,count=0,target=30}
    raw.groups[24]=model.group({{id="a",name="蛊饲",complete=complete},{id="b",name="鵺兽",complete=false}},"fixture")
    return model.build(catalog,raw)
end
local before,after=snapshot(false),snapshot(true)
assert(before.rows[24].count==0 and after.rows[24].count==1)
assert(snapshot(false).rows[24].count==0,"读旧档必须回退，不能累计历史缓存")
assert(after.rows[50].unlocked and after.rows[50].count==0)
assert(model.label(after.rows[50]):find("已解锁",1,true))
assert(after.rows[27].count==nil,"无计数不能假装为零")
assert(#model.filter(after,1,true,"Get This Thing Off Me")==0)
assert(#model.filter(after,1,false,"genma-ologist")==1)
assert(#model.filter(after,2,false,"幻魔专家")==1)
assert(#model.filter(after,3,false,"幻魔专家")==0)
assert(not pcall(model.group,{{id="x"},{id="x"}},"fixture"))
local saved,writes=nil,0
local c=Controller.new(model,function()return nil end,function(v)saved=v;writes=writes+1 end)
c.accept(before);assert(c.selected_item().id=="a")
c.accept(after);assert(c.selected_item().id=="b","拿到一件后自动定位下一缺失项")
c.persist();local first=writes
c.accept(after);c.persist();assert(writes==first,"无变更不得重复保存设置")
c.accept(model.build(catalog,{status="waiting"}))
assert(c.selected()==nil and c.selected_item()==nil,"转场不能展示旧进度")
c.accept(model.build(catalog,{status="error",error="fixture"}))
assert(#c.state.rows==0 and c.state.error=="fixture")
c.accept(before);assert(c.selected().count==0)
assert(saved.achievements==nil and saved.count==nil,"设置不得包含游戏进度")
local broken=Controller.new(model,function()return {group=99,font_size=90,selected="bad"} end,function()end)
assert(broken.config.group==1 and broken.config.font_size==22)
''')
print('PASS: 进度增减、事件归零、未知数量、去重、中文/英文搜索、转场/错误清空、偏好保存')
font=TTFont(root.parent/'fonts/onimusha_tracker_sans.ttf')
cmap=font.getBestCmap();units=font['head'].unitsPerEm
text=''.join(p.read_text(encoding='utf-8') for p in root.glob('*.lua'))
missing=sorted({c for c in text if 0x3000<=ord(c)<=0xFFFF and ord(c) not in cmap})
assert not missing,repr(missing)
print('PASS: 随包开源字体 cmap 覆盖全部中文界面与提示字符')
def measure(s,size=22): return sum(font['hmtx'][cmap[ord(c)]][0] for c in s)*size/units
wrap=module('view').wrap
for size in (18,22,26):
    for width in (1280,1920,2560):
        available=min(size*20,width-24)-40
        for t in ['幻魔杂记【鵺兽】','洛东：五条通　西破魔镜以北的屋内。','击败最终首领后读档：六道珍皇寺后方井内。','一次性吸收不少于30个灵魂']:
            parts=list(wrap(t,available,lambda s:measure(s,size)).values())
            assert ''.join(parts)==t
            assert all(measure(p,size)<=available for p in parts)
print('PASS: 18/22/26 字号 × 1280/1920/2560 宽度中文换行无丢字、无超宽')
rt.globals().Map=module('map_model')
rt.execute('''
local p=Map.physical({x=960,y=540},{x=0,y=0},{x=.75,y=.75})
assert(p.x==1280 and p.y==720,"原生 1080p 坐标必须转换到真实 1440p 画面")
local letterbox=Map.physical({x=960,y=540},{x=-320,y=0},{x=-319,y=1})
assert(letterbox.x==1280 and letterbox.y==540,"保留引擎给出的宽屏偏移")
assert(not pcall(Map.physical,{x=1,y=1},{x=0,y=0},{x=0,y=0}))
local fields={{area="洛东",floor="地面"}}
assert(Map.matches({area="洛东",floor="地面"},fields))
assert(not Map.matches({area="大江山",floor="地面"},fields))
assert(not Map.matches({area="洛东",floor="地下"},fields))
assert(Map.visible({x=100,y=100},{x=0,y=0},{x=200,y=200},20))
assert(not Map.visible({x=199,y=100},{x=0,y=0},{x=200,y=200},20))
assert(not Map.valid({area_key="x",floor_key="x",x=0/0,y=0,z=0}))
assert(not Map.valid({area_key="x",floor_key="x",x=math.huge,y=0,z=0}))
''')
seed=module('map_points')
assert list(seed.items()),'缺少已验证坐标'
for key,point in seed.items():
    assert rt.globals().Map.valid(point),key
print('PASS: 地图像素换算、宽屏偏移、区域/楼层隔离、边界裁切与位置缓存校验')
locations=module('location_catalog')
assert len(list(locations.books.items()))==23
assert len(list(locations.dogs.items()))==36
for section in (locations.books,locations.dogs):
    guids=list(section.values())
    assert len(set(guids))==len(guids),'固定收集条目不能指向同一个物件'
    assert all(locations.points[g] is not None for g in guids)
for key,guids in locations['items'].items():
    assert len(set(guids.values()))==len(list(guids.values())),key
    for guid in guids.values():assert locations.points[guid] is not None,(key,guid)
for guid,point in locations.points.items():
    assert point.guid==guid
    assert point.area or point.area_key
    assert all(isinstance(point[k],(int,float)) and abs(point[k])<1000000 for k in ('x','y','z'))
assert locations.points[locations.boss] is not None
assert locations.boss=='da71b42c-bcf1-4c91-b7fe-52659073924e'
assert locations.points[locations.boss].area_key=='Area201_002','清水寺成就不得指向地下研究所的同种敌人'
for entry in locations.rescues.values():assert locations.points[entry.guid] is not None
rt.execute('''
local raw={status="ready",achievements={},groups={}}
for i=1,52 do raw.achievements[i]={unlocked=false,count=-1,target=0} end
raw.groups[20]={count=15,total=30,items={{id="ref",reference=true,complete=false}},source="fixture"}
raw.groups[19]=model.group({{id="boss",complete=true}},"fixture")
local s=model.build(catalog,raw)
assert(s.rows[20].count==15 and s.rows[20].total==30,"候选点数量不能代替救援计数")
assert(#model.items(s.rows[20],true)==1,"参考点不假冒已收集")
assert(#model.items(s.rows[19],true)==0)
assert(s.rows[37].map_note and s.rows[25].map_note,"非位置条件必须说明")
''')
print('PASS: 完整 23 本/36 只定位引用、坐标有效性、候选救援与成就计数分离')

i18n=module('i18n')
catalog=rt.globals().catalog
non_chinese=['Japanese','English','French','Italian','German','Spanish','Russian','Polish','Dutch','Portuguese','PortugueseBr','Korean','Finnish','Swedish','Danish','Norwegian','Czech','Hungarian','Slovak','Arabic','Turkish','Bulgarian','Greek','Romanian','Thai','Ukrainian','Vietnamese','Indonesian','Fiction','Hindi','LatinAmericanSpanish','Max','Unknown','future-language']
assert all(i18n.select(name)=='en' for name in non_chinese)
assert i18n.select(None)=='en'
assert i18n.select('SimplelifiedChinese')=='zh'
assert i18n.select('TransitionalChinese')=='zh'
english=i18n.translator('en')
zh=i18n.translator('zh')
keys=[]
for p in root.glob('*.lua'):
    if p.name=='i18n.lua':continue
    for value in re.findall(r't\(("(?:\\.|[^"\\])*")\)',p.read_text(encoding='utf8')):
        key=json.loads(value)
        assert zh(key)==key
        translated=english(key)
        assert not re.search('[\u3400-\u9fff]',translated),(key,translated)
        keys.append(key)
for hint in module('hints').values():
    for field in ('location','detail','source'):assert not re.search('[\u3400-\u9fff]',english(hint[field]))
for size in (18,22,26):
    for width in (1280,1920,2560):
        available=min(size*20,width-24)-40
        for text in [english(key) for key in keys]+[v.english_name for v in catalog.values()]+[v.english_description for v in catalog.values()]:
            parts=list(wrap(text,available,lambda s:measure(s,size)).values())
            assert ''.join(parts)==text
            assert all(measure(p,size)<=available for p in parts)
rt.execute('''
local raw={status="ready",language="en",achievements={},groups={}}
for i=1,52 do raw.achievements[i]={unlocked=false,count=-1,target=0} end
local en=model.build(catalog,raw)
assert(en.rows[24].name=="Genma-ologist")
assert(en.rows[24].description=="Collect all the Genma notes.")
assert(model.label(en.rows[24])=="Locked | Condition-based")
assert(#model.filter(en,1,false,"幻魔专家")==1)
assert(#model.filter(en,1,false,"genma-ologist")==1)
local c=Controller.new(model,function()return {selected="ACHIEVEMENT_020",hud=false} end,function()end)
c.accept(en)
raw.language="zh";c.accept(model.build(catalog,raw))
assert(c.config.selected=="ACHIEVEMENT_020" and not c.config.hud)
assert(c.selected().name=="救助居民")
raw.language="en";c.accept(model.build(catalog,raw))
assert(c.selected().name=="Citizen Savior")
''')
print('PASS: 全部游戏语言分类、中英文文本完整性、英文换行、语言切换保留选择和双语搜索')

rt.execute('''
-- 精确复现实际失败：文字为英文、语音/资源语言仍为中文。
-- 此替身故意不提供 ResourceManager，误读它时测试必须失败。
local option={text=1,voice=13}
local function dtype(name) return {get_full_name=function()return name end} end
local function field(name,value) return {is_static=function()return true end,get_name=function()return name end,get_data=function(_,owner)assert(owner==nil);return value end} end
local fields={English=field("English",1),SimplelifiedChinese=field("SimplelifiedChinese",13),TransitionalChinese=field("TransitionalChinese",12),Japanese=field("Japanese",0)}
local language_type={get_fields=function()return {fields.English,fields.SimplelifiedChinese,fields.TransitionalChinese,fields.Japanese} end,get_field=function(_,key)return fields[key] end}
local text_reader={is_static=function()return false end,get_return_type=function()return dtype("via.Language") end,call=function(_,owner)assert(owner==option);return owner.text end}
local guid={call=function(_,method)assert(method=="ToString");return "fixture-name" end}
local message_reads=0
local message_reader={get_name=function()return "get" end,get_param_types=function()return {dtype("System.Guid"),dtype("via.Language")} end,is_static=function()return true end,get_return_type=function()return dtype("System.String") end,
 call=function(_,owner,value,lang)assert(owner==nil and value==guid);message_reads=message_reads+1;return lang==1 and "Oni Stone" or "鬼石" end}
local item_reader={is_static=function()return true end,get_return_type=function()return dtype("app.user_data.ItemData.cData") end,
 call=function(_,owner,id)assert(owner==nil and id==123);return {get_field=function(_,key)assert(key=="_NameGuid");return guid end} end}
local types={
 ["via.Language"]=language_type,
 ["app.savedata.cOptionParam"]={get_method=function(_,name)assert(name=="getTextLanguage");return text_reader end},
 ["via.gui.message"]={get_methods=function()return {message_reader} end},
 ["app.ItemUtil"]={get_method=function(_,name)assert(name=="getData");return item_reader end}
}
sdk={find_type_definition=function(name)return assert(types[name],"Unexpected type: "..name) end,
 get_managed_singleton=function(name)assert(name=="app.SaveDataManager");return {call=function(_,method)assert(method=="get_SystemSaveData");return {get_field=function(_,key)assert(key=="_Option");return option end} end} end}
local adapter=dofile("reframework/achievement_tracker/language_runtime.lua").new()
assert(adapter.locale=="en" and adapter.game_language=="English")
assert(adapter.item_name(123)=="Oni Stone")
assert(adapter.item_name(123)=="Oni Stone" and message_reads==1)
option.text=13;adapter.refresh()
assert(adapter.locale=="zh" and adapter.item_name(123)=="鬼石" and message_reads==2)
option.text=0;adapter.refresh()
assert(adapter.locale=="en" and adapter.game_language=="Japanese" and adapter.item_name(123)=="Oni Stone")
assert(option.voice==13)
for _,key in ipairs({"hud","unfinished","missing","map_tracking"}) do
 local stored={};stored[key]=false
 local c=Controller.new(model,function()return stored end,function()end)
 assert(c.config[key]==false,"已保存的 false 不得回退到默认 true："..key)
end
''')
print('PASS: 英文文字＋中文语音回归、运行时切换清空名称缓存、其他语言回退英文、false 偏好完整保留')

# 狛犬完成状态必须独立于场景中的 MysteryManager 临时数组。
# 执行真实读取段，模拟传送/救援前后存档状态变化；禁止访问场景管理器。
source=(root/'runtime.lua').read_text(encoding='utf-8')
dog_read=source[source.index('        local dogs={}'):source.index('        local sk=')]
rt.globals().dog_read=dog_read
rt.globals().positions=module('location_catalog')
rt.execute('''
local released={}
helper={get_field=function(_,key)
    assert(key=="_Mystery")
    return {call=function(_,method,key) return released[key] or false end}
end}
function singleton(name)
    assert(name=="app.EnvironmentManager", "不能依赖场景 MysteryManager 的临时数组")
    return {call=function(_,_,id) return id end}
end
function enum(_,key) return key end
function message(id) return id end
function t(s) return s end
local read=assert(load(dog_read))
raw={groups={}};read()
assert(raw.groups[23].total==36 and raw.groups[23].count==0)
local first=next(positions.dogs);released[first]=true
raw={groups={}};read()
assert(raw.groups[23].total==36 and raw.groups[23].count==1)
released={};raw={groups={}};read()
assert(raw.groups[23].count==0,"读取其他存档后状态必须更新")
''')
print('PASS: 狛犬读取不依赖场景临时数组；36 项清单及救助/读档状态更新')

map_source=(root/'map_runtime.lua').read_text(encoding='utf-8')
rt.globals().batch_source=map_source[map_source.index('        if all_locations then'):map_source.index('        local map=gui:call("getMapPosFromWorldPos",Vector3f.new(target.x')]
rt.execute('''
local points={a={area="A",floor="1",x=50,y=50,z=0},b={area="A",floor="1",x=90,y=90,z=0},c={area="B",floor="1",x=50,y=50,z=0},d={area="A",floor="2",x=50,y=50,z=0},e={area="A",floor="1",x=500,y=500,z=0}}
function resolve(id) return points[id] end
Vector3f={new=function(x,y,z)return {x=x,y=y,z=z}end}
geometry=Map;origin={x=0,y=0};unit={x=1,y=1}
fields={{area="A",floor="1"}};selected={guid="b"};self={};all_locations=true
row={items={}}
for _,id in ipairs({"a","b","c","d","e","a"}) do row.items[#row.items+1]={map_targets={{guid=id,name=id}}} end
gui={get_field=function(_,name) if name=="_MapCursor" then return {get_field=function()return {x=50,y=50}end} elseif name=="_CursorMoveLimitMin" then return {x=0,y=0} else return {x=200,y=200} end end,call=function(_,method,p)return p end}
local update=assert(load(batch_source));update()
assert(self.state.multi and #self.state.markers==2,"仅当前地图楼层可见点，去重并排除视野外位置")
assert(not self.state.markers[1].selected and self.state.markers[2].selected)
fields={{area="B",floor="1"}};update();assert(#self.state.markers==1,"切换地图重新筛选")
row.id="ACHIEVEMENT_024";c={config={missing=true}}
row.items[1].complete=true;row.items[6].complete=true
fields={{area="A",floor="1"}};update()
assert(#self.state.markers==1 and self.state.markers[1].name=="b","缺失筛选排除已收集杂记")
c.config.missing=false;update();assert(#self.state.markers==2,"关闭缺失筛选显示已收集杂记")
all_locations=false;self.state={status="single"};update();assert(self.state.status=="single")
local c=Controller.new(model,function()return {rescue_all=true} end,function()end)
assert(c.config.rescue_all);c.change("rescue_all",false);assert(not c.config.rescue_all)
''')
print('PASS: 救援全地图模式筛选、楼层隔离、裁切、去重、选中标签及偏好')

rt.execute('''local a,b={x=0,y=0},{x=20,y=0}
assert(Map.focus({a,b},{x=17,y=0},32)==b)
assert(Map.focus({a,b},{x=100,y=100},32)==nil)
assert(Map.focus({a,b},{x=10,y=0},32)==a)
assert(Map.focus({},{x=0,y=0},32)==nil)''')
print('PASS: 光标聚焦最近圆环、移开恢复、等距稳定及空地图')
