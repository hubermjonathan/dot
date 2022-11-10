""""""""""""""""""""""
"    Vundle Setup    "
"                    "
""""""""""""""""""""""
set nocompatible
filetype off
set rtp+=~/.vim/bundle/Vundle.vim

call vundle#begin()

" main vundle plugin
Plugin 'VundleVim/Vundle.vim'

" tree view
Plugin 'scrooloose/nerdtree'

" better bottom status bar
Plugin 'itchyny/lightline.vim'

" syntax highlighting for TypeScript
Plugin 'leafgarland/typescript-vim'

call vundle#end()
filetype plugin indent on


"""""""""""""""""""""""""""
"    NERDTree Settings    "
"                         "
"""""""""""""""""""""""""""
" auto open the tree view
autocmd vimenter * NERDTree

" open nerd tree without specifying a file
autocmd StdinReadPre * let s:std_in=1
autocmd VimEnter * if argc() == 0 && !exists("s:std_in") | NERDTree | endif

" show hidden files
let NERDTreeShowHidden=1

" map toggle NERDTree to control-n
map <C-n> :NERDTreeToggle<CR>


""""""""""""""""""""""
"    Key Mappings    "
"                    "
""""""""""""""""""""""
" easier method for switching between windows
map <C-j> <C-W>j
map <C-k> <C-W>k
map <C-h> <C-W>h
map <C-l> <C-W>l

" remap escape to jk
imap jk <Esc>

" remap Q to quit all
command Q qa


"""""""""""""""""""""""""
"    Editor Settings    "
"                       "
"""""""""""""""""""""""""
" fix backspace behavior
set backspace=eol,start,indent
set backspace=2

" turn on auto indenting
set ai
set si

" use spaces instead of tabs
set expandtab

" set tab to space amount
set shiftwidth=2
set tabstop=2

" wrap lines
set wrap


"""""""""""""""""""""""""
"    Search Settings    "
"                       "
"""""""""""""""""""""""""
" ignore case when searching
set ignorecase

" turn on smart case search
set smartcase

" highlight search results
set hlsearch

" turn on incrementing searches
set incsearch


"""""""""""""""""""""""
"    View Settings    "
"                     "
"""""""""""""""""""""""
" enable syntax highlighting
syntax enable

" turn on numbered lines
set nu

" turn on show matching brackets
set showmatch
set mat=2

" turn on visual ruler
set ruler

" set colorscheme
colo noir
