# [ported from .zshrc] tmux session manager
#   t          — fzf-pick an existing session
#   t <name>   — attach, or create in a known/zoxide-resolved dir
function t --description 'tmux session manager'
    set -l name $argv[1]

    if test -z "$name"
        set -l sessions (tmux list-sessions -F '#S' 2>/dev/null)
        if test -z "$sessions"
            echo "No active sessions. Usage: t <name> [dir]"
            return
        end
        set name (printf '%s\n' $sessions | fzf --prompt="Session: " --height=10)
        test -z "$name"; and return
        tmux attach-session -t "$name"
        return
    end

    if tmux has-session -t "$name" 2>/dev/null
        tmux attach-session -t "$name"
        return
    end

    set -l dir $argv[2]
    if test -z "$dir"
        switch $name
            case office;       set dir "$HOME/dev/office"
            case personal;     set dir "$HOME/dev/personal"
            case professional; set dir "$HOME/dev/professional"
            case sandbox;      set dir "$HOME/dev/sandbox"
            case dotfiles dot; set dir "$HOME/Documents/dot-files"
            case '*';          set dir (zoxide query "$name" 2>/dev/null; or echo "$HOME")
        end
    end

    test -d "$dir"; or set dir "$HOME"
    tmux new-session -d -s "$name" -c "$dir"
    tmux attach-session -t "$name"
end
