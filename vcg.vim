let s:scope = 0

python << endpy
import vim
crt_dir = vim.eval('system("pwd")')
crt_dir = crt_dir.strip()
SCOPE = SCOPE.strip()
if crt_dir:
	if SCOPE == crt_dir: vim.command("let s:scope = 1")
#vim.command("let s:scope = 1")
endpy
if !s:scope
	finish
endif

if !has('python')
	echo "ERROR: Require vim compiled with +python"
	finish
endif

"initialize
python << endpy
print "CGinVIM author:averybigant@gmail.com"
print "copyright:Simplified BSD License"
cg = CG(SITEURL)
crt_chp = None
crt_asm = None
if cg.login(USERNAME, PASSWORD): print "Login successful!"
endpy

function! Cgv_showclass()
python << endpy
cg.print_class_list()
endpy
endfunction

function! Cgv_setclass(id)
python << endpy
crt_cid = int(vim.eval("a:id"))
cg.print_chapter_list(crt_cid)
endpy
endfunction

function! Cgv_setchapter(chpid)
python << endpy
chpid = int(vim.eval("a:chpid"))
if not crt_cid:
	print "please use Cgv_setclass(id) set your class first."
	vim.command('return 1')	
classid = crt_cid
#classid -= 1
chpid -= 1
crt_chp = Chapter(cg, chpid, classid)
crt_chp.print_list()
endpy
endfunction

function! Cgv_setasm(asmid)
python << endpy 
if not crt_chp:
	print "please use Cgv_setchapter(chpid) set chapter first."
	vim.command('return 1')	
asmid = int(vim.eval("a:asmid")) - 1
crt_asm = Assignment(crt_chp, asmid)
crt_asm.print_description()
endpy 
endfunction

function! Cgv_showcurrent()
python << endpy 
if not crt_asm:
	print "please use Cgv_setasm(asmid) set assignment first!"
	vim.command('return 1')	
crt_asm.print_description()
endpy 
endfunction

function! Cgv_uploadcurrentfile()
python << endpy 
if not crt_asm:
	print "please use Cgv_setasm(asmid) set assignment first!"
	vim.command('return 1')	
crt_file = vim.eval("expand('%:p')")
crt_asm.upload_source(crt_file)
crt_asm.print_upstat()
endpy 
endfunction

function! Cgv_chapter()
python << endpy 
crt_cid = 1
crt_chp = Chapter(cg, int(cg.get_chapter_select()[0])-1)
crt_chp.print_list()
endpy 
endfunction

function! Cgv_showstat()
python << endpy 
if not crt_asm:
	print "please use Cgv_setasm(asmid) set assignment first!"
	vim.command('return 1')	
crt_asm.print_upstat()
endpy 
endfunction

function! Cgv_addhead()
python << endpy 
if not crt_asm:
	print "please use Cgv_setasm(asmid) set assignment first!"
	vim.command('return 1')	
#reverse
vim.current.buffer.append('//' + '=' * 42, 0)
vim.current.buffer.append('//Time:%s' % vim.eval('system("date")'), 0)
vim.current.buffer.append('//Author:%s' % cg.usr, 0)
vim.current.buffer.append('//Title:%s' % crt_asm.name.encode('utf-8'), 0)
#vim.current.window.cursor = (4, 0)
endpy 
endfunction

"some macros
"printf
let @p = '0iprintf("€@7",);F,'
"printf with \n
let @o = '0iprintf("€@7\n",);F,'
"scanf
let @l = '0iscanf*€kb("€@7",);F,'

"command

command! -nargs=0 Chapter call Cgv_chapter()
command! -nargs=1 Setasm call Cgv_setasm(<args>)
command! -nargs=1 Setchapter call Cgv_setchapter(<args>)
command! -nargs=0 Addhead call Cgv_addhead()

map <f7> :call Cgv_showcurrent()<CR>
map <f8> :call Cgv_uploadcurrentfile()<CR>
