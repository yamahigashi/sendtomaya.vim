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

* command port
```vim:.vimrc
g:send_to_maya_host="localhost"
g:send_to_maya_port=12345
```

* key mapping
```vim
vmap maya <Plug>(SendToMaya)
nmap <silent><Leader>maya :SendToMaya<CR>
```

---
## License

[MIT License](http://en.wikipedia.org/wiki/MIT_License)
