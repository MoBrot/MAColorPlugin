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
--------------------

local cColMixTypeNone = "None"
local cColMixTypeRGBCMY = "RGB_CMY"
local cColMixTypeWheelFixed = "ColorWheel"
local execute = Cmd;

function print(value)
  Printf(tostring(value))
end

------------ Util ------------
local function stringToIntArray(str)
  local result = {}
  for num in string.gmatch(str, "([^,]+)") do
      table.insert(result, tonumber(num)) -- Umwandlung in Ganzzahl
  end
  return result
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

function getColorPreset(index)
  return getGma3Pools().Preset:Children()[4]:Children()[index];
end

function getAllColorPresets()
  local result = {}

  for i=1, maximumPresets do
    local current = getColorPreset(i);

    if current ~= nil then
      table.insert(result, current)
    end
  end

  return result
end
-----------------------------------

------------ Create Layout ------------

function getColorAppearanceFromPreset(presetIndex)
  local data = GetPresetData(getColorPreset(presetIndex), false, false);

  print(data);

  return {
    color_R = 255 * (data[3][1].absolute / 100),
    color_G = 255 * (data[4][1].absolute / 100),
    color_B = 255 * (data[5][1].absolute / 100)
  };
end

function createAppereances()

  Import()

  execute("Store Appearance " .. (pluginOffset + 1) .. " Thru " .. (pluginOffset + (#pluginPresets * 2)) .. " /nu");

  local appearancePool = getGma3Pools().Appearance;
  for i = 1, #pluginPresets do
    local color = getColorAppearanceFromPreset(pluginPresets[i]);

    appearancePool[pluginOffset + i]:Set("backr", color.color_R);
    appearancePool[pluginOffset + i]:Set("backg", color.color_G);
    appearancePool[pluginOffset + i]:Set("backb", color.color_B);

    appearancePool[pluginOffset + i]:Set("imager", color.color_R);
    appearancePool[pluginOffset + i]:Set("imageg", color.color_G);
    appearancePool[pluginOffset + i]:Set("imageb", color.color_B);

    appearancePool[pluginOffset + i]:Set("backalpha", 255);
    appearancePool[pluginOffset + i]:Set("name", "");
  end
end

function buildLayout()
  createAppereances();
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

  --


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