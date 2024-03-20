" An XTerm-capable IPC.

if !has('terminal')
  finish
endif

let s:cpoptions = &cpoptions
set cpoptions-=C

func IPCSupport() abort
  let lines =<< trim END
    let s:ipc_state = {'t_ts': &t_ts, 't_fs': &t_fs, 'titlestring': &titlestring}

    func IPCReset() abort
      exe printf('set t_ts=%s t_fs=%s titlestring=%s',
	\ s:ipc_state.t_ts,
	\ s:ipc_state.t_fs,
	\ s:ipc_state.titlestring)
      redraw!
    endfu

    func IPCWrite(message, _) abort
      " See ":help terminal_api" and OSC in a documentation for XTerm:
      " https://invisible-island.net/xterm/ctlseqs/ctlseqs.txt
      exe "set t_ts=\033]51; t_fs=\007"
      let &titlestring = js_encode(["call", "Tapi_Read", js_encode(a:message)])
      redraw!
    endfu
  END

  return lines
endfunc

func IPCBusyRead(_, turns) abort
  let turns = a:turns < 5 ? 5 : a:turns

  while !exists('s:ipc_payload')
    sleep 50m

    if turns < 2
      return []
    endif

    let turns -= 1
  endwhile

  return type(s:ipc_payload) == type([])
    \ ? copy(s:ipc_payload)
    \ : [copy(s:ipc_payload)]
endfunc

func IPCFree(_) abort
  unlet! s:ipc_payload
endfunc

" Accept payload from an XTerm family terminal.
func Tapi_Read(writer, payload) abort
  unlet! s:ipc_payload
  let s:ipc_payload = js_decode(a:payload)
  call term_sendkeys(a:writer, ":call IPCReset()\<CR>")
endfunc

let &cpoptions = s:cpoptions
unlet s:cpoptions

" vim:ts=8
