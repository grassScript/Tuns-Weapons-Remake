-- Blasterix: energy blaster, 100 dmg per shot, 5s between shots
-- Version 1.0.2 addition

SWEP.PrintName = "Blasterix"
SWEP.Author = "GPT"
SWEP.Instructions = "ЛКМ — выстрел. 100 урона, но 5 секунд на перезарядку каждого выстрела."
SWEP.Category = "TUNS Weapons"

SWEP.Spawnable = true
SWEP.AdminSpawnable = true

-- Бесконечная энергия: задержку между выстрелами задаёт Primary.Delay
SWEP.Primary.ClipSize = -1
SWEP.Primary.DefaultClip = -1
SWEP.Primary.Automatic = false
SWEP.Primary.Ammo = "none"
SWEP.Primary.Delay = 5 -- 5 секунд на каждый выстрел
SWEP.Primary.Damage = 100
SWEP.Primary.Recoil = 3
SWEP.Primary.NumShots = 1
SWEP.Primary.Spread = 0.01
SWEP.Primary.Force = 10

SWEP.Secondary.ClipSize = -1
SWEP.Secondary.DefaultClip = -1
SWEP.Secondary.Automatic = false
SWEP.Secondary.Ammo = "None"

SWEP.Weight = 5
SWEP.DrawAmmo = false
SWEP.DrawCrosshair = true

SWEP.Slot = 2
SWEP.SlotPos = 5

SWEP.ViewModel = "models/weapons/c_irifle.mdl"
SWEP.WorldModel = "models/weapons/w_irifle.mdl"
SWEP.UseHands = true

function SWEP:Initialize()
    self:SetHoldType("ar2")
end

function SWEP:PrimaryAttack()
    if not self:CanPrimaryAttack() then return end

    local owner = self:GetOwner()
    if not IsValid(owner) then return end

    self:EmitSound("Weapon_AR2.Single")

    local bullet = {}
    bullet.Num = self.Primary.NumShots
    bullet.Src = owner:GetShootPos()
    bullet.Dir = owner:GetAimVector()
    bullet.Spread = Vector(self.Primary.Spread, self.Primary.Spread, 0)
    bullet.Tracer = 1
    bullet.TracerName = "GaussTracer"
    bullet.Force = self.Primary.Force
    bullet.Damage = self.Primary.Damage
    bullet.AmmoType = self.Primary.Ammo
    owner:FireBullets(bullet)

    self:ShootEffects()

    if owner.ViewPunch then
        owner:ViewPunch(Angle(-self.Primary.Recoil, 0, 0))
    end

    self:SetNextPrimaryFire(CurTime() + self.Primary.Delay)
end

function SWEP:Reload()
    -- Перезарядка не нужна: 5 секунд между выстрелами и есть перезарядка
end

function SWEP:SecondaryAttack()
    -- Нет вторичной атаки
end
