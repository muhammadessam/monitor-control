--!nonstrict
-- Monitor Control bar widget - the focused output's refresh rate at a glance.
--
-- Click opens the panel; every compositor call goes through the service, so
-- several bars on several outputs still share one poller. The widget is a thin
-- presentation of the "monitor.state" snapshot. The resolution deliberately
-- lives on the control-center tile (and in the panel), so the bar keeps the
-- short, dynamic half of the mode.

local snapshot = { available = false, outputs = {} }

local function outputByName(name)
  for _, output in ipairs(snapshot.outputs or {}) do
    if output.name == name then
      return output
    end
  end
  return nil
end

local function currentMode(output)
  if output == nil then
    return nil
  end
  for _, mode in ipairs(output.modes or {}) do
    if mode.current == true then
      return mode
    end
  end
  return nil
end

local function hzText(mode)
  local hz = mode.refresh_mhz / 1000
  local rounded = math.floor(hz + 0.5)
  return math.abs(hz - rounded) < 0.02 and tostring(rounded) or string.format("%.2f", hz)
end

-- "120Hz" - the bar's half of the mode. The resolution is the tile's.
local function refreshText(mode)
  if mode == nil then
    return nil
  end
  return hzText(mode) .. "Hz"
end

-- Full "WxH @ Hz" form, for the tooltip only.
local function modeText(mode)
  if mode == nil then
    return nil
  end
  return `{mode.width}x{mode.height} {hzText(mode)}Hz`
end

local function render()
  -- Only meaningful on an Umbriel session: take no bar space elsewhere.
  if snapshot.available ~= true then
    barWidget.setVisible(false)
    return
  end
  barWidget.setVisible(true)

  -- Prefer the output THIS bar instance sits on: snapshot.focused comes from
  -- the service and can be nil outside a focus-driven refresh.
  local name = barWidget.outputName() or snapshot.focused
  local output = outputByName(name)
  if output == nil then
    -- Fallback: the first enabled output with an active mode, so the widget
    -- still says something useful on a headless/unfocused session.
    for _, candidate in ipairs(snapshot.outputs or {}) do
      if candidate.enabled == true and currentMode(candidate) ~= nil then
        name = candidate.name
        output = candidate
        break
      end
    end
  end
  local mode = currentMode(output)
  local text = refreshText(mode)

  barWidget.setGlyph(noctalia.getConfig("glyph") or "device-desktop")
  if noctalia.getConfig("show_text") == true and text ~= nil then
    barWidget.setText(text)
    barWidget.setTooltip({
      { key = noctalia.tr("tooltip.output"), value = tostring(name) },
      { key = noctalia.tr("tooltip.mode"), value = modeText(mode) },
    })
  else
    barWidget.setText("")
    barWidget.setTooltip(noctalia.tr("tooltip.open"))
  end
end

function update()
  render()
end

function onClick()
  noctalia.togglePanel("muhammadessam/umbriel-monitor-control:panel")
end

noctalia.state.watch("monitor.state", function(value)
  if type(value) == "table" then
    snapshot = value
    render()
  end
end)

render()

-- Ask the service for a fresh snapshot on load: watch does not replay an old
-- value, and render() from a stale default hides the widget.
noctalia.state.set("monitor.request", { action = "refresh" })
