echo $(cat $HOME/.ssh/id_ecdsa | sha256sum | head -c 16)
