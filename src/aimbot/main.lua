local UserInputService = game:GetService('UserInputService');

local Workspace = game:GetService('Workspace');
local Players = game:GetService('Players');
local LocalPlayer = Players.LocalPlayer;

local Target = nil;

local function TeamCheck(Team)
    local TeamCheck = _G.TeamCheck or false;

    if Team and TeamCheck then
        return Team.Name ~= LocalPlayer.Team.Name;
    elseif not Team and not TeamCheck then
        return true;
    elseif Team and not TeamCheck then
        return true;
    elseif not Team and TeamCheck then
        return false;
    end
end

local function GetCameraXYZ(Part)
    local CurrentCamera = Workspace.CurrentCamera;

    local CameraX, CameraY, CameraZ = CurrentCamera.CFrame:ToOrientation();

    local NewCFrame = CFrame.new(CurrentCamera.CFrame.p, Part.CFrame.p);

    local NewX, NewY, NewZ = NewCFrame:ToOrientation();

    return Vector3.new(CameraX - NewX, CameraY - NewY, CameraZ - NewZ);
end

local function GetClosestPlayerInFov(Part)
    local XYZ = GetCameraXYZ(Part);

    return (math.abs(XYZ.X) + math.abs(XYZ.Y));
end

UserInputService.InputBegan:Connect(function(Input)
    if (Input.UserInputType == Enum.UserInputType.MouseButton2) then
        if not (Target)  then
            local MaxAngle = math.rad(20);

            for i, v in pairs(Players:GetChildren()) do
                if (v.Name ~= LocalPlayer.Name and v.Character) then
                    local Head = v.Character:FindFirstChild('Head');
                    
                    local Humanoid = v.Character:FindFirstChild('Humanoid');
    
                    if (Head and Humanoid) then
                        if (Humanoid.Health > 1) then
                            if TeamCheck(v.Team) then
                                local ClosestPlayerInFov = GetClosestPlayerInFov(Head);
    
                                if ClosestPlayerInFov < MaxAngle then
                                    MaxAngle = ClosestPlayerInFov;
    
                                    Target = Head;
                                end
                            end
                        end
                    end
    
                    v.Character.Humanoid.Died:Connect(function()
                        if (Head.Parent == v.Character or Head == nil) then
                            Target = nil;
                        end
                    end);
                end
            end
        end
    end
end);

UserInputService.InputEnded:Connect(function(Input)
    if (Input.UserInputType == Enum.UserInputType.MouseButton2) then
        if (Target) then
            Target = nil;
        end
    end
end);

game:GetService('RunService').RenderStepped:Connect(function()
    if (Target) then
        if (Target.Parent ~= LocalPlayer.Character) then
            local Precision = _G.Precision or 1;

            local Camera = Workspace.CurrentCamera;

            Camera.CFrame = Camera.CFrame:Lerp(
                CFrame.new(
                    Camera.CFrame.Position,
                    Target.CFrame.Position
                ),
                Precision
            );
        else
            Target = nil;
        end
    end
end);