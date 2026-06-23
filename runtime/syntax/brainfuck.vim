" Name: vim-brainfuck
" Author: veleth <llathasa@outlook.com>
" Version: 2.1.0+

syn keyword bf_todo TODO FIXME NOTE ToDo FixMe Note

" Match brackets
syn region bf_brackets_skip contained start=/\[/ end=/]/ transparent contains=bf_brackets_skip
syn region bf_brackets matchgroup=Conditional start=/\[/ end=/]/ transparent contains=TOP,bf_brackets_comment
syn region bf_brackets_comment matchgroup=Comment start=/^\%1l\s*\zs\[/ end=/]/ transparent contains=bf_brackets_skip,bf_todo

" Match plus and minus signs
syn match bf_byte /[+-]/

" Match IO operators
syn match bf_io /[.,]/

" Match data pointer increment/decrement operators
syn match bf_cell /[><]/

" Match comments
syn match bf_comment /!.*/ contains=bf_todo

" Highlight
hi def link bf_todo Todo
hi def link bf_byte Operator
hi def link bf_io String
hi def link bf_cell Delimiter
hi def link bf_comment Comment

let b:current_syntax = 'brainfuck'
