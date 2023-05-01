local assets =
{

    Asset("IMAGE","images/inventoryimages/lswq_spear.tex"),
    Asset("ATLAS","images/inventoryimages/lswq_spear.xml"),
    Asset("IMAGE","images/inventoryimages/lswq_spear_silvery.tex"),
    Asset("ATLAS","images/inventoryimages/lswq_spear_silvery.xml"),
    Asset("ANIM", "anim/lswq_spear.zip"),
    Asset("ANIM", "anim/lswq_spear_silvery.zip"),
    Asset("ANIM", "anim/floating_items.zip"),
}

local assets_lightning = {
    Asset("ANIM", "anim/lightning.zip"),
}

local assets_shockfx = {
    Asset("ANIM", "anim/lavaarena_hammer_attack_fx.zip"),
}

local assets_preparefx = {
    Asset("ANIM", "anim/lavaarena_creature_teleport.zip"),
}

local function ReticuleTargetFn()
    local player = ThePlayer
    local ground = TheWorld.Map
    local pos = Vector3()
    for r = 5, 0, -.25 do
        pos.x, pos.y, pos.z = player.entity:LocalToWorldSpace(r, 0, 0)
        --if ground:IsPassableAtPoint(pos:Get()) and not ground:IsGroundTargetBlocked(pos) then
		if  not ground:IsGroundTargetBlocked(pos) then
            return pos
        end
    end
    return pos
end

local function DoDivineWrath(inst,doer,target)
    SpawnAt("lswq_spear_lightning",target)
    if target.components.health and not target.components.health:IsDead() then 
        if doer and doer.components.singinginspiration and  doer.components.singinginspiration.current > 0 then
            target.components.health:DoDelta(-math.ceil(doer.components.singinginspiration.current),nil,doer.prefab,false,nil,true)
            target:PushEvent("attacked",{attacker = inst,damage = 0})
            if target.sg and target.sg:HasState("hit") and not target.sg:HasStateTag("noouthit")then 
                target.sg:GoToState("hit")
            end
        end
    end
end

local nottags = {'FX', 'NOCLICK', 'INLIMBO', 'playerghost','wall',"companion","abigail"}
if not TheNet:GetPVPEnabled() then
	table.insert(nottags, "player")
end


local function onequip(inst, owner)
    local skin_build = inst:GetSkinBuild()
    if skin_build ~= nil then
        owner:PushEvent("equipskinneditem", inst:GetSkinName())
        owner.AnimState:OverrideItemSkinSymbol("swap_object", skin_build, "lswq_spear", inst.GUID, "lswq_spear")
    else
        owner.AnimState:OverrideSymbol("swap_object", "lswq_spear", "lswq_spear")
    end
    --owner.AnimState:OverrideSymbol("swap_object", "lswq_spear", "swap")

    owner.AnimState:Show("ARM_carry")
    owner.AnimState:Hide("ARM_normal")

    if owner.components.singinginspiration then
        if inst.listenforhit then
            inst:RemoveEventCallback("onhitother", inst.blood,owner)
            inst.listenforhit = false
        end
        inst:ListenForEvent("onhitother",inst.blood,owner)
        inst.listenforhit = true
    end
end

local function onunequip(inst, owner)
    owner.AnimState:Hide("ARM_carry")
    owner.AnimState:Show("ARM_normal")
    local skin_build = inst:GetSkinBuild()
    if skin_build ~= nil then
        owner:PushEvent("unequipskinneditem", inst:GetSkinName())
    end
	inst.AttackNum = 0
	inst.LastAttackTarget = nil
    if inst.listenforhit then
        inst:RemoveEventCallback("onhitother", inst.blood,owner)
        inst.listenforhit = false
    end
end

local function OnAttack(inst,owner,target)

    inst.components.rechargeable:DoUpdate(1)

    if target ~= inst.LastAttackTarget then
        inst.AttackNum = 1
    else
        inst.AttackNum = inst.AttackNum + 1
        if inst.AttackNum >= 5 then 
            DoDivineWrath(inst,owner,target)
            inst.AttackNum = 0
        end
    end
    inst.LastAttackTarget = target 
end

local function spawntornado(inst, doer, pos)
    local max = 4 
    local current = 0
    SpawnAt("lswq_spear_lightning",doer)
    inst:StartThread(function()
        while true do 
            local ents = TheSim:FindEntities(pos.x,0,pos.z,7,{"_combat","_health"},nottags)
            for k,v in pairs(ents) do 
                if v ~= doer and v:IsValid() and  v.components.combat and v.components.health  and not v.components.health:IsDead()  and doer.components.combat:CanTarget(v) and not doer.components.combat:IsAlly(v) then 
                    SpawnAt("lswq_spear_elec_preparefx",v)
                    v.components.combat:GetAttacked(doer,doer.components.combat:CalcDamage(v, inst)*2)
                    if v.components.health:IsDead() then
                        max = max + 1
                    end
                    if doer:IsValid() and doer.components.singinginspiration then
                        doer.components.singinginspiration:DoDelta(3)
                    end
					
					--饥饿损耗
                    if doer:IsValid() and doer.components.hunger then
						doer.components.hunger:DoDelta(-10)
                    end
                    break
                end
            end    
            current = current +1
            if current > max then
                return
            end
            Sleep(0.35) 
        end
    end)
    inst.components.rechargeable:StartRecharging()
end

local function oncharg(inst)
    --inst.components.spellcaster:SetSpellFn(nil)
end

local function donecharg(inst)
    --inst.components.spellcaster:SetSpellFn(spawntornado)
end

local function fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddNetwork()
    inst.entity:AddMiniMapEntity()

    MakeInventoryPhysics(inst)
    inst.AnimState:SetBank("lswq_spear")
    inst.AnimState:SetBuild("lswq_spear")
    inst.AnimState:PlayAnimation("idle")

    inst:AddTag("sharp")
    inst:AddTag("pointy")
    inst:AddTag("lswq_spear")
    inst:AddTag("rechargeable")

    inst:AddTag("weapon")

    inst:AddComponent("aoetargeting")
    inst.components.aoetargeting:SetRange(16)
    inst.components.aoetargeting.reticule.reticuleprefab = "lswq_spear_re"
    inst.components.aoetargeting.reticule.pingprefab = "lswq_spear_re2"
    inst.components.aoetargeting.reticule.targetfn = ReticuleTargetFn
    inst.components.aoetargeting.reticule.validcolour = { 1, .75, 0, 1 }
    inst.components.aoetargeting.reticule.invalidcolour = { .5, 0, 0, 1 }
    inst.components.aoetargeting.reticule.ease = true
    inst.components.aoetargeting.reticule.mouseenabled = true   
	inst.components.aoetargeting.alwaysvalid = true 

    inst.spelltype = "LSWQ"

    MakeInventoryFloatable(inst, "med", 0.1, {0.7, 0.5, 0.7}, true, -9, {sym_build = "lswq_spear"})

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst.AttackNum = 0
    inst.LastAttackTarget = nil 

    inst.blood =  function(owner,data)
        if data and data.weapon == inst and owner.components.singinginspiration then
            local delta = (data and data.damage  or 0 ) * 0.01*(owner.components.singinginspiration.current/20)
            if owner.components.health ~= nil and owner.components.health:GetPercent() < 1 then
                owner.components.health:DoDelta(delta, false)
            end
        end
    end

    inst:AddComponent("timer")

    inst:AddComponent("weapon")
    inst.components.weapon:SetDamage(55)
    inst.components.weapon:SetOnAttack(OnAttack)

    inst:AddComponent("inspectable")

    inst:AddComponent("inventoryitem")
    --inst.components.inventoryitem.imagename = "spear_wathgrithr"
    inst.components.inventoryitem.atlasname = "images/inventoryimages/lswq_spear.xml"

    inst:AddComponent("equippable")
	--inst.components.equippable.restrictedtag = "valkyrie"
    inst.components.equippable.insulated = true
    inst.components.equippable:SetOnEquip(onequip)
    inst.components.equippable:SetOnUnequip(onunequip)

    --inst:AddComponent("spellcaster")
    --inst.components.spellcaster.canuseontargets = true
    --inst.components.spellcaster.canonlyuseonlocomotorspvp = true
    --inst.components.spellcaster.canonlyuseoncombat = true
    --inst.components.spellcaster:SetSpellFn(spawntornado)
    --inst.components.spellcaster.CanCast = function(self,doer, target, pos) return true end

	inst:AddComponent("lswq_aoespell")
    inst.components.aoespell = inst.components.lswq_aoespell
	inst.components.aoespell:SetSpellFn(spawntornado)
	inst.components.aoespell.ispassableatallpoints = true
	inst:RegisterComponentActions("aoespell")

    inst:AddComponent("lswq_rechargeable")
    inst.components.rechargeable = inst.components.lswq_rechargeable
	--冷却CD
    inst.components.rechargeable:SetRechargeTime(10)
    inst.components.rechargeable.rechargingfn = oncharg
    inst.components.rechargeable.stoprechargfn = donecharg
    inst:RegisterComponentActions("rechargeable")


    MakeHauntableLaunch(inst)

    return inst
end

----------------------------------------------------------------------------------------------

local function PlayLightningAnim(pos)
    local inst = CreateEntity()

    inst:AddTag("FX")
    --[[Non-networked entity]]
    inst.entity:SetCanSleep(false)
    inst.persists = false

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddLight()

    inst.Transform:SetPosition(pos:Get())
    inst.Transform:SetScale(2, 2, 2)

    inst.AnimState:SetBloomEffectHandle("shaders/anim.ksh")
    inst.AnimState:SetLightOverride(1)
    -- inst.AnimState:SetSortOrder(2)
    inst.AnimState:SetBank("lightning")
    inst.AnimState:SetBuild("lightning")
    inst.AnimState:PlayAnimation("anim")
    
    
    inst:ListenForEvent("animover", inst.Remove)
end

local function PlayThunderSound(pos)
    local inst = CreateEntity()

    --[[Non-networked entity]]

    inst.entity:AddTransform()
    inst.entity:AddSoundEmitter()

    inst.Transform:SetPosition(pos:Get())
    inst.SoundEmitter:PlaySoundWithParams("dontstarve/rain/thunder_close", {intensity= 0.7})
    inst:Remove()
end

local function StartFX(proxy)
    TheWorld:PushEvent("screenflash", .5)

    local pos = Vector3(proxy.Transform:GetWorldPosition())
    PlayLightningAnim(pos)

    --Dedicated server does not need to spawn the local fx
    --(except red_lightning anim since it affects lighting)
    if TheNet:IsDedicated() then
        return
    end

    local pos0 = Vector3(TheFocalPoint.Transform:GetWorldPosition())
    local diff = pos - pos0
    local distsq = diff:LengthSq()
    local minsounddist = 10
    local normpos = pos
    if distsq > minsounddist * minsounddist then
        --Sound needs to be played closer to us if red_lightning is too far from player
        local normdiff = diff * (minsounddist / math.sqrt(distsq))
        normpos = pos0 + normdiff
    end

    if ThePlayer ~= nil then
        ThePlayer:ShakeCamera(CAMERASHAKE.FULL, .7, .02, .5, proxy, 40)
    end
    PlayThunderSound(normpos)
end

local function lightningfn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddNetwork()

    inst:AddTag("FX")

    --Delay one frame so that we are positioned properly before starting the effect
    --or in case we are about to be removed
    inst:DoTaskInTime(0, StartFX)

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst.entity:SetCanSleep(false)
    inst.persists = false
    inst:DoTaskInTime(1, inst.Remove)

    return inst
end
-------------------------------------------------------------------------------------

--------------------------------------------------------------------------------

local function shockfxhitfn()
    local inst = CreateEntity()
    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddSoundEmitter()
    inst.entity:AddNetwork()

    inst.AnimState:SetBank("lavaarena_hammer_attack_fx")
    inst.AnimState:SetBuild("lavaarena_hammer_attack_fx")
    inst.AnimState:PlayAnimation("crackle_hit")
    -- inst.AnimState:SetMultColour(14/255,192/255,255/255,1)
    inst.AnimState:SetLightOverride(1)
    -- inst.AnimState:SetSortOrder(2)
    
    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst.persists = false
    
    inst:ListenForEvent("animover",inst.Remove)
    
    return inst
end

local function shockfxfn()
    local inst = CreateEntity()
    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddSoundEmitter()
    inst.entity:AddNetwork()

    inst.AnimState:SetBank("lavaarena_hammer_attack_fx")
    inst.AnimState:SetBuild("lavaarena_hammer_attack_fx")
    inst.AnimState:PlayAnimation("crackle_loop",true)
    inst.AnimState:SetLightOverride(1)

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst.persists = false
    
    inst.KillFX = function(self)
        self.AnimState:PushAnimation("crackle_pst",false)
        self:ListenForEvent("animover", function() 
            if self.AnimState:IsCurrentAnimation("crackle_pst") then
                self:Remove()
            end
        end) 
    end
    
    return inst
end

-----------------------------------------------------------------------------
local function preparefxfn()
    local inst = CreateEntity()
    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddNetwork()

    inst.AnimState:SetBank("lavaarena_creature_teleport")
    inst.AnimState:SetBuild("lavaarena_creature_teleport")
    inst.AnimState:PlayAnimation("spawn_medium")

    inst.AnimState:HideSymbol("blast")
    inst.AnimState:HideSymbol("smoke1")
    inst.AnimState:HideSymbol("smoke3")

    inst.AnimState:SetLightOverride(1)
    -- inst.AnimState:SetSortOrder(2)

    -- inst.AnimState:SetMultColour(50/255,195/255,215/255,1)

    -- inst.AnimState:SetDeltaTimeMultiplier(1.1)

    inst.Transform:SetScale(1.5,1.5,1.5)
    
    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst.persists = false
    
    inst:ListenForEvent("animover",inst.Remove)
    inst:DoTaskInTime(9 * FRAMES,inst.Remove)

    
    
    return inst
end

local function makeaoe(name, fx, size)
    local function fn()
        local inst = SpawnPrefab(fx)
        inst.AnimState:SetScale(size, size)
        return inst
    end

    return Prefab(name, fn)
end

return Prefab("lswq_spear", fn, assets),
    Prefab("lswq_spear_lightning",lightningfn,assets_lightning),
    Prefab("lswq_spear_elec_shockfx_hit",shockfxhitfn,assets_shockfx),
    Prefab("lswq_spear_elec_shockfx",shockfxfn,assets_shockfx),
    Prefab("lswq_spear_elec_preparefx",preparefxfn,assets_preparefx),
    makeaoe("lswq_spear_re", "reticuleaoe", 2.6),
    makeaoe("lswq_spear_re2", "reticuleaoeping", 2.6)