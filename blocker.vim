" Blocker is used to toggle blocks between multiline and single line mode.
" Outstanding issues
"   * Unable to handle edge case where block is followed by a single character
"   on the same line as the close parenthesis
"   * Replaces the x register
if exists('g:loaded_blocker')
    finish
endif
let g:loaded_blocker = 1

" Parens
let s:parens = {
            \ '(': ')',
            \ '{': '}',
            \ '[': ']'
            \ }
let s:parensClose = {
            \ ')': '(',
            \ '}': '{',
            \ ']': '['
            \ }
let s:parensStack = []
function! s:parensInit()
    let s:parensStack = []
endfunction
function! s:parensIsOpen(char)
    return has_key(s:parens, a:char)
endfunction
function! s:parensIsClose(char)
    return has_key(s:parensClose, a:char)
endfunction
function! s:parensAdd(char)
    if ! s:parensIsOpen(a:char) && ! s:parensIsClose(a:char)
        echo "Invalid character"
        return
    endif
    call add(s:parensStack, a:char)
endfunction
function! s:parensPop(char)
    if s:parensIsOpen(s:parensStack[-1])
        let l:checkParens = s:parensClose
    elseif s:parensIsClose(s:parensStack[-1])
        let l:checkParens = s:parens
    else
        echo "Invalid character"
        return 0
    endif
    if s:parensStack[-1] == l:checkParens[a:char]
        let s:parensStack = s:parensStack[:-2]
        return 1
    endif
    return 0
endfunction


" Cursor
function! s:getChar(cursor)
    return getline(a:cursor[0])[a:cursor[1]-1]
endfunction

function! s:curBack(cur)
    let l:line = a:cur[0]
    let l:col = a:cur[1] - 1

    if l:col == 0
        let l:line = l:line - 1
        let l:col = strlen(getline(l:line))
    endif
    return [l:line, l:col]
endfunction

function! s:replaceVisualSelection(selection)
    let [l:line_start, l:column_start] = getpos("'<")[1:2]
    let [l:line_end, l:column_end] = getpos("'>")[1:2]
    let l:line_length = strlen(getline(l:line_end))

    normal d
    let @x = a:selection
    " Put the text before the cursor by default. But if we are at the start
    " or the end of the line then we want to put the text after the cursor.
    if l:column_end == l:line_length || l:column_start == 0
        normal "xp
    else
        normal "xP
    endif
endfunction


" From stack overflow
" https://stackoverflow.com/a/6271254
function! s:get_visual_selection()
    " Why is this not a built-in Vim script function?!
    let [line_start, column_start] = getpos("'<")[1:2]
    let [line_end, column_end] = getpos("'>")[1:2]
    let lines = getline(line_start, line_end)
    if len(lines) == 0
        return ''
    endif
    let lines[-1] = lines[-1][: column_end - (&selection == 'inclusive' ? 1 : 2)]
    let lines[0] = lines[0][column_start - 1:]
    return join(lines, "\n")
endfunction

" Blocker
function! s:blockerGetBlockType(start)
    if a:start[1] == col("$") - 1
        return 0
    endif
    return 1
endfunction

function! s:blockerGetBlockTypeOld(start)
    normal %
    if line(".") == a:start[0]
        if col(".") == a:start[1]
            return -1
        endif
        normal %
        return 0
    endif
    normal %
    return 1
endfunction

" Starting from the current cursor position move backwards pushing the
" close parenthesis we find onto the stack and popping them off with an open
" parenthesis. We assume we are inside a parenthesis block and so we finish
" when the stack goes negative.
function! s:blockerSearchBackwards(start)
    let l:cursor = a:start
    call s:parensInit()
    " If we start on a close parenthesis move one back so we start inside the
    " block.
    let l:character = s:getChar(l:cursor)
    if s:parensIsClose(l:character)
        let l:cursor = s:curBack(l:cursor)
    endif

    let l:i = 0
    while l:i < 10000
        let l:i = l:i + 1
        let l:character = s:getChar(l:cursor)
        if s:parensIsOpen(l:character)
            if len(s:parensStack) == 0
                return l:cursor
            else
                call s:parensPop(l:character)
            endif
        elseif s:parensIsClose(l:character)
            call s:parensAdd(l:character)
        endif

        let l:cursor = s:curBack(l:cursor)
    endwhile
    return [0, -1]
endfunction

let s:whitespace = {
            \ " ": 1,
            \ "\t": 1,
            \ "\n": 1
            \}

function! s:removeChar(string, index)
    return a:string[:a:index-1] .. a:string[a:index+1:]
endfunction

function! s:blockerContract(start)
    call cursor(a:start[0], a:start[1])
    " Probably a better way of doing this but get_visual_selection only seems
    " to work once we have exited visual mode.
    normal v%
    execute "normal! \<Esc>"
    let l:selection = s:get_visual_selection()
    let l:cursor = 0
    call s:parensInit()
    let l:mode = "Search"
    let l:i = 0
    while l:i < 10000
        let l:i = l:i + 1

        let l:character = l:selection[l:cursor]
        if l:mode == "Remove Whitespace"
            if has_key(s:whitespace, l:character)
                let l:selection = s:removeChar(l:selection, l:cursor)
                continue
            else
                let l:mode = "Search"
            endif
        endif
        if s:parensIsClose(l:character)
            if len(s:parensStack) == 1
                break
            else
                call s:parensPop(l:character)
            endif
        elseif s:parensIsOpen(l:character)
            call s:parensAdd(l:character)
            if len(s:parensStack) == 1
                let l:mode = "Remove Whitespace"
            endif
        endif
        if len(s:parensStack) == 1
            if l:character == ","
                let l:mode = "Remove Whitespace"
                " Add a whitespace and then skip it to ensure there is
                " whitespace after a comma
                let l:selection = l:selection[:l:cursor] .. " " .. l:selection[l:cursor+1:]
                let l:cursor = l:cursor + 1
            endif
        endif

        let l:cursor = l:cursor + 1
    endwhile
    let l:cursor = l:cursor - 1
    let l:i = 0
    while 1
        if l:i > 10000
            break
        endif
        let l:i = l:i + 1

        let l:character = l:selection[l:cursor]
        if has_key(s:whitespace, l:character) || l:character == ","
            let l:selection = s:removeChar(l:selection, l:cursor)
        else
            break
        endif
        let l:cursor = l:cursor - 1
    endwhile
    normal v%
    call s:replaceVisualSelection(l:selection)
    normal =%
    call cursor(a:start[0], a:start[1])
endfunction

function! s:blockerExpand(start)
    call cursor(a:start[0], a:start[1])
    normal v%
    execute "normal! \<Esc>"
    let l:selection = s:get_visual_selection()
    let l:cursor = 0
    call s:parensInit()
    let l:i = 0
    while l:i < 10000
        let l:i = l:i + 1

        let l:character = l:selection[l:cursor]
        if s:parensIsClose(l:character)
            if len(s:parensStack) == 1
                let l:selection = l:selection[:l:cursor-1] .. ",\n" .. l:selection[l:cursor:]
                let l:cursor = l:cursor + 2
                break
            else
                call s:parensPop(l:character)
            endif
        elseif s:parensIsOpen(l:character)
            call s:parensAdd(l:character)
            if len(s:parensStack) == 1
                let l:selection = l:selection[:l:cursor] .. "\n" .. l:selection[l:cursor+1:]
                let l:cursor = l:cursor + 1
            endif
        endif
        if len(s:parensStack) == 1
            if l:character == ","
                let l:mode = "Add Whitespace"
                let l:selection = l:selection[:l:cursor] .. "\n" .. l:selection[l:cursor+1:]
                let l:cursor = l:cursor + 1
            endif
        endif

        let l:cursor = l:cursor + 1
    endwhile
    normal v%
    call s:replaceVisualSelection(l:selection)
    normal =%
    call cursor(a:start[0], a:start[1])
endfunction

function! s:blocker() abort
    let l:curpos = [line("."), col(".")]
    let l:start = s:blockerSearchBackwards(l:curpos)
    if l:start[1] == -1
        echo "Invalid Block. Abort"
        return
    endif
    call cursor(l:start[0], l:start[1])
    let l:blocktype = s:blockerGetBlockType(l:start)
    if l:blocktype == 1
        call s:blockerExpand(l:start)
    else
        call s:blockerContract(l:start)
    endif
endfunction

command! Blocker call <SID>blocker()
nnoremap tb :Blocker<CR>
