-- Verity: рофл-оружие. ЛКМ — игрок взрывается иконками Verity.
-- Version 1.0.2 addition

SWEP.PrintName = "Verity"
SWEP.Author = "GPT"
SWEP.Instructions = "ЛКМ — взорваться иконками Verity. Абсолютно бесполезно и прекрасно."
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
SWEP.DrawCrosshair = true

SWEP.Slot = 5
SWEP.SlotPos = 1

SWEP.ViewModel = "models/weapons/c_slam.mdl"
SWEP.WorldModel = "models/weapons/w_slam.mdl"
SWEP.UseHands = true

SWEP.WepSelectIcon = Material("tunsweapons/verity.png")

if SERVER then
    util.AddNetworkString("verity_icon")
end

if CLIENT then
    -- Killicon: та же иконка, но исключительно в красных тонах
    killicon.Add("weapon_verity", "tunsweapons/verity_red.png", Color(255, 255, 255))

    -- Летящие иконки: запоминаем энтити, рисуем их сами
    local flyingIcons = {}
    net.Receive("verity_icon", function()
        local ent = net.ReadEntity()
        if not IsValid(ent) then return end
        flyingIcons[ent] = CurTime() + 10
    end)

    hook.Add("PreDrawTranslucentRenderables", "verity_icons", function(bDepth, bSkybox)
        if bSkybox then return end
        local now = CurTime()
        local mat = Material("tunsweapons/verity.png")
        for ent, deadline in pairs(flyingIcons) do
            if not IsValid(ent) or now > deadline then
                flyingIcons[ent] = nil
            else
                -- Куб невидим, поверх — плоская иконка, смотрящая на игрока
                render.SetMaterial(mat)
                local pos = ent:GetPos() + Vector(0, 0, 12)
                render.DrawSprite(pos, 16, 16, color_white)
            end
        end
    end)

    -- Чистим таблицу от мёртвых записей
    timer.Create("verity_icons_cleanup", 5, 0, function()
        local now = CurTime()
        for ent, deadline in pairs(flyingIcons) do
            if not IsValid(ent) or now > deadline then
                flyingIcons[ent] = nil
            end
        end
    end)
end

function SWEP:Initialize()
    self:SetHoldType("normal")
end

function SWEP:PrimaryAttack()
    self:SetNextPrimaryFire(CurTime() + 1)

    if SERVER then
        local ply = self:GetOwner()
        if not IsValid(ply) then return end

        local pos = ply:GetPos() + Vector(0, 0, 40)

        -- Взрыв (визуал + звук)
        local fx = EffectData()
        fx:SetOrigin(pos)
        util.Effect("Explosion", fx)
        ply:EmitSound("ambient/explosions/explode_4.wav", 100, 100)

        -- Везде летят иконки Verity: невидимые кубы-носители,
        -- клиент рисует поверх них картинку
        for i = 1, 20 do
            local icon = ents.Create("prop_physics")
            if not IsValid(icon) then break end
            icon:SetModel("models/hunter/blocks/cube025x025x025.mdl")
            icon:SetPos(pos + VectorRand() * 20)
            icon:SetRenderMode(RENDERMODE_TRANSCOLOR)
            icon:SetColor(Color(255, 255, 255, 0)) -- сам куб невидим
            icon:Spawn()
            icon:SetCollisionGroup(COLLISION_GROUP_DEBRIS)

            local phys = icon:GetPhysicsObject()
            if IsValid(phys) then
                phys:ApplyForceCenter((VectorRand() + Vector(0, 0, 1)) * 20000)
                phys:AddAngleVelocity(VectorRand() * 500)
            end

            -- Кричащая надпись + билборд-иконка на клиенте
            icon.VerityIcon = true
            local idx = icon:EntIndex()
            net.Start("verity_icon")
            net.WriteEntity(icon)
            net.Broadcast()

            -- Иконки исчезают через 10 секунд
            icon:Fire("Kill", "", 10)
        end

        -- Взрыв бьёт по окружающим: 100 хп в маленьком радиусе (без урона владельцу
        -- двойным счётом — владельца добивает blast ниже)
        for _, ent in ipairs(ents.FindInSphere(pos, 150)) do
            if ent ~= ply and (ent:IsPlayer() or ent:IsNPC()) then
                local blast = DamageInfo()
                blast:SetDamage(100)
                blast:SetDamageType(DMG_BLAST)
                blast:SetInflictor(self)
                blast:SetAttacker(ply)
                ent:TakeDamageInfo(blast)
            end
        end

        -- Игрок взрывается
        local dmg = DamageInfo()
        dmg:SetDamage(1000)
        dmg:SetDamageType(DMG_BLAST)
        dmg:SetInflictor(self)
        dmg:SetAttacker(ply)
        ply:TakeDamageInfo(dmg)
    end
end

function SWEP:SecondaryAttack()
    -- Ничего
end

function SWEP:Reload()
    -- Ничего
end

if CLIENT then
    -- Иконка verity в HUD слоте при переключении оружия
    function SWEP:DrawWeaponSelection(x, y, wide, tall, alpha)
        if not self.WepSelectIcon then return end
        surface.SetDrawColor(255, 255, 255, alpha)
        surface.SetMaterial(self.WepSelectIcon)
        local size = math.min(wide, tall)
        surface.DrawTexturedRect(x + (wide - size) / 2, y + (tall - size) / 2, size, size)
    end
end
