set nocompatible                              " use the newest vim settings

call pathogen#infect()
call pathogen#helptags()

"-----------Searching----------"
set hlsearch                                            " when there is a previous search pattern, highlight all the matches
set ignorecase                                          " ignore case while searching
set incsearch                                           " show search matches incrementally as you are typing
set suffixes=.bak,~,.o,.h,.info,.swp,.obj,.pyc          " give lower precendence to these file suffixes when searching

let g:ag_prg="sift -n"                                  " use sift as the search program for the Ag plugin
let g:ag_highlight=1                                    " highlight results
let g:ag_format="%f:%l:%m"                              " format for Ag plugin output

"-----------Visuals----------"
colorscheme helix
syntax on                                               " turn on syntax highlighting
set background=dark                                     " dark background
set t_Co=256                                            " 256 Color mode in Terminal
set ruler                                               " show the line and column number of cursor position
set number                                              " show line numbers
set wildmenu                                            " command line completion
set wildmode=list:longest,full                          " display full list of commands
set cursorline                                          " highlight the line the cursor is on
set list                                                " show hidden characters
set listchars=tab:▸\ ,eol:¬                             " show tabs and end of line characters
let g:airline_theme = 'powerlineish'                    " set airline theme
"let g:airline#extensions#tabline#enabled = 1           " enables powerline to handle tabs
"let g:airline#extensions#tabline#tab_min_count = 2     " only show airline tabline if there is actually a tab
"let g:airline#extensions#tabline#buffer_min_count = 2  "
let g:airline_powerline_fonts = 1                       " turn powerline fonts on
set colorcolumn=80,120                                  " show a column at 80 characters
"highlight OverLength ctermbg=red ctermfg=white guibg=#592929 "highlights everything past 120 characters with light red background
"match OverLength /\%120v.\+/

"let php_sql_query=1                                    " allow for highlighting of MySQL in PHP strings
let php_htmlInStrings=1                                 " allow for highlighting of HTML in PHP strings 
"let php_noShortTags=1

"-----------GUI (MacVim)----------"
set guifont=Monaco\ for\ Powerline:h13                  " font for MacVim
set guioptions-=l                                       " remove left scrollbars
set guioptions-=L                                       " remove left scrollbars on a split
set guioptions-=r                                       " remove right scrollbars
set guioptions-=R                                       " remove right scrollbars on a split

"-----------Saving----------"
set updatecount=50                                      " write the swap file to disk after typing 50 chars (default is 200)

"-----------Splits----------"
set splitbelow                                          " create all splits to the bottom
set splitright                                          " create all splits to the right

"-----------Editing----------"
set wrap!                                               " wrap lines to the next line (add ! to prevent wrapping)
set showmatch matchtime=3                               " when adding a bracket or paren, briefly jump to the matching paren for 3/10 of a second
set softtabstop=4                                       " when hitting <BS>, pretend like a tab is removed, even if spaces
set expandtab                                           " expand tabs by default
set shiftwidth=4                                        " number of spaces to use for autoindenting
set shiftround                                          " use multiple of shiftwidth when indenting with '<' and '>'
set tabstop=4                                           " 4 spaces for tab
set smarttab                                            " use smart tabs (http://vimdoc.sourceforge.net/htmldoc/options.html#'smarttab')
set autoindent                                          " copy indent from current line when creating a new line

set ffs=unix,dos,mac                                    " The types of files that can be opened
filetype plugin indent on                               " enables file detection, filetype scripts, and filetype indent scripts



"-----------Mappings----------"

" Toogle NERDTree visibility
map <F2> :NERDTreeToggle<CR>

" Find current buffer in NERDTree
map <F3> :NERDTreeFind<CR>

" Output the highlight rules under the cursor
map <F4> :echo "hi<" . synIDattr(synID(line("."),col("."),1),"name") . '> trans<' . synIDattr(synID(line("."),col("."),0),"name") . "> lo<" . synIDattr(synIDtrans(synID(line("."),col("."),1)),"name") . ">" . " FG:" . synIDattr(synIDtrans(synID(line("."),col("."),1)),"fg#")<CR>
nnoremap <F5> :GundoToggle<CR>

" Files that NERDTree Ignores
let NERDTreeIgnore = ['\.swp$', '\.vagrant\/']

" wordwraps a paragraph
map <leader>q gqap

" starts the current project's vagrant instance
map <leader>v :!vagrant up<CR>

" reload vimrc file
nmap <leader>s :source ~/.vimrc<CR>

"-----------Commands and Functions----------"

" If the current buffer has never been saved, it will have no name,
" call the file browser to save it, otherwise just save it.
command! -nargs=0 -bar Update if &modified
                           \|    if empty(bufname('%'))
                           \|        browse confirm write
                           \|    else
                           \|        confirm write
                           \|    endif
                           \|endif
nnoremap <silent> <C-S> :<C-u>Update<CR>

" show NERDTree on open except for a git commit message
autocmd VimEnter * if &filetype !=# 'gitcommit' | NERDTree | wincmd p | endif

"automatically close vim if NERDTree is the only buffer open
autocmd bufenter * if (winnr("$") == 1 && exists("b:NERDTreeType") && b:NERDTreeType == "primary") | q | endif

"retab
map <leader>r :retab<CR>

" tabularize mappings
map <leader>t= :Tabularize /=<CR>
map <leader>t> :Tabularize /=><CR>
map <leader>t: :Tabularize /:<CR>
map <leader>t, :Tabularize /,<CR>

" Movement through buffers with shift and arrow keys
map <S-Right> :wincmd l <CR>
map <S-Left> :wincmd h <CR>
map <S-Up> :wincmd k <CR>
map <S-Down> :wincmd j <CR>

" Movement through tabs with cmd and arrow keys
map <D-Right> :tabnext<CR>
map <D-Left> :tabprevious <CR>

" Set filetypes based on directory locations and file extension
autocmd BufRead *.py set smartindent cinwords=if,elif,else,for,while,try,except,finally,def,class
autocmd BufWritePre *.py normal m`:%s/\s\+$//e ``
autocmd BufRead,BufNewFile *.html set filetype=php
autocmd BufRead,BufNewFile *.sass set filetype=css
autocmd BufRead,BufNewFile *.less set filetype=less
autocmd BufRead,BufNewFile *.scss set filetype=css
autocmd BufRead,BufNewFile .*rc set filetype=sh
autocmd BufNewFile,BufRead apache2/*.conf* setf apache
autocmd BufNewFile,BufRead apache2/conf/*.conf* setf apache
autocmd BufNewFile,BufRead apache2/conf.d/*.conf* setf apache
autocmd BufNewFile,BufRead apache/*.conf* setf apache
autocmd BufNewFile,BufRead apache/conf/*.conf* setf apache
autocmd BufNewFile,BufRead apache/conf.d/*.conf* setf apache
autocmd BufNewFile,BufRead httpd/*.conf* setf apache
autocmd BufNewFile,BufRead httpd/conf/*.conf* setf apache
autocmd BufNewFile,BufRead httpd/conf.d/*.conf* setf apache
autocmd BufRead,BufNewFile *.md set filetype=markdown

autocmd FileType python set omnifunc=pythoncomplete#Complete
autocmd FileType javascript set omnifunc=javascriptcomplete#CompleteJS
autocmd FileType html set omnifunc=htmlcomplete#CompleteTags
autocmd FileType css set omnifunc=csscomplete#CompleteCSS
autocmd FileType make set noexpandtab

autocmd FileType php set makeprg=php\ -l\ %
autocmd FileType php set errorformat=%m\ in\ %f\ on\ line\ %l

"if saving vimrc, automatically source it
autocmd! bufwritepost .vimrc source %

"SYNTASTIC CONFIG

"let g:syntastic_check_on_open=1
"let g:syntastic_auto_loc_list=1

function! Trailspace ()
	%s/\s\+$//e
endfunction

function! Condenselines ()
	call Trailspace()
	%s/\n\{3,}/\r\r/e
endfunction

map <leader>n :call Condenselines()<CR>

" php namespace
inoremap <Leader>e <C-O>:call PhpExpandClass()<CR>
noremap <Leader>e :call PhpExpandClass()<CR>

" PHP-Doc configuration and key-mappings
autocmd FileType php inoremap <leader>c <ESC>:call PhpDocSingle()<CR>i
autocmd FileType php nnoremap <leader>c :call PhpDocSingle()<CR>
autocmd FileType php vnoremap <leader>c :call PhpDocRange()<CR>

let g:pdv_cfg_Author = "David Allen <trooper898@gmail.com>"
let g:pdv_cfg_autoEndFunction = 0 " Disable function end trailing comment
