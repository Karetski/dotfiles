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

# lssplit: ls grouped into Directories / Files / Symlinks with icons,
# colors, human-readable sizes, and a layout that adapts to terminal width.
# Set LSSPLIT_ICONS=0 to fall back to plain text (no Nerd Font glyphs).
lssplit() {
    emulate -L zsh
    setopt local_options null_glob extended_glob

    local target="${1:-.}"
    if [[ ! -d $target ]]; then
        printf 'lssplit: %s: not a directory\n' "$target" >&2
        return 1
    fi

    local -a entries=( "$target"/*(ND) )
    if (( ${#entries} == 0 )); then
        printf '  \e[2m(empty)\e[0m\n'
        return 0
    fi

    local width=${COLUMNS:-$(tput cols 2>/dev/null || echo 80)}
    local icons=${LSSPLIT_ICONS:-1}

    local mode
    if   (( width < 60 ));  then mode=grid
    elif (( width < 100 )); then mode=compact
    else                         mode=full
    fi

    # Pared-back palette: only entry types are colored; all metadata is dim.
    local reset=$'\e[0m' bold=$'\e[1m'
    local c_dir=$'\e[34m' c_exec=$'\e[32m' c_link=$'\e[36m'
    local c_hidden=$'\e[2m' c_broken=$'\e[31m'
    local c_header=$'\e[2m' c_meta=$'\e[2m' c_target=$'\e[2m'

    local -A ext_icon=(
        py     $''   js     $''   mjs    $''
        ts     $''   tsx    $''   jsx    $''
        json   $''   md     $''   sh     $''
        zsh    $''   bash   $''   fish   $''
        lua    $''   go     $''   rs     $''
        rb     $''   c      $''   cpp    $''
        h      $''   hpp    $''   java   $''
        kt     $''   swift  $''   html   $''
        css    $''   scss   $''   yml    $''
        yaml   $''   toml   $''   xml    $''
        sql    $''   csv    $''   png    $''
        jpg    $''   jpeg   $''   gif    $''
        svg    $''   webp   $''   ico    $''
        pdf    $''   zip    $''   tar    $''
        gz     $''   tgz    $''   xz     $''
        bz2    $''   log    $''   txt    $''
        conf   $''   ini    $''   env    $''
        lock   $''   sock   $''   db     $''
        sqlite $''   vim    $''   nix    $''
        dart   $''   php    $''   ex     $''
        exs    $''   mp3    $''   mp4    $''
        mov    $''   wav    $''
    )
    local -A name_icon=(
        Dockerfile           $''
        docker-compose.yml   $''
        docker-compose.yaml  $''
        Makefile             $''
        makefile             $''
        package.json         $''
        package-lock.json    $''
        yarn.lock            $''
        Cargo.toml           $''
        Cargo.lock           $''
        go.mod               $''
        go.sum               $''
        README               $''
        README.md            $''
        LICENSE              $''
        .gitignore           $''
        .gitattributes       $''
        .gitmodules          $''
        .git                 $''
        .env                 $''
        .DS_Store            $''
    )
    local i_dir=$'' i_file=$'' i_file_hidden=$'' i_link=$''

    # One stat call for everything; \x1f keeps fields safe from tabs/spaces.
    local sep=$'\x1f'
    local -a stats_lines
    stats_lines=( ${(f)"$(stat -f "%N${sep}%HT${sep}%Sp${sep}%z${sep}%m${sep}%Y" -- "${entries[@]}" 2>/dev/null)"} )

    local -A info
    local -a names_dir names_file names_link
    local now=$(date +%s)
    local line fpath htype perms size mtime tgt bname kind hidden
    for line in "${stats_lines[@]}"; do
        IFS=$sep read -r fpath htype perms size mtime tgt <<< "$line"
        bname=${fpath:t}
        hidden=0
        [[ $bname == .* ]] && hidden=1
        case $htype in
            "Symbolic Link") kind=link; names_link+=( "$bname" ) ;;
            "Directory")     kind=dir;  names_dir+=( "$bname" ) ;;
            *)               kind=file; names_file+=( "$bname" ) ;;
        esac
        info[$bname]="${fpath}${sep}${kind}${sep}${perms}${sep}${size}${sep}${mtime}${sep}${tgt}${sep}${hidden}"
    done

    names_dir=( ${(io)names_dir} )
    names_link=( ${(io)names_link} )
    # Files: extension first, then name — matches the original behaviour.
    local n ext
    names_file=( ${(f)"$(
        for n in "${names_file[@]}"; do
            ext=""
            if   [[ $n == *.* && $n != .* ]]; then ext=${n##*.}
            elif [[ $n == .*.* ]];                 then ext=${n##*.}
            fi
            printf '%s\t%s\t%s\n' "${(L)ext}" "${(L)n}" "$n"
        done | sort -k1,1 -k2,2 | cut -f3-
    )"} )

    _lssplit_icon() {
        local name=$1 kind=$2 hidden=$3
        (( icons )) || return
        if [[ -n ${name_icon[$name]:-} ]]; then
            print -rn -- "${name_icon[$name]}"
            return
        fi
        case $kind in
            dir)  print -rn -- "$i_dir";  return ;;
            link) print -rn -- "$i_link"; return ;;
        esac
        if [[ $name == *.* ]]; then
            local e=${(L)name##*.}
            if [[ -n ${ext_icon[$e]:-} ]]; then
                print -rn -- "${ext_icon[$e]}"
                return
            fi
        fi
        if (( hidden )); then print -rn -- "$i_file_hidden"
        else                  print -rn -- "$i_file"
        fi
    }

    _lssplit_hsize() {
        local b=$1
        if   (( b < 1024 ));       then printf '%4dB' "$b"
        elif (( b < 102400 ));     then printf '%4.1fK' "$(( b / 1024.0 ))"
        elif (( b < 1048576 ));    then printf '%4dK' "$(( b / 1024 ))"
        elif (( b < 104857600 ));  then printf '%4.1fM' "$(( b / 1048576.0 ))"
        elif (( b < 1073741824 )); then printf '%4dM' "$(( b / 1048576 ))"
        else                            printf '%4.1fG' "$(( b / 1073741824.0 ))"
        fi
    }

    _lssplit_hdate() {
        local mt=$1
        if (( now - mt > 15768000 )); then
            date -r "$mt" '+%b %e  %Y'
        else
            date -r "$mt" '+%b %e %H:%M'
        fi
    }

    _lssplit_header() {
        local title=$1 count=$2 icon_arg=${3:-} icon_color=${4:-}
        local icon=""
        (( icons )) && [[ -n $icon_arg ]] && icon=$icon_arg
        local visible
        if [[ -n $icon ]]; then visible=" ${icon}  ${title} (${count}) "
        else                    visible=" ${title} (${count}) "
        fi
        local tlen=${#visible}
        local left=$(( (width - tlen) / 2 ))
        local right=$(( width - tlen - left ))
        (( left  < 0 )) && left=0
        (( right < 0 )) && right=0
        local label
        if [[ -n $icon ]]; then
            label=" ${icon_color}${icon}${reset}  ${bold}${title}${reset}${c_header} (${count}) "
        else
            label=" ${bold}${title}${reset}${c_header} (${count}) "
        fi
        printf '%s%s%s%s%s\n' \
            "$c_header" \
            "${(l:$left::─:)}" \
            "$label" \
            "${(l:$right::─:)}" \
            "$reset"
    }

    _lssplit_render_entry() {
        local name=$1
        local IFS=$sep
        local fpath kind perms size mtime tgt hidden
        read -r fpath kind perms size mtime tgt hidden <<< "${info[$name]}"

        local color=""
        case $kind in
            dir)  color=$c_dir ;;
            link) color=$c_link ;;
            file) [[ $perms == *x* ]] && color=$c_exec ;;
        esac
        (( hidden )) && color=$c_hidden
        [[ $kind == link && ! -e $fpath ]] && color=$c_broken

        local icon=$(_lssplit_icon "$name" "$kind" "$hidden")
        local icon_sp=""
        [[ -n $icon ]] && icon_sp=" "

        local hsz hdt
        if [[ $kind == dir ]]; then hsz="    -"
        else                        hsz=$(_lssplit_hsize "$size")
        fi
        hdt=$(_lssplit_hdate "$mtime")

        case $mode in
            compact)
                local fixed=$(( 2 + 2 + 2 + 5 + 2 + 12 ))
                (( icons )) || fixed=$(( fixed - 2 ))
                local nw=$(( width - fixed ))
                (( nw < 10 )) && nw=10
                local display=$name
                (( ${#display} > nw )) && display="${display[1,nw-1]}…"
                printf '  %s%s%s%-*s%s  %s%5s%s  %s%s%s\n' \
                    "$color" "$icon" "$icon_sp" \
                    $nw "$display" "$reset" \
                    "$c_meta" "$hsz" "$reset" \
                    "$c_meta" "$hdt" "$reset"
                ;;
            full)
                local target_str=""
                [[ $kind == link && -n $tgt ]] && target_str=" ${c_target}→ ${tgt}${reset}"
                printf '  %s%s%s%s%s%s  %s%5s%s  %s%-12s%s  %s%s%s%s\n' \
                    "$color" "$icon" "$icon_sp" \
                    "$c_meta" "$perms" "$reset" \
                    "$c_meta" "$hsz" "$reset" \
                    "$c_meta" "$hdt" "$reset" \
                    "$color" "$name" "$reset" "$target_str"
                ;;
        esac
    }

    _lssplit_render_grid() {
        (( $# == 0 )) && return
        local max=0 nm
        for nm in "$@"; do
            (( ${#nm} > max )) && max=${#nm}
        done
        local cell=$(( max + 2 ))
        (( icons )) && cell=$(( cell + 2 ))
        local cols=$(( width / cell ))
        (( cols < 1 )) && cols=1
        local i=0 IFS=$sep
        local fpath kind perms size mtime tgt hidden color icon icon_sp
        for nm in "$@"; do
            read -r fpath kind perms size mtime tgt hidden <<< "${info[$nm]}"
            color=""
            case $kind in
                dir)  color=$c_dir ;;
                link) color=$c_link ;;
                file) [[ $perms == *x* ]] && color=$c_exec ;;
            esac
            (( hidden )) && color=$c_hidden
            [[ $kind == link && ! -e $fpath ]] && color=$c_broken
            icon=$(_lssplit_icon "$nm" "$kind" "$hidden")
            icon_sp=""
            [[ -n $icon ]] && icon_sp=" "
            printf '%s%s%s%-*s%s' "$color" "$icon" "$icon_sp" $max "$nm" "$reset"
            (( i++ ))
            if (( i % cols == 0 )); then printf '\n'
            else                          printf '  '
            fi
        done
        (( i % cols != 0 )) && printf '\n'
    }

    if (( ${#names_dir} > 0 )); then
        _lssplit_header "Directories" ${#names_dir} "$i_dir" "$c_dir"
        if [[ $mode == grid ]]; then
            _lssplit_render_grid "${names_dir[@]}"
        else
            for n in "${names_dir[@]}"; do _lssplit_render_entry "$n"; done
        fi
    fi
    if (( ${#names_file} > 0 )); then
        _lssplit_header "Files" ${#names_file} "$i_file" ""
        if [[ $mode == grid ]]; then
            _lssplit_render_grid "${names_file[@]}"
        else
            for n in "${names_file[@]}"; do _lssplit_render_entry "$n"; done
        fi
    fi
    if (( ${#names_link} > 0 )); then
        _lssplit_header "Symlinks" ${#names_link} "$i_link" "$c_link"
        if [[ $mode == grid ]]; then
            _lssplit_render_grid "${names_link[@]}"
        else
            for n in "${names_link[@]}"; do _lssplit_render_entry "$n"; done
        fi
    fi

    unfunction _lssplit_icon _lssplit_hsize _lssplit_hdate _lssplit_header \
        _lssplit_render_entry _lssplit_render_grid 2>/dev/null
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

# Style the vcs_info messages — two formats so branch and status can live in
# separate colour segments. msg_0 = branch name; msg_1 = status symbols + arrows.
# No colour codes here; colours are applied in PROMPT so zsh treats them as
# zero-width (avoids cursor drift).
zstyle ':vcs_info:*' enable git
zstyle ':vcs_info:git*' formats '%b' '%u%c%m'
zstyle ':vcs_info:git*' actionformats '%b [%a]' '%u%c%m'
zstyle ':vcs_info:git*' unstagedstr '□'
zstyle ':vcs_info:git*' stagedstr '■'
zstyle ':vcs_info:*:*' check-for-changes true
zstyle ':vcs_info:git*+set-message:*' hooks git-ahead-behind

# Append ↑N ↓N to %m (appears in msg_1) when the branch has an upstream
function +vi-git-ahead-behind() {
    local -a ab
    git rev-parse ${hook_com[branch]}@{upstream} &>/dev/null || return 0
    ab=($(git rev-list --left-right --count HEAD...${hook_com[branch]}@{upstream} 2>/dev/null))
    local ahead=${ab[1]} behind=${ab[2]}
    local arrows=''
    (( ahead  )) && arrows+="↑${ahead}"
    (( behind )) && arrows+="${arrows:+ }↓${behind}"
    # Use = instead of += to avoid duplication when vcs_info processes multiple formats
    [[ -n $arrows ]] && hook_com[misc]=" ${arrows}"
}

# Rebuild PROMPT before each command.
# Line 1: three cascading segments with Rounded separators (, ).
#   178 (#d7af00) path  →  220 (#ffd700) branch  →  226 (#ffff00) status
# Line 2: input line.
_set_prompt() {
    local branch=${vcs_info_msg_0_//\%/%%}
    local status_str=${${vcs_info_msg_1_//\%/%%}## }  # trim hook's leading space

    # Path segment (with rounded start)
    local line1="%F{178}%K{178}%F{black} %B%~%b %f"
    
    if [[ -n $branch ]]; then
        # Transition Path -> Branch
        line1+="%K{220}%F{178}%F{black} ⎇ ${branch} %f"
        
        if [[ -n $status_str ]]; then
            # Transition Branch -> Status
            line1+="%K{226}%F{220}%F{black} ${status_str} %f%k%F{226}%f"
        else
            # End Branch segment
            line1+="%k%F{220}%f"
        fi
    else
        # End Path segment
        line1+="%k%F{178}%f"
    fi

    PROMPT="${line1}"$'\n'"%(?.%F{blue}●.%F{red}●)%f %# "
}
add-zsh-hook precmd _set_prompt

RPROMPT=''


# --------------------------------------------------------
# LOCAL OVERRIDES
# --------------------------------------------------------

[[ -f ~/.zshrc.local ]] && source ~/.zshrc.local
