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
