function vpn -a name
    if test -z "$name"
        set name 'server'
    end
    vpn-down
    mkdir -p $HOME/.config/weavc/vpn
    sudo wg-quick up $HOME/.config/weavc/vpn/$name.conf 2> /dev/null && echo 'connected'
end

function vpn-list
    mkdir -p $HOME/.config/weavc/vpn
    ls $HOME/.config/weavc/vpn
end

function vpn-down 
    mkdir -p $HOME/.config/weavc/vpn
    sudo wg-quick down $HOME/.config/weavc/vpn/$(sudo wg show | grep -i 'interface:' | sed 's/interface: //1').conf 2> /dev/null && echo 'disconnected'
end
