if status is-interactive
    set -gx PATH $PATH $HOME/.local/bin /opt/bin $HOME/.cargo/bin $HOME/.local/dotnet $HOME/.local/go/bin $HOME/dev/go/bin $HOME/.cargo/bin
    set -gx DOTNET_ROOT $HOME/.local/dotnet
    set -gx NVM_DIR $HOME/.nvm

    if not test -e $HOME/.config/fish/functions/fisher.fish
        curl -sL https://raw.githubusercontent.com/jorgebucaran/fisher/main/functions/fisher.fish | source && fisher install jorgebucaran/fisher
    end
end