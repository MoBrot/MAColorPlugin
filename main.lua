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
local pluginButtonWidth = 150;
local pluginButtonHeight = 110;
local pluginButtonSeparation = 6;
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

local layoutItems = {};

local cColMixTypeNone = "None"
local cColMixTypeRGBCMY = "RGB_CMY"
local cColMixTypeWheelFixed = "ColorWheel"
local execute = Cmd;

function print(value)
  Printf(tostring(value))
end

------------ Util ------------

function getSymbol(symbolName)
  return "SYMBOL/symbols/" .. symbolName .. ".png";
end

function getMATricksAppearanceIndex()
  return pluginOffset + (2 * #pluginPresets) + 1;
end

local totalNumberSymbolsToImport = 5;
function getNumbersAppearancesOffset(activeStatus)

  local offset = 0;

  if activeStatus == false then
    offset = totalNumberSymbolsToImport;
  end

  return getMATricksAppearanceIndex() + 1 + offset;
end

function mapMATricksIndexFromGroupArrayIndex(groupArrayID)
  return pluginOffset + groupArrayID - 1;
end

function pluginColorPresetAmount()
  return #pluginGroups * #pluginPresets;
end

function mapMacroIndexFromPresetAndGroup(presetArrayID, groupArrayID)
  return pluginOffset + ((groupArrayID - 1) * #pluginPresets) + (presetArrayID - 1);
end

function mapColorAppearanceFromPresetID(presetArrayID, isActive)

  local appearanceOffset = 0;
  if isActive == false then
    appearanceOffset = appearanceOffset + #pluginPresets;
  end

  return pluginOffset + presetArrayID + appearanceOffset;
end

function getGroupOffsetIndex()
  return pluginOffset + pluginColorPresetAmount();
end

function getAllColorChangeMacrosOffset()
  return getGroupOffsetIndex() + #pluginGroups;
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

function storePoolObject(poolType, index)
  execute("Delete " .. poolType .. " " .. index);
  execute("Store " .. poolType .. " " .. index);
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
    execute("Delete Image " .. image.index);
    execute("Import Image 'Images'." .. image.index .." /File '" .. image.name .. "' /nc /o")
  end

  execute("Delete Appearance " .. (pluginOffset) .. " Thru " .. (pluginOffset + (#pluginPresets * 2)) .. " /nu");
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

  -- Create MATricks Appearance --

  storePoolObject("Appearance", getMATricksAppearanceIndex());
  local matricksAppearance = appearancePool[getMATricksAppearanceIndex()];
  matricksAppearance:Set("name", "MATricks");
  matricksAppearance:Set('mediafilename', getSymbol("matricks"))

  -- Create Number and Calculator Appearances --

  local numberOffsetActiveOffset = getNumbersAppearancesOffset(true) + 1;
  local numberOffsetInActiveOffset = getNumbersAppearancesOffset(false);

  local calculatorOffset = getNumbersAppearancesOffset(true);

  storePoolObject("Appearance", calculatorOffset);
  local calculatorAppearance = appearancePool[calculatorOffset];
  calculatorAppearance:Set("name", "Calculator");
  calculatorAppearance:Set('mediafilename', getSymbol("calculator_white"));

  for i = 1, totalNumberSymbolsToImport do
    
    local currentNumberOffsetActive = numberOffsetActiveOffset + i - 1;
    local currentNumberOffsetInActive = numberOffsetInActiveOffset + i;

    storePoolObject("Appearance", currentNumberOffsetActive);
    storePoolObject("Appearance", currentNumberOffsetInActive);

    local numberOffsetActive = appearancePool[currentNumberOffsetActive];
    numberOffsetActive:Set("name", i - 1 .. " - Active");
    numberOffsetActive:Set('mediafilename', getSymbol("number_" .. i - 1 .. "_white"));

    local numberOffsetInActive = appearancePool[currentNumberOffsetInActive];
    numberOffsetInActive:Set("name", i - 1 .. " - InActive");
    numberOffsetInActive:Set('mediafilename', getSymbol("number_" .. i - 1 .. "_black"));
  end
end

function registerLayoutItem(iobjectType, iobjectIndex, iwidth, iheight, iposX, iposY, irow, icolumn, ivisibleText)

  local finalWidth = iwidth or pluginButtonWidth;
  local finalHeight = iheight or pluginButtonHeight;

  layoutItem = {
    objectType = iobjectType,
    objectIndex = iobjectIndex,
    width = finalWidth,
    height = finalHeight,
    posX = iposX or ((icolumn * finalWidth) + (icolumn * pluginButtonSeparation)),
    posY = iposY or ((irow * finalHeight) + (irow * pluginButtonSeparation)),
    visibleText = ivisibleText
  }

  table.insert(layoutItems, layoutItem);
end

--- Group 0 = All Selector Row, Group #pluginGroups + 1 = Bump Group
function createMacrosForColorRow(macroOffset, defaultActiv, group)

  local macroPool = getGma3Pools().Macro;

  local result = {};

  for pi = 1, #pluginPresets do

    local macroPosition = macroOffset + pi - 1;

    storePoolObject("Macro", macroPosition);
    local currentColorMacro = macroPool[macroPosition];
    currentColorMacro:Set("appearance", mapColorAppearanceFromPresetID(pi, defaultActiv));

    registerLayoutItem("Macro", macroPosition, nil, nil, nil, nil, group, pi, false);
    result[pi] = macroPosition;
  end

  return result;
end

function storeNewMacroLine(macroIndex, name, command)
  execute("Store Macro " .. macroIndex .. " '" .. name .. "' 'Command' '" .. command .. "'");
end

function assignToRecipe(sequenceIndex, assignType, assignTypeValueIndex, cue, part)
  execute("Assign " .. assignType .. " " .. assignTypeValueIndex .. " at cue " .. cue .." part 0." .. part .." Sequence " .. sequenceIndex .. " /nu");
end

function createGridMacrosAndSequenses()

  -- Preset to Appearance map -> 
  local macroPool = getGma3Pools().Macro;
  local sequencePool = getGma3Pools().Sequence;

  -- Create Group Grid --
  for gi = 1, #pluginGroups do

    local macroOffset = pluginOffset + (gi * #pluginPresets) - #pluginPresets;
    local group = getAsGroup(pluginGroups[gi]);

    -- Store MATricks --
    local matricksPosition = mapMATricksIndexFromGroupArrayIndex(gi);
    storePoolObject("MAtricks", matricksPosition);
    local currentMATricks = getGma3Pools().Matricks[matricksPosition];
    currentMATricks:Set("name", group.name .. " Color MATricks");

    -- Create Group Macros --
    local currentGroupMacroIndex = getGroupOffsetIndex() + gi - 1;
    storePoolObject("Macro", currentGroupMacroIndex);
    local currentGroupMacro = macroPool[currentGroupMacroIndex];

    currentGroupMacro:Set("name", group.name);
    currentGroupMacro:Set("appearance", pluginOffset);
    storeNewMacroLine(currentGroupMacroIndex, "Clear", "Clear");
    storeNewMacroLine(currentGroupMacroIndex, "Select Group", "#[Group " .. group.no .. "]");

    registerLayoutItem("Macro", currentGroupMacroIndex, nil, nil, nil, nil, gi, 0, true);

    for pi = 1, #pluginPresets do

      local colorPreset = getAsColorPreset(pluginPresets[pi]);
      local macroPosition = macroOffset + pi - 1;

      -- Sequences --
      storePoolObject("Sequence", macroPosition);
      local currentSequence = sequencePool[macroPosition];
      currentSequence:Set("name", group.name .. " - " .. colorPreset.name);
      currentSequence:Set('offwhenoverridden','true');

      -- Create and Configure Recipe --
      assignToRecipe(macroPosition, "Group", group.no, 1, 1);
      assignToRecipe(macroPosition, "Preset 4.", colorPreset.no, 1, 1);
      assignToRecipe(macroPosition, "MATricks", currentMATricks.no, 1, 1);

    end

    -- Create Color Macros
    local macros = createMacrosForColorRow(macroOffset, false, gi);
    for i = 1, #macros do
      storeNewMacroLine(macros[i], "Go Sequence", "Go+ #[Sequence " .. macros[i] .. "]");
      storeNewMacroLine(macros[i], "Set Active Image", "Assign Appearance " .. mapColorAppearanceFromPresetID(i, true) .. " at Macro ".. macros[i]);
      
      local assignString = "";
      for m = 1, #macros do
        if m ~= i then
          assignString = assignString .. "Assign Appearance " .. mapColorAppearanceFromPresetID(m, false) .. " at Macro " .. macros[m] .. ";";
        end
      end

      storeNewMacroLine(
        macros[i],
        "Assign Deactivating Appearance",
        assignString
      );
    end
  end


  -- Create All Color Change Macros --
    local allColorChangeMacrosOffset = getAllColorChangeMacrosOffset();
    local allColorChangeMacros = createMacrosForColorRow(allColorChangeMacrosOffset, true, 0);

    for macro = 1, #allColorChangeMacros do
      local goString = "";

      for groupIndex = 1, #pluginGroups do
        goString = goString .. "Go+ Macro " .. mapMacroIndexFromPresetAndGroup(macro, groupIndex) .. ";"
      end

      storeNewMacroLine(allColorChangeMacros[macro], "Change Groups", goString);
    end
end

function createMATricksShortcut(macroOffset, matricksFunction, row, columnOffset)

  storePoolObject("Macro", macroOffset .. " Thru " .. macroOffset + totalNumberSymbolsToImport);
  

end

function createMATricksShortCutsAndExtendedOptions()
  local macroPool = getGma3Pools().Macro;

  -- Extended --
  local macroOffset = getAllColorChangeMacrosOffset() + #pluginPresets;

  storePoolObject("Macro", macroOffset);
  local labelMacro = macroPool[macroOffset];
  labelMacro:Set("name", "MATricks Settings");
  labelMacro:Set("appearance", pluginOffset);
  registerLayoutItem("Macro", macroOffset, nil, nil, nil, nil, 0, #pluginPresets + 2, true);

  for gi = 1, #pluginGroups do

    local currentMacroIndex = macroOffset + gi;

    storePoolObject("Macro", currentMacroIndex);
    storeNewMacroLine(currentMacroIndex, "Edit MaTricks", "Edit MATricks " .. mapMATricksIndexFromGroupArrayIndex(gi));

    local currentMacro = macroPool[currentMacroIndex];
    currentMacro:Set("name", "Edit " .. getGma3Pools().Group[pluginGroups[gi]].name .. " Matricks");
    currentMacro:Set("appearance", getMATricksAppearanceIndex());

    registerLayoutItem("Macro", currentMacroIndex, nil, nil, nil, nil, gi, #pluginPresets + 2, false);
  end

  local numbersMacroOffset = macroOffset + #pluginGroups;

  createMATricksShortcut(numbersMacroOffset, "Delay From X", #pluginGroups + 3, 1);
  createMATricksShortcut(numbersMacroOffset + (totalNumberSymbolsToImport * 1), "Delay To X", #pluginGroups + 3, 6);

  createMATricksShortcut(numbersMacroOffset + (totalNumberSymbolsToImport * 2), "Fade From X", #pluginGroups + 4, 1);
  createMATricksShortcut(numbersMacroOffset + (totalNumberSymbolsToImport * 3), "Fade To X", #pluginGroups + 4, 6);
end

function setLayoutItemProperty(layoutIndex, layoutItemIndex, property, value)
  execute("Set Layout " .. layoutIndex .. "." .. layoutItemIndex .. " Property '" .. property .. "' " .. value);
end

function buildLayout()

  local layoutIndex = pluginOffset;

  storePoolObject("Layout", layoutIndex)

  createAppereances();
  createGridMacrosAndSequenses();
  createMATricksShortCutsAndExtendedOptions();

  local layoutItemIndex = 1;
  -- Build Layout --
  for itemKey, itemValue in ipairs(layoutItems) do

    execute("Assign " .. itemValue.objectType .. " " .. itemValue.objectIndex .. " at Layout " .. layoutIndex);

    setLayoutItemProperty(layoutIndex, layoutItemIndex, "PosX", itemValue.posX);
    setLayoutItemProperty(layoutIndex, layoutItemIndex, "PosY", itemValue.posY * -1);
    setLayoutItemProperty(layoutIndex, layoutItemIndex, "PositionW", itemValue.width);
    setLayoutItemProperty(layoutIndex, layoutItemIndex, "PositionH", itemValue.height);

    if itemValue.visibleText == false then
      execute("Set Layout " .. layoutIndex .. "." .. layoutItemIndex .. " Property 'VisibilityObjectName' off Executor");
    end

    layoutItemIndex = layoutItemIndex + 1;
  end

  -- Set Default Value
  execute("Go+ Macro " .. getAllColorChangeMacrosOffset());
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