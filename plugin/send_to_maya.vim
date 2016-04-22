if exists("g:loaded_send_to_maya_plugin")
  finish
endif
let g:loaded_send_to_maya_plugin = 1


command! -nargs=* -range -bang SendToMaya <line1>,<line2>call send_to_maya#send('<bang>' == '!', '', 0, <q-args>)
command! -nargs=* -range -bang SendToMayaPy <line1>,<line2>call send_to_maya#send('<bang>' == '!', '', 1, <q-args>)
command! -nargs=* -range -bang SendToMayaMel <line1>,<line2>call send_to_maya#send('<bang>' == '!', '', 2, <q-args>)

let s:last_command = 'SendToMaya'


function! s:abs(v)
  return a:v >= 0 ? a:v : - a:v
endfunction


function! s:remember_visual(mode)
  let s:last_visual = [a:mode, s:abs(line("'>") - line("'<")), s:abs(col("'>") - col("'<"))]
endfunction


function! s:repeat_visual()

  let [mode, ldiff, cdiff] = s:last_visual
  let cmd = 'normal! '.mode
  if ldiff > 0
    let cmd .= ldiff . 'j'
  endif

  let ve_save = &virtualedit
  try
    if mode == "\<C-V>"
      if cdiff > 0
        let cmd .= cdiff . 'l'
      endif
      set virtualedit+=block
    endif
    execute cmd.":\<C-r>=g:send_to_maya_last_command\<Enter>\<Enter>"
    call s:set_repeat()

  finally
    if ve_save != &virtualedit
      let &virtualedit = ve_save
    endif
  endtry

endfunction


function! s:repeat_in_visual()

  if exists('g:send_to_maya_last_command')
    call s:remember_visual(visualmode())
    call s:repeat_visual()
  endif

endfunction


function! s:set_repeat()
  silent! call repeat#set("\<Plug>(SendToMayaRepeat)")
endfunction


function! s:send_to_maya_repeat()

  if exists('s:last_visual')
    call s:repeat_visual()

  else
    try
      let g:send_to_maya_need_repeat = 1
      normal! .
    finally
      unlet! g:send_to_maya_need_repeat
    endtry
  endif

endfunction


function! s:generic_send_to_maya_op(type, vmode, codetype)

  if !&modifiable
    if a:vmode
      normal! gv
    endif
    return
  endif

  let sel_save = &selection
  let &selection = "inclusive"

  if a:vmode
    let vmode = a:type
    let [l1, l2] = ["'<", "'>"]
    call s:remember_visual(vmode)
  else
    let vmode = ''
    let [l1, l2] = [line("'["), line("']")]
    unlet! s:last_visual
  endif

  try
    let range = l1.','.l2
    if get(g:, 'send_to_maya_need_repeat', 0)
      execute range . g:send_to_maya_last_command
    else
      execute range . "call send_to_maya#send('<bang>' == '!', vmode, '')"
    end
    call s:set_repeat()
  finally
    let &selection = sel_save
  endtry

endfunction


function! s:send_to_maya_op(type, ...)
  call s:generic_send_to_maya_op(a:type, a:0, a:1)
endfunction


nnoremap <silent> <Plug>(SendToMaya) :set opfunc=<SID>send_to_maya_op<Enter>g@
vnoremap <silent> <Plug>(SendToMaya) :<C-U>call <SID>send_to_maya_op(visualmode(), 1)<Enter>

nnoremap <silent> <Plug>(SendToMayaPy) :set opfunc=<SID>send_to_maya_op<Enter>g@
vnoremap <silent> <Plug>(SendToMayaPy) :<C-U>call <SID>send_to_maya_op(visualmode(), 1, 1)<Enter>

nnoremap <silent> <Plug>(SendToMayaMel) :set opfunc=<SID>send_to_maya_op<Enter>g@
vnoremap <silent> <Plug>(SendToMayaMel) :<C-U>call <SID>send_to_maya_op(visualmode(), 1, 2)<Enter>

" vim-repeat support
nnoremap <silent> <Plug>(SendToMayaRepeat) :call <SID>send_to_maya_repeat()<Enter>
vnoremap <silent> <Plug>(SendToMayaRepeat) :<C-U>call <SID>repeat_in_visual()<Enter>
