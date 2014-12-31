" http://py.vaults.ca/~x/python_and_vim.html

call pathogen#infect()
call pathogen#helptags()

set backspace=2 sts=4 ts=4 sw=4 smarttab noet ai nocp wrap
set ruler nowrap backspace=2 hidden showmatch matchtime=3
set wrap incsearch ignorecase hlsearch mouse=a
set updatecount=50 showmatch matchtime=3
set modeline modelines=5 nu spr
set iskeyword-=_
set suffixes=.bak,~,.o,.h,.info,.swp,.obj,.pyc
set wildmenu
set wildmode=list:longest,full

syntax on
set background=dark
set t_Co=256
colorscheme helix
set cursorline

"folding settings
"set foldmethod=indent
"set foldnestmax=10
"set nofoldenable
"set foldlevel=1

set ffs=unix,dos,mac
filetype plugin indent on

" paste and indent
map <leader>P P'[v']=
map <leader>p p'[v']=
map <F3> :echo "hi<" . synIDattr(synID(line("."),col("."),1),"name") . '> trans<' . synIDattr(synID(line("."),col("."),0),"name") . "> lo<" . synIDattr(synIDtrans(synID(line("."),col("."),1)),"name") . ">" . " FG:" . synIDattr(synIDtrans(synID(line("."),col("."),1)),"fg#")<CR>

" wordwraps a paragraph
map <leader>q gqap
" makes the current window wider by 10 characters
map <leader>] 10<C-W>
" makes the current window smaller by 10 characters
map <leader>[ 10<C-W><

map <leader>v :call TogglePasteMode()<CR>

map <silent> <leader>l :nohl<CR>
map <silent> <leader>L :se nu!<CR>
nmap <leader>s :source ~/.vimrc<CR>

" Ctrl-j/k deletes blank line below/above, and Alt-j/k inserts.
nnoremap <silent><C-j> m`:silent +g/\m^\s*$/d<CR>``:noh<CR>
nnoremap <silent><C-k> m`:silent -g/\m^\s*$/d<CR>``:noh<CR>
nnoremap <silent><leader><o> :set paste<CR>m`o<Esc>``:set nopaste<CR>
nnoremap <silent><leader><O> :set paste<CR>m`o<Esc>``:set nopaste<CR>

" If the current buffer has never been saved, it will have no name,
" call the file browser to save it, otherwise just save it.
command -nargs=0 -bar Update if &modified 
                           \|    if empty(bufname('%'))
                           \|        browse confirm write
                           \|    else
                           \|        confirm write
                           \|    endif
                           \|endif
nnoremap <silent> <C-S> :<C-u>Update<CR>

map K <Nop>
"automatic nerd tree
autocmd VimEnter * if &filetype !=# 'gitcommit' | NERDTree | wincmd p | endif
"automatically close vim in NERDTree is the only buffer open
autocmd bufenter * if (winnr("$") == 1 && exists("b:NERDTreeType") && b:NERDTreeType == "primary") | q | endif

"vim-airline
let g:airline_theme = 'powerlineish'
"let g:airline#extensions#tabline#enabled = 1
let g:airline_powerline_fonts = 1

"tabularize
map <leader>t= :Tabularize /=<CR>
map <leader>t: :Tabularize /:<CR>
map <leader>t, :Tabularize /,<CR>

map <leader>m :set nonumber<CR> :set mouse-=a<CR>
map <S-Right> :wincmd l <CR>
map <S-Left> :wincmd h <CR>
map <S-Up> :wincmd k <CR>
map <S-Down> :wincmd j <CR>

:nnoremap <leader>i :setl noai nocin nosi inde=<CR>

"File Type functions
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

let php_sql_query=1
let php_htmlInStrings=1
let php_noShortTags=1
let php_folding=0

autocmd FileType php set makeprg=php\ -l\ %
autocmd FileType php set errorformat=%m\ in\ %f\ on\ line\ %l

"SYNTASTIC CONFIG

"let g:syntastic_check_on_open=1
"let g:syntastic_auto_loc_list=1


"function! MyTabOrComplete()
"	let col = col('.')-1
"		if !col || getline('.')[col-1] !~ '\k'
"		return "\<tab>"
"	else
"		return "\<C-N>"
"	endif
"endfunction
"inoremap <Tab> <C-R>=MyTabOrComplete()<CR>


function TogglePasteMode ()
	if (&paste)
		set nopaste
		echo "paste mode off"
     else
     	set paste
     	echo "paste mode on"
     endif
endfunction

" external copy paste -- saves selected buffer into your .viminfo file
" so you can paste it into another vim instance
vmap <silent> ,y "xy<CR>:wviminfo! ~/.viminfo<CR>
vmap <silent> ,d "xd<CR>:wviminfo! ~/.viminfo<CR>
nmap <silent> ,y "xyy<CR>:wviminfo! ~/.viminfo<CR>
nmap <silent> ,d "xdd<CR>:wviminfo! ~/.viminfo<CR>
nmap <silent> ,p :rviminfo! ~/.viminfo<CR>"xp
nmap <silent> ,p :rviminfo! ~/.viminfo<CR>"xp
nmap ,v :tabedit $MYVIMRC<CR>

" PHP-Doc configuration and key-mappings
autocmd FileType php inoremap <leader>c <ESC>:call PhpDocSingle()<CR>i
autocmd FileType php nnoremap <leader>c :call PhpDocSingle()<CR>
autocmd FileType php vnoremap <leader>c :call PhpDocRange()<CR>

let g:pdv_cfg_Author = "David Allen <trooper898@gmail.com>"
let g:pdv_cfg_autoEndFunction = 0 " Disable function end trailing comment
