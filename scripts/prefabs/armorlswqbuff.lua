local function OnTick(inst, target)
    if target.components.health ~= nil and
        not target.components.health:IsDead() and
        not target:HasTag("playerghost") then
        target.components.health:DoDelta(5, nil, "jellybean")
    else
        inst.components.debuff:Stop()
    end
end

local function removebufffx(inst)
	if inst.armorlswq_fx  then
		inst.armorlswq_fx:Remove()
		inst.armorlswq_fx = nil
	end
end

local function addbufffx(inst)
    if not inst.armorlswq_fx then
        inst.armorlswq_fx = SpawnPrefab("armorlswq_fx")
        inst.armorlswq_fx.entity:SetParent(inst.entity)
        --inst.armorlswq_fx.Transform:SetPosition(0, 0.2, 0)
    end
end

local function OnAttached(inst, target)
    inst.entity:SetParent(target.entity)
    inst.Transform:SetPosition(0, 0, 0) --in case of loading
    --inst.task = inst:DoPeriodicTask(TUNING.JELLYBEAN_TICK_RATE, OnTick, nil, target)
    --target.armorlswqbuff = true
    if target.components.locomotor then
        target.components.locomotor:SetExternalSpeedMultiplier(target, "armorlswqbuff", 1.5)
    end
    addbufffx(target)

    inst:ListenForEvent("death", function()
        inst.components.debuff:Stop()
    end, target)
end

local function OnTimerDone(inst, data)
    if data.name == "regenover" then
        inst.components.debuff:Stop()
    end
end

local function OnExtended(inst, target)
    inst.components.timer:StopTimer("regenover")
    inst.components.timer:StartTimer("regenover", 5)
    --inst.task:Cancel()
    --inst.task = inst:DoPeriodicTask(TUNING.JELLYBEAN_TICK_RATE, OnTick, nil, target)
end

local function OnRemove(inst,target)
    if target then
        if target.components.locomotor ~= nil then
            target.components.locomotor:RemoveExternalSpeedMultiplier(target, "armorlswqbuff")
        end
        removebufffx(target)
    end
    inst:Remove()
end

local function fn()
    local inst = CreateEntity()

    if not TheWorld.ismastersim then
        inst:DoTaskInTime(0, inst.Remove)

        return inst
    end

    inst.entity:AddTransform()

    inst.entity:Hide()
    inst.persists = false

    inst:AddTag("CLASSIFIED")

    inst:AddComponent("debuff")
    inst.components.debuff:SetAttachedFn(OnAttached)
    inst.components.debuff:SetDetachedFn(OnRemove)
    inst.components.debuff:SetExtendedFn(OnExtended)
    inst.components.debuff.keepondespawn = true

    inst:AddComponent("timer")
    inst.components.timer:StartTimer("regenover", 5)
    inst:ListenForEvent("timerdone", OnTimerDone)

    return inst
end

return Prefab("armorlswqbuff", fn)
