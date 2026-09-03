local base = "rgba(121212ff)"
local inactive = "rgba(595959aa)"
local ember = "rgba(e68e0dff)"

hl.curve("friendEase", {
    type = "bezier",
    points = { { 0.23, 1 }, { 0.32, 1 } },
})

hl.animation({ leaf = "global", enabled = true, speed = 4, bezier = "friendEase" })
hl.animation({ leaf = "windows", enabled = true, speed = 4, bezier = "friendEase", style = "popin 87%" })
hl.animation({ leaf = "workspaces", enabled = true, speed = 5, bezier = "friendEase", style = "slide" })

hl.config({
    general = {
        gaps_in = 5,
        gaps_out = 10,
        border_size = 2,
        resize_on_border = true,
        allow_tearing = false,
        layout = "dwindle",
        col = {
            active_border = ember,
            inactive_border = inactive,
        },
    },
    decoration = {
        rounding = 8,
        active_opacity = 1.0,
        inactive_opacity = 0.97,
        shadow = {
            enabled = true,
            range = 2,
            render_power = 3,
            color = base,
        },
        blur = {
            enabled = true,
            size = 2,
            passes = 2,
            brightness = 0.60,
            contrast = 0.75,
            special = true,
        },
    },
    dwindle = {
        preserve_split = true,
        force_split = 2,
    },
    misc = {
        force_default_wallpaper = 0,
        disable_hyprland_logo = true,
        middle_click_paste = false,
    },
    ecosystem = {
        no_update_news = true,
        no_donation_nag = true,
    },
})
