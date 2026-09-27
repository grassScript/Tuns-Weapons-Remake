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

-- Базовый CanPrimaryAttack молча блокирует выстрел при Ammo = "none" и ClipSize = -1
function SWEP:CanPrimaryAttack()
    return true
end

function SWEP:Initialize()
    self:SetHoldType("ar2")
end

function SWEP:PrimaryAttack()
    if not self:CanPrimaryAttack() then return end

    local owner = self:GetOwner()
    if not IsValid(owner) then return end

    local shootPos = owner:GetShootPos()
    local aim = owner:GetAimVector()

    self:EmitSound("Weapon_AR2.Single")

    local bullet = {}
    bullet.Num = self.Primary.NumShots
    bullet.Src = shootPos
    bullet.Dir = aim
    bullet.Spread = Vector(self.Primary.Spread, self.Primary.Spread, 0)
    bullet.Tracer = 1
    bullet.TracerName = "GaussTracer"
    bullet.Force = self.Primary.Force
    bullet.Damage = self.Primary.Damage
    bullet.AmmoType = self.Primary.Ammo

    if SERVER then
        -- Энергетический всплеск у дула (эффект энергошара AR2)
        local muzzleFx = EffectData()
        muzzleFx:SetOrigin(shootPos + aim * 40)
        util.Effect("cball_explode", muzzleFx)

        -- Электро-разряд вместо обычного выстрела
        sound.Play("ambient/levels/labs/electric_explosion4.wav", shootPos, 100, 90, 1)

        util.ScreenShake(shootPos, 8, 20, 0.5, 400)

        bullet.Callback = function(att, tr, dmg)
            if tr.Hit and not tr.HitSky then
                local impactFx = EffectData()
                impactFx:SetOrigin(tr.HitPos)
                impactFx:SetNormal(tr.HitNormal)
                util.Effect("cball_explode", impactFx)
            end
        end
    end

    owner:FireBullets(bullet)

    self:ShootEffects()

    if owner.ViewPunch then
        owner:ViewPunch(Angle(-self.Primary.Recoil, math.Rand(-1, 1), 0))
    end

    self:SetNextPrimaryFire(CurTime() + self.Primary.Delay)
end

function SWEP:Reload()
    -- Перезарядка не нужна: 5 секунд между выстрелами и есть перезарядка
end

function SWEP:SecondaryAttack()
    -- Нет вторичной атаки
end

if CLIENT then
    local CHARGE_TIME = 5

    -- HUD-полоса: сколько осталось до следующего выстрела
    function SWEP:DrawHUD()
        local owner = self:GetOwner()
        if not IsValid(owner) then return end

        local frac = 1 - math.Clamp((self:GetNextPrimaryFire() - CurTime()) / CHARGE_TIME, 0, 1)
        local charging = frac < 1

        surface.SetFont("TargetBB")
        local w = 200
        local h = 14
        local x = (ScrW() - w) / 2
        local y = ScrH() / 2 + 60

        -- фон
        surface.SetDrawColor(0, 0, 0, 150)
        surface.DrawRect(x - 2, y - 2, w + 4, h + 4)

        -- заполнение: синее заряжается, зелёное = готово
        if charging then
            surface.SetDrawColor(0, 130, 255, 220)
        else
            surface.SetDrawColor(0, 255, 100, 180)
        end
        surface.DrawRect(x, y, w * frac, h)

        -- надпись
        surface.SetTextColor(255, 255, 255, 255)
        local label = charging and ("ЗАРЯДКА: " .. math.ceil(self:GetNextPrimaryFire() - CurTime()) .. "с")
            or "ГОТОВ К ВЫСТРЕЛУ"
        local tw, th = surface.GetTextSize(label)
        surface.SetTextPos(x + (w - tw) / 2, y + h + 6)
        surface.DrawText(label)
    end
end
