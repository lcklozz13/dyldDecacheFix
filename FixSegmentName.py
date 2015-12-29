#!/usr/bin/env python
from macholib import MachO
from macholib import mach_o
import macholib.ptypes
import os
import sys
#https://github.com/opensource-apple/cctools/blob/fdb4825f303fd5c0751be524babd32958181b3ed/libstuff/ofile.c Line 3629
sectForAppend=list()#A List of {sect.offset,sect.size,lcsize}
commandSizeForAppend=list()
def main(exePath):
	print 'dyld_shared_cache decache Fix'
	print
	print 'During the production of this script,no Mach-O was killed'
	print
	print 'Designed by Naville Zhang'
	rawFile = open(exePath, 'r')
	rawFile.seek(-4, 2)
	#if cmp(rawFile.read(),'BOOM') == 0:
	#	print '#Error: Executable has been patched'
	#	exit()
	macho=MachO.MachO(exePath)
	for header in macho.headers:
		IterateLCInHeader(header)
		FixMachO(header)
		replaceDATA(header)
	print '[+]Generating new executable'
	spliceHeadersAndRawStuff(header,exePath)
	print '[+]New executable generated'

	print '[+]Overwriting raw executable'
	os.system('mv %s_tmp %s' % (exePath, exePath))

	print '[+]Giving execute permission to new executable'
	givex(exePath)
	print
	print '[+]All done.'
	return

def givex(str):
    os.system('chmod +x %s' % str)
    return

def spliceHeadersAndRawStuff(header, name):
    outputexecutable = open('%s_tmp' % name,'wb')
    header.write(outputexecutable)
    
    rawStuff = open('%s_tmp' % name, 'rb')
    
    offset = header.headers[len(header.headers)-1].low_offset
    
    rawStuff.seek(offset)
    outputexecutable.write(rawStuff.read())
    outputexecutable.write('BOOM')
    
    outputexecutable.close()
    rawStuff.close()
    
    return
def FixMachO(Header):
	for i in range(0,len(Header.commands)):
		LC,cmd, data = Header.commands[i]

		isSC=type(cmd) == mach_o.segment_command or type(cmd) == mach_o.segment_command_64
		if(isSC):
			if(str(cmd.segname).replace("\0", "")=="__DATA"):
				print "Found",cmd.segname
				DATALCSize=0
				if(LC.cmd==1):#load_command:1
					print "Old __DATA LOAD COMMAND SIZE:",LC.cmdsize
					for x in sectForAppend:
						LC.cmdsize=LC.cmdsize+x[2]
						cmd.vmsize=cmd.vmsize+x[1]
						cmd.filesize=cmd.filesize+x[1]
						cmd.nsects=cmd.nsects+1
					print "New __DATA LOAD COMMAND SIZE:",LC.cmdsize
					print "New __DATA LOAD File&VM SIZE:",cmd.vmsize
					print "New __DATA Number of Sections:",cmd.nsects
				#print "Original Number Of Sections:",cmd.nsects
				#print "Original CMDSize:",cmd.cmdsize

				else:
					print "Not __DATA Skip",cmd.segname

def IterateLCInHeader(Header):
	for i in range(0,len(Header.commands)):
		LC,cmd, data = Header.commands[i]
		if(type(cmd) == mach_o.segment_command or type(cmd) == mach_o.segment_command_64):
			if("__DATA" in str(cmd.segname).replace("\0", "")):
				for seg in data:
					print "Collecting Info For:",seg.segname,"/",seg.sectname
					dict={"SectName":seg.sectname,"SegName":seg.segname,""}
		

		else:
			print "Not __DATA Segment Command"



if __name__ == '__main__':
    if len(sys.argv) != 2:
        print 'Usage: python',sys.argv[0],'[executable path]'
        exit()
    
    if not os.path.exists(sys.argv[1]):
        print '#Error: File does not exist'
        exit()

    main(sys.argv[1])
    exit()
