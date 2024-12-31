local function getGma3Pools()
  return {
    -- token = PoolHandle
    Sequence        = DataPool().Sequences;
    World           = DataPool().Worlds;
    Filter          = DataPool().Filters;
    Group           = DataPool().Groups;
    Plugin          = DataPool().Plugins;
    Macro           = DataPool().Macros;
    Matricks        = DataPool().Matricks;
    Configuration   = DataPool().Configurations;
    Page            = DataPool().Pages;
    Layout          = DataPool().Layouts;
    Timecode        = DataPool().Timecodes;
    Preset          = DataPool().PresetPools;
    View            = Root().ShowData.UserProfiles.Default.ViewPool;
    Appearance      = Root().ShowData.Appearances;
    Camera          = Root().ShowData.UserProfiles.Default.CameraPool;
    Sound           = Root().ShowData.Sounds;
    User            = Root().ShowData.Users;
    Userprofile     = Root().ShowData.Userprofiles;
    Scribble        = Root().ShowData.ScribblePool;
    ViewButton      = Root().ShowData.UserProfiles.Default.ScreenConfigurations.Default["ViewButtonPages 2"];
    Screencontents  = Root().ShowData.UserProfiles.Default.ScreenConfigurations.Default.ScreenContents;
    Display         = Root().GraphicsRoot.PultCollect["Pult 1"].DisplayCollect;
    DataPool        = Root().ShowData.DataPools;
    Image           = Root().ShowData.ImagePools;
    Fixturetype     = Root().ShowData.LivePatch.FixtureTypes;
    GelPools        = Root().ShowData.GelPools;
  }
end

-- Plugin Config ---
local pluginOffset = 3000;
local buttonWidth = 110;
local buttonHeight = 110;
local buttonSeparation = 5;
local maximumPresets = 40;

local pluginGroups = {};
local pluginPresets = {};
local pluginBumpGroup = 0;

-- Required Images --
local pluginUI = {
  activeImage = {
    name = "Color-GridItem-active.png.xml",
    index = pluginOffset + 1
  },
  inActiveImage = {
    name = "Color-GridItem-inactive.png.xml",
    index = pluginOffset + 2
  }
};

--------------------

local cColMixTypeNone = "None"
local cColMixTypeRGBCMY = "RGB_CMY"
local cColMixTypeWheelFixed = "ColorWheel"
local execute = Cmd;

function print(value)
  Printf(tostring(value))
end

------------ Util ------------
function pluginColorPresetAmount()
  return #pluginGroups * #pluginPresets;
end

function stringToIntArray(str)
  local result = {}
  for num in string.gmatch(str, "([^,]+)") do
      table.insert(result, tonumber(num)) -- Umwandlung in Ganzzahl
  end
  return result
end

function getAsFixture(inFixtureIndex)
  local myResult = nil
  local myLowestSubFixture = nil
  local myNextSubfixture = GetSubfixture(inFixtureIndex)
  
  while myNextSubfixture ~= nil do
    myLowestSubFixture = myNextSubfixture
    myNextSubfixture = GetSubfixture(myLowestSubFixture)		
  end
  
  if myLowestSubFixture ~= nil then
    myResult = myLowestSubFixture
  end
  
  return myResult
end

function getAsGroup(groupIndex)
  return getGma3Pools().Group[groupIndex];
end

function getAsColorPreset(index)
  return getGma3Pools().Preset:Children()[4]:Children()[index];
end
-----------------------------------

------------ Suggestions ------------
function arrayToNumber(groups)
  local result = {}

  for _, group in ipairs(groups) do
    table.insert(result, group.no)
  end

  return result
end

function convertNumberArrayToStringList(array)
  local result = ""

  for i = 1, #array do
    result = result .. tostring(array[i])

    if i ~= #array then
      result = result .. ","
    end
  end

  return result
end

local function getUiChannelIdxForAttributeName(inFixtureIndex, inAttributeName)
  local myResult = nil
  local myAttrIdx = GetAttributeIndex(inAttributeName)
  
  if myAttrIdx ~= nil and inFixtureIndex ~= nil then
    myResult = GetUIChannelIndex(inFixtureIndex, myAttrIdx)
  end
  
  return myResult
end

local function getFixtureColMixType(inFixtureIndex)
  local myResult = cColMixTypeNone
  local myRgbRUiChannelIdx = getUiChannelIdxForAttributeName(inFixtureIndex, "ColorRGB_R")
  local myRgbCUiChannelIdx = getUiChannelIdxForAttributeName(inFixtureIndex, "ColorRGB_C")
  local myColor1UiChannelIdx = getUiChannelIdxForAttributeName(inFixtureIndex, "Color1")
  
  if myRgbCUiChannelIdx == nil and myRgbRUiChannelIdx == nil then
    if myColor1UiChannelIdx ~= nil then
      myResult = cColMixTypeWheelFixed
    end
  else
    myResult = cColMixTypeRGBCMY
  end
  
  return myResult
end

function selectNewGroup(group)
  execute("Clear")
  execute("Self Group " .. group)
end

function doesGroupContainColorFixtures(group)
  selectNewGroup(group.no)
  local current = SelectionFirst(true)

  while current do
    if getFixtureColMixType(current) ~= cColMixTypeNone then
      return true
    end
    current = SelectionNext(current)
  end

  return false
end

function getAllColorGroups()
  local groups = getGma3Pools().Group
  local result = {}

  for i = 1, #groups do
    local group = groups[i] or false;

    if group ~= false and doesGroupContainColorFixtures(group) then
      table.insert(result, group)
    end
  end

  execute("Clear");
  return result
end

function getAllColorPresets()
  local result = {}

  for i=1, maximumPresets do
    local current = getAsColorPreset(i);

    if current ~= nil then
      table.insert(result, current)
    end
  end

  return result
end
-----------------------------------

------------ Create Layout ------------

function getColorAppearanceFromPreset(presetIndex)
  local data = GetPresetData(getAsColorPreset(presetIndex), false, false);

  return {
    color_R = 255 * (data[3][1].absolute / 100),
    color_G = 255 * (data[4][1].absolute / 100),
    color_B = 255 * (data[5][1].absolute / 100)
  };
end

function setColorAppearance(appearance, color, image)
  appearance:Set("imager", color.color_R);
  appearance:Set("imageg", color.color_G);
  appearance:Set("imageb", color.color_B);
  appearance:Set("imagemode", "Stretch");
  execute("Assign Image 3." .. image.index .. " at Appearance " .. appearance.no)
end

function createAppereances()
  local appearancePool = getGma3Pools().Appearance;

  ------- Create Color Appearances -------

  -- Import Images --
  for key, image in pairs(pluginUI) do
    execute("Import Image 'Images'." .. image.index .." /File '" .. image.name .. "' /nc /o")
  end

  execute("Store Appearance " .. (pluginOffset) .. " Thru " .. (pluginOffset + (#pluginPresets * 2)) .. " /nu");

  for i = 1, #pluginPresets do
    local color = getColorAppearanceFromPreset(pluginPresets[i]);

    local currentAppearanceIndex = pluginOffset + i;
    local currentAppearance = appearancePool[currentAppearanceIndex];

    setColorAppearance(currentAppearance, color, pluginUI.activeImage);

    local currentAppearanceIndexInactivs = pluginOffset + i + #pluginPresets;
    local currentAppearanceInactivs = appearancePool[currentAppearanceIndexInactivs];

    setColorAppearance(currentAppearanceInactivs, color, pluginUI.inActiveImage);
  end
  -------------------------------------------

   ------- Create Transparent Appearances -------

   local transparentAppearance = appearancePool[pluginOffset];

   -------------------------------------------
end

function storePoolObject(poolType, index)
  execute("Delete " .. poolType .. " " .. index);
  execute("Store " .. poolType .. " " .. index);
end

function createMacrosForColorRow(macroOffset)

  local macroPool = getGma3Pools().Macro;

  local result = {};

  for pi = 1, #pluginPresets do

    local macroPosition = macroOffset + pi - 1;

    storePoolObject("Macro", macroPosition);
    local currentColorMacro = macroPool[macroPosition];
    currentColorMacro:Set("appearance", pluginOffset + pi + #pluginPresets);

    execute("Store Macro " .. macroPosition .. " 'Set Active Image' 'Command' 'Assign #[Appearance " .. (pluginOffset + pi) .. "] at #[Macro ".. macroPosition .. "]'");

    result[pi] = macroPosition;
  end

  return result;
end

function createGridMacrosAndSequenses()

  -- Preset to Appearance map -> 
  local macroPool = getGma3Pools().Macro;
  local sequencePool = getGma3Pools().Sequence;

  print("createGridMacrosAndSequenses");

  -- Create Group Grid --
  for gi = 1, #pluginGroups do

    local macroOffset = pluginOffset + (gi * #pluginPresets) - #pluginPresets;
    local group = getAsGroup(pluginGroups[gi]);

    -- Store MATricks --
    local matricksPosition = pluginOffset + gi;
    storePoolObject("MAtricks", matricksPosition);
    local currentMATricks = getGma3Pools().Matricks[matricksPosition];
    currentMATricks:Set("name", group.name .. " Color MATricks");

    -- Create Group Macros --
    local currentGroupMacroIndex = pluginOffset + pluginColorPresetAmount() + gi - 1;
    storePoolObject("Macro", currentGroupMacroIndex);
    local currentGroupMacro = macroPool[currentGroupMacroIndex];

    currentGroupMacro:Set("name", group.name);
    currentGroupMacro:Set("appearance", pluginOffset);
    execute("Store Macro " .. currentGroupMacroIndex .. " 'Select Group' 'Command' '#[Group " .. group.no .. "]'");

    for pi = 1, #pluginPresets do

      local colorPreset = getAsColorPreset(pluginPresets[pi]);
      local macroPosition = macroOffset + pi - 1;

      -- Sequences --
      storePoolObject("Sequence", macroPosition);
      local currentSequence = sequencePool[macroPosition];
      currentSequence:Set("name", group.name .. " - " .. colorPreset.name);
      currentSequence:Set('offwhenoverridden','true');

      -- Create and Configure Recipe --
      execute("Assign Group " .. group.no .. " at cue 1 part 0.1 Sequence " .. macroPosition .. " /nu");
      execute("Assign Preset 4." .. colorPreset.no .. " at cue 1 part 0.1 Sequence " .. macroPosition .. " /nu");
      execute("Assign MATricks " .. currentMATricks.no .. " at cue 1 part 0.1 Sequence " .. macroPosition .. " /nu");

    end

    local macros = createMacrosForColorRow(macroOffset);
    for i = 1, #macros do
      execute("Store Macro " .. macros[i] .. " 'Go Sequence' 'Command' 'Go+ #[Sequence " .. macros[i] .. "]'")
    end    
  end
end

function buildLayout()

  execute("Store Layout " .. pluginOffset);

  createAppereances();
  createGridMacrosAndSequenses();
end
-----------------------------------

------------ BuildUI ------------

local offsetText = "Offset";
local gridGroupsText = "Grid-Groups";
local bumpsGroupsText = "Bump-Groups";
local gridPresetsText = "Grid-Presets";

function buildDefaultUI(groupSuggest, presetSuggest)
  local textInputs = {
    { name = offsetText, value = tostring(pluginOffset), whiteFilter = "0123456789" },
    { name = gridGroupsText, value = groupSuggest, whiteFilter = ",0123456789" },
    { name = bumpsGroupsText, value = string.match(groupSuggest, "([^,]+)"), whiteFilter = "0123456789" },
    { name = gridPresetsText, value = presetSuggest, whiteFilter = ",0123456789" }
  };

  local commands = {
    { name = "next", value = 1 },
    { name = "close", value = 0 }
  };

  return {
    title = "Color Grid Config",
    commands = commands,
    inputs = textInputs
  };
end

function buildPluginInfo() end

function buildErrorUI(errorMessage)
  return {
    title = "Error while Building the Colorgrid",
    message = errorMessage,
    message_align_h = Enums.AlignmentH.Middle
  };
end
-----------------------------------

function main()
  local groupSuggest = getAllColorGroups();
  local groupString = convertNumberArrayToStringList(arrayToNumber(groupSuggest));
  local presetSuggest = getAllColorPresets();
  local presetString = convertNumberArrayToStringList(arrayToNumber(presetSuggest));

  -- TODO - Check if Groups are Valid and Presets are valid

  local defaultUI = MessageBox(buildDefaultUI(groupString, presetString));

  if defaultUI.result ~= 1 then
    return;
  end

  local inputs = defaultUI.inputs;

  pluginOffset = inputs[offsetText];
  pluginGroups = stringToIntArray(inputs[gridGroupsText]);
  pluginPresets = stringToIntArray(inputs[gridPresetsText]);
  pluginBumpGroup = inputs[bumpsGroupsText];

  -- Check if all Groups are valid and check if all Presets are valid 
  -- build Info Messagebox

  buildLayout();
end

return main