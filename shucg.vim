"Copyright (c) 2012, Yu Renbi
"All rights reserved.

"Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:

"Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
"Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.

"THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS 'AS IS' AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
python << EndPy
#!/usr/bin/python 
#coding=utf-8

import urllib,urllib2
from cookielib import CookieJar

try:
	from bs4 import BeautifulSoup
except ImportError:
	print "CANNOT IMPORT BeautifulSoup!"

try:
	import poster
except ImportError:
	print "CANNOT IMPORT poster!"

#======CONFIGURE YOUR ACCOUNT HERE!!======
USERNAME = "11121281"
PASSWORD = "Yu221250"
SITEURL = "http://program3.ccshu.net/"
SCOPE = "/home/averybigant/Documents/C_HKL"
#======SOME CONFIGURATION FOR CUSTOMIZE===
TRYTIMES = 5
SHOWTRY = True
DEBUG = False
#=========================================






def _looptry(times=TRYTIMES, printinfo=SHOWTRY):
	"""a decorator to let the function retry certain times(TRYTIMES) when failed for login or network problems."""
	def newdeco(fn):
		def fn_with_looptry(*args):
			i = 1
			while 1:
				if i != 1 and printinfo: 
					print "The %d try failed.Trying again." % (i - 1)
				try:
					result = fn(*args)
					#self._check_login(self._currentsoup)
					return result
				except urllib2.URLError:
					if i + 1 <= times:
						continue
					else:
						print "与CG网站连接时发生错误,已尝试了设定的%d次均失败" % times
						raise urllib2.URLError
				except LoginError,x:
					if i + 1 <= times:
						continue
					else:
						print "登录CG网站时发生错误 %s" % x
						raise LoginError
				finally:
					i += 1
					if i > times: break
		return fn_with_looptry
	return newdeco

class LoginError(Exception):
	def __init__(self, value=""):
		self.value = value
	def __str__(self):
		return repr(self.value)

class CG(object):
	def __init__(self, siteurl):
		self.LGINADDR = "login/loginproc.jsp"
		self.ASMADDR = "assignment/"
		self.TRYTIMES = TRYTIMES 
		self.SHOWTRY = SHOWTRY
		self.siteurl = siteurl

		self.ckj = CookieJar()
		self.u2opener = urllib2.build_opener(urllib2.HTTPCookieProcessor(self.ckj))
		self.Loginstatus = False
		self._coursetable = None
		self._currentsoup = None
		self._classselect = None
		self._chapterlist = None
		self._classlist = None
		self._chapterselected = None
		self.usr = None
		self.pwd = None


	def _check_login(self, soup, autorelogin=True):
		ltxt = soup.get_text()
		if len(ltxt) <= 10 or u"学号或者密码错误" in ltxt[0:500]:
			if autorelogin and self.Loginstatus: 
				self.login(self.usr, self.pwd)
			return False
		return True


	@_looptry()
	def login(self, usr, pwd):
		params = {'stid': usr, 'pwd': pwd}
		self.usr = usr
		self.pwd = pwd
		response = self.u2opener.open(self.siteurl + self.LGINADDR,
				urllib.urlencode(params)).read()
		self._currentsoup = soup = BeautifulSoup(response)
		self.Loginstatus = u"欢迎你" in soup.prettify() and u"注销" in soup.prettify()
		if u"学号或者密码错误" in soup.get_text()[0:500]: raise LoginError,"学号或者密码错误"
		return self.Loginstatus

	@_looptry()
	def get_class_list(self, runfull = False, class_select = 1):
		if self._classselect and (self._classlist and not runfull) and str(class_select) == self._classselect[0]: 
			return self._classlist

		self._currentsoup = soup =BeautifulSoup(self.u2opener.open(
			self.siteurl + self.ASMADDR, urllib.urlencode(
				{'doChangeCourse': 'true', 'changeCourse': str(class_select)})))
		if not self._check_login(soup): raise LoginError

		classlist = soup.find("select", {"name": "changeCourse"}).find_all("option")
		self._classlist = [(i['value'], i.string) for i in classlist]

		self._classselect = [(i['value'], i.string) for i in classlist if i.has_key('selected')][0]

		chapterlist = soup.find_all("td","menu1")
		chapterlist.reverse()
		self._chapterlist = []
		for i in range(1, len(chapterlist) + 1):
			thischapter = chapterlist[i - 1]
			self._chapterlist.append((i, thischapter.a.string, thischapter.a['href']))

		self._chapterselected = self._chapterlist[-1]

		return self._classlist

	def get_class_select(self):
		if not self._classselect: self.get_class_list(True)
		return self._classselect

	def get_chapter_list(self, class_select=1):
		if not self._classselect or not (self._chapterlist and
				self._classselect[0] == str(class_select)):
			self.get_class_list(True, class_select)
		return self._chapterlist
	
	def get_chapter_select(self, class_select=1):
		if not self._classselect or not (self._chapterselected and
				self._classselect[0] == str(class_select)):
			self.get_class_list(True, class_select)
		return self._chapterselected

	def print_class_list(self):
		clist = self.get_class_list()
		for tup in clist:
			flag = "_"
			if self.get_class_select() == tup:
				flag = "*"
			print flag, tup[0].ljust(2), tup[1]
			
	def print_chapter_list(self, cid=1):
		clist = self.get_chapter_list(cid)
		for tup in clist:
			print tup[0], tup[1]

		

class Chapter(object):
	def __init__(self, CGinstance, chapternum, classnum = 1):
		self.CG = CGinstance
		self.id, self.name, self.href = self.CG.get_chapter_list(classnum)[chapternum]
		self.href = self.CG.siteurl + self.CG.ASMADDR + self.href
		self._ASMlist = None
		self._info = None
		self._currentsoup = self.CG._currentsoup

	def _check_ASM_pass(self, tr):
		"""0 no upload 1 wrong upload 2 pass"""
		if u"还未提交源文件" in tr.find_all('td')[-1].get_text():
			return 0
		tabeltr = tr.table.find_all("tr")[1:]
		tds = [i.find_all('td')[-1].string for i in tabeltr]
		for i in tds:
			if not u"完全正确" in i: return 1
		return 2


	@_looptry()
	def get_ASM_list(self, runfull=False):
		if self._ASMlist and not runfull:
			return self._ASMlist
		soup = BeautifulSoup(self.CG.u2opener.open(self.href).read())
		if not self.CG._check_login(soup): raise LoginError
		self._currentsoup = soup

		trs = soup.find_all("tr", "formtext")
		self._ASMlist= []
		for tr in trs:
			self._ASMlist.append((tr.td.b.string[:-1], tr.a.string, self._check_ASM_pass(tr),tr.a['href']))

		self._info = soup.find("table","tableline").table.table.tr.td.string

		return self._ASMlist

	def get_info(self):
		if not self._info:
			self.get_ASM_list(True)
		return self._info

	def print_list(self):
		asmlist = self.get_ASM_list()
		print self.get_info()
		for tup in asmlist:
			if tup[2] == 0:
				stat = "未传"
			elif tup[2] == 1:
				stat = "做错"
			else:
				stat = "已过"
			print tup[0].rjust(2), stat, tup[1] 

class Assignment(object):
	def __init__(self, Chapterinstance, asmnum):
		self.chp = Chapterinstance
		self.id, self.name, self.status, self.href = self.chp.get_ASM_list()[asmnum]
		self.href = self.chp.CG.siteurl + self.chp.CG.ASMADDR + self.href
		self._uploadurl = None
		self._currentsoup = None
		self.fresh_soup()
		self._description = None
		self._lastuploadstat = None
	
	@_looptry()
	def fresh_soup(self):
		self._currentsoup = soup = BeautifulSoup(
				self.chp.CG.u2opener.open(self.href).read())
		if not self.chp.CG._check_login(soup): raise LoginError
		url = soup.find("form",target = "showmessage")['action']
		self._uploadurl = self.chp.CG.siteurl + self.chp.CG.ASMADDR + url

	def get_description(self):
		soup = self._currentsoup
		scriptTG = soup.find("script")
		infotr = scriptTG.find_parent("table").tr 
		self._description = infotr.get_text()
		return self._description

	def print_description(self):
		if self.status == 0:
			stat = "未传"
		elif self.status == 1:
			stat = "做错"
		else:
			stat = "已过"
		print stat
		if not self._description:
			self.get_description()
		print self._description

	@_looptry()
	def upload_source(self, filepath):
		pstopener = poster.streaminghttp.register_openers()
		pstopener.add_handler(urllib2.HTTPCookieProcessor(self.chp.CG.ckj))
		params = {'FILE1': open(filepath, 'r'), 'javaMainClass': ''}
		datagen, headers = poster.encode.multipart_encode(params)
		request = urllib2.Request(self._uploadurl, datagen, headers)
		soup = BeautifulSoup(urllib2.urlopen(request).read())
		if not self.chp.CG._check_login(soup): return LoginError
		self.chp.get_ASM_list(True)
		self.__init__(self.chp, int(self.id)-1)
		self._lastuploadstat = soup.find('td', height="100%").stripped_strings
		self._lastuploadstat = [text for text in self._lastuploadstat]
	
	def print_upstat(self):
		if not self._lastuploadstat:
			print "本次会话目前为止没有成功的上传"
		else:
			head = self._lastuploadstat[:3]
			content = self._lastuploadstat[3:]
			print self.name
			for l in head:
				print l
			for i in range(0,len(content) / 2):
				this = 2 * i 
				print "%s  %s" % (content[this],content[this + 1])



#=============SOME INPUT ASSIST FUNCTION=========================
#they all return a list to insert into vim.current.buffer

#def input_single_variable(varname,tip=None, outname = None):
	#if not outname:
		#outname = varname
	#if not tip:
		#tip = "Input %s: "
	#rlist = []
	#rlist.append('printf("



#================================================================	


def main():
	"""just some simple tests"""
	testtoggle = [1,1,1,1]
	spagetoggle= [0,0,0,0]
	flag = 0
	testfile = "/home/averybigant/Documents/CGinVIM/hehe_LTMP.c"
	#cg = CG(SITEURL)
	cg = CG(SITEURL)
	cg.login(USERNAME, PASSWORD)
	chp=Chapter(cg, 1)
	chp.print_list()
	if testtoggle[flag]:
		print "test login"
		print cg.login(USERNAME, PASSWORD)
		if spagetoggle[flag]: print cg._currentsoup
		print "LOGIN TEST DONE"
		flag += 1
	if testtoggle[flag]:
		print "test get_class_list"
		print cg.get_class_select()
		print cg.get_class_list()
		if spagetoggle[flag]: print cg._currentsoup
		print cg.get_chapter_list()
		print cg.get_chapter_select()
		cg.print_class_list()
		cg.print_chapter_list()
		print "TEST GET_CLASS_LIST DONE"
		flag+=1
	if testtoggle[flag]:
		print "test Chapter"
		chp = Chapter(cg, 7)
		print chp.get_ASM_list()
		if spagetoggle[flag]: print chp._currentsoup
		chp.print_list()
		print chp._info
		print "test Chapter finish"
		flag+=1
	if testtoggle[flag]:
		print "test Assignment"
		asm = Assignment(chp, 3)
		if spagetoggle[flag]: print asm._currentsoup
		asm.print_description()
		asm.print_upstat()
		asm.upload_source(testfile)
		asm.print_upstat()
		print "End test Assignment"
		flag+=1



if __name__ == "__main__" and DEBUG:
	main()
EndPy


"=====VIML_BEGIN=====


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
let @p = '0iprintf("�@7",);F,'
"printf with \n
let @o = '0iprintf("�@7\n",);F,'
"scanf
let @l = '0iscanf*�kb("�@7",);F,'

"command

command! -nargs=0 Chapter call Cgv_chapter()
command! -nargs=1 Setasm call Cgv_setasm(<args>)
command! -nargs=1 Setchapter call Cgv_setchapter(<args>)
command! -nargs=0 Addhead call Cgv_addhead()

map <f7> :call Cgv_showcurrent()<CR>
map <f8> :call Cgv_uploadcurrentfile()<CR>
