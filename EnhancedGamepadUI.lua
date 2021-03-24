EnhancedGamepadUI = {}

EnhancedGamepadUI.name = "EnhancedGamepadUI"
EnhancedGamepadUI.defaultSavedVariables = {
  usePCLabels = false
}

local MOUSE_SPEED_FACTOR = 12
local isDrag = false

function EnhancedGamepadUI:InitializeSettingsPanel()
  local LAM = LibAddonMenu2
  local panelName = "EnhancedGamepadUIPanel"
  local panelData = {
    type = "panel",
    name = "EnhancedGamepadUI",
    displayName = "Enhanced Gamepad UI",
    author = "AdeonMaster",
    version = "1.1",
    website = "https://www.esoui.com/downloads/info2975-EnhancedGamepadUI.html",
    registerForRefresh = true,
    registerForDefaults = true
  }
  local panel = LAM:RegisterAddonPanel(panelName, panelData)
  local optionsData = {
    {
      type = "checkbox",
      name = "Use PC key labels for Gamepad UI",
      getFunc = function() return EnhancedGamepadUI.savedVariables.usePCLabels end,
      setFunc = function(value) EnhancedGamepadUI.savedVariables.usePCLabels = value end,
      warning = "Will need to reload the UI",
    }
  }
  LAM:RegisterOptionControls(panelName, optionsData)
end

function EnhancedGamepadUI:ExtendControlsHandlers()
  function onMouseUp(self, mouseButton, upInside, shift, ctrl, alt, command)
    if mouseButton == MOUSE_BUTTON_INDEX_LEFT then
      isDrag = false
      WINDOW_MANAGER:SetMouseCursor(MOUSE_CURSOR_DEFAULT_CURSOR)
    end
  end
  
  function onMouseDown(self, mouseButton, upInside, shift, ctrl, alt, command)
    if mouseButton == MOUSE_BUTTON_INDEX_LEFT then
      isDrag = true
      WINDOW_MANAGER:SetMouseCursor(MOUSE_CURSOR_PAN)
    end
  end

  -- champion.lua
  local championPerksCanvasControl = GetControl("ZO_ChampionPerksCanvas")

  ZO_PreHookHandler(championPerksCanvasControl, "OnMouseUp", onMouseUp)
  ZO_PreHookHandler(championPerksCanvasControl, "OnMouseDown", onMouseDown)

  -- worldmap.lua
  local worldMapScrollControl = GetControl("ZO_WorldMapScroll")
  local worldMapContainerControl = GetControl("ZO_WorldMapContainer")

  ZO_PreHookHandler(worldMapContainerControl, "OnMouseUp", onMouseUp)
  ZO_PreHookHandler(worldMapContainerControl, "OnMouseDown", onMouseDown)

  ZO_PreHookHandler(worldMapScrollControl, "OnMouseUp", onMouseUp)
  ZO_PreHookHandler(worldMapScrollControl, "OnMouseDown", onMouseDown)
end

function EnhancedGamepadUI:Initialize()
  -- Load saved variables
  EnhancedGamepadUI.savedVariables = ZO_SavedVars:NewAccountWide("EnhancedGamepadUI_SavedVariables", 1, nil, EnhancedGamepadUI.defaultSavedVariables)

  -- Init LibAddonMenu2 settings panel
  EnhancedGamepadUI:InitializeSettingsPanel()

  EnhancedGamepadUI:ExtendControlsHandlers()
end

function EnhancedGamepadUI.OnAddOnLoaded(event, addonName)
  if addonName == EnhancedGamepadUI.name then
    EnhancedGamepadUI:Initialize()
  end
end

EVENT_MANAGER:RegisterForEvent(EnhancedGamepadUI.name, EVENT_ADD_ON_LOADED, EnhancedGamepadUI.OnAddOnLoaded)

-- esoui/libraries/zo_directionalinput/zo_directionalinput.lua
local _GetGamepadLeftStickX = GetGamepadLeftStickX
function GetGamepadLeftStickX()
  local gamepadDeltaX = _GetGamepadLeftStickX()

  if isDrag then
    if ZO_WorldMap_IsWorldMapShowing() or SYSTEMS:IsShowing("champion") then
      local mouseDeltaX, mouseDeltaY = GetUIMouseDeltas()

      if mouseDeltaX ~= 0 then
        return mouseDeltaX / MOUSE_SPEED_FACTOR
      end
    end
  end

  return gamepadDeltaX
end

local _GetGamepadLeftStickY = GetGamepadLeftStickY
function GetGamepadLeftStickY()
  local gamepadDeltaY = _GetGamepadLeftStickY()

  if isDrag then
    if ZO_WorldMap_IsWorldMapShowing() or SYSTEMS:IsShowing("champion") then
      local mouseDeltaX, mouseDeltaY = GetUIMouseDeltas()

      if mouseDeltaY ~= 0 then
        return (mouseDeltaY * -1) / MOUSE_SPEED_FACTOR
      end
    end
  end

  return gamepadDeltaY
end

-- esoui/common/zo_keybindings/keybindingutils.lua
function ZO_Keybindings_GetHighestPriorityBindingStringFromAction(actionName, textOptions, textureOptions, alwaysPreferGamepadMode, showAsHold)
  local preferGamepadMode
  -- custom code start
  if IsInGamepadPreferredMode() and EnhancedGamepadUI.savedVariables and EnhancedGamepadUI.savedVariables.usePCLabels then
    preferGamepadMode = false
  else
    if alwaysPreferGamepadMode == nil then
      preferGamepadMode = IsInGamepadPreferredMode()
    else
      preferGamepadMode = alwaysPreferGamepadMode
    end
  end
  -- custom code end

  local key, mod1, mod2, mod3, mod4 = GetHighestPriorityActionBindingInfoFromName(actionName, preferGamepadMode)

  if key ~= KEY_INVALID then
    if showAsHold then
      local holdKey = ConvertKeyPressToHold(key)
      if holdKey ~= KEY_INVALID then
        key = holdKey
      end
    end

    -- custom code start
    if IsInGamepadPreferredMode() and EnhancedGamepadUI.savedVariables and EnhancedGamepadUI.savedVariables.usePCLabels then
      local layerIndex, categoryIndex, actionIndex = GetActionIndicesFromName(actionName)
      local pcKey = GetActionBindingInfo(layerIndex, categoryIndex, actionIndex, 1)

      return "|u25%:25%:key:"..GetKeyName(pcKey).."|u", pcKey, mod1, mod2, mod3, mod4
    end
    -- custom code end

    return ZO_Keybindings_GetBindingStringFromKeys(key, mod1, mod2, mod3, mod4, textOptions, textureOptions), key, mod1, mod2, mod3, mod4
  end

  return nil
end

-- esoui/ingame/lockpick/lockpick.lua
local STARTING_NORMALIZED_LOCKPICK_X = .53
local GAMEPAD_SPEED_FACTOR = 3.5

function ZO_Lockpick:UpdateVirtualMousePosition()
  if not self.virtualMouseX then
    self.virtualMouseX = zo_lerp(self.lockpickLowerBound, self.lockpickUpperBound, STARTING_NORMALIZED_LOCKPICK_X)
    self.virtualNormalizedMouseX = STARTING_NORMALIZED_LOCKPICK_X
    self:OnVirtualLockpickPositionChanged()
  else
    -- custom code start
    local uiMouseDelta = GetUIMouseDeltas()
    local gamepadDelta = (ZO_Gamepad_GetLeftStickEasedX() * GAMEPAD_SPEED_FACTOR)
    local deltaX

    if uiMouseDelta ~= 0 then
      deltaX = uiMouseDelta
    else
      deltaX = gamepadDelta
    end
    -- custom code end
    deltaX = deltaX * GetFrameDeltaNormalizedForTargetFramerate()

    if deltaX ~= 0 then
      local newX = self.virtualMouseX + deltaX

      local clampedX = zo_clamp(newX, self.lockpickLowerBound, self.lockpickUpperBound)
      if clampedX ~= self.virtualMouseX then
        self.virtualMouseX = clampedX
        self.virtualNormalizedMouseX = (clampedX - self.lockpickLowerBound) / (self.lockpickUpperBound - self.lockpickLowerBound)

        self:OnVirtualLockpickPositionChanged()
      end
    end
  end
end

-- libraries/zo_radialmenu/zo_radialmenu.lua
function ZO_RadialMenu:UpdateVirtualMousePositionFromGamepad()
  -- custom code start
  if self:UpdateVirtualMousePosition() then
    return true
  end
  -- custom code end

  local outerRadius = zo_max(self.control:GetDimensions()) * .5
  local x, y = DIRECTIONAL_INPUT:GetXY(unpack(self.directionInputs))
  if (not self.selectIfCentered) or (x ~= 0) or (y ~= 0) then
    self.virtualMouseX = x * outerRadius
    self.virtualMouseY = -y * outerRadius
      
    return self:ShouldUpdateSelection()
  end

  return false
end  
