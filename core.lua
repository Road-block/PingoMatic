PingoMatic = AceLibrary("AceAddon-2.0"):new("AceConsole-2.0", "AceDB-2.0", "AceEvent-2.0", "AceHook-2.1", "FuBarPlugin-2.0")
local T = AceLibrary("Tablet-2.0")
local L = AceLibrary("AceLocale-2.2"):new("PingoMatic")
local BS = AceLibrary("Babble-Spell-2.2")
local roster = AceLibrary("RosterLib-2.0")

local defaults = {
  Pinger = true,
  Filter = "all",
  Fps = 64,
  Fade = 2,
  Ratio = 0.5,
  Scale = 1.0,
  Alpha = 0.9,
  Radius = 256,
  Width = 256,
  Health = 100,
  Debuff = false,
  Rate = 3,
  Repeat = 3,
  Color = {r = 1.00, g = 0.00, b = 0.00},
  GPSColor = {r = 0.25, g = 0.25, b = 1.00},
  GPSFlash = {r = 0.00, g = 1.00, b = 0.00},
  Whitelist = {},
  DebuffList = {L["Plague"]},
}
local empty = {}
PingoMatic._minimapPlayerModel = false
PingoMatic._cameraPan = false
PingoMatic._coord = { x = 50, y = 50 }
PingoMatic._gps = { x = -1, y = -1 }
PingoMatic._coordsystem = "ping"

local options  = {
  type = "group",
  handler = PingoMatic,
  args =
  {
    Pinger =
    {
      name = L["Pinger"],
      desc = L["Show Who Pinged on Minimap"],
      type = "toggle",
      get  = "GetPingerStatusOption",
      set  = "SetPingerStatusOption",
      order = 10,
    },
    Coords = {
      name = L["Coords"],
      desc = L["Point to Custom Coords\nx.xx y.yy"],
      type = "text",
      usage = "<input>",
      get  = false,
      set  = "SetCoords",
      input = true,
      validate = "VerifyCoord",
      order = 11,
    },
    GPS = {
      name = L["GPS"],
      desc = string.format(L["Session persistent Arrow\nx.xx y.yy\nType |cffC0C0C0%s|r to remove"],DELETE),
      type = "text",
      usage = "<input>",
      get  = "GetGPS",
      set  = "SetGPS",
      input = true,
      validate = "VerifyCoord",
      order = 12,
    },
    Arrow = {
      type = "group",
      handler = PingoMatic,
      name = L["Arrow"],
      desc = L["Arrow Options"],
      order = 20,
      args = {
        Fps = {
          name = L["FPS"],
          desc = L["Arrow Refresh Rate"],
          type = "range",
          get  = "GetFPSOption",
          set  = "SetFPSOption",
          min  = 8,
          max  = 64,
          step = 8,
          order = 21,
        },
        Fade = {
          name = L["Fade"],
          desc = L["Arrow Fade Time"],
          type = "range",
          get  = "GetFadeOption",
          set  = "SetFadeOption",
          min  = 1,
          max  = 10,
          step = 1,
          order = 22,
        },
        Ratio = {
          name = L["Ratio"],
          desc = L["Set Arrow Ratio"],
          type = "range",
          get  = "GetRatioOption",
          set  = "SetRatioOption",
          min  = 0.1,
          max  = 1.0,
          step = 0.1,
          order = 23,
        },
        Scale = {
          name = L["Scale"],
          desc = L["Set Arrow Scaling"],
          type = "range",
          get  = "GetScaleOption",
          set  = "SetScaleOption",
          min  = 0.2,
          max  = 2,
          step = 0.1,
          order = 24,
        },
        Alpha = {
          name = L["Alpha"],
          desc = L["Set Arrow Alpha"],
          type = "range",
          get  = "GetAlphaOption",
          set  = "SetAlphaOption",
          min  = 0.1,
          max  = 1.0,
          step = 0.1,
          order = 25,
        },
        Radius = {
          name = L["Radius"],
          desc = L["Set Arrow Radius"],
          type = "range",
          get  = "GetRadiusOption",
          set  = "SetRadiusOption",
          min  = 128,
          max  = 256,
          step = 8,
          order = 26,
        },
        Width = {
          name = L["Width"],
          desc = L["Set Arrow Width"],
          type = "range",
          get  = "GetWidthOption",
          set  = "SetWidthOption",
          min  = 128,
          max  = 256,
          step = 8,
          order = 27,
        },
        Color = {
          name = L["Color"],
          desc = L["Set Arrow Color"],
          type = "color",
          get  = "GetArrowColor",
          set  = "SetArrowColor",
          order = 28,
        },
        GPSColor = {
          name = L["GPS Color"],
          desc = L["Set GPS Arrow Color"],
          type = "color",
          get  = "GetGPSColor",
          set  = "SetGPSColor",
          order = 29,
        },
        GPSFlash = {
          name = L["GPS Flash Color"],
          desc = L["Set GPS Arrow Flash Color"],
          type = "color",
          get  = "GetGPSFlashColor",
          set  = "SetGPSFlashColor",
          order = 30
        },
      },
    },    
    Filter =
    {
      name = L["Filter"],
      desc = L["Only show pings from"],
      type = "text",
      get  = "GetFilterOption",
      set  = "SetFilterOption",
      usage = "<channel>",
      disabled = function() return not PingoMatic._minimapPlayerModel end,
      order = 40,
      validate = {["all"]=ALL,["guild"]=GUILD,["assist"]=L["Assist"], ["leader"]=L["Leader"], ["whitelist"]=L["Whitelist"]},
    },
    WhiteList = {
      type = "group",
      handler = PingoMatic,
      name = L["Whitelist"],
      desc = L["Whitelist Management"],
      order = 50,
      hidden = function() return PingoMatic.db.profile.Filter ~= "whitelist" end,
      args = {
        Add = {
          name = L["Add"],
          desc = L["Add name to Whitelist"],
          type = "text",
          get  = false,
          set  = "AddToWhitelist",
          usage = "<name>",
          order = 51,
        },
        Remove = {
          name = L["Remove"],
          desc = L["Remove name from Whitelist"],
          type = "text",
          get = false,
          set = "RemoveFromWhitelist",
          usage = "<name>",
          validate = empty,
          order = 52,
        },
      },
    },
    Autoping = 
    {
      type = "group",
      handler = PingoMatic,
      name = L["Autoping"],
      desc = L["Autoping Options"],
      order = 60,
      args = {
        Health = {
          name = L["Health"],
          desc = L["Ping me at Low Health (100 to disable)"],
          type = "range",
          get  = "GetHealthStatusOption",
          set  = "SetHealthStatusOption",
          min  = 0,
          max  = 100,
          step = 5,
          order = 61,
        },
        Debuff = {
          name = L["Debuff"],
          desc = L["Ping me when Debuffed"],
          type = "toggle",
          get  = "GetDebuffOption",
          set  = "SetDebuffOption",
          order = 62,
        },
        DebuffList = {
          type = "group",
          name = L["DebuffList"],
          desc = L["DebuffList Management"],
          handler = PingoMatic,
          hidden = function() return not PingoMatic.db.profile.Debuff end,
          order = 63,
          args = {
            Add = {
              name = L["Add"],
              desc = L["Add debuff"],
              type = "text",
              get  = false,
              set = "AddToDebuffList",
              usage = "<name>",
              order = 64,
            },
            Remove = {
              name = L["Remove"],
              desc = L["Remove debuff"],
              type = "text",
              get = false,
              set = "RemoveFromDebuffList",
              usage = "<name>",
              validate = empty,
              order = 65,
            },
          },
        },
        Rate = {
          name = L["Rate"],
          desc = L["Max rate of autoping"],
          type = "range",
          get  = "GetRateOption",
          set  = "SetRateOption",
          min  = 1,
          max  = 5,
          step = 1,
          order = 66,
        },
        Repeat = {
          name = L["Repeat"],
          desc = L["Max repeats of autoping"],
          type = "range",
          get  = "GetRepeatOption",
          set  = "SetRepeatOption",
          min  = 1,
          max  = 3,
          step = 1,
          order = 67,
        },
      },
    },
  },
}

---------
-- FuBar
---------
PingoMatic.hasIcon = [[Interface\Minimap\Ping\ping2]]
PingoMatic.title = L["PingoMatic"]
PingoMatic.defaultMinimapPosition = 245
PingoMatic.defaultPosition = "CENTER"
PingoMatic.cannotDetachTooltip = true
PingoMatic.tooltipHiddenWhenEmpty = false
PingoMatic.hideWithoutStandby = true
PingoMatic.independentProfile = true

function PingoMatic:OnTooltipUpdate()
  local hint = L["|cffFFA500Click:|r Ping my location\n|cffFFA500Right-Click:|r Options"]
  T:SetHint(hint)
end

function PingoMatic:OnTextUpdate()
  self:SetText(L["PingoMatic"])
end

function PingoMatic:OnClick()
  self:PingMe()
end

function PingoMatic:refreshOptions()
  options.args.WhiteList.args.Remove.validate = self.db.profile.Whitelist
  options.args.Autoping.args.DebuffList.args.Remove.validate = self.db.profile.DebuffList
end

function PingoMatic:OnInitialize() -- ADDON_LOADED (1)
  self:RegisterDB("PingoMaticDB")
  self:RegisterDefaults("profile", defaults )
  self:RegisterChatCommand( { "/pingo", "/pingomatic" }, options )
  self.OnMenuRequest = options
  if not FuBar then
    self.OnMenuRequest.args.hide.guiName = L["Hide minimap icon"]
    self.OnMenuRequest.args.hide.desc = L["Hide minimap icon"]
  end
  self._minimapPlayerModel = self:SaveMinimapPlayerModel(Minimap:GetChildren()) or false
end

function PingoMatic:IconUpdate()
  if self.db.profile.Pinger then
    self:SetIcon([[Interface\Minimap\Ping\ping2]])
  else
    self:SetIcon([[Interface\Minimap\Ping\ping4]])
  end
end

function PingoMatic:OnEnable() -- PLAYER_LOGIN (2)
  self:refreshOptions()
  self:RegisterEvent("PLAYER_ENTERING_WORLD")
  self:IconUpdate()
  self:UpdateTooltip()
end

function PingoMatic:OnDisable()
  self:UnregisterAllEvents()
  self:CancelAllScheduledEvents()
  self:UnhookAll()
  self:IconUpdate()
  self:Print(L["Disabling"])
end

function PingoMatic:SaveMinimapPlayerModel(...)
  for i = arg.n, 1, -1 do
    if arg[i]:IsObjectType("Model") and not arg[i]:GetName() and not self._minimapPlayerModel then
      return arg[i]
    end
  end
end

PingoMatic._hexColorCache = {}
function PingoMatic:RGBtoHEX(colortab,r,g,b)
  if (colortab) then
    local r,g,b
    if colortab.r then
      r,g,b = colortab.r, colortab.g, colortab.b
    elseif table.getn(colortab) == 3 then
      r,g,b = colortab[1],colortab[2],colortab[3]
    end
    if r and g and b then
      local colorKey = string.format("%s%s%s",r,g,b)
      if self._hexColorCache[colorKey] == nil then
        self._hexColorCache[colorKey] = string.format("|cff%02x%02x%02x", r*255, g*255, b*255)
      end
      return self._hexColorCache[colorKey]
    end
  elseif r and g and b then
    local colorKey = string.format("%s%s%s",r,g,b)
    if self._hexColorCache[colorKey] == nil then
      self._hexColorCache[colorKey] = string.format("|cff%02x%02x%02x", r*255, g*255, b*255)
    end
    return self._hexColorCache[colorKey]
  end
  return ""
end

local CUSTOM_CLASS_COLORS = {}
do
  for class,colorTab in pairs(RAID_CLASS_COLORS) do
    CUSTOM_CLASS_COLORS[class] = colorTab
    CUSTOM_CLASS_COLORS[class].hex = PingoMatic:RGBtoHEX(colorTab)
  end
  CUSTOM_CLASS_COLORS["UNKNOWN"] = {r = 0.6, g = 0.6, b = 0.6, hex = "|cff999999"}
end

function PingoMatic:CreateMinimapMessage()
  self._frames = self._frames or {}
  if not self._frames.Minimessage then
    self._frames.Minimessage = CreateFrame("MessageFrame",nil,Minimap)
    self._frames.Minimessage:SetFrameStrata("DIALOG")
    self._frames.Minimessage:SetWidth(500)
    self._frames.Minimessage:SetHeight(75)
    self._frames.Minimessage:SetPoint("CENTER",Minimap,"CENTER",0,0)
    self._frames.Minimessage:SetToplevel(true)
    self._frames.Minimessage:SetFadeDuration(self.db.profile.Fade)
    self._frames.Minimessage:SetTimeVisible(0.1)
    self._frames.Minimessage:SetInsertMode("TOP")
    self._frames.Minimessage:SetFont(STANDARD_TEXT_FONT,22,"OUTLINE")
    self._frames.Minimessage:SetJustifyH("CENTER")
    self._frames.Minimessage:Show()
  end
end

function PingoMatic:CreateArrow(arrowType,x,y,alpha)
  self._frames = self._frames or {}
  if not self._frames[arrowType] then
    self._frames[arrowType] = CreateFrame("Frame",nil,UIParent)
    self._frames[arrowType]:EnableMouse(false)
    self._frames[arrowType]:SetFrameStrata("TOOLTIP")
    self._frames[arrowType]:SetWidth(256)
    self._frames[arrowType]:SetHeight(256)
    self._frames[arrowType].tx = self._frames[arrowType]:CreateTexture(nil,"OVERLAY")
    self._frames[arrowType].tx:SetTexture([[Interface\AddOns\PingoMatic\img\Arrow.tga]])
    self._frames[arrowType].tx:SetWidth(256)
    self._frames[arrowType].tx:SetHeight(256)
    self._frames[arrowType].tx:SetAllPoints(self._frames[arrowType])
    self._frames[arrowType].txt = self._frames[arrowType]:CreateFontString(nil,"ARTWORK","GameFontNormal")
    self._frames[arrowType].txt:SetWidth(256)
    self._frames[arrowType].txt:SetHeight(32)
    self._frames[arrowType].txt:SetPoint("BOTTOM",self._frames[arrowType],"TOP",0,0)
    self._frames[arrowType].txt:SetJustifyH("CENTER")
  end
  local color
  if arrowType == "Ping" then
    color = self.db.profile.Color
  elseif arrowType == "GPS" then
    color = self.db.profile.GPSColor
  end
  self._frames[arrowType].tx:SetVertexColor(color.r,color.g,color.b)
  if not x then x = 0 end
  if not y then y = 0 end
  self._frames[arrowType]:SetPoint("CENTER",UIParent,"CENTER",x,y)
    if not alpha then alpha = 0 end
  self._frames[arrowType]:SetAlpha(alpha)
  self._frames[arrowType]:Show()
end

function PingoMatic:UpdateArrow(arrowType,height,scale,colortab,ULx,ULy,LLx,LLy,URx,URy,LRx,LRy,x,y,text,alpha,txalpha)
  if not self._frames and self._frames[arrowType] then
    self:CreateArrow(arrowType)
  end
  if (height) then
    self._frames[arrowType]:SetHeight(height)
  end
  if (scale) then
    self._frames[arrowType]:SetScale(scale)
  end
  if colortab and type(colortab)=="table" then
    self._frames[arrowType].tx:SetVertexColor(colortab.r,colortab.g,colortab.b)
  end
  if (ULx) and (LRy) then
    self._frames[arrowType].tx:SetTexCoord(ULx,ULy,LLx,LLy,URx,URy,LRx,LRy)
  end
  if (x) and (y) then
    self._frames[arrowType]:ClearAllPoints()
    self._frames[arrowType]:SetPoint("CENTER",UIParent,"CENTER",x,y)
  end
  if (text) then
    self._frames[arrowType].txt:SetText(text)
  end
  if (alpha) then
    self._frames[arrowType]:SetAlpha(alpha)
  end
  if (txalpha) then
    self._frames[arrowType].tx:SetAlpha(txalpha)
  end
end

function PingoMatic:inTable(value,tab)
  value = string.lower(tostring(value))
  for k,v in pairs(tab) do
    if string.lower(tostring(v)) == value then
      return k
    end
  end
  return false
end

function PingoMatic:GetPingerStatusOption()
  return self.db.profile.Pinger
end
function PingoMatic:SetPingerStatusOption(newStatus)
  self.db.profile.Pinger = newStatus
  self:IconUpdate()
end
function PingoMatic:GetFilterOption()
  return self.db.profile.Filter
end
function PingoMatic:SetFilterOption(newFilter)
  self.db.profile.Filter = newFilter
end
function PingoMatic:AddToWhitelist(name)
  if not self:inTable(name, self.db.profile.Whitelist) then
    table.insert(self.db.profile.Whitelist,name)
  end
  self:refreshOptions()
end
function PingoMatic:RemoveFromWhitelist(name)
  local found = self:inTable(name, self.db.profile.Whitelist)
  if found then
    table.remove(self.db.profile.Whitelist, found)
  end
  self:refreshOptions()
end
function PingoMatic:GetFPSOption()
  return self.db.profile.Fps
end
function PingoMatic:SetFPSOption(newFPS)
  self.db.profile.Fps = newFPS
  self:UpdateTimer(tonumber(newFPS))
end
function PingoMatic:GetFadeOption()
  return self.db.profile.Fade
end
function PingoMatic:SetFadeOption(newFade)
  self.db.profile.Fade = newFade
end
function PingoMatic:GetRatioOption()
  return self.db.profile.Ratio
end
function PingoMatic:SetRatioOption(newRatio)
  self.db.profile.Ratio = newRatio
end
function PingoMatic:GetScaleOption()
  return self.db.profile.Scale
end
function PingoMatic:SetScaleOption(newScale)
  self.db.profile.Scale = newScale
end
function PingoMatic:GetAlphaOption()
  return self.db.profile.Alpha
end
function PingoMatic:SetAlphaOption(newAlpha)
  self.db.profile.Alpha = newAlpha
end
function PingoMatic:GetRadiusOption()
  return self.db.profile.Radius
end
function PingoMatic:SetRadiusOption(newRadius)
  self.db.profile.Radius = newRadius
end
function PingoMatic:GetWidthOption()
  return self.db.profile.Width
end
function PingoMatic:SetWidthOption(newWidth)
  self.db.profile.Width = newWidth
end
function PingoMatic:GetArrowColor()
  return self.db.profile.Color.r, self.db.profile.Color.g, self.db.profile.Color.b
end
function PingoMatic:SetArrowColor(r,g,b,a)
  self.db.profile.Color.r = r
  self.db.profile.Color.g = g
  self.db.profile.Color.b = b
end
function PingoMatic:GetGPSColor()
  return self.db.profile.GPSColor.r, self.db.profile.GPSColor.g, self.db.profile.GPSColor.b
end
function PingoMatic:SetGPSColor(r,g,b,a)
  self.db.profile.GPSColor.r = r
  self.db.profile.GPSColor.g = g
  self.db.profile.GPSColor.b = b  
end
function PingoMatic:GetGPSFlashColor()
  return self.db.profile.GPSFlash.r, self.db.profile.GPSFlash.g, self.db.profile.GPSFlash.b
end
function PingoMatic:SetGPSFlashColor(r,g,b,a)
  self.db.profile.GPSFlash.r = r
  self.db.profile.GPSFlash.g = g
  self.db.profile.GPSFlash.b = b  
end
function PingoMatic:GetHealthStatusOption()
  return self.db.profile.Health
end
function PingoMatic:SetHealthStatusOption(newHPpct)
  self.db.profile.Health = newHPpct
end
function PingoMatic:GetDebuffOption()
  return self.db.profile.Debuff
end
function PingoMatic:SetDebuffOption(newStatus)
  self.db.profile.Debuff = newStatus
end
function PingoMatic:AddToDebuffList(debuff)
  if not self:inTable(debuff, self.db.profile.DebuffList) then
    table.insert(self.db.profile.DebuffList,debuff)
  end
  self:refreshOptions()  
end
function PingoMatic:RemoveFromDebuffList(debuff)
  local found = self:inTable(debuff, self.db.profile.DebuffList)
  if found then
    table.remove(self.db.profile.DebuffList, found)
  end
  self:refreshOptions()  
end
function PingoMatic:GetRateOption()
  return self.db.profile.Rate
end
function PingoMatic:SetRateOption(newRate)
  self.db.profile.Rate = newRate
end
function PingoMatic:GetRepeatOption()
  return self.db.profile.Repeat
end
function PingoMatic:SetRepeatOption(newRepeat)
  self.db.profile.Repeat = newRepeat
end

function PingoMatic:ParseCoords(input)
  input = tostring(input)
  for x,y in string.gfind(input,"(%d+%.?%d*)%s+(%d+%.?%d*)") do
    return tonumber(x), tonumber(y)
  end
end

function PingoMatic:VerifyCoord(input)
  if input == DELETE then return true end
  local x, y = self:ParseCoords(input)
  if x and y and (x>=0 and x<=100) and (y>=0 and y<=100) then return true end
  self:Print(L["Invalid Coord Input. Use: x[.xx] y[.yy]"])
end

function PingoMatic:SetCoords(input)
  local x, y = self:ParseCoords(input)
  if x and y then
    self._coord.x = x
    self._coord.y = y
    self:UpdateArrow("Ping",nil,nil,nil,nil,nil,nil,nil,nil,nil,nil,nil,nil,nil,string.format("%2.1f, %2.1f", x, y))
    self._coordsystem = "coord"
    UIFrameFadeOut(self._frames.Ping,1,1,0)
  end
end
function PingoMatic:SetGPS(input)
  if input == DELETE then
    self._gps.x = -1
    self._gps.y = -1
    self._frames.GPS:SetAlpha(0)
    return
  end
  local x, y = self:ParseCoords(input)
  if x and y then
    self._gps.x = x
    self._gps.y = y
    self:UpdateArrow("GPS",nil,nil,self.db.profile.GPSColor,nil,nil,nil,nil,nil,nil,nil,nil,nil,nil,string.format("%2.1f, %2.1f", x, y),1,self.db.profile.Alpha)
  end
end

function PingoMatic:GetGPS()
  if self._gps.x == -1 and self._gps.y == -1 then return end
  return string.format("%s %s",self._gps.x,self._gps.y)
end

function PingoMatic:UpdateTimer(fps)
  self:ScheduleRepeatingEvent("PingoMatic_Update", self.OnUpdate, 1/fps, self)
end

function PingoMatic:GetCoords(system)
  local x = 0
  local y = 1.0
  local px, py = GetPlayerMapPosition("player")
  if (system == "ping") then
    x, y = Minimap:GetPingPosition()
    x = x + 0.05
    y = y + 0.05
  elseif (system == "coord") then
    x = self._coord.x -(px * 100)
    y =(100 - self._coord.y) -((1 - py) * 100)
  elseif (system == "gps") then
    x = self._gps.x -(px * 100)
    y =(100 - self._gps.y) -((1 - py) * 100)
  end
  return x, y  
end

local PI = math.pi
function PingoMatic:OnUpdate()
  local pitch, yaw, squish
  if not self._minimapPlayerModel then return end
  
  local facing = self._minimapPlayerModel:GetFacing() -(1.5 * PI)
  SaveView(5)
  pitch = tonumber(GetCVar("cameraPitchD"))
  yaw = tonumber(GetCVar("cameraYawD"))
  yaw = yaw *(2 * PI) / 360

  if self._cameraPan or IsMouselooking() then
    facing = yaw +(PI / 2)
  else
    facing = facing + yaw
  end

  squish = abs(pitch) / 90
  
  local lastx, lasty = self:GetCoords(self._coordsystem)
  local angle = math.atan2(lasty, lastx)

  local bearing = angle - facing
  if (pitch < 0) then
    bearing = - bearing + PI
  end
  local r = (5 * PI / 4) - bearing

  local sinr = math.sin(r) * 0.7071067811
  local cosr = math.cos(r) * 0.7071067811

  self:UpdateArrow("Ping",self.db.profile.Width * squish,nil,nil,0.5-sinr, 0.5+cosr, 0.5-cosr, 0.5-sinr, 0.5+cosr, 0.5+sinr, 0.5+sinr, 0.5-cosr, -math.sin(bearing) * self.db.profile.Radius, math.cos(bearing) * self.db.profile.Radius * squish)

  if (self._gps.x ~= -1) and (self._gps.y ~= -1) then
    self:UpdateArrow("GPS", self.db.profile.Width * squish)
    lastx, lasty = self:GetCoords("gps")

    if (math.abs(lastx) < 0.05) and (math.abs(lasty) < 0.05) then
      self:UpdateArrow("GPS",nil,nil,self.db.profile.GPSFlash,nil,nil,nil,nil,nil,nil,nil,nil,nil,nil, string.format(">> %2.1f, %2.1f <<", self._gps.x, self._gps.y))
      UIFrameFadeOut(self._frames.GPS, 1.0, 1.0, 0.0)
      PlaySound("MapPing")
      self._gps.x = -1
      self._gps.y = -1
      return
    end

    angle = math.atan2(lasty, lastx)
    bearing = angle - facing
    if (pitch < 0) then
      bearing = - bearing + PI
    end
    r =(5 * PI / 4) - bearing
    sinr = math.sin(r) * 0.7071067811
    cosr = math.cos(r) * 0.7071067811

    self:UpdateArrow("GPS",nil,nil,nil,0.5-sinr, 0.5+cosr, 0.5-cosr, 0.5-sinr, 0.5+cosr, 0.5+sinr, 0.5+sinr, 0.5-cosr, -math.sin(bearing) * self.db.profile.Radius, math.cos(bearing) * self.db.profile.Radius * squish)
  end  
end

function PingoMatic:OnWorldMouseDown()
  self.hooks[WorldFrame].OnMouseDown()
  if arg1 == "LeftButton" then
    self._cameraPan = true
  end
end

function PingoMatic:OnWorldMouseUp()
  self.hooks[WorldFrame].OnMouseUp()
  if arg1 == "LeftButton" then
    self._cameraPan = false
  end
end

function PingoMatic:MINIMAP_PING()
  if not self._minimapPlayerModel then return end
  local unitName = UnitName(arg1)
  if not unitName then return end
  local leader = UnitIsPartyLeader(arg1)
  if self.db.profile.Filter == "leader" and not leader then return end
  if self.db.profile.Filter == "whitelist" and not self:inTable(unitName, self.db.profile.Whitelist) then return end
  if self.db.profile.Pinger then
    local _, eClass = UnitClass(arg1)
    local msg
    if leader then
      msg = PVP_RANK_LEADER
    end
    if eClass and CUSTOM_CLASS_COLORS[eClass] then
      msg = msg and string.format("%s\n%s",msg,CUSTOM_CLASS_COLORS[eClass].hex) or CUSTOM_CLASS_COLORS[eClass].hex
    end
    msg = string.format("%s%s|r",msg,unitName)
    self._frames.Ping.txt:SetText(msg)
    self._frames.Minimessage:AddMessage(msg)
  else
    self._frames.Ping.txt:SetText("")
  end
  self._coordsystem = "ping"
  UIFrameFadeOut(self._frames.Ping, self.db.profile.Fade, 1, 0)
end

function PingoMatic:PLAYER_ENTERING_WORLD()
  self:CreateArrow("Ping",nil,nil,0)
  self:CreateArrow("GPS",nil,nil,0)
  self:UpdateArrow("Ping",self.db.profile.Width * self.db.profile.Ratio, self.db.profile.Scale)
  self:UpdateArrow("GPS",self.db.profile.Width * self.db.profile.Ratio, self.db.profile.Scale)
  self:CreateMinimapMessage()
  if not self:IsEventScheduled("PingoMatic_Update") then
    self:UpdateTimer(tonumber(self.db.profile.Fps))
  end
  if not self:IsEventRegistered("MINIMAP_PING") then
    self:RegisterEvent("MINIMAP_PING")
  end
  if not self:IsHooked(WorldFrame,"OnMouseDown")  then
    self:HookScript(WorldFrame,"OnMouseDown", "OnWorldMouseDown")
  end
  if not self:IsHooked(WorldFrame,"OnMouseUp") then
    self:HookScript(WorldFrame,"OnMouseUp", "OnWorldMouseUp")
  end
end

function PingoMatic:PingMe(reason)
  if not self._minimapPlayerModel then return end
  local x,y = self._minimapPlayerModel:GetPosition()
  x,y = -500*x, -500*y
  Minimap:PingLocation(x,y)
end