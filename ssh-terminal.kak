declare-option str ssh_terminal_target
declare-option str ssh_terminal_cmd

define-command ssh-terminal -override -params .. %{
    evaluate-commands -save-regs 'a' %{
        set-register a %arg{@}
        evaluate-commands %sh{
            dir=$(mktemp -d "${TMPDIR:-/tmp}"/kak-ssh.XXXXXXXX)
            mkfifo "$dir/fifo"
            echo "echo 'eval -client $kak_client -verbatim -- prompt -password ssh-password:  %{ echo -to-file $dir/fifo %val{text} }' | kak -p $kak_session" >> $dir/askpass
            echo "cat '$dir/fifo'" >> $dir/askpass
            chmod +x "$dir/askpass"

            (
                trap "rm -R $dir" EXIT
                SSH_ASKPASS_REQUIRE=force SSH_ASKPASS="$dir/askpass" ssh $kak_opt_ssh_terminal_target -- \
                    "( $kak_opt_ssh_terminal_cmd \"ssh -t $HOSTNAME -- \\\"cd $PWD; env PATH=$PATH $kak_quoted_reg_a\\\"\" ) >/dev/null </dev/null 2>&1 &" 2>&1 |
                    while read -r line; do
                        ( echo "eval -client $kak_client -verbatim info %{ssh: $line}; echo -debug %{ssh: $line}" | kak -p $kak_session )
                    done
            ) >/dev/null </dev/null 2>&1 &
        }
    }
}
