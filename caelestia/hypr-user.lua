-- Monitor configuration
hl.monitor({
    output   = "eDP-1",
    mode     = "1920x1080@60",
    position = "-1920x0",
    scale    = 1,
})
hl.monitor({
    output   = "HDMI-A-1",
    mode     = "1920x1080@180",
    position = "0x0",
    scale    = 1,
    vrr      = 2,
})

-- Avoid an invisible hardware cursor on the external AMD/HDMI output.
hl.config({
    cursor = {
        no_hardware_cursors = false,
        use_cpu_buffer      = true,
    },
})

-- Core Keeper's Linux build only exposes the laptop as Display 0 through
-- XWayland. Keep its workspace on the HDMI output so its cursor coordinates
-- and fullscreen surface stay on the same monitor.
hl.workspace_rule({
    workspace = "3",
    monitor   = "HDMI-A-1",
})
hl.window_rule({
    match     = { class = "CoreKeeper" },
    workspace = "3 silent",
})

-- Custom keybinds
hl.bind("SUPER + Return", hl.dsp.exec_cmd("foot"))
hl.bind("SUPER + SHIFT + Z", hl.dsp.exec_cmd("zed"))

-- Workspace overview / task switcher (Super+Tab)
hl.bind("SUPER + Tab", hl.dsp.exec_cmd("caelestia shell nexus open"))

-- Cycle through the 5 special workspaces (scratchpads)
hl.bind("SUPER + bar", hl.dsp.exec_cmd("/home/aarons_aa/.config/hypr/scripts/cycle-specials.sh"))

-- Toggle Do Not Disturb mode (notifications)
hl.bind("SUPER + SHIFT + N", hl.dsp.exec_cmd("caelestia shell notifs toggleDnd"))

-- Toggle del Game Mode nativo de Caelestia
hl.bind("SUPER + G", hl.dsp.exec_cmd("caelestia shell gameMode toggle"))

-- Teclado español latinoamericano (Costa Rica)
hl.config({
    input = {
        kb_layout  = "latam",
        kb_variant = "",
    },
})

-- Glass effect: blur behind Caelestia surfaces and the dock
hl.layer_rule({ match = { namespace = "caelestia-drawers" }, blur = true, ignore_alpha = 0.2 })
hl.layer_rule({ match = { namespace = "bottombar" }, blur = true, ignore_alpha = 0.2 })
