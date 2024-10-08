declare-option str ssh_terminal_target
declare-option str ssh_terminal_server %sh{echo $HOSTNAME}
declare-option str ssh_terminal_cmd

define-command ssh-exec -override -params 2 -docstring 'ssh-exec <target> <shell command>' %{
    evaluate-commands %sh{
        dir=$(mktemp -d "${TMPDIR:-/tmp}"/kak-ssh.XXXXXXXX)
        mkfifo "$dir/fifo"
        echo "#!/bin/sh" > $dir/askpass
        echo "echo 'eval -client $kak_client -verbatim -- prompt -password -on-abort %{ echo -to-file $dir/fifo } ssh-password: %{ echo -to-file $dir/fifo %val{text} }' | kak -p $kak_session" >> $dir/askpass
        echo "cat '$dir/fifo'" >> $dir/askpass
        chmod +x "$dir/askpass"

        (
            trap "rm -R $dir" EXIT
            SSH_ASKPASS_REQUIRE=force SSH_ASKPASS="$dir/askpass" ssh $1 -- "$2" 2>&1 |
                while read -r line; do
                    ( echo "eval -client $kak_client -verbatim info %{ssh: $line}; echo -debug %{ssh: $line}" | kak -p $kak_session )
                done
        ) >/dev/null </dev/null 2>&1 &
    }
}

define-command ssh-terminal -override -params .. %{
    evaluate-commands -save-regs 'a' %{
        set-register a %arg{@}
        ssh-exec %opt{ssh_terminal_target} %sh{
            echo "$kak_opt_ssh_terminal_cmd \"ssh -t $kak_opt_ssh_terminal_server -- \\\"cd $PWD; env PATH=$PATH XDG_RUNTIME_DIR=$XDG_RUNTIME_DIR $kak_quoted_reg_a\\\"\""
        }
    }
}

define-command ssh-teminal-enable-from-connection -params 1 %{
    evaluate-commands %sh{
        if [ -z "$SSH_CONNECTION" ]; then
            echo "fail 'SSH_CONNECTION is not set'"
            exit
        fi
        echo "set global windowing_module ssh"
        echo "set global ssh_terminal_target $(echo $SSH_CONNECTION | cut -d' ' -f1)"
        echo "set global ssh_terminal_server $(echo $SSH_CONNECTION | cut -d' ' -f3)"
        echo "set global ssh_terminal_cmd %{$1}"
    }
}

alias global ssh-terminal-window ssh-terminal
alias global ssh-terminal-horizontal ssh-terminal
alias global ssh-terminal-vertical ssh-terminal
alias global ssh-terminal-tab ssh-terminal
