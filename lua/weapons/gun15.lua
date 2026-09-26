-- Мощный дробовик для Garry's Mod, основанный на gun1.lua

SWEP.PrintName = "Ba-12 Shotgun"
SWEP.Author = "GPT"
SWEP.Instructions = "ЛКМ — выстрел. Присядьте для большей кучности."
SWEP.Category = "TUNS Weapons"

SWEP.Spawnable = true
SWEP.AdminSpawnable = true

SWEP.Primary.ClipSize = 8
SWEP.Primary.DefaultClip = 32
SWEP.Primary.Automatic = false
SWEP.Primary.Ammo = "Buckshot"
SWEP.Primary.Delay = 0.85
SWEP.Primary.Damage = 13
SWEP.Primary.Recoil = 2.3
SWEP.Primary.NumShots = 7
SWEP.Primary.Spread = 0.045 -- базовый минимальный разброс
SWEP.Primary.MaxSpread = 0.11
SWEP.Primary.SpreadIncrease = 0.014 -- насколько разброс увеличивается за выстрел
SWEP.Primary.SpreadRecovery = 0.035 -- скорость восстановления разброса в секунду
SWEP.Primary.Force = 8

SWEP.CrouchSpreadMul = 0.48 -- уменьшение разброса при приседании

SWEP.Secondary.ClipSize = -1
SWEP.Secondary.DefaultClip = -1
SWEP.Secondary.Automatic = false
SWEP.Secondary.Ammo = "None"

SWEP.Weight = 7
SWEP.DrawAmmo = true
SWEP.DrawCrosshair = true

SWEP.Slot = 2
SWEP.SlotPos = 5

SWEP.ViewModel = "models/weapons/cstrike/c_shot_xm1014.mdl"
SWEP.WorldModel = "models/weapons/w_shot_xm1014.mdl"
SWEP.UseHands = true

function SWEP:Initialize()
    self:SetHoldType("shotgun")
    self.CurrentSpread = self.Primary.Spread
    self.LastFireTime = 0
end

function SWEP:GetModifiedSpread()
    if IsValid(self.Owner) and self.Owner:Crouching() then
        return (self.CurrentSpread or self.Primary.Spread) * self.CrouchSpreadMul
    end
    return self.CurrentSpread or self.Primary.Spread
end

function SWEP:GetModifiedBaseSpread()
    if IsValid(self.Owner) and self.Owner:Crouching() then
        return self.Primary.Spread * self.CrouchSpreadMul
    end
    return self.Primary.Spread
end

function SWEP:GetModifiedMaxSpread()
    if IsValid(self.Owner) and self.Owner:Crouching() then
        return self.Primary.MaxSpread * self.CrouchSpreadMul
    end
    return self.Primary.MaxSpread
end

function SWEP:PrimaryAttack()
    if (not self:CanPrimaryAttack()) then return end

    local owner = self:GetOwner()
    if not IsValid(owner) then return end

    -- Увеличиваем разброс при каждом выстреле (учитываем максимум с учетом приседания)
    local maxSpread = self:GetModifiedMaxSpread()
    self.CurrentSpread = math.min(
        (self.CurrentSpread or self.Primary.Spread) + self.Primary.SpreadIncrease,
        maxSpread
    )
    self.LastFireTime = CurTime()

    self:EmitSound("Weapon_XM1014.Single")
    self:ShootBullet(self.Primary.Damage, self.Primary.NumShots, self:GetModifiedSpread())
    self:TakePrimaryAmmo(1)

    owner:ViewPunch(Angle(-self.Primary.Recoil, 0, 0))

    self:SetNextPrimaryFire(CurTime() + self.Primary.Delay)
end

function SWEP:Think()
    -- Постепенно восстанавливаем разброс, если не стреляем
    if not self.LastFireTime then return end
    local baseSpread = self:GetModifiedBaseSpread()
    if (self.CurrentSpread or self.Primary.Spread) > baseSpread then
        self.CurrentSpread = math.max(
            baseSpread,
            (self.CurrentSpread or self.Primary.Spread) - self.Primary.SpreadRecovery * FrameTime()
        )
        self.LastFireTime = CurTime()
    end
end

function SWEP:ShootBullet(damage, num_bullets, aimcone)
    local owner = self:GetOwner()
    if not IsValid(owner) then return end

    local bullet = {}
    bullet.Num = num_bullets
    bullet.Src = owner:GetShootPos()
    bullet.Dir = owner:GetAimVector()
    bullet.Spread = Vector(aimcone, aimcone, 0)
    bullet.Tracer = 1
    bullet.TracerName = "Tracer"
    bullet.Force = self.Primary.Force
    bullet.Damage = damage
    bullet.AmmoType = self.Primary.Ammo

    owner:FireBullets(bullet)
    self:ShootEffects()
end

-- Перезарядка: start -> вставка патронов -> finish
function SWEP:Reload()
    if self.Reloading then return end
    if self:Clip1() >= self.Primary.ClipSize then return end

    local owner = self:GetOwner()
    if not IsValid(owner) then return end
    if owner:GetAmmoCount(self.Primary.Ammo) <= 0 then return end

    self.Reloading = true
    self:SetNextPrimaryFire(CurTime() + 0.4)
    self:SetNextSecondaryFire(CurTime() + 0.4)

    local vm = owner:GetViewModel()
    local startDuration = 0.4
    if IsValid(vm) then
        startDuration = self:PlayViewModelAnimation(vm, ACT_SHOTGUN_RELOAD_START, "reload_start", startDuration)
    else
        self:SendWeaponAnim(ACT_SHOTGUN_RELOAD_START)
    end

    timer.Simple(startDuration, function()
        if not self:IsStillReloading(owner) then return end
        self:InsertShell()
    end)
end

function SWEP:PlayViewModelAnimation(vm, activity, sequenceName, fallback)
    if not IsValid(vm) then return fallback end

    local sequence = vm:LookupSequence(sequenceName)
    if sequence and sequence > 0 then
        vm:ResetSequence(sequence)
    else
        vm:ResetSequence(activity)
    end

    local duration = vm:SequenceDuration(sequence or activity)
    if duration and duration > 0.1 then
        return math.max(duration, 0.1)
    end

    return fallback
end

function SWEP:IsStillReloading(owner)
    if not IsValid(self) or not IsValid(owner) then
        if IsValid(self) then self:CancelReload() end
        return false
    end

    if not self.Reloading then return false end
    if self:GetOwner() ~= owner then
        self:CancelReload()
        return false
    end

    return true
end

function SWEP:InsertShell()
    local owner = self:GetOwner()
    if not self:IsStillReloading(owner) then return end
    if self:Clip1() >= self.Primary.ClipSize or owner:GetAmmoCount(self.Primary.Ammo) <= 0 then
        self:FinishReload()
        return
    end

    local vm = owner:GetViewModel()
    local shellDuration = 0.45
    if IsValid(vm) then
        shellDuration = self:PlayViewModelAnimation(vm, ACT_VM_RELOAD, "reload_insert", shellDuration)
    else
        self:SendWeaponAnim(ACT_VM_RELOAD)
    end

    timer.Simple(shellDuration, function()
        if not self:IsStillReloading(owner) then return end

        if SERVER then
            if self:Clip1() >= self.Primary.ClipSize or owner:GetAmmoCount(self.Primary.Ammo) <= 0 then
                self:FinishReload()
                return
            end

            self:SetClip1(self:Clip1() + 1)
            owner:RemoveAmmo(1, self.Primary.Ammo)
        end

        if self:Clip1() < self.Primary.ClipSize and owner:GetAmmoCount(self.Primary.Ammo) > 0 then
            self:InsertShell()
        else
            self:FinishReload()
        end
    end)
end

function SWEP:FinishReload()
    if not IsValid(self) then return end

    local owner = self:GetOwner()
    if not IsValid(owner) then
        self:CancelReload()
        return
    end

    -- Финальная анимация должна проигрываться только один раз.
    if self.FinishReloadPlaying then return end
    self.FinishReloadPlaying = true

    local vm = owner:GetViewModel()
    local finishDuration = 0.4
    if IsValid(vm) then
        finishDuration = self:PlayViewModelAnimation(vm, ACT_SHOTGUN_RELOAD_FINISH, "reload_finish", finishDuration)
    else
        self:SendWeaponAnim(ACT_SHOTGUN_RELOAD_FINISH)
    end

    self:SetNextPrimaryFire(CurTime() + finishDuration)
    self:SetNextSecondaryFire(CurTime() + finishDuration)

    timer.Simple(finishDuration, function()
        if not IsValid(self) then return end
        self.Reloading = false
        self.FinishReloadPlaying = nil
        self:SendWeaponAnim(ACT_VM_IDLE)
        self:SetNextPrimaryFire(CurTime())
        self:SetNextSecondaryFire(CurTime())
    end)
end

function SWEP:CancelReload()
    if not IsValid(self) then return end

    self.Reloading = false
    self.FinishReloadPlaying = nil
    self:SendWeaponAnim(ACT_VM_IDLE)
    self:SetNextPrimaryFire(CurTime())
    self:SetNextSecondaryFire(CurTime())
end

-- Сбрасываем возможный незакрытый таймер перезарядки при смене оружия.
function SWEP:Holster()
    self:CancelReload()
    return true
end

function SWEP:Deploy()
    self.Reloading = false
    self.FinishReloadPlaying = nil
    return true
end

function SWEP:CanPrimaryAttack()
    if self.Reloading then return false end
    return self:Clip1() > 0
end

function SWEP:SecondaryAttack()
end
