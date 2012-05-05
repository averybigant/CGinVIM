#!/usr/bin/python 
#coding=utf-8

import urllib,urllib2
from cookielib import CookieJar
#import vim

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
#======SOME CONFIGURATION FOR CUSTOMIZE===
TRYTIMES = 2
SHOWTRY = True
#=========================================

#ASMPGADDR="assignment/programList.jsp?proNum=%d&courseID=%d&assignID=%d"


class LoginError(Exception):
	def __init__(self, value):
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

	def _looptry(times=TRYTIMES, printinfo=SHOWTRY):
		def newdeco(fn):
			def fn_with_looptry(*args):
				i = 1
				while 1:
					if i != 1 and printinfo: 
						print "The %d try failed.Trying again." % i
					try:
						result = fn(*args)
						#self._check_login(self._currentsoup)
						break
					except urllib2.URLError:
						if i + 1 < times:
							continue
						else:
							print "与CG网站连接时发生错误,已尝试了设定的%d次均失败" % times
					except LoginError,x:
						if i + 1 < times:
							continue
						else:
							print "登录CG网站时发生错误 %s" % x
					finally:
						i += 1
						if i > times: break
				return result
			return fn_with_looptry
		return newdeco

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
		if not self._chapterlist and self._classselect[0] == str(class_select):
			self.get_class_list(True, class_select)
		return self._chapterlist
	
	def get_chapter_select(self, class_select=1):
		if not self._chapterselected and self._classselect[0] == str(class_select):
			self.get_class_list(True, class_select)
		return self._chapterselected

	def print_class_list(self):
		clist = self.get_class_list
		for tup in clist:
			flag = " "
			if self.get_class_select() == tup:
				flag = "*"
			print flag, tup[0].ljust(2), tup[1]
			
	def print_chapter_list(self):
		clist = self.get_chapter_list()
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

	def __check_ASM_pass(tr):
		"""0 no upload 1 wrong upload 2 pass"""
		if u"还未提交源文件" in tr.find_all('td')[-1].get_text():
			return 0
		tabeltr = tr.tabel.find_all("tr")[1:]
		tds = [i.find_all('td')[-1].string for i in tabeltr]
		for i in tds:
			if not u"完全正确" in i: return 1
		return 2


	CG._looptry()
	def get_ASM_list(self, runfull=False):
		if self._ASMlist and not runfull:
			return self._ASMlist
		soup = BeautifulSoup(self.CG.u2opener.open(self.href).read())
		if not self.CG._check_login(response): raise LoginError
		self._currentsoup = soup

		trs = soup.find_all("tr", "formtext")
		self._ASMlist= []
		for tr in trs:
			self._ASMlist.append((tr.td.b.string[:-1], tr.a.string, __check_ASM_pass(tr),tr.a['href']))

		self._info = soup.find("table","tableline").table.table.tr.td.string

		return self._ASMlist

	def get_info(self):
		if not self._info:
			self.get_ASM_list(True)
		return self._info

	def print_list(self):
		asmlist = self.get_ASM_list()
		for tup in asmlist:
			if tup[2] == 0:
				stat = "未过"
			elif tup[2] == 1:
				stat = "做错"
			else:
				stat = "已过"
			print tup[0].rjust(2), stat, tup[1] 



		


	
	


def main():
	testtoggle = [1,1,1]
	spagetoggle= [0,0,0]
	flag = 0
	#cg = CG(SITEURL)
	global cg
	cg = CG(SITEURL)
	if testtoggle[flag]:
		print "test login"
		print cg.login(USERNAME, PASSWORD)
		if spagetoggle[flag]: print cg._currentsoup
		print "LOGIN TEST DONE"
		flag += 1
	if testtoggle[flag]:
		print "test get_class_list"
		print cg.get_class_list()
		if spagetoggle[flag]: print cg._currentsoup
		print cg.get_class_select()
		print cg.get_chapter_list()
		print cg.get_chapter_select()
		print "TEST GET_CLASS_LIST DONE"
		flag+=1
	if testtoggle[flag]:
		print "test Chapter"
		chp = Chapter(cg, 7)
		chp.print_list()
		if spagetoggle[flag]: print chp._currentsoup
		print chp._info
		print "test Chapter finish"


if __name__ == "__main__":
	main()
