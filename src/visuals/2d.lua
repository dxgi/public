--[[
local Workspace = game:GetService('Workspace');
local RunService = game:GetService('RunService');

local Camera = Workspace.CurrentCamera;

--#region Meta

local Meta = {};
Meta.__index = Meta;

function Meta:Square(Options)
    local Square = Drawing.new('Square');

    Square.Visible = Options.Visible or true;
    Square.Transparency = Options.Transparency or 1;
    Square.Color = Options.Color or Color3.fromRGB(0, 255, 0);
    Square.Thickness = Options.Thickness or 1;
    Square.Filled = Options.Filled or false;

    return Square;
end

function Meta:Text(Options)
    local Text = Drawing.new('Text');
    
    Text.Visible = Options.Visible or true;
    Text.Transparency = Options.Transparency or 1;
    Text.Color = Options.Color or Color3.fromRGB(0, 255, 0);

    Text.Text = Options.Text or '';
    Text.Font = 3;
    Text.Size = Options.Size or 14;
    Text.Center = Options.Center or true;
    Text.Outline = Options.Outline or false;
    Text.OutlineColor = Options.OutlineColor or Color3.fromRGB(0, 0, 0);

    return Text;
end

function Meta:ToVector2(Vector3)
    return Vector2.new(Vector3.X, Vector3.Y);
end

--#endregion

--#region Box

local Box = {
    Player = nil,
    Cache = {},

    Visible = false,
    Transparency = 1,
    Color = Color3.fromRGB(0,255,0),
    Thickness = 1,

    Disposed = false
};

Box.__index = Box;

function Box:Initialize()
    if not self.Player.Character then return; end

    if #self.Cache > 0 then
        self:Destroy();
    end

    table.insert(self.Cache, {
        Box = Meta:Square({
            Visible = self.Visible,
            Transparency = self.Transparency,
            Color = self.Color,
            Thickness = self.Thickness,
            Filled = false
        }),
        BoxOutline = Meta:Square({
            Visible = self.Visible,
            Transparency = self.Transparency,
            Color = self.Color,
            Thickness = self.Thickness,
            Filled = false
        }),
        HealthBar = Meta:Square({
            Visible = self.Visible,
            Transparency = self.Transparency,
            Color = self.Color,
            Thickness = self.Thickness,
            Filled = true
        }),
        HealthBarOutline = Meta:Square({
            Visible = self.Visible,
            Transparency = self.Transparency,
            Color = self.Color,
            Thickness = self.Thickness,
            Filled = false
        }),
        Name = Meta:Text({
            Visible = self.Visible,
            Transparency = self.Transparency,
            Color = self.Color,
            Text = '',
            Size = 14,
            Center = true,
            Outline = true,
            OutlineColor = Color3.fromRGB(0, 0, 0)
        })
    });
end

function Box:Update()
    if self.Disposed then return; end

    if #self.Cache == 0 then return; end

    local Character = self.Player.Character;

    if not Character then
        self:SetVisible(false);

        if not self.Player.Parent then
            self:Dispose();
        end
        
        return;
    end

    local Humanoid, HumanoidRootPart = Character:FindFirstChild('Humanoid'), Character:FindFirstChild('HumanoidRootPart');

    if not Humanoid or not HumanoidRootPart then 
        self:SetVisible(false);
        
        return;
    end

    if Humanoid.Health <= 0 then 
        self:SetVisible(false);

        return;
    end

    local CFrame, Size = Character:GetBoundingBox();

    local Vector, OnScreen = Camera:WorldToViewportPoint(CFrame.p);

    local Cache = self.Cache[1];

	print(Character:GetScale());

    local ScaleFactor = 1 / (Vector.Z * math.tan(math.rad(Camera.FieldOfView * Character:GetScale() * 0.5)) * 2) * 100;

    local Width, Height = 37.5 * ScaleFactor, 55 * ScaleFactor;

    local Position = Vector2.new(Vector.X - Width / 2, Vector.Y - Height / 2);

    Cache.Box.Visible = OnScreen;
    Cache.Box.Size = Vector2.new(Width, Height);
    Cache.Box.Position = Position;
    Cache.ZIndex = 2;
end

function Box:Toggle()
    self.Visible = not self.Visible;

    if (self.Visible) then
        self:Initialize();

        local Connection;
        
        Connection = RunService.RenderStepped:Connect(function()
            if not self.Visible then
                self:SetVisible(false);

                Connection:Disconnect();

                return;
            end

            self:Update();
        end);
    end
end

function Box:SetVisible(State)
    self.Visible = State;

    for _, Object in next, self.Cache do
        for _, Child in next, Object do
            Child.Visible = State;
        end
    end
end

function Box:Destroy()
    for _, Object in next, self.Cache do
        for _, Child in next, Object do
            Child:Remove();
        end
    end

    self.Cache = {};
end

function Box:Dispose()
    self.Disposed = true;

    self:Destroy();
end

--#endregion

--#region Library

local Library = {};
Library.__index = Library;

function Library:Singleton(Player, Visible)
    local Singleton = setmetatable({
        Player = Player
    }, Box);

    if (Visible) then
        Singleton:Toggle();
    end

    return Singleton;
end

--#endregion

--#region Example

local Boxes = {};

local Players = game:GetService('Players');

for i,v in next, Players:GetPlayers() do
    if (v.Name == Players.LocalPlayer.Name) then
        table.insert(Boxes, Library:Singleton(v, true));
    end
end

--#endregion
]]