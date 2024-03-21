" Runs all the syntax tests for which there is no "done/name" file.
"
" Current directory must be runtime/syntax.

" Only do this with the +eval feature
if 1

" Remember the directory where we started.  Will change to "testdir" below.
let syntaxDir = getcwd()

let s:messagesFname = fnameescape(syntaxDir .. '/testdir/messages')

let s:messages = []

" Add one message to the list of messages
func Message(msg)
  echomsg a:msg
  call add(s:messages, a:msg)
endfunc

" Report a fatal message and exit
func Fatal(msg)
  echoerr a:msg
  call AppendMessages(a:msg)
  qall!
endfunc

" Append s:messages to the messages file and make it empty.
func AppendMessages(header)
  exe 'split ' .. s:messagesFname
  call append(line('$'), '')
  call append(line('$'), a:header)
  call append(line('$'), s:messages)
  let s:messages = []
  wq
endfunc

" Relevant messages are written to the "messages" file.
" If the file already exists it is appended to.
exe 'split ' .. s:messagesFname
call append(line('$'), repeat('=-', 70))
call append(line('$'), '')
let s:test_run_message = 'Test run on ' .. strftime("%Y %b %d %H:%M:%S")
call append(line('$'), s:test_run_message)
wq

if syntaxDir !~ '[/\\]runtime[/\\]syntax\>'
  call Fatal('Current directory must be "runtime/syntax"')
endif
if !isdirectory('testdir')
  call Fatal('"testdir" directory not found')
endif

" Use the script for source code screendump testing.  It sources other scripts,
" therefore we must "cd" there.
cd ../../src/testdir
source screendump.vim
exe 'cd ' .. fnameescape(syntaxDir)

" For these tests we need to be able to run terminal Vim with 256 colors.  On
" MS-Windows the console only has 16 colors and the GUI can't run in a
" terminal.
if !CanRunVimInTerminal()
  call Fatal('Cannot make screendumps, aborting')
endif

cd testdir
if !isdirectory('done')
  call mkdir('done')
endif

" Obtain basic IPC support.
source ipc/dispatch.vim

set nocp
set nowrapscan
set report=9999
set modeline
set debug=throw
set nomore

au! SwapExists * call HandleSwapExists()
func HandleSwapExists()
  " Ignore finding a swap file for the test input, the user might be editing
  " it and that's OK.
  if expand('<afile>') =~ 'input[/\\].*\..*'
    let v:swapchoice = 'e'
  endif
endfunc

func RunTest()
  let ok_count = 0
  let failed_tests = []
  let skipped_count = 0
  let MAX_FAILED_COUNT = 5
  " Create a map of setup configuration filenames with their basenames as keys.
  let setup = glob('input/setup/*.vim', 1, 1)
    \ ->reduce({d, f -> extend(d, {fnamemodify(f, ':t:r'): f})}, {})

  for fname in glob('input/*.*', 1, 1)
    if fname =~ '\~$'
      " backup file, skip
      continue
    endif

    let root = fnamemodify(fname, ':t:r')
    let filetype = substitute(root, '\([^_.]*\)[_.].*', '\1', '')
    let failed_root = 'failed/' .. root

    " Execute the test if the "done" file does not exist or when the input file
    " is newer.
    let in_time = getftime(fname)
    let out_time = getftime('done/' .. root)
    if out_time < 0 || in_time > out_time
      call ch_log('running tests for: ' .. fname)

      for dumpname in glob(failed_root .. '_\d*\.dump', 1, 1)
	call delete(dumpname)
      endfor
      call delete('done/' .. root)

      let lines =<< trim END
	" extra info for shell variables
	func ShellInfo()
	  let msg = ''
	  for [key, val] in items(b:)
	    if key =~ '^is_'
	      let msg ..= key .. ': ' .. val .. ', '
	    endif
	  endfor
	  if msg != ''
	    echomsg msg
	  endif
	endfunc

	au! SwapExists * call HandleSwapExists()
	func HandleSwapExists()
	  " Ignore finding a swap file for the test input, the user might be
	  " editing it and that's OK.
	  if expand('<afile>') =~ 'input[/\\].*\..*'
	    let v:swapchoice = 'e'
	  endif
	endfunc

	func LoadFiletype(type)
	  for file in glob("ftplugin/" .. a:type .. "*.vim", 1, 1)
	    exe "source " .. file
	  endfor
	  redraw!
	endfunc

	func SetUpVim()
	  call cursor(1, 1)
	  " Defend against rogue VIM_TEST_SETUP commands.
	  for _ in range(20)
	    let lnum = search('\C\<VIM_TEST_SETUP\>', 'eW', 20)
	    if lnum < 1
	      break
	    endif
	    exe substitute(getline(lnum), '\C.*\<VIM_TEST_SETUP\>', '', '')
	  endfor
	  call cursor(1, 1)
	  " BEGIN [runtime/defaults.vim]
	  " Also, disable italic highlighting to avoid issues on some terminals.
	  set display=lastline ruler scrolloff=5 t_ZH= t_ZR=
	  syntax on
	  " END [runtime/defaults.vim]
	  redraw!
	endfunc

	func s:Stride(state, width) abort
	  let span = (1 + ((a:width > a:state.w)
	    \ ? (a:width - 1) / a:state.w
	    \ : 0))
	  let a:state.t += span
	  return a:state
	endfunc

	func SerialiseLineCount() abort
	  let state = getline(1, '$')
	    \ ->reduce({s, t -> s:Stride(s, strdisplaywidth(t))},
		\ {'w': winwidth(0), 't': 0})
	  call IPCWrite(state.t, 'Xipcpayload')
	endfunc
      END
      call writefile(extend(lines, IPCSupport()), 'Xtestscript')

      " close all but the last window
      while winnr('$') > 1
	close
      endwhile

      " Redraw to make sure that messages are cleared and there is enough space
      " for the terminal window.
      redraw

      " Let "Xtestscript#SetUpVim()" turn the syntax on.
      let prefix = '-Nu NONE -S Xtestscript'
      let path = get(setup, root, '')
      " Source the found setup configuration file.
      let args = !empty(path)
	\ ? prefix .. ' -S ' .. path
	\ : prefix
      let buf = RunVimInTerminal(args, {})
      " edit the file only after catching the SwapExists event
      call term_sendkeys(buf, ":edit " .. fname .. "\<CR>")
      " set up the testing environment
      call term_sendkeys(buf, ":call SetUpVim()\<CR>")
      " load filetype specific settings
      call term_sendkeys(buf, ":call LoadFiletype('" .. filetype .. "')\<CR>")
      call IPCFree('Xipcpayload')
      call term_sendkeys(buf, ":call SerialiseLineCount()\<CR>")

      if filetype == 'sh'
	call term_sendkeys(buf, ":call ShellInfo()\<CR>")
      endif

      " Screendump at the start of the file: failed/root_00.dump
      let root_00 = root .. '_00'
      call ch_log('First screendump for ' .. fname .. ': failed/' .. root_00 .. '.dump')
      let fail = VerifyScreenDump(buf, root_00, {})

      " Try for about (50 * 40) milliseconds before aborting.
      let linecount = get(IPCBusyRead('Xipcpayload', 40), 0, 0)

      " clear the shell info if there are not enough lines to cause a scroll
      if filetype == 'sh' && linecount <= 19
	call term_sendkeys(buf, ":redraw\<CR>")
      endif

      " Make a Screendump every 18 lines of the file: failed/root_NN.dump
      let topline = 1
      let nr = 1
      while linecount - topline > 20
	let topline += 18
	" With "g^", align the contents of &ruler for the current "gj" and
	" the succeeded "G".
	call term_sendkeys(buf, '18gjztg^')
	let root_next = root .. printf('_%02d', nr)
	call ch_log('Next screendump for ' .. fname .. ': failed/' .. root_next .. '.dump')
	let fail += VerifyScreenDump(buf, root_next, {})
	let nr += 1
      endwhile

      " Screendump at the end of the file: failed/root_99.dump
      call term_sendkeys(buf, 'Gzb')
      let root_last = root .. '_99'
      call ch_log('Last screendump for ' .. fname .. ': failed/' .. root_last .. '.dump')
      let fail += VerifyScreenDump(buf, root_last, {})

      call StopVimInTerminal(buf)
      call delete('Xtestscript')
      call IPCFree('Xipcpayload')

      " redraw here to avoid the following messages to get mixed up with screen
      " output.
      redraw

      " Add any assert errors to s:messages.
      if len(v:errors) > 0
	call extend(s:messages, v:errors)
	" Echo the errors here, in case the script aborts or the "messages" file
	" is not displayed later.
	echomsg v:errors
	let v:errors = []
	let fail += 1
      endif

      if fail == 0
	call Message("Test " .. root .. " OK")

	call writefile(['OK'], 'done/' .. root)

	let ok_count += 1
      else
	call Message("Test " .. root .. " FAILED")

	call delete('done/' .. root)

	eval failed_tests->add(root)
	if len(failed_tests) > MAX_FAILED_COUNT
	  call Message('')
	  call Message('Too many errors, aborting')
	endif
      endif
    else
      call Message("Test " .. root .. " skipped")
      let skipped_count += 1
    endif

    " Append messages to the file "testdir/messages"
    call AppendMessages('Input file ' .. fname .. ':')

    if len(failed_tests) > MAX_FAILED_COUNT
      break
    endif
  endfor

  call Message(s:test_run_message)
  call Message('OK: ' .. ok_count)
  call Message('FAILED: ' .. len(failed_tests) .. ': ' .. string(failed_tests))
  call Message('skipped: ' .. skipped_count)
  call AppendMessages('== SUMMARY ==')

  if len(failed_tests) > 0
    " have make report an error
    cquit
  endif
endfunc

call RunTest()

" Matching "if 1" at the start.
endif

qall!

" vim:ts=8
