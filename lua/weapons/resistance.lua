-- Resistance: passive device, suppresses impulse (knockback) on the player 3x while held
-- Category "Tuns SWEP" per request

SWEP.PrintName = "Resistance"
SWEP.Author = "GPT"
SWEP.Instructions = "Держите в руках — импульсы (отбрасывание) на игрока подавляются в 3 раза."
SWEP.Category = "Tuns SWEP"

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
SWEP.DrawCrosshair = false

SWEP.Slot = 4
SWEP.SlotPos = 1

SWEP.ViewModel = "models/weapons/c_slam.mdl"
SWEP.WorldModel = "models/items/battery.mdl"
SWEP.UseHands = true

function SWEP:Initialize()
    self:SetHoldType("slam")
end

if SERVER then
    -- Все импульсы от урона проходят через EntityTakeDamage —
    -- делим damage force на 3, пока оружие в руках
    local function hookID(self)
        return "TunsResistance_" .. self:EntIndex()
    end

    function SWEP:Deploy()
        local owner = self:GetOwner()
        local id = hookID(self)
        hook.Add("EntityTakeDamage", id, function(ent, dmginfo)
            if ent ~= owner or not ent:IsPlayer() then return end
            dmginfo:SetDamageForce(dmginfo:GetDamageForce() / 3)
        end)
        return true
    end

    function SWEP:Holster()
        hook.Remove("EntityTakeDamage", hookID(self))
        return true
    end

    function SWEP:OnRemove()
        hook.Remove("EntityTakeDamage", hookID(self))
    end
end

function SWEP:PrimaryAttack()
    -- Пассивное устройство, не стреляет
end

function SWEP:SecondaryAttack()
    -- Нет вторичной атаки
end

function SWEP:Reload()
    -- Нет перезарядки
end
