-- Monitor configuration
hl.monitor({
    output   = "eDP-1",
    mode     = "1920x1080@60",
    position = "0x0",
    scale    = 1,
})
hl.monitor({
    output   = "HDMI-A-1",
    mode     = "1920x1080@180",
    position = "1920x0",
    scale    = 1,
    vrr      = 2,
})

-- Custom keybinds
hl.bind("SUPER + Return", hl.dsp.exec_cmd("foot"))
hl.bind("SUPER + SHIFT + Z", hl.dsp.exec_cmd("zed"))

-- Workspace overview / task switcher (Super+Tab)
hl.bind("SUPER + Tab", hl.dsp.exec_cmd("caelestia shell nexus open"))

-- Toggle Do Not Disturb mode (notifications)
hl.bind("SUPER + SHIFT + N", hl.dsp.exec_cmd("caelestia shell notifs toggleDnd"))

-- Toggle Game Mode (desactiva blur/sombras/animaciones para máximo rendimiento)
hl.bind("SUPER + G", hl.dsp.exec_cmd("~/.config/caelestia/scripts/game-mode.sh"))
