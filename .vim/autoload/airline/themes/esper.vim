" Airline theme for the Esper colorschemes in .vim/colors.
"
" It holds no colors of its own: each Esper colorscheme defines the EsperMode*
" and EsperStatus* highlight groups, and this reads them. Airline calls
" refresh() again whenever the colorscheme changes, so the status line follows.

let g:airline#themes#esper#palette = {}

function! airline#themes#esper#refresh() abort
  let l:b = airline#themes#get_highlight('EsperStatusB')
  let l:c = airline#themes#get_highlight('EsperStatusC')
  let l:inactive = airline#themes#get_highlight('EsperStatusInactive')
  let l:palette = g:airline#themes#esper#palette

  for [l:mode, l:group] in [
        \ ['normal', 'EsperModeNormal'],
        \ ['insert', 'EsperModeInsert'],
        \ ['visual', 'EsperModeVisual'],
        \ ['replace', 'EsperModeReplace'],
        \ ]
    let l:palette[l:mode] = airline#themes#generate_color_map(
          \ airline#themes#get_highlight(l:group), l:b, l:c)
  endfor
  let l:palette.inactive = airline#themes#generate_color_map(l:inactive, l:inactive, l:inactive)
endfunction

call airline#themes#esper#refresh()
