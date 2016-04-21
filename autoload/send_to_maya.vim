if exists("g:loaded_send_to_maya")
  finish
endif
let g:loaded_send_to_maya = 1

let s:cpo_save = &cpo
set cpo&vim


function! s:get_target_host()
  return get(g:, 'send_to_maya_host') ? g:send_to_maya_host : 'localhost' 
endfunction


function! s:get_target_port()
  return get(g:, 'send_to_maya_port') ? g:send_to_maya_port : '20160'
endfunction


function! s:echon_(tokens)
  " http://vim.wikia.com/wiki/How_to_print_full_screen_width_messages
  let xy = [&ruler, &showcmd]
  try
    set noruler noshowcmd

    let winlen = winwidth(winnr()) - 2
    let len = len(join(map(copy(a:tokens), 'v:val[1]'), ''))
    let ellipsis = len > winlen ? '..' : ''

    echon "\r"
    let yet = 0
    for [hl, msg] in a:tokens
      if empty(msg) | continue | endif
      execute "echohl ". hl
      let yet += len(msg)
      if yet > winlen - len(ellipsis)
        echon msg[ 0 : (winlen - len(ellipsis) - yet - 1) ] . ellipsis
        break
      else
        echon msg
      endif
    endfor
  finally
    echohl None
    let [&ruler, &showcmd] = xy
  endtry
endfunction


function! s:echon()
  let tokens = [
  \ ['Function', ':SendToMaya'],
  \ ['None', ' ']]

  call s:echon_(tokens)
  return join(map(tokens, 'v:val[1]'), '')
endfunction


function! s:do_send(code)

python << EOF
import vim
import socket
import os
import tempfile
import textwrap
import re

try:

    # filst step: make tmp file for execute
    code = unicode(vim.eval("a:code"), 'utf-8')
    temp = tempfile.mkstemp()
    with os.fdopen(temp[0], 'w') as f:
        f.write(code)

    # TODO: determine code_type
    if "mel" not in vim.current.buffer[0]:
        code_type = "python"
    else:
        code_type = "mel"

    # second step: generate command to execute in maya
    command = textwrap.dedent('''
    import __main__
    import os
    import maya.OpenMaya as om

    temp = os.path.abspath(r"{0}")
    code_type = "{1}"
    with open(temp, "r") as f:
        if code_type == "python":
            exec(f, __main__.__dict__, __main__.__dict__)

        elif code_type == "mel":
           mel_cmd = 'source "%s"' % temp
           om.MGlobal.executeCommand(mel_cmd, True, True)
    os.remove(temp)
    '''.format(temp[1], code_type))

    command = command.replace("\\", "/").encode('string_escape').replace('"', r'\"')

    # sencond step: connet to maya
    host = vim.eval("s:get_target_host()")
    port = int(vim.eval("s:get_target_port()"))

    sk = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
    sk.connect((host, port))

    # third step: execute command file
    sk.send('python("{}")'.format(command))

except Exception as e:
    print "vim to maya fail: {}".format(e)
finally:
    sk.close()
EOF
endfunction


function! s:get_visual_selection()
  let [lnum1, col1] = getpos("'<")[1:2]
  let [lnum2, col2] = getpos("'>")[1:2]
  let lines = getline(lnum1, lnum2)
  let lines[-1] = lines[-1][: col2 - (&selection == 'inclusive' ? 1 : 2)]
  let lines[0] = lines[0][col1 - 1:]
  return join(lines, "\n")
endfunction


function! s:get_buffer_contents()
  return join(getline(1,'$'), "\n")
endfunction


function! send_to_maya#send(bang, visualmode, expr) range

  try
    if a:visualmode == "v" || a:visualmode == "V"
      let code = s:get_visual_selection()
    else
      let code = s:get_buffer_contents()
    endif
    call s:do_send(code)
    let g:send_to_maya_last_command = s:echon()


  catch /^\%(Vim:Interrupt\|exit\)$/
    if empty(a:visualmode)
      echon "\r"
      echon "\r"
    else
      normal! gv
    endif
    
  endtry

endfunction


let &cpo = s:cpo_save
unlet s:cpo_save
