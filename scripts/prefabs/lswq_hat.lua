
local assets=
{
	Asset("ANIM", "anim/lswq_hat.zip"),
    Asset("ANIM", "anim/lswq_hat_silvery.zip"),

	Asset("IMAGE", "images/inventoryimages/lswq_hat.tex"),
	Asset("ATLAS", "images/inventoryimages/lswq_hat.xml"),
	Asset("IMAGE", "images/inventoryimages/lswq_hat_silvery.tex"),
	Asset("ATLAS", "images/inventoryimages/lswq_hat_silvery.xml"),
}

local prefabs =
{
}

local function removefx(inst)
    if inst._lswqfx ~= nil then
        inst._lswqfx:kill_fx()
        inst._lswqfx = nil
    end
end

local function ruinshat_oncooldown(inst)
    removefx(inst)
    inst.lswqhatfx = false
end

local function addfx(inst)
    inst:AddTag("forcefield")
    if inst._lswqfx ~= nil then
        inst._lswqfx:kill_fx()
    end
    inst._lswqfx = SpawnPrefab("forcefieldfx")
    inst._lswqfx.entity:SetParent(inst.entity)
    inst._lswqfx.Transform:SetPosition(0, 0.2, 0)
    inst.lswqhatfx = true

    if inst._lswqfxtask ~= nil then
        inst._lswqfxtask:Cancel()
    end
    inst._lswqfxtask = inst:DoTaskInTime(2, ruinshat_oncooldown)
end

local function huifu(inst)
    local owner  = inst.components.inventoryitem.owner
    if owner and inst.components.armor and owner.components.combat then
        if owner.components.singinginspiration and owner.components.singinginspiration.current > 0 then
            inst.components.armor:SetCondition(inst.components.armor.condition + 3)
        end
        if owner.components.sanity then
            local per = owner.components.sanity:GetPercent()
            if per >= 0.8 then
                inst.components.armor.absorb_percent = 0.65
                owner.components.combat.externaldamagemultipliers:SetModifier("lswq_hat", 1.2)
            elseif per >= 0.6 then
                inst.components.armor.absorb_percent = 0.65
                owner.components.combat.externaldamagemultipliers:SetModifier("lswq_hat", 1.1)
            elseif per >= 0.4 then
                inst.components.armor.absorb_percent = 0.8
                owner.components.combat.externaldamagemultipliers:SetModifier("lswq_hat", 1.3)
            else
                owner.components.combat.externaldamagemultipliers:RemoveModifier("lswq_hat")
                inst.components.armor.absorb_percent = 0.95
            end
        end
    end
end

local fname  = "lswq_hat"

local function opentop_onequip(inst, owner)
    local skin_build = inst:GetSkinBuild()
    if skin_build ~= nil then
        owner:PushEvent("equipskinneditem", inst:GetSkinName())
        owner.AnimState:OverrideItemSkinSymbol("swap_hat", skin_build, "swap_hat", inst.GUID, fname)
    else
        owner.AnimState:OverrideSymbol("swap_hat", fname, "swap_hat")
    end

    owner.AnimState:Show("HAT")
    owner.AnimState:Hide("HAIR_HAT")
    owner.AnimState:Show("HAIR_NOHAT")
    owner.AnimState:Show("HAIR")

    if owner:HasTag("player") then
        owner.AnimState:Show("HEAD")
        owner.AnimState:Hide("HEAD_HAT")
    end

    if owner.components.health ~= nil then
        inst.healthRedirect_old = owner.components.health.redirect
        owner.components.health.redirect = function(ow, amount, overtime, cause, ignore_invincible, afflicter, ignore_absorb)
            local self = ow.components.health

            if not ignore_invincible and (self:IsInvincible() or self.inst.is_teleporting) then
                return true
            elseif amount < 0 then
                if not ignore_absorb then
                    amount = amount * math.clamp(1 - (self.playerabsorb ~= 0 and afflicter ~= nil and afflicter:HasTag("player") and self.playerabsorb + self.absorb or self.absorb), 0, 1) * math.clamp(1 - self.externalabsorbmodifiers:Get(), 0, 1)
                end
                if self.currenthealth > 0 and self.currenthealth + amount <= 0 then
                    inst:Remove()
                    addfx(ow)
                    return true
                end
            end
            if inst.healthRedirect_old ~= nil then
                return inst.healthRedirect_old(ow, amount, overtime, cause, ignore_invincible, afflicter, ignore_absorb)
            end
        end
    end
    if inst.huifutask then
        inst.huifutask:Cancel()
    end
    inst.huifutask = inst:DoPeriodicTask(0.33,huifu,0.33)
end

local function onunequip(inst, owner)
    local skin_build = inst:GetSkinBuild()
    if skin_build ~= nil then
        owner:PushEvent("unequipskinneditem", inst:GetSkinName())
    end

    owner.AnimState:ClearOverrideSymbol("swap_hat")
    owner.AnimState:Hide("HAT")
    owner.AnimState:Hide("HAIR_HAT")
    owner.AnimState:Show("HAIR_NOHAT")
    owner.AnimState:Show("HAIR")

    if owner:HasTag("player") then
        owner.AnimState:Show("HEAD")
        owner.AnimState:Hide("HEAD_HAT")
    end
    if owner.components.health ~= nil then
        owner.components.health.redirect = inst.healthRedirect_old
    end
    inst.healthRedirect_old = nil
    if inst.huifutask then
        inst.huifutask:Cancel()
        inst.huifutask = nil
    end
end

local function finished(inst)
    inst:Remove()
end

local function ontakefuel(inst)
	inst.components.armor:SetCondition(inst.components.armor.condition + 200)
end

local function fn(Sim)
	local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddNetwork()

    MakeInventoryPhysics(inst)

    inst.AnimState:SetBank("lswq_hat")
    inst.AnimState:SetBuild("lswq_hat")
    inst.AnimState:PlayAnimation("anim")

    --inst:AddTag("hide_percentage")
	inst:AddTag("hat")
    	
    MakeInventoryFloatable(inst)

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end
    --inst._opentop_onequip = opentop_onequip
    --inst._onequip = _onequip
    inst:AddComponent("inspectable")
		
    inst:AddComponent("inventoryitem")
    inst.components.inventoryitem.atlasname = "images/inventoryimages/lswq_hat.xml"
       
    inst:AddComponent("armor")
    inst.components.armor:InitCondition(2000, 0.65)
    --inst.components.armor.indestructible = true

    inst:AddComponent("waterproofer")
    inst.components.waterproofer:SetEffectiveness(TUNING.WATERPROOFNESS_SMALL)

	inst:AddComponent("equippable")
    --inst.components.equippable.restrictedtag = "valkyrie"
	inst.components.equippable.equipslot = EQUIPSLOTS.HEAD
	inst.components.equippable:SetOnEquip(opentop_onequip)
    inst.components.equippable:SetOnUnequip( onunequip)
	
	inst:AddComponent("fueled")
    inst.components.fueled.fueltype = FUELTYPE.GOLDNUGGET
    inst.components.fueled:SetTakeFuelFn(ontakefuel)
    inst.components.fueled.accepting = true
    
    inst:AddComponent("tradable")
	
	MakeHauntableLaunch(inst)
    return inst
end 
    
return Prefab( "lswq_hat", fn, assets, prefabs) 