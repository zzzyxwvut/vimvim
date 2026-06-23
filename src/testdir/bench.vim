vim9script

# Usage: BENCH_FILE=/path/to/sample BENCH_OUT=/tmp/bench.log BENCH_MODE=off ../vim --clean -S bench.vim
syntax on

if getenv('BENCH_MODE') == 'off'
  test_override('syn_prefilter', 1)   # disable the prefilter => baseline
endif

def Sweep(): float
  synID(1, 1, 1)
  var last = line('$')
  var start = reltime()
  for lnum in range(1, last)
    var lc = col([lnum, '$'])
    var c = 1
    while c < lc
      synID(lnum, c, 1)
      c += 1
    endwhile
  endfor
  return reltimefloat(reltime(start))
enddef

for _ in range(20)
  execute 'edit ' .. $BENCH_FILE
  syntax sync fromstart
  writefile([printf('%3s %.4f', $BENCH_MODE, Sweep())], $BENCH_OUT, 'a')
  new
  only
  execute 'bwipeout #'
  sleep 1m
endfor

qa!
