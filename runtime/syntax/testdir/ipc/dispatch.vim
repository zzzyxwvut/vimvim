if !has('terminal') || strridx(getcwd(), '/testdir') < 0
  finish
endif

let s:cpoptions = &cpoptions
set cpoptions-=C

if !exists('s:xtermable')

" Accept payload from an XTerm family terminal.
func Tapi_Read(writer, payload) abort
  let payload = js_decode(a:payload)
  unlet! s:ipc_payload
  let s:ipc_payload = type(payload) == type('') && payload == 'ping'
    \ ? 'pong'
    \ : payload
  call term_sendkeys(a:writer, ":call IPCReset()\<CR>")
endfunc

" Send a 'ping' message to another Vim instance in a terminal window.
func s:TryXTermIPC() abort
  let lines =<< trim END
    let s:ipc_state = {'t_ts': &t_ts, 't_fs': &t_fs, 'titlestring': &titlestring}

    func IPCReset() abort
      exe printf('set t_ts=%s t_fs=%s titlestring=%s',
	\ s:ipc_state.t_ts,
	\ s:ipc_state.t_fs,
	\ s:ipc_state.titlestring)
      redraw!
    endfu

    func IPCWrite(message) abort
      " See ":help terminal_api" and OSC in a documentation for XTerm:
      " https://invisible-island.net/xterm/ctlseqs/ctlseqs.txt
      exe "set t_ts=\033]51; t_fs=\007"
      let &titlestring = js_encode(["call", "Tapi_Read", js_encode(a:message)])
      redraw!
    endfu
  END

  call writefile(lines, 'Xipcsupport')

  " With term_util.vim#RunVimInTerminal(), 'hidden' and 'norestore' are ignored.
  let buffer = term_start('vim -f --clean -v -Nu NONE -S Xipcsupport',
    \ {'term_name': '[IPC_TEST]', 'hidden': 1, 'norestore': 1})

  try
    unlet! s:ipc_payload
    call term_sendkeys(buffer, ":call IPCWrite('ping')\<CR>")
    sleep 500m
  finally
    exe buffer .. 'bwipe!'
  endtry

  let s:xtermable = exists('s:ipc_payload') &&
    \ type(s:ipc_payload) == type('') &&
    \ s:ipc_payload == 'pong'
  lockvar s:xtermable
  let dirs = split(&directory, ',')

  " Optionally, collect information about XTerm-capable IPC in
  " testdir/VIM_IPC_INFO, or whatever &directory[0] is.
  if !empty(dirs) && filewritable(dirs[0] .. '/VIM_IPC_INFO') == 1
    let info = printf('%s: %sXTerm capable', &term, (s:xtermable ? "" : "Not "))
    call writefile([info], dirs[0] .. '/VIM_IPC_INFO', 'a')
  endif
endfunc

try
  call s:TryXTermIPC()
finally
  call delete('Xipcsupport')
  unlet! s:ipc_payload
  delfunction Tapi_Read
  delfunction s:TryXTermIPC
endtry

endif

if s:xtermable
  source ipc/xterm.vim
else
  source ipc/file.vim
endif

let &cpoptions = s:cpoptions
unlet s:cpoptions

" vim:ts=8
