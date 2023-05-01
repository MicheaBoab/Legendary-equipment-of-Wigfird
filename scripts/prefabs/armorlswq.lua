local assets =
{
    Asset("ANIM", "anim/armorlswq.zip"),
	Asset("IMAGE", "images/inventoryimages/armorlswq.tex"),
	Asset("ATLAS", "images/inventoryimages/armorlswq.xml"),
}

local fxassets =
{
    Asset("ANIM", "anim/lavaarena_battlestandard.zip"),
}

local function OnBlocked(owner) 
    owner.SoundEmitter:PlaySound("dontstarve/wilson/hit_marble")
end

local function huifu(inst)
    local owner  = inst.components.inventoryitem.owner
	if owner and inst.components.armor and owner.components.combat then
        if owner.components.singinginspiration and owner.components.singinginspiration.current > 0 then
            inst.components.armor:SetCondition(inst.components.armor.condition + 3)
        end
	end
    if owner and owner.components.singinginspiration then
        local songs = #owner.components.singinginspiration.active_songs
        inst.components.equippable.walkspeedmult = 1.05 + 0.05*songs
        if owner.components.combat ~= nil then
            owner.components.combat.externaldamagemultipliers:SetModifier(inst, 1.1 + 0.05*songs)
        end
        if songs > 0 and inst.components.armor then
            inst.components.armor:SetCondition(inst.components.armor.condition + 10*songs)
        end
    end
end

local function onequip(inst, owner) 
    local skin_build = inst:GetSkinBuild()
    if skin_build ~= nil then
        owner:PushEvent("equipskinneditem", inst:GetSkinName())
        owner.AnimState:OverrideItemSkinSymbol("swap_body", skin_build, "swap_body", inst.GUID, "armorlswq")
    else
		owner.AnimState:OverrideSymbol("swap_body", "armorlswq", "swap_body")
    end
	if owner.components.combat ~= nil then
		owner.components.combat.externaldamagemultipliers:SetModifier(inst, 1.1)
	end
    if owner.components.sanity ~= nil then
        owner.components.sanity.neg_aura_modifiers:SetModifier(inst, TUNING.BATTLESONG_NEG_SANITY_AURA_MOD)
    end

    if inst.huifutask then
        inst.huifutask:Cancel()
    end
    inst.huifutask = inst:DoPeriodicTask(1,huifu)

    inst:ListenForEvent("blocked", OnBlocked, owner)
end

local function onunequip(inst, owner) 
    owner.AnimState:ClearOverrideSymbol("swap_body")
    inst:RemoveEventCallback("blocked", OnBlocked, owner)
	
    if inst.huifutask then
        inst.huifutask:Cancel()
        inst.huifutask = nil
    end
    inst.components.equippable.walkspeedmult = 1.05

	if owner.components.combat ~= nil then
		owner.components.combat.externaldamagemultipliers:RemoveModifier(inst)
	end
    --if owner.components.sanity ~= nil then
    --    owner.components.sanity.neg_aura_modifiers:RemoveModifier(inst)
    --end
    local skin_build = inst:GetSkinBuild()
    if skin_build ~= nil then
        owner:PushEvent("unequipskinneditem", inst:GetSkinName())
    end
end

local function ontakefuel(inst)
	inst.components.armor:SetCondition(inst.components.armor.condition + 200)
end

local function fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddNetwork()

    MakeInventoryPhysics(inst)

    inst.AnimState:SetBank("armorlswq")
    inst.AnimState:SetBuild("armorlswq")
    inst.AnimState:PlayAnimation("anim")

    inst:AddTag("marble")
    --inst:AddTag("hide_percentage")

    inst.foleysound = "dontstarve/movement/foley/marblearmour"

    MakeInventoryFloatable(inst, "small", 0.2, 0.80)

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst:AddComponent("inspectable")

    inst:AddComponent("inventoryitem")
    inst.components.inventoryitem.atlasname = "images/inventoryimages/armorlswq.xml"

    inst:AddComponent("armor")
    inst.components.armor:InitCondition(3000, 0.75)
    --inst.components.armor.indestructible = true

    inst:AddComponent("timer")
	
	inst:AddComponent("fueled")
    inst.components.fueled.fueltype = FUELTYPE.GOLDNUGGET
    inst.components.fueled:SetTakeFuelFn(ontakefuel)
    inst.components.fueled.accepting = true
	

    inst:AddComponent("equippable")
    --inst.components.equippable.restrictedtag = "valkyrie"
    inst.components.equippable.equipslot = EQUIPSLOTS.BODY

    inst.components.equippable:SetOnEquip(onequip)
    inst.components.equippable:SetOnUnequip(onunequip)
    inst.components.equippable.walkspeedmult = 1.05

    MakeHauntableLaunch(inst)

    return inst
end

local function fxfn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddNetwork()
    inst.entity:AddAnimState()
    inst:AddTag("FX")
    inst.entity:SetCanSleep(false)
    
    inst.AnimState:SetBank("lavaarena_battlestandard")
    inst.AnimState:SetBuild("lavaarena_battlestandard")
    inst.AnimState:PlayAnimation("attack_fx3",true)
    inst.AnimState:SetFinalOffset(-1)
    inst.AnimState:SetOrientation( ANIM_ORIENTATION.OnGround )
    inst.AnimState:SetLayer( LAYER_BACKGROUND )
    inst.AnimState:SetSortOrder( 3 )

    inst.entity:SetPristine()
    if not TheWorld.ismastersim then
        return inst
    end
    inst.persists = false
    return inst
end

return Prefab("armorlswq", fn, assets),Prefab("armorlswq_fx", fxfn, fxassets)
