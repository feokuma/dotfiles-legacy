#!/usr/bin/env bash
set -o pipefail

default_source="$(pactl info | awk -F': ' '/^Default Source:/{print $2; exit}')"

if [[ -z "$default_source" ]]; then
	jq -cn \
		--arg text " N/A" \
		--arg tooltip "Microphone unavailable" \
		--arg class "muted" \
		'{text: $text, tooltip: $tooltip, class: $class}'
	exit 0
fi

source_json="$(pactl --format=json list sources | jq -c --arg name "$default_source" 'map(select(.name == $name))[0]')"

if [[ -z "$source_json" || "$source_json" == "null" ]]; then
	jq -cn \
		--arg text " N/A" \
		--arg tooltip "$default_source" \
		--arg class "muted" \
		'{text: $text, tooltip: $tooltip, class: $class}'
	exit 0
fi

description="$(jq -r '.description // .properties["node.nick"] // .name' <<< "$source_json")"
muted="$(jq -r '.mute' <<< "$source_json")"
volume="$(jq -r '[.volume[]?.value_percent | rtrimstr("%") | tonumber] | if length == 0 then 0 else (add / length | round) end' <<< "$source_json")"

if [[ "$muted" == "true" ]]; then
	text=" Muted"
	class="muted"
else
	text=" ${volume}%"
	class="unmuted"
fi

jq -cn \
	--arg text "$text" \
	--arg tooltip "$description" \
	--arg class "$class" \
	'{text: $text, tooltip: $tooltip, class: $class}'
