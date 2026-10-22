link .vimrc ~/.vimrc
post_link install-plugins 'for p in preservim/nerdtree itchyny/lightline.vim andreasvc/vim-256noir; do d="$HOME/.vim/pack/plugins/start/${p#*/}"; test -d "$d" || git clone -q --depth 1 "https://github.com/$p" "$d" || exit 1; done'
