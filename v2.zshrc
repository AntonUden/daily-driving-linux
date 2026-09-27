# ~/.zshrc file for zsh non-login shells.

# =============================================================================
# 1. ENVIRONMENT VARIABLES
# =============================================================================
export LC_ALL=en_US.UTF-8
export PATH="$HOME/.cargo/bin:$PATH"
export PROMPT_EOL_MARK=""          # Hide EOL sign ('%')
WORDCHARS=${WORDCHARS//\/}         # Don't consider certain characters part of the word

# =============================================================================
# 2. ZSH OPTIONS
# =============================================================================
setopt autocd                      # Change directory just by typing its name
setopt interactivecomments         # Allow comments in interactive mode
setopt ksharrays                   # Arrays start at 0
setopt magicequalsubst             # Enable filename expansion for 'anything=expression'
setopt nonomatch                   # Hide error message if there is no match for the pattern
setopt notify                      # Report the status of background jobs immediately
setopt numericglobsort             # Sort filenames numerically when it makes sense
setopt promptsubst                 # Enable command substitution in prompt

# =============================================================================
# 3. HISTORY CONFIGURATION
# =============================================================================
HISTFILE=~/.zsh_history
HISTSIZE=10000
SAVEHIST=10000
setopt hist_expire_dups_first      # Delete duplicates first when HISTFILE size exceeds HISTSIZE
setopt hist_ignore_dups            # Ignore duplicated commands history list
setopt hist_ignore_space           # Ignore commands that start with space
setopt hist_verify                 # Show command with history expansion to user before running it

# =============================================================================
# 4. KEYBINDINGS
# =============================================================================
bindkey -e                                        # Emacs key bindings
bindkey ' ' magic-space                           # Do history expansion on space
bindkey '^[[3;5~' kill-word                       # Ctrl + Supr
bindkey '^[[5~' beginning-of-buffer-or-history    # Page up
bindkey '^[[6~' end-of-buffer-or-history          # Page down
bindkey '^[[Z' undo                               # Shift + Tab undo last action

# Home/End key variations across different terminal emulators
bindkey "^[[H" beginning-of-line
bindkey "^[[1~" beginning-of-line
bindkey "^[OH" beginning-of-line
bindkey "^[[F" end-of-line
bindkey "^[[4~" end-of-line
bindkey "^[OF" end-of-line

# =============================================================================
# 5. COMPLETIONS & DIRECTORIES
# =============================================================================
autoload -Uz compinit
compinit -d ~/.cache/zcompdump

# Enable Bash compatibility for completions (fixes 'complete' command not found)
autoload -U +X bashcompinit
bashcompinit

zstyle ':completion:*:*:*:*:*' menu select
zstyle ':completion:*' matcher-list 'm:{a-zA-Z}={A-Za-z}' # Case insensitive tab completion

if [[ -x /usr/bin/dircolors ]]; then
    test -r ~/.dircolors && eval "$(dircolors -b ~/.dircolors)" || eval "$(dircolors -b)"
    zstyle ':completion:*' list-colors "${(s.:.)LS_COLORS}"
fi

# =============================================================================
# 6. PROMPT & THEMING
# =============================================================================
# Chroot identification
if [[ -z "${debian_chroot:-}" ]] && [[ -r /etc/debian_chroot ]]; then
    debian_chroot=$(cat /etc/debian_chroot)
fi

# Git prompt logic
ZSH_THEME_GIT_PROMPT_PREFIX="-[git:"
ZSH_THEME_GIT_PROMPT_SUFFIX="]"
ZSH_THEME_GIT_PROMPT_DIRTY=" %F{red}✗%f"
ZSH_THEME_GIT_PROMPT_CLEAN=" %F{green}✔%f"

git_prompt_info() {
    local ref dirty
    ref=$(git symbolic-ref --short HEAD 2>/dev/null || git rev-parse --short HEAD 2>/dev/null)
    [[ -n "$ref" ]] || return
    if ! git diff --quiet 2>/dev/null || ! git diff --cached --quiet 2>/dev/null; then
        dirty="$ZSH_THEME_GIT_PROMPT_DIRTY"
    else
        dirty="$ZSH_THEME_GIT_PROMPT_CLEAN"
    fi
    echo "${ZSH_THEME_GIT_PROMPT_PREFIX}${ref}${ZSH_THEME_GIT_PROMPT_SUFFIX}${dirty}"
}

# Main Prompt
PROMPT=$'%F{%(#.blue.green)}┌──${debian_chroot:+($debian_chroot)──}(%B%F{%(#.red.blue)}%n%(#.💀.λ)%m%b%F{%(#.blue.green)})-[%B%F{reset}%(6~.%-1~/…/%4~.%5~)%b%F{%(#.blue.green)}]%b $(git_prompt_info)\n%F{%(#.blue.green)}└─%B%(#.%F{red}#.%F{blue}$)%b%F{reset} '

# Terminal Title
case "$TERM" in
    xterm*|rxvt*) TERM_TITLE='\e]0;${debian_chroot:+($debian_chroot)}%n@%m: %~\a' ;;
    *) TERM_TITLE='' ;;
esac

# Execution Timing & RPROMPT Setup
new_line_before_prompt=yes

preexec() {
    cmd_start_time=$(($(date +%s%0N)/1000000))
}

precmd() {
    if [[ -n "$cmd_start_time" ]]; then
        local now=$(($(date +%s%0N)/1000000))
        local elapsed=$((now - cmd_start_time))
        export RPROMPT="%F{cyan}${elapsed}ms %{$reset_color%}"
        unset cmd_start_time
    fi

    print -Pn "$TERM_TITLE"

    if [[ "$new_line_before_prompt" == "yes" ]]; then
        if [[ -z "$_NEW_LINE_BEFORE_PROMPT" ]]; then
            _NEW_LINE_BEFORE_PROMPT=1
        else
            print ""
        fi
    fi
}

# =============================================================================
# 7. ALIASES
# =============================================================================
alias history="history 0"
alias ls='ls --color=auto'
alias ll='ls -l'
alias la='ls -A'
alias l='ls -CF'
alias grep='grep --color=auto'
alias fgrep='fgrep --color=auto'
alias egrep='egrep --color=auto'
alias diff='diff --color=auto'
alias ip='ip --color=auto'
alias fuckthemshaders="rm ~/.local/share/Steam/steamapps/shadercache -fr"

# =============================================================================
# 8. PLUGINS & INTEGRATIONS
# =============================================================================
# NVM (Node Version Manager)
export NVM_DIR="$HOME/.nvm"
[[ -s "$NVM_DIR/nvm.sh" ]] && \. "$NVM_DIR/nvm.sh"
[[ -s "$NVM_DIR/bash_completion" ]] && \. "$NVM_DIR/bash_completion"

# Angular CLI autocompletion
if command -v ng &>/dev/null; then
    source <(ng completion script)
fi

# ZSH Autosuggestions
if [[ -f /usr/share/zsh-autosuggestions/zsh-autosuggestions.zsh ]]; then
    source /usr/share/zsh-autosuggestions/zsh-autosuggestions.zsh
    ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE='fg=#999'
fi

# ZSH Syntax Highlighting
if [[ -f /usr/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh ]]; then
    unsetopt ksharrays # Prevents breaking the plugin temporarily
    source /usr/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh

    # Custom Highlighting Styles
    ZSH_HIGHLIGHT_HIGHLIGHTERS=(main brackets pattern)
    ZSH_HIGHLIGHT_STYLES[unknown-token]=fg=red,bold
    ZSH_HIGHLIGHT_STYLES[reserved-word]=fg=cyan,bold
    ZSH_HIGHLIGHT_STYLES[suffix-alias]=fg=green,underline
    ZSH_HIGHLIGHT_STYLES[global-alias]=fg=magenta
    ZSH_HIGHLIGHT_STYLES[precommand]=fg=green,underline
    ZSH_HIGHLIGHT_STYLES[commandseparator]=fg=blue,bold
    ZSH_HIGHLIGHT_STYLES[autodirectory]=fg=green,underline
    ZSH_HIGHLIGHT_STYLES[path]=underline
    ZSH_HIGHLIGHT_STYLES[globbing]=fg=blue,bold
    ZSH_HIGHLIGHT_STYLES[history-expansion]=fg=blue,bold
    ZSH_HIGHLIGHT_STYLES[command-substitution-delimiter]=fg=magenta
    ZSH_HIGHLIGHT_STYLES[process-substitution-delimiter]=fg=magenta
    ZSH_HIGHLIGHT_STYLES[single-hyphen-option]=fg=magenta
    ZSH_HIGHLIGHT_STYLES[double-hyphen-option]=fg=magenta
    ZSH_HIGHLIGHT_STYLES[back-quoted-argument-delimiter]=fg=blue,bold
    ZSH_HIGHLIGHT_STYLES[single-quoted-argument]=fg=yellow
    ZSH_HIGHLIGHT_STYLES[double-quoted-argument]=fg=yellow
    ZSH_HIGHLIGHT_STYLES[dollar-quoted-argument]=fg=yellow
    ZSH_HIGHLIGHT_STYLES[rc-quote]=fg=magenta
    ZSH_HIGHLIGHT_STYLES[dollar-double-quoted-argument]=fg=magenta
    ZSH_HIGHLIGHT_STYLES[back-double-quoted-argument]=fg=magenta
    ZSH_HIGHLIGHT_STYLES[back-dollar-quoted-argument]=fg=magenta
    ZSH_HIGHLIGHT_STYLES[redirection]=fg=blue,bold
    ZSH_HIGHLIGHT_STYLES[comment]=fg=black,bold
    ZSH_HIGHLIGHT_STYLES[arg0]=fg=green
    ZSH_HIGHLIGHT_STYLES[bracket-error]=fg=red,bold
    ZSH_HIGHLIGHT_STYLES[bracket-level-1]=fg=blue,bold
    ZSH_HIGHLIGHT_STYLES[bracket-level-2]=fg=green,bold
    ZSH_HIGHLIGHT_STYLES[bracket-level-3]=fg=magenta,bold
    ZSH_HIGHLIGHT_STYLES[bracket-level-4]=fg=yellow,bold
    ZSH_HIGHLIGHT_STYLES[bracket-level-5]=fg=cyan,bold
    ZSH_HIGHLIGHT_STYLES[cursor-matchingbracket]=standout
fi

# Pager Color Support (Less)
export LESS_TERMCAP_mb=$'\E[1;31m'     # begin blink
export LESS_TERMCAP_md=$'\E[1;36m'     # begin bold
export LESS_TERMCAP_me=$'\E[0m'        # reset bold/blink
export LESS_TERMCAP_so=$'\E[01;33m'    # begin reverse video
export LESS_TERMCAP_se=$'\E[0m'        # reset reverse video
export LESS_TERMCAP_us=$'\E[1;32m'     # begin underline
export LESS_TERMCAP_ue=$'\E[0m'        # reset underline
