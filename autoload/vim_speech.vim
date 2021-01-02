"Author: w0rp <devw0rp@gmail.com>
"Description: The main file for implementing Vim speech-to-text control.

if !exists('s:job_id')
    let s:job_id = 0
endif

if !exists('s:buffer_to_write_to')
    let s:buffer_to_write_to = 0
endif

if !exists('g:vim_speech_info')
    let g:vim_speech_info = {
    \ 'recording': 0,
    \}
endif

function! s:HandleExit(job_id, exit_code) abort
    " If the job is the current one, clear the ID so we start again.
    if a:job_id is s:job_id
        let s:job_id = 0
    endif
endfunction

function! s:HandleSpeech(speech) abort
    if empty(a:speech)
        " Do nothing when we get nothing back.
        return
    endif

    if s:buffer_to_write_to is bufnr('')
        " Get the cursor's position and the text for the line.
        let l:pos = getcurpos()
        let l:line = getline(l:pos[1])

        let l:before = l:line[: l:pos[2]]
        let l:after = l:line[l:pos[2] :]
        let l:inserted = a:speech

        " Add a space before the words, if we need to.
        if !empty(l:before) && l:before !~? ' $'
            let l:inserted = ' ' . l:inserted
        endif

        " Add a space after the words, if we need to.
        if !empty(l:after) && l:after !~? '^ '
            let l:inserted = l:inserted . ' '
        endif

        let l:line = l:before . l:inserted . l:after
        let l:pos[2] += len(l:inserted)

        " Update the line and the cursor's position.
        call setline(l:pos[1], l:line)
        call setpos('.', l:pos)
    endif
endfunction

" Handle lines from the speech to text client.
function! s:HandleResponseLine(job_id, line) abort
    let l:match = matchlist(a:line, '\v^(speech) (.*)$')

    if empty(l:match)
        return
    endif

    let l:command = l:match[1]
    let l:value = l:match[2]

    if l:command =~? '^speech$'
        call s:HandleSpeech(l:value)
    endif
endfunction

function! s:HandleErrorLine(job_id, line) abort
endfunction

function! s:StartJobIfNeeded(buffer) abort
    if s:job_id > 0
        return
    endif

    if empty($GOOGLE_APPLICATION_CREDENTIALS) && empty($DEEPSPEECH_MODEL)
        throw 'Neither GOOGLE_APPLICATION_CREDENTIALS nor DEEPSPEECH_MODEL is set'
    endif

    let l:command = ale#Escape(g:vim_speech_dir . '/venv/bin/python')
    \   . ' ' . ale#Escape(g:vim_speech_dir . '/speech_to_text_client.py')
    let l:job_options = {
    \   'mode': 'nl',
    \   'exit_cb': function('s:HandleExit'),
    \   'out_cb': function('s:HandleResponseLine'),
    \   'err_cb': function('s:HandleErrorLine'),
    \}

    let l:command = ale#job#PrepareCommand(a:buffer, l:command)
    let s:job_id = ale#job#Start(l:command, l:job_options)
endfunction

function! vim_speech#StartRecording() abort
    let l:buffer = bufnr('')

    call s:StartJobIfNeeded(l:buffer)

    if s:job_id > 0
        call ale#job#SendRaw(s:job_id, "record\n")
        let g:vim_speech_info.recording = 1
    else
        throw 'Failed to start speech client!'
    endif
endfunction

function! vim_speech#StopRecording() abort
    let l:buffer = bufnr('')

    if s:job_id > 0
        call ale#job#SendRaw(s:job_id, "stop\n")
        let s:buffer_to_write_to = l:buffer
        let g:vim_speech_info.recording = 0
    endif
endfunction

" Toggle recording on and off, for easier keybinds.
function! vim_speech#ToggleRecording() abort
    if get(g:vim_speech_info, 'recording', 0)
        call vim_speech#StopRecording()
    else
        call vim_speech#StartRecording()
    endif
endfunction

function! vim_speech#Quit() abort
    if s:job_id > 0
        " Send a command to shutdown safely.
        call ale#job#SendRaw(s:job_id, "quit\n")
        " Assume the job will close later and forget the ID now.
        let s:job_id = 0
    endif
endfunction
