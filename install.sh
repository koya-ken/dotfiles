#!/usr/bin/env bash

BASHRC_ID=2edf6971-2384-4a15-b10e-5c67587e9a57
DUMMY_ID=52728688-620e-448d-b8a2-2c84bb4bbf2b

# https://unix.stackexchange.com/questions/552188/how-to-remove-empty-lines-from-beginning-and-end-of-file
function __trim_line_file() {
    sed -i -e '/./,$!d' -e :a -e '/^\n*$/{$d;N;ba' -e '}' $1
}

function __install_bashrc() {
    cat <<EOF >> ~/.bashrc

# $BASHRC_ID
# install from dotfiles

if [ -f ~/.dotfiles/.bashrc ]; then
    . ~/.dotfiles/.bashrc
fi
# after install dotfiles
# $BASHRC_ID

EOF
__trim_line_file ~/.bashrc
}

function install_bashrc() {
    if (grep $BASHRC_ID ~/.bashrc >/dev/null) ; then
        echo bashrc already installed.
    else
        echo install bashrc.
        __install_bashrc
    fi
}

function __uninstall_bashrc {
    awk -v DUMMY_ID="$DUMMY_ID" -v BASHRC_ID="# $BASHRC_ID" 'BEGIN{FS=DUMMY_ID; RS=BASHRC_ID;OFS="";ORS=""} NR!=2 {print $NF}' ~/.bashrc |tee ~/.bashrc >/dev/null
    __trim_line_file ~/.bashrc
}

function uninstall_bashrc {
    if (grep $BASHRC_ID ~/.bashrc >/dev/null) ; then
        echo bashrc uninstall.
        __uninstall_bashrc
    else
        echo bashrc not installed.
    fi
}

function install_vimrc() {
    echo instll vimrc.
    cat <<EOF > .vimrc
source ~/.dotfiles/.vimrc
EOF

}

function uninstall_vimrc() {
    echo uninstall vimrc.
    rm ~/.vimrc
}

function install_inputrc() {
    echo instll inputrc.
    cat <<EOF > ~/.inputrc
\$include ~/.dotfiles/.inputrc
EOF
}

function uninstall_inputrc() {
    echo uninstall inputrc.
    rm ~/.inputrc
}

function install_tmux_conf() {
    echo instll tmux.conf.
    cat <<EOF > ~/.tmux.conf
    source-file ~/.dotfiles/.tmux.conf
EOF
}

function uninstall_tmux_conf() {
    echo uninstall tmux.conf.
    rm ~/.tmux.conf
}

function install_dotfiles () {
    echo install dotfiles.
    install_bashrc
    install_vimrc
    install_inputrc
    install_tmux_conf
}

function uninstall_dotfiles() {
    echo uninstall dotfiles.
    uninstall_bashrc
    uninstall_vimrc
    uninstall_inputrc
    uninstall_tmux_conf
}

function usage {
    cat <<EOM
Usage: $(basename "$0") [OPTION]...
  -h          Display help
  -i          install dotfiles
  -u          uninstall dotfiles
EOM

exit 2
}

# https://unix.stackexchange.com/questions/287190/execute-default-option-when-no-options-are-specified-in-getopts
if [ "$#" == 0 ]; then
    usage
fi

# https://qiita.com/Esfahan/items/e88bb806c7ca1dc8b758
while getopts iuh: optKey; do
    case "$optKey" in
        i)
            install_dotfiles
            ;;
        u)
            uninstall_dotfiles
            ;;
        '-h'|'--help'|* )
            usage
            ;;
    esac
done

