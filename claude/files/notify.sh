#!/bin/bash
# Only notify if Terminal is not the focused window

active_app=$(osascript -e 'tell application "System Events" to get name of first process whose frontmost is true' 2>/dev/null)

terminal_apps=("Terminal" "iTerm2" "Alacritty" "Kitty" "WezTerm" "Hyper" "Warp" "Ghostty")
for app in "${terminal_apps[@]}"; do
  [ "$active_app" = "$app" ] && exit 0
done

# Parse JSON from stdin
input=$(cat)
json_message=$(echo "$input" | jq -r '.message // empty' 2>/dev/null)
transcript_path=$(echo "$input" | jq -r '.transcript_path // empty' 2>/dev/null)

if [ -n "$json_message" ]; then
  # Notification hook — use the provided message
  title="🔔 Claude Code"
  message="$json_message"
elif [ -n "$transcript_path" ] && [ -f "$transcript_path" ]; then
  # Stop hook — extract last assistant text from transcript
  title="✅ Claude Code"
  last_text=$(grep -o '"role":"assistant"[^}]*' "$transcript_path" 2>/dev/null | \
    tail -1 | grep -o '"text":"[^"]*"' | head -1 | sed 's/"text":"//;s/"$//')
  if [ -n "$last_text" ]; then
    message="${last_text:0:80}…"
  else
    message="Task completed"
  fi
else
  title="✅ Claude Code"
  message="Task completed"
fi

/opt/homebrew/bin/terminal-notifier -title "$title" -message "$message" -sound Blow
