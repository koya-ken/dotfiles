inoremap <silent> jj <ESC>
set number
set tabstop=4
set shiftwidth=4
set expandtab

" https://unix.stackexchange.com/questions/19945/auto-indent-format-code-for-vim
filetype indent on
set smartindent
autocmd BufRead,BufWritePre *.sh normal gg=G

" https://linuxfan.info/bow-stop-beep
set visualbell t_vb=
colorscheme murphy
