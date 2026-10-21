filetype plugin indent on

autocmd vimenter * NERDTree
let NERDTreeShowHidden=1
map <C-n> :NERDTreeToggle<CR>

map <C-j> <C-W>j
map <C-k> <C-W>k
map <C-h> <C-W>h
map <C-l> <C-W>l
imap jk <Esc>
command Q qa

set backspace=eol,start,indent
set ai
set si
set expandtab
set shiftwidth=2
set tabstop=2

set ignorecase
set smartcase
set hlsearch
set incsearch

syntax enable
set nu
set showmatch
set mat=2
set ruler
colo 256_noir
