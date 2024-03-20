" A plain file IPC.

if !has('terminal')
  finish
endif

func IPCSupport() abort
  let lines =<< trim END
    func IPCWrite(message, fname) abort
      call writefile([a:message], a:fname, 's')
      redraw!
    endfu
  END

  return lines
endfunc

func IPCBusyRead(fname, turns) abort
  let turns = a:turns < 5 ? 5 : a:turns

  while !filereadable(a:fname)
    sleep 50m

    if turns < 2
      return []
    endif

    let turns -= 1
  endwhile

  return readfile(a:fname)
endfunc

func IPCFree(fname) abort
  call delete(a:fname)
endfunc

" vim:ts=8
