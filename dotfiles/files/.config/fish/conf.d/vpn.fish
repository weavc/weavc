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
    set -l wginterface (sudo wg show | grep -i 'interface:' | sed 's/interface: //1')
    sudo wg-quick down $HOME/.config/weavc/vpn/$wginterface.conf 2> /dev/null && echo 'disconnected'
end

function enc -a op -a file
    set -f enc_help "Usage: enc <e|d|ef|df> <file>
    \re:\tEncrypt input from editor to file.
    \rd:\tDecrypt file and open in editor.
    \ref:\tEncrypt input file.
    \rdf:\tDecrypt input file."
    set -f invalid_op "Operation parameter must be provided.\n\n$enc_help"

    if test -z "$op"
        printf $invalid_op
        return 1
    end

    if test "$op" = "help" || test "$op" = "--help" || test "$op" = "-h"
        printf $enc_help
        return 0
    end

    if test -z "$file"
        printf "File parameter must be provided"
        return 1
    end

    set -f tmpfile /run/user/(id -u)/enc.session
    set -f keyfile $HOME/.sec/enc_id_ed25519
    set -f enc_editor vim
    if command -q nvim
        set -f enc_editor nvim
    end

    truncate -s 0 $tmpfile

    if test "$op" = "e"
        $enc_editor $tmpfile
        age --encrypt -a -R $keyfile.pub -o $file $tmpfile
    else if test "$op" = "d"
        age --decrypt -i $keyfile -o $tmpfile $file
        $enc_editor $tmpfile
    else if test "$op" = "ef"
        age --encrypt --armor -R $keyfile.pub -o $file.enc $file
    else if test "$op" = "df"
        age --decrypt -i $keyfile -o (echo $file | sed -e 's/.enc$//') $file
    else
        printf $invalid_op
        return 1
    end

    truncate -s 0 $tmpfile
end
