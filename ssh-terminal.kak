declare-option str ssh_terminal_target
declare-option str ssh_terminal_cmd

define-command ssh-terminal -override -params .. %{
    evaluate-commands -save-regs 'a' %{
        set-register a %arg{@}
        evaluate-commands %sh{
            ssh $kak_opt_ssh_terminal_target -- "( $kak_opt_ssh_terminal_cmd \"ssh -t $HOSTNAME -- \\\"cd $PWD; env PATH=$PATH $kak_quoted_reg_a\\\"\" ) >/dev/null </dev/null 2>&1 &"
        }
    }
}
