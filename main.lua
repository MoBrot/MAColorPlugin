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
--------------------

local cColMixTypeNone = "None"
local cColMixTypeRGBCMY = "RGB_CMY"
local cColMixTypeWheelFixed = "ColorWheel"

local execute = Cmd;

function print(value)
  Printf(tostring(value))
end

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
function getAppearanceFromPreset(presetIndex)

  local data = GetPresetData(presetIndex, false, false)[3];

  return {
    color_R = data[1].absolute;
    color_G = data[2].absolute;
    color_B = data[3].absolute;
  }

end

function buildUI()
  local messageBox = {
    title = "ColorGrid",
  }

  MessageBox(messageBox)
end

function buildLayout()

end
-----------------------------------

------------ BuildUI ------------
function buildDefaultUI(groupSuggest, presetSuggest)

  local textInputs = {
    { name = "Offset: ", value = tostring(pluginOffset), whiteFilter = "0123456789" },
    { name = "Grid-Groups", value = groupSuggest, whiteFilter = ",0123456789" },
    { name = "Bump-Groups", value = string.match(groupSuggest, "([^,]+)"), whiteFilter = "0123456789" },
    { name = "Grid-Presets", value = presetSuggest, whiteFilter = ",0123456789" }
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

  for key, value in pairs(defaultUI.inputs) do

    print("Key: " .. key .. " Value: " .. value)

  end
end

return main
