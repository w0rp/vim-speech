scriptencoding utf-8

function! vim_speech#statusline#GetStatus() abort
    if get(get(g:, 'vim_speech_info', {}), 'recording')
        return '◉ REC'
    endif

    return ''
endfunction
