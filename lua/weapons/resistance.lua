-- Resistance: inject once (like Shield Injector), then passively absorbs ALL
-- impulse signals (knockback) applied to the player while active
-- Category "TUNS Swep", same as Shield Injector

SWEP.PrintName = "Resistance"
SWEP.Author = "GPT"
SWEP.Instructions = "ЛКМ — вживить. Абсолютно все импульсы (отбрасывание) на игрока поглощаются, пока эффект активен."
SWEP.Category = "TUNS Swep"

SWEP.Spawnable = true
SWEP.AdminSpawnable = true

SWEP.Primary.ClipSize = -1
SWEP.Primary.DefaultClip = -1
SWEP.Primary.Automatic = false
SWEP.Primary.Ammo = "none"

SWEP.Secondary.ClipSize = -1
SWEP.Secondary.DefaultClip = -1
SWEP.Secondary.Automatic = false
SWEP.Secondary.Ammo = "none"

SWEP.Weight = 1
SWEP.DrawAmmo = false
SWEP.DrawCrosshair = true

SWEP.Slot = 3
SWEP.SlotPos = 2

SWEP.ViewModel = "models/weapons/c_superphyscannon.mdl"
SWEP.WorldModel = "models/weapons/w_physics.mdl"
SWEP.UseHands = true

if SERVER then
    -- Не даём взять Resistance, если эффект уже активен
    hook.Add("PlayerCanPickupWeapon", "resistance_block", function(ply, wep)
        if IsValid(wep) and wep:GetClass() == "resistance" and ply.ResistanceActive then
            return false
        end
    end)
end

function SWEP:Initialize()
    self:SetHoldType("shotgun")
end

local function clearResistance(ply)
    ply.ResistanceActive = false
    hook.Remove("EntityTakeDamage", "resistance_" .. ply:EntIndex())
    hook.Remove("DoPlayerDeath", "resistance_death_" .. ply:EntIndex())
end

if SERVER then
    local function applyResistance(ply)
        ply.ResistanceActive = true

        -- Все импульсы от урона проходят через EntityTakeDamage —
        -- обнуляем силу урона полностью: никакого отбрасывания
        hook.Add("EntityTakeDamage", "resistance_" .. ply:EntIndex(), function(ent, dmginfo)
            if ent ~= ply or not ent:IsPlayer() then return end
            dmginfo:SetDamageForce(vector_origin)
        end)

        local deathHook = "resistance_death_" .. ply:EntIndex()
        hook.Add("DoPlayerDeath", deathHook, function(victim)
            if victim == ply then
                clearResistance(ply)
            end
        end)
    end

    function SWEP:PrimaryAttack()
        if not IsFirstTimePredicted() then return end
        local ply = self:GetOwner()
        if not IsValid(ply) then return end

        if ply.ResistanceActive then return end

        ply:ChatPrint("[Resistance] Импульсная защита активирована. Все отбрасывания поглощаются.")

        applyResistance(ply)

        -- Убираем оружие из инвентаря после активации, как Shield Injector
        ply:StripWeapon(self:GetClass())
    end
end

function SWEP:SecondaryAttack() end
function SWEP:Reload() end
function SWEP:Think() end

function SWEP:OnRemove()
    if not SERVER then return end
    local ply = self:GetOwner()
    if IsValid(ply) then
        clearResistance(ply)
    end
end

function SWEP:Holster()
    return true
end

function SWEP:ShouldDropOnDie()
    return false
end
