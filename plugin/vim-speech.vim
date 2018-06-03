"Author: w0rp <devw0rp@gmail.com>
"Description: A plugin for implementing Vim speech-to-text control.

if exists('g:loaded_vim_speech')
    finish
endif

let g:loaded_vim_speech = 1

let g:vim_speech_dir = fnamemodify(resolve(expand('<sfile>:p')), ':h')

command! -bar SpeechRecord :call vim_speech#StartRecording()
command! -bar SpeechStop :call vim_speech#StopRecording()
command! -bar SpeechQuit :call vim_speech#Quit()

" <Plug> mappings for commands
nnoremap <silent> <Plug>(vim_speech_record) :SpeechRecord<Return>
nnoremap <silent> <Plug>(vim_speech_stop) :SpeechStop<Return>
nnoremap <silent> <Plug>(vim_speech_quit) :SpeechQuit<Return>
