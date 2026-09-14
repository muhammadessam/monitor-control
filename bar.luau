--!nonstrict
-- Monitor Control bar widget - the focused output's current mode at a glance.
--
-- Click opens the panel; every compositor call goes through the service, so
-- several bars on several outputs still share one poller. The widget is a thin
-- presentation of the "monitor.state" snapshot, rendered through snapshot.luau
-- so the bar and the control-center tile show the same monitor the same way.

local snapshotModule = require("./snapshot.luau")

local snapshot = { available = false, outputs = {} }

local function render()
  -- Only meaningful on an Umbriel session: take no bar space elsewhere.
  if snapshot.available ~= true then
    barWidget.setVisible(false)
    return
  end
  barWidget.setVisible(true)

  -- Prefer the output THIS bar instance sits on: snapshot.focused comes from
  -- the service and can be nil outside a focus-driven refresh.
  local output = snapshotModule.headline(snapshot, barWidget.outputName())
  local modeText = snapshotModule.modeText(output)

  barWidget.setGlyph(noctalia.getConfig("glyph") or "device-desktop")
  if noctalia.getConfig("show_text") == true and modeText ~= nil then
    barWidget.setText(modeText)
    barWidget.setTooltip({
      { key = noctalia.tr("tooltip.output"), value = tostring(output.name) },
      { key = noctalia.tr("tooltip.mode"), value = modeText },
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
