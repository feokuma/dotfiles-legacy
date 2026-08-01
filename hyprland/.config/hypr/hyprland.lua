-- Hyprland configuration using the Lua format introduced in 0.56.

local home = os.getenv("HOME")
local mainMod = "SUPER"

hl.monitor({
	output = "eDP-1",
	mode = "preferred",
	position = "0x0",
	scale = 1.5,
})

hl.env("_JAVA_AWT_WM_NONREPARENTING", "1")
hl.env("XCURSOR_SIZE", "24")
hl.env("WLR_NO_HARDWARE_CURSORS", "1")
hl.env("HYPRLAND_NO_SD_NOTIFY", "1")
hl.env("ELECTRON_OZONE_PLATFORM_HINT", "auto")
hl.env("XCOMPOSEFILE", home .. "/.config/xkb/compose")
hl.env("XCOMPOSECACHE", home .. "/.cache/xcompose")
hl.env("DOTNET_ROOT", home .. "/.dotnet")
hl.env("PATH", os.getenv("PATH") .. ":" .. home .. "/.dotnet:" .. home .. "/.dotnet/tools")
hl.env("GTK_THEME", "Adwaita:dark")
hl.env("XDG_CURRENT_DESKTOP", "Hyprland")
hl.env("XDG_SESSION_DESKTOP", "Hyprland")

hl.on("hyprland.start", function()
	local commands = {
		"fcitx5",
		home .. "/.config/hypr/xdg-portal-hyprland",
		"dbus-update-activation-environment --systemd WAYLAND_DISPLAY XDG_CURRENT_DESKTOP",
		"systemctl --user import-environment WAYLAND_DISPLAY XDG_CURRENT_DESKTOP",
		"waybar",
		"hyprpaper",
		"swaync",
		"hypridle",
		"mako",
		"wlr-randr",
		"wl-paste",
		"wl-copy",
		"lxqt-policykit-agent",
	}

	for _, command in ipairs(commands) do
		hl.exec_cmd(command)
	end
end)

hl.config({
	input = {
		kb_layout = "us",
		kb_variant = "intl",
		follow_mouse = 1,
		sensitivity = 0.3,
		touchpad = {
			natural_scroll = true,
			disable_while_typing = true,
		},
	},
	general = {
		gaps_in = 5,
		gaps_out = 5,
		border_size = 0,
		col = {
			active_border = "rgb(cdd6f4)",
			inactive_border = "rgba(595959aa)",
		},
		layout = "dwindle",
	},
	misc = {
		disable_hyprland_logo = true,
		disable_splash_rendering = true,
	},
	decoration = {
		rounding = 5,
		blur = {
			enabled = false,
			size = 7,
			passes = 3,
		},
		shadow = {
			enabled = true,
			range = 2,
			render_power = 1,
			color = "rgba(1a1a1aee)",
		},
	},
	animations = {
		enabled = true,
	},
	dwindle = {
		preserve_split = true,
	},
	xwayland = {
		force_zero_scaling = true,
	},
})

hl.curve("myBezier", {
	type = "bezier",
	points = { { 0.05, 0.9 }, { 0.1, 1.05 } },
})

hl.animation({ leaf = "windows", enabled = true, speed = 7, bezier = "myBezier", style = "gnomed" })
hl.animation({ leaf = "windowsOut", enabled = true, speed = 7, bezier = "default", style = "popin 80%" })
hl.animation({ leaf = "border", enabled = true, speed = 10, bezier = "default" })
hl.animation({ leaf = "fade", enabled = true, speed = 7, bezier = "default" })
hl.animation({ leaf = "workspaces", enabled = true, speed = 6, bezier = "default", style = "slide" })

hl.gesture({
	fingers = 3,
	direction = "horizontal",
	action = "workspace",
})

hl.window_rule({
	name = "thunar",
	match = { class = "thunar" },
	opacity = 0.95,
	size = "1200 800",
	center = true,
	float = true,
})

hl.window_rule({
	name = "gtk-file-portal",
	match = { class = "^xdg-desktop-portal-gtk$" },
	float = true,
	size = "1200 800",
	center = true,
})

hl.window_rule({
	name = "chrome-file-dialogs",
	match = {
		class = "^(google-chrome|Google-chrome|chromium|Chromium)$",
		title = "^(Save File|Save As|Salvar arquivo|Open File|Abrir arquivo)$",
	},
	float = true,
	size = "1200 800",
	center = true,
})

hl.window_rule({
	name = "firefox",
	match = { class = "firefox" },
})

hl.window_rule({
	name = "code",
	match = { class = "code" },
	opacity = 0.98,
})

hl.window_rule({
	name = "kitty",
	match = { class = "kitty" },
	opacity = 0.95,
})

hl.window_rule({
	name = "jetbrains",
	match = { class = "jetbrains-*" },
	center = true,
})

hl.bind(mainMod .. " + Q", hl.dsp.exec_cmd("kitty"))
hl.bind("ALT + F4", hl.dsp.window.close())
hl.bind(mainMod .. " + L", hl.dsp.exec_cmd("hyprlock"))
hl.bind(mainMod .. " + M", hl.dsp.exec_cmd("wlogout --protocol layer-shell"))
hl.bind(mainMod .. " + SHIFT + M", hl.dsp.exit())
hl.bind(mainMod .. " + E", hl.dsp.exec_cmd("thunar"))
hl.bind("ALT + SPACE", hl.dsp.exec_cmd("wofi --show drun"))
hl.bind(mainMod .. " + P", hl.dsp.window.pseudo())
hl.bind(mainMod .. " + J", hl.dsp.layout("togglesplit"))
hl.bind(mainMod .. " + S", hl.dsp.exec_cmd([[grim -g "$(slurp)" - | swappy -f -]]))
hl.bind("ALT + N", hl.dsp.exec_cmd([[networkmanager_dmenu -b --dmenu 'wofi --show dmenu']]))
hl.bind("CTRL + PERIOD", hl.dsp.exec_cmd("wofi-emoji --clipboard"))
hl.bind(
	mainMod .. " + F",
	hl.dsp.exec_cmd(
		"hyprctl dispatch togglefloating && hyprctl dispatch resizeactive exact 1200 800 && hyprctl dispatch centerwindow"
	)
)
hl.bind(mainMod .. " + SPACE", hl.dsp.exec_cmd("hyprctl switchxkblayout at-translated-set-2-keyboard next"))
hl.bind(
	mainMod .. " + SHIFT + R",
	hl.dsp.exec_cmd([[sh -c 'pkill -x waybar; sleep 0.2; nohup /usr/bin/waybar >/tmp/waybar.log 2>&1 &']])
)
hl.bind(mainMod .. " + C", hl.dsp.exec_cmd("hyprpicker -a"))

hl.bind("code:156", hl.dsp.exec_cmd("rog-control-center"))
hl.bind("code:211", hl.dsp.exec_cmd("asusctl profile -n; pkill -SIGRTMIN+8 waybar"))
hl.bind("code:232", hl.dsp.exec_cmd("brightnessctl set 1%-"))
hl.bind("code:233", hl.dsp.exec_cmd("brightnessctl set 1%+"))
hl.bind("code:237", hl.dsp.exec_cmd("brightnessctl -d asus::kbd_backlight set 33%-"))
hl.bind("code:238", hl.dsp.exec_cmd("brightnessctl -d asus::kbd_backlight set 33%+"))
hl.bind("code:210", hl.dsp.exec_cmd("asusctl led-mode -n"))

hl.bind("code:123", hl.dsp.exec_cmd("wpctl set-volume @DEFAULT_AUDIO_SINK@ 1%+ && pkill -SIGRTMIN+8 waybar"))
hl.bind("code:122", hl.dsp.exec_cmd("wpctl set-volume @DEFAULT_AUDIO_SINK@ 1%- && pkill -SIGRTMIN+8 waybar"))
hl.bind("code:121", hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle && pkill -SIGRTMIN+8 waybar"))

hl.bind(mainMod .. " + L", hl.dsp.focus({ direction = "left" }))
hl.bind(mainMod .. " + H", hl.dsp.focus({ direction = "right" }))
hl.bind(mainMod .. " + K", hl.dsp.focus({ direction = "up" }))
hl.bind(mainMod .. " + J", hl.dsp.focus({ direction = "down" }))

for workspace = 1, 10 do
	local key = workspace % 10
	hl.bind(mainMod .. " + " .. key, hl.dsp.focus({ workspace = workspace }))
	hl.bind(mainMod .. " + SHIFT + " .. key, hl.dsp.window.move({ workspace = workspace }))
end

hl.bind(mainMod .. " + mouse_down", hl.dsp.focus({ workspace = "e+1" }))
hl.bind(mainMod .. " + mouse_up", hl.dsp.focus({ workspace = "e-1" }))
hl.bind(mainMod .. " + mouse:272", hl.dsp.window.drag(), { mouse = true })
hl.bind(mainMod .. " + mouse:273", hl.dsp.window.resize(), { mouse = true })

hl.bind("Print", hl.dsp.exec_cmd("hyprshot -m region -o - | swappy -f -"))
hl.bind("switch:on:Lid Switch", hl.dsp.exec_cmd([[hyprctl keyword monitor "eDP-1, disable"]]), { locked = true })
hl.bind("switch:off:Lid Switch", hl.dsp.exec_cmd("hyprctl reload"), { locked = true })
