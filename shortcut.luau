--!nonstrict
-- Monitor Control control-center tile - the focused output's mode, one click
-- from the panel.
--
-- A thin client like the bar widget: it renders the service's "monitor.state"
-- snapshot (through snapshot.luau, so both entries name and format the same
-- monitor) and opens the panel on click, so every compositor call stays in the
-- service. Add it in Settings -> Control Center -> Shortcuts.

local snapshotModule = require("./snapshot.luau")

local snapshot = { available = false, outputs = {} }

local function render()
  -- The plugin's own glyph: the tile has no settings of its own, and the bar
  -- widget's glyph setting is per widget instance, so there is nothing to read
  -- here.
  shortcut.setIcon("device-desktop")

  if snapshot.available ~= true then
    shortcut.setLabel(noctalia.tr("shortcut.unavailable"))
    shortcut.setActive(false)
    shortcut.setEnabled(false)
    return
  end

  local output = snapshotModule.headline(snapshot)
  -- Resolution alone: the tile label is one line, elided, beside the icon; the
  -- full mode string lives on the bar widget and in the panel.
  shortcut.setLabel(snapshotModule.resolutionText(output) or noctalia.tr("shortcut.label"))
  -- The tile is a way into the panel, not a state of its own, so it never
  -- lights up; the shell renders every plugin shortcut as a toggle tile.
  shortcut.setActive(false)
  shortcut.setEnabled(true)
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

-- watch does not replay an old value to a freshly loaded entry, and the service
-- may have last published before this tile was added: ask for a snapshot,
-- exactly as the bar widget does.
noctalia.state.set("monitor.request", { action = "refresh" })
