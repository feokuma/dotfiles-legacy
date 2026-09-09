-- Hyprland configuration using the Lua format introduced in 0.56.

local home = os.getenv("HOME")
local main_mod = "SUPER"
local terminal = "ghostty"
local file_manager = "thunar"
local launcher = "wofi --show drun"
local touchpad_name = "asup1206:00-093a:300d-touchpad"

local function is_lid_closed()
	local file = io.open("/proc/acpi/button/lid/LID/state", "r")
	if not file then
		return false
	end

	local state = file:read("*a")
	file:close()
	return state:find("closed", 1, true) ~= nil
end

-- Monitor
hl.monitor({
	output = "eDP-1",
	mode = "preferred",
	position = "0x0",
	scale = 1.5,
	disabled = is_lid_closed(),
})

hl.monitor({
	output = "desc:Dell Inc. DELL S2421HN B1P4DQ3",
	mode = "preferred",
	position = "auto",
	scale = 1,
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
		"qs",
		"hyprpaper",
		"swaync",
		"hypridle",
		"lxqt-policykit-agent",
		home .. "/.config/hypr/lid-monitor.sh",
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
			enabled = true,
			size = 1,
			passes = 2,
		},
		shadow = {
			enabled = true,
			range = 2,
			render_power = 1,
			color = "rgba(1a1a1aee)",
		},

		active_opacity = 1.0,
		inactive_opacity = 0.9,
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

-- Applications and launchers
hl.bind(main_mod .. " + Q", hl.dsp.exec_cmd(terminal))
hl.bind(main_mod .. " + E", hl.dsp.exec_cmd(file_manager))
hl.bind("ALT + SPACE", hl.dsp.exec_cmd(launcher))
hl.bind("ALT + N", hl.dsp.exec_cmd([[networkmanager_dmenu -b --dmenu 'wofi --show dmenu']]))
hl.bind("CTRL + PERIOD", hl.dsp.exec_cmd("wofi-emoji --clipboard"))

-- Session controls
hl.bind(main_mod .. " + L", hl.dsp.exec_cmd("hyprlock"))
hl.bind(main_mod .. " + M", hl.dsp.exec_cmd("wlogout --protocol layer-shell"))
hl.bind(main_mod .. " + SHIFT + M", hl.dsp.exit())
hl.bind(
	main_mod .. " + SHIFT + R",
	hl.dsp.exec_cmd([[pkill -x waybar; sleep 0.2; nohup /usr/bin/waybar >/tmp/waybar.log 2>&1 &]])
)

-- Window actions
hl.bind("ALT + F4", hl.dsp.window.close())
hl.bind(main_mod .. " + P", hl.dsp.window.pseudo())
hl.bind(main_mod .. " + J", hl.dsp.layout("togglesplit"))
hl.bind(main_mod .. " + F", function()
	hl.dispatch(hl.dsp.window.float({ action = "toggle" }))
	hl.dispatch(hl.dsp.window.resize({ x = 1200, y = 800 }))
	hl.dispatch(hl.dsp.window.center())
end)

-- Screenshots and color picker
hl.bind(main_mod .. " + S", hl.dsp.exec_cmd([[grim -g "$(slurp)" - | swappy -f -]]))
hl.bind("Print", hl.dsp.exec_cmd("hyprshot -m region -o - | swappy -f -"))
hl.bind(main_mod .. " + C", hl.dsp.exec_cmd("hyprpicker -a"))

-- Keyboard layout
hl.bind(main_mod .. " + SPACE", hl.dsp.exec_cmd("hyprctl switchxkblayout at-translated-set-2-keyboard next"))

-- Window focus
hl.bind(main_mod .. " + LEFT", hl.dsp.focus({ direction = "left" }))
hl.bind(main_mod .. " + RIGHT", hl.dsp.focus({ direction = "right" }))
hl.bind(main_mod .. " + UP", hl.dsp.focus({ direction = "up" }))
hl.bind(main_mod .. " + DOWN", hl.dsp.focus({ direction = "down" }))

-- Workspaces
for workspace = 1, 10 do
	local key = workspace % 10
	hl.bind(main_mod .. " + " .. key, hl.dsp.focus({ workspace = workspace }))
	hl.bind(main_mod .. " + SHIFT + " .. key, hl.dsp.window.move({ workspace = workspace }))
end

-- Mouse actions
hl.bind(main_mod .. " + mouse_down", hl.dsp.focus({ workspace = "e+1" }))
hl.bind(main_mod .. " + mouse_up", hl.dsp.focus({ workspace = "e-1" }))
hl.bind(main_mod .. " + mouse:272", hl.dsp.window.drag(), { mouse = true })
hl.bind(main_mod .. " + mouse:273", hl.dsp.window.resize(), { mouse = true })

-- ASUS hardware keys
hl.bind("code:156", hl.dsp.exec_cmd("rog-control-center"))
hl.bind("code:211", hl.dsp.exec_cmd("asusctl profile -n; pkill -SIGRTMIN+8 waybar"), { locked = true })
hl.bind("code:210", hl.dsp.exec_cmd("asusctl led-mode -n"))

-- Touchpad
hl.device({ name = touchpad_name, enabled = true })

-- Brightness
hl.bind("XF86MonBrightnessDown", hl.dsp.exec_cmd("brightnessctl set 1%-"), { locked = true, repeating = true })
hl.bind("XF86MonBrightnessUp", hl.dsp.exec_cmd("brightnessctl set 1%+"), { locked = true, repeating = true })
hl.bind("code:237", hl.dsp.exec_cmd("brightnessctl -d asus::kbd_backlight set 33%-"), {
	locked = true,
	repeating = true,
})
hl.bind("code:238", hl.dsp.exec_cmd("brightnessctl -d asus::kbd_backlight set 33%+"), {
	locked = true,
	repeating = true,
})

-- Audio
hl.bind(
	"XF86AudioRaiseVolume",
	hl.dsp.exec_cmd("wpctl set-volume @DEFAULT_AUDIO_SINK@ 1%+ && pkill -SIGRTMIN+8 waybar"),
	{
		locked = true,
		repeating = true,
	}
)
hl.bind(
	"XF86AudioLowerVolume",
	hl.dsp.exec_cmd("wpctl set-volume @DEFAULT_AUDIO_SINK@ 1%- && pkill -SIGRTMIN+8 waybar"),
	{
		locked = true,
		repeating = true,
	}
)
hl.bind("XF86AudioMute", hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle && pkill -SIGRTMIN+8 waybar"), {
	locked = true,
	repeating = true,
})

-- HyprMod managed settings
require("hyprland-gui")
