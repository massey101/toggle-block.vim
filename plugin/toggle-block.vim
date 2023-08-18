" Title:          Toggle Block
" Description:    This plugin toggles blocks between single and multi line.
" Last Change:    19 August 2023
" Maintainer:     Jack Massey <https://github.com/massey101>

if exists("g:loaded_toggle_block")
    finish
endif
let g:loaded_toggle_block = 1

command! ToggleBlock call toggleBlock#ToggleBlock()
" nnoremap tb :ToggleBlock<CR>
