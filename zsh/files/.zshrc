export PATH="$HOME/.local/bin:$PATH"


# --------------------------------------------------------
# TOOL CONFIGURATION
# --------------------------------------------------------

# zsh-autocomplete
source /opt/homebrew/share/zsh-autocomplete/zsh-autocomplete.plugin.zsh

# fzf
source <(fzf --zsh)

# nvm
export NVM_DIR="$HOME/.nvm"
[ -s "/opt/homebrew/opt/nvm/nvm.sh" ] && source "/opt/homebrew/opt/nvm/nvm.sh"

# uv
eval "$(uv generate-shell-completion zsh)"


# --------------------------------------------------------
# ALIAS
# --------------------------------------------------------


# LS ENHANCEMENTS

# ls split into sections
lssplit() {
    local target="${1:-.}"
    local bold='\033[1m'
    local cyan='\033[36m'
    local reset='\033[0m'
    local width=${COLUMNS:-$(tput cols 2>/dev/null || echo 80)}
    local listing out

    _lssplit_header() {
        local title=" $1 "
        local tlen=${#title}
        local left=$(( (width - tlen) / 2 ))
        local right=$(( width - tlen - left ))
        printf "${bold}${cyan}"
        printf '─%.0s' $(seq 1 $left)
        printf '%s' "$title"
        printf '─%.0s' $(seq 1 $right)
        printf "${reset}\n"
    }

    listing=$(ls -la "$target")

    out=$(echo "$listing" | awk '$1 ~ /^d/')
    if [[ -n "$out" ]]; then
        _lssplit_header "Directories"
        printf "%s\n" "$out"
    fi

    out=$(echo "$listing" | awk '$1 ~ /^-/' | awk '{
        n = split($NF, a, ".");
        ext = (n > 1) ? tolower(a[n]) : "";
        print ext "\t" tolower($NF) "\t" $0
    }' | sort -k1,2 | cut -f3-)
    if [[ -n "$out" ]]; then
        _lssplit_header "Files"
        printf "%s\n" "$out"
    fi

    out=$(echo "$listing" | awk '$1 ~ /^l/')
    if [[ -n "$out" ]]; then
        _lssplit_header "Symlinks"
        printf "%s\n" "$out"
    fi

    unfunction _lssplit_header
}

alias ll='lssplit'


# NEOVIM

alias nv='nvim'


# FZF

alias nvf='nvim $(fzf)'


# CAFFEINATE

alias caff='caffeinate'
alias caffd='caffeinate -d'


# --------------------------------------------------------
# KEY BINDINGS
# --------------------------------------------------------

# Cmd+Left/Right → beginning/end of line
bindkey "^[[H"  beginning-of-line
bindkey "^[[F"  end-of-line
# Option+Delete → delete word backward
bindkey "^[^?"  backward-kill-word
bindkey "^[^H"  backward-kill-word


# --------------------------------------------------------
# PROMPT
# --------------------------------------------------------

# Autoload zsh's `add-zsh-hook` and `vcs_info` functions
# (-U autoload w/o substition, -z use zsh style)
autoload -Uz add-zsh-hook vcs_info

# Set prompt substitution so we can use variables in PROMPT
setopt prompt_subst

# Run the `vcs_info` hook to grab git info before displaying the prompt
add-zsh-hook precmd vcs_info

# Style the vcs_info message — no color codes here; colors are applied in
# PROMPT directly so zsh treats them as zero-width (avoids cursor drift)
zstyle ':vcs_info:*' enable git
zstyle ':vcs_info:git*' formats '⎇ %b %u%c%m'
zstyle ':vcs_info:git*' actionformats '⎇ %b %u%c%m [%a]'
zstyle ':vcs_info:git*' unstagedstr '□'
zstyle ':vcs_info:git*' stagedstr '■'
zstyle ':vcs_info:*:*' check-for-changes true
zstyle ':vcs_info:git*+set-message:*' hooks git-ahead-behind

# Append ⇡N ⇣N to %m when the branch has an upstream
function +vi-git-ahead-behind() {
    local -a ab
    git rev-parse ${hook_com[branch]}@{upstream} &>/dev/null || return 0
    ab=($(git rev-list --left-right --count HEAD...${hook_com[branch]}@{upstream} 2>/dev/null))
    local ahead=${ab[1]} behind=${ab[2]}
    local arrows=''
    (( ahead  )) && arrows+="⇡${ahead}"
    (( behind )) && arrows+="${arrows:+ }⇣${behind}"
    [[ -n $arrows ]] && hook_com[misc]+=" ${arrows}"
}

# Rebuild PROMPT before each command so vcs line only appears in git repos.
# Line 1: full-width yellow bar (%K{yellow}…%E%k), path first then git, left-to-right.
# ANSI yellow maps to the theme's yellow, so it adapts to both light and dark modes.
# Black text (%F{black}) ensures legibility on any theme's yellow.
# Line 2: input line.
_set_prompt() {
    if [[ -n $vcs_info_msg_0_ ]]; then
        PROMPT=$'%K{yellow}%F{black} %B%~%b  ${vcs_info_msg_0_} %E%f%k\n%(?.%F{green}❯.%F{red}❯)%f %# '
    else
        PROMPT=$'%K{yellow}%F{black} %B%~%b %E%f%k\n%(?.%F{green}❯.%F{red}❯)%f %# '
    fi
}
add-zsh-hook precmd _set_prompt

RPROMPT=''


# --------------------------------------------------------
# LOCAL OVERRIDES
# --------------------------------------------------------

[[ -f ~/.zshrc.local ]] && source ~/.zshrc.local
