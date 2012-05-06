if !has('python')
	echo "ERROR: Require vim compiled with +python"
	finish
endif


"initialize
python << endpy
import vim
print "hello~welcome to use CGinVIM~"
cg = CG(SITEURL)
crt_chp = None
crt_asm = None
cg.login(USERNAME, PASSWORD)
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
