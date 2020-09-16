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


function! s:do_send(code, language)

python3 << EOF
import vim
import socket
import os
import tempfile
import textwrap
import re


# filst step: make tmp file for execute
code = vim.eval("a:code")
code = "# coding=utf-8\n" + code
fd, tmp_path = tempfile.mkstemp()
with open(tmp_path, 'w', encoding="utf-8") as f:
    f.write(code)

# second step: generate command to execute in maya
code_type = vim.eval("b:language")
if code_type == "python":
    command = textwrap.dedent('''
        import __main__
        import os
        import maya.OpenMaya as om

        temp = os.path.abspath(r"{0}")
        code_type = "{1}"

        with open(temp, "r") as f:
            exec(f, __main__.__dict__, __main__.__dict__)
        os.remove(temp)
    '''.format(tmp_path, code_type))
    command = command.replace("\\", "/").replace('"', r'\"').replace("\n", "\\n")
    command = 'python("{}")'.format(command)

elif code_type == "mel":
    command = textwrap.dedent('''source "{0}";sysFile -delete "{0}"'''.format(tmp_path))
    command = command.replace("\\", "/").encode("unicode_escape")

try:
    # sencond step: connet to maya
    host = vim.eval("s:get_target_host()")
    port = int(vim.eval("s:get_target_port()"))

    sk = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
    sk.connect((host, port))

    # third step: execute command file
    sk.send(command.encode())

    # forth step: error handling
    mes = sk.recv(4096)
    print("receive: {0}".format(mes))

except Exception:
    import traceback
    traceback.print_exc()
    print("send to maya failed")

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


function! s:detect_codetype()

if &filetype == "python"
return "python"
  elseif &filetype == "mel"
  return "mel"

  " ---------------------------------------------------------------------------
  " determine by shebang
  if get(g:, 'send_to_maya_prefer_language') && g:send_to_maya_prefer_language == 'mel'
  let match_shebang_py = matchstr(getline(1), '^#!\(.*py.*\)')
  if !empty(match_shebang_py)
      return "python"
    else
      return "mel"
    endif

  elseif get(g:, 'send_to_maya_prefer_language') && g:send_to_maya_prefer_language == 'python'
    let match_shebang_mel = matchstr(getline(1), '^#!\(.*mel.*\)')
    if !empty(match_shebang_mel)
      return "mel"
    else
      return "python"
    endif

  else
    let match_shebang_mel = matchstr(getline(1), '.*mel.*')
    if !empty(match_shebang_mel)
      return "mel"
    endif
    let match_shebang_py = matchstr(getline(1), '^#!\(.*py.*\)')
    if !empty(match_shebang_py)
      return "python"
    endif
  endif

  " ---------------------------------------------------------------------------
  "  determine by semicolon(;) at eof
  let l:semicolon_count = 0.0
  let l:total_line_count = 0.0
  for i in range(1, line('$'))
    if !empty(matchstr(getline(i), ';$'))
      let l:semicolon_count += 1.0 
    endif
    if match(getline(i), '^ *$')
      let l:total_line_count += 1.0
    endif
  endfor

  if ( semicolon_count / total_line_count ) > 0.5
    return "mel"
  endif

  " ---------------------------------------------------------------------------
  " default
  return "python"

endfunction


function! send_to_maya#send(bang, visualmode, codetype, expr) range

  if a:codetype == 0
    let b:language = s:detect_codetype()

  elseif a:codetype == 1
    let b:language = "python"

  else
    let b:language = "mel"
  endif

  try
    if a:visualmode == "v" || a:visualmode == "V"
      let code = s:get_visual_selection()
    else
      let code = s:get_buffer_contents()
    endif

    call s:do_send(code, b:language)
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
