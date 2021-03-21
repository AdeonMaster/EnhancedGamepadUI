EnhancedGamepadUI = {}

EnhancedGamepadUI.name = "EnhancedGamepadUI"

local MOUSE_SPEED_FACTOR = 12
local isDrag = false
local _GetGamepadLeftStickX = GetGamepadLeftStickX
local _GetGamepadLeftStickY = GetGamepadLeftStickY

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

function EnhancedGamepadUI:Initialize()
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

function EnhancedGamepadUI.OnAddOnLoaded(event, addonName)
  if addonName == EnhancedGamepadUI.name then
    EnhancedGamepadUI:Initialize()
  end
end

EVENT_MANAGER:RegisterForEvent(EnhancedGamepadUI.name, EVENT_ADD_ON_LOADED, EnhancedGamepadUI.OnAddOnLoaded)
