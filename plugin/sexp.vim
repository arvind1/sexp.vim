
"    .o            o8o                                                              o.
"   .8'            '"'                                                              `8.
"  .8' oooo    ooooooo ooo. .oo.  .oo.        .oooo.o .ooooo. oooo    ooooo.ooooo.   `8.
"  88   `88.  .8' `888 `888P"Y88bP"Y88b      d88(  "8d88' `88b `88b..8P'  888' `88b   88
"  88    `88..8'   888  888   888   888 8888 `"Y88b. 888ooo888   Y888'    888   888   88
"  `8.    `888'    888  888   888   888      o.  )88b888    .o .o8"'88b   888   888  .8'
"   `8.    `8'    o888oo888o o888o o888o     8""888P'`Y8bod8P'o88'   888o 888bod8P' .8'
"    `"                                                                   888       "'
"                                                                        o888o
" Author:   guns <self@sungpae.com>
" Version:  0.1
" License:  MIT
" Homepage: https://github.com/guns/vim-sexp

if exists('g:loaded_vim_sexp')
    finish
endif
let g:loaded_vim_sexp = 1

let s:bracket = '\v[\(\)\[\]\{\}]'
let s:opening_bracket = '\v[\(\[\{]'
let s:closing_bracket = '\v[\)\]\}]'
let s:pairs = [['\V(','\V)'], ['\V[','\V]'], ['\V{','\V}']]

function! s:current_char()
    return getline('.')[col('.')-1]
endfunction

function! s:previous_char()
    return getline('.')[col('.')-2]
endfunction

function! s:syntax_name(line, col)
    return synIDattr(synID(a:line, a:col, 0), 'name')
endfunction

function! s:is_ignored_scope(line, col)
    return s:syntax_name(a:line, a:col) =~? '\vstring|comment|char'
endfunction

" Position of nearest bracket: 0 for opening, 1 for closing.
function! s:nearest_bracket(closing)
    let [_b, cline, ccol, _o] = getpos('.')
    let closest = []
    let flags = a:closing ? 'n' : 'bn'
    let stopline = a:closing ? line('$') : 1

    for [start, end] in s:pairs
        let [line, col] = searchpairpos(start, '', end, flags,
            \ 's:is_ignored_scope(line("."), col("."))',
            \ stopline)
        if !line | continue | endif

        if empty(closest) || ((abs(line - cline) <= abs(closest[1] - cline)) &&
                           \  (abs(col - ccol) < abs(closest[2] - ccol)))
            let closest = [_b, line, col, _o]
        endif
    endfor

    return empty(closest) ? [_b, 0, 0, _o] : closest
endfunction

" Tries to move cursor to nearest bracket; same arguments as s:nearest_bracket
function! s:move_to_bracket(closing)
    let pos = s:nearest_bracket(a:closing)
    if pos[1] | call setpos('.', pos) | endif
endfunction

function! s:pos_with_col_offset(pos, offset)
    let [b, l, c, o] = a:pos
    return [b, l, c + a:offset, o]
endfunction

function! s:visual_bracket(offset)
    let vmode = visualmode()
    execute "normal! \<C-\\>\<C-n>"

    if s:current_char() =~ s:opening_bracket || s:previous_char() =~ s:opening_bracket
        " Native text objects expand when repeating inner motions too
        if s:current_char() !~ s:opening_bracket | execute 'normal! h' | endif

        " If we're already in visual mode, we want to expand the selection
        if vmode =~? '\v^v'
            call s:move_to_bracket(1)
            call s:move_to_bracket(1)
            call setpos("'<", s:pos_with_col_offset(s:nearest_bracket(0), a:offset))
            call setpos("'>", s:pos_with_col_offset(getpos('.'), -a:offset))
        else
            call setpos("'<", s:pos_with_col_offset(getpos('.'), a:offset))
            call setpos("'>", s:pos_with_col_offset(s:nearest_bracket(1), -a:offset))
        endif
    elseif s:current_char() =~ s:closing_bracket
        call setpos("'<", s:pos_with_col_offset(s:nearest_bracket(0), a:offset))
        call setpos("'>", s:pos_with_col_offset(getpos('.'), -a:offset))
    else
        let pos = s:nearest_bracket(1)
        if pos[1]
            call setpos("'<", s:pos_with_col_offset(s:nearest_bracket(0), a:offset))
            call setpos("'>", s:pos_with_col_offset(pos, -a:offset))
        endif
    endif

    normal! gv
endfunction

vnoremap af :<C-u>call <SID>visual_bracket(0)<CR>
vnoremap if :<C-u>call <SID>visual_bracket(1)<CR>
