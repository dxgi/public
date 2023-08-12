local Players = game:GetService('Players');
local LocalPlayer = Players.LocalPlayer;

local Leaderboard = LocalPlayer.PlayerGui:WaitForChild('LeaderboardScreenGui');
local DisplayScore = Leaderboard:WaitForChild('DisplayScoreFrame');
local DisplayContainer = DisplayScore:WaitForChild('Container');

local DisplayPhantom = DisplayContainer:WaitForChild('DisplayPhantomBoard');
local DisplayPhantomContainer = DisplayPhantom:WaitForChild('Container');


local function FindTeam()
    local Team = nil;

    for Index, DisplayPlayerScore in next, DisplayPhantomContainer:GetChildren() do
        if DisplayPlayerScore:IsA('Frame') then
            local TextPlayer = DisplayPlayerScore:WaitForChild('TextPlayer');

            if Index == #DisplayPhantomContainer:GetChildren() and not Team then
                Team = { 
                    ["TeamName"] = "Ghosts",
                    ["TeamColor"] = "Bright orange"
                };
            end

            if TextPlayer.Text == LocalPlayer.Name and not Team then
                Team = { 
                    ["TeamName"] = "Phantoms",
                    ["TeamColor"] = "Bright blue"
                };
            end
        end
    end

    return Team;
end

print(FindTeam());