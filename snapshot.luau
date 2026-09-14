--!nonstrict
-- Display helpers shared by the bar widget and the control-center tile: both
-- read the service's "monitor.state" snapshot and must name the same output and
-- format the same mode text. Kept free of host globals so tests/run.lua can
-- unit-test it outside Noctalia.
--
-- A snapshot is what the service publishes:
--   {
--     available = true,
--     focused = "eDP-1",
--     outputs = { { name = "eDP-1", enabled = true, modes = { { current = true, ... } } } },
--   }
--
-- A mode is one entry of an output's "modes" array (umbriel outputs --json):
-- current, width, height, refresh_mhz.

local M = {}

-- The output carrying this connector name, or nil. An absent or empty name
-- comes back nil too, so a caller can hand over an optional value (a bar's own
-- output, a state field that is not set) without checking it first.
function M.byName(outputs, name)
  if type(name) ~= "string" or name == "" then
    return nil
  end
  for _, output in ipairs(outputs or {}) do
    if output.name == name then
      return output
    end
  end
  return nil
end

-- The mode flagged current, or nil when the output reports none. A mode
-- without a usable size is skipped, so the formatters below can rely on
-- width/height being numbers.
function M.currentMode(output)
  if output == nil then
    return nil
  end
  for _, mode in ipairs(output.modes or {}) do
    if mode.current == true and type(mode.width) == "number" and type(mode.height) == "number" then
      return mode
    end
  end
  return nil
end

-- Refresh rate as text: a whole number when the panel's rate is within 0.02 Hz
-- of one (143999 mHz -> "144"), otherwise two decimals (59940 -> "59.94"), so
-- a 60 Hz-class mode is not rounded up into a rate the display never ran at.
-- nil when the mode reports no rate.
function M.hzText(refreshMhz)
  local mhz = tonumber(refreshMhz)
  if mhz == nil then
    return nil
  end
  local hz = mhz / 1000
  local rounded = math.floor(hz + 0.5)
  if math.abs(hz - rounded) < 0.02 then
    return tostring(rounded)
  end
  return string.format("%.2f", hz)
end

-- "1920x1080" for an output's current mode, or nil. The control-center tile's
-- label is a single elided line next to its icon, so it takes the resolution
-- alone; the full mode string (with refresh rate) is what the bar widget shows
-- and what the panel lists per monitor.
function M.resolutionText(output)
  local mode = M.currentMode(output)
  if mode == nil then
    return nil
  end
  return string.format("%dx%d", mode.width, mode.height)
end

-- "1920x1080 120Hz" for an output's current mode, or nil when it has none - the
-- bar widget's text. A mode that carries no refresh rate reads as its
-- resolution alone.
function M.modeText(output)
  local mode = M.currentMode(output)
  if mode == nil then
    return nil
  end
  local hz = M.hzText(mode.refresh_mhz)
  if hz == nil then
    return M.resolutionText(output)
  end
  return string.format("%s %sHz", M.resolutionText(output), hz)
end

-- The output a heading describes: the connector asked for (a bar instance's own
-- output) when the snapshot holds it, otherwise the focused output, otherwise
-- the first enabled output with a mode - so an unfocused or headless session
-- still says something useful instead of nothing.
function M.headline(snapshot, preferred)
  local outputs = (snapshot and snapshot.outputs) or {}
  local output = M.byName(outputs, preferred) or M.byName(outputs, snapshot and snapshot.focused)
  if output == nil then
    for _, candidate in ipairs(outputs) do
      if candidate.enabled == true and M.modeText(candidate) ~= nil then
        output = candidate
        break
      end
    end
  end
  return output
end

return M
