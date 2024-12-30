
--- Plugin Config ---

local appereanceProperty = "APPEREANCE";

local panInvertDMXProperty = "DMXINVERTPAN";
local panInvertDMXProperty = "DMXINVERTTILT";

local dmx = true;
-----------------------

local execute = Cmd;
function print(value)
  Printf(tostring(value));
end

--- Method Credits ---
-- https://github.com/Toom3000/ma3_Magic_ColorGrid --
-- Returns the Fixture Instance from it's ID
----------------------
function getAsFixture(inFixtureIndex)
	local myResult = nil;
	local myLowestSubFixture = nil;
	local myNextSubfixture = GetSubfixture(inFixtureIndex);
	while myNextSubfixture ~= nil do
		myLowestSubFixture = myNextSubfixture;
		myNextSubfixture = GetSubfixture(myLowestSubFixture);		
	end
	if myLowestSubFixture ~= nil then
		myResult = myLowestSubFixture
	end
	return myResult;
end


function getCurrentPanInvertStatus()

end

function getCurrentTiltInvertStatus()

end

function invertPan(fixture)

end

function invertTilt(fixture)

end

function setPatch(fixture, universe, address)

end

function buildUI()

  local inputs = {
    
  }

  local messageBox = {
    title = "Fixture Patch Plugin",
    caller = GetFocusDisplay(),
    commands = {{value = 0, name = "Close"}},
    inputs = inputs
  }

  MessageBox(messageBox);

end

function buildErrorUI()

end

function main()
  
  -- Test Pruposes --
  execute("Clear");
  execute("5");
  -------------------

  local index = SelectionFirst(true);
  local testFixture = getAsFixture(index);

  if(testFixture ~= nil) then

    buildUI();
    testFixture:Dump();

  else

    buildErrorUI();
    print("No Fixture Selected")

  end
end

return main;