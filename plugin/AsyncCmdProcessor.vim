" github.com/johannst/AsyncCmdProcessor.vim.git -- plugins/AsyncCmdProcessor.vim
" author: johannst

if v:version<800
	echom 'AsyncCmdProcessor plugin needs at least vim 8.0'
	finish
endif

if exists('s:plugin_loaded')
	finish
endif
let s:plugin_loaded = 1

" job_start was not working without CB
function! s:StdOutCB(job, message)
endfunction

" job_start was not working without CB
function! s:StdErrCB(job, message)
endfunction

let s:gAsyncJobReturnStatus='*'
function! s:JobExitCB(job, status)
   "execute 'cbuffer! ' . g:stderr_buffer
   "execute 'caddbuffer ' . s:async_buffer
   echom 'AsyncCmdProcessor: Job exited'
   let s:gAsyncJobReturnStatus = a:status
   let s:gAsyncJobRunning=0
endfunction

let s:gAsyncJobRunning=0
let s:gAsyncBuffer=0
function! s:GetAsyncBuffer()
	return s:gAsyncBuffer
endfunction
function! s:AsyncCmdProcessor(...)
   if a:0 == 0
      echom 'AsyncCmdProcessor: no cmd specified'
      return
   endif

   if s:gAsyncJobRunning == 1
      echom 'AsyncCmdProcessor: currently only one job at a time supported'
      return
   endif
   let s:gAsyncJobReturnStatus='*'
   let s:gAsyncJobRunning=1

   let l:current_buffer = bufnr('%')
   let s:gAsyncBuffer = s:CreateLogBuffer('async_buffer')
   execute 'b ' . l:current_buffer

   " concatenate command string
   let l:cmd = ''
   for arg in a:000
      let l:cmd = l:cmd. ' ' . arg
   endfor
   echom l:cmd

   let s:gAsyncJob = job_start(l:cmd, {
            \ 'out_io': 'buffer',
            \ 'out_buf': s:gAsyncBuffer,
            \ 'out_cb': function('s:StdOutCB'),
            \ 'out_msg': '0',
            \ 'err_io': 'buffer',
            \ 'err_buf': s:gAsyncBuffer,
            \ 'err_cb': function('s:StdErrCB'),
            \ 'err_msg': '0',
            \ 'exit_cb': function('s:JobExitCB')
            \})
endfunction

" Exported function: Returns status of last executed cmd
function! GetAsyncJobStatus()
   if exists('s:gAsyncJob')
      return job_status(s:gAsyncJob) . ':' . s:gAsyncJobReturnStatus
   endif
   return '*:*'
endfunction

function! s:KillAsyncJob()
   if exists('s:gAsyncJob')
      let l:dudel = job_stop(s:gAsyncJob)
      execute 'sleep 200ms'
      if job_status(s:gAsyncJob) !=? 'dead'
         echom 'Failed to kill AsyncJob'
      endif
   endif
endfunction

let s:fname_filters = [ '\m\(.\{-}\):\%(\(\d\+\)\%(:\(\d\+\):\)\?\)\?' ]
" matches current line(from beginning indep of cursor position) against fname_filters
" the first file name found from beginning of line is opened in window evaluated by 'wincmd w'
function! s:OpenFirstFileNameMatch()
   " TODO: experimenting <cWORD>
   let l:line = getline('.')

   let l:file_info = []
   let l:file_info =  matchlist(line, s:fname_filters[0])

   if !empty(l:file_info)
      for path in split(&path, ',')    " take first match from path
         if ( empty(path) && !empty(glob(l:file_info[1])) ) || !empty(glob(path . '/' . l:file_info[1]))
            let l:fname = l:file_info[1]
            let l:lnum  = l:file_info[2] == ''? '1' : l:file_info[2]
            let l:cnum  = l:file_info[3] == ''? '1' : l:file_info[3]
            execute 'wincmd w'
            execute 'open ' . l:fname
            call cursor(l:lnum, l:cnum)
            execute 'wincmd p'
            break
         endif
      endfor
   endif
endfunction

function! s:CreateLogBuffer(buffer_name)
   let l:buffer_num = bufnr(a:buffer_name, 1)
   execute 'b ' . l:buffer_num
   execute '%d'
   execute 'setlocal buflisted'
   execute 'setlocal buftype=nofile'
   execute 'setlocal noswapfile'
   execute 'setlocal wrap'
   nnoremap <buffer> <CR> :call <SID>OpenFirstFileNameMatch()<CR>
   " go line by line in wrapped lines
   nnoremap <buffer> j gj
   nnoremap <buffer> k gk
   return l:buffer_num
endfunction

command! -complete=file -nargs=* Async call s:AsyncCmdProcessor(<f-args>)
" Space after :Async explicitly wanted ;)
nnoremap <leader>a :Async 
nnoremap <leader>ab :execute ':buffer ' . <SID>GetAsyncBuffer()<CR>
nnoremap <leader>ak :call <SID>KillAsyncJob()<CR>

"% vim:fen:fdm=marker:fmr={{{,}}}:fdl=0:fdc=1
