-- Verity: рофл-оружие, ничего не делает
-- Version 1.0.2 addition

SWEP.PrintName = "Verity"
SWEP.Author = "GPT"
SWEP.Instructions = "Абсолютно ничего не делает. Просто она."
SWEP.Category = "TUNS Weapons"

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

SWEP.Slot = 5
SWEP.SlotPos = 1

SWEP.ViewModel = "models/weapons/c_slam.mdl"
SWEP.WorldModel = "models/weapons/w_slam.mdl"
SWEP.UseHands = true

SWEP.WepSelectIcon = Material("tunsweapons/verity.vtf")

function SWEP:Initialize()
    self:SetHoldType("normal")
end

function SWEP:PrimaryAttack()
    -- Ничего
end

function SWEP:SecondaryAttack()
    -- Ничего
end

function SWEP:Reload()
    -- Ничего
end

if CLIENT then
    -- Иконка verity.jpg в HUD слоте и в спавнменю
    function SWEP:DrawWeaponSelection(x, y, wide, tall, alpha)
        if not self.WepSelectIcon then return end
        surface.SetDrawColor(255, 255, 255, alpha)
        surface.SetMaterial(self.WepSelectIcon)
        local size = math.min(wide, tall)
        surface.DrawTexturedRect(x + (wide - size) / 2, y + (tall - size) / 2, size, size)
    end
end
