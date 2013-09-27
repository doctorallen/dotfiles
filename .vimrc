" http://py.vaults.ca/~x/python_and_vim.html

set backspace=2 sts=4 ts=4 sw=4 smarttab noet ai nocp wrap
set ruler nowrap backspace=2 hidden showmatch matchtime=3
set wrap incsearch ignorecase hlsearch mouse=a
set updatecount=50 showmatch matchtime=3
set modeline modelines=5 nu spr
set iskeyword-=_
set t_Co=256
call pathogen#infect()
call pathogen#helptags()
filetype plugin indent on
" paste and indent
map <leader>P P'[v']=
map <leader>p p'[v']=
" wordwraps a paragraph
map <leader>q gqap
" makes the current window wider by 10 characters
map <leader>] 10<C-W>>
" makes the current window smaller by 10 characters
map <leader>[ 10<C-W><

map <leader>v :call TogglePasteMode()<CR>

map <silent> <leader>l :nohl<CR>
map <silent> <leader>L :se nu!<CR>
nmap <leader>s :source ~/.vimrc<CR>

map K <Nop>
"automatic nerd tree
autocmd VimEnter * if &filetype !=# 'gitcommit' | NERDTree | wincmd p | endif
"automatically close vim in NERDTree is the only buffer open
autocmd bufenter * if (winnr("$") == 1 && exists("b:NERDTreeType") && b:NERDTreeType == "primary") | q | endif

"vim-airline
let g:airline_theme = 'powerlineish'

"vim-ne0complcache
let g:neocomplcache_enable_at_startup = 1

" http://vim.wikia.com/wiki/Open_SVN_diff_window
map <leader>d :vnew<CR>:read !svn diff<CR>:set syntax=diff buftype=nofile<CR>ggdd

:nnoremap <leader>i :setl noai nocin nosi inde=<CR>

"highlight LineNr term=bold cterm=NONE ctermfg=DarkGrey ctermbg=NONE gui=NONE guifg=DarkGrey guibg=NONE

" abbr epoch <C-R>=strftime('%s')<CR>
abbr Firephp PSU::get('firephp')


autocmd BufRead *.py set smartindent cinwords=if,elif,else,for,while,try,except,finally,def,class
autocmd BufWritePre *.py normal m`:%s/\s\+$//e ``
autocmd BufRead,BufNewFile *.html set filetype=php
autocmd BufRead,BufNewFile *.sass set filetype=css
autocmd BufRead,BufNewFile *.scss set filetype=css
autocmd BufRead,BufNewFile .*rc set filetype=sh

filetype indent on

set suffixes=.bak,~,.o,.h,.info,.swp,.obj,.pyc

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

set wildmenu
set wildmode=list:longest,full

function! MyTabOrComplete()
	let col = col('.')-1
		if !col || getline('.')[col-1] !~ '\k'
		return "\<tab>"
	else
		return "\<C-N>"
	endif
endfunction
inoremap <Tab> <C-R>=MyTabOrComplete()<CR>

" gf helpers (goto file)
set suffixesadd=.php,.class.php,.inc.php
set includeexpr=substitute(v:fname,'-$','','g')

syntax on
set background=dark
colorscheme railscasts
"highlight Comment ctermfg=Brown guifg=Brown

"folding settings
"set foldmethod=indent
"set foldnestmax=10
"set nofoldenable
"set foldlevel=1

"set t_Co=256
set ffs=unix,dos,mac

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

" Change highlight colors for vimdiff
highlight DiffAdd cterm=none ctermfg=black ctermbg=Green gui=none guifg=black guibg=Green 
highlight DiffDelete cterm=none ctermfg=black ctermbg=Red gui=none guifg=black guibg=Red 
highlight DiffChange cterm=none ctermfg=black ctermbg=Yellow gui=none guifg=black guibg=Yellow 
highlight DiffText cterm=none ctermfg=black ctermbg=Magenta gui=none guifg=black guibg=Magenta


hi Conceal ctermfg=Cyan ctermbg=NONE

"indent guides
let g:indent_guides_start_level=2
let g:indent_guides_guide_size=1
autocmd VimEnter,Colorscheme * :hi IndentGuidesOdd  guibg=red   ctermbg=3
autocmd VimEnter,Colorscheme * :hi IndentGuidesEven guibg=green ctermbg=4
:command -nargs=1 Dbug :normal iecho '<pre>';<CR>print_r($<args>);<CR>echo '</pre>';<CR><ESC>
" PHP-Doc configuration and key-mappings
" autocmd FileType php inoremap <leader>c <ESC>:call PhpDocSingle()<CR>i
autocmd FileType php nnoremap <leader>c :call PhpDocSingle()<CR>
autocmd FileType php vnoremap <leader>c :call PhpDocRange()<CR>
let g:pdv_cfg_autoEndFunction = 0 " Disable function end trailing comment
