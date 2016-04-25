
Send to maya Vim Plugin
=======================

Vim plugin for Autodesk Maya script development.

About
-----

execute 
* current buffer
* current selection

in Maya

Installation
------------

sendtomaya.vim follows the standard runtime path structure. thus I recommend to use one of these package managers.


*  [Pathogen](https://github.com/tpope/vim-pathogen)
  * `git clone https://github.com/yamahigashi/sendtomaya.vim.git ~/.vim/bundle/sendtomaya.vim`
*  [vim-plug](https://github.com/junegunn/vim-plug)
  * `Plug 'yamahigashi/sendtomaya.vim'`
*  [NeoBundle](https://github.com/Shougo/neobundle.vim)
  * `NeoBundle 'yamahigashi/sendtomaya.vim'`
*  [Vundle](https://github.com/gmarik/vundle)
  * `Plugin 'yamahigashi/sendtomaya.vim'`


Setting
-------

You can set the command port variable.

```vim
"""""""""""""""""""""""""""""""""""""""""""
" Send To Maya
"""""""""""""""""""""""""""""""""""""""""""
"  command port
let g:send_to_maya_host="localhost"
let g:send_to_maya_port=12345

" language detection(optional)
let g:send_to_maya_prefer_language = 'python'
" or
let g:send_to_maya_prefer_language = 'mel'

"""""""""""""""""""""""""""""""""""""""""""
" key mapping
"  auto detect
vmap mayaa <Plug>(SendToMaya)
nmap <silent><Leader>mayaa :SendToMaya<CR>

" specify lang
vmap mayap <Plug>(SendToMayaPy)
nmap <silent><Leader>mayap :SendToMayaPy<CR>
vmap mayam <Plug>(SendToMayaMel)
nmap <silent><Leader>mayam :SendToMayaMel<CR>
```

---
## License

[MIT License](http://en.wikipedia.org/wiki/MIT_License)
