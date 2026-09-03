local floating = "^(pavucontrol|blueman-manager|nm-connection-editor|org\\.keepassxc\\.KeePassXC)$"
local terminals = "^(Alacritty|kitty|com\\.mitchellh\\.ghostty)$"

hl.window_rule({ match = { class = floating }, float = true, center = true, persistent_size = true })
hl.window_rule({ match = { class = terminals }, opacity = "0.96 0.92" })
hl.window_rule({
    match = { title = "^([Pp]icture[-\\s]?[Ii]n[-\\s]?[Pp]icture)(.*)$" },
    float = true,
    keep_aspect_ratio = true,
    pin = true,
})
hl.layer_rule({
    name = "friend-waybar",
    match = { namespace = "waybar" },
    blur = true,
    ignore_alpha = 0.2,
})
