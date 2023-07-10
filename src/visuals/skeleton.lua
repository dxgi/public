local Workspace = game:GetService('Workspace');
local RunService = game:GetService('RunService');

local Camera = Workspace.CurrentCamera;

--#region Methods

local Meta = {};
Meta.__index = Meta;

function Meta:Line(Options)
	local Line = Drawing.new('Line');

	Line.Visible = Options.Visible or true;
	Line.Transparency = Options.Transparency or 1;
	Line.Color = Options.Color or Color3.fromRGB(0, 255, 0);
	Line.Thickness = Options.Thickness or 1;

	return Line;
end

function Meta:ToVector2(Vector3)
	return Vector2.new(Vector3.X, Vector3.Y);
end

--#endregion

--#region Skeleton

local Skeleton = {
	Player = nil,
	Lines = {},

	Visible = false,
	Transparency = 1,
	Color = Color3.fromRGB(0,255,0),
	Thickness = 1,

	FullBody = true,
	Disposed = false
};

Skeleton.__index = Skeleton;

function Skeleton:Initialize()
	if not self.Player.Character then return end

	self:Destroy();

	for _, Part in next, self.Player.Character:GetChildren() do
		if Part:IsA('BasePart') then
			for _, Motor in next, Part:GetChildren() do
				if Motor:IsA('Motor6D') then
					table.insert(self.Lines, {
						PrimaryLine = Meta:Line({
							Visible = self.Visible,
							Transparency = self.Transparency,
							Color = self.Color,
							Thickness = self.Thickness
						}),
						SecondaryLine = Meta:Line({
							Visible = self.Visible,
							Transparency = self.Transparency,
							Color = self.Color,
							Thickness = self.Thickness
						}),
						PartName = Part.Name,
						MotorName = Motor.Name
					});
				end
			end
		end
	end
end

function Skeleton:Update()
	if self.Disposed then
		return;
	end

	local Character = self.Player.Character;
	if not Character then
		self:SetVisible(false);
		if not self.Player.Parent then
			self:Dispose();
		end
		return;
	end

	local Humanoid = Character:FindFirstChildOfClass('Humanoid');

	if not Humanoid then
		self:SetVisible(false);

		return;
	end

	self:SetTransparency(self.Transparency);
	self:SetColor(self.Color);
	self:SetThickness(self.Thickness);

	local RequireUpdate = false;
	
	for _, Line in pairs(self.Lines) do
		local Part = Character:FindFirstChild(Line.PartName);

		local Motor = Part and Part:FindFirstChild(Line.MotorName);

		if not (Part and Motor) then
			Line.PrimaryLine.Visible = false;
			Line.SecondaryLine.Visible = false;

			RequireUpdate = true;

			continue;
		end

		local Part0 = Motor.Part0;
		local Part1 = Motor.Part1;
		
		local C0 = Motor.C0;
		local C1 = Motor.C1;

		if self.FullBody and C0 and C1 then
			local UpperPart0, UpperPart0Visible = Camera.WorldToViewportPoint(Camera, Part0.CFrame.Position);
			local LowerPart0, LowerPart0Visible = Camera.WorldToViewportPoint(Camera, (Part0.CFrame * C0).Position);

			local UpperPart1, UpperPart1Visible = Camera.WorldToViewportPoint(Camera, Part1.CFrame.p);
			local LowerPart1, LowerPart1Visible = Camera.WorldToViewportPoint(Camera, (Part1.CFrame * C1).Position);

			if UpperPart0Visible and LowerPart0Visible then
				Line.PrimaryLine.From = Meta:ToVector2(UpperPart0);
				Line.PrimaryLine.To = Meta:ToVector2(LowerPart0);

				Line.PrimaryLine.Visible = true;
			else 
				Line.PrimaryLine.Visible = false;
			end
			
			if UpperPart1Visible and LowerPart1Visible then
				Line.SecondaryLine.From = Meta:ToVector2(UpperPart1);
				Line.SecondaryLine.To = Meta:ToVector2(LowerPart1);

				Line.SecondaryLine.Visible = true;
			else 
				Line.SecondaryLine.Visible = false;
			end
		else
			local UpperPart0, UpperPart0Visible = Camera.WorldToViewportPoint(Camera, Part0.CFrame.Position);
			local UpperPart1, UpperPart1Visible = Camera.WorldToViewportPoint(Camera, Part1.CFrame.Position);

			if UpperPart0Visible and UpperPart1Visible then
				Line.PrimaryLine.From = Meta:ToVector2(UpperPart0);
				Line.PrimaryLine.To = Meta:ToVector2(UpperPart1);

				Line.PrimaryLine.Visible = true;
			else 
				Line.PrimaryLine.Visible = false;
			end

			Line.SecondaryLine.Visible = false;
		end
	end
	
	if RequireUpdate or #self.Lines == 0 then
		self:Initialize();
	end
end

function Skeleton:Toggle()
	self.Visible = not self.Visible;

	if self.Visible then 
		self:Destroy();
		self:Initialize();
		
		local Connection;
		
		Connection = RunService.RenderStepped:Connect(function()
			if not self.Visible then
				self:SetVisible(false);

				Connection:Disconnect();

				return;
			end

			self:Update();
		end)
	end
end

function Skeleton:SetVisible(State)
	for _, Line in pairs(self.Lines) do
		Line.PrimaryLine.Visible = State;
		Line.SecondaryLine.Visible = State;
	end
end

function Skeleton:SetTransparency(Transparency)
	self.Transparency = Transparency;

	for _, Line in pairs(self.Lines) do
		Line.PrimaryLine.Transparency = Transparency;
		Line.SecondaryLine.Transparency = Transparency;
	end
end

function Skeleton:SetColor(Color)
	self.Color = Color;

	for _, Line in pairs(self.Lines) do
		Line.PrimaryLine.Color = Color;
		Line.SecondaryLine.Color = Color;
	end
end

function Skeleton:SetThickness(Thickness)
	self.Thickness = Thickness;

	for _, Line in pairs(self.Lines) do
		Line.PrimaryLine.Thickness = Thickness;
		Line.SecondaryLine.Thickness = Thickness;
	end
end

function Skeleton:Destroy()
	for _, Line in pairs(self.Lines) do
		Line.PrimaryLine:Remove();
		Line.SecondaryLine:Remove();
	end

	self.Lines = {};
end

function Skeleton:Dispose()
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
	}, Skeleton);

	if Visible then
		Singleton:Toggle();
	end

	return Singleton;
end

return Library;

--#endregion