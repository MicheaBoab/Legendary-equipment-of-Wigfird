GLOBAL.setmetatable(
    env,
    {__index = function(t, k)
            return GLOBAL.rawget(GLOBAL, k)
        end}
)

GLOBAL.FUELTYPE.GOLDNUGGET = "GOLDNUGGET"

PrefabFiles = {
    "lswq_spear",
    "lswq_hat",
    "armorlswq",
	"armorlswqbuff"
}

Assets = {

}

STRINGS.NAMES.LSWQ_SPEAR = "告死天使之赐"
STRINGS.RECIPE_DESC.LSWQ_SPEAR = "英灵殿的一道惊雷"
STRINGS.CHARACTERS.GENERIC.DESCRIBE.LSWQ_SPEAR = "我乘闪电而来."

STRINGS.NAMES.LSWQ_HAT = "风暴屹立者之心"
STRINGS.RECIPE_DESC.LSWQ_HAT = "永远的独角兽"
STRINGS.CHARACTERS.GENERIC.DESCRIBE.LSWQ_HAT = "相信的心就是你的魔法"

STRINGS.NAMES.ARMORLSWQ = "瓦尔基里的神圣羽衣"
STRINGS.RECIPE_DESC.ARMORLSWQ = "为我奏响战鼓"
STRINGS.CHARACTERS.GENERIC.DESCRIBE.ARMORLSWQ = "瓦尔哈尔在召唤"

STRINGS.ACTIONS.CASTAOE.LSWQ_SPEAR = "惊蛰"

STRINGS.ACTIONS.CASTSPELL.LSWQ = "惩戒"

RegisterInventoryItemAtlas("images/inventoryimages/lswq_spear.xml", "lswq_spear.tex")
RegisterInventoryItemAtlas("images/inventoryimages/lswq_hat.xml", "lswq_hat.tex")
RegisterInventoryItemAtlas("images/inventoryimages/armorlswq.xml", "armorlswq.tex")

modimport("scripts/lswq_skin/lswq_skinsapi.lua")
MakeItemSkinDefaultImage("lswq_spear","images/inventoryimages/lswq_spear.xml","lswq_spear")
MakeItemSkinDefaultImage("lswq_hat","images/inventoryimages/lswq_hat.xml","lswq_hat")
MakeItemSkin("lswq_spear","lswq_spear_silvery",
{
	basebuild = "lswq_spear",
	rarity = "Loyal",
	type = "item",
	name = "银色审判",
    atlas = "images/inventoryimages/lswq_spear_silvery.xml",
    image = "lswq_spear_silvery",
})

MakeItemSkin("lswq_hat","lswq_hat_silvery",
{
	basebuild = "lswq_hat",
	rarity = "Loyal",
	type = "item",
	name = "银色审判",
    atlas = "images/inventoryimages/lswq_hat_silvery.xml",
    image = "lswq_hat_silvery",
})


AddRecipe(
    "lswq_spear",
    {Ingredient("spear_wathgrithr", 1), Ingredient("orangegem", 3), Ingredient("lightninggoathorn", 5)},
    RECIPETABS.WAR,
    TECH.NONE,
    nil,
    nil,
    nil,
    nil,
	nil,
    --"valkyrie",
    "images/inventoryimages/lswq_spear.xml",
    "lswq_spear.tex"
)

AddRecipe(
    "lswq_hat",
    {Ingredient("wathgrithrhat", 1), Ingredient("reviver", 1)},
    RECIPETABS.WAR,
    TECH.NONE,
    nil,
    nil,
    nil,
    nil,
	nil,
    --"valkyrie",
    "images/inventoryimages/lswq_hat.xml",
    "lswq_hat.tex"
)

AddRecipe(
    "armorlswq",
    {Ingredient("petals", 10),Ingredient("bearger_fur", 3), Ingredient("reviver", 1),Ingredient("goose_feather", 10)},
    RECIPETABS.WAR,
    TECH.NONE,
    nil,
    nil,
    nil,
    nil,
	nil,
    --"valkyrie",
    "images/inventoryimages/armorlswq.xml",
    "armorlswq.tex"
)


AddStategraphPostInit(
    "wilson",
    function(sg)
        local old_CASTAOE = sg.actionhandlers[ACTIONS.CASTAOE].deststate
        sg.actionhandlers[ACTIONS.CASTAOE].deststate = function(inst, action)
            local weapon = action.invobject
            if weapon then
                if weapon:HasTag("lswq_spear") then
                    return "lswq_spear_elec_dash"
                end
            end
            return old_CASTAOE(inst, action)
        end
    end
)
AddStategraphPostInit(
    "wilson_client",
    function(sg)
        local old_CASTAOE = sg.actionhandlers[ACTIONS.CASTAOE].deststate
        sg.actionhandlers[ACTIONS.CASTAOE].deststate = function(inst, action)
            local weapon = action.invobject
            if weapon then
                if weapon:HasTag("lswq_spear") then
                    return "lswq_spear_elec_dash"
                end
            end
            return old_CASTAOE(inst, action)
        end
    end
)

local talkers = {
    "忏悔！",
    "你的神抛弃了你！",
    "在神的怒火下颤抖吧！",
    "我即是天罚，我即是清算！",
}

AddStategraphState(
    "wilson",
    State {
        name = "lswq_spear_elec_dash",
        tags = {"aoe", "doing", "busy", "nointerrupt", "nomorph","notalking"},
        onenter = function(inst)
            inst.components.locomotor:Stop()
            inst.AnimState:PlayAnimation("multithrust_yell")
        end,
        timeline = {
            TimeEvent(
                5 * FRAMES,
                function(inst)
                    local fire = SpawnPrefab("lswq_spear_elec_preparefx")
                    fire.entity:AddFollower()
                    fire.Follower:FollowSymbol(inst.GUID, "swap_object", 0, -110, 0)
                    inst.SoundEmitter:PlaySoundWithParams("dontstarve/rain/thunder_close", {intensity = 0.7})
                end
            ),
            TimeEvent(
                15 * FRAMES,
                function(inst)
                    inst.AnimState:PlayAnimation("atk_pre")
                    inst.SoundEmitter:PlaySound("dontstarve/wilson/attack_weapon")
                end
            ),

            TimeEvent(
                20 * FRAMES,
                function(inst)
                    inst.components.talker:Say(talkers[math.random(#talkers)])
                    inst:PerformBufferedAction()
                end
            ),
            TimeEvent(
                22 * FRAMES,
                function(inst)
                    inst.AnimState:PlayAnimation("atk", false)
                    inst.sg:GoToState("idle", true)
                end
            ),
        },
    }
)

AddStategraphState(
    "wilson_client",
    State {
        name = "lswq_spear_elec_dash",
        tags = {"aoe", "doing", "busy", "nointerrupt", "nomorph","notalking"},
        onenter = function(inst)
            inst.components.locomotor:Stop()
            inst.AnimState:PlayAnimation("multithrust_yell")
            inst:PerformPreviewBufferedAction()
        end,
        timeline = {
            TimeEvent(
                15 * FRAMES,
                function(inst)
                    inst.AnimState:PlayAnimation("atk_pre")
                    inst.AnimState:PushAnimation("atk", false)
                    inst.sg:GoToState("idle", true)
                end
            )
        },
        onexit = function(inst)
            inst:ClearBufferedAction()
        end
    }
)

AddModRPCHandler(
    "lswqrpc",
    "lswqrpc",
    function(inst)
        if inst:HasTag("playerghost") or (inst.components.health and inst.components.health:IsDead()) or  inst.sg:HasStateTag("dead") then
            return
        end
        if inst.lswqrpccdin then
            return
        end
        if not (inst.components.playercontroller and inst.components.playercontroller:IsEnabled()) then
            return
        end
		local armor = inst.components.inventory and inst.components.inventory:GetEquippedItem(EQUIPSLOTS.BODY)

		if armor and armor.prefab == "armorlswq" then
			if not armor.components.timer:TimerExists("armorlswq_cd") then
                inst.sg:GoToState("book")
				armor.components.timer:StartTimer("armorlswq_cd",600)
				local x,y,z = inst.Transform:GetWorldPosition()
				local ents = TheSim:FindEntities(x,0,z,32,{"player"}) 
				for k,v in pairs(ents) do 
					if v:IsValid() then 
                        v:DoTaskInTime(v:HasTag("playerghost") and 3 or 0,function()
                            if v.components.debuffable ~= nil and v.components.debuffable:IsEnabled() and
                            not (v.components.health ~= nil and v.components.health:IsDead()) and
                            not v:HasTag("playerghost")
                            then
                                v.components.debuffable:AddDebuff("armorlswqbuff", "armorlswqbuff")
                            end                               
                        end)
                        if v:HasTag("playerghost") then
						    v:PushEvent("respawnfromghost", { source = armor })
                        end
					end
				end
			else
				local lefttime  = math.ceil(armor.components.timer:GetTimeLeft("armorlswq_cd")) or 0
				inst.components.talker:Say("我的神力尚需恢复 剩余时间:"..lefttime.."秒")
			end

		elseif inst.components.talker then
			inst.components.talker:Say("需要装备瓦尔基里的神圣羽衣")
		end
        inst.lswqrpccdin = true
        inst:DoTaskInTime(
            0.2,
            function()
                inst.lswqrpccdin = false
            end
        )

        return true
    end
)
local function IsHUDScreen()
	local defaultscreen = false
	if TheFrontEnd:GetActiveScreen() and TheFrontEnd:GetActiveScreen().name and type(TheFrontEnd:GetActiveScreen().name) == "string" and TheFrontEnd:GetActiveScreen().name == "HUD" then
		defaultscreen = true
	end
	return defaultscreen
end

AddClassPostConstruct(
    "widgets/controls",
    function(self)
        self.inst:ListenForEvent(
            "onremove",
            function()
                if self.lswqhandler ~= nil then
                    self.lswqhandler:Remove()
                end
            end
        )
        if self.owner then
            self.lswqhandler =
                TheInput:AddKeyDownHandler(
                GetModConfigData('KEYKEYKEY'),
                function()
                    if not IsHUDScreen() then
                        return
                    end
                    SendModRPCToServer(MOD_RPC["lswqrpc"]["lswqrpc"])
                end
            )
        end
    end
)

local function goldnuggetfuel(inst)
	if not GLOBAL.TheWorld.ismastersim then
		return
	end
	
	inst:AddComponent("fuel")
	inst.components.fuel.fueltype = GLOBAL.FUELTYPE.GOLDNUGGET	-- assign fuel type
	inst.components.fuel.fuelvalue = GLOBAL.TUNING.LARGE_FUEL	-- assign fuel value, see tuning.lua
end

AddComponentPostInit("inventory",function(self)
	local old_ApplyDamage = self.ApplyDamage
	self.ApplyDamage = function(self,damage,attacker, weapon,...)
        if  self.inst.armorlswqbuff or self.inst.lswqhatfx then
            return 0
        end
		return old_ApplyDamage(self,damage,attacker, weapon,...)
	end
end)

AddPrefabPostInit("goldnugget", goldnuggetfuel)