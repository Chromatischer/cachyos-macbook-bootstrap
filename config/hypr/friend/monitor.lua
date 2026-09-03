-- Automatic mode is safe across Intel MacBook generations and external displays.
-- After the first login, inspect connector names with: hyprctl monitors
hl.monitor({
    output = "",
    mode = "preferred",
    position = "auto",
    scale = "auto",
})

