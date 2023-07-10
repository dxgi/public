--#region Methods

local Meta = {};
Meta.__index = Meta;

function Meta:ToExtension(File)
    local Index = nil;

    for _ = #File, 1, -1 do
        if (string.sub(File, _, _) == '.') then
            Index = _;

            break;
        end
    end

    if (Index) then
        return string.sub(File, Index);
    else
        return '';
    end
end

function Meta:Descend(Path, Level, _)
    Level = Level or 0;

    for _, File in ipairs(listfiles(Path)) do
        if (isfolder(File)) then
            if (File == '.\\autoexec' and Level == 0) then
                self:Descend(File, Level + 1, true);
            elseif (Level ~= 0) then
                self:Descend(File, Level + 1, true);
            end
        elseif _ then
            local Extension = self:ToExtension(File);

            if (Extension == '.txt' or Extension == '.lua') then
                dofile(File);
            end
        end
    end
end

--#endregion

Meta:Descend('.');