local Workspace = game:GetService('Workspace');
local RunService = game:GetService('RunService');

local Camera = Workspace.CurrentCamera;

--#region Methods

local Meta = {};
Meta.__index = Meta;

function Meta:Quad(Options)
    local Quad = Drawing.new('Quad');

    Quad.Visible = Options.Visible or true;
    Quad.Transparency = Options.Transparency or 1;
    Quad.Color = Options.Color or Color3.fromRGB(255, 255, 255);
    Quad.Thickness = Options.Thickness or 1;
    Quad.Filled = Options.Filled or true;

    return Quad;
end

function Meta:Line(Options)
    local Line = Drawing.new('Line');

    Line.Visible = Options.Visible or true;
    Line.Transparency = Options.Transparency or 1;
    Line.Color = Options.Color or Color3.fromRGB(255, 255, 255);
    Line.Thickness = Options.Thickness or 1;

    return Line;
end

function Meta:ToCorners(CF, Size)
    local Corners = {};

    local _ = Size / 2;

    for X = -1, 1, 2 do
        for Y = -1, 1, 2 do
            for Z = -1, 1, 2 do
                Corners[#Corners + 1] = (CF * CFrame.new(_ * Vector3.new(X, Y, Z))).Position;
            end
        end
    end

    return Corners;
end

function Meta:ToViewport(Target)
    return Meta:ToVector2(Camera:WorldToViewportPoint(Target));
end

function Meta:ToVector2(Target)
    return Vector2.new(Target.X, Target.Y);
end

--#endregion

--#region Constants

--[[
    1 - Bottom Front Left
    2 - Bottom Back Left
    3 - Top Front Left
    4 - Top Back Left
    5 - Bottom Front Right
    6 - Bottom Back Right
    7 - Top Front Right
    8 - Top Back Right
]]

local Faces = {
    {
        3,
        1,
        5,
        7,
        'Front'
    },
    {
        4,
        2,
        6,
        8,
        'Back'
    },
    {
        3,
        4,
        8,
        7,
        'Top'
    },
    { 
        1,
        2,
        6,
        5,
        'Bottom'
    },
    {
        3,
        1,
        2,
        4,
        'Left'
    },
    {
        7,
        5,
        6,
        8,
        'Right'
    }
};

local Edges = {
    'TopFront',
    'TopBack',
    'TopLeft',
    'TopRight',
    'BottomFront',
    'BottomBack',
    'BottomLeft',
    'BottomRight',
    'FrontLeft',
    'FrontRight',
    'BackLeft',
    'BackRight'
};

--#endregion

--#region 3D Box

local Box = {
    Player = nil,
    Quads = {},
    Lines = {},

    Visible = false,
    COlor = Color3.fromRGB(255, 255, 255),

    QuadTransparency = 0.25,
    LineTransparency = 1,

    QuadThickness = 0.5,
    LineThickness = 1,

    Disposed = false
};

Box.__index = Box;

function Box:Initialize()
    if not self.Player.Character then return; end;

    if #self.Quads > 0 or #self.Lines > 0 then
        self:Destroy();
    end;

    for _, Face in next, Faces do
        table.insert(self.Quads, Meta:Quad({
            Visible = false,
            Transparency = self.QuadTransparency,
            Color = self.Color,
            Thickness = self.QuadThickness,
            Filled = true
        }));
    end    

    for _, Edge in next, Edges do
        table.insert(self.Lines, Meta:Line({
            Visible = false,
            Transparency = self.LineTransparency,
            Color = self.Color,
            Thickness = self.LineThickness
        }));
    end;
end

function Box:Update()
    if self.Disposed then return; end

    if #self.Quads == 0 or #self.Lines == 0 then return; end

    local Character = self.Player.Character;

    if not Character then
        self:SetVisible(false);

        if not self.Player.Parent then
            self:Dispose();
        end

        return;
    end

    local Humanoid, HumanoidRootPart = Character:FindFirstChildOfClass('Humanoid'), Character:FindFirstChild('HumanoidRootPart');

    if not Humanoid or not HumanoidRootPart then
        self:SetVisible(false);

        return;
    end

    if Humanoid.Health <= 0 then
        self:SetVisible(false);

        return;
    end

    local CFrame, Size = Character:GetBoundingBox();

    local _, OnScreen = Camera:WorldToViewportPoint(CFrame.Position);

    local Corners = Meta:ToCorners(CFrame, Size);

    for Index, Vertices in next, Faces do
        local Quad = self.Quads[Index];

        Quad.Visible = OnScreen;

        Quad.PointA = Meta:ToViewport(Corners[Vertices[1]]);
        Quad.PointB = Meta:ToViewport(Corners[Vertices[2]]);
        Quad.PointC = Meta:ToViewport(Corners[Vertices[3]]);
        Quad.PointD = Meta:ToViewport(Corners[Vertices[4]]);
    end
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
            end;

            self:Update();
        end);
    end
end

function Box:SetVisible(State)
    self.Visible = State;

    for _, Quad in next, self.Quads do
        Quad.Visible = State;
    end;

    for _, Line in next, self.Lines do
        Line.Visible = State;
    end;
end

function Box:Destroy()
    for _, Quad in next, self.Quads do
        Quad:Remove();
    end;

    for _, Line in next, self.Lines do
        Line:Remove();
    end;

    self.Quads = {};

    self.Lines = {};
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

    if Visible then
        Singleton:Toggle();
    end

    return Singleton;
end

--#endregion

--#region Testing

local Players = game:GetService('Players');

local Cache = {};

for i, Player in next, Players:GetPlayers() do
    table.insert(Cache, Library:Singleton(Player, true));
end

--#endregion