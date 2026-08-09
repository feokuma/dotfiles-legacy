-- Hyprland configuration using the Lua format introduced in 0.56.

local home = os.getenv("HOME")
local main_mod = "SUPER"
local terminal = "kitty"
local file_manager = "thunar"
local launcher = "wofi --show drun"

local function bind_exec(key, command, options)
	hl.bind(key, hl.dsp.exec_cmd(command), options)
end

-- Monitor
hl.monitor({
	output = "eDP-1",
	mode = "preferred",
	position = "0x0",
	scale = 1.5,
})

-- Environment
local environment = {
	_JAVA_AWT_WM_NONREPARENTING = "1",
	XCURSOR_SIZE = "24",
	WLR_NO_HARDWARE_CURSORS = "1",
	HYPRLAND_NO_SD_NOTIFY = "1",
	ELECTRON_OZONE_PLATFORM_HINT = "auto",
	XCOMPOSEFILE = home .. "/.config/xkb/compose",
	XCOMPOSECACHE = home .. "/.cache/xcompose",
	DOTNET_ROOT = home .. "/.dotnet",
	PATH = os.getenv("PATH") .. ":" .. home .. "/.dotnet:" .. home .. "/.dotnet/tools",
	GTK_THEME = "Adwaita:dark",
	XDG_CURRENT_DESKTOP = "Hyprland",
	XDG_SESSION_DESKTOP = "Hyprland",
}

for name, value in pairs(environment) do
	hl.env(name, value)
end

-- Startup
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
		"lxqt-policykit-agent",
	}

	for _, command in ipairs(commands) do
		hl.exec_cmd(command)
	end
end)

-- General configuration
hl.config({
	input = {
		kb_layout = "us",
		kb_variant = "intl",
		follow_mouse = 1,
		sensitivity = 0.3,
		touchpad = {
			natural_scroll = true,
			disable_while_typing = true,
			tap_to_click = false,
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

-- Animations
hl.curve("myBezier", {
	type = "bezier",
	points = { { 0.05, 0.9 }, { 0.1, 1.05 } },
})

local animations = {
	{ leaf = "windows", enabled = true, speed = 7, bezier = "myBezier", style = "gnomed" },
	{ leaf = "windowsOut", enabled = true, speed = 7, bezier = "default", style = "popin 80%" },
	{ leaf = "border", enabled = true, speed = 10, bezier = "default" },
	{ leaf = "fade", enabled = true, speed = 7, bezier = "default" },
	{ leaf = "workspaces", enabled = true, speed = 6, bezier = "default", style = "slide" },
}

for _, animation in ipairs(animations) do
	hl.animation(animation)
end

-- Gestures
hl.gesture({
	fingers = 3,
	direction = "horizontal",
	action = "workspace",
})

-- Window rules
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

-- Application bindings
bind_exec(main_mod .. " + Q", terminal)
hl.bind("ALT + F4", hl.dsp.window.close())
bind_exec(main_mod .. " + L", "hyprlock")
bind_exec(main_mod .. " + M", "wlogout --protocol layer-shell")
hl.bind(main_mod .. " + SHIFT + M", hl.dsp.exit())
bind_exec(main_mod .. " + E", file_manager)
bind_exec("ALT + SPACE", launcher)
hl.bind(main_mod .. " + P", hl.dsp.window.pseudo())
hl.bind(main_mod .. " + J", hl.dsp.layout("togglesplit"))
bind_exec(main_mod .. " + S", [[grim -g "$(slurp)" - | swappy -f -]])
bind_exec("ALT + N", [[networkmanager_dmenu -b --dmenu 'wofi --show dmenu']])
bind_exec("CTRL + PERIOD", "wofi-emoji --clipboard")
bind_exec(
	main_mod .. " + F",
	"hyprctl dispatch togglefloating && hyprctl dispatch resizeactive exact 1200 800 && hyprctl dispatch centerwindow"
)
bind_exec(main_mod .. " + SPACE", "hyprctl switchxkblayout at-translated-set-2-keyboard next")

local restart_waybar = [[sh -c 'pkill -x waybar; sleep 0.2; nohup /usr/bin/waybar >/tmp/waybar.log 2>&1 &']]
bind_exec(main_mod .. " + SHIFT + R", restart_waybar)
bind_exec(main_mod .. " + C", "hyprpicker -a")

-- Hardware bindings
bind_exec("code:156", "rog-control-center")
bind_exec("code:211", "asusctl profile -n; pkill -SIGRTMIN+8 waybar")
bind_exec("code:232", "brightnessctl set 1%-")
bind_exec("code:233", "brightnessctl set 1%+")
bind_exec("code:237", "brightnessctl -d asus::kbd_backlight set 33%-")
bind_exec("code:238", "brightnessctl -d asus::kbd_backlight set 33%+")
bind_exec("code:210", "asusctl led-mode -n")

bind_exec("code:123", "wpctl set-volume @DEFAULT_AUDIO_SINK@ 1%+ && pkill -SIGRTMIN+8 waybar")
bind_exec("code:122", "wpctl set-volume @DEFAULT_AUDIO_SINK@ 1%- && pkill -SIGRTMIN+8 waybar")
bind_exec("code:121", "wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle && pkill -SIGRTMIN+8 waybar")

-- Window and workspace navigation
hl.bind(main_mod .. " + LEFT", hl.dsp.focus({ direction = "left" }))
hl.bind(main_mod .. " + RIGHT", hl.dsp.focus({ direction = "right" }))
hl.bind(main_mod .. " + UP", hl.dsp.focus({ direction = "up" }))
hl.bind(main_mod .. " + DOWN", hl.dsp.focus({ direction = "down" }))

for workspace = 1, 10 do
	local key = workspace % 10
	hl.bind(main_mod .. " + " .. key, hl.dsp.focus({ workspace = workspace }))
	hl.bind(main_mod .. " + SHIFT + " .. key, hl.dsp.window.move({ workspace = workspace }))
end

hl.bind(main_mod .. " + mouse_down", hl.dsp.focus({ workspace = "e+1" }))
hl.bind(main_mod .. " + mouse_up", hl.dsp.focus({ workspace = "e-1" }))
hl.bind(main_mod .. " + mouse:272", hl.dsp.window.drag(), { mouse = true })
hl.bind(main_mod .. " + mouse:273", hl.dsp.window.resize(), { mouse = true })

-- System bindings
bind_exec("Print", "hyprshot -m region -o - | swappy -f -")
bind_exec("switch:on:Lid Switch", [[hyprctl keyword monitor "eDP-1, disable"]], { locked = true })
bind_exec("switch:off:Lid Switch", "hyprctl reload", { locked = true })
