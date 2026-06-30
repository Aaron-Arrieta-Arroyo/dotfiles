hl.config({
    animations = {
        enabled = true,
    },
})

-- Animation curves
hl.curve("specialWorkSwitch", { type = "bezier", points = { { 0.0, 0.8 }, { 0.1, 1 } } })
hl.curve("emphasizedAccel", { type = "bezier", points = { { 0.4, 0 }, { 0.9, 0.1 } } })
hl.curve("emphasizedDecel", { type = "bezier", points = { { 0.0, 0.8 }, { 0.1, 1 } } })
hl.curve("standard", { type = "bezier", points = { { 0.1, 0 }, { 0, 1 } } })

-- Animation configs
hl.animation({ leaf = "layersIn", enabled = true, speed = 7, bezier = "emphasizedDecel", style = "slide" })
hl.animation({ leaf = "layersOut", enabled = true, speed = 5, bezier = "emphasizedAccel", style = "slide" })
hl.animation({ leaf = "fadeLayers", enabled = true, speed = 7, bezier = "standard" })

hl.animation({ leaf = "windowsIn", enabled = true, speed = 7, bezier = "emphasizedDecel" })
hl.animation({ leaf = "windowsOut", enabled = true, speed = 5, bezier = "emphasizedAccel" })
hl.animation({ leaf = "windowsMove", enabled = true, speed = 8, bezier = "standard" })
hl.animation({ leaf = "workspaces", enabled = true, speed = 7, bezier = "standard" })

hl.animation({
    leaf    = "specialWorkspace",
    enabled = true,
    speed   = 6,
    bezier  = "specialWorkSwitch",
    style   = "slidefadevert 15%"
})
hl.animation({ leaf = "fade", enabled = true, speed = 8, bezier = "standard" })
hl.animation({ leaf = "fadeDim", enabled = true, speed = 8, bezier = "standard" })
hl.animation({ leaf = "border", enabled = true, speed = 8, bezier = "standard" })
