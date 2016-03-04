set background=dark
hi clear
if exists("syntax_on")
  syntax reset
endif

let g:colors_name = "helix"

hi link htmlTag                     xmlTag
hi link htmlTagName                 xmlTagName
hi link htmlEndTag                  xmlEndTag

highlight Normal                    guifg=#E6E1DC guibg=#111111 
highlight Cursor                    guifg=#000000 ctermfg=0 guibg=#FFFFFF ctermbg=15	
highlight CursorLine                guibg=#1c1c1c ctermbg=233 cterm=NONE
highlight CursorColumn              guibg=#1c1c1c ctermbg=233 cterm=NONE
highlight ColorColumn               guibg=#262626 ctermbg=233 cterm=NONE

highlight Comment                   guifg=#4e4e4e ctermfg=239 gui=italic
highlight Constant                  guifg=#448AA9 ctermfg=31
highlight Define                    guifg=#af8787 ctermfg=138
highlight Error                     guifg=#ffdf5f ctermfg=221 guibg=#990000 ctermbg=88
highlight Function                  guifg=#af8787 ctermfg=221 gui=NONE cterm=NONE
highlight Identifier                guifg=#448AA9 ctermfg=31 gui=NONE cterm=NONE
highlight Include                   guifg=#af8787 ctermfg=138 gui=NONE cterm=NONE
highlight PreCondit                 guifg=#af8787 ctermfg=138 gui=NONE cterm=NONE
highlight Keyword                   guifg=#af8787 ctermfg=138 cterm=NONE
highlight LineNr                    guifg=#4e4e4e ctermfg=239 ctermbg=234 guibg=#1c1c1c
highlight Number                    guifg=#FF8147 ctermfg=202
highlight PreProc                   guifg=#d7875f ctermfg=173
highlight Search                    guifg=NONE ctermfg=NONE guibg=#2b2b2b ctermbg=235 gui=italic cterm=underline
highlight Statement                 guifg=#af8787 ctermfg=138 gui=NONE cterm=NONE
highlight String                    guifg=#FF8147 ctermfg=202
highlight Title                     guifg=#FFFFFF ctermfg=15
highlight Type                      guifg=#d75f5f ctermfg=167 gui=NONE cterm=NONE
highlight Visual                    guibg=#5f5f87 ctermbg=60

highlight DiffAdd                   guifg=#E6E1DC ctermfg=7 guibg=#519F50 ctermbg=71
highlight DiffDelete                guifg=#E6E1DC ctermfg=7 guibg=#660000 ctermbg=52
highlight Special                   guifg=#d75f5f ctermfg=167 
highlight SpecialKey                guifg=#4e4e4e ctermfg=239 
highlight NonText                  guifg=#4e4e4e ctermfg=239 

highlight pythonBuiltin             guifg=#448AA9 ctermfg=31 gui=NONE cterm=NONE
highlight rubyBlockParameter        guifg=#FFFFFF ctermfg=15
highlight rubyClass                 guifg=#FFFFFF ctermfg=15
highlight rubyConstant              guifg=#d75f5f ctermfg=167
highlight rubyInstanceVariable      guifg=#D0D0FF ctermfg=189
highlight rubyInterpolation         guifg=#FF8147 ctermfg=202
highlight rubyLocalVariableOrMethod guifg=#D0D0FF ctermfg=189
highlight rubyPredefinedConstant    guifg=#d75f5f ctermfg=167
highlight rubyPseudoVariable        guifg=#af8787 ctermfg=221
highlight rubyStringDelimiter       guifg=#A5C261 ctermfg=143

highlight xmlTag                    guifg=#E8BF6A ctermfg=179
highlight xmlTagName                guifg=#E8BF6A ctermfg=179
highlight xmlEndTag                 guifg=#E8BF6A ctermfg=179

highlight mailSubject               guifg=#FF8147 ctermfg=202
highlight mailHeaderKey             guifg=#ffdf5f ctermfg=221
highlight mailEmail                 guifg=#FF8147 ctermfg=202 gui=italic cterm=underline

highlight SpellBad                  guifg=#d70000 ctermfg=160 ctermbg=NONE cterm=underline
highlight SpellRare                 guifg=#d75f87 ctermfg=168 guibg=NONE ctermbg=NONE gui=underline cterm=underline
highlight SpellCap                  guifg=#dfdfff ctermfg=189 guibg=NONE ctermbg=NONE gui=underline cterm=underline
highlight MatchParen                guifg=#FFFFFF ctermfg=15 guibg=#005f5f ctermbg=23
highlight Todo                      guifg=#d7875f guibg=#d7875f ctermbg=221 ctermfg=173

highlight ApacheDeclaration         guibg=#d75f5f ctermfg=167 
highlight apacheSection             guifg=#d7875f ctermfg=173
highlight NERDTreeDir               guifg=#448AA9 ctermfg=31
highlight NERDTreeUp                guifg=#448AA9 ctermfg=31
highlight shFunctionKey             guifg=#d7875f ctermfg=173
highlight phpClasses                guifg=#E3EDFF ctermfg=173
hi link shFunction                  vimSetEqual
