hl.config({
    input = {
        kb_layout = "us",
        kb_options = "compose:caps",
        repeat_rate = 40,
        repeat_delay = 600,
        follow_mouse = 1,
        sensitivity = 0,
        touchpad = {
            natural_scroll = true,
            tap_to_click = true,
            clickfinger_behavior = true,
            scroll_factor = 0.55,
        },
    },
})

hl.gesture({ fingers = 3, direction = "horizontal", action = "workspace" })

