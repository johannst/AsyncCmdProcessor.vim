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

if !exists('g:gACP_buffer_name')
	let g:gACP_buffer_name = 'async_buffer'
endif

let s:gAsyncJob = {
\  'BufferName' : g:gACP_buffer_name,
\  'BufferNumber' : -1,
\  'IsRunning'  : 0,
\  'ReturnValue' : '*',
\  'JobHandle' : '',
\}

" job_start was not working without CB
function! s:StdOutCB(job, message)
endfunction

" job_start was not working without CB
function! s:StdErrCB(job, message)
endfunction

function! s:JobExitCB(job, status)
   echom 'AsyncCmdProcessor: Job exited'
   let s:gAsyncJob.ReturnValue = a:status
   let s:gAsyncJob.IsRunning=0
endfunction

function! s:AsyncCmdProcessor(...)
   if a:0 == 0
      echom 'AsyncCmdProcessor: no cmd specified'
      return
   endif

   if s:gAsyncJob.IsRunning == 1
      echom 'AsyncCmdProcessor: currently only one job at a time supported'
      return
   endif
   let s:gAsyncJob.ReturnValue='*'
   let s:gAsyncJob.IsRunning=1

   let l:current_buffer = bufnr('%')
   let s:gAsyncJob.BufferNumber = s:CreateLogBuffer(s:gAsyncJob.BufferName)
   execute 'b ' . l:current_buffer

   " concatenate command string
   let l:cmd = ''
   for arg in a:000
      let l:cmd = l:cmd. ' ' . arg
   endfor
   echom l:cmd

   let s:gAsyncJob.JobHandle = job_start(l:cmd, {
            \ 'out_io': 'buffer',
            \ 'out_buf': s:gAsyncJob.BufferNumber,
            \ 'out_cb': function('s:StdOutCB'),
            \ 'out_msg': '0',
            \ 'err_io': 'buffer',
            \ 'err_buf': s:gAsyncJob.BufferNumber,
            \ 'err_cb': function('s:StdErrCB'),
            \ 'err_msg': '0',
            \ 'exit_cb': function('s:JobExitCB')
            \})
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

function! s:GetAsyncBuffer()
	if s:gAsyncJob.BufferNumber==-1
		echom 'AsyncCmdProcessor: Async buffer not created, since no async job run until now!'
		return bufnr('%') " stay in current buffer
	endif
	return s:gAsyncJob.BufferNumber
endfunction

function! s:KillAsyncJob()
   if s:gAsyncJob.JobHandle!=''
      let l:dudel = job_stop(s:gAsyncJob.JobHandle)
      execute 'sleep 200ms'
      if job_status(s:gAsyncJob.JobHandle) !=? 'dead'
         echom 'Failed to kill AsyncJob'
      endif
   endif
endfunction

" Exported function: Returns status of last executed cmd
function! GetAsyncJobStatus()
   if s:gAsyncJob.JobHandle!=''
      return job_status(s:gAsyncJob.JobHandle) . ':' . s:gAsyncJob.ReturnValue
   endif
   return '*:*'
endfunction

command! -complete=file -nargs=* Async call s:AsyncCmdProcessor(<f-args>)
" Space after :Async explicitly wanted ;)
nnoremap <leader>a :Async 
nnoremap <leader>ab :execute ':buffer ' . <SID>GetAsyncBuffer()<CR>
nnoremap <leader>ak :call <SID>KillAsyncJob()<CR>

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

"% vim:fen:fdm=marker:fmr={{{,}}}:fdl=0:fdc=1
