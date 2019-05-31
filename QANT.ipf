//#pragma rtGlobals=3		// Use modern global access method and strict wave access.

#include "elementlibrary"
#include <Multi-peak fitting 2.0>
Menu "QANT v1.12"
	"Advanced Options", /Q, Execute/P/Q "Init_QANT_AdvPanel()"
	help={"Advanced NEXAFS Analysis options"}
	"about", /Q, Execute/P/Q "QANT_About_QANT()"
	help={"About QANT"}
End
function /s QANT_NEXAFSfileEXt_AUmainasc() // MDA
	return ".asc"
end
function /s QANT_LoadNEXAFSfile_AUmainasc(pathn)
	string pathn
	make /free /T tempdata, extrapvs
	grep /INDX /z=2 /E="^#[\\s]*([[:digit:]]+)\\s+[^\]]*\][\\s]*([^,\\s]{1,})?" pathn as Tempdata
	grep /INDX /z=2 /E="^#[\\s]*Extra PV [[:digit:]]+:\\s+([^,\\s]{1,})\\s*,\\s*([^,]*)\\s*,\\s*\"?([^\"]*)\"?\\s*,?\\s*([^\\s]*)?" pathn as extrapvs

	if(! (strlen(s_filename)>0) )
		print "nothing loaded"
		return ""
	endif
	string fullpath = s_filename
	
	string completedpnts, triedpnts
	grep/Q/LIST/E="Points completed =" fullpath
	splitstring /e="# Points completed = ([1234567890]*) of ([1234567890]*);" s_value, completedpnts, triedpnts
	if(str2num(completedpnts)<5 || strlen(completedpnts)==0)
		print "Aborted Scan Detected"
		return ""
	endif
	
	string scantime
	grep/Q/LIST/E="# Scan time = " fullpath
	splitstring /e="# Scan time = (.*)" s_value, scantime
	string scanname = ParseFilePath(3, fullpath, ":", 1, 0)
	string foldersave = getdatafolder(1)
	string year, month, day,hour,minute,second
	splitstring /e="^([::alpha::]{3,4}) ([::digit::]{1,2}), ([::digit::]{4}) ([::digit::]{1,2}):([::digit::]{2}):([::digit::.]*)" scantime, month, day, year, hour, minute, second
	print year
	print month
	print day
	print hour
	print minute
	print second
	//sscanf instring, "\"%4d%*[-]%2d%*[-]%2d%*[ ] %2d%*[:] %2d%*[:]%2d\"", year, month, day,hour,minute,second
 
	//return  date2secs(year, month, day ) + hour*3600+minute*60 +second
	setdatafolder root:
	newdatafolder /O/S NEXAFS

	wave /T QANT_LUT
	newdatafolder /O/S Scans
	newdatafolder /O/S $cleanupname(scanname,1)

	killwaves /Z/A
	string /g filename = fullpath
	string /g acqtime = scantime
	getfilefolderinfo /p=NEXAFSPath /q/z scanname+".asc"
	string /g filesize
	sprintf filesize, "%d" ,v_logEOF
	string /g cdate
	sprintf cdate, "%d" ,v_creationdate
	string /g mdate
	sprintf mdate, "%d" ,v_modificationdate
	
	string /g notes
	if(strlen(notes)*0!=0)
		notes = ""
	endif
	string /g SampleName
	if(strlen(SampleName)*0!=0)
		SampleName = ""
	endif
	string /g SampleSet
	if(strlen(SampleSet)*0!=0)
		SampleSet = ""
	endif
	string /g refscan
	if(strlen(refscan)*0!=0)
		refscan = "Default"
	endif
	string /g darkscan
	if(strlen(darkscan)*0!=0)
		darkscan = "Default"
	endif
	string /g enoffset
	if(strlen(enoffset)*0!=0)
		enoffset = "Default"
	endif
	
	if(dimsize(extrapvs,0)>0)
		make /o/t/n=(dimsize(extrapvs,0),4) extrainfo
		variable k
		string pvname, realname, value, units
		for(k=0;k<dimsize(extrapvs,0);k+=1)
			splitstring /e="^#[\\s]*Extra PV [[:digit:]]+:\\s+([^,\\s]{1,})\\s*,\\s*([^,]*)\\s*,\\s*\"?([^\"]*)\"?\\s*,?\\s*([^\\s]*)?" extrapvs[k], pvname, realname, value, units
			extrainfo[k][0] = pvname
			extrainfo[k][1] = realname
			extrainfo[k][2] = value
			extrainfo[k][3] = units
		endfor
		variable xloc=nan, yloc=nan, zloc=nan, r1loc=nan, r2loc=nan
		findvalue /text="SR14ID01MCS02FAM:X.RBV" extrainfo
		if(v_value >=0)
			xloc=str2num(extrainfo[v_value][2])
		endif
		findvalue /text="SR14ID01MCS02FAM:Y.RBV" extrainfo
		if(v_value >=0)
			yloc=str2num(extrainfo[v_value][2])
		endif
		findvalue /text="SR14ID01MCS02FAM:Z.RBV" extrainfo
		if(v_value >=0)
			zloc=str2num(extrainfo[v_value][2])
		endif
		findvalue /text="SR14ID01MCS02FAM:R1.RBV" extrainfo
		if(v_value >=0)
			R1loc=str2num(extrainfo[v_value][2])
		endif
		findvalue /text="SR14ID01MCS02FAM:R2.RBV" extrainfo
		if(v_value >=0)
			R2loc=str2num(extrainfo[v_value][2])
		endif
		if(xloc*yloc*zloc*r1loc*r2loc*0==0)
			notes = "( X="+num2str(xloc)+", Y="+num2str(yloc)+", Z="+num2str(zloc)+", R1="+num2str(r1loc)+", R2="+num2str(r2loc)+")"
		endif
	endif
	
	variable j
	string columnnumber, nametouse
	string columnname
	make /o/n=(dimsize(tempdata,0)) /T Columnnames
	string columnstring=""
	for(j=0;j<dimsize(tempdata,0);j+=1)
		splitstring /e="^#[\\s]*([[:digit:]]+)\\s+[^\]]*\][\\s]*([^,\\s]{1,})?" tempdata[j], columnnumber, columnname
		FindValue /TEXT=columnname /TXOP=3 QANT_LUT
		if(v_value>=0)
			nametouse = QANT_LUT[v_value][1]
			if(checkname(nametouse,1)==0)
				columnnames[str2num(columnnumber)-1] = nametouse
				make /n=0 $nametouse
			else				
				columnnames[str2num(columnnumber)-1] = uniquename(cleanupname(nametouse,1),1,0)
				make /n=0 $uniquename(cleanupname(nametouse,1),1,0)
			endif
		else
			nametouse = columnname
			if(checkname(cleanupname(nametouse,1),1)==0)
				columnnames[str2num(columnnumber)-1] = cleanupname(nametouse,1)
				make /n=0 $cleanupname(nametouse,1)
			else				
				columnnames[str2num(columnnumber)-1] = uniquename(cleanupname(nametouse,1),1,0)
				make /n=0 $uniquename(cleanupname(nametouse,1),1,0)
			endif
		endif
		columnstring +="C=1,F=0,N='"+columnnames[str2num(columnnumber)-1]+"';"
	endfor
	grep /INDX /Q /E="# 1-D Scan Values" fullpath

	wave w_index
	LoadWave/Q/O/B=columnstring/D/A/J/L={0,w_index[0]+3,0,0,dimsize(tempdata,0)} fullpath
	setdatafolder foldersave
	print "Loaded NEXAFS file : " + cleanupname(scanname,1)
	return 	cleanupname(scanname,1)
end

function QANT_listNEXAFSscans()
	string foldersave = getdatafolder(1)
	setdatafolder root:NEXAFS:scans
	string datafolderlist = datafolderdir(1)
	datafolderlist = stringbykey("FOLDERS",datafolderlist,":",";")
	variable num = itemsinlist(datafolderlist,",")
	datafolderlist = sortlist(datafolderlist,",",16)
	variable j, k
	string curfolder
	svar loadedfilelist = root:NEXAFS:oldfilelist
	svar badfilelist = root:NEXAFS:badfilelist
	if(!svar_exists(badfilelist))
		string /g root:NEXAFS:badfilelist
		svar badfilelist = root:NEXAFS:badfilelist
	endif
	string newloadedfilelist =  ""
	setdatafolder root:NEXAFS:
	make/o /n=(num,11) /t scanlistfull, scanlist
	scanlist = scanlistfull
	make /o /n=(num) enabled
	make /o/n=(num,3) colorcolwave
	make /o/n=(num) selwavescanlistfull
	duplicate /o selwavescanlistfull, selwavescanlist

	
	setdatafolder root:NEXAFS:scans:
	for(j=0;j<num;j+=1)
		curfolder = stringfromlist(j,datafolderlist,",")
		setdatafolder $curfolder
		scanlist[j][0] = curfolder
		svar notes
		if(!svar_exists(notes))
			string /g notes = curfolder
		endif
		svar SampleName
		if(!svar_exists(SampleName))
			string /g SampleName = cleanupname(notes,0)
		endif
		svar Otherstr
		if(!svar_exists(Otherstr))
			string /g Otherstr = ""
		endif
		svar SampleSet
		if(!svar_exists(SampleSet))
			string /g SampleSet = ""
		endif
		svar Anglestr
		if(!svar_exists(Anglestr))
			string /g Anglestr =""
		endif
		svar refscan
		if(!svar_exists(refscan) || whichlistitem(refscan,QANT_reflist())<0)
			string /g refscan ="Default"
		endif
		svar darkscan
		if(!svar_exists(darkscan) || whichlistitem(darkscan,QANT_darklist())<0)
			string /g darkscan ="Default"
		endif
		svar enoffset
		if(!svar_exists(enoffset) )
			string /g enoffset ="0"
		endif
		nvar selected
		if(!nvar_exists(selected) )
			variable /g selected =0
		endif
//		scanlist[j][1] = notes
//		scanlist[j][2] = Anglestr
//		scanlist[j][3] = refscan
//		scanlist[j][4] = darkscan
		scanlist[j][1] = SampleName
		scanlist[j][2] = Anglestr
		scanlist[j][3] = Otherstr
		scanlist[j][4] = SampleSet
		scanlist[j][5] = Notes
		scanlist[j][6] = refscan
		scanlist[j][7] = darkscan
		selwavescanlist[j] = selected
		svar filename, acqtime, filesize, cdate, mdate
		if(strsearch(badfilelist,filename,0)>0)
			for(k=0;k<itemsinlist(badfilelist);k+=1)
				if(stringmatch(filename, stringbykey("filename",stringfromlist(k,badfilelist),"=",",")))
					badfilelist = removefromlist( stringfromlist(k,badfilelist),badfilelist )
				endif
			endfor
		endif
//		scanlist[j][6] = filename
//		scanlist[j][5] = acqtime
//		scanlist[j][7] = enoffset

		scanlist[j][8] = acqtime
		scanlist[j][9] = filename
		scanlist[j][10] = enoffset
		newloadedfilelist += "filename="+filename+","
		newloadedfilelist += "Created Date="+cdate+","
		newloadedfilelist += "Modified Date="+mdate+","
		newloadedfilelist += "DataSize="+filesize+","
		newloadedfilelist +=";"
		wave Index
		enabled[j] = waveexists(Index)
		if(waveexists(Index) && dimsize(index,0)>1)
			colorcolwave[j]=0
		else
			colorcolwave[j]=30000
		endif
		setdatafolder ::
	endfor

	loadedfilelist = newloadedfilelist
	string listofchannels = QANT_channellistdisp()
	setdatafolder root:NEXAFS:
	// ADDING for matchstr
	// make a copy of scanlist and selscanwave
	// sort scan list if there is sorting
	redimension /n=(num,12) ScanList
	ScanList[][11]=num2str(p)
	nvar /z LastScanCol, ScanOrder
	if(nvar_exists(LastScanCol) && LastScanCol >= 0 && LastScanCol <11 && nvar_exists(ScanOrder) && dimsize(Scanlist,0)>0)
		MDsort(scanlist,LastScanCol,reversed = ScanOrder)
	endif
	make /n=(num) /free listorder = str2num(Scanlist[p][11])
	redimension /n=(num,11) ScanList
	duplicate /free listorder, listorder2
	listorder2=p
	sort listorder,listorder2
	sort listorder2, selwavescanlist
	// end sorting
	
	
	duplicate /o scanlist scanwavefull
	duplicate /o selwavescanlist, selwavescanlistfull
	svar matchstr
	variable matchfound, m, itemstomatch, matchesfound
	string searchterms = "",  teststringmatch, parsedstr
	if(svar_exists(matchstr))
		if(strlen(matchstr)>0)
			// parse matchstr to figure out what we are going to search for {0 scannum search terms;1 name search terms; 2 set search terms; 3 notes search terms ; 4 angle search terms ; 5 other search terms} 
			
			for(j=num-1; j>=0;j-=1)
				matchesfound = 0
				
				itemstomatch = itemsinlist(matchstr," ")
				for(m=0;m<itemstomatch;m+=1)
					matchfound=0
					teststringmatch = stringfromlist(m,matchstr," ")
					parsedstr = QANT_parsematchstr(teststringmatch)
					searchterms = stringfromlist(0,parsedstr) //scan filename
					if(strlen(searchterms)>0)
						for(k=0;k<itemsinlist(searchterms,",");k+=1)
							if(stringmatch(scanlist[j][0],"*"+stringfromlist(k,searchterms,",")+"*"))
								matchfound=1
							endif
						endfor
					endif
					searchterms = stringfromlist(1,parsedstr) // name
					if(strlen(searchterms)>0)
						for(k=0;k<itemsinlist(searchterms,",");k+=1)
							if(stringmatch(scanlist[j][1],"*"+stringfromlist(k,searchterms,",")+"*"))
								matchfound=1
							endif
						endfor
					endif
					searchterms = stringfromlist(2,parsedstr) // set
					if(strlen(searchterms)>0)
						for(k=0;k<itemsinlist(searchterms,",");k+=1)
							if(stringmatch(scanlist[j][4],"*"+stringfromlist(k,searchterms,",")+"*"))
								matchfound=1
							endif
						endfor
					endif
					searchterms = stringfromlist(3,parsedstr) // notes
					if(strlen(searchterms)>0)
						for(k=0;k<itemsinlist(searchterms,",");k+=1)
							if(stringmatch(scanlist[j][5],"*"+stringfromlist(k,searchterms,",")+"*"))
								matchfound=1
							endif
						endfor
					endif
					searchterms = stringfromlist(4,parsedstr) // angle
					if(strlen(searchterms)>0)
						for(k=0;k<itemsinlist(searchterms,",");k+=1)
							if(stringmatch(scanlist[j][2],"*"+stringfromlist(k,searchterms,",")+"*"))
								matchfound=1
							endif
						endfor
					endif
					searchterms = stringfromlist(5,parsedstr) // other
					if(strlen(searchterms)>0)
						for(k=0;k<itemsinlist(searchterms,",");k+=1)
							if(stringmatch(scanlist[j][3],"*"+stringfromlist(k,searchterms,",")+"*"))
								matchfound=1
							endif
						endfor
					endif
					if(matchfound)
						matchesfound+=1
					endif
				endfor
				if(matchesfound<itemstomatch)
					DeletePoints /M=0 j, 1, scanlist, selwavescanlist
				endif
			endfor
		endif
	endif
	
	
	
	
	//ending Matchstr
	wave channelsel
	string listofchannelsconv = QANT_channellistconv()
	wave /t channels,channelsconv
	redimension /n=(itemsinlist(listofchannels)) channelSel, channels
	channels = stringfromlist(p,listofchannels)
	redimension /n=(itemsinlist(listofchannelsconv)) channelsconv
	channelsconv = stringfromlist(p,listofchannelsconv)
	setdatafolder foldersave
	QANT_CalcNormalizations("selected")
	//QANT_replotdata()
end

function /s QANT_parsematchstr(stringin)
	string stringin
	string m = stringin
	string out
	string word
	variable loc
	variable spacesatbeginning = 1
	// format of outstr is going to be 6 element list {0 scannum search terms;1 name search terms; 2 set search terms; 3 notes search terms ; 4 angle search terms ; 5 other search terms} 
	// each element can be itself a comma seperated list of terms.  Each comma seperated term is a complete search term.  ie ";;a n2200 sample,f;;;"  will search for a name that contains both "a n2200 sample" and "f" exactly.
	// a general search term should be put in every one of the 6 elements
	string scannumstr="", namestr="", setstr="", notesstr="", anglestr="", otherstr=""
	do
		do
			if(!cmpstr(m[0]," "))
				m = m[1,strlen(m)]
				spacesatbeginning = 1
			else
				spacesatbeginning = 0
			endif
		while(spacesatbeginning)
		word = stringfromlist(0,m," ")
		if(stringmatch(word,"scan:*"))
			loc = strsearch(m, "\"", strlen(word))
			if(stringmatch(word,"scan:\"*") && loc>0)
				word = m[6,loc-1]
				m = m[loc+1,strlen(m)]
			else
				m = replacestring (word,m,"")
				word = replacestring("scan:",word,"")
			endif
			scannumstr = addlistitem(word,scannumstr,",")
		elseif(stringmatch(word,"name:*"))
			loc = strsearch(m, "\"", strlen(word))
			if(stringmatch(word,"name:\"*") && loc>0)
				word = m[6,loc-1]
				m = m[loc+1,strlen(m)]
			else
				m = replacestring (word,m,"")
				word = replacestring("name:",word,"")
			endif
			namestr = addlistitem(word,namestr,",")
		elseif(stringmatch(word,"set:*"))
			loc = strsearch(m, "\"", strlen(word))
			if(stringmatch(word,"set:\"*") && loc>0)
				word = m[5,loc-1]
				m = m[loc+1,strlen(m)]
			else
				m = replacestring (word,m,"")
				word = replacestring("set:",word,"")
			endif
			setstr = addlistitem(word,setstr,",")
		elseif(stringmatch(word,"note:*"))
			loc = strsearch(m, "\"", strlen(word))
			if(stringmatch(word,"note:\"*") && loc>0)
				word = m[6,loc-1]
				m = m[loc+1,strlen(m)]
			else
				m = replacestring (word,m,"")
				word = replacestring("note:",word,"")
			endif
			notesstr = addlistitem(word,notesstr,",")
		elseif(stringmatch(word,"angle:*"))
			loc = strsearch(m, "\"", strlen(word))
			if(stringmatch(word,"angle:\"*") && loc>0)
				word = m[7,loc-1]
				m = m[loc+1,strlen(m)]
			else
				m = replacestring (word,m,"")
				word = replacestring("angle:",word,"")
			endif
			anglestr = addlistitem(word,anglestr,",")
		elseif(stringmatch(word,"other:*"))
			loc = strsearch(m, "\"", strlen(word))
			if(stringmatch(word,"other:\"*") && loc>0)
				word = m[7,loc-1]
				m = m[loc+1,strlen(m)]
			else
				m = replacestring (word,m,"")
				word = replacestring("other:",word,"")
			endif
			otherstr = addlistitem(word,otherstr,",")
		else
			loc = strsearch(m, "\"", strlen(word))
			if(stringmatch(word,"\"*") && loc>0)
				word = m[1,loc-1]
				m = m[loc+1,strlen(m)]
			else
				m = replacestring (word,m,"")
			endif
			scannumstr = addlistitem(word,scannumstr,",")
			namestr = addlistitem(word,namestr,",")
			setstr = addlistitem(word,setstr,",")
			notesstr = addlistitem(word,notesstr,",")
			anglestr = addlistitem(word,anglestr,",")
			otherstr = addlistitem(word,otherstr,",")
			m = replacestring (word,m,"")
		endif
	while(strlen(m)>0)
	out = scannumstr + ";" + namestr + ";" + setstr + ";" + notesstr + ";" + anglestr + ";" + otherstr
	return out
end


Function QANT_LoadBut(ba) : ButtonControl
	STRUCT WMButtonAction &ba

	switch( ba.eventCode )
		case 2: // mouse up
			//string loadedscan = QANT_LoadNEXAFSfile("")
			svar FileType = root:NEXAFS:Filetype
			if(exists("QANT_LoadNEXAFSfile_"+FileType)==6)
				funcref QANT_LoadNEXAFSfile FileLoader=$("QANT_LoadNEXAFSfile_"+FileType)
				string loadedscan = FileLoader("")
			else
				print "no recognized loader could be found"
				return -1
			endif
			
			
			if(strlen(loadedscan)>0)
				QANT_listNEXAFSscans()
				wave selwave = root:NEXAFS:selwavescanlist
				wave scanlist = root:NEXAFS:scanlist
				findvalue /TEXT=loadedscan scanlist
				selwave[v_value]=8
				QANT_listNEXAFSscans()
			endif
			break
		case -1: // control being killed
			break
	endswitch

	return 0
End

Function QANT_LoadDirBut(ba) : ButtonControl
	STRUCT WMButtonAction &ba

	switch( ba.eventCode )
		case 2: // mouse up
			//QANT_LoadDirectory()
			//QANT_BGCheckdir() // changing to this function, so load directory acts essentially as a single "autocheck" directory
								// it doesn't re load every scan (which is better)
								// once autoloading is working well, we can switch this behavior back to reloading directory
			QANT_CheckFulldir()
			break
		case -1: // control being killed
			break
	endswitch

	return 0
End
function QANT_loadDirectory()
	pathinfo NEXAFSPath
	if(v_flag==0)
		newpath/o/q/z/m="Chose the path to the NEXAFS data to load into Igor" NEXAFSPath
		if(v_flag==0)
			print "No Valid Path was Chosen"
			return -1
		endif
		svar directory = root:NEXAFS:directory
		pathinfo NEXAFSPath
		directory = s_path
	endif
	svar fileType = root:NEXAFS:filetype
	funcref QANT_NEXAFSfileEXt_AUMain FileTypeFunc=$("QANT_NEXAFSfileEXt_"+FileType)
	
	string listoffiles = IndexedFile(NEXAFSPath,-1,FileTypeFunc())
	listoffiles = sortlist(listoffiles,";",16)
	variable j
	string filename, loadedscan="", listofscans=""
	for(j=0;j<itemsinlist(listoffiles);j+=1)
		filename = Indexedfile(NEXAFSPath,j,FileTypeFunc())
		getfilefolderinfo/q /P=NEXAFSPath filename
		svar FileType = root:NEXAFS:FileType
		if(exists("QANT_LoadNEXAFSfile_"+FileType)==6)
				funcref QANT_LoadNEXAFSfile FileLoader=$("QANT_LoadNEXAFSfile_"+FileType)
				loadedscan = FileLoader(s_path)
			else
				print "no recognized loader could be found"
				return -1
		endif
		
		
		
		
		
		
		//loadedscan = QANT_LoadNEXAFSfile(s_path)
		if(strlen(loadedscan)>0)
			listofscans += loadedscan + ";"
		endif
	endfor
	QANT_listNEXAFSscans()
	wave selwave = root:NEXAFS:selwavescanlist
	wave scanlist = root:NEXAFS:scanlist
	for(j=0;j<itemsinlist(listofscans);j+=1)
		findvalue /TEXT=stringfromlist(j,listofscans) scanlist
		selwave[v_value]=8
	endfor
	QANT_listNEXAFSscans()
end

Function QANT_but_SaveExperiment(ba) : ButtonControl
	STRUCT WMButtonAction &ba

	switch( ba.eventCode )
		case 2: // mouse up
			saveexperiment
			break
		case -1: // control being killed
			break
	endswitch

	return 0
End

function QANT_Loaderfunc() 
	string foldersave = getdatafolder(1)
	setdatafolder root:
	dowindow /k SHEILA_Resultplot
	dowindow /k SHEILA_Contrast
	dowindow /k SHEILA_AdvPanel
	dowindow /k SHEILA_PeaksetEditWindow
	dowindow /k SHEILA_RefScans_win
	dowindow /k SHEILA_DarkScans_win
	dowindow /k SHEILA_TweakZeroValues
	dowindow /k SHEILA_SaveMPF2Panel
	dowindow /k SHEILA_CreateNewPeakSetWindow
	dowindow /k SHEILALoaderPanel
	dowindow /k SHEILA_plot
	dowindow /k AUNX_Resultplot
	dowindow /k AUNX_Contrast
	dowindow /k AUNX_AdvPanel
	dowindow /k AUNX_PeaksetEditWindow
	dowindow /k AUNX_RefScans_win
	dowindow /k AUNX_DarkScans_win
	dowindow /k AUNX_TweakZeroValues
	dowindow /k AUNX_SaveMPF2Panel
	dowindow /k AUNX_CreateNewPeakSetWindow
	dowindow /k AUNXLoaderPanel
	dowindow /k AUNX_plot
	dowindow /k QANT_Resultplot
	dowindow /k QANT_Contrast
	dowindow /k QANT_AdvPanel
	dowindow /k QANT_PeaksetEditWindow
	dowindow /k QANT_RefScans_win
	dowindow /k QANT_DarkScans_win
	dowindow /k QANT_TweakZeroValues
	dowindow /k QANT_SaveMPF2Panel
	dowindow /k QANT_CreateNewPeakSetWindow
	dowindow /k QANTLoaderPanel
	dowindow /k QANT_plot
	//killdatafolder /Z NEXAFS
	NewPanel /K=1 /n=QANTLoaderPanel  /W=(694,84,1570,713) as "QANT v1.12 (Quick AS NEXAFS Tool)"
	ModifyPanel /w=QANTLoaderPanel fixedSize=1
	debuggeroptions debugOnError=0
	newdatafolder /o/s NEXAFS
	newdatafolder /o scans
	wave/z /t scanlist, channels, channelsconv, coltitles, materialslist, materialstofitlist,  materialslistcols
	wave/z selwavescanlist, colorcolwave, channelSel, enabled, materialslistsel, materialstofitlistsel
	if(!waveexists(materialslist))
		make /o/n=(1,3) /T materialslist
		make /o/n=(1) materialslistsel
	endif
	if(!waveexists(materialstofitlist))
		make /o/n=(0) /T materialstofitlist
		make /o/n=(0) materialstofitlistsel
	endif
	if(!waveexists(materialslistcols))
		make /o/n=(3) /T materialslistcols = {"Name","Scan","Channel"}
	endif
	if(!waveexists(scanlist))
		make /o/n=(1,11) /T scanlist
	endif
	if(dimsize(scanlist,1)==8)
		make /o /t /n=(dimsize(scanlist,0),dimsize(scanlist,1)) scanlistbackup
		scanlistbackup = scanlist
		redimension /n=(dimsize(scanlist,0),11) scanlist
		scanlist[][0] = scanlistbackup[p][0] // scan name is the same  this is critical
		scanlist[][1] = cleanupname(scanlistbackup[p][1],0) // new name is the same as old notes
		scanlist[][2] = scanlistbackup[p][2] // angle is the same as angle
		scanlist[][3] = "" // other is nothing
		scanlist[][4] = "" // sample set is blank
		scanlist[][5] = scanlistbackup[p][1] // notes is identical to "old" notes
		scanlist[][6] = scanlistbackup[p][3]
		scanlist[][7] = scanlistbackup[p][4]
		scanlist[][8] = scanlistbackup[p][5]
		scanlist[][9] = scanlistbackup[p][6]
		scanlist[][10] = scanlistbackup[p][7]
	endif
	if(dimsize(scanlist,1)!=11)
		redimension /n=(dimsize(scanlist,0),11) scanlist
	endif
	if(!waveexists(selwavescanlist))
		make /o/n=(1) selwavescanlist
	endif
	if(!waveexists(colorcolwave))
		make /o/n=(1,3) colorcolwave
	endif
	if(!waveexists(channelSel))
		make /o/n=(1) channelSel=0
	endif
	if(!waveexists(channelsconv))
		make /T/o/n=(1) channelsconv=""
	endif
	if(!waveexists(channels))
		make /T/o/n=(1) channels=""
	endif
	//if(!waveexists(coltitles) || dimsize(coltitles,0)!=11)
		make /o/n=11 /T coltitles={"File","Scan Name","Angle","Other","Set","Notes","Reference","Dark","Time","File from disk","Energy Offset"}
		//{"Name","Notes","Angle","Reference","Dark","Time","Filename","Energy Offset"}
	//endif
	if(!waveexists(enabled))
		make /o/n=1 enabled
	endif
	make /o/n=(33,2)/t QANT_LUT  // a look up table for the channels available in NEXAFS scans at the australian Synchrotron, with their English equivalent discription // this should be changed as needed
								// the channel names themselves shouldn't matter too much, except in special circumstances.
									// for instance, it is important to label Photodiodes with PHD in their name, so they can be treated accordingly (transmission is -ln(I/I0) not the usual I/I0)
									// additionally, certain channels may be hard coded according to their name  (ref_foil is currently hard coded to be the energy calibration channel)
										// these circumstances will be changed in future versions
	QANT_LUT[0][0] = ""
	QANT_LUT[0][1] = "Index"
	QANT_LUT[1][0] = "SR14ID01PGM:REMOTE_SP"
	QANT_LUT[1][1] = "PhotonEnergy"
	QANT_LUT[2][0] = "SR14ID01IOC68:scaler1.TP"
	QANT_LUT[2][1] = "ExpTime"
	QANT_LUT[3][0] = "SR14ID01IOC68:scaler1.S2"
	QANT_LUT[3][1] = "DrainCurrentVF"
	QANT_LUT[4][0] = "SR14ID01IOC68:scaler1.S3"
	QANT_LUT[4][1] = "IzeroVF"
	QANT_LUT[5][0] = "SR14ID01IOC68:scaler1.S4"
	QANT_LUT[5][1] = "Ref_Foil_VF"
	QANT_LUT[6][0] = "SR14ID01IOC68:scaler1.S6"
	QANT_LUT[6][1] = "MCP"
	QANT_LUT[7][0] = "SR14ID01IOC68:scaler1.S10"
	QANT_LUT[7][1] = "Channeltron"
	QANT_LUT[8][0] = "SR14ID01IOC68:scaler1.S11"
	QANT_LUT[8][1] = "TFY_PHD_VF"
	QANT_LUT[9][0] = "SR14ID01IOC68:scaler1.S8"
	QANT_LUT[9][1] = "Direct_PHD_VF"
	QANT_LUT[10][0] = "SR11BCM01:CURRENT_MONITOR"
	QANT_LUT[10][1] = "Ring Current"
	QANT_LUT[11][0] = "SR14ID01PGM_CALC_ENERGY_MONITOR.P"
	QANT_LUT[11][1] = "EncoderPhotonEnergy"
	QANT_LUT[12][0] = "SR14ID01PGM_ENERGY_SP"
	QANT_LUT[12][1] = "EnergySetpoint"
	QANT_LUT[13][0] = "SR14ID01AMP01:CURR_MONITOR"
	QANT_LUT[13][1] = "DrainCurrent_Keithley1"
	QANT_LUT[14][0] = "SR14ID01AMP03:CURR_MONITOR"
	QANT_LUT[14][1] = "Izero_Keithley3"
	QANT_LUT[15][0] = "SR14ID01AMP04:CURR_MONITOR"
	QANT_LUT[15][1] = "RefFoil_Keithley4"
	QANT_LUT[16][0] = "SR14ID01AMP06:CURR_MONITOR"
	QANT_LUT[16][1] = "Keithley6"
	QANT_LUT[17][0] = "SR14ID01IOC68:scaler1.S9"
	QANT_LUT[17][1] = "BL_PHD_VF"
	QANT_LUT[18][0] = "SR14ID01AMP02:CURR_MONITOR"
	QANT_LUT[18][1] = "BL_PHD_Keithley2"
	QANT_LUT[19][0] = "SR14ID01:BL_GAP_REQUEST"
	QANT_LUT[19][1] = "Undulator_Gap_Request"
	QANT_LUT[20][0] = "SR14ID01:GAP_MONITOR"
	QANT_LUT[20][1] = "Undulator_Gap_Readback"
	QANT_LUT[21][0] = "SR14ID01PGM:LOCAL_SP"
	QANT_LUT[21][1] = "EnergySetpoint"
	
	QANT_LUT[22][0] = "SR14ID01IOC68:scaler1.S20"
	QANT_LUT[22][1] = "Drain_Current_VF"
	QANT_LUT[23][0] = "SR14ID01IOC68:scaler1.S18"
	QANT_LUT[23][1] = "Izero_VF"
	QANT_LUT[24][0] = "SR14ID01IOC68:scaler1.S19"
	QANT_LUT[24][1] = "Ref_Foil_VF"
	QANT_LUT[25][0] = "SR14ID01IOC68:scaler1.S22"
	QANT_LUT[25][1] = "MCP_/_TFY"
	QANT_LUT[26][0] = "SR14ID01IOC68:scaler1.S21"
	QANT_LUT[26][1] = "Channeltron_Front_/_PEY"
	QANT_LUT[27][0] = "SR14ID01IOC68:scaler1.S23"
	QANT_LUT[27][1] = "Hemispherical_Analyser_/_AEY"
	QANT_LUT[28][0] = "SR14ID01IOC68:scaler1.S17"
	QANT_LUT[28][1] = "Direct_PHD_VF"
	QANT_LUT[29][0] = "SR14ID01AMP08:CURR_MONITOR"
	QANT_LUT[29][1] = "DrainCurrent_Keithley8"
	QANT_LUT[30][0] = "SR14ID01AMP09:CURR_MONITOR"
	QANT_LUT[30][1] = "Izero_Keithley9"
	QANT_LUT[31][0] = "SR14ID01AMP07:CURR_MONITOR"
	QANT_LUT[31][1] = "RefFoil_Keithley7"
	QANT_LUT[32][0] = "SR14ID01AMP05:CURR_MONITOR"
	QANT_LUT[32][1] = "Direct_PHD_Keithley5"
	
	QANT_LUT[33][0] = "SR14ID01IOC68:scaler1.S9"
	QANT_LUT[33][1] = "BL_PHD_VF"
	
	svar directory,normchan,dnormchan,x_axis, peaksetfit, Colortable, matchstr, FileType, CloneName, CitationText
	if(svar_exists(directory)==0)
		string /g directory = ""
	endif
	if(svar_exists(normchan)==0)
		string /g normchan = "none"
	endif
	if(svar_exists(dnormchan)==0)
		string /g dnormchan = "none"
	endif
	if(svar_exists(x_axis)==0)
		string /g x_axis = "none"
	endif
	if(svar_exists(peaksetfit)==0)
		string /g peaksetfit = "none"
	endif
	if(svar_exists(Colortable)==0)
		string /g Colortable = "YellowHot"
	endif
	if(svar_exists(matchstr)==0)
		string /g matchstr = ""
	endif
	if(svar_exists(FileType)==0)
		string /g FileType="MDA"
	endif
	if(svar_exists(CloneName)==0)
		string /g CloneName=""
	endif
	if(svar_exists(CitationText)==0)
		string /g CitationText="\JCQuick AS NEXAFS Tool (QANT): \ra program for NEXAFS loading and analysis \rdeveloped at the Australian Synchrotron\rE Gann, CR McNeill, A Tadich,\r BCC Cowie, L Thomsen\rJournal of synchrotron radiation, 2016\r\rdoi.org/10.1107/S1600577515018688"
	endif
	
	
	nvar CorExptime, NormCursors, subcursors, curax, curbx, curcx, curdx, cura, curb, curc, curd, HoldPeakWidth, HoldPeakPositions, HoldNexafsEdge, running, lastRunTicks, RunNumber, MatFittingXMax, MatFittingXMin, scanorder, lastscancol
	if(nvar_exists(CorExptime)==0)
		variable /g CorExptime=0
	endif
	if(nvar_exists(NormCursors)==0)
		variable /g NormCursors=0
	endif
	if(nvar_exists(subcursors)==0)
		variable /g subcursors=0
	endif
	if(nvar_exists(curax)==0)
		variable /g curax=280
	endif
	if(nvar_exists(curbx)==0)
		variable /g curbx=282
	endif
	if(nvar_exists(curcx)==0)
		variable /g curcx=310
	endif
	if(nvar_exists(curdx)==0)
		variable /g curdx=320
	endif
	 // sets nominal cursor locations, this isn't working correctly right now
	if(nvar_exists(cura)==0)
		variable /g cura=.02
	endif
	if(nvar_exists(curb)==0)
		variable /g curb=.1
	endif
	if(nvar_exists(curc)==0)
		variable /g curc=0.90
	endif
	if(nvar_exists(curd)==0)
		variable /g curd=0.98
	endif
	if(nvar_exists(HoldPeakWidth)==0)
		variable /g HoldPeakWidth=1
	endif
	if(nvar_exists(HoldPeakPositions)==0)
		variable /g HoldPeakPositions=1
	endif
	if(nvar_exists(HoldNexafsEdge)==0)
		variable /g HoldNexafsEdge=1
	endif
	if(nvar_exists(running)==0)
		variable /g running=0
	endif
	if(nvar_exists(lastRunTicks)==0)
		variable /g lastRunTicks=ticks
	endif
	if(nvar_exists(RunNumber)==0)
		variable /g RunNumber=0
	endif
	if(nvar_exists(MatFittingXMax)==0)
		variable /g MatFittingXMax=inf
	endif
	if(nvar_exists(MatFittingXMin)==0)
		variable /g MatFittingXMin=-inf
	endif
	if(nvar_exists(ScanOrder)==0)
		variable /g ScanOrder=0
	endif
	if(nvar_exists(LastScanCol)==0)
		variable /g LastScanCol=8
	endif
	//advanced options
	nvar correctphotodiode //(divides the spectrum by the energy to the first order, to account for the 3.66 eV * photon / electron produced in the diode
	if(nvar_exists(correctphotodiode)==0)
		variable /g correctphotodiode=0
	endif
	nvar calcKK //Calculates the Kramers Kronig of displayed spectrums if a chemical formula (of the form"CHEMFORM:AaXBbYCcZ" and density of the form (DENSITY:X) are specified in sample set
	// warning this calculation can be a bit time intensive, so a status window will be displayed
	if(nvar_exists(calcKK)==0)
		variable /g calcKK=0
	endif
	nvar DispStitched //Displays the Stitched data from 0 to 30keV (only available if calcKK is 1 and chenical formula and density are specified)
	if(nvar_exists(DispStitched)==0)
		variable /g DispStitched=0
	endif
	nvar DispDelta //Displays delta along with Beta (only available if calcKK is 1 and chenical formula and density are specified)  if dispstitched data is chosen, then delta will also be stitched 
	if(nvar_exists(DispDelta)==0)
		variable /g DispDelta=0
	endif
	nvar LinearPreEdge //Displays delta along with Beta (only available if calcKK is 1 and chenical formula and density are specified)  if dispstitched data is chosen, then delta will also be stitched 
	if(nvar_exists(LinearPreEdge)==0)
		variable /g LinearPreEdge=0
	endif
	nvar ExpPreEdge //Displays delta along with Beta (only available if calcKK is 1 and chenical formula and density are specified)  if dispstitched data is chosen, then delta will also be stitched 
	if(nvar_exists(ExpPreEdge)==0)
		variable /g ExpPreEdge=0
	endif
	
	
	newdatafolder /o fitting
	//autoloader
	string /g oldfilelist
	variable modenum=0
	
	// new version start
	
	SetDrawLayer UserBack
	DrawText 13,407,"Scan Notes:"
	DrawText 322,618,"Fit Name (blank for auto):"
	DrawText 13,431,"Scan Name:"
	DrawText 214,456,"Other:"
	DrawText 215,432,"Angle:"
	SetDrawEnv fsize= 10
	DrawText 493,215,"Secondary Normalization Reference"
	DrawText 490,293,"Dark values to use for selection:"
	DrawText 13,455,"Sample Set:"
	DrawText 598,622,"Material Name:"
	SetDrawEnv fsize= 10
	DrawText 240,44,"use \"name:\" to limit search to the Sample Name"
	SetDrawEnv fsize= 10
	DrawText 246,56,"or \"note:\", \"angle:\", \"scan:\", \"set:\" or \"other:\""
	SetDrawEnv fsize= 10
	DrawText 504,129,"Double Normalization Channel:"
	SetDrawEnv fsize= 10
	DrawText 512,90,"Normalization Channel (I\\B0\\M):"
	DrawText 240,27,"Search Scans"
	SetDrawEnv fsize= 10
	DrawText 494,226,"For Selected Scan(s):"
	GroupBox QANT_group_scaling,pos={677,321},size={187,70},title="Step Scaling"
	GroupBox QANT_group_scaling,labelBack=(57344,65280,48896),frame=0
	GroupBox QANT_group_loading,pos={6,458},size={300,170},title="Loading and Exporting"
	GroupBox QANT_group_loading,labelBack=(48896,65280,48896)
	GroupBox QANT_group_Fitting,pos={308,413},size={563,215},title="Analysis"
	GroupBox QANT_group_Fitting,labelBack=(48896,52992,65280),fSize=12
	GroupBox QANT_group_peaksets,pos={313,430},size={274,165},title="Peak Fitting and Peaksets"
	GroupBox QANT_group_peaksets,labelBack=(38400,54784,59648),frame=0
	GroupBox QANT_group_darkscans,pos={487,255},size={181,134},title="Dark Values"
	GroupBox QANT_group_darkscans,labelBack=(65280,54528,48896),frame=0
	GroupBox QANT_group_Normscans,pos={487,8},size={180,244},title="Normalizations and Corrections"
	GroupBox QANT_group_Normscans,labelBack=(48896,65280,57344),frame=0
	GroupBox QANT_group_graphing,pos={676,9},size={190,306},title="Graphing"
	GroupBox QANT_group_graphing,labelBack=(65280,65280,48896),frame=0
	GroupBox QANT_group_scans,pos={3,44},size={470,342},title="Scans (hold alt (opt) to changing column sizes)"
	ListBox QANT_listbox_loadedfiles,pos={10,60},size={463,321},proc=QANT_ScanListbox
	ListBox QANT_listbox_loadedfiles,labelBack=(32768,40704,65280)
	ListBox QANT_listbox_loadedfiles,listWave=root:NEXAFS:scanlist
	ListBox QANT_listbox_loadedfiles,selWave=root:NEXAFS:selwavescanlist
	ListBox QANT_listbox_loadedfiles,colorWave=root:NEXAFS:colorcolwave
	ListBox QANT_listbox_loadedfiles,titleWave=root:NEXAFS:coltitles,mode=9
	ListBox QANT_listbox_loadedfiles,widths={74,77,34,35,75,150,64,54,155,97,71}
	ListBox QANT_listbox_loadedfiles,userColumnResize= 1
	SetVariable QANT_strval_Matchstring,pos={325,11},size={151,16},bodyWidth=151,proc=QANT_Matchstr,title=" "
	SetVariable QANT_strval_Matchstring,value= root:NEXAFS:matchstr,live= 1
	Button QANT_but_LoadFile,pos={128,476},size={70,37},proc=QANT_LoadBut,title="Load\rsingle file",font="Arial",fSize=10
	Button QANT_but_LoadDif,pos={134.00,541.00},size={66.00,38.00},proc=QANT_LoadDirBut,title="Reload Directory",font="Arial",fSize=10
	Button QANT_but_browse,pos={18,476},size={104,37},proc=QANT_browse,title="Browse for Directory",font="Arial",fSize=10
	CheckBox QANT_autoload,pos={20,544},size={118,24},proc=QANT_AutoloaderCheck,title="Auto Load Directory",font="Arial",fSize=10
	CheckBox QANT_autoload,value= 0
	TitleBox QANT_title_AutoloadDir,pos={19,518},size={277,21}
	TitleBox QANT_title_AutoloadDir,variable= root:NEXAFS:directory,fixedSize=1
	Button QANT_but_LoadDark,pos={498,321},size={161,39},disable=2,proc=QANT_LoadDarkBut,title="Load dark values\rfrom selected scan",font="Arial",fSize=10
	Button QANT_but_LoadRef,pos={504,157},size={151,43},disable=2,proc=QANT_LoadRefBut,title="Load Selected Scan as an\rI\\B0\\M Secondary Normalization\rReference",font="Arial",fSize=10
	Button QANT_but_Remove,pos={206,476},size={88,37},disable=2,proc=QANT_RemoveScanBut,title="Remove\rScan(s)",font="Arial",fSize=10
	Button QANT_but_Fit,pos={471,533},size={100,44},disable=2,proc=QANT_but_FitPeaks,title="Fit graphed scan(s)\rto this Peak Set",font="Arial",fSize=10
	PopupMenu QANT_popup_Norm_Channel,pos={502,92},size={151,21},bodyWidth=151,proc=QANT_popNorm
	modenum = whichlistitem(normchan,QANT_channellistn())+1
	PopupMenu QANT_popup_Norm_Channel,mode=modenum,popvalue=normchan,value= #"QANT_channellistn()"
	PopupMenu QANT_popup_Norm_Channel1,pos={502,132},size={153,21},bodyWidth=153,disable=2,proc=QANT_popDNorm
	modenum = whichlistitem(dnormchan,QANT_channellistdn())+1
	PopupMenu QANT_popup_Norm_Channel1,mode=modenum,popvalue=dnormchan,value= #"QANT_Channellistdn()"
	ListBox QANT_list_Channels,pos={684,30},size={175,250},proc=QANT_ChannelSelectionListBox
	ListBox QANT_list_Channels,listWave=root:NEXAFS:channels
	ListBox QANT_list_Channels,selWave=root:NEXAFS:channelSel,mode= 9
	PopupMenu QANT_popup_X_xais,pos={19,11},size={209,21},bodyWidth=174,proc=QANT_X_axis_pop,title="X-Axis:"
	PopupMenu QANT_popup_X_xais,fSize=12,fStyle=0
	modenum = max(whichlistitem(x_axis,QANT_channellistxaxis())+1,1)
	PopupMenu QANT_popup_X_xais,mode=modenum,popvalue=x_axis,value= #"QANT_channellistxaxis()"
	CheckBox QANT_CHK_NormCursors,pos={695,338},size={132,24},proc=QANT_NormCursorsCheckProc,title="Scale area between BLACK\rCursor to 1",font="Arial",fSize=10
	CheckBox QANT_CHK_NormCursors,variable= root:NEXAFS:NormCursors
	CheckBox QANT_CHK_SubCursors,pos={695,362},size={126,24},proc=QANT_SubCursorsCheckProc,title="Scale area between BLUE\rcursors to 0",font="Arial",fSize=10
	CheckBox QANT_CHK_SubCursors,variable= root:NEXAFS:SubCursors
	Button QANT_but_NewPeak,pos={321,485},size={60,35},proc=QANT_but_NewPeak,title="Make New\rPeak Set",font="Arial",fSize=10
	PopupMenu QANT_popup_PeakSet,pos={331,446},size={237,24},bodyWidth=207,proc=QANT_PeakSetPOP,title="Peak  \rSet:"
	modenum = whichlistitem(peaksetfit,QANT_ListPeakSets())+1
	PopupMenu QANT_popup_PeakSet,mode=modenum,popvalue=peaksetfit,value= #"QANT_ListPeakSets()"
	Button QANT_but_LoadPeakSet,pos={383,484},size={84,35},proc=QANT_LoadPeakSet_button,title="Open Peak Set\rFrom Disk",font="Arial",fSize=10
	Button QANT_but_RemovePeakSet,pos={472,484},size={52,35},disable=2,proc=QANT_RemovePeakSet,title="Remove",font="Arial",fSize=10
	CheckBox QANT_CHK_Fitting_HoldPos,pos={333,545},size={102,14},title="Hold Peak Positions",font="Arial",fSize=10
	CheckBox QANT_CHK_Fitting_HoldPos,variable= root:NEXAFS:HoldPeakPositions
	CheckBox QANT_CHK_Fitting_HoldWidths,pos={333,526},size={93,14},title="Hold Peak Widths",font="Arial",fSize=10
	CheckBox QANT_CHK_Fitting_HoldWidths,variable= root:NEXAFS:HoldPeakWidth
	SetVariable QANT_setVar_FitName,pos={463,604},size={123,16},bodyWidth=123
	SetVariable QANT_setVar_FitName,value= _STR:"",live= 1
	CheckBox QANT_CHK_Fitting_HoldEdge,pos={333,564},size={95,14},title="Hold Nexafs Edge",font="Arial",fSize=10
	CheckBox QANT_CHK_Fitting_HoldEdge,variable= root:NEXAFS:HoldNexafsEdge
	Button QANT_but_Saveexperiment,pos={10,581},size={97,45},proc=QANT_SaveExperiment_but,title="Save\rExperiment\r(crtl-s)",font="Arial",fSize=10
	Button QANT_but_ExportSelData,pos={108,581},size={97,45},disable=2,proc=QANT_ExportSelData_but,title="Export Selected\rScan(s) to File",font="Arial",fSize=10
	Button QANT_but_ExportGraph,pos={206,581},size={97,45},proc=QANT_ExportGraph_but,title="Copy data from\rtop graph to\rsystem clipboard",font="Arial",fSize=10
	PopupMenu QANT_Colortabpop,pos={684,287},size={71,21},bodyWidth=71,proc=QANT_Colorpop
	modenum = whichlistitem(Colortable,CTabList())+1
	PopupMenu QANT_Colortabpop,mode=modenum,value= #"\"*COLORTABLEPOPNONAMES*\""
	Button QANT_but_ManageDarks,pos={498,362},size={161,21},proc=QANT_adjDarks,title="Manage dark values",font="Arial",fSize=10
	Button QANT_but_ManageRefs,pos={501,28},size={152,45},proc=QANT_adjRefs,title="Manage secondary\rnormalization references and\rX-ray energy corrections",font="Arial",fSize=10
	PopupMenu QANT_popup_DarkSel,pos={498,296},size={162,21},bodyWidth=162,proc=QANT_popDark
	PopupMenu QANT_popup_DarkSel,mode=1,popvalue="Default",value= #"QANT_DarkList()"
	PopupMenu QANT_popup_RefSel,pos={504,227},size={150,21},bodyWidth=150,proc=QANT_popRef
	PopupMenu QANT_popup_RefSel,mode=2,popvalue="Default",value= #"QANT_RefList()"
	PopupMenu QANT_popup_LineThickness,pos={763,287},size={95,21},bodyWidth=40,proc=QANT_linethickness,title="Line weight: ",font="Arial",fSize=10
	PopupMenu QANT_popup_LineThickness,mode=1,popvalue="1",value= #"\"1;1.5;2;3;4;5\""
	GroupBox QANT_group_MaterialsFitting,pos={593,430},size={273,194},title="Material Composition",font="Arial",fSize=10
	GroupBox QANT_group_MaterialsFitting,labelBack=(48896,49152,65280),frame=0
	Button QANT_but_EditPeakSet,pos={526,484},size={52,35},disable=2,proc=QANT_EditPeaksetWindowOpen,title="Edit",font="Arial",fSize=10
	SetVariable QANT_strval_SampleName,pos={82,417},size={125,16},bodyWidth=125,disable=1,proc=QANT_NameSet
	SetVariable QANT_strval_SampleName,value= _STR:"",live= 1,font="Arial",fSize=10
	SetVariable QANT_strval_scanAngle,pos={254,417},size={41,16},bodyWidth=41,disable=1,proc=QANT_AngSet
	SetVariable QANT_strval_scanAngle,value= _STR:"",live= 1,font="Arial",fSize=10
	SetVariable QANT_strval_scanOther,pos={254,441},size={41,16},bodyWidth=41,disable=1,proc=QANT_OtherSet
	SetVariable QANT_strval_scanOther,value= _STR:"",live= 1,font="Arial",fSize=10
	SetVariable QANT_strval_SampleSet,pos={82,440},size={122,16},bodyWidth=122,disable=1,proc=QANT_SampleSetSet
	SetVariable QANT_strval_SampleSet,value= _STR:"",live= 1,font="Arial",fSize=10
	SetVariable QANT_strval_notes,pos={82,392},size={783,16},bodyWidth=783,disable=1,proc=QANT_notesSet
	SetVariable QANT_strval_notes,value= _STR:"( X=5, Y=5.1, Z=4, R1=80, R2=1)",styledText= 1,live= 1,font="Arial",fSize=10
	ListBox QANT_listb_MaterialsAvailable,pos={597,448},size={108,118},proc=QANT_list_MaterialsAvailable,font="Arial",fSize=10
	ListBox QANT_listb_MaterialsAvailable,labelBack=(32768,40704,65280)
	ListBox QANT_listb_MaterialsAvailable,listWave=root:NEXAFS:materialslist
	ListBox QANT_listb_MaterialsAvailable,selWave=root:NEXAFS:materialslistsel
	ListBox QANT_listb_MaterialsAvailable,colorWave=root:NEXAFS:colorcolwave
	ListBox QANT_listb_MaterialsAvailable,titleWave=root:NEXAFS:materialslistcols
	ListBox QANT_listb_MaterialsAvailable,mode= 4,widths={70,70,70}
	ListBox QANT_listb_MaterialsAvailable,userColumnResize= 1
	SetVariable QANT_strval_Materialname,pos={685,606},size={172,16},proc=QANT_strset_materialname
	SetVariable QANT_strval_Materialname,value= _STR:"",font="Arial",fSize=10
	ListBox QANT_listbox_MaterialsToFit,pos={742,461},size={116,45},proc=QANT_list_MaterialsToFit
	ListBox QANT_listbox_MaterialsToFit,labelBack=(32768,40704,65280)
	ListBox QANT_listbox_MaterialsToFit,listWave=root:NEXAFS:materialstofitlist
	ListBox QANT_listbox_MaterialsToFit,selWave=root:NEXAFS:materialstofitlistsel
	ListBox QANT_listbox_MaterialsToFit,mode= 4,userColumnResize= 1,font="Arial",fSize=10
	GroupBox QANT_group_MaterialsToFit,pos={738,446},size={123,63},title="Materials to Fit"
	GroupBox QANT_group_MaterialsToFit,frame=0,font="Arial",fSize=10
	Button QANT_but_AddMaterialsToFit,pos={709,466},size={25,31},proc=QANT_AddMaterialtoFit,title="->",font="Arial",fSize=10
	Button QANT_but_AddMaterialsToFit,fSize=16,fStyle=1
	Button QANT_but_AddScanToMaterials,pos={600,570},size={117,34},proc=QANT_but_AddscantoMaterials,title="Save graphed scan(s)\r as Material(s)",font="Arial",fSize=10
	Button QANT_but_FitMaterials,pos={740,517},size={117,34},proc=QANT_FitMaterials,title="FIT graphed scan(s)\rto these Materials",font="Arial",fSize=10
	Button QANT_but_RemoveMatersFromFit,pos={709,497},size={25,31},proc=QANT_rmMaterialsFromFit,title="<-",font="Arial",fSize=10
	Button QANT_but_RemoveMatersFromFit,fSize=16,fStyle=1
	Button QANT_but_RemoveMaterials,pos={706,531},size={31,29},proc=QANT_delMaterial,title="DEL",font="Arial",fSize=10
	Button QANT_but_RemoveMaterials,fSize=12,fStyle=1
	SetVariable QANT_setvar_Materials_xmin,pos={748,565},size={89,16},bodyWidth=62,title="X min",font="Arial",fSize=10
	SetVariable QANT_setvar_Materials_xmin,value= root:NEXAFS:MatFittingXMin
	SetVariable QANT_setvar_Materials_xmax,pos={745,585},size={92,16},bodyWidth=62,title="X max",font="Arial",fSize=10
	SetVariable QANT_setvar_Materials_xmax,value= root:NEXAFS:MatFittingXMax

	PopupMenu FileFormatPopup,pos={13.00,561.00},size={152.00,19.00},title="File Type:"
	PopupMenu FileFormatPopup,mode=1,popvalue=FileType,value= #"QANT_FTypeList()",proc=QANT_popFType
	
	Button QANT_CloneBut,pos={206.00,542.00},size={95.00,20.00},proc=QANT_Clone_but,title="Clone Top Graph"
	Button QANT_CloneBut,font="Arial",fSize=10
	SetVariable QANT_CloneName,pos={207.00,563.00},size={92.00,16.00},title="Name"
	SetVariable QANT_CloneName,font="Arial",fSize=10,variable=CloneName
	//New Layout End
	
		
	pathinfo NEXAFSPath
	if(v_flag)
		directory = s_path
	endif
	
	setdatafolder root:NEXAFS
	QANT_listNEXAFSscans()
end 

function /S QANT_channellistdisp()
	string basiclist = QANT_channellist()
	svar nchan =  root:NEXAFS:normchan
	svar dnchan =  root:NEXAFS:dnormchan
	svar x_axis =  root:NEXAFS:x_axis
	Nvar CorExptime =  root:NEXAFS:CorExptime
	if(CorEXPtime)
		basiclist = removefromlist("ExpTime",basiclist)
	endif
	//return removefromlist(nchan,removefromlist(x_axis,removefromlist("none",basiclist,";")))
	return removefromlist("ExtraPVs",removefromlist("extrainfo",removefromlist(x_axis,removefromlist("none",basiclist,";"))))
end
function /S QANT_channellistxaxis()
	
	svar nchan =  root:NEXAFS:normchan
	svar dnchan =  root:NEXAFS:dnormchan
	svar x_axis =  root:NEXAFS:x_axis
	string basiclist = removefromlist("ExtraPVs",removefromlist("extrainfo",removefromlist(nchan,removefromlist(dnchan,removefromlist("none",QANT_channellist(),";")))))
	if(findlistitem(x_axis,basiclist) == -1)
		x_axis = "EncoderPhotonEnergy"
		if(findlistitem(x_axis,basiclist) == -1)
			string energylikeobject
			splitstring /e=";([^;]*[E|e]n[^;]*);" basiclist, energylikeobject
			if(strlen(energylikeobject)>1)
				x_axis = energylikeobject
				PopupMenu QANT_popup_X_xais win=QANTLoaderPanel, fSize=12,fstyle=0,fColor=(0,0,0)
			else
				basiclist += ";Choose an X-axis first"
				x_axis =  "Choose an X-axis first"
				PopupMenu QANT_popup_X_xais win=QANTLoaderPanel, fSize=14,fstyle=3,fColor=(65280,0,0)
			endif
		else
			PopupMenu QANT_popup_X_xais win=QANTLoaderPanel, fSize=12,fstyle=0,fColor=(0,0,0)
		endif
	else
		PopupMenu QANT_popup_X_xais win=QANTLoaderPanel, fSize=12,fstyle=0,fColor=(0,0,0)
	endif
	return basiclist
end
function /S QANT_channellistconv()
	string basiclist = QANT_channellist()
	svar x_axis =  root:NEXAFS:x_axis
	Nvar CorExptime =  root:NEXAFS:CorExptime
	if(CorEXPtime)
		basiclist = removefromlist("ExpTime",basiclist)
	endif
	basiclist = removefromlist("HOPG",basiclist)
	basiclist = removefromlist("Ring Current",basiclist)
	return removefromlist(x_axis,removefromlist("none",basiclist,";"))
end
function /S QANT_channellistdn()
	string basiclist = QANT_channellist()
	svar nchan =  root:NEXAFS:normchan
	nvar reffile = root:NEXAFS:reffile
	svar x_axis =  root:NEXAFS:x_axis
	Nvar CorExptime =  root:NEXAFS:CorExptime
	if(cmpstr(nchan,"none"))
		basiclist = removefromlist(nchan,basiclist)
	endif
	if(cmpstr(x_axis,"none"))
		basiclist = removefromlist(x_axis,basiclist)
	endif
	if(CorEXPtime)
		basiclist = removefromlist("ExpTime",basiclist)
	endif
	return basiclist
end
function /S QANT_channellistn()
	string basiclist = QANT_channellist()
	svar x_axis =  root:NEXAFS:x_axis
	svar dnchan =  root:NEXAFS:dnormchan
	nvar CorExptime = root:NEXAFS:CorExptime
	if(cmpstr(dnchan,"none"))
		basiclist = removefromlist(dnchan,basiclist)
	endif
	if(cmpstr(x_axis,"none"))
		basiclist = removefromlist(x_axis,basiclist)
	endif
	if(CorEXPtime)
		basiclist = removefromlist("ExpTime",basiclist)
	endif
	return basiclist
end
function /S QANT_channellist()
	string clist
	clist = "none;"
	string foldersave = getdatafolder(1)
	setdatafolder root:NEXAFS
	wave/t scanlist
	wave selwave = root:NEXAFS:selwavescanlist
	duplicate /free selwave, selwavescanlist
	if(waveexists(selwave))
		if(dimsize(selwave,0)>0)
			selwavescanlist =selwave? 1 : 0
		endif
	endif
	setdatafolder scans
	variable j,k
	string templist, templist2
	string testchannel
	for(j=0;j<dimsize(selwavescanlist,0);j+=1)
		if(selwavescanlist[j]==0)
			continue
		endif
		setdatafolder $scanlist[j][0]
		templist =wavelist("*",";","MINROWS:5,TEXT:0,DIMS:1")
		templist2 =wavelist("*_old",";","MINROWS:5,TEXT:0,DIMS:1")
		templist = removefromlist("Channelnames",removefromlist("Columnnames",templist))
		for(k=0;k<itemsinlist(templist2);k+=1)
			templist = removefromlist(stringfromlist(k,templist2),templist)
		endfor
		
		for(k=0;k<itemsinlist(templist);k+=1)
			testchannel = stringfromlist(k,templist)
			if(findlistitem(testchannel,clist)==-1)
				clist += testchannel +";"
			endif
		endfor
		setdatafolder ::
	endfor
	setdatafolder foldersave
	return removefromlist("ExtraPVs",removefromlist("extrainfo",clist))
end


Function QANT_browse(ba) : ButtonControl
	STRUCT WMButtonAction &ba

	switch( ba.eventCode )
		case 2: // mouse up
			svar directory = root:NEXAFS:directory
			newpath/o/q/z/m="Chose the path to the NEXAFS data to load into Igor" NEXAFSPath
			if(v_flag==1)
				print "No Valid Path was Chosen"
			endif
			pathinfo NEXAFSPath
			directory = s_path
			break
		case -1: // control being killed
			break
	endswitch

	return 0
End

Function QANT_notesSet(sva) : SetVariableControl
	STRUCT WMSetVariableAction &sva

	switch( sva.eventCode )
		case 1: // mouse up
		case 2: // Enter key
		case 3: // Live update
			Variable dval = sva.dval
			variable i
			String sval = sva.sval
			string foldersave = getdatafolder(1)
			setdatafolder root:NEXAFS
			wave selwave = root:NEXAFS:selwavescanlist
			duplicate /free selwave, selwavescanlist
			selwavescanlist =selwave? 1 : 0
			wave /t scanlist
			setdatafolder scans
			// popup warning if multiple scans are selected
			if(sum(selwavescanlist)>1)
				doalert /t="Warning" 1, "The changes you have made will apply to multiple scans! Continue?"
				if(v_flag==2)
					break
				endif
			endif
			for(i=0;i<sum(selwavescanlist);i+=1)
				if(i==0)
					findvalue /v=1 /T=.1 /z selwavescanlist // find selected Scan
				else
					findvalue /s=(v_value+1) /v=1 /T=.1 /z selwavescanlist // find next selected Scan
				endif
				setdatafolder $scanlist[v_value][0] // goto selected scan so we can set the notes variable
				svar /z notes
				if(!svar_exists(notes))
					string /g Notes
				endif
				notes = sval
				setdatafolder ::
			endfor
			setdatafolder foldersave
			QANT_listNEXAFSscans()
			listbox QANT_listbox_loadedfiles activate
			break
		case -1: // control being killed
			break
	endswitch

	return 0
End
Function QANT_PeakFitNameSet(sva) : SetVariableControl
	STRUCT WMSetVariableAction &sva

	switch( sva.eventCode )
		case 1: // mouse up
		case 2: // Enter key
		case 3: // Live update
			Variable dval = sva.dval
			variable i
			String sval = sva.sval
			string cleanedname
			string foldersave = getdatafolder(1)
			cleanedname = cleanupname(sval,0)
			setvariable QANT_setVar_FitName win=QANTLoaderPanel,value=_STR:CleanedName
			// setvariable value to the accepted version here.  No need, because we rescan all variables below, so it will update automatically
			break
		case -1: // control being killed
			break
	endswitch

	return 0
End
Function QANT_NameSet(sva) : SetVariableControl
	STRUCT WMSetVariableAction &sva

	switch( sva.eventCode )
		case 1: // mouse up
		case 2: // Enter key
		case 3: // Live update
			Variable dval = sva.dval
			variable i
			String sval = sva.sval
			string cleanedname
			string foldersave = getdatafolder(1)
			setdatafolder root:NEXAFS
			wave selwave = root:NEXAFS:selwavescanlist
			duplicate /free selwave, selwavescanlist
			selwavescanlist =selwave? 1 : 0
			wave /t scanlist
			setdatafolder scans
			cleanedname = cleanupname(sval,0)
			setvariable QANT_strval_SampleName win=QANTLoaderPanel,value=_STR:CleanedName
			// setvariable value to the accepted version here.  No need, because we rescan all variables below, so it will update automatically
			
			// popup warning if multiple scans are selected
			if(sum(selwavescanlist)>1)
				doalert /t="Warning" 1, "The changes you have made will apply to multiple scans! Continue?"
				if(v_flag==2)
					break
				endif
			endif
			for(i=0;i<sum(selwavescanlist);i+=1)
				if(i==0)
					findvalue /v=1 /T=.1 /z selwavescanlist // find selected Scan
				else
					findvalue /s=(v_value+1) /v=1 /T=.1 /z selwavescanlist // find next selected Scan
				endif
				setdatafolder $scanlist[v_value][0] // goto selected scan so we can set the notes variable
				svar /z SampleName
				if(!svar_exists(SampleName))
					string /g SampleName
				endif
				SampleName = cleanedname
				setdatafolder ::
			endfor
			setdatafolder foldersave
			QANT_listNEXAFSscans()
			listbox QANT_listbox_loadedfiles activate
			break
		case -1: // control being killed
			break
	endswitch

	return 0
End
Function QANT_SampleSetSet(sva) : SetVariableControl
	STRUCT WMSetVariableAction &sva

	switch( sva.eventCode )
		case 1: // mouse up
		case 2: // Enter key
		case 3: // Live update
			Variable dval = sva.dval
			variable i
			String sval = sva.sval
			string foldersave = getdatafolder(1)
			setdatafolder root:NEXAFS
			wave selwave = root:NEXAFS:selwavescanlist
			duplicate /free selwave, selwavescanlist
			selwavescanlist =selwave? 1 : 0
			wave /t scanlist
			setdatafolder scans
			// popup warning if multiple scans are selected
			if(sum(selwavescanlist)>1)
				doalert /t="Warning" 1, "The changes you have made will apply to multiple scans! Continue?"
				if(v_flag==2)
					break
				endif
			endif
			for(i=0;i<sum(selwavescanlist);i+=1)
				if(i==0)
					findvalue /v=1 /T=.1 /z selwavescanlist // find selected Scan
				else
					findvalue /s=(v_value+1) /v=1 /T=.1 /z selwavescanlist // find next selected Scan
				endif
				setdatafolder $scanlist[v_value][0] // goto selected scan so we can set the notes variable
				svar /z SampleSet
				if(!svar_exists(SampleSet))
					string /g SampleSet
				endif
				SampleSet = sval
				setdatafolder ::
			endfor
			setdatafolder foldersave
			QANT_listNEXAFSscans()
			listbox QANT_listbox_loadedfiles activate
			break
		case -1: // control being killed
			break
	endswitch

	return 0
End
Function MDsort(w,keycol, [reversed])
	Wave w
	variable keycol, reversed
 
	variable type
 
	type = Wavetype(w)
 
	make/Y=(type)/free/n=(dimsize(w,0)) key
	make/free/n=(dimsize(w,0)) valindex
 
	if(type == 0)
		Wave/t indirectSource = w
		Wave/t output = key
		output[] = indirectSource[p][keycol]
	else
		Wave indirectSource2 = w
		multithread key[] = indirectSource2[p][keycol]
 	endif
 
	valindex=p
	duplicate /free valindex, originalindex
 	if(reversed)
 		sort/a/r {key,originalindex},key,valindex
 	else
		sort/a {key,originalindex},key,valindex
 	endif
 
	if(type == 0)
		duplicate/free indirectSource, M_newtoInsert
		Wave/t output = M_newtoInsert
	 	output[][] = indirectSource[valindex[p]][q]
	 	indirectSource = output
	else
		duplicate/free indirectSource2, M_newtoInsert
	 	multithread M_newtoinsert[][] = indirectSource2[valindex[p]][q]
		multithread indirectSource2 = M_newtoinsert
 	endif 
End

Function QANT_ScanListbox(lba) : ListBoxControl
	STRUCT WMListboxAction &lba
	lba.BlockReentry = 1
	Variable row = lba.row
	Variable col = lba.col
	WAVE/T/Z listWave = lba.listWave
	WAVE/Z selWave = lba.selWave
	string foldersave = getdatafolder(1)
	variable /g root:NEXAFS:busy
	nvar busy = root:NEXAFS:busy
	if(busy)
		return 0
	endif
	switch( lba.eventCode )
		case -1: // control being killed
			break
		case 3: // double click
		// moved this from the end of case 5
			busy=1
			variable /g colselected = col
			if(row>dimsize(listwave,0) || row <0)
				break
			endif
			if(colselected==1)
				setvariable QANT_strval_SampleName activate
			elseif(colselected==2)
				setvariable QANT_strval_ScanAngle activate
			elseif(colselected==3)
				setvariable QANT_strval_ScanOther activate
			elseif(colselected==4)
				setvariable QANT_strval_SampleSet activate
			elseif(colselected==5)
				setvariable QANT_strval_Notes activate
			elseif(colselected==10)
				// change the energy offset of selection
				QANT_ChangeEnergySel()
			endif
			//break
		case 1: // mouse down
			busy=1
			if(!(row>=0) || row >dimsize(listwave,0))
				string sortfoldersave = getdatafolder(1)
				setdatafolder root:NEXAFS:
				nvar ScanOrder,LastScanCol
				if(!nvar_exists(ScanOrder))
					variable /g ScanOrder=0
				endif
				if(!nvar_exists(LastScanCol))
					variable /g LastScanCol=nan
				endif
				if(LastScanCol==Col)
					ScanOrder =1-Scanorder
				endif
				LastScanCol= Col
				//do selections again!
				QANT_listNEXAFSscans()
				
			endif
			variable /g colselected = col
			if(row<=dimsize(listwave,0) && row >=0 && lba.eventmod==5)
				
				if(colselected==1)
					setvariable QANT_strval_SampleName activate
				elseif(colselected==2)
					setvariable QANT_strval_ScanAngle activate
				elseif(colselected==3)
					setvariable QANT_strval_ScanOther activate
				elseif(colselected==4)
					setvariable QANT_strval_SampleSet activate
				elseif(colselected==5)
					setvariable QANT_strval_Notes activate
				elseif(colselected==10)
					// change the energy offset of selection
					QANT_ChangeEnergySel()
				endif
			endif
			//break
		case 4: // cell selection
		case 5: // cell selection plus shift key
			busy=1
			svar x_axis = root:NEXAFS:x_axis
			variable modenum = max(whichlistitem(x_axis,QANT_channellistxaxis())+1,1)
			PopupMenu QANT_popup_X_xais win=QANTLoaderPanel,mode=modenum,popvalue=x_axis
	
			setdatafolder root:NEXAFS
			wave/T scanlist
			wave selwave = root:NEXAFS:selwavescanlist
			duplicate /free selwave, selwavescanlist
			selwavescanlist =selwave? 1 : 0
			variable num, numericalvalue
			string list 
			svar normchan, dnormchan
			setdatafolder scans
			variable j
			for(j=0;j<dimsize(selwavescanlist,0);j+=1)
				setdatafolder $scanlist[j][0]
				variable /g selected = selwavescanlist[j]
				setdatafolder ::
			endfor
			setdatafolder root:NEXAFS
			if(sum(selwavescanlist)==1)
				Button QANT_but_LoadDark win=QANTLoaderPanel, disable=0
				if(cmpstr(normchan,"none")&&cmpstr(dnormchan,"none"))
					Button QANT_but_LoadRef win=QANTLoaderPanel, disable=0
				else
					Button QANT_but_LoadRef win=QANTLoaderPanel, disable=2
				endif
				Button QANT_but_Remove win=QANTLoaderPanel, disable=0
				popupmenu QANT_popup_RefSel win=QANTLoaderPanel,  disable=0
				popupmenu QANT_popup_DarkSel win=QANTLoaderPanel,  disable=0
				
				Button QANT_but_NewPeak win=QANTLoaderPanel, disable=0
				Button QANT_but_AddScanToMaterials win=QANTLoaderPanel, disable=0
				Button QANT_but_FitMaterials win=QANTLoaderPanel, disable=0
				Button QANT_but_ExportSelData win=QANTLoaderPanel, disable=0
				PopupMenu QANT_popup_Norm_Channel1 win=QANTLoaderPanel, disable=0
				PopupMenu QANT_popup_Norm_Channel win=QANTLoaderPanel, disable=0
				ListBox QANT_list_Channels win=QANTLoaderPanel, disable=0
				PopupMenu QANT_popup_X_xais win=QANTLoaderPanel, disable=0
				
				setdatafolder scans
				findvalue /t=.1/v=1 selwavescanlist
				setdatafolder $scanlist[v_value][0]
				
				// display extra info if debugging
				wave /t /z extrainfo
				if(waveexists(extrainfo))
					dowindow extrapvdisp
					if(v_flag)
						wave /t oldextrapv = WaveRefIndexed("extrapvdisp", 0,1)
						if(waveexists(oldextrapv))
							removefromtable /w=extrapvdisp oldextrapv
						endif
						DoWindow /T extrapvdisp,"Extra PVs for Last Loaded File : " + scanlist[v_value][0]
					else
						edit /k=1/W=(738,512,1416.75,742.25) /n=extrapvdisp as "Extra PVs for Last Loaded File : " + scanlist[v_value][0]
					endif
					appendtotable/w=extrapvdisp extrainfo
					ModifyTable/w=extrapvdisp format(Point)=1
					ModifyTable/w=extrapvdisp width(extrainfo.d)=83,width[1]=240,width[2]=213,width[3,4]=66
				endif
				// comment out these lines if not wanting this info
				
				variable /g selected = 1
				string /g notes
				setvariable QANT_strval_notes win=QANTLoaderPanel,value=_STR:notes, disable=0,title=""
				string /g SampleName
				setvariable QANT_strval_SampleName win=QANTLoaderPanel,value=_STR:SampleName, disable=0,title=""
				string /g SampleSet
				setvariable QANT_strval_SampleSet win=QANTLoaderPanel,value=_STR:SampleSet, disable=0,title=""
				string /g AngleStr
				if(strlen(Anglestr)>0)
					setvariable QANT_strval_scanAngle win=QANTLoaderPanel,value=_NUM:str2num(AngleStr), disable=0,title=""
				else
					setvariable QANT_strval_scanAngle win=QANTLoaderPanel,value=_STR:"", disable=0,title=""
				endif
				string /g OtherStr
				numericalvalue = str2num(otherstr)
				if(strlen(OtherStr)>0)
					if(numericalvalue*0==0 && strlen(num2str(numericalvalue))>=strlen(otherstr)) // other string is really a number
						setvariable QANT_strval_scanOther win=QANTLoaderPanel,value=_NUM:str2num(OtherStr), disable=0,title=""
					else // treat it as a string
						setvariable QANT_strval_scanOther win=QANTLoaderPanel,value=_STR:OtherStr, disable=0,title=""
					endif
				else // it is empty, so leave the box empty
					setvariable QANT_strval_scanOther win=QANTLoaderPanel,value=_STR:"", disable=0,title=""
				endif
				svar darkscan, refscan
				if(svar_exists(darkscan))
					list = QANT_darklist()
					num = WhichListItem(darkscan, list) +1
					num = num<1? 0 : num
					popupmenu QANT_popup_DarkSel win=QANTLoaderPanel, mode=(num)
				endif
				if(svar_exists(refscan))
					list = QANT_reflist()
					num = WhichListItem(refscan, list) + 1
					num = num<1? 0 : num
					popupmenu QANT_popup_RefSel win=QANTLoaderPanel, mode=(num)
				endif
			elseif(sum(selwavescanlist)==0)
				Button QANT_but_LoadDark win=QANTLoaderPanel, disable=2
				Button QANT_but_LoadRef win=QANTLoaderPanel, disable=2
				Button QANT_but_Remove win=QANTLoaderPanel, disable=2
				Button QANT_but_NewPeak win=QANTLoaderPanel, disable=2
				Button QANT_but_AddScanToMaterials win=QANTLoaderPanel, disable=2
				Button QANT_but_FitMaterials win=QANTLoaderPanel, disable=2
				Button QANT_but_ExportSelData win=QANTLoaderPanel, disable=2
				PopupMenu QANT_popup_Norm_Channel1 win=QANTLoaderPanel, disable=2
				PopupMenu QANT_popup_Norm_Channel win=QANTLoaderPanel, disable=2
				ListBox QANT_list_Channels win=QANTLoaderPanel, disable=2 
				PopupMenu QANT_popup_X_xais win=QANTLoaderPanel, disable=2
				popupmenu QANT_popup_RefSel win=QANTLoaderPanel,  disable=1
				popupmenu QANT_popup_DarkSel win=QANTLoaderPanel,  disable=1
				setvariable QANT_strval_notes win=QANTLoaderPanel,value=_STR:"",disable=1,title=""
				setvariable QANT_strval_scanAngle win=QANTLoaderPanel,value=_STR:"",disable=1,title=""
				setvariable QANT_strval_scanOther win=QANTLoaderPanel,value=_STR:"",disable=1,title=""
				setvariable QANT_strval_SampleSet win=QANTLoaderPanel,value=_STR:"", disable=1,title=""
				setvariable QANT_strval_SampleName win=QANTLoaderPanel,value=_STR:"", disable=1,title=""
			else
				// go through all scans and select the scans that are selected and deselect the others
				setdatafolder scans
				for(j=0;j<dimsize(selwavescanlist,0);j+=1)
					setdatafolder $scanlist[j][0]
					variable /g selected = selwavescanlist[j]
					setdatafolder ::
				endfor
				
				Button QANT_but_LoadDark win=QANTLoaderPanel, disable=0
				if(cmpstr(normchan,"none")&&cmpstr(dnormchan,"none"))
					Button QANT_but_LoadRef win=QANTLoaderPanel, disable=0
				else
					Button QANT_but_LoadRef win=QANTLoaderPanel, disable=2
				endif
				
				Button QANT_but_NewPeak win=QANTLoaderPanel, disable=0
				Button QANT_but_AddScanToMaterials win=QANTLoaderPanel, disable=0
				Button QANT_but_FitMaterials win=QANTLoaderPanel, disable=0
				Button QANT_but_ExportSelData win=QANTLoaderPanel, disable=0
				PopupMenu QANT_popup_Norm_Channel1 win=QANTLoaderPanel, disable=0
				PopupMenu QANT_popup_Norm_Channel win=QANTLoaderPanel, disable=0
				ListBox QANT_list_Channels win=QANTLoaderPanel, disable=0
				PopupMenu QANT_popup_X_xais win=QANTLoaderPanel, disable=0
				
				findvalue /t=.1/v=1 selwavescanlist //CHANGE THIS to 1
				setdatafolder $scanlist[v_value][0]
				svar notes
				setvariable QANT_strval_notes win=QANTLoaderPanel,value=_STR:notes, disable=0,title=""
				svar SampleName
				setvariable QANT_strval_SampleName win=QANTLoaderPanel,value=_STR:SampleName, disable=0,title=""
				svar SampleSet
				setvariable QANT_strval_SampleSet win=QANTLoaderPanel,value=_STR:SampleSet, disable=0,title=""
				svar AngleStr
				if(strlen(Anglestr)>0)
					setvariable QANT_strval_scanAngle win=QANTLoaderPanel,value=_NUM:str2num(AngleStr), disable=0,title=""
				else
					setvariable QANT_strval_scanAngle win=QANTLoaderPanel,value=_STR:"", disable=0,title=""
				endif
				svar OtherStr
				numericalvalue = str2num(otherstr)
				if(strlen(OtherStr)>0)
					if(numericalvalue*0==0 && strlen(num2str(numericalvalue))>=strlen(otherstr)) // other string is really a number
						setvariable QANT_strval_scanOther win=QANTLoaderPanel,value=_NUM:str2num(OtherStr), disable=0,title=""
					else // treat it as a string
						setvariable QANT_strval_scanOther win=QANTLoaderPanel,value=_STR:OtherStr, disable=0,title=""
					endif
				else // it is empty, so leave the box empty
					setvariable QANT_strval_scanOther win=QANTLoaderPanel,value=_STR:"", disable=0,title=""
				endif
				svar darkscan, refscan
				if(svar_exists(darkscan))
					list = QANT_darklist()
					num = WhichListItem(darkscan, list) +1
					num = num<1? 0 : num
					popupmenu QANT_popup_DarkSel win=QANTLoaderPanel, mode=(num)
				else
					print "this is a weird error"
				endif
				if(svar_exists(refscan))
					list = QANT_reflist()
					num = WhichListItem(refscan, list) + 1
					num = num<1? 0 : num
					popupmenu QANT_popup_RefSel win=QANTLoaderPanel, mode=(num)
				endif
			endif
			setdatafolder foldersave
			
			QANT_listNEXAFSscans()
			doupdate
			QANT_replotdata(ontop=2)
			//dowindow /F QANTLoaderPanel
			busy=0
			break
		case 6: // begin edit
			
			break
		case 7: // finish edit
			
			break
		case 13: // checkbox clicked (Igor 6.2 or later)
			break
	endswitch
	busy=0
	return 0
End


Function QANT_popNorm(pa) : PopupMenuControl
	STRUCT WMPopupAction &pa

	switch( pa.eventCode )
		case 2: // mouse up
			Variable popNum = pa.popNum
			String popStr = pa.popStr
			svar normchannel = root:NEXAFS:normChan
			svar dnormchannel = root:NEXAFS:dnormChan
			wave selwavescanlist = root:NEXAFS:selwavescanlist
			duplicate /free selwavescanlist, selwave
			selwave = selwave ? 1 : 0
			normchannel = popstr
			if(cmpstr(normchannel,"none") && cmpstr(dnormchannel,"none") && sum(selwave)>0)
				Button QANT_but_LoadRef win=QANTLoaderPanel, disable=0
			else
				Button QANT_but_LoadRef win=QANTLoaderPanel, disable=2
			endif
			QANT_listNEXAFSscans()
			//QANT_CalcNormalizations("selected")
			break
		case -1: // control being killed
			break
	endswitch

	return 0
End

Function QANT_popDNorm(pa) : PopupMenuControl
	STRUCT WMPopupAction &pa

	switch( pa.eventCode )
		case 2: // mouse up
			Variable popNum = pa.popNum
			String popStr = pa.popStr
			svar dnorm = root:NEXAFS:dnormChan
			dnorm = popstr
			
			svar normchannel = root:NEXAFS:normChan
			svar dnormchannel = root:NEXAFS:dnormChan
			wave selwavescanlist = root:NEXAFS:selwavescanlist
			duplicate /free selwavescanlist, selwave
			selwave = selwave ? 1 : 0
			Dnormchannel = popstr
			if(cmpstr(normchannel,"none") && cmpstr(dnormchannel,"none") && sum(selwave)>0)
				Button QANT_but_LoadRef win=QANTLoaderPanel, disable=0
			else
				Button QANT_but_LoadRef win=QANTLoaderPanel, disable=2
			endif
			QANT_CalcNormalizations("selected")
			QANT_listNEXAFSscans()
			break
		case -1: // control being killed
			break
	endswitch

	return 0
End

function QANT_cleanupXaxis()
	string foldersave = getdatafolder(1)
	setdatafolder root:NEXAFS
	svar x_axis
	wave /t ScanList
	variable j,k
	setdatafolder scans
	string oldwaves
	variable notloaded=0
	for(j=0;j<dimsize(scanlist,0);j+=1)
		setdatafolder scanlist[j][0]
		oldwaves = wavelist("*_old",";","")
		for(k=0;k<itemsinlist(oldwaves);k+=1)
			duplicate /o $stringfromlist(k,oldwaves), $replacestring("_old",stringfromlist(k,oldwaves),"")
			killwaves $stringfromlist(k,oldwaves)
		endfor
		
		wave xwave = $x_axis
		if(!waveexists(xwave))
			notloaded=1
			setdatafolder ::
			continue
		endif
		duplicate xwave, $x_axis+"_old"
		differentiate xwave /d=tempwave
		if(sign(wavemin(tempwave))!=sign(wavemax(tempwave)))
			//check where the zero crossing is
			if(binarysearch(tempwave, 0)<2)
				xwave[0,2]=xwave[3]-(3-p)*(xwave[4]-xwave[3])
			endif
		endif
		killwaves/z tempwave
		setdatafolder ::
	endfor
	if(notloaded)
		print "Warning: Chosen X-Axis is not in all scans"
	endif
	
	setdatafolder foldersave
end

Function QANT_RemoveScanBut(ba) : ButtonControl
	STRUCT WMButtonAction &ba

	switch( ba.eventCode )
		case 2: // mouse up
			// click code here
			QANT_RemoveScan()
			break
		case -1: // control being killed
			break
	endswitch

	return 0
End

Function QANT_LoadDarkBut(ba) : ButtonControl
	STRUCT WMButtonAction &ba

	switch( ba.eventCode )
		case 2: // mouse up
			// click code here
			QANT_LoadDark()
			break
		case -1: // control being killed
			break
	endswitch

	return 0
End

Function QANT_RemoveDarkBut(ba) : ButtonControl
	STRUCT WMButtonAction &ba

	switch( ba.eventCode )
		case 2: // mouse up
			// click code here
			QANT_RemoveDark()
			break
		case -1: // control being killed
			break
	endswitch

	return 0
End

Function QANT_LoadRefBut(ba) : ButtonControl
	STRUCT WMButtonAction &ba

	switch( ba.eventCode )
		case 2: // mouse up
			// click code here
			QANT_LoadRef()
			break
		case -1: // control being killed
			break
	endswitch

	return 0
End

Function QANT_RemoveRefBut(ba) : ButtonControl
	STRUCT WMButtonAction &ba

	switch( ba.eventCode )
		case 2: // mouse up
			// click code here
			QANT_RemoveRef()
			break
		case -1: // control being killed
			break
	endswitch

	return 0
End

function QANT_RemoveScan()
	wave selwavescanlist = root:NEXAFS:selwavescanlist
	duplicate /free selwavescanlist, selwave
	selwave = selwave ? 1 : 0
	wave/t scanlist = root:NEXAFS:scanlist
	variable j
	string foldersave = getdatafolder(1)
	dowindow /k extrapvdisp
	dowindow /k QANT_plot
	for(j=0;j<dimsize(selwave,0);j+=1)
		if(selwave[j])
			setdatafolder root:NEXAFS:scans:
			killdatafolder  $scanlist[j][0]
		endif
	endfor
	selwave=0
	QANT_listNEXAFSscans()
	QANT_replotdata()
	setdatafolder foldersave
	
end

function QANT_LoadDark()
	wave selwavescanlist = root:NEXAFS:selwavescanlist
	duplicate /free selwavescanlist, selwave
	selwave = selwave ? 1 : 0
	
	
	wave/t scanlist = root:NEXAFS:scanlist
	svar x_axis = root:NEXAFS:x_axis
	variable j, k, oldvalue=0
	string foldersave = getdatafolder(1)
	findvalue /v=1 /t=.1 selwave
	if(sum(selwave)>0 && v_value>=0)		
		for(k=0;k<sum(selwave);k+=1)
			findvalue /v=1 /t=.1 /s=(oldvalue+1) selwave
			oldvalue = v_value
			string darkname = scanlist[v_value][0]
			setdatafolder root:NEXAFS:Scans
			setdatafolder darkname
			string darkfolder = getdatafolder(1)
			string channellist = WaveList("*",";", "")
			setdatafolder root:NEXAFS
			newdatafolder /o/s darks
			wave/t darks
			if(datafolderexists(darkname))
				newdatafolder /o/s $uniquename(darkname+"_",11,0)
			else
				newdatafolder /o/s $darkname
			endif
			variable i
			string channelname
			for(i=0;i<itemsinlist(channellist);i+=1)
				channelname = stringfromlist(i, channellist)
				if(stringmatch(channelname,"*columnnames*") || stringmatch(channelname,"*Index*")   || stringmatch(channelname,"*Energy*")  || stringmatch(channelname,"Ring Current")  || stringmatch(channelname,x_axis) || stringmatch(channelname,"*time") )
					continue
				endif
				wave channel = $(darkfolder + possiblyquotename(stringfromlist(i,channellist)))
				variable /g $(possiblyquotename(stringfromlist(i,channellist))+"_mean") = mean(channel)
			endfor
			wave /z xwave = $("root:NEXAFS:Scans:"+possiblyquotename(darkname)+":"+possiblyquotename(x_axis))
			if(waveexists(xwave) && dimsize(xwave,0)>2)
				string /g en_range = num2str(xwave[0])
				variable enrange = xwave[0]
				// gothrough all other references, and if they are set to this range, then unset them
				for(i=0;i<dimsize(darks,0);i+=1)
					if(strlen(darks[i][2])>0 && abs(str2num(darks[i][2])-enrange) < 1.5)
						setdatafolder ::
						setdatafolder darks[i][0]
						string/g en_range=""
					endif
				endfor
			endif
			
			
			
			setdatafolder ::
			QANT_listNEXAFSscans()
		endfor
	endif
	setdatafolder foldersave
end

function QANT_RemoveDark()
	wave darkssel = root:NEXAFS:darks:darkssel
	wave/t darks = root:NEXAFS:darks:darks

	variable i,row=-1
	string foldersave = getdatafolder(1)
	setdatafolder "root:NEXAFS:darks"
	for(i=0;i<dimsize(darkssel,0);i+=1)
		if(darkssel[i][0] & 1 || darkssel[i][1] & 1  || darkssel[i][2] & 1) // row i is selected
			killdatafolder/z darks[i][0]
			row = i
		endif
	endfor
	
	QANT_UpdateDarks()
	if(row<0)
		darkssel[0][0]=3
	elseif(row>=dimsize(darkssel,0))
		darkssel[dimsize(darkssel,0)-1][0]=3
	else
		darkssel[row][0]=3
	endif
	
	dowindow /k QANT_plot
	
	killdatafolder /z root:NEXAFS:DarkCorrected
	QANT_listNEXAFSscans()
	QANT_CalcNormalizations("selected")

	setdatafolder foldersave
end

function QANT_LoadRef()
	wave selwavescanlist = root:NEXAFS:selwavescanlist
	duplicate /free selwavescanlist, selwave
	selwave = selwave ? 1 : 0
	wave/t scanlist = root:NEXAFS:scanlist
	svar x_axis = root:NEXAFS:x_axis
	variable i,j, oldvalue=0, enrange
	string foldersave = getdatafolder(1)
	findvalue /v=1 /t=.1 selwave
	if(sum(selwave)>0 && v_value>=0)
		for(j=0;j<sum(selwave);j+=1)
			findvalue /v=1 /t=.1 /s=(oldvalue+1) selwave
			oldvalue = v_value
			string refname = scanlist[v_value][0]
			wave xwave = $("root:NEXAFS:Scans:"+possiblyquotename(refname)+":"+possiblyquotename(x_axis))
			setdatafolder root:NEXAFS
			newdatafolder /o/s refs
			wave/t refs
			newdatafolder /o/s $refname
			if(waveexists(xwave) && dimsize(xwave,0)>2)
				string /g en_range = num2str(xwave[0])
				enrange = xwave[0]
				// gothrough all other references, and if they are set to this range, then unset them
				for(i=0;i<dimsize(refs,0);i+=1)
					if(!stringmatch(refname,refs[i][0]) && strlen(refs[i][2])>0 && abs(str2num(refs[i][2])-enrange) < 1.5)
						setdatafolder ::
						setdatafolder refs[i][0]
						string/g en_range=""
					endif
				endfor
			endif
			QANT_listNEXAFSscans()
		endfor
	endif
	setdatafolder foldersave
end

function QANT_RemoveRef()
	wave refssel = root:NEXAFS:refs:refssel
	wave/t refs = root:NEXAFS:refs:refs
	string tracelist = TraceNameList("QANT_RefScans_win#G0",";",1)
	variable i
	for(i=itemsinlist(tracelist)-1;i>=0;i-=1)
		removefromgraph/z /w=QANT_RefScans_win#G0 $stringfromlist(i,tracelist)
	endfor
	variable row=-1
	string foldersave = getdatafolder(1)
	setdatafolder "root:NEXAFS:refs"
	for(i=0;i<dimsize(refssel,0);i+=1)
		if(refssel[i][0] & 1 || refssel[i][1] & 1  || refssel[i][2] & 1) // row i is selected
			killdatafolder refs[i][0]
			row = i
		endif
	endfor
	
	//QANT_Updaterefs() // I think this is redundant, it will be done in CalcNormalizations below
	if(row<0)
		refssel[0][0]=1
	elseif(row>=dimsize(refssel,0))
		refssel[dimsize(refssel,0)-1][0]=1
	else
		refssel[row][0]=1
	endif
	
	dowindow /k QANT_plot
	killdatafolder /z root:NEXAFS:DarkCorrected
	QANT_listNEXAFSscans()
	QANT_CalcNormalizations("selected")

	setdatafolder foldersave
end

function QANT_CalcNormalizations(scanstocalc)
	string scanstocalc
	
	QANT_UpdateDarks()

	string foldersave0 = getdatafolder(1)
	setdatafolder root:NEXAFS
	wave /t scanlist
	wave selwave = root:NEXAFS:selwavescanlist
	duplicate /free selwave, selwavescanlist
	if(dimsize(selwave,0)>0)
		selwavescanlist =selwave? 1 : 0
	endif
	wave /t channels = channels
	variable j,k
	
	nvar correctphotodiode  //(divides the spectrum by the energy to the first order, to account for the 3.66 eV * photon / electron produced in the diode
	svar x_axis,normchan, dnormchan
	
	newdatafolder /o/s darks
	variable dodarks  = CountObjects("",4)
	make /o/t/n=(dodarks) darklist=getindexedobjname("",4,p)
	wave/t darks
	wave darkssel
	setdatafolder ::
	
	newdatafolder /o/s refs // we need to change this to look for if there is a reference channel chosen
	variable doref = stringmatch(normchan,"none") || strlen(normchan)==0 ? 0 : 1
	variable numrefs  = CountObjects("",4)
	make /o/t/n=(numrefs) reflist=getindexedobjname("",4,p)
	wave/t refs
	wave refssel
	wave refwaves = root:NEXAFS:refs:refs
	wave matwave = root:NEXAFS:materialslist
	setdatafolder ::
	variable scanisref
	variable scanismaterial
	string datafolder = "root:NEXAFS:Scans" // the data that reference will be divided from (if there is a background, we will use the background subtracted data)
	variable replotdata=0 // set to 1 if anything changes
	if(dodarks)
		newdatafolder /o/s DarkCorrected
		datafolder = "root:NEXAFS:DarkCorrected"

		for(j=0;j<dimsize(scanlist,0);j+=1)
			if(StringMatch(scanstocalc, "selected"))
				
				findvalue /text=scanlist[j][0] /txop=4 refs
				scanisref = v_value==-1 ? 0 : 1
				findvalue /text=scanlist[j][0] /txop=4 matwave
				scanismaterial = v_value==-1 ? 0 : 1
				
				if(selwavescanlist[j]==0 &&scanisref==0 && scanismaterial==0)
					continue
				endif
			elseif(StringMatch(scanstocalc,"all"))
				// do nothing
			elseif(whichlistitem(scanlist[j][0],scanstocalc)>=0)
				// do nothing
			else
				continue
			endif
			newdatafolder /o/s $scanlist[j][0]
			string darktouse = scanlist[j][7] // name of a scan (or default of none)
			wave xwave = $("root:Nexafs:Scans:"+possiblyquotename(scanlist[j][0])+ ":" + possiblyquotename(x_axis))
										// the xwave of the current scan
			findvalue /text=darktouse /txop=4 darklist // finding the supposed darkscan in the list of darkscans (-1 if it isn't a dark)
			if(stringmatch(darktouse,"none"))
				setdatafolder ::
				killdatafolder /z $scanlist[j][0]
				continue
			elseif(stringmatch(darktouse,"Default") || v_value==-1)  					//  we are using the default dark
				if(waveexists(xwave) && dimsize(xwave,0) > 3)  						//  is there a valid xwave for the current scan?
					variable enstart = xwave[0] 									// when was the start energy of the current scan
					make/free /n=(dimsize(darks,0)) enstarts = str2num(darks[p][2]) 	// starting energies of 
					findvalue /t=2 /v=(enstart) enstarts 								// see if there is a default dark for this energy 
					if(v_value>=0)					// if there is one, change darktouse to that dark
						darktouse = darks[v_value][0]
						findvalue /text=darktouse /txop=4 darklist
						if(v_value==-1)
							darktouse = "Default"
						endif
					else
						darktouse = "Default" // otherwise use default dark
					endif
				else
					darktouse = "Default" // if there isn't an x wave, just use the default values
				endif
			endif
			if(stringmatch(darktouse,"Default"))
				make /free /n=(dimsize(darks,0)) darkchecked = darkssel[p][1]==48 ? 1 : 0
				findvalue /v=1 darkchecked // find the dark that is default
				if(v_value>=0)
					darktouse = darks[v_value][0]
					findvalue /text=darktouse /txop=4 darklist
					if(v_value==-1)
						darktouse = "none"
						print "Problem finding a dark default"
						continue // no dark default, no other valid darks to use, so skip
					endif
				else
					darktouse = "none"
					print "Problem finding a dark default"
					continue // no dark default, no other valid darks to use, so skip
				endif
			endif
			if(stringmatch(darktouse,"none"))
				setdatafolder ::
				killdatafolder /z $scanlist[j][0]
				continue
			endif
			
			string darkdirectory = "root:Nexafs:Darks:"+possiblyquotename(darktouse)+":"
			wave xwave = $("root:Nexafs:Scans:"+possiblyquotename(scanlist[j][0])+ ":" + possiblyquotename(x_axis))
			if(waveexists(xwave))
				duplicate/o xwave, $(x_axis) // we can't subtract a dark from the xwave, so go ahead and copy that over
			endif
			wave expwave = $("root:Nexafs:Scans:"+possiblyquotename(scanlist[j][0])+ ":" + "ExpTime")
			if(waveexists(expwave))
				duplicate/o expwave, ExpTime // copy the exptime wave over if it exists
			endif
			wave/t channels = $("root:Nexafs:Scans:"+possiblyquotename(scanlist[j][0])+ ":Columnnames")
			for(k=0;k<dimsize(channels,0);k+=1)
				wave datawave = $("root:Nexafs:Scans:"+possiblyquotename(scanlist[j][0])+":"+possiblyquotename(channels[k]))
				if(waveexists(datawave))
					nvar darkvalue = $(darkdirectory+possiblyquotename(channels[k]+"_mean"))
					duplicate/o datawave, $Channels[k]
					wave newdatawave = $Channels[k]
					if(nvar_exists(darkvalue))
						newdatawave -= darkvalue
						Note newdatawave, "\nDark value of "+ num2str(darkvalue) + " Subtracted from dark: "+darktouse+";"
						replotdata=1
					else
						Note newdatawave, "\nNo Dark Value was Subtracted ;"
					endif
				endif
			endfor
			
			setdatafolder ::
		endfor
	elseif(datafolderexists("root:NEXAFS:DarkCorrected"))
		setdatafolder root:NEXAFS
		dowindow /k QANT_plot
		killdatafolder /z DarkCorrected
		datafolder = "root:NEXAFS:Scans"
		replotdata=1
	endif

	//Correct for exposure time -- not sure if this is at all useful  I've removed the option to even do it from the front panel
	setdatafolder root:NEXAFS
	nvar corexptime
	if(corexptime)
		for(j=0;j<dimsize(scanlist,0);j+=1)
			if(StringMatch(scanstocalc, "selected"))
				findvalue /text=scanlist[j][0] /txop=4 refs
				scanisref = v_value==-1 ? 0 : 1
				findvalue /text=scanlist[j][0] /txop=4 matwave
				scanismaterial = v_value==-1 ? 0 : 1
				if(selwavescanlist[j]==0 &&scanisref==0 && scanismaterial==0)
					continue
				endif
			elseif(StringMatch(scanstocalc,"all"))
				// do nothing
			elseif(whichlistitem(scanlist[j][0],scanstocalc)>=0)
				// do nothing
			else
				continue
			endif
			wave refwave = $(datafolder+":"+possiblyquotename(scanlist[j][0])+ ":" + possiblyquotename(normchan))
			wave exptime = $(datafolder+":"+possiblyquotename(scanlist[j][0])+ ":exptime")
			if(!waveexists(exptime) || !waveexists(refwave))
				continue
			endif
			refwave /=exptime
			Note refwave, "\nExposure time corrected : ;"
			wave/t channels = $("root:Nexafs:Scans:"+possiblyquotename(scanlist[j][0])+ ":Columnnames")
			for(k=0;k<dimsize(channels,0);k+=1)
				if(cmpstr(channels[k],normchan)==0)
					continue
				endif
				wave datawave = $(datafolder+":"+possiblyquotename(scanlist[j][0])+":"+possiblyquotename(channels[k]))
				if(waveexists(datawave))
					datawave /= exptime
					Note datawave, "\nExposure time corrected : ;"
					replotdata=1
				endif
			endfor
		endfor
	endif
	// if there is normalization chosen, and if there is double normalization chosen and a reference file, then load the reference file and divide
	//  normalization wave by the reference wave so create a "normOverref" wave in the NEXAFS directory
	// Next copy all the data (background subtracted if possible) to a new directory, refdivided as above, and in each directory, divide the norm
	//   wave by the normoverref wave, and divide all the data by this refcorrectedwave
	string wnote=""
	variable enoffset
	
	// do the energy (xwave) offsets and (photodiode correction if desired)
	setdatafolder root:NEXAFS
	newdatafolder /o/s EnergyCorrected
	 // energy correcting is always done, but if the column of of Energy Offsets is not filled in yet, nothing is done with that scan
	for(j=0;j<dimsize(scanlist,0);j+=1)
		setdatafolder root:NEXAFS:EnergyCorrected
		newdatafolder /o/s $scanlist[j][0]
		wave xwave = $(datafolder+":"+possiblyquotename(scanlist[j][0])+ ":" + possiblyquotename(x_axis))
		if(!waveexists(xwave))
			wave xwave = $("root:Nexafs:Scans:"+possiblyquotename(scanlist[j][0])+ ":" + possiblyquotename(x_axis))
		endif
		if(!waveexists(xwave))
			continue
		endif
		duplicate/o xwave, $x_axis // these two waves won't be changed by the process
		wave/t channels = $("root:Nexafs:Scans:"+possiblyquotename(scanlist[j][0])+ ":Columnnames")
		for(k=0;k<dimsize(channels,0);k+=1)
			if(cmpstr(channels[k],x_axis)==0)
				continue // if the channel is the normalization channel or the x axis then it's already taken care of, so don't do anything
			endif
			wave datawave = $(datafolder+":"+possiblyquotename(scanlist[j][0])+":"+possiblyquotename(channels[k]))
			if(waveexists(datawave))
				duplicate/o datawave, $Channels[k]
			endif
		endfor
		wave xwave = $x_axis // this is the xwave which we will correct for energy calibration
		enoffset = str2num(scanlist[j][10])
		if(enoffset*0==0) // if energyoffset is a number
			xwave -= enoffset
			note xwave "\nAdjusted values by " + num2str(enoffset) + " to match calibration"
			replotdata=1
		endif
	endfor
	// do any prenormalization calculations on channels, and add pseudo channels here
	datafolder = "root:NEXAFS:EnergyCorrected"
	QANT_UpdateRefs() // this moves the reference scans (now dark and energy corrected appropriately) to a new folder and calculates the double normalization wave vs x
	if(doref)
		setdatafolder root:NEXAFS
		newdatafolder /o/s RefCorrectedData
		for(j=0;j<dimsize(scanlist,0);j+=1)
			if(StringMatch(scanstocalc, "selected"))
				findvalue /text=scanlist[j][0] /txop=4 refs
				scanisref = v_value==-1 ? 0 : 1
				findvalue /text=scanlist[j][0] /txop=4 matwave
				scanismaterial = v_value==-1 ? 0 : 1
				if(selwavescanlist[j]==0 &&scanisref==0 && scanismaterial==0)
					continue
				endif
			elseif(StringMatch(scanstocalc,"all"))
				// do nothing
			elseif(whichlistitem(scanlist[j][0],scanstocalc)>=0)
				// do nothing
			else
				continue
			endif
			string reftouse = scanlist[j][6]
			if(numrefs==0)
				reftouse = "none"
			endif
			wave xwave = $("root:Nexafs:Scans:"+possiblyquotename(scanlist[j][0])+ ":" + possiblyquotename(x_axis))
			// find the reference for double normalization
			findvalue /text=reftouse /txop=4 reflist
			if(!stringmatch(reftouse,"none") && (stringmatch(reftouse,"Default") || v_value==-1)) // is there a chosen reference that exists?
				if(waveexists(xwave) && dimsize(xwave,0)>3)
					variable refenstart = xwave[0]
					make/free /n=(dimsize(refs,0)) refenstarts = str2num(refs[p][2]) // is there a reference which starts within 1.5 eV of the current scan ?
					findvalue /t=1.5 /v=(refenstart) refenstarts
					if(v_value>=0)
						reftouse = refs[v_value][0]
						findvalue /text=reftouse reflist
						if(v_value==-1)
							reftouse = "Default"
						endif
					else
						reftouse = "Default" // if not, use the default reference
					endif
				else
					reftouse = "Default"
				endif
			endif
			if(stringmatch(reftouse,"Default"))
				make /free /n=(dimsize(refs,0)) refchecked = refssel[p][1]==48 ? 1 : 0
				findvalue /v=1 refchecked
				if(v_value>=0)
					reftouse = refs[v_value][0]
					findvalue /text=reftouse reflist
					if(v_value==-1)
						reftouse = "none"
					endif
				else
					reftouse = "none"
				endif
			endif
			// the reference scan which we will use for double normalization is now in "reftouse"
			wnote=""
			
			wave/z oldxwave = $(datafolder+":"+possiblyquotename(scanlist[j][0])+ ":" + possiblyquotename(x_axis))
			wave/z oldrefwave = $(datafolder+":"+possiblyquotename(scanlist[j][0])+ ":" + possiblyquotename(normchan))
			setdatafolder root:NEXAFS:RefCorrectedData
			newdatafolder /o/s $scanlist[j][0]
			if(waveexists(oldxwave))
				duplicate/o oldxwave, $(":" + possiblyquotename(x_axis))
				wave xwave = $(":" + possiblyquotename(x_axis))
			endif
			if(waveexists(oldrefwave))
				duplicate/o oldrefwave, $(":" + possiblyquotename(normchan))
				wave refwave = $(":" + possiblyquotename(normchan))
			endif
			if(cmpstr(reftouse,"none"))
				wave normoverref = $("root:Nexafs:refs:"+possiblyquotename(reftouse)+":normoverref")
				wave xnormoverref = $("root:Nexafs:refs:"+possiblyquotename(reftouse)+":xnormoverref")
			endif
			if(!waveexists(xwave) || !waveexists(refwave) || numpnts(xwave)<10 || numpnts(refwave)<10) // if the reference or xaxis waves aren't big enough this will be useless
				continue
			endif

			wave/t channels = $("root:Nexafs:Scans:"+possiblyquotename(scanlist[j][0])+ ":Columnnames")
			
			if(numpnts(xwave)<numpnts(refwave))
				redimension /n=(numpnts(xwave)) refwave
			endif
			// need to move refwave to the new directory
			if(waveexists(NormOverRef) && waveexists(xNormOverRef))
				refwave /= xwave[p]<wavemin(xnormoverref) || xwave[p]>wavemax(xnormoverref) ? 1 : interp(xwave[p],xnormoverref,normoverref) // double normalize the values within x range of the normalization
				refwave /= xwave[p]<wavemin(xnormoverref) ? normoverref[0] : 1 // double normalize the values outside this value by the extreme values of the normalization 
				refwave /= xwave[p]>wavemax(xnormoverref) ? normoverref[dimsize(normoverref,0)-1] : 1 
			endif
			xwave = refwave[p]*0 != 0 ? nan :xwave[p] // set values to nan in both waves if nan in either wave
			refwave = xwave[p]*0 != 0 ? nan :refwave[p]
			//wavetransform/o zapnans xwave // used to delete nans from the xwave and refwave, now we don't  -- if it becomes a problem, we can add this back in
			//wavetransform/o zapnans refwave
			note refwave "\nReference double normalized by channel :"+dnormchan+"; in scan: " + reftouse + ";"
			wnote = "\nReference double normalized by channel :"+dnormchan+"; in scan: " + reftouse + ";"
			if(numpnts(refwave)<5) // pointless now that we are not removing nans, but that's ok
				setdatafolder ::
				killdatafolder scanlist[j][0]
				continue
			endif
			
			for(k=0;k<dimsize(channels,0);k+=1)
				if(cmpstr(channels[k],normchan)==0 || cmpstr(channels[k],x_axis)==0)
					continue // if the channel is the normalization channel or the x axis then it's already taken care of, so don't do anything
				endif
				wave datawave = $(datafolder+":"+possiblyquotename(scanlist[j][0])+":"+possiblyquotename(channels[k]))
				if(waveexists(datawave))
					duplicate/o datawave, $Channels[k]
					
					wave newdatawave = $Channels[k]
					if(cmpstr(Channels[k], "ExpTime")&&cmpstr(Channels[k], "Ring Current")&&cmpstr(Channels[k], "EnergySetpoint")&&cmpstr(Channels[k], "Index")&&!stringmatch(Channels[k], "*Energy*")&&!stringmatch(Channels[k], "BGsub_*"))
						// these are all channels which should never be normalized (cmpstr is non zero if the two elements are NOT identical)
						if(numpnts(refwave)<numpnts(newdatawave))
							redimension /n=(numpnts(refwave)) newdatawave
						endif
						newdatawave /=refwave
						if(correctphotodiode)
							newdatawave/=xwave
							wnote +="\nCorrected for photodiode responce by dividing by : " + x_axis + ";"
						endif
						
						Note newdatawave, wnote+"\nReference divided : " + normchan + ";"
						replotdata=1
						if(stringmatch(Channels[k],"*_phd_*"))
							newdatawave = -ln(newdatawave) // it it's a diode, we are doing transmission, which we change here to optical density
						elseif(stringmatch(Channels[k],"*mcp*"))
							newdatawave = newdatawave // not sure what to do with the mcp data yet - self absorption needs to be taken into account
						endif
					else
						Note newdatawave, "\nReference was not divided ;"
					endif
				endif
			endfor
			setdatafolder root:NEXAFS:RefCorrectedData
		endfor
		datafolder = "root:NEXAFS:RefCorrectedData"
	elseif(datafolderexists("root:NEXAFS:RefCorrectedData"))
		setdatafolder root:NEXAFS
		dowindow /z qant_plot
		killdatafolder /z RefCorrectedData
		replotdata=1
	endif
	setdatafolder root:NEXAFS
	
	//moving cursor scaling here, rather than after KK calculations, so preedge normalizations are done first
	
	make/free /n=(dimsize(scanlist,0),3) offsets, scales
	make/free /t/n=(dimsize(scanlist,0)) offsetnames
	variable offsetnum=0
	nvar NormCursors,curax,curbx,curcx,curdx, subcursors, LinearPreEdge, ExpPreEdge
	variable offset,normv
	string tempnote =""
	if(replotdata)
		QANT_RePlotData()
	endif
	if((NormCursors || subcursors) && curax*curbx*curcx*curdx*0==0) //&& CalcKK==0) // we can't normalize to cursors if we're doing Kramers Kronig scaling (changed temporarily)
		newdatafolder /o/s NormalizedData
		for(j=0;j<dimsize(scanlist,0);j+=1)
			if(StringMatch(scanstocalc, "selected"))
				findvalue /text=scanlist[j][0] /txop=4 refs
				scanisref = v_value==-1 ? 0 : 1
				findvalue /text=scanlist[j][0] /txop=4 matwave
				scanismaterial = v_value==-1 ? 0 : 1
				//if(selwavescanlist[j]==0 &&scanisref==0 && scanismaterial==0)
				if(selwavescanlist[j]==0 && scanismaterial==0) // if the scan is a material, we should do the same scaling, but for a reference, scaling isn't appropriate, I think
					continue
				endif
			elseif(StringMatch(scanstocalc,"all"))
				// we want to norm this scan
			elseif(whichlistitem(scanlist[j][0],scanstocalc)>=0)
				// we want to norm this scan
			else
				continue
			endif
			wave xwave = $(datafolder+":"+possiblyquotename(scanlist[j][0])+ ":" + possiblyquotename(x_axis))
			
			if(!waveexists(xwave))
				continue
			endif
			newdatafolder /o/s $scanlist[j][0]
			duplicate/o xwave, $x_axis
			wave/t channels = $("root:Nexafs:Scans:"+possiblyquotename(scanlist[j][0])+ ":Columnnames")
			
			for(k=0;k<dimsize(channels,0);k+=1)
				if(cmpstr(channels[k],normchan)==0)
					continue
				endif
				wave datawave = $(datafolder+":"+possiblyquotename(scanlist[j][0])+":"+possiblyquotename(channels[k]))
				wavestats /q/z datawave
				if(waveexists(datawave) &&v_npnts>10)
					duplicate/o datawave, $Channels[k]
					wave newdatawave = $Channels[k]
					if(cmpstr(Channels[k], "ExpTime")&&cmpstr(Channels[k], "Ring Current")&&cmpstr(Channels[k], "EnergySetpoint")&&cmpstr(Channels[k], "Index")&&!stringmatch(Channels[k], "*Energy*"))
						// START CHANGE
						if(subcursors)
							//offset = faveragexy(xwave,newdatawave,curax,curbx)
							if(linearpreedge)
								variable v_fiterror=0
								Variable CFerror
								//try 
									if(ExpPreEdge)
										v_fiterror=0
										curvefit/q/n/w=2 exp newdatawave[binarysearch(xwave,curax),binarysearch(xwave,curbx)] /x=xwave;CFerror=GetRTError(1)//; AbortOnRTE;CFerror= GetRTError(1)
										//v_fiterror=0
									else
										v_fiterror=0
										curvefit/q/n/w=2 line newdatawave[binarysearch(xwave,curax),binarysearch(xwave,curbx)] /x=xwave;CFerror=GetRTError(1)//; AbortOnRTE
										//v_fiterror=0
									endif
								//catch
								//	v_fiterror=0
								//	CFerror = GetRTError(1)
								//endtry
								if(v_fiterror)
									v_fiterror=0
									offset = faveragexy(xwave,newdatawave,curax,curbx)
									newdatawave -= offset
									tempnote = "\nOffset by: " + num2str(offset) + ";"
								else
									wave w_coef
									if(ExpPreEdge)
										newdatawave -= w_coef[0]+w_coef[1]*Exp(-w_coef[2]*xwave)
										tempnote = "\nOffset by: " + num2str(w_coef[0]) +" + " + num2str(w_coef[1])+" * Exp( "+num2str(-w_coef[2])+" * x )"
									else
										newdatawave -= w_coef[0]+w_coef[1]*xwave
										tempnote = "\nOffset by: " + num2str(w_coef[0]) +" + " + num2str(w_coef[1])+" * x"
									endif
								endif
							else
								offset = faveragexy(xwave,newdatawave,curax,curbx)
								newdatawave -= offset
								tempnote = "\nOffset by: " + num2str(offset) + ";"
							endif
						else
							offset =0
							tempnote = "\nNo Offset was chosen;"
						endif
						// END CHANGE
						if(normcursors)
							//normv = interp(curcx,xwave,newdatawave)
							normv =  faveragexy(xwave,newdatawave,curcx,curdx)
							if(normv*0!=0)
							//	print "Normalization problem"
							endif
							newdatawave /= normv
							tempnote += "\nDivided by :"+num2str(normv)+";"
						else
							normv = 1
							tempnote += "\nNo Normalization was selected;"
						endif
						Note newdatawave, tempnote
						if(!cmpstr(Channels[k],"Channeltron"))
							offsets[offsetnum][0] = offset
							scales[offsetnum][0] = normv
						elseif(!cmpstr(Channels[k],"DrainCurrentVF"))
							offsets[offsetnum][1] = offset
							scales[offsetnum][1] = normv
						elseif(!cmpstr(Channels[k],"MCP"))
							offsets[offsetnum][2] = offset
							scales[offsetnum][2] = normv
						endif
						
					else
						Note newdatawave, "\nThis data was not offset or normalized ;"
					endif
				endif
			endfor
			offsetnames[offsetnum] = scanlist[j][0]
			offsetnum+=1
			setdatafolder ::
		endfor
		redimension /n=(offsetnum) offsetnames
		redimension /n=(offsetnum,3) offsets, scales
		replotdata=1
		datafolder = "root:NEXAFS:NormalizedData"
	elseif(datafolderexists("root:NEXAFS:NormalizedData"))
		setdatafolder root:NEXAFS
		dowindow /z qant_plot
		killdatafolder /z NormalizedData
		replotdata=1
	endif
	
	
	
	
	setdatafolder root:NEXAFS
	// calculate KK if possible
	nvar calcKK //Calculates the Kramers Kronig of displayed spectrums if a chemical formula (of the form"CHEMFORM:AaXBbYCcZ" and density of the form (DENSITY:X) are specified in sample set
	 // this will create the molecular scattering factor normalizations and full scale (0-30keV) normalizations and delta, which are all options for plotting
	 // generate warnings if chosen scans do not have chemical formulas
	string chemicalformula, densitystr
	variable density, WarnChemFormula=0, numkkcalc=0
	wave/t channels = root:NEXAFS:Channels
	wave channelsel = root:NEXAFS:ChannelSel
	make /free /wave /n=0 FullRangeBetas, FullRangeDeltas
	if(calcKK)
			//make busy window
		NewPanel/FLT /N=myProgress/W=(285,111,739,193) as "Working..."
		SetDrawLayer UserBack
		DrawText 25,53,"Please do not touch anything during this time,\rCalculations, particularilly Kramers-Kronig Calculations can take some time.."
		SetActiveSubwindow _endfloat_
		DoUpdate/W=myProgress/E=1 // mark this as our progress window
		SetWindow myProgress,hook(spinner)=MySpinnHook
		Variable t0= ticks

		
		
		for(j=0;j<dimsize(scanlist,0);j+=1) // go through all the loaded scans
			if(StringMatch(scanstocalc, "selected"))
				//findvalue /text=scanlist[j][0] /txop=4 refs
				//scanisref = v_value==-1 ? 0 : 1
				findvalue /text=scanlist[j][0] /txop=4 matwave
				scanismaterial = v_value==-1 ? 0 : 1
				if(selwavescanlist[j]==0 &&scanisref==0 && scanismaterial==0)
					continue // we don't want to calcKK for this scan
				endif
			elseif(StringMatch(scanstocalc,"all"))
				// we want to norm this scan
			elseif(whichlistitem(scanlist[j][0],scanstocalc)>=0)
				// we want to norm this scan
			else
				continue
			endif
			wave xwave = $(datafolder+":"+possiblyquotename(scanlist[j][0])+ ":" + possiblyquotename(x_axis))
			 // is there an x_axis wave in this scan folder?
			if(!waveexists(xwave))
				continue
			endif
			splitstring /e="ChemForm:([[:alpha:][:digit:].]*)" scanlist[j][5], chemicalformula // find the chemical formula in the notes
			splitstring /e="Density:([[:alpha:][:digit:].]*)" scanlist[j][5], densitystr
			density = str2num(densitystr)
			if(!strlen(chemicalformula)>1 || numtype(density))
				WarnChemFormula =1
				continue // chemical formula and density are not specified
			endif
			string warningtext = ""
			for(k=0;k<dimsize(channels,0);k+=1)
				if(!cmpstr(channels[k],normchan)||!cmpstr(Channels[k], "ExpTime")||!cmpstr(Channels[k], "Ring Current")||!cmpstr(Channels[k], "EnergySetpoint")||!cmpstr(Channels[k], "Index") || stringmatch(Channels[k], "*Energy*") || stringmatch(Channels[k], "BGsub_*"))
					continue
				endif
				if(!channelsel[k])
					continue
				endif
				wave datawave = $(datafolder+":"+possiblyquotename(scanlist[j][0])+":"+possiblyquotename(channels[k]))
				if(waveexists(datawave))
					// do the kramers kronig transformation/  xwave, datawave, chemicalformula and density are all defined
					if(!datafolderexists("root:AtomicScatteringFactors"))
						loadelementlibrary()
					endif
					if(!datafolderexists("root:AtomicScatteringFactors"))
						warningtext = ""
						warningtext +="***Error, no element library found.  Please download and extract the tar.gz available http://henke.lbl.gov/optical_constants/asf.html\r"
						warningtext +="    to the \"Atomic Scattering Factors\" directory in User Procedures\r"
						DoAlert /T="Kramers Krong Calculation" 0, warningtext
						if(numkkcalc==0)
							calckk=0
							STRUCT WMCheckboxAction cba1
							cba1.eventcode=2
							QANT_AdvPanel_CheckProc(cba1)
							dowindow /f QANT_AdvPanel
							warnchemformula=0
						endif
						break // there is something wrong with the atomic scattering factors
					endif
					wave bareatommu = GetBareAtomMu(chemicalformula) // creates and links to a wave in the nexafs/bateatomapectra direectory
					if(!waveexists(bareatommu))
						continue
					endif
					wave FullRangeF2 = SpliceintoF2(bareatommu, datawave, xwave) // creates new directory in NEXAFS/spliced/ that has the same scan name as the beta wave, with the same name as the beta wave
					wave FullRangeF1 = f1wavefromf2(FullRangeF2, density) // the energy wave is in the x scaling of the wave, so no need to keep that
					duplicate /free FullRangeF1, FullRangeEnergy
					Fullrangeenergy=x
					wave FullRangeBeta = F2toBeta(FullRangeF2, FullRangeEnergy, density)
					wave FullRangeDelta = F1toDelta(FullRangeF1, FullRangeEnergy, density)
					wave ScaledBeta = EnRangeBeta(FullRangeBeta, FullRangeEnergy, xwave)
					wave ScaledDelta = EnRangeDelta(FullRangeDelta, FullRangeEnergy, xwave)
					numkkcalc +=1
					replotdata=1
					if(numkkCalc>0)
						insertpoints inf,1,FullRangeBetas, FullrangeDeltas
						FullRangeBetas[inf] = FullRangeBeta
						FullRangeDeltas[inf] = FullRangeDelta
					endif
				endif
			endfor
		endfor
		if(warnchemformula)
			warningtext = ""
			warningtext +="***WARNING: Chemical Formula or Density were not specified for at least one selected scan, or designated material\r"
			warningtext +="     It is required that you specify the chemical formula (i.e. C42H7N9) and density (g/ml) to complete this calculation\r"
			DoAlert /T="Kramers Krong Calculation" 0, warningtext
			warningtext +="     Do this in the \"notes\" for the scan by adding somewhere the text \"ChemForm:\" followed directly by the chemical formula\r"
			warningtext +="       including only Element abbreviations (C, He, Br etc) and numbers and \"Density:\" followed immediately by a number, with no spaces\r"
			warningtext +="     If \"Calculate Kramers Kronig\" is chosen, ONLY those scans with enough information to complete the calculation will be shown"
			print warningtext
			if(numkkcalc==0)
				calckk=0
				STRUCT WMCheckboxAction cba
				cba.eventcode=2
				QANT_AdvPanel_CheckProc(cba)
				dowindow /f QANT_AdvPanel
			endif
		endif
		// old method, when only contrasts of two materials were calculated
//		if(0)//numKKcalc==2)
//			newdatafolder /o/s root:NEXAFS:ContrastFunctions
//			newdatafolder /o/s $(getwavesdatafolder(FullRangeBeta1,0) + getwavesdatafolder(FullRangeBeta,0))
//			duplicate/o FullRangeBeta1, $nameofwave(FullRangeBeta1)
//			wave contrast = $nameofwave(FullRangeBeta1)
//			contrast = (FullRangeBeta1-FullRangeBeta)^2 + (FullRangeDelta1-FullRangeDelta)^2 * x^4
//			
//			newdatafolder /o/s ::$(getwavesdatafolder(FullRangeBeta1,0) + "vac")
//			duplicate/o FullRangeBeta1, $nameofwave(FullRangeBeta1)
//			wave vaccontrast1 = $nameofwave(FullRangeBeta1)
//			vaccontrast1 = (FullRangeBeta1)^2 + (FullRangeDelta1)^2 * x^4
//			
//			newdatafolder /o/s ::$(getwavesdatafolder(FullRangeBeta,0) + "vac")
//			duplicate/o FullRangeBeta, $nameofwave(FullRangeBeta)
//			wave vaccontrast2 = $nameofwave(FullRangeBeta)
//			vaccontrast2 = (FullRangeBeta)^2 + (FullRangeDelta)^2 * x^4
//			
//			dowindow /k QANT_Contrast
//			svar samplename1 = $("root:NEXAFS:Scans:"+getwavesdatafolder(FullRangeBeta1,0)+":SampleName")
//			svar samplename2 = $("root:NEXAFS:Scans:"+getwavesdatafolder(FullRangeBeta,0)+":SampleName")
//			display /k=1 /n=QANT_Contrast contrast /tn=$(samplename1 +"_"+ samplename2), vaccontrast1 /tn=$(samplename1 +"_Vacuum"), vaccontrast2 /tn=$(samplename2 +"_Vacuum") as "Calculated Contrast functions"
//			ModifyGraph /w=QANT_Contrast log=1, rgb[0]=(0,0,0), rgb[1]=(0,50000,0), rgb[2]=(0,0,50000)
//			ModifyGraph /w=QANT_Contrast tick=2,mirror=1,minor=1,standoff=0;DelayUpdate
//			Label /w=QANT_Contrast left "Scattering Contrast";DelayUpdate
//			Label /w=QANT_Contrast bottom "X-ray Energy [\\u]"
//			SetAxis /w=QANT_Contrast /A=2 left
//			SetAxis /w=QANT_Contrast bottom 100,2000
//			ModifyGraph /w=QANT_Contrast lsize=1
//			Legend/w=QANT_Contrast /C/N=text0/A=RT
//			ModifyGraph/w=QANT_Contrast grid(bottom)=1
//			ModifyGraph log(left)=0
//		endif
		if(numKKcalc>1)
			variable i=0
			variable numcontrasts = numKKcalc * (numKKCalc+1)/2 // always include vacuum, which is zero
			make /free /t /n=(numcontrasts) contwavefldr1, contwavefldr2, sname1, sname2
			make /free /wave /n=(numcontrasts) contdelta1,contbeta1,contdelta2, contbeta2
			k=0
			duplicate/free FullRangeDeltas[i], vacdelta, vacbeta
			vacdelta=0
			vacbeta=0
			
			for(i=0;i<numKKcalc;i+=1)
				for(j=numKKcalc;j>i;j-=1)
					if(i==numKKcalc)
						sname1[k] = "vac"
						contwavefldr1[k] = "vac"
						contdelta1[k] = vacdelta
						contbeta1[k] = vacbeta
					else
						svar samplename = $("root:NEXAFS:Scans:"+getwavesdatafolder(FullRangeBetas[i],0)+":SampleName")
						svar /z AngleStr = $("root:NEXAFS:Scans:"+getwavesdatafolder(FullRangeBetas[i],0)+":AngleStr") 
						sname1[k] = samplename+ AngleStr
						contwavefldr1[k] = getwavesdatafolder(FullRangeBetas[i],0)
						contdelta1[k] = FullRangeDeltas[i]
						contbeta1[k] = FullRangeBetas[i]
					endif
					if(j==numKKcalc)
						sname2[k] = "vac"
						contwavefldr2[k] = "vac"
						contdelta2[k] = vacdelta
						contbeta2[k] = vacbeta
					else
						svar samplename = $("root:NEXAFS:Scans:"+getwavesdatafolder(FullRangeBetas[j],0)+":SampleName")
						svar /z AngleStr = $("root:NEXAFS:Scans:"+getwavesdatafolder(FullRangeBetas[j],0)+":AngleStr") 
						sname2[k] = samplename + AngleStr
						contwavefldr2[k] = getwavesdatafolder(FullRangeBetas[j],0)
						contdelta2[k] = FullRangeDeltas[j]
						contbeta2[k] = FullRangeBetas[j]
					endif
					k+=1
				endfor
			endfor
			getaxis /q /w=QANT_plot bottom
			variable minen = v_min
			variable maxen = v_max
			string colorstr, tracename
			variable red, blue, green
			dowindow /k QANT_deltabeta
			display /W=(32,428,427,878)/k=1 /n=QANT_deltabeta as "delta vs beta"
			//string tracelist = tracenamelist("QANT_plot",1)
			variable minp, maxp
			nvar dispdelta = root:NEXAFS:dispdelta
			for(i=0;i<numKKcalc;i+=1)
				wave deltaw = fullrangedeltas[i]
				wave betaw = fullrangebetas[i]
				
				svar /z AngleStr = $("root:NEXAFS:Scans:"+getwavesdatafolder(deltaw,0)+":AngleStr") 
				svar /z otherStr = $("root:NEXAFS:Scans:"+getwavesdatafolder(deltaw,0)+":otherStr")
				svar samplename = $("root:NEXAFS:Scans:"+getwavesdatafolder(deltaw,0)+":SampleName")
				
				tracename = cleanupname(samplename+"_"+Anglestr+"deg_"+otherStr+"_"+nameofwave(deltaw),0)
				if(dispdelta)
					tracename = cleanupname(samplename+"_"+Anglestr+"deg_"+otherStr+"_"+"delta"+"_"+nameofwave(deltaw),0)
				endif
				
				minp = round(x2pnt(deltaw,minen))
				maxp = round(x2pnt(deltaw,maxen))
				appendtograph /w=QANT_deltabeta deltaw[minp,maxp] /tn=$tracename vs betaw[minp,maxp]
				
				colorstr = stringbykey("RGB(x)",traceinfo("QANT_plot",tracename,0),"=",";")
				sscanf colorstr, "(%d,%d,%d)",red,blue,green
				modifygraph /w=QANT_deltabeta rgb($tracename)=(red,blue,green)
				
			endfor
			svar ctable = root:NEXAFS:Colortable
			//QANT_ColorTraces(ctable,"QANT_deltabeta")
			ModifyGraph/w=QANT_deltabeta height={Plan,1,left,bottom}, gfsize=16,margin(left)=55,margin(bottom)=55
			Label /w=QANT_deltabeta left "Dispersion [delta] \\u"
			Label /w=QANT_deltabeta bottom "Absorption [beta] \\u"
			SetAxis /w=QANT_deltabeta /A=2 left
			SetAxis /w=QANT_deltabeta bottom 0,*
			ModifyGraph/w=QANT_deltabeta grid=1,tick=2,mirror=1,standoff=0
			
			newdatafolder /o/s root:NEXAFS:ContrastFunctions
			dowindow /k QANT_Contrast
			display /k=1 /n=QANT_Contrast /W=(611,38,1541,397) as "Calculated Contrast functions"
		//	dowindow /k QANT_Contrastvis
		//	display /k=1 /n=QANT_Contrastvis as "delta vs beta plots"
			for(i=0;i<numcontrasts;i+=1)
				setdatafolder root:NEXAFS:ContrastFunctions
				newdatafolder /o/s $(contwavefldr1[i] + contwavefldr2[i])
				if(cmpstr(nameofwave(contdelta1[i]),"vacdelta"))
					duplicate/o contdelta1[i], $nameofwave(contdelta1[i])
					wave contrast = $nameofwave(contdelta1[i])
				else
					duplicate/o contdelta2[i], $nameofwave(contdelta2[i])
					wave contrast = $nameofwave(contdelta2[i])
				endif
				wave del1 = contdelta1[i]
				wave bet1 = contbeta1[i]
				wave del2 = contdelta2[i]
				wave bet2 = contbeta2[i]
				
				contrast = ((del1-del2)^2 + (bet1-bet2)^2 )* x^4
				
				appendtograph /w=QANT_Contrast contrast /tn=$(sname1[i] +"_"+ sname2[i]) 
				if(cmpstr(sname2[i],"vac"))
					modifygraph /w=QANT_Contrast lstyle[i]=0, lsize[i]=2
				else
					modifygraph /w=QANT_Contrast lstyle[i]=3, lsize[i]=1
				endif
			endfor
			ModifyGraph /w=QANT_Contrast tick=2,mirror=1,minor=1,standoff=0,log=1
			Label /w=QANT_Contrast left "Scattering Contrast"
			Label /w=QANT_Contrast bottom "X-ray Energy [\\u]"
			SetAxis /w=QANT_Contrast /A=2 left
			Legend/w=QANT_Contrast /C/N=text0/A=RT
			ModifyGraph/w=QANT_Contrast grid(bottom)=1
			setaxis /w=QANT_Contrast bottom minen, maxen
			QANT_ColorTraces("SpectrumBlack","QANT_Contrast")
			doupdate
			QANT_FindInterestingContrasts(graph=0,graphname="QANT_Contrast")
			
			SetWindow QANT_Contrast, hook(mousemoved)=qant_contrasthook
			SetWindow QANT_deltabeta, hook(mouseclicked)=qant_deltabetahook
			SetWindow QANT_contrast_table, hook(selection)=qant_contrasttablehook
			
			
		endif
		//close busy window
		Variable timeperloop= (ticks-t0)/(60)
		KillWindow myProgress
		print "Calculation time =",timeperloop
	endif
	// end of Kramers Kronig Calc
	// this is where to do all channel math and Scan math, so that the results can be scaled. v2.0
	
	// do any post normalization calculations here and add further pseudo channels
	if(replotdata)
		QANT_RePlotData()
	endif
	// process any pseudo scans which are selected
	setdatafolder foldersave0
	

end

Function QANT_ChannelSelectionListBox(lba) : ListBoxControl
	STRUCT WMListboxAction &lba
	lba.BlockReentry = 1
	Variable row = lba.row
	Variable col = lba.col
	WAVE/T/Z listWave = lba.listWave
	WAVE/Z selWave = lba.selWave

	switch( lba.eventCode )
		case -1: // control being killed
			break
		case 1: // mouse down
			break
		case 3: // double click
			break
		case 4: // cell selection
		case 5: // shift cell selection
			QANT_recordchosenchannels()
			QANT_replotdata()
			break
		case 6: // begin edit
			break
		case 7: // finish edit
			break
		case 13: // checkbox clicked (Igor 6.2 or later)
			break
	endswitch

	return 0
End
function QANT_recordchosenchannels()
	// record the channel names which are chosen
	svar ChannelSelection = root:NEXAFS:ChannelSelection
	if(!svar_exists(channelselection))
		string foldersave = getdatafolder(1)
		setdatafolder root:nexafs
		string/g ChannelSelection
		setdatafolder foldersave
	endif
	wave/t channels = root:NEXAFS:Channels
	wave channelsel = root:NEXAFS:Channelsel
	variable i
	for(i=0;i<dimsize(channels,0);i+=1)
		if(channelsel[i])
			if(whichlistitem(channels[i],channelselection)>=0)
				continue
			else
				channelselection += channels[i] + ";"
			endif
		else
			if(whichlistitem(channels[i],channelselection)>=0)
				channelselection = removelistitem(whichlistitem(channels[i],channelselection),channelselection)
			else
				continue
			endif
		endif
	endfor
	// if the channel is still an option, but not selected, then remove it from the list, otherwise keep it on the list
	
	
end
function QANT_CorrectChannelSelection()
	// if there is a recorded list of channels which were selected, then correct the current selection wave to have those selected channels again
	//removing from the list channels which are no longer options??  or leaving them in case they are chosen again? - choosing latter for now
	svar ChannelSelection = root:NEXAFS:ChannelSelection
	if(!svar_exists(channelselection))
		QANT_recordchosenchannels()
		return 0
	endif
	wave/t channels = root:NEXAFS:Channels
	wave channelsel = root:NEXAFS:Channelsel
	variable i
	for(i=0;i<dimsize(channels,0);i+=1)
		if(whichlistitem(channels[i],channelselection)>=0)
			channelsel[i]=1
		else
			channelsel[i]=0
		endif
	endfor
end

function QANT_replotdata([nochangeofplot,ontop])
	variable nochangeofplot // if non zero, then we assume that the traces on the plot will stay the same, and se won't recreate the whole thing
	variable ontop // if 0, don't put either window ontop, if 1 put the plot window on top, if 2 put  QANTLoaderPanel on top
	variable j,k
	string foldersave = getdatafolder(1)
	nochangeofplot = paramisdefault(nochangeofplot) ? 0 : nochangeofplot

	setdatafolder root:NEXAFS
	svar x_axis
	if(!svar_exists(x_axis) || !cmpstr(x_axis,"none"))
		return 0
	endif
	wave /t scanlist
	wave selwave = root:NEXAFS:selwavescanlist
	duplicate /free selwave, selwavescanlist
	selwavescanlist =selwave? 1 : 0
	QANT_CorrectChannelSelection()
	wave /t channels
	wave channelsel
	nvar cura, curb, curc, curd, curax, curbx, curcx, curdx
	nvar thickness,cursormoving
	if(cursormoving)
		//return 0
		nochangeofplot=1
	endif
	if(nvar_exists(thickness)==0)
		variable /g thickness=1.5
	endif
	thickness = thickness < 1 ? 1 : thickness
	thickness = thickness > 5 ? 5 : thickness
	variable oldcura = cura*0==0 ? cura : .01
	variable oldcurb = curb*0==0 ? curb : .11
	variable oldcurc = curc*0==0 ? curc : .90
	variable oldcurd = curd*0==0 ? curd : .98
	
	variable minxaxis = nan
	variable maxxaxis = nan
		
	svar colortable
	dowindow QANT_Plot
	variable newwindow = 0
	if(v_flag==0 )
		newwindow =1
		display /hide=1 /k=1 /n=QANT_plot as "plot of NEXAFS Channels"
	elseif(nochangeofplot==0)
		SetWindow QANT_plot, hook(cursormoved)=$""
		setwindow QANT_plot, hook(taghook)=$""
		getaxis /w=QANT_plot /Q bottom
		minxaxis = v_min
		maxxaxis = v_max
		string listoftraces = tracenamelist("QANT_plot",";",1)
		for(j=itemsinlist(listoftraces)-1;j>=0;j-=1)
			removefromgraph/w=QANT_plot /z $stringfromlist(j,listoftraces)
		endfor
	endif
	if(sum(channelsel)*sum(selwavescanlist)==0)
		dowindow /k QANT_Plot
		return 0
	endif
	
	make/free /n=(sum(channelsel)) stylesperchan
	make/free /n=(sum(selwavescanlist),3) colorsperscan
	make/free /n=(sum(selwavescanlist)) anglesofscans, scannumbers, otherofscans, scanorder
	stylesperChan = mod(p,17)
	
	Colortab2wave $colortable
	wave m_colors
	setscale/i x, 0, sum(selwavescanlist), m_colors
	colorsperScan = m_colors(p)[q]
	svar x_axis,normchan,darkscan
	nvar calcKK, DispStitched, DispDelta
	string betafolder=""
	string deltafolder=""
	//v2.0 change this to elseif
	// add in if raw data is checked only display the raw data
	if(calcKK && datafolderexists("ExtendedDelta"))
		if(DispStitched)
			if(DispDelta)
				setdatafolder ExtendedDelta
				deltafolder = getdatafolder(1)
				setdatafolder ::ExtendedBeta
				betafolder = getdatafolder(1)
			else
				setdatafolder ExtendedBeta
			endif
		else
			if(DispDelta)
				setdatafolder ScaledDelta
				deltafolder = getdatafolder(1)
				setdatafolder ::ScaledBeta
				betafolder = getdatafolder(1)
			else
				setdatafolder ScaledBeta
			endif
		endif
	else
		if(datafolderexists("Normalizeddata"))
			setdatafolder NormalizedData
		elseif(datafolderexists("RefCorrecteddata") && cmpstr(normchan,"none"))
			setdatafolder RefCorrectedData
		elseif(datafolderexists("EnergyCorrected"))
			setdatafolder EnergyCorrected
		elseif(datafolderexists("DarkCorrected"))
			setdatafolder DarkCorrected
		else
			setdatafolder scans
		endif
	endif
	variable channum=0
	variable scannum=0
	string lastplotted
	string title
	k=0
	for(j=0;j<dimsize(scanlist,0);j+=1) // go through and find the selected scans, and the associated angles, so we can sort them according to angle
		if(selwavescanlist[j]&&datafolderexists(scanlist[j][0]))
			svar /z AngleStr = $("root:NEXAFS:Scans:"+possiblyquotename(scanlist[j][0])+":AngleStr") 
			svar /z otherStr = $("root:NEXAFS:Scans:"+possiblyquotename(scanlist[j][0])+":otherStr") 
			if(svar_exists(Anglestr))
				anglesofscans[k]=str2num(AngleStr)
				otherofscans[k]=str2num(otherStr)
			else
				anglesofscans[k]=0
				otherofscans[k]=0
			endif
			scanorder[k]=k
			scannumbers[k] = j
			k+=1
		endif
	endfor
	sort {anglesofscans,otherofscans,scanorder}, scannumbers, anglesofscans, otherofscans, scanorder
	variable jloop
	string channelforlabel
	for(jloop=0;jloop<numpnts(scannumbers);jloop+=1)
			j=scannumbers[jloop]
			if(!datafolderexists(scanlist[j][0]))
				continue
			endif
			setdatafolder scanlist[j][0]
			wave xwave = $x_axis
			if(!waveexists(xwave) && !DispStitched) // if stitching, we won't use the xaxis
				setdatafolder ::
				continue
			endif
			channum=0
			for(k=0;k<dimsize(channels,0);k+=1)
				wave datawave = $channels[k]
				svar SampleName = $(":::Scans:"+possiblyquotename(scanlist[j][0])+":SampleName") 
				svar AngleStr = $(":::Scans:"+possiblyquotename(scanlist[j][0])+":AngleStr") 
				svar OtherStr = $(":::Scans:"+possiblyquotename(scanlist[j][0])+":OtherStr") 
				if(svar_exists(SampleName) && strlen(SampleName)>1)
					title = SampleName
				else
					title = scanlist[j][0]
				endif
					if(svar_exists(anglestr) && strlen(anglestr)>0)
					title +="_"+Anglestr+"deg"
				endif
				if(svar_exists(Otherstr) && strlen(Otherstr)>0)
					title +="_"+Otherstr
				endif
				if(dispdelta)
					title +="_beta"
				endif
				title = cleanupname(title,1)
				if(channelsel[k])
					if(waveexists(datawave))
						if(!nochangeofplot)
							if(dispstitched)
								appendtograph /w=QANT_plot /c=(colorsperscan[scannum][0],colorsperscan[scannum][1],colorsperscan[scannum][2]) $channels[k] /TN=$(title +"_"+channels[k])
							else
								appendtograph /w=QANT_plot /c=(colorsperscan[scannum][0],colorsperscan[scannum][1],colorsperscan[scannum][2]) $channels[k] /TN=$(title +"_"+channels[k]) vs xwave
							endif
							modifygraph /w=QANT_plot lStyle($(title +"_"+channels[k]))=stylesperchan[channum]
							modifygraph /w=QANT_plot lSize($(title +"_"+channels[k]))=1, lsize = thickness
							channum+=1
						endif
							lastplotted = (title+"_"+channels[k])
					else
						wave datawave = root:NEXAFS:Scans:$channels[k] // channel may not have been corrected (ie HOPG or Ring current)
						if(waveexists(datawave))
							if(!nochangeofplot)
								appendtograph /w=QANT_plot /c=(colorsperscan[scannum][0],colorsperscan[scannum][1],colorsperscan[scannum][2]) $channels[k] /TN=$(title +"_"+channels[k]) vs xwave
								modifygraph /w=QANT_plot lStyle($(title+"_"+channels[k]))=stylesperchan[channum]
								modifygraph /w=QANT_plot lSize($(title+"_"+channels[k]))=1, lsize = thickness
								channum+=1
							endif
							lastplotted = (title+"_"+channels[k])
						endif
					endif
				endif		
			endfor
			if(dispdelta && calcKK && !nochangeofplot) // do it again for the delta values
				setdatafolder deltafolder
				setdatafolder scanlist[j][0]
				wave xwave = $x_axis
				if(!waveexists(xwave) && !DispStitched) // if stitching, we won't use the xaxis
					setdatafolder ::
					continue
				endif
				channum=0
				for(k=0;k<dimsize(channels,0);k+=1)
					wave datawave = $channels[k]
					svar SampleName = $(":::Scans:"+possiblyquotename(scanlist[j][0])+":SampleName") 
					svar AngleStr = $(":::Scans:"+possiblyquotename(scanlist[j][0])+":AngleStr") 
					svar OtherStr = $(":::Scans:"+possiblyquotename(scanlist[j][0])+":OtherStr") 
					if(svar_exists(SampleName) && strlen(SampleName)>1)
						title = SampleName
					else
						title = scanlist[j][0]
					endif
						if(svar_exists(anglestr) && strlen(anglestr)>0)
						title +="_"+Anglestr+"deg"
					endif
					if(svar_exists(Otherstr) && strlen(Otherstr)>0)
						title +="_"+Otherstr
					endif
					if(dispdelta)
						title +="_delta"
					endif
					title = cleanupname(title,1)
					if(channelsel[k])
						if(waveexists(datawave))
							if(dispstitched)
								appendtograph /w=QANT_plot /c=(colorsperscan[scannum][0],colorsperscan[scannum][1],colorsperscan[scannum][2]) $channels[k] /TN=$(title +"_"+channels[k])
							else
								appendtograph /w=QANT_plot /c=(colorsperscan[scannum][0],colorsperscan[scannum][1],colorsperscan[scannum][2]) $channels[k] /TN=$(title +"_"+channels[k]) vs xwave
							endif
							channelforlabel = channels[k]
							modifygraph /w=QANT_plot lStyle($(title +"_"+channels[k]))=5
							modifygraph /w=QANT_plot lSize($(title +"_"+channels[k]))=1, lsize = thickness
							channum+=1
							lastplotted = (title+"_"+channels[k])
						else
							wave datawave = root:NEXAFS:Scans:$channels[k] // channel may not have been corrected (ie HOPG or Ring current)
							if(waveexists(datawave))
								appendtograph /w=QANT_plot /c=(colorsperscan[scannum][0],colorsperscan[scannum][1],colorsperscan[scannum][2]) $channels[k] /TN=$(title +"_"+channels[k]) vs xwave
								modifygraph /w=QANT_plot lStyle($(title+"_"+channels[k]))=stylesperchan[channum]
								modifygraph /w=QANT_plot lSize($(title+"_"+channels[k]))=1, lsize = thickness
								channum+=1
								lastplotted = (title+"_"+channels[k])
							endif
						endif
					endif
				endfor
				setdatafolder betafolder
				setdatafolder scanlist[j][0]
			endif
			scannum+=1
			setdatafolder ::
		
	endfor
	if(Itemsinlist(tracenamelist("QANT_plot",";",1))==0)
		SetWindow QANT_plot, hook(cursormoved)=$""
		setwindow QANT_plot, hook(taghook)=$""
		dowindow /k QANT_plot
	elseif(!nochangeofplot)
		dowindow /hide=0 QANT_plot
		SetWindow QANT_plot, hook(cursormoved)=$""
		setwindow QANT_plot, hook(taghook)=$""
		Cursor/w=QANT_plot /S=2/H=2/L=0 /C=(0,43520,65280)/F/P A $lastplotted  oldcura,.5
		Cursor/w=QANT_plot /S=2/H=2/L=0 /C=(0,43520,65280)/F/P B $lastplotted  oldcurb,.5
		Cursor/w=QANT_plot /S=2/H=2/L=0 /C=(0,0,0)/F/P C $lastplotted oldcurc,.5
		Cursor/w=QANT_plot /S=2/H=2/L=0 /C=(0,0,0)/F/P D $lastplotted oldcurd,.5
		
		
		
		
		
		SetAxis /w=QANT_plot/A=2 left
		modifygraph/w=QANT_plot log(bottom)=1
		ModifyGraph/w=QANT_plot grid(left)=2,grid(bottom)=1,tick=2,mirror=1,minor=1,standoff=1;DelayUpdate
		ModifyGraph/w=QANT_plot gridStyle=3, lsize = thickness
		ModifyGraph/w=QANT_plot gridRGB(left)=(56576,56576,56576),gridRGB(bottom)=(52224,52224,52224)
		SetWindow QANT_plot, hook(cursormoved)=QANT_CursorHook
		setwindow QANT_plot, hook(taghook)=TagWindowHook
		Label/w=QANT_plot bottom X_AXIS
		
		if(sum(channelsel)==1&&strlen(channelforlabel)>0)
			label/w=QANT_plot left channelforlabel
		endif
		Legend/w=QANT_plot/C/N=text0
		doupdate/w=QANT_plot
		cura = pcsr(A,"QANT_plot")
		curb = pcsr(B,"QANT_plot")
		curc = pcsr(C,"QANT_plot")
		curd = pcsr(D,"QANT_plot")

		
	endif
	dowindow QANT_plot
	if(v_flag)
		curax = hcsr(A,"QANT_plot")
		curbx = hcsr(B,"QANT_plot")
		curcx = hcsr(C,"QANT_plot")
		curdx = hcsr(D,"QANT_plot")
		setdrawlayer/w=QANT_plot /k userback
		if(!calcKK)
			
			SetDrawEnv/w=QANT_plot xcoord= bottom,linefgc= (49151,60031,65535),fillfgc= (49151,60031,65535),fillpat= 3,linethick= 0.00
			DrawRect/w=QANT_plot curax,0,curbx,1
			SetDrawEnv/w=QANT_plot xcoord= bottom,linefgc= (49151,49151,49151),fillfgc= (49151,49151,49151),fillpat= 3,linethick= 0.00
			DrawRect/w=QANT_plot curcx,0,curdx,1
		endif
	endif
	variable plotted=0
	if(Itemsinlist(tracenamelist("QANT_plot",";",1))==1)
		plotted=1
		wave ywave = tracenametowaveref("QANT_plot",stringfromlist(0,tracenamelist("QANT_plot",";",1)))
		wave xwave = xwavereffromtrace("QANT_plot",stringfromlist(0,tracenamelist("QANT_plot",";",1)))
		string infowave
		if(waveexists(xwave))
			infowave = "Y Axis : "+ replacestring("\r\r",replacestring("\r\r",replacestring(";",replacestring("\n",nameofwave(ywave)+":\r"+note(ywave)+"\r--------------------\r"+"X Axis : "+  nameofwave(xwave)+":\r" + note(xwave),"\r"),"\r"),"\r"),"\r")
		else
			infowave = "Y Axis : "+  replacestring("\r\r",replacestring("\r\r",replacestring(";",replacestring("\n",nameofwave(ywave)+":\r"+note(ywave),"\r"),"\r"),"\r"),"\r")
		endif
		if(cmpstr(infowave[0],"\r")==0)
			infowave = infowave[1,strlen(infowave)-1]
		endif
		if(cmpstr(infowave[strlen(infowave)-1],"\r")==0)
			infowave = infowave[0,strlen(infowave)-2]
		endif
		TextBox/w=QANT_plot/C/N=WaveInfo1/A=MB/X=5.00/Y=5.00/E  infowave
		if(newwindow)
			MoveWindow /W=QANT_plot 30,40,600,500
		endif
	elseif(Itemsinlist(tracenamelist("QANT_plot",";",1))>1)
		plotted=1
		TextBox/w=QANT_plot /K/N=WaveInfo1
		if(newwindow)
			MoveWindow /W=QANT_plot 30,40,600,400
		endif
	endif
	if(!newwindow && plotted)
		getaxis /w=QANT_plot /q bottom
		if(minxaxis < v_max && maxxaxis > v_min)
			setaxis /w=QANT_plot /z bottom minxaxis, maxxaxis
		endif
	endif
	if(ontop==1)
		dowindow /F QANT_plot
	elseif(ontop==2)
		dowindow /F QANTLoaderPanel
	endif
	doupdate
	setdatafolder foldersave
end
Function QANT_EXPCheckProc(cba) : CheckBoxControl
	STRUCT WMCheckboxAction &cba

	switch( cba.eventCode )
		case 2: // mouse up
			Variable checked = cba.checked
			QANT_listNEXAFSscans()
			break
		case -1: // control being killed
			break
	endswitch

	return 0
End
Function QANT_NormCursorsCheckProc(cba) : CheckBoxControl
	STRUCT WMCheckboxAction &cba

	switch( cba.eventCode )
		case 2: // mouse up
			Variable checked = cba.checked
			nvar NormCursors = root:NEXAFS:NormCursors
			normcursors = checked
			if(checked==0)
				dowindow /k QANT_plot
				killdatafolder /z root:NEXAFS:NormalizedData
				QANT_listNEXAFSscans()
				QANT_RePlotData()
				//QANT_CalcNormalizations("selected")
				//QANT_listNEXAFSscans()
			else
				QANT_listNEXAFSscans()
				//QANT_CalcNormalizations("selected")
				//QANT_listNEXAFSscans()
			endif
			break
		case -1: // control being killed
			break
	endswitch

	return 0
End

Function QANT_CursorHook(s)
	STRUCT WMWinHookStruct &s
	Variable hookResult = 0
	switch(s.eventCode)
		case 5:
			string foldersave2 = getdatafolder(1)
			setdatafolder root:NEXAFS
			variable cursorwasmoving
			variable /g cursormoving
			cursorwasmoving = cursormoving
			cursormoving=0
			setdatafolder foldersave2
			if(cursorwasmoving)
				QANT_replotdata(nochangeofplot=1)
			endif
			// set that the sursors aren't moving anymore
			break
		case 7:				// Cursor has moved
			// Handle activate
			string foldersave1 = getdatafolder(1)
			setdatafolder root:NEXAFS
			variable /g cursormoving=1
			setdatafolder foldersave1
			nvar cura = root:NEXAFS:cura
			nvar curb = root:NEXAFS:curb
			nvar curc = root:NEXAFS:curc
			nvar curd = root:NEXAFS:curd
			nvar curax = root:NEXAFS:curax
			nvar curbx = root:NEXAFS:curbx
			nvar curcx = root:NEXAFS:curcx
			nvar curdx = root:NEXAFS:curdx
			string tracename
			if(strlen(CsrInfo(A)) > 0)
				cura = pcsr(A,"QANT_plot")
			else
				tracename = stringfromlist(0,tracenamelist("QANT_plot",";",0))
				cura = cura > 0 && cura < 1 ? cura : 0.02
				Cursor/w=QANT_plot /S=2/H=2/L=0 /C=(0,0,0)/F/P A $tracename cura,.5
			endif
			if(strlen(CsrInfo(B)) > 0)
				curb = pcsr(B,"QANT_plot")
			else
				tracename = stringfromlist(0,tracenamelist("QANT_plot",";",0))
				curb = curb > 0 && curb < 1 ? curb : 0.05
				Cursor/w=QANT_plot /S=2/H=2/L=0 /C=(0,0,0)/F/P B $tracename curb,.5
			endif
			if(strlen(CsrInfo(C)) > 0)
				curc = pcsr(c,"QANT_plot")
			else
				tracename = stringfromlist(0,tracenamelist("QANT_plot",";",0))
				curc = curc > 0 && curc < 1 ? curc : 0.95
				Cursor/w=QANT_plot /S=2/H=2/L=0 /C=(0,0,0)/F/P C $tracename curc,.5
			endif
			if(strlen(CsrInfo(D)) > 0)
				curd = pcsr(D,"QANT_plot")
			else
				tracename = stringfromlist(0,tracenamelist("QANT_plot",";",0))
				curd = curd > 0 && curd < 1 ? curd : 0.98
				Cursor/w=QANT_plot /S=2/H=2/L=0 /C=(0,0,0)/F/P D $tracename curd,.5
			endif
			curax = hcsr(A,"QANT_plot")
			curbx = hcsr(B,"QANT_plot")
			curcx = hcsr(C,"QANT_plot")
			curdx = hcsr(D,"QANT_plot")
			doupdate
			setdrawlayer/w=QANT_plot /k userback
			SetDrawEnv/w=QANT_plot xcoord= bottom,linefgc= (49151,60031,65535),fillfgc= (49151,60031,65535),fillpat= 3,linethick= 0.00
			DrawRect/w=QANT_plot curax,0,curbx,1
			SetDrawEnv/w=QANT_plot xcoord= bottom,linefgc= (49151,49151,49151),fillfgc= (49151,49151,49151),fillpat= 3,linethick= 0.00
			DrawRect/w=QANT_plot curcx,0,curdx,1

			nvar NormCursors = root:NEXAFS:NormCursors
			if(NormCursors && curax*curbx*curcx*curdx*0==0)
				//QANT_Calcnormalizations("selected")
				QANT_listNEXAFSscans()
			endif
			hookResult = 0
			doupdate
			break
		default:				// Deactivate
			string foldersave3 = getdatafolder(1)
			setdatafolder root:NEXAFS
			variable /g cursormoving=0
			setdatafolder foldersave3
			//QANT_replotdata()
			break

		// And so on . . .
	endswitch

	return hookResult		// 0 if nothing done, else 1
End


Function QANT_contrasthook(s)
	STRUCT WMWinHookStruct &s
	Variable hookResult = 0
	switch(s.eventCode)

		case 4:
			if(!(s.eventmod&1))
				hookresult=0
				return 0
			endif
		case 3:
		case 5:

			variable energy = axisvalfrompixel("QANT_contrast","bottom",s.mouseLoc.h)
			getaxis/q /w=QANT_plot bottom
			variable minen = v_min
			variable maxen = v_max
			if(energy >v_min && energy<v_max)
				setdrawlayer /k userback
				setdrawlayer userback
				SetDrawEnv xcoord= bottom,dash= 6;DelayUpdate
				DrawLine energy,0,energy,1
				QANT_emphasizeXval("QANT_deltabeta",energy)
				
			else
				hookresult=0
				return 0
			endif
			hookresult=1
			return 1
			// set that the sursors aren't moving anymore
			break
		
		default:				// Deactivate
			break
	endswitch

	return hookResult		// 0 if nothing done, else 1
End

Function QANT_deltabetahook(s)
	STRUCT WMWinHookStruct &s
	Variable hookResult = 0
	switch(s.eventCode)

		case 4:
			if(!(s.eventmod&1))
				hookresult=0
				return 0
			endif
		case 3:
		case 5:
			string trace = tracefromPixel(s.mouseLoc.h,s.mouseLoc.v,"")
			string waven = stringbykey("TRACE",trace)
			string yrange = stringbykey("yrange",traceinfo("",waven,0))
			variable startpnt, endpnt
			sscanf yrange, "[%f,%f]", startpnt, endpnt
			variable xpnt = numberbykey("HitPoint",trace) + startpnt

			wave/z tracewave = tracenametowaveref("",waven)
			if(!waveexists(tracewave))
				return 0
			endif
			variable energy = pnt2x(tracewave,xpnt)
			getaxis/q /w=QANT_plot bottom
			variable minen = v_min
			variable maxen = v_max
			if(energy >v_min && energy<v_max)
				TextBox /C/N=text1/F=0/A=RT/X=2.00/Y=5.00 "\\s("+waven+") "+waven
				QANT_emphasizeXval("QANT_deltabeta",energy)
				if(s.eventCode<5)
					hookresult=1
					return 1
				endif
			else
				hookresult=0
				return 0
			endif
			hookresult=0
			return 0
			// set that the sursors aren't moving anymore
			break
			
		default:				// Deactivate
			break
	endswitch

	return hookResult		// 0 if nothing done, else 1
End

Function qant_contrasttablehook(s)
	STRUCT WMWinHookStruct &s
	Variable hookResult = 0
		variable adjustsel = 0
	switch(s.eventCode)

		//case 4:
			if(!(s.eventmod&1))
				hookresult=0
				return 0
			endif
		case 11:
			if(s.KeyCode == 30)
				adjustsel=-1
			elseif(s.KeyCode == 31)
				adjustsel=+1
			endif
		case 5:
			String info = TableInfo(s.winName, -2)
			if (strlen(info) == 0)
					return -1		// No such table
			endif
	
			String selectionInfo
			selectionInfo = StringByKey("SELECTION", info)
			wave /t tablewave = WaveRefIndexed(s.winName, 0, 1 )
		
			Variable fRow, fCol, lRow, lCol, tRow, tCol
			sscanf selectionInfo, "%d,%d,%d,%d,%d,%d", fRow, fCol, lRow, lCol, tRow, tCol
			
			string energystr = tablewave[min(max(1,frow + adjustsel),dimsize(tablewave,0))][2]
			variable energy = str2num(energystr)
		//	variable energy = axisvalfrompixel("QANT_contrast","bottom",s.mouseLoc.h)
			getaxis/q /w=QANT_plot bottom
			variable minen = v_min
			variable maxen = v_max
			if(energy >v_min && energy<v_max)
				setdrawlayer /w=QANT_Contrast /k userback
				setdrawlayer /w=QANT_Contrast userback
				SetDrawEnv /w=QANT_Contrast xcoord= bottom,dash= 6;DelayUpdate
				DrawLine /w=QANT_Contrast energy,0,energy,1
				QANT_emphasizeXval("QANT_deltabeta",energy)
			endif
			hookresult=0
			return 0
			break
		default:				// Deactivate
			break
	endswitch

	return hookResult		// 0 if nothing done, else 1
End


Function QANT_but_NewPeak(ba) : ButtonControl
	STRUCT WMButtonAction &ba

	switch( ba.eventCode )
		case 2: // mouse up
			// click code here
			QANT_CreateNewPeakSetWinfunc()
			break
		case -1: // control being killed
			break
	endswitch

	return 0
End

Function QANT_but_FitPeaks(ba) : ButtonControl
	STRUCT WMButtonAction &ba

	switch( ba.eventCode )
		case 2: // mouse up
			controlinfo /w=QANTLoaderPanel QANT_popup_PeakSet
			QANT_fitgraphtoPeakSet(s_value,gname="QANT_plot")
			break
		case -1: // control being killed
			break
	endswitch

	return 0
End


function /s Edge_BLFuncInfo(InfoDesired)
	Variable InfoDesired

	String info=""

	switch(InfoDesired)
		case BLFuncInfo_ParamNames:
			info = "EdgeEnergy;EdgeHeight;Edge Width;Decay;"
			break;
		case BLFuncInfo_BaselineFName:
			info = "Edge_BLFunc"
			break;
	endswitch

	return info
end
Function Edge_BLFunc(s)
	STRUCT MPF2_BLFitStruct &s
	variable step = s.x>=s.cwave[0]+s.cwave[2]? 1 : 0
	variable location = s.cwave[0]
	variable height = s.cwave[1]
	variable width = s.cwave[2]
	variable decay = s.cwave[3]
	return (height/2)*(1+erf((s.x-location)*2*ln(2)/width))*(1+step*(exp(-decay*(s.x-location-width))-1))
end

Function QANT_AutoLoaderCheck(cba) : CheckBoxControl
	STRUCT WMCheckboxAction &cba

	switch( cba.eventCode )
		case 2: // mouse up
			Variable checked = cba.checked
			nvar running=root:NEXAFS:running
			if(checked)
				if(running)
					break
				endif
				running=1
				CtrlNamedBackground QANT_BGTask, burst=0, proc=QANT_BGTask, period=120,dialogsOK=1, start
			else
				if(!running)
					break
				endif
				running=0
				CtrlNamedBackground QANT_BGTask, stop
			endif
			break
		case -1: // control being killed
			break
	endswitch

	return 0
End


Function QANT_BGTask(s)
	STRUCT WMBackgroundStruct &s
	NVAR running= root:NEXAFS:running
	if( running == 0 )
		return 0 // not running -- wait for user
	endif
	NVAR lastRunTicks= root:NEXAFS:lastRunTicks
	if( (lastRunTicks+120) >= ticks )
		return 0 // not time yet, wait
	endif
	NVAR runNumber= root:NEXAFS:runNumber
	runNumber += 1
	variable bgcheck= QANT_BGCheckdir()
	if(bgcheck<0)
		CheckBox QANT_autoload , win=QANTLoaderPanel , value=0
		running=0
		return 1
	endif
	lastRunTicks= ticks
	return 0
End
function /s QANT_getfilelist()
	svar fileType = root:NEXAFS:filetype
	funcref QANT_NEXAFSfileEXt_AUMain FileTypeFunc=$("QANT_NEXAFSfileEXt_"+FileType)
	string filelist="", filenames = sortlist(indexedfile(NEXAFSPath,-1,FileTypeFunc()))
	variable i
	string filename
	string filepath, cdate, mdate, size
	for(i=0;i<itemsinlist(filenames);i+=1)
		filename = stringfromlist(i,filenames)
		getfilefolderinfo /p=NEXAFSPath /q/z filename
		if(v_flag)
			continue
		endif
		filepath = s_Path
		sprintf cdate, "%d" ,v_creationdate
		sprintf mdate, "%d" ,v_modificationdate
		sprintf size, "%d" ,V_logEOF
		filelist += "filename="+filepath+","
		filelist += "Created Date="+cdate+","
		filelist += "Modified Date="+mdate+","
		filelist += "DataSize="+size+","
		filelist +=";"
	endfor
	return filelist 
end

function /s QANT_getfileinfo(filename)
	string filename
	getfilefolderinfo /p=NEXAFSPath /q/z filename
	if(v_flag)
		return "Error"
	endif
	string cdate, mdate, size, filelist, filepath = s_Path
	sprintf cdate, "%d" ,v_creationdate
	sprintf mdate, "%d" ,v_modificationdate
	sprintf size, "%d" ,V_logEOF
	filelist = "filename="+filepath+","
	filelist += "Created Date="+cdate+","
	filelist += "Modified Date="+mdate+","
	filelist += "DataSize="+size+","
	return filelist 
end
function QANT_BGCheckdir()
	// the purpose of this function is to safely and quietly check the directory, and load any new files, and check the last few files in the directory to see if the file sizes have changed
	// to this end, we need to remember a list of files we have loaded, so we don't load them again
	// we only want to check the sizes of the last ~10 files in the directory, but we can't check the dates, so we will have to work with the filenames
	// this is a somewhat annoying problem, because the file names can change once in a while, however this is not usual behavior
	// additionally, the "load directory" button will go through and check everything in the directory, this is meant to be a very quick and easy function
	string dfsave = getdatafolder(1)
	setdatafolder root:NEXAFS
	string /g oldfilelist // list of all loaded files, names dates etc.
	string /g filenamelist // list of just the filenames, as produced by indexedfile
	string /g badfilelist
	pathinfo NEXAFSPath
	if(v_flag==0)
		print "Error, no Path chosen"
		return -1
	endif
	svar fileType = root:NEXAFS:filetype
	funcref QANT_NEXAFSfileEXt_AuMAIN FileTypeFunc=$("QANT_NEXAFSfileEXt_"+FileType)
	
	string filenames = indexedfile(NEXAFSPath,-1,FileTypeFunc())//QANT_getfilelist()
	filenames = sortlist(filenames,";",16)
	variable i
	variable newfilefound = 0,written=0
	string openedfilenames="", openedfilename, openedFileNamesReal
	string testfilename, testfile, filename
	for(i=0;i<itemsinlist(filenames,";");i+=1) // check all files if they are new
		testfile = stringfromlist(i,filenames)
		if(FindListItem(testfile,filenamelist) < 0)
			//filename is not in the old list of files  this filename should be loaded!
			GetFileFolderInfo /P=NEXAFSPath /Q /Z testfile
			if(strlen(s_path)>0)
				svar FileType = root:NEXAFS:FileType
				if(exists("QANT_LoadNEXAFSfile_"+FileType)==6)
						funcref QANT_LoadNEXAFSfile FileLoader=$("QANT_LoadNEXAFSfile_"+FileType)
						openedfilename = FileLoader(s_path)
					else
						print "no recognized loader could be found"
						return -1
				endif
			
			
			
				//openedfilename=QANT_LoadNEXAFSfile(S_Path) // this loads the file
				if(strlen(openedfilename)>0) // if successfully loaded
					newfilefound+=1 // count up the new files
					openedfilenames += openedfilename + ";" // add this to a list of opened scans
					filenamelist += testfile+ ";" // record the filename
					oldfilelist += QANT_getfileinfo(testfile) + ";" // record all of the file info
				endif
			endif
		endif
	endfor
	 // check just the most recent 15 files if they have changed
	for(i=itemsinlist(filenames,";");i>itemsinlist(filenames,";")-15;i-=1) // check last 15 files sorted alphabetically
		filename = stringfromlist(i,filenames)
		testfile = QANT_getfileinfo(filename)
		if(FindListItem(testfile,oldfilelist) < 0 &&FindListItem(testfile,badfilelist) < 0 && strlen(filename)>0)
			//either this file is new (shouldn't be because of previous loop), or the file has changed
			//openedfilename=QANT_LoadNEXAFSfile(stringbykey("filename",testfile,"=",",")) // load the file
			
			svar FileType = root:NEXAFS:FileType
			if(exists("QANT_LoadNEXAFSfile_"+FileType)==6)
					funcref QANT_LoadNEXAFSfile FileLoader=$("QANT_LoadNEXAFSfile_"+FileType)
					openedfilename = FileLoader(stringbykey("filename",testfile,"=",","))
				else
					print "no recognized loader could be found"
					return -1
			endif
			
			if(strlen(openedfilename)>0) // did the file load?
				newfilefound+=1
				openedfilenames += openedfilename + ";"
				oldfilelist += testfile + ";"
				filenamelist += filename + ";"
			else
				badfilelist += testfile + ";"
			endif
		endif
	endfor
	if(newfilefound>0)
		QANT_listNEXAFSscans() // add the files to the scanlist
		QANT_CalcNormalizations(openedfilenames) // make sure they are normalized 
		setdatafolder root:NEXAFS
		wave/t scanlist
		wave selwave = root:NEXAFS:selwavescanlist
		duplicate /free selwave, selwavescanlist
		selwavescanlist =selwave? 1 : 0
		for(i=0;i<newfilefound;i+=1)
			findvalue /TEXT=stringfromlist(i,openedfilenames) scanlist
			if(v_value>=0)
				selwave[v_value]=8 // select the new files
			endif
		endfor
		QANT_listNEXAFSscans() // update the scanlist again
		string foldersave = getdatafolder(1)
		if(datafolderexists("root:NEXAFS:refs")) // calculate the energy corrections
			setdatafolder root:NEXAFS:refs
			nvar minsearch, maxsearch, peakloc, smsize 
			if(nvar_exists(minsearch) &&nvar_exists(maxsearch) &&nvar_exists(peakloc) &&nvar_exists(smsize) )
				QANT_CalcEnergyCalibrationAll(minsearch, maxsearch, peakloc, smsize,avg=0)
				QANT_CalcNormalizations("selected")
			endif
		endif
	endif
	setdatafolder dfsave
	return newfilefound
end

function QANT_CheckFulldir()
	// this function is the old "auto load" function, but it takes far too long, because it checks the size of every file in the directory, which can take up to a minute
	string dfsave = getdatafolder(1)
	setdatafolder root:NEXAFS
	string /g oldfilelist, badfilelist
	string /g filenamelist
	pathinfo NEXAFSPath
	if(v_flag==0)
		print "Error, no Path chosen"
		return -1
	endif
	string filenames = QANT_getfilelist()
	variable i
	variable newfilefound = 0,written=0
	string openedfilenames="", openedfilename
	string testfilename, testfile
	for(i=0;i<itemsinlist(filenames,";");i+=1)
		testfile = stringfromlist(i,filenames)
		if(FindListItem(testfile,oldfilelist) < 0 && FindListItem(testfile,badfilelist) < 0)
			//filename is not in the old list of files  this filename should be loaded!

			svar FileType = root:NEXAFS:FileType
			if(exists("QANT_LoadNEXAFSfile_"+FileType)==6)
					funcref QANT_LoadNEXAFSfile FileLoader=$("QANT_LoadNEXAFSfile_"+FileType)
					openedfilename = FileLoader(stringbykey("filename",testfile,"=",","))
				else
					print "no recognized loader could be found"
					return -1
			endif
			
			//openedfilename=QANT_LoadNEXAFSfile(stringbykey("filename",testfile,"=",","))
			if(strlen(openedfilename)>0 && cmpstr(openedfilename,"BAD"))
				newfilefound+=1
				openedfilenames += openedfilename + ";"
				filenamelist += ParseFilePath(0,stringbykey("filename",testfile,"=",","),":",1,0) + ";"
			else
				// mark this file as bad
				badfilelist += testfile + ";"
			endif
		endif
	endfor
	if(newfilefound>0)
		QANT_listNEXAFSscans()
		QANT_CalcNormalizations(openedfilenames)
		setdatafolder root:NEXAFS
		wave/t scanlist
		wave selwave = root:NEXAFS:selwavescanlist
		duplicate /free selwave, selwavescanlist
		selwavescanlist =selwave? 1 : 0
		for(i=0;i<newfilefound;i+=1)
			findvalue /TEXT=stringfromlist(i,openedfilenames) scanlist
			if(v_value>=0)
				selwave[v_value]=8
			endif
		endfor
		QANT_listNEXAFSscans()
		string foldersave = getdatafolder(1)
		if(datafolderexists("root:NEXAFS:refs"))
			setdatafolder root:NEXAFS:refs
			nvar minsearch, maxsearch, peakloc, smsize 
			if(nvar_exists(minsearch) &&nvar_exists(maxsearch) &&nvar_exists(peakloc) &&nvar_exists(smsize) )
				QANT_CalcEnergyCalibrationAll(minsearch, maxsearch, peakloc, smsize,avg=0)
				QANT_CalcNormalizations("selected")
			endif
		endif
	endif
	setdatafolder dfsave
	return newfilefound
end

function /S QANT_ListTraces()
	string basiclist =TraceNameList("",";",1)//QANT_plot
	basiclist = "none;"+basiclist
	return basiclist
end


function /S QANT_ExistingfitsList()
	string foldersave = getdatafolder(1)
	string basiclist 
	if(datafolderexists("root:Packages:MultiPeakfit2"))
		setdatafolder root:Packages:MultiPeakfit2
		string listofdatafolders = datafolderdir(1)
		basiclist= replacestring(",",stringbykey("FOLDERS",listofdatafolders,":",";"),";")
	
		setdatafolder foldersave
	else
		basiclist=""
	endif
	basiclist = "none;"+basiclist
	return basiclist
end
function QANT_CreateNewPeakSetWinfunc()
	PauseUpdate; Silent 1		// building window...
	string foldersave = getdatafolder(1)
	setdatafolder root:NEXAFS
	newdatafolder/o/s fitting
	string /g tracetofit="none"
	variable /g previousfitpop=0
	dowindow /k QANT_CreateNewPeakSetWindow
	NewPanel /n=QANT_CreateNewPeakSetWindow /W=(681,491,949,601)  as "Create New Peak Set"
	ModifyPanel fixedSize=1
	SetDrawLayer UserBack
	Button QANT_Fitting_StartNewBut,pos={137,70},size={127,29},proc=QANT_NewFitStart_but,title="Start New Multipeakfit",disable=2
	PopupMenu QANT_Fitting_ExistingPop,pos={19,37},size={241,24},bodyWidth=177,title="Existing Fits: ",proc=QANT_FittingExisting_pop
	PopupMenu QANT_Fitting_ExistingPop,mode=1,popvalue="none",value= #"QANT_ExistingfitsList()"
	Button QANT_Fitting_NewCancel,pos={6,70},size={127,29},proc=QANT_NewFitCancel_but,title="Cancel",disable=0
	PopupMenu QANT_Fitting_NewFromGraphPop,pos={40,9},size={220,24},bodyWidth=177,title="Dataset:"
	PopupMenu QANT_Fitting_NewFromGraphPop,mode=1,popvalue="none",value= #"QANT_ListTraces()",proc=QANT_FittingFromGraph_pop
	
	setdatafolder foldersave
End

Function QANT_FittingExisting_pop(pa) : PopupMenuControl
	STRUCT WMPopupAction &pa

	switch( pa.eventCode )
		case 2: // mouse up
			Variable popNum = pa.popNum
			String popStr = pa.popStr
			nvar previousfitpop = root:NEXAFS:fitting:previousfitpop
			previousfitpop = popnum
			break
		case -1: // control being killed
			break
	endswitch

	return 0
End

Function QANT_FittingFromGraph_pop(pa) : PopupMenuControl
	STRUCT WMPopupAction &pa

	switch( pa.eventCode )
		case 2: // mouse up
			Variable popNum = pa.popNum
			String popStr = pa.popStr
			svar tracetofit = root:NEXAFS:fitting:tracetofit
			tracetofit = popStr
			if(popnum<2)
				Button QANT_Fitting_StartNewBut,disable=2
			else
				Button QANT_Fitting_StartNewBut,disable=0
			endif
			break
		case -1: // control being killed
			break
	endswitch

	return 0
End
Function QANT_NewFitCancel_but(ba) : ButtonControl
	STRUCT WMButtonAction &ba

	switch( ba.eventCode )
		case 2: // mouse up
			// click code here
			killwindow QANT_CreateNewPeakSetWindow
			break
		case -1: // control being killed
			break
	endswitch

	return 0
End

Function QANT_NewFitStart_but(ba) : ButtonControl
	STRUCT WMButtonAction &ba

	switch( ba.eventCode )
		case 2: // mouse up
			// click code here
			string foldersave = getdatafolder(1)
			setdatafolder root:NEXAFS:fitting
			nvar previousfitpop
			svar tracetofit
			variable initfrom = previousfitpop<2 ? 1 : 3
			if (!DataFolderExists("root:Packages:MultiPeakFit2"))
				String SaveDF = GetDataFolder(2)
				SetDataFolder root:
				NewDataFolder/O/S Packages
				NewDataFolder/O/S MultiPeakFit2
				
				Variable/G currentSetNumber = 0
		
				String/G MPF2_DoFitHelpBoxText
				
				MPF2_DoFitHelpBoxText = "To get started, add peaks to the list."
				MPF2_DoFitHelpBoxText += "\rEither click the \f01Auto-locate Peaks\f]0 button, above,"
				MPF2_DoFitHelpBoxText += "\ror drag a marquee on the graph and select"
				MPF2_DoFitHelpBoxText += "\r\f01Add or Edit Peaks\f]0 from the marquee menu."
				Variable/G MPF2_DontShowHelpMessage=0
				
				SetDataFolder saveDF
			endif
			MPF2_StartNewMPFit(0, "New Graph", GetWavesDataFolder(TraceNameToWaveRef("",tracetofit),2) , getwavesdatafolder(XWaveRefFromTrace("",tracetofit),2), initfrom, previousfitpop-1) // removed QANT_plot from wave reference getting
			killwindow QANT_CreateNewPeakSetWindow
			QANT_savePeakSetfunc()
			setdatafolder foldersave
			break
		case -1: // control being killed
			break
	endswitch
	return 0
End

function QANT_MPF2_to_PeakSet(name)
	string name
	string foldersave = getdatafolder(1)
	
	getwindow kwtopWin wtitle
	string traces = tracenamelist("",";",1)
	variable tracenumber = whichlistitem("'Peak 0'",traces)
	if(tracenumber<0)
		//there are no peaks
		print "There are no peaks on selected graph, please place at least one peak"
		return -1
	endif
	string tracename = stringfromlist(tracenumber,traces)
	string datafolder = getwavesdatafolder(tracenametowaveref("",tracename),1)
	if(!stringmatch(datafolder,"root:Packages:MultiPeakFit2:MPF_SetFolder_*"))
		//we do not have a valid datafolder
		print "invalid top graph, please select the fit window you would like to load and try again"
		return -1
	endif
	setdatafolder root:NEXAFS
	newdatafolder /O/S fitting
	
	string peaksetname = cleanupname(name,1)
	wave/t peakset = $peaksetname
	if(waveexists(peakset))
		peaksetname = uniquename(peaksetname,1,0)
	endif
	make /n=0 /t $peaksetname
	wave /t peakset = $peaksetname
	
	setdatafolder datafolder
	svar funcliststring
	if(!svar_exists(funcliststring))
		print "no valid function list string was found in this MPF2 Peak directory, maybe do at least a single peak fit"
		return -1
	endif
	
	string peaktype, funcstring
	redimension /n=(itemsinlist(funcliststring,"}")) peakset
	variable j
	for(j=0;j<itemsinlist(funcliststring,"}");j+=1)
		funcstring = stringfromlist(j,funcliststring,"}")
		funcstring = replacestring("{",funcstring,"")
		peaktype = stringfromlist(0,funcstring,",")
		wave coefwave = $stringfromlist(1,funcstring,",")
		peakset[j] = QANT_translatepeak2Wooshka(peaktype,coefwave)
	endfor
	ControlUpdate /W=QANTLoaderPanel  QANT_popup_PeakSet
	ControlInfo /W=QANTLoaderPanel QANT_popup_PeakSet
	STRUCT WMPopupAction pa
	pa.popnum = v_value
	pa.popstr = S_value
	pa.eventCode = 2
	QANT_PeakSetPOP(pa)
	setdatafolder foldersave
end
function /s QANT_translatepeak2Wooshka(MPF2Peakname,cwave)
	string MPF2Peakname
	wave cwave
	string outputstring=""	
	variable j
	strswitch(MPF2Peakname)	// string switch
		case "MPFXGaussPeak":
			outputstring ="GAUSSIAN;"
			outputstring += num2str(abs(cwave[1])) + ";" // height
			outputstring += num2str(cwave[0]) + ";" // location
			outputstring += num2str(abs(2*sqrt(2*ln(2))*cwave[2])) + ";" // FWHM
			break
		case "Edge_BLFunc":
			outputstring ="NEXAFS_EDGE;"
			outputstring += num2str(cwave[1]) + ";" // height
			outputstring += num2str(cwave[0]) + ";" // location
			outputstring += num2str(cwave[2]) + ";" // FWHM
			outputstring += num2str(cwave[3]) + ";" // decay
			break
		case "MPFXEMGPeak":
			outputstring ="ASYM_GAUS;"
			outputstring += num2str(abs(cwave[1])) + ";" // height
			outputstring += num2str(cwave[0]) + ";" // location
			outputstring += num2str(abs(2*sqrt(2*ln(2))*cwave[2])) + ";" // FWHM
			outputstring += num2str(abs(cwave[3])) + ";" // decay
			break
		default:						// optional default expression executed
			outputstring =MPF2Peakname+";"
			outputstring += num2str(cwave[1]) + ";" // height
			outputstring += num2str(cwave[0]) + ";" // location
			outputstring += num2str(cwave[2]) + ";" // FWHM
			for(j=3;j<dimsize(cwave,0);j+=1)
				outputstring += num2str(cwave[j]) + ";" // other
			endfor
			break
	endswitch
	return outputstring
end

Function QANT_PeakSetPOP(pa) : PopupMenuControl
	STRUCT WMPopupAction &pa

	switch( pa.eventCode )
		case 2: // mouse up
			Variable popNum = pa.popNum
			String popStr = pa.popStr
			svar peaksetfit =  root:NEXAFS:peaksetfit
			peaksetfit = popStr
			if(!cmpstr("none",popStr))
				button QANT_but_Fit, win=QANTLoaderPanel, disable=2
				Button QANT_but_RemovePeakSet, win=QANTLoaderPanel, disable=2
				Button QANT_but_EditPeakSet, win=QANTLoaderPanel, disable=2
			else
				button QANT_but_Fit, win=QANTLoaderPanel, disable=0
				Button QANT_but_RemovePeakSet, win=QANTLoaderPanel, disable=0
				Button QANT_but_EditPeakSet, win=QANTLoaderPanel, disable=0
				
			endif
			popupmenu QANT_popup_PeakSet win=QANTLoaderPanel, mode=popnum
			popupmenu /z QANT_popup_PeakSet win=QANT_PeaksetEditWindow, mode=popnum
			QANT_updatePeaksetDisp()
			QANT_PeakEdit_UpdatePlot()
			break
		case -1: // control being killed
			break
	endswitch

	return 0
End

Function QANT_RemovePeakSet(ba) : ButtonControl
	STRUCT WMButtonAction &ba

	switch( ba.eventCode )
		case 2: // mouse up
			// click code here
			string foldersave = getdatafolder(1)
			svar PeakSetFit = root:NEXAFS:PeakSetFit
			wave peakset = root:NEXAFS:fitting:$peaksetfit
			
			ControlInfo /W=QANTLoaderPanel QANT_popup_PeakSet
			variable oldpopnum = v_value
			
			killwaves /z peakset
			
			ControlUpdate /W=QANTLoaderPanel  QANT_popup_PeakSet
			if(oldpopnum > itemsinlist(QANT_ListPeakSets()))
				popupmenu QANT_popup_PeakSet, win=QANTLoaderPanel, mode=(oldpopnum-1)
				ControlUpdate /W=QANTLoaderPanel  QANT_popup_PeakSet
			endif
			ControlInfo /W=QANTLoaderPanel QANT_popup_PeakSet
			STRUCT WMPopupAction pa
			pa.popnum = v_value
			pa.popstr = S_value
			pa.eventCode = 2
			QANT_PeakSetPOP(pa)
			setdatafolder foldersave
			break
		case -1: // control being killed
			break
	endswitch

	return 0
End

function /s QANT_ListPeakSets()
	string foldersave = getdatafolder(1)
	setdatafolder root:NEXAFS:fitting
	string output = wavelist("!List*",";","DIMS:1,TEXT:1")
	if(strlen(output)<1)
		output = "none"
	endif
	setdatafolder foldersave
	return output
end

Function QANT_MPF2_to_peakset_but(ba) : ButtonControl
	STRUCT WMButtonAction &ba

	switch( ba.eventCode )
		case 2: // mouse up
			// click code here
			controlinfo /w=QANT_SaveMPF2Panel QANT_PeakSetNameVariable
			if(QANT_MPF2_to_peakset(s_value)!=-1)
				string fitwname = WinName(0,1)
				dowindow /k $fitwname
				
			endif
			killwindow QANT_SaveMPF2Panel
			break
		case -1: // control being killed
			break
	endswitch

	return 0
End
function QANT_savePeakSetfunc()
	PauseUpdate; Silent 1		// building window...
	dowindow QANT_SaveMPF2Panel
	if(v_flag==1)
		killwindow QANT_SaveMPF2Panel
	endif
	NewPanel /k=2 /FLT /n=QANT_SaveMPF2Panel /W=(1328,103,1570,224) as "Save Peak Set"
	ModifyPanel /w=QANT_SaveMPF2Panel fixedSize=1
	SetDrawLayer /w=QANT_SaveMPF2Panel UserBack
	DrawText /w=QANT_SaveMPF2Panel 23,76,"to close the multipeakfitting window"
	DrawText /w=QANT_SaveMPF2Panel 13,90,"and save the peak set for NEXAFS fitting"
	DrawText /w=QANT_SaveMPF2Panel 10,62,"when satisfied with the peaks, click here"
	Button QANT_saveMPF2PeakSet_button,win=QANT_SaveMPF2Panel,pos={45,4},size={145,40},proc=QANT_MPF2_to_peakset_but,title="Close Fitting window and\rSave Peak Set"
	SetVariable QANT_PeakSetNameVariable,win=QANT_SaveMPF2Panel,pos={10,96},size={215,16},title="Name for Saved Peak Set: "
	SetVariable QANT_PeakSetNameVariable,win=QANT_SaveMPF2Panel,value= _STR:"PeakSet"
	SetActiveSubwindow _endfloat_
End


function QANT_fitgraphtoPeakSet(PeakSetname,[gname])
	string peaksetname
	string gname
	wave/t peakset = root:NEXAFS:fitting:$(peaksetname)
	string foldersave = getdatafolder(1)
	if(!waveexists(peakset))
		print "Cannot load peakfit"
		return -1
	endif
	if(paramisdefault(gname))
		gname = ""
	endif
	QANT_replotdata()
	string traces="", tracenames = TraceNameList(gname,";",1)
	variable j
	string datawaves="", xwaves="", tracename
	for(j=0;j<itemsinlist(tracenames);j+=1)
		tracename = stringfromlist(j,tracenames)
		if( stringmatch(tracename,"*res_*") || stringmatch(tracename,"*fit_*") ||  stringmatch(tracename,"*Gauss*") ||  stringmatch(tracename,"Edge"))
			continue
		endif
		traces += tracename + ";"
		datawaves += GetWavesDataFolder(TraceNameToWaveRef(gname,tracename),2) + ";"
		xwaves += GetWavesDataFolder(XWaveRefFromTrace(gname,tracename),2)+ ";"
	endfor
	dowindow /f $gname
	controlinfo /w=QANTLoaderPanel QANT_setVar_FitName
	QANT_multipeakBatchfit(peakset,datawaves,xwaves, traces,s_value)
	
	setdatafolder foldersave
end
function QANT_multipeakBatchfit(peakset, datawaves, xwaves, tracenames,name)
	string datawaves, xwaves, tracenames, name
	wave/t peakset
	
	variable nfits = itemsinlist(datawaves)
	setdatafolder root:NEXAFS:fitting
	if(nfits==0)
		return 0
	endif
	
	if(strlen(name)<1)
		name = uniquename("FitSet",11,0)
	else
		name = cleanupname(name,1)
		if(datafolderexists(name))
			name = uniquename(name,11,0)
		endif
	endif
	newdatafolder/o/s $name
	duplicate peakset, PeakSetInit
	make /n=(nfits) /o /wave peaksets, peakerrors
	string FitDatafolder = getdatafolder(1)
	struct MPFitInfoStruct s
	s.npeaks = dimsize(peakset,0)-1
	s.FitCurvePoints = 1000
	s.fitOptions = 4	// no display window
	
	// loop through each of the data sets, calling MPF2_DoMPFit
	// on each one. After each call, the results are checked and acted
	// on appropriately.

	make /o/n=(nfits) /t fitnames
	make /o/n=(nfits,s.npeaks) /d locations, widths, heights
	make /o/n=(s.npeaks) /t PeakTypes = stringfromlist(0,peakset[p])
	make /o/n=(s.npeaks+1) /t s.constraints
	string batchname="", batchfulldatafolder, tracelist
	variable err, i, j, k
	for(i=0;i<nfits;i+=1)
		setdatafolder FitDatafolder
		batchname = replacestring("'",stringfromlist(i,tracenames),"")
		newdatafolder /o/s $cleanupname(batchname,1)
		batchfulldatafolder = getdatafolder(1)
		s.ListOfFunctions=""
		s.listofCWaveNames=""
		s.ListOfHoldStrings=""
		variable heightnum, kcount=0
		k=0
		for(j=0;j<dimsize(peakset,0);j+=1)
			s.ListOfFunctions += QANT_WhooskaNametoMPF2(stringfromlist(0,peakset[j])) + ";"
			s.listofCWaveNames += QANT_MakeCwaveFromPeakSet(peakset[j],0) + ";"
			heightnum = QANT_getHeightLocFromPeakSet(peakset[j])
			//if(heightnum>0)
			//	s.constraints[k] = "K" +num2str(max(0,kcount+heightnum)) + " > 0"
			//	k+=1
			//endif
			s.ListOfHoldStrings += QANT_HoldStringFromPeakSet(peakset[j]) + ";"
			kcount +=itemsinlist(peakset[j])-1
		endfor
		redimension /n=(k) s.constraints
		wave s.ywave = $stringfromlist(i,datawaves)
		fitnames[i] = StringFromList(i, datawaves)
		wave s.xwave = $stringfromlist(i,xwaves)
		s.XPointRangeBegin = 2
		s.XPointRangeEnd = numpnts(s.xwave)-1
		//setdatafolder ::
		
		duplicate/o s.ywave, $Cleanupname("fit_"+batchname,1)
		removefromgraph /z $Cleanupname("fit_"+batchname,1)
		appendtograph $Cleanupname("fit_"+batchname,1) vs s.xwave
		err = QANT_MPF2_DoMPFit(s, batchfulldatafolder,outputname=Cleanupname("fit_"+batchname,1))
		string listofsigmawaves = wavelist("W_sigma_*",";","")
		if (err)
			// error return from MPF2_DoMPFit generally indicates
			// a programmer error
			DoAlert 0, "Error calling MPF2_DoMPFit: "+num2str(err)
			//continue
		endif
		if (s.fitQuitReason == 2)
			// if the user aborts a fit, we assume that the whole process
			// should be aborted
			//DoAlert 0, "User aborted batch fit"
			//continue // commenting this out for now to allow for mass fitting without messing up the results which are tabulated below
		endif
		if (s.fitError)
			// Something went wrong with the current fit, and it
			// failed to converge. We note this fact to the user via
			// an alert, then move on to the next one. You may wish
			// to do something more sophisticated than this.
			
			// Avoid a long line by concatenating the message
			// in small pieces
			String alertMsg = "Error doing fit to "
			alertMsg += StringFromList(i, datawaves)+": "
			alertMsg += num2str(s.fitError)
			alertMsg += "; continuing with next fit."
			//DoAlert 0, alertMsg
			//continue
		endif
		tracelist = tracenamelist("",";",1)
		for(j=0;j<itemsinlist(tracelist);j+=1)
			if(stringmatch(stringfromlist(j,tracelist),"*res_*"))
				removefromgraph $stringfromlist(j,tracelist) //remove residuals from graph to stop them clogging everything up
			endif
		endfor
		for(j=0;j<s.npeaks-1;j+=1)
			wave peakw = $(batchfulldatafolder+stringfromlist(j,s.listofCWaveNames))
			locations[i][j] = peakw[0]
			widths[i][j] = peakw[1]
			heights [i][j] = peakw[2]
		endfor
		peakerrors[i] = QANT_PeakErrorFromFuncListSt(s.FuncListString,stringfromlist(i,tracenames),listofsigmawaves )
		peaksets[i] = QANT_PeakSetFromFuncListStr(s.FuncListString,stringfromlist(i,tracenames))
		setdatafolder ::
		string/g funcliststringsave = s.FuncListString
	endfor
	// Load Peak Set Window and create peak set waves if they don't exist already
	setdatafolder root:NEXAFS:fitting
	make/o/t/n=(CountObjects("", 4 )) ListOfGroupFits  = GetIndexedObjName("", 4 ,p)
	findvalue /text="plotting" ListofGroupFits
	if(v_value>=0)
		Deletepoints v_value,1,ListofGroupFits
	endif
	make/o/n=(dimsize(ListOfGroupFits,0)) ListOfGroupFitsSel
	make /o/n=(nfits)/t ListOfFits = stringfromlist(p,tracenames)
	make /o/n=(nfits) ListOfFitsSel = 0
	make /o/n=(s.npeaks+1,4)/t ListOfPeaks
	make /o/n=(s.npeaks+1,7)/t ListOfPeaksSplitErr
	make /o/n=(s.npeaks+1,7)/t ListOfPeaksSplitSet
	ListOfPeaks[][0] = stringfromlist(0,peakset[p]) + " at " + stringfromlist(2,peakset[p])
	ListOfPeaksSplitErr[][0]=ListOfPeaks[p][0]
	make /o/n=(s.npeaks+1,4) ListOfPeaksSel = 0
	make /o/n=4 /t listpeakcolumnnames = {"Peak","Stšhr 9.16a","Stšhr 9.17a","Stšhr 9.14a"}
	findvalue /TEXT=name ListOfGroupFits
	QANT_PeakFitResultsPanelfunc(val = v_value)
	dowindow QANT_Plot
	if(v_flag)
		QANT_addPeaksettoPlot(peaksets[nfits-1])
	endif
	string outputstring = "Peak\tFit to Stšhr 9.16a\tUncertainty\tFit to Stšhr 9.17a\tUncertainty\tFit to Stšhr 9.14a\tUncertainty\r"
	for(j=0;j<dimsize(peakset,0);j+=1)
		for(k=0;k<7;k+=1)
			outputstring += listofpeaksSplitErr[j][k] + "\t"
		endfor
		outputstring = removeending(outputstring)
		outputstring +="\r"
	endfor
	outputstring = removeending(outputstring)
	putscraptext outputstring
end
function/s QANT_MakeCwaveFromPeakSet(stringin,temp)
	string stringin
	variable temp
	string wname
	if(temp)
		wname="cWave"
	else
		wname = uniquename("cWave",1,0)
	endif
	strswitch(stringfromlist(0,stringin))
		case "NEXAFS_EDGE":
			make /o/n=4 $wname
			wave waveout = $wname
			waveout[0] = str2num(stringfromlist(2,stringin))
			waveout[1] = str2num(stringfromlist(1,stringin))
			waveout[2] = str2num(stringfromlist(3,stringin))
			waveout[3] = str2num(stringfromlist(4,stringin))
			break
		case "GAUSSIAN":
			make /o/n=3 $wname
			wave waveout = $wname
			waveout[0] = str2num(stringfromlist(2,stringin))
			waveout[1] = str2num(stringfromlist(1,stringin))
			waveout[2] = str2num(stringfromlist(3,stringin)) / (2*sqrt(2*ln(2)))
			break
		case "ASYM_GAUS":
			make /o/n=4 $wname
			wave waveout = $wname
			waveout[0] = str2num(stringfromlist(2,stringin))
			waveout[1] = str2num(stringfromlist(1,stringin))
			waveout[2] = str2num(stringfromlist(3,stringin)) / (2*sqrt(2*ln(2)))
			waveout[3] = str2num(stringfromlist(4,stringin))
			break
		default:
			make /o/n=(Itemsinlist(stringin)-1) $wname
			wave waveout = $wname
			variable i
			waveout[0] = str2num(stringfromlist(2,stringin))
			waveout[1] = str2num(stringfromlist(1,stringin))
			waveout[2] = str2num(stringfromlist(3,stringin))
			for(i=4;i<itemsinlist(stringin);i+=1)
				waveout[i-1] = str2num(stringfromlist(i,stringin))
			endfor
			break
	endswitch
	return wname
end
function/s QANT_WhooskaNametoMPF2(stringin)
	string stringin
	strswitch(stringin)
		case "NEXAFS_EDGE":
			return "Edge"
		case "MPF_LogNormal":
			return "LogNormal"
		case "GAUSSIAN":
			return "Gauss"
		case "ASYM_GAUS":
			return "ExpModGauss"
		default:
			return stringin
	endswitch
end
function QANT_getHeightLocFromPeakSet(stringin)
	string stringin
	strswitch(stringfromlist(0,stringin))
		case "NEXAFS_EDGE":
			return -1
		case "LogCubic_BLFunc":
			return -1
		default:
			return 2
	endswitch
end
function/s QANT_HoldStringFromPeakSet(stringin)
	string stringin
	
	nvar HoldNEXAFSEdge = root:NEXAFS:HoldNEXAFSEdge
	nvar HoldPeakPositions = root:NEXAFS:HoldPeakPositions
	nvar HoldPeakWidths = root:NEXAFS:HoldPeakWidth
	strswitch(stringfromlist(0,stringin))
		case "NEXAFS_EDGE":
			if(holdNexafsEdge)
				return "1111"
			else
				return "0000"
			endif
		case "Cubic_BLFunc":
			if(holdNexafsEdge)
				return "1111"
			else
				return "0000"
			endif
		case "LogCubic_BLFunc":
			if(holdNexafsEdge)
				return "1111"
			else
				return "0000"
			endif
		case "LogPoly5_BLFunc":
			if(holdNexafsEdge)
				return "111111"
			else
				return "000000"
			endif
		case "GAUSSIAN":
			return num2str(HoldPeakPositions)+num2str(HoldPeakWidths)+"0"
		case "ASYM_GAUS":
			return num2str(HoldPeakPositions)+num2str(HoldPeakWidths)+"0" + num2str(HoldPeakWidths)
		default:
			string retstring = num2str(HoldPeakPositions)+num2str(HoldPeakWidths) +"0"
			variable i
			for(i=4;i<itemsinlist(stringin);i+=1)
				retstring+= num2str(HoldPeakWidths)
			endfor
			return retstring
	endswitch
end

// Function to do a multi-peak fit from client code.
// Input: a structure with information about the fit, plus the name of a data folder containing coefficient waves,
// one for each peak, plus a coefficient wave for the baseline (unless the baseline function is "none").
// The contents of DataFolderName is a full path to the data folder, with final ":"
// Returns the function list string used in FuncFit sum-of-functions list.
// This version is very slightly altered (by eliot) to allow for better naming options for fit waves, and remove plotting of residuals (unforunately this meant copying the whole function)
Function QANT_MPF2_DoMPFit(MPstruct, DataFolderName [, doUpdates, outputname])
	STRUCT MPFitInfoStruct &MPstruct
	String DataFolderName, outputname
	Variable doUpdates
	variable doAutoDest
	if(paramisdefault(outputname))
		doAutoDest = 1
	else
		doAutoDest = 0
	endif
	if (ParamIsDefault(doUpdates))
		doUpdates = 1
	endif
	
	Variable npeaks = MPstruct.NPeaks
	Wave yw = MPstruct.yWave
	Wave/Z xw = MPstruct.xWave
	
	if (ItemsInList(MPstruct.ListOfFunctions) != npeaks+1)		// +1 for the baseline function
		return MPF2_Err_BadNumberOfFunctions
	endif
	
	if (ItemsInList(MPstruct.ListOfCWaveNames) != npeaks+1)
		return MPF2_Err_BadNumberOfCWaves
	endif
	
	MPstruct.FuncListString = ""
	String holdString
	
	String BL_TypeName = StringFromList(0, MPstruct.ListOfFunctions)
	Variable doBaseLine = CmpStr(BL_TypeName, "None") != 0
	if (doBaseLine)
		String BL_FuncName
		Variable nBLParams
		BL_typename = removeending(BL_typename, "_BLFunc")
		FUNCREF MPF2_FuncInfoTemplate blinfo = $(BL_typename + BL_INFO_SUFFIX)
		BL_FuncName = blinfo(BLFuncInfo_BaselineFName)
		nBLParams = ItemsInList(blinfo(BLFuncInfo_ParamNames))
		if (nBLParams == 0)
			return MPF2_Err_NoSuchBLType
		endif
		
		STRUCT MPF2_BLFitStruct BLStruct
		if (WaveExists(xw))
			BLStruct.xStart = xw[MPstruct.XPointRangeBegin]
			BLStruct.xEnd = xw[MPstruct.XPointRangeEnd]
		else
			BLStruct.xStart = pnt2x(yw, MPstruct.XPointRangeBegin)
			BLStruct.xEnd = pnt2x(yw, MPstruct.XPointRangeEnd)
		endif
		String blcoefwname = StringFromList(0, MPstruct.ListOfCWaveNames)
		Wave/Z blcoefwave = $(DataFolderName+PossiblyQuoteName(blcoefwname))
		if (!WaveExists(blcoefwave))
			return MPF2_Err_BLCoefWaveNotFound
		endif
		MPstruct.FuncListString += "{"+BL_FuncName+", "+GetWavesDataFolder(blcoefwave,2)
		Duplicate/O blcoefwave, blepswave
		blepswave = 1e-6
		MPstruct.FuncListString += ", EPSW="+GetWavesDataFolder(blepswave,2)
		holdString = StringFromList(0, MPstruct.ListOfHoldStrings)
		if (strlen(holdString) > 0)
			MPstruct.FuncListString += ", HOLD=\""+holdString+"\""
		endif
		MPstruct.FuncListString += ", STRC=BLStruct}"
	endif
	
	Variable i
	for (i = 0; i < nPeaks; i += 1)
		String PeakTypeName = StringFromList(i+1, MPstruct.ListOfFunctions)
		
		FUNCREF MPF2_FuncInfoTemplate infoFunc=$(PeakTypeName+PEAK_INFO_SUFFIX)
		String PeakFuncName = 	infoFunc(PeakFuncInfo_PeakFName)
		if (strlen(PeakFuncName) == 0)
			return MPF2_Err_NoSuchPeakType
		endif

		String pwname = StringFromList(i+1, MPstruct.ListOfCWaveNames)
		pwname = PossiblyQuoteName(pwname)
		pwname = DataFolderName + pwname
		Wave/Z coefw = $pwname
		if (!WaveExists(coefw))
			return MPF2_Err_PeakCoefWaveNotFound
		endif
		
		MPstruct.FuncListString += "{"+PeakFuncName+","+pwname
		Duplicate/O coefw, $(NameOfWave(coefw)+"eps")
		Wave epsw = $(NameOfWave(coefw)+"eps")
		epsw = 1e-6
		MPstruct.FuncListString += ", EPSW="+GetWavesDataFolder(epsw,2)
		holdString = StringFromList(i+1, MPstruct.ListOfHoldStrings)			// i+1 to account for the fact that the first hold string goes with the baseline
		if (strlen(holdString) > 0)
			MPstruct.FuncListString += ", HOLD=\""+holdString+"\""
		endif
		MPstruct.FuncListString += "}"
	endfor

	Variable V_FitQuitReason = 0
	Variable V_FitMaxIters=5000
	if (MPStruct.fitMaxIters > 0)
		V_FitMaxIters=MPStruct.fitMaxIters
	endif
	Variable V_FitOptions=MPStruct.fitOptions
	variable /g v_fittol = .00001
//print MPstruct.FuncListString
	MPstruct.fitErrorMsg = ""
	
	QANT_MPF2_BackupCoefWaves(MPstruct.ListOfCWaveNames, DataFolderName)

	Variable errorCode=0
	DebuggerOptions
	Variable doDebugOnError = V_debugOnError
	DebuggerOptions debugOnError=0
	try
		Variable xPtRgBgn = MPstruct.XPointRangeBegin     //added to avoid FuncFit command being 400 chars - NH
		Variable xPtRgEnd = MPstruct.XPointRangeEnd                    				
		if (!WaveExists(MPstruct.Constraints))
			Make /T/Free/N=0 MPstruct.Constraints
		endif
		FuncFit/Q=1/N=(doUpdates==0?1:0)/M=2 {string=MPstruct.FuncListString} yw[xPtRgBgn,xPtRgEnd]/X=xw[xPtRgBgn,xPtRgEnd]/W=MPstruct.weightWave[xPtRgBgn,xPtRgEnd]/I=1/M=MPstruct.maskWave[xPtRgBgn,xPtRgEnd] /AD=(doAutoDest)/A=0/NWOK/C=MPstruct.constraints/D=$outputname;AbortOnRTE  
	catch
		MPstruct.fitErrorMsg = GetRTErrMessage()
		Variable semiPos = strsearch(MPstruct.fitErrorMsg, ";", 0)
		if (semiPos >= 0)
			String errWithPeaksNamed = QANT_MPF2_StringKToPeakNot(MPstruct.fitErrorMsg[semiPos+1, inf], MPstruct)
			MPstruct.fitErrorMsg = errWithPeaksNamed // MPstruct.fitErrorMsg[semiPos+1, inf]
		endif
		errorCode = GetRTError(1)
	endtry
	DebuggerOptions debugOnError=doDebugOnError
	
	MPstruct.dateTimeOfFit = DateTime
	MPstruct.fitPnts = V_npnts
	MPstruct.chisq = V_chisq
	MPstruct.fitError = errorCode
	MPstruct.fitQuitReason = V_FitQuitReason
		
	return MPF2_Err_NoError
end

static Function QANT_MPF2_BackupCoefWaves(listofWaveNames, DataFolderName, [backupName])
	String listofWaveNames, DataFolderName, backupName

	String saveDF = GetDataFolder(1)
	SetDataFolder DataFolderName
	
	Variable nWaves = ItemsInList(listofWaveNames)
	
	if (ParamIsDefault(backupName))
		backupName = "MPF2_CoefsBackup_"
	endif

	Variable i
	for (i = 0; i < nWaves; i += 1)
		Wave/Z coefs = $StringFromList(i, listofWaveNames)
		if (WaveExists(coefs))				// this is actually because the baseline coefficient wave may not exist.
			Duplicate/O coefs, $(backupName+num2istr(i))
		endif
	endfor
	
	SetDataFolder saveDF
end

Static Function /S QANT_MPF2_StringKToPeakNot(kString, MPStruct)
	String kString
	STRUCT MPFitInfoStruct &MPStruct

	Variable i, j
	
	Make /Free /N=(MPStruct.nPeaks+1) totalNCoefs
	
	/// get the total number of coefficients for each peak
	Variable doBaseLine = CmpStr(MPStruct.listOfFunctions[0], "None") != 0
	if (doBaseLine)
		FUNCREF MPF2_FuncInfoTemplate blinfo = $(StringFromList(0, MPStruct.listOfFunctions)+BL_INFO_SUFFIX)
		totalNCoefs[0] = ItemsInList(blinfo(BLFuncInfo_ParamNames))
	else
		totalNCoefs[0] = 0
	endif
	
	for (i = 1; i <= MPStruct.nPeaks; i += 1)
		String peakItem = "Peak "+num2istr(i-1)
		
		FUNCREF MPF2_FuncInfoTemplate peakInfoFunc=$(StringFromList(i, MPStruct.listOfFunctions)+PEAK_INFO_SUFFIX)
		totalNCoefs[i] = totalNCoefs[i-1] + ItemsInList(peakInfoFunc(PeakFuncInfo_ParamNames))
	endfor
	
	String regExprStr = "( [Kk][0-9]+ )(.*)"
	
	Variable peakNum, coefNum
	String ParamNames, replacementStr 
	String currPeakString = kString, ret = kString
	String substring1, substring2
	
	do 			// do baseline
		SplitString /E=(regExprStr) currPeakString, substring1, substring2
		currPeakString = substring2
		
		if (strlen(substring1))
			sscanf substring1, " %*[kK]%i ", coefNum
			
			for (j=0; j<MPStruct.nPeaks+1; j+=1)
				if (totalNCoefs[j] > coefNum)
					if (j==0)
						FUNCREF MPF2_FuncInfoTemplate blinfo = $(StringFromList(0, MPStruct.listOfFunctions)+BL_INFO_SUFFIX)
						ParamNames = blinfo(BLFuncInfo_ParamNames)
						replacementStr = "Baseline "+StringFromList(coefNum, ParamNames)
					else
						FUNCREF MPF2_FuncInfoTemplate peakInfoFunc=$(StringFromList(j, MPStruct.listOfFunctions)+PEAK_INFO_SUFFIX)
						ParamNames = peakInfoFunc(PeakFuncInfo_ParamNames)
						replacementStr = " Peak "+num2str(j-1)+" "+StringFromList(coefNum-totalNCoefs[j-1], ParamNames)+" "
					endif
					break
				endif
			endfor
			
			if (strlen(replacementStr))
				ret = ReplaceString(substring1, ret, replacementStr)
			endif
		else
			break
		endif		
		
	while(1)	
	
	return ret
End
function /wave QANT_PeakErrorFromFuncListSt(funcliststring,fitname,listofsigmawaves)
	string funcliststring, fitname, listofsigmawaves
	string peaktype, funcstring
	string foldersave = getdatafolder(1)
	setdatafolder ::
	make /t/o/n=(itemsinlist(funcliststring,"}")) $(cleanupname("pss_" +fitname,1))
	wave /t peakset = $cleanupname("pss_" + fitname,1)
	
	variable j
	if(itemsinlist(listofsigmawaves)<itemsinlist(funcliststring,"}"))
		for(j=0;j<itemsinlist(funcliststring,"}");j+=1)
			funcstring = stringfromlist(j,funcliststring,"}")
			funcstring = replacestring("{",funcstring,"")
			peaktype = stringfromlist(0,funcstring,",")
			wave coefwave = $stringfromlist(1,funcstring,",")
			duplicate /o coefwave, tempsigma
			tempsigma = 0
			tempsigma[1] = sqrt(coefwave[1]/1000)
			peakset[j] = QANT_translatepeak2Wooshka(peaktype,tempsigma)
		endfor
	else
		setdatafolder foldersave
		for(j=0;j<itemsinlist(funcliststring,"}");j+=1)
			funcstring = stringfromlist(j,funcliststring,"}")
			funcstring = replacestring("{",funcstring,"")
			peaktype = stringfromlist(0,funcstring,",")
			wave sigmawave = $stringfromlist(j,listofsigmawaves)
			peakset[j] = QANT_translatepeak2Wooshka(peaktype,sigmawave)
		endfor
	endif
	setdatafolder foldersave
	return peakset
end
function /wave QANT_PeakSetFromFuncListStr(funcliststring,fitname)
	string funcliststring, fitname
	
	
	string peaktype, funcstring
	string foldersave = getdatafolder(1)
	setdatafolder ::
	make /t/o/n=(itemsinlist(funcliststring,"}")) $(cleanupname("psr_" +fitname,1))
	wave /t peakset = $cleanupname("psr_" + fitname,1)
	variable j
	for(j=0;j<itemsinlist(funcliststring,"}");j+=1)
		funcstring = stringfromlist(j,funcliststring,"}")
		funcstring = replacestring("{",funcstring,"")
		peaktype = stringfromlist(0,funcstring,",")
		wave coefwave = $stringfromlist(1,funcstring,",")
		peakset[j] = QANT_translatepeak2Wooshka(peaktype,coefwave)
	endfor
	setdatafolder foldersave
	return peakset
end
function QANT_PeakFitResultsPanelfunc([val])
	variable val
	val = paramisdefault(val) ? 0 : val
	dowindow /k QANT_PeakFitResultsPanel
	string foldersave = getdatafolder(1)
	if(!datafolderexists("root:NEXAFS:Fitting"))
		return 0
	endif
	setdatafolder root:NEXAFS:fitting
	variable /g PlotCombinedArea
	variable /g plot16a
	string /g fitresult16a, fitresult17a, fitresultaligned
	
	NewPanel /n=QANT_PeakFitResultsPanel /W=(1040,569,1786,788) as "Peak Fitting Results"
	ModifyPanel fixedSize=1
	SetDrawLayer UserBack
	DrawText 12,23,"Fit Groups:"
	DrawText 154,23,"Fits in Group:"
	DrawText 329,23,"Peaks in Group:"
	ListBox list_groupFitResults,pos={13,25},size={130,147},proc=QANT_list_fitGroup
	ListBox list_groupFitResults,listWave=root:NEXAFS:fitting:ListOfGroupFits
	ListBox list_groupFitResults,selWave=root:NEXAFS:fitting:ListOfGroupFitsSel
	ListBox list_groupFitResults,row=max(0,val-5) ,mode= 1,selRow= val
	ListBox list_FitResults,pos={154,25},size={165,147},proc=QANT_List_FitResult
	ListBox list_FitResults,listWave=root:NEXAFS:fitting:ListOfFits
	ListBox list_FitResults,selWave=root:NEXAFS:fitting:ListOfFitsSel,mode= 1
	ListBox list_FitResults,selRow=val
	Button QANT_but_SaveGroup,pos={20,178},size={115,35},proc=QANT_SaveGroupToDisk,title="Save Group to Disk"
	Button QANT_but_SaveFit,pos={155,179},size={78,35},proc=QANT_but_SaveIndividualFit,title="Save Individual\rFit to Disk"
	ListBox list_PeakResults,pos={328,26},size={407,146},proc=QANT_List_Peaks
	ListBox list_PeakResults,listWave=root:NEXAFS:fitting:ListOfPeaks
	ListBox list_PeakResults,selWave=root:NEXAFS:fitting:ListOfPeaksSel
	ListBox list_PeakResults,titleWave=root:NEXAFS:fitting:listpeakcolumnnames,mode= 9
	ListBox list_PeakResults,widths={130,90,90,90},userColumnResize= 1
	CheckBox Chk_PlotArea,pos={328,179},size={60,14},proc=QANT_PeakResultCombinedChk,title="Plot Sum"
	CheckBox Chk_PlotArea,variable= root:NEXAFS:fitting:PlotCombinedArea
	Button QANT_but_SaveFit1,pos={237,178},size={78,35},proc=QANT_but_FitResult2PeakSet,title="Save Individual\rFit as Peak Set"
	SetVariable Var_CombinedResult16a,pos={480,178},size={120,16},title="9.16a"
	SetVariable Var_CombinedResult16a,value= root:NEXAFS:fitting:fitresult16a
	SetVariable Var_CombinedResult17a,pos={616,178},size={120,16},title="9.17a"
	SetVariable Var_CombinedResult17a,value= root:NEXAFS:fitting:fitresult17a
	PopupMenu popup0,pos={323,197},size={173,21},proc=QANT_Fit_PlotfitFormula_pop,title="Use: "
	PopupMenu popup0,mode=plot16a,value= #"\"Vector symmetry (Stšhr 9.16a);Planar symmetry (Stšhr 9.17a);In-Plane Alignment (Stšhr 9.14a)\""
	SetVariable Var_CombinedResultaligned,pos={547,197},size={120,16},title="9.14a"
	SetVariable Var_CombinedResultaligned,value= root:NEXAFS:fitting:fitresultaligned
	QANT_UpdateFitResults()
	setdatafolder foldersave
End

Function QANT_Chk_Plot16a(cba) : CheckBoxControl
	STRUCT WMCheckboxAction &cba

	switch( cba.eventCode )
		case 2: // mouse up
			Variable checked = cba.checked
			if(checked)
				checkbox QANT_Plot16a_chk title="Plotting 16.a"
				QANT_PlotPeakResults()
			else
				checkbox QANT_Plot16a_chk title="Plotting 17.a"
				QANT_PlotPeakResults()
			endif
			break
		case -1: // control being killed
			break
	endswitch

	return 0
End
Function QANT_list_fitGroup(lba) : ListBoxControl
	STRUCT WMListboxAction &lba
	lba.BlockReentry = 1
	Variable row = lba.row
	Variable col = lba.col
	WAVE/T/Z listWave = lba.listWave
	WAVE/Z selWave = lba.selWave
	string foldersave
	variable whichfile
	switch( lba.eventCode )
		case -1: // control being killed
			break
		case 1: // mouse down
			break
		case 3: // double click
			break
		case 4: // cell selection
		case 5: // cell selection plus shift key
			QANT_UpdateFitResults()
			break
		case 6: // begin edit
			break
		case 7: // finish edit
			break
		case 13: // checkbox clicked (Igor 6.2 or later)
			break
	endswitch

	return 0
End

function QANT_UpdateFitResults()
	ControlInfo /W=QANT_PeakFitResultsPanel list_GroupFitResults
	variable row = v_value
	string foldersave = getdatafolder(1)
	setdatafolder root:NEXAFS:Fitting:
	wave /t ListOfFits
	wave ListOfFitsSel
	wave /t ListOfPeaks
	wave /t ListOfPeaksSplitErr
	wave ListOfPeaksSel
	wave/t listofgroupfits
	wave listofgroupfitssel
	if(row<0 || row>=dimsize(listofgroupfits,0))
		redimension /n=1 ListOfFits, ListOfFitsSel,ListOfPeaks,ListOfPeaksSel
		listoffits = ""
		listofpeaks = ""
		listofFitsSel=0
		listofPeakssel=0
		return 0
	endif
	setdatafolder $listofgroupfits[row]
	
	redimension /n=(CountObjects("", 4 )) ListOfFits, ListOfFitsSel
	listofFits = GetIndexedObjName("", 4 ,p)
	ListofFitsSel =0
	variable whichpeak=0
	controlinfo list_FitResults
	if(v_value>=0 && v_value<dimsize(ListOfFits,0))
		whichpeak=v_value
	endif
	wave/wave peaksets
	wave /t peakset = peaksets[whichpeak]
	redimension /n=(dimsize(peakset,0),4) ListOfPeaks
	redimension /n=(dimsize(peakset,0),7) ListOfPeaksSplitErr
	redimension /n=(dimsize(peakset,0)) ListofPeaksSel
	ListOfPeaks[][0] = stringfromlist(0,peakset[p]) + " at " + stringfromlist(2,peakset[p])
	ListofPeaksSplitErr[][0] = ListofPeaks[p][0] 
	QANT_FitGroup(listofgroupfits[row],listoffits, listofpeaks, ListofPeaksSplitErr)
	setdatafolder foldersave
	QANT_PlotPeakResults()
end

Function QANT_list_fitresult(lba) : ListBoxControl
	STRUCT WMListboxAction &lba
	lba.BlockReentry = 1
	Variable row = lba.row
	Variable col = lba.col
	WAVE/T/Z listWave = lba.listWave
	WAVE/Z selWave = lba.selWave
	string foldersave
	switch( lba.eventCode )
		case -1: // control being killed
			break
		case 1: // mouse down
			break
		case 3: // double click
			break
		case 4: // cell selection
		case 5: // cell selection plus shift key
			foldersave = getdatafolder(1)
			setdatafolder root:NEXAFS:Fitting:
			wave /t ListOfGroupFits
			wave /t ListOfPeaks, ListOfPeaksSplitErr
			wave ListOfPeaksSel
			controlinfo list_GroupFitResults
			if(v_value<0 || v_value > dimsize(ListOfGroupFits,0)-1)
				break
			endif
			setdatafolder $ListOfGroupFits[v_value]
			
			if(row<0 || row>=dimsize(listwave,0))
				break
			endif
			wave/wave peaksets
			wave/t peakset = peaksets[row]
			redimension /n=(dimsize(peakset,0),4) ListOfPeaks
			redimension /n=(dimsize(peakset,0),7) ListOfPeaksSplitErr
			redimension /n=(dimsize(peakset,0)) ListofPeaksSel
			ListOfPeaks[][0] = stringfromlist(0,peakset[p]) + " at " + stringfromlist(2,peakset[p])
			listofpeaksspliterr[][0] = ListOfPeaks[p][0]
			setdatafolder foldersave
			QANT_PlotPeakResults()
			break
		case 6: // begin edit
			break
		case 7: // finish edit
			break
		case 13: // checkbox clicked (Igor 6.2 or later)
			break
	endswitch

	return 0
End
Function QANT_SaveSettoDisk(ba) : ButtonControl
	STRUCT WMButtonAction &ba

	switch( ba.eventCode )
		case 2: // mouse up
			svar PeakSetFit = root:NEXAFS:PeakSetFit
			wave peakset = root:NEXAFS:fitting:$peaksetfit
			
			QANT_ExportPeakSet(peakset)
			
			break
		case -1: // control being killed
			break
	endswitch

	return 0
End
function QANT_ExportPeakSet(wavein)
	wave /t wavein
	variable refnum
	open/D /F="Peak Set Files:.pks;All Files:.*;" /M="Choose where to save peaks Information" refnum as nameofwave(wavein)
	if(strlen(S_fileName)<2)
		return 0
	endif
	string outputpath = s_filename
	open refnum outputpath
	variable line=0,elem=0
	for(line=0;line<dimsize(wavein,0);line+=1)
		fprintf refNum, "%s	", stringfromlist(0,wavein[line])
		for (elem=1;elem<itemsinlist(wavein[line]);elem+=1)
			fprintf refNum, "%10g	", str2num(stringfromlist(elem,wavein[line]))
		endfor
		fprintf refnum, "\r"
	endfor
	close refnum
end
function QANT_ExportGroupofPeakSet(wavein)
	wave /wave wavein
	variable refnum
	NewPath/C/O/M="Select or Create directory for your files" savePeaksDirectory
	if(v_flag)
		print "Failed to create directory"
		return 0
	endif
	variable i
	for(i=0;i<dimsize(wavein,0);i+=1)
		wave/t peakset = wavein[i]
		open/p=savePeaksDirectory refnum nameofwave(peakset)
		variable line=0,elem=0
		for(line=0;line<dimsize(peakset,0);line+=1)
			fprintf refNum, "%s	", stringfromlist(0,peakset[line])
			for (elem=1;elem<itemsinlist(peakset[line]);elem+=1)
				fprintf refNum, "%10g	", str2num(stringfromlist(elem,peakset[line]))
			endfor
			fprintf refnum, "\r"
		endfor
		close refnum
	endfor
end
function QANT_ExportData(whichdata)
	string whichdata
	QANT_CalcNormalizations(whichdata)
	variable exportall
	if(StringMatch(whichdata,"all")) // this isn't working
		exportall = 1
	else
		exportall =0
	endif
	string foldersave = getdatafolder(1)
	setdatafolder root:NEXAFS
	svar x_axis,normchan
	nvar NormCursors
	if(datafolderexists("Normalizeddata") && NormCursors)
		setdatafolder NormalizedData
	elseif(datafolderexists("RefCorrecteddata") && cmpstr(normchan,"none"))
		setdatafolder RefCorrectedData
	elseif(datafolderexists("DarkCorrected"))
		setdatafolder DarkCorrected
	else
		print "Nothing new to save"
		setdatafolder foldersave
		return 0
	endif
	
	variable tries=0, refnum
	do
		if(tries>0)
			NewPath/q/z/C/O/M="Invalid Directory.  Please Select or Create directory for your files" saveDataDirectory
		else
			NewPath/q/z/C/O/M="Select or Create directory for your files" saveDataDirectory
		endif
		if(v_flag)
			//print "Failed to create directory"
			setdatafolder foldersave
			return 0
		endif
		open/a/z/p=saveDataDirectory refnum "testfile.txt"
		if(v_flag==0)
			close refnum
			DeleteFile /z /p=saveDataDirectory "testfile..txt"
			break
		endif
		tries+=1
	while(v_flag)
	
	variable i,j
	variable numscans = countobjects("",4)
	string listofwaves, nameofscan, tempdatafolder
	string header = ""
	for(i=0;i<numscans;i+=1)
		nameofscan = GetIndexedObjName("", 4, i )
		if(findlistitem(nameofscan,whichdata)==-1 && !exportall)
			continue
		endif
		setdatafolder $nameofscan
		listofwaves = wavelist("*",";","")
		if(WhichListItem(x_axis,listofwaves))
			listofwaves = removefromlist(x_axis,listofwaves)
			listofwaves = x_axis +";"+ listofwaves // put xaxis first
		endif
		header = "File Produced by QANTv1.12 by Eliot Gann at the Australian Synchrotron and NIST (eliot.gann@nist.gov)\r"
		header += "----------------------------------------------------\rList of dataseries and their notes:\r\r" 
		for(j=0;j<itemsinlist(listofwaves);j+=1)
			header += stringfromlist(j,listofwaves)+"\r"
			header += note($stringfromlist(j,listofwaves)) + "\r\r"
		endfor
		tempdatafolder = getdatafolder(1)
		setdatafolder $("root:NEXAFS:Scans:"+possiblyquotename(nameofscan))
		header += "----------------------------------------------------\rList of strings or notes regarding this dataset:\r\r" 
		for(j=0;j<countobjects("",3);j+=1)
			svar stringvariable = $GetIndexedObjName("", 3, j )
			header += GetIndexedObjName("", 3, j ) +" = " + stringvariable + "\r\r"
		endfor
		header += "-----------------------------------------------------\rList of numeric variables regarding this dataset:\r\r" 
		for(j=0;j<countobjects("",2);j+=1)
			nvar numericvariable = $GetIndexedObjName("", 2, j )
			header += GetIndexedObjName("", 2, j ) + " = " + num2str(numericvariable) + "\r\r"
		endfor
		wave /z /t extrapvs
		if(waveexists(extrapvs))
			header += "-----------------------------------------------------\rExtra PVs:\r\r" 
			for(j=0;j<dimsize(extrapvs,0);j+=1)
				header += extrapvs[j][0] + "	" + extrapvs[j][1] + "	" + extrapvs[j][2] + "	" + extrapvs[j][3] + "\r"
			endfor
		endif
		header += "\r\rData---------------------------------------------------\r\r" 
		setdatafolder tempdatafolder
		open/p=saveDataDirectory refnum nameofscan +".txt"
		fbinwrite refNum, header 
		close refnum
		
		Save/A/p=saveDataDirectory/J/W/B listofwaves as nameofscan +".txt"
		setdatafolder ::
	endfor
	setdatafolder foldersave
end




Function QANT_LoadPeakSet_button(ba) : ButtonControl
	STRUCT WMButtonAction &ba

	switch( ba.eventCode )
		case 2: // mouse up
			variable refnum
			open /D/R/MULT=1 /F="Peak Set Files:.pks;All Files:.*;" /M="Choose File(s) to Load" refnum
			string outputpaths = s_filename
			string wname
			string fileline, s1, s2, s3, s4, s5, s6, s7, s8, s9, s10
			variable i
			variable line, eof
			for(i=0;i<Itemsinlist(outputpaths,"\r");i+=1)
				open refnum stringfromlist(i,outputpaths,"\r")
				wname = ParseFilePath(3, s_filename, ":", 0, 0)
				make /o/t/n=100 root:NEXAFS:Fitting:$wname // maximum of 100 peaks to read from file
				wave/t peakset =  root:NEXAFS:Fitting:$wname
				do
					freadline refnum, fileline
					if(strlen(fileline)==0)
						eof=1
					else
						splitstring /e="^([[:alpha:]_]*)\\s*([^\\s]*)\\s*([^\\s]*)\\s*([^\\s]*)\\s*([^\\s]*)\\s*([^\\s]*)\\s*([^\\s]*)\\s*([^\\s]*)\\s*([^\\s]*)" fileline, s1, s2, s3, s4, s5, s6, s7, s8, s9, s10
						peakset[line] = s1 +";"+ s2 +";"+ s3 +";"+ s4 +";"+ s5 +";"+ s6 +";"+ s7 +";"+ s8 +";"+ s9 +";"+ s10
						line+=1
					endif
				while(eof==0 && line<100)
				redimension /n=(line) peakset
				close refnum
			endfor
			break
		case -1: // control being killed
			break
	endswitch

	return 0
End

Function QANT_but_SaveIndividualFit(ba) : ButtonControl
	STRUCT WMButtonAction &ba

	switch( ba.eventCode )
		case 2: // mouse up
			controlinfo list_FitResults
			variable selrow = v_value
			if(selrow<0)
				break
			endif
			controlinfo list_groupFitResults
			variable selgrouprow = v_value
			if(selgrouprow<0)
				break
			endif
			wave/t ListOfFits = root:NEXAFS:fitting:ListOfFits
			wave/t ListOfGroupFits = root:NEXAFS:fitting:ListOfGroupFits
			wave/wave peaksets = $("root:NEXAFS:fitting:" + possiblyquotename(ListOfGroupFits[selgrouprow])+":peaksets")
			wave/t peakset = peaksets[selrow] // this simplifies things considerably, just record where the peaksets are initially!
			if(waveexists(peakset))
				QANT_ExportPeakSet(peakset)
			else
				print "error in finding peakset"
			endif
			break
		case -1: // control being killed
			break
	endswitch

	return 0
End

Function QANT_but_FitResult2PeakSet(ba) : ButtonControl
	STRUCT WMButtonAction &ba

	switch( ba.eventCode )
		case 2: // mouse up
			controlinfo list_FitResults
			variable selrow = v_value
			if(selrow<0)
				break
			endif
			controlinfo list_groupFitResults
			variable selgrouprow = v_value
			if(selgrouprow<0)
				break
			endif
			wave/t ListOfFits = root:NEXAFS:fitting:ListOfFits
			wave/t ListOfGroupFits = root:NEXAFS:fitting:ListOfGroupFits
			wave/wave peaksets = $("root:NEXAFS:fitting:" + possiblyquotename(ListOfGroupFits[selgrouprow])+":peaksets")
			wave/t peakset = peaksets[selrow]
			if(waveexists(peakset))
				duplicate peakset, $("root:NEXAFS:fitting:"+Cleanupname(ListOfFits[selrow],1))
			else
				print "error in finding peakset"
			endif
			break
		case -1: // control being killed
			break
	endswitch

	return 0
End

function QANT_GetAngle(name) // tries several options to find the angle of a scan based on it's name
	string name // this is a scanname
	// name will contain the filll scanname, but may have other strings tagged on
	// first search for the complete name
	//string foldername="" // this is where we will put the actual foldername which we will access
	//wave/t scans = root:NEXAFS:Scanlist
	//findvalue /text=name scans // simpliest is if the name actually appears in scanlist
	//if(v_value>=0)
		// we've found it!
		string foldername = name
	//else
	//	string testname = name
	//	testname = replacestring("psr__",testname,"")
	//	testname = replacestring("psr_",testname,"")
	//	testname = replacestring("_psr",testname,"")
	//	do
	//		testname = removeending(testname) // now try removing the last character one and a time - hopefully one of these will match a scanname (we append things onto the name for plotting
	//		findvalue /text=testname scans
	//	while( strlen(testname)>1 && v_value<0 )
	//	foldername = scans[mod(v_value,dimsize(scans,0))][0] // the name might originate from any column of scans, unfortunately
	//endif
	//if(v_value<0) // nothing was successful
	//	print "Error finding scan"
	//	return -1
	//endif
	svar/z anglestr = $("root:NEXAFS:Scans:"+possiblyquotename(foldername)+":anglestr")
	variable angle
	if(svar_exists(anglestr))
		angle = str2num(anglestr)
	else
		// is the angle in the name itself?
		// for giwaxs, use a stringmatch
		string testangle
		splitstring /e="_(0p[0123456789]*)_" name , testangle 
		angle= str2num(replacestring("p",testangle,"."))
	endif
	return angle
end
function QANT_getOther(name) // tries several options to find the angle of a scan based on it's name
	string name // this is a scanname
	string foldername = name
	svar/z otherstr = $("root:NEXAFS:Scans:"+possiblyquotename(foldername)+":otherstr")
	variable angle
	if(svar_exists(otherstr))
		angle = str2num(otherstr)
	else
		angle=nan
	endif
	return angle
end

function /s QANT_GetName(name)
	string name
	// name will contain the filll scanname, but may have other strings tagged on
	// first search for the complete name
	string foldername=name // this is where we will put the actual foldername which we will access
//	wave/t scans = root:NEXAFS:Scanlist
//	findvalue /text=name scans
//	if(v_value>=0)
//		// we've found it!
//		foldername = name
//	else
//		string testname=name
//		testname = replacestring("psr__",testname,"")
//		testname = replacestring("psr_",testname,"")
//		testname = replacestring("_psr",testname,"")
//		findvalue /text=testname scans
//		if(strlen(testname)>1 && v_value<0)
//			do
//				testname = removeending(testname)
//				findvalue /text=testname scans
//			while( strlen(testname)>1 && v_value<0 )
//		endif
//		foldername = scans[mod(v_value,dimsize(scans,0))][0]
//	endif
//	if(v_value<0)
//		print "Error finding scan"
//		return name
//	endif
	svar/z notesstr = $("root:NEXAFS:Scans:"+possiblyquotename(foldername)+":samplename")
	string notes
	if(svar_exists(notesstr))
		notes = notesstr
	else
		notes= foldername
	endif
	return notes
end


Function QANT_List_Peaks(lba) : ListBoxControl
	STRUCT WMListboxAction &lba
	lba.BlockReentry = 1
	Variable row = lba.row
	Variable col = lba.col
	WAVE/T/Z listWave = lba.listWave
	WAVE/Z selWave = lba.selWave

	switch( lba.eventCode )
		case -1: // control being killed
			break
		case 1: // mouse down
			break
		case 3: // double click
			break
		case 4: // cell selection
		case 5: // cell selection plus shift key
			lba.BlockReentry = 1
			QANT_PlotPeakResults()
			break
		case 6: // begin edit
			break
		case 7: // finish edit
			break
		case 13: // checkbox clicked (Igor 6.2 or later)
			break
	endswitch

	return 0
End
function QANT_PlotPeakResults()
	wave/t listw = root:NEXAFS:Fitting:ListOfGroupFits
	wave selwave = root:NEXAFS:Fitting:ListOfPeaksSel
	controlinfo list_groupFitResults
	if(v_value<0 || v_value >= dimsize(listw,0) || !waveexists(listw) || !waveexists(selwave) )
		return -1
	endif
	string fitname = listw[v_value]
	nvar combined = root:NEXAFS:fitting:PlotCombinedArea
	nvar plot16a =  root:NEXAFS:fitting:plot16a
	string foldersave = getdatafolder(1)
	setdatafolder root:NEXAFS:Fitting
	setdatafolder $possiblyquotename(fitname)
	string listofpeaksets = wavelist("*psr*",";","")
	variable nfits = itemsinlist(listofpeaksets) // the number of fits which we are going to plot
	//make /o/n=(nfits) /WAVE peaksets = $stringfromlist(p,listofpeaksets)
	wave /wave peaksets
	wave /wave peakerrors
	wave /t fitnames // the full paths to the original data which was fit
	make /o/n=(dimsize(fitnames,0)) /t scannames
	variable j
	string fitname1,scanname1
	for(j=0;j<dimsize(fitnames,0);j+=1)
		fitname1 = fitnames[j]
		splitstring /e=":([^:]*):[^:]*$" fitname1,scanname1
		scannames[j]=scanname1
	endfor
	make /o/n=(dimsize(angles,0)) /wave scanwaves = $fitnames[p]
	// peaksets is now a wave of waves (textwaves) which comtain all the information about the peaks
	// peak errors is a mirror wave to above, but the wave in it contain all the information about uncertainty in the above parameters
	setdatafolder ::
	
	newdatafolder /o/s plotting // keep all plotted waves in this folder
	newdatafolder /o/s $possiblyquotename(fitname)
	dowindow QANT_ResultPlot 
	
	variable i, useangles = 1, useother = 0
	if(v_flag==0)
		display /hide=1 /k=1 /n=QANT_Resultplot as "Plot of Peak Intensities"
	else
		string listoftraces = tracenamelist("QANT_Resultplot",";",1)
		for(i=0;i<itemsinlist(listoftraces);i+=1)
			removefromgraph/w=QANT_Resultplot /z $stringfromlist(i,listoftraces)
		endfor
	endif
	//print GetWavesDataFolder(tracenametowaveref("QANT_Resultplot",stringfromlist(0,listofpeaksets)),0)
	make /o/n=(nfits) angles = QANT_getAngle(scannames[p])
	
	if(wavemin(angles) == wavemax(angles) || sum(angles)*0 != 0)
		make /o/n=(nfits) angles = QANT_getAngle(fitnames[p])
		if(wavemin(angles) == wavemax(angles) || sum(angles)*0 != 0)
		// try other ? 
			make /o/n=(nfits) angles = QANT_getOther(scannames[p])
			if(wavemin(angles) == wavemax(angles) || sum(angles)*0 != 0)
				// try beamlineenergy from wavenotes?
				angles = numberbykey("BeamlineEnergy",note(scanwaves[p]), "=",";")
				if(wavemin(angles) == wavemax(angles) || sum(angles)*0 != 0)
					killwaves angles
					useangles=0
					make /o/n=(nfits)/t names =  QANT_getName(scannames[p])
				else
					useother=1
				endif
			else
				useother=1
			endif
		endif
	endif
	string wname = ""
	variable angleout 
	variable npeaks = dimsize(selwave,0) // note this is different than npeaks in the fitting code
										// because this includes the background function
	// create a wave for each peak that is choses (that is, go through selwave and if there is a 1
		//create a wave that is named the same as the corresponding peak (ie GAUSS_285eV)
		// the length of that wave should be the number of peaksets
		// each element of that wave should be the area calculated from each peakset for that peak
	variable nwavesplotted=0
	if(combined)
		make /o/n=(nfits) SumofAreas=0, ErrorofSumofAreas=0
		if(useangles)
			appendtograph /w=QANT_Resultplot SumofAreas vs angles
			Label  /w=QANT_Resultplot bottom "Angle [deg]"
		else
			appendtograph /w=QANT_Resultplot SumofAreas vs names
		endif
		Label  /w=QANT_Resultplot  left "Peak Area [AU]"
		ErrorBars /w=QANT_Resultplot  SumofAreas Y,wave=(ErrorofSumofAreas,ErrorofSumofAreas)
	endif
	for(i=0;i<npeaks;i+=1)
		if(selwave(i))
			wname= QANT_GetNameofPeak(Peaksets[0],i)
			make /o/n=(nfits) $wname
			make /o/n=(nfits) $cleanupname("e_"+wname,1)
			wave peakareas = $wname
			wave peakerror = $cleanupname("e_"+wname,1)
			peakareas = QANT_getareaofpeak(peaksets[p],i)
			peakerror =  QANT_geterrorofpeak(peaksets[p],peakerrors[p],i)
			if(useangles)
				appendtograph /w=QANT_Resultplot $wname vs angles
				sort angles, peakareas, peakerror
			else
				appendtograph /w=QANT_Resultplot $wname vs names
			endif
			if(combined)
				ErrorofSumofAreas = sqrt(ErrorofSumofAreas^2 + peakerror^2)
				SumofAreas +=PeakAreas
			endif
			ErrorBars /w=QANT_Resultplot  $wname Y,wave=(peakerror,peakerror)
			nwavesplotted+=1
			wave adjustments
			if(waveexists(adjustments))
				peakareas /= adjustments
			endif
		endif
	endfor
	
	if(nwavesplotted>0)
		if(useangles)
			sort angles, angles
			modifygraph /w=QANT_Resultplot mode=4, marker=19, log(left)=1
		else
			ModifyGraph /w=QANT_Resultplot mode=5,toMode=3,tkLblRot(bottom)=90
		endif
		dowindow /hide=0 /f QANT_Resultplot
		dowindow /f QANT_PeakFitResultsPanel
		Legend/w=QANT_Resultplot/N=text0/A=RC/X=3.87/Y=2.31/C/E
		QANT_ColorTraces("SpectrumBlack","QANT_Resultplot")
		if(useangles && combined && sum(angles)*0 ==0)
			make /o/n=3 w_coef = {45,10}
			//print "working"
			//print W_coef
			//print peakareas
			//print peakerror
			//print angles
			
			svar fitresult16a = root:NEXAFS:fitting:fitresult16a
			svar fitresult17a = root:NEXAFS:fitting:fitresult17a
			svar fitresultaligned = root:NEXAFS:fitting:fitresultaligned
			if(useother)
				
			elseif(plot16a==1) // do all the other fits which will not be in the final plot, and store those values
				FuncFit/W=2/q/H="00"/NTHR=0 QANT_Nexafs_Plane_9_17a W_coef  SumofAreas /I=1 /w=ErrorofSumofAreas /X=angles /D
				wave w_sigma 
				angleout = abs(mod(w_coef[0],360))
				angleout = angleout>180 ? angleout-180 : angleout
				angleout = angleout>90 ? 180-angleout : angleout
				sprintf fitresult17a, "%2.4g ± %2.2g", angleout, w_sigma[0]
				FuncFit/W=2/q/H="00"/NTHR=0 QANT_Nexafs_Alignment_9_14a W_coef  SumofAreas /I=1 /w=ErrorofSumofAreas /X=angles /D
				wave w_sigma
				angleout = abs(mod(w_coef[0],360))
				angleout = angleout>180 ? angleout-180 : angleout
				angleout = angleout>90 ? 180-angleout : angleout
				sprintf fitresultaligned, "%2.4g ± %2.2g", angleout, w_sigma[0]
			elseif(plot16a==2)
				FuncFit/W=2/q/H="00"/NTHR=0 QANT_Nexafs_Vector_9_16a W_coef  SumofAreas /I=1 /w=ErrorofSumofAreas /X=angles /D
				wave w_sigma
				angleout = abs(mod(w_coef[0],360))
				angleout = angleout>180 ? angleout-180 : angleout
				angleout = angleout>90 ? 180-angleout : angleout
				sprintf fitresult16a, "%2.4g ± %2.2g", angleout, w_sigma[0]
				FuncFit/W=2/q/H="00"/NTHR=0 QANT_Nexafs_Alignment_9_14a W_coef  SumofAreas /I=1 /w=ErrorofSumofAreas /X=angles /D
				wave w_sigma
				angleout = abs(mod(w_coef[0],360))
				angleout = angleout>180 ? angleout-180 : angleout
				angleout = angleout>90 ? 180-angleout : angleout
				sprintf fitresultaligned, "%2.4g ± %2.2g", angleout, w_sigma[0]
			elseif(plot16a==3)
				FuncFit/W=2/q/H="00"/NTHR=0 QANT_Nexafs_Plane_9_17a W_coef  SumofAreas /I=1 /w=ErrorofSumofAreas /X=angles /D 
				wave w_sigma
				angleout = abs(mod(w_coef[0],360))
				angleout = angleout>180 ? angleout-180 : angleout
				angleout = angleout>90 ? 180-angleout : angleout
				sprintf fitresult17a, "%2.4g ± %2.2g", angleout, w_sigma[0]
				FuncFit/W=2/q/H="00"/NTHR=0 QANT_Nexafs_Vector_9_16a W_coef  SumofAreas /I=1 /w=ErrorofSumofAreas /X=angles /D
				wave w_sigma
				angleout = abs(mod(w_coef[0],360))
				angleout = angleout>180 ? angleout-180 : angleout
				angleout = angleout>90 ? 180-angleout : angleout
				sprintf fitresult16a, "%2.4g ± %2.2g", angleout, w_sigma[0]
			endif
			
			 // do the final fit of the data
			if(useother)
				K2 = 2*pi/180;
				CurveFit/W=2/q/H="0010"/NTHR=0 sin SumofAreas  /I=1 /w=ErrorofSumofAreas /F={.95, 1, Contour} /X=angles /D 
			elseif(plot16a==1)
				FuncFit/W=2/q/H="00"/NTHR=0 QANT_Nexafs_Vector_9_16a W_coef  SumofAreas /I=1 /w=ErrorofSumofAreas /F={.95, 1, Contour} /X=angles /D
			elseif(plot16a==2)
				FuncFit/W=2/q/H="00"/NTHR=0 QANT_Nexafs_Plane_9_17a W_coef  SumofAreas /I=1 /w=ErrorofSumofAreas /F={.95, 1, Contour} /X=angles /D
			elseif(plot16a==3)
				FuncFit/W=2/q/H="00"/NTHR=0 QANT_Nexafs_Alignment_9_14a W_coef  SumofAreas /I=1 /w=ErrorofSumofAreas  /F={.95, 1, Contour} /X=angles /D 
			endif
			RemoveFromGraph/z UP_SumofAreas,LP_SumofAreas,UC_SumofAreas,LC_SumofAreas
			wave UC_SumofAreas, LC_SumofAreas
			if(useangles)
				appendtograph UC_SumofAreas /TN='+95% Confidence', LC_SumofAreas /TN='-95% Confidence'
			else
				appendtograph UC_SumofAreas /TN='+95% Confidence', LC_SumofAreas /TN='-95% Confidence'
			endif
			wave w_sigma
			ModifyGraph /w=QANT_Resultplot  mode('+95% Confidence')=7,toMode('+95% Confidence')=1
			ModifyGraph /w=QANT_Resultplot  hbFill('+95% Confidence')=5,rgb('+95% Confidence')=(65280,65280,16384);DelayUpdate
			ModifyGraph /w=QANT_Resultplot  rgb('-95% Confidence')=(65280,65280,0)
			ReorderTraces /w=QANT_Resultplot  SumofAreas,{'+95% Confidence','-95% Confidence'}
			angleout = abs(mod(w_coef[0],360))
			angleout = angleout>180 ? angleout-180 : angleout
			angleout = angleout>90 ? 180-angleout : angleout
			if(useother)
				string sincurveresults = "Fit to a sin wave with period of 180 gives"
				string format ="%2.3g ± %2.1g\r Minimum R2 = %2.3g ± %2.1g"
			//	//sincurveresults += "\rY offset = " + num2str(w_coef[0]) + " +/- " + num2str(w_sigma[0]) 
			//	//sincurveresults += "\rAmplitude = " + num2str(w_coef[1])  + " +/- " + num2str(w_sigma[1]) 
			//	sincurveresults += "\rDichroic Ratio = " + num2str(w_coef[1]/w_coef[0])  + " ± " + num2str(sqrt((w_sigma[1]/w_coef[0])^2 + (w_coef[1]*w_sigma[0]/w_coef[0]^2)^2 )) 
			//	sincurveresults += "\rMinimum R2 = " + num2str(-w_coef[3]* 180/(2*pi) - 45)  + " ± " + num2str(abs(w_sigma[3]* 180/(2*pi)) ) 
				variable val1 = w_coef[1]/w_coef[0]
				variable val2 = sqrt((w_sigma[1]/w_coef[0])^2 + (w_coef[1]*w_sigma[0]/w_coef[0]^2)^2 )
				variable val3 = -w_coef[3]* 180/(2*pi) - 45
				variable val4 = abs(w_sigma[3]* 180/(2*pi)) 
				sprintf sincurveresults, format, val1,val2,val3,val4 
				sincurveresults = "Fit to a sin wave with period of 180 gives\rDichroic Ratio = "+sincurveresults
				TextBox/C/N=text1/A=RB/X=5.00/Y=15.00/E=2 sincurveresults
			elseif(plot16a==1)
				if(w_sigma[0]<1)
					sprintf fitresult16a, "%2.4g ± %2.2g", angleout, w_sigma[0]
				else
					sprintf fitresult16a, "%2.3g ± %2.1g", angleout, w_sigma[0]
				endif
				//fitresult16a= num2str(angleout)+" ± " + num2str(w_sigma[0])
				TextBox/C/N=text1/A=RB/X=5.00/Y=15.00/E=2 "Fit to the vector symmetry formula Stšhr 9.16a\r\\F'Symbol'g\\F]0 = " + fitresult16a
			elseif(plot16a==2)
				if(w_sigma[0]<1)
					sprintf fitresult17a, "%2.4g ± %2.2g", angleout, w_sigma[0]
				else
					sprintf fitresult17a, "%2.3g ± %2.1g", angleout, w_sigma[0]
				endif
				TextBox/C/N=text1/A=RB/X=5.00/Y=15.00/E=2 "Fit to the planar symmetry formula Stšhr 9.17a\r\\F'Symbol'g\\F]0 = " + fitresult17a
			elseif(plot16a==3)
				if(w_sigma[0]<1)
					sprintf fitresultaligned, "%2.4g ± %2.2g", angleout, w_sigma[0]
				else
					sprintf fitresultaligned, "%2.3g ± %2.1g", angleout, w_sigma[0]
				endif
				TextBox/C/N=text1/A=RB/X=5.00/Y=15.00/E=2 "Fit to the vector symmetry with in-plane alignment Stšhr 9.14a\r\\F'Symbol'g\\F]0 = " + fitresultaligned
			endif
			putscrapText num2str(angleout) + "\t" + num2str(w_sigma[0])
		else
			svar fitresult16a = root:NEXAFS:fitting:fitresult16a
			svar fitresult17a = root:NEXAFS:fitting:fitresult17a
			svar fitresultaligned = root:NEXAFS:fitting:fitresultaligned
			fitresult16a=""
			fitresult17a=""
			fitresultaligned=""
			TextBox/K/N=text1
		endif
	else
		dowindow /hide=1 QANT_Resultplot
	endif
	setdatafolder foldersave
end

function /s QANT_GetNameofPeak(peakset,peaknum)
	wave /t peakset
	variable peaknum
	string peakname
	peakname = stringfromlist(0,peakset[peaknum]) + "_at_" + stringfromlist(2,peakset[peaknum])
	return peakname
end
function QANT_geterrorofpeak(peakset,peakerror, peaknum)
	wave/t peakset, peakerror
	variable peaknum
	variable totalpeakerror, peakarea
	string peaktype = stringfromlist(0,peakset[peaknum])
	variable height = str2num(stringfromlist(1,peakset[peaknum]))
	variable sheight =  str2num(stringfromlist(1,peakerror[peaknum]))
	variable location = str2num(stringfromlist(2,peakset[peaknum]))
	variable slocation = str2num(stringfromlist(2,peakerror[peaknum]))
	variable width = str2num(stringfromlist(3,peakset[peaknum]))
	variable swidth = str2num(stringfromlist(3,peakerror[peaknum]))
	variable other = str2num(stringfromlist(4,peakset[peaknum]))
	variable sother = str2num(stringfromlist(4,peakerror[peaknum]))
	strswitch(peaktype)
		case "GAUSSIAN":
			peakarea = height*width*sqrt(pi/ln(2))/2
			totalpeakerror = peakarea * sqrt( (sheight/height)^2 + (swidth/width)^2 )
			break
		case "NEXAFS_EDGE":
			peakarea = height
			totalpeakerror = sheight
			break
		default:
			peakarea = height*width
			totalpeakerror = peakarea * sqrt( (sheight/height)^2 + (swidth/width)^2 )
	endswitch
	return totalpeakerror
end
function QANT_getareaofpeak(peakset, peaknum)
	wave/t peakset
	variable peaknum
	variable peakarea
	string peaktype = stringfromlist(0,peakset[peaknum])
	variable height = str2num(stringfromlist(1,peakset[peaknum]))
	variable location = str2num(stringfromlist(2,peakset[peaknum]))
	variable width = str2num(stringfromlist(3,peakset[peaknum]))
	variable other = str2num(stringfromlist(4,peakset[peaknum]))
	strswitch(peaktype)
		case "GAUSSIAN":
			peakarea = height*width*sqrt(pi/ln(2))/2
			break
		case "NEXAFS_EDGE":
			peakarea = height
			break
		default:
			peakarea = height*width
	endswitch
	return peakarea
end


Function QANT_Nexafs_Vector_9_16a(w,theta) : FitFunc
	Wave w
	Variable theta

	//CurveFitDialog/ These comments were created by the Curve Fitting dialog. Altering them will
	//CurveFitDialog/ make the function less convenient to work with in the Curve Fitting dialog.
	//CurveFitDialog/ Equation:
	//CurveFitDialog/ f(theta) = Offset+Scaling* (1/3)*(1+(1/2)*(3*cos(theta*pi/180)^2-1)*(3*cos(gamma*pi/180)^2-1))
	//CurveFitDialog/ End of Equation
	//CurveFitDialog/ Independent Variables 1
	//CurveFitDialog/ theta
	//CurveFitDialog/ Coefficients 3
	//CurveFitDialog/ w[0] = gamma
	//CurveFitDialog/ w[1] = Scaling

	return w[1]* (1/3)*(1+(1/2)*(3*cos(theta*pi/180)^2-1)*(3*cos(w[0]*pi/180)^2-1))
End

Function QANT_Nexafs_Plane_9_17a(w,Theta) : FitFunc
	Wave w
	Variable Theta

	//CurveFitDialog/ These comments were created by the Curve Fitting dialog. Altering them will
	//CurveFitDialog/ make the function less convenient to work with in the Curve Fitting dialog.
	//CurveFitDialog/ Equation:
	//CurveFitDialog/ theta =  (Offset+theta)*pi/180
	//CurveFitDialog/ 
	//CurveFitDialog/ f(theta) = Scaling* (2/3)*(1-(1/4)*(3*cos(theta)^2-1)*(3*cos(gamma*pi/180)^2-1))
	//CurveFitDialog/ End of Equation
	//CurveFitDialog/ Independent Variables 1
	//CurveFitDialog/ Theta
	//CurveFitDialog/ Coefficients 2
	//CurveFitDialog/ w[0] = Gamma
	//CurveFitDialog/ w[1] = Scaling

	return  w[1]* (2/3)*(1-(1/4)*(3*cos(theta*pi/180)^2-1)*(3*cos(w[0]*pi/180)^2-1))
End


Function QANT_Nexafs_Alignment_9_14a(w,theta) : FitFunc
	Wave w
	Variable theta

	//CurveFitDialog/ These comments were created by the Curve Fitting dialog. Altering them will
	//CurveFitDialog/ make the function less convenient to work with in the Curve Fitting dialog.
	//CurveFitDialog/ Equation:
	//CurveFitDialog/ f(theta) = Scaling* (cos(Gamma*pi/180)^2 + sin(Gamma*pi/180)^2 * cos(theta*pi/180)^2) 
	//CurveFitDialog/ End of Equation
	//CurveFitDialog/ Independent Variables 1
	//CurveFitDialog/ theta
	//CurveFitDialog/ Coefficients 2
	//CurveFitDialog/ w[0] = Gamma
	//CurveFitDialog/ w[1] = Scaling

	return w[1]* ( sin(w[0]*pi/180)^2 * sin(theta*pi/180)^2 +  Cos(w[0]*pi/180)^2 * Cos(theta*pi/180)^2 ) 
End

Function QANT_Fit_PlotfitFormula_pop(pa) : PopupMenuControl
	STRUCT WMPopupAction &pa

	switch( pa.eventCode )
		case 2: // mouse up
			Variable popNum = pa.popNum
			String popStr = pa.popStr
			nvar plot16a =  root:NEXAFS:fitting:plot16a
			plot16a = popnum
			QANT_PlotPeakResults()
			break
		case -1: // control being killed
			break
	endswitch

	return 0
End

Function QANT_PeakResultCombinedChk(cba) : CheckBoxControl
	STRUCT WMCheckboxAction &cba

	switch( cba.eventCode )
		case 2: // mouse up
			Variable checked = cba.checked
			cba.blockReentry = 1
			QANT_PlotPeakResults()
			break
		case -1: // control being killed
			break
	endswitch

	return 0
End

Function QANT_SaveGroupToDisk(ba) : ButtonControl
	STRUCT WMButtonAction &ba

	switch( ba.eventCode )
		case 2: // mouse up
			controlinfo list_groupFitResults
			variable selgrouprow = v_value
			if(selgrouprow<0)
				break
			endif
			wave/t ListOfFits = root:NEXAFS:fitting:ListOfFits
			wave/t ListOfGroupFits = root:NEXAFS:fitting:ListOfGroupFits
			//make /wave/o/n=(dimsize(ListOfFits,0)) Peaksets
			wave /wave peaksets = $("root:NEXAFS:fitting:" + possiblyquotename(ListOfGroupFits[selgrouprow])+":peaksets")
			make /o/n=(dimsize(ListOfFits,0)) peaksetvalid = waveexists(peaksets[p])
			if(sum(peaksetvalid)==dimsize(peaksetvalid,0))
				QANT_ExportGroupofPeakSet(peaksets)
			else
				print "error in finding peakset"
			endif
			break
		case -1: // control being killed
			break
	endswitch

	return 0
End

Function QANT_ExportAllData_but(ba) : ButtonControl
	STRUCT WMButtonAction &ba

	switch( ba.eventCode )
		case 2: // mouse up
			// click code here
			QANT_ExportData("all")
			break
		case -1: // control being killed
			break
	endswitch

	return 0
End

function QANT_ColorTraces(Colortabname,Graphname)
	string colortabname, graphname
	
	if(cmpstr(graphName,"")==0)
		graphname = WinName(0, 1)
	endif
	if (strlen(graphName) == 0)
		return -1
	endif

	Variable numTraces =itemsinlist(TraceNameList(graphName,";",1))
	if (numTraces <= 0)
		return -1
	endif
	variable numtracesden=numtraces
	if( numTraces < 2 )
		numTracesden= 2	// avoid divide by zero, use just the first color for 1 trace
	endif

	ColorTab2Wave $colortabname
	wave RGB = M_colors
	Variable numRows= DimSize(rgb,0)
	Variable red, green, blue
	Variable i, index
	for(i=0; i<numTraces; i+=1)
		index = round(i/(numTracesden-1) * (numRows*2/3-1))	// spread entire color range over all traces.
		ModifyGraph/w=$graphName rgb[i]=(rgb[index][0], rgb[index][1], rgb[index][2])
	endfor
end

function QANT_FitGroup(fitgroupname,listoffits,listofpeaks, ListOfPeaksSplitErr)
	string fitgroupname
	wave/t listofpeaks, listoffits, ListOfPeaksSplitErr
	wave/wave peaksets
	nvar combined = root:NEXAFS:fitting:PlotCombinedArea
	// we will populate columns 1 and 2 of list of peaks, if we can fit them
	string foldersave = getdatafolder(1)
	setdatafolder root:NEXAFS:fitting
	setdatafolder $fitgroupname
	wave /t fitnames // the full paths to the original data which was fit
	make /O/n=(dimsize(fitnames,0)) /t scannames
	make /O/wave/n=(dimsize(fitnames,0)) fitwaves = $fitnames[p]
	scannames[] = GetWavesDataFolder(fitwaves[p],0)
	make/o /n=(dimsize(listoffits,0)) angles = QANT_getAngle(scannames[p])
	if(sum(angles)*0!=0)
		scannames[] = fitnames[p]
		make/o /n=(dimsize(listoffits,0)) angles = QANT_getAngle(scannames[p])
		if(sum(angles)*0!=0)
			listofpeaks[][1]="Bad Alpha"
			listofpeaks[][2]="Bad Alpha"
			listofpeaks[][3]="Bad Alpha"
			ListOfPeaksSplitErr[][1,6]="Bad Alpha"
			return 0
		endif
	endif
	string listofpeaksets = wavelist("*psr*",";","")
	variable nfits = itemsinlist(listofpeaksets) // the number of fits which we are going to fit
	//make /o/n=(nfits) /WAVE peaksets = $stringfromlist(p,listofpeaksets)
	wave /wave peaksets
	wave /wave peakerrors
	variable npeaks = dimsize(listofpeaks,0)
	variable i, angleout, errorout

	make /o/n=(nfits) tempwave
	if(abs(wavemax(angles)-wavemin(angles))<.001 || sum(angles)*0 != 0)
		listofpeaks[][1] = "Invalid Angles"
		listofpeaks[][2] = "Invalid Angles"
		listofpeaks[][3] = "Invalid Angles"
		ListOfPeaksSplitErr[][1,6]="Invalid Angles"
		setdatafolder foldersave
		return 0
	endif
	string wname, tempstring
	listofpeaks[0][1,3] = "N/A"
	ListOfPeaksSplitErr[0][1,6] = "N/A"
	for(i=1;i<npeaks;i+=1)
		make /o/n=2 w_coef = {45,10}, w_sigma=0
		wname= "temppeak"
		make /o/n=(nfits) $wname
		make /o/n=(nfits) $cleanupname("e_"+wname,1)
		wave peakareas = $wname
		wave peakerror = $cleanupname("e_"+wname,1)
		peakareas = QANT_getareaofpeak(peaksets[p],i)
		peakerror =  QANT_geterrorofpeak(peaksets[p],peakerrors[p],i)
		
		variable V_FitError = 0
		make /o/t constraints = {"K0 > 0","K0 < 90"}

		//FuncFit/W=2/q/H="001"/NTHR=0  QANT_Nexafs_Vector_9_16a W_coef  peakareas /i=1 /w=peakerror /C=constraints /X=angles /D 
//		print "not working"
//		print W_coef
//		print peakareas
//		print peakerror
//		print angles
		FuncFit/W=2/q/H="00"/NTHR=0 QANT_Nexafs_Vector_9_16a W_coef  peakareas /I=1 /w=peakerror /X=angles /D 
		if(V_FitError)
			listofpeaks[i][1] = "fit error"
			ListOfPeaksSplitErr[i][1,2]="fit error"
		else
			errorout = w_sigma[0]
			angleout = abs(mod(w_coef[0],360))
			angleout = angleout>180 ? angleout-180 : angleout
			angleout = angleout>90 ? 180-angleout : angleout
			if(errorout < 1)
				sprintf tempstring, "%2.4g ± %2.1g", angleout, errorout
			else
				sprintf tempstring, "%2.3g ± %2.1g", angleout, errorout
			endif			
			listofpeaks[i][1] = tempstring
			ListOfPeaksSplitErr[i][1]=num2str(angleout)
			ListOfPeaksSplitErr[i][2]=num2str(errorout)
		endif
		constraints = {"K0 > 0","K0 < 90"}
		V_FitError = 0
		//FuncFit/W=2/q/H="001"/NTHR=0 QANT_Nexafs_Plane_9_17a W_coef  peakareas  /i=1 /w=peakerror /C=constraints /X=angles /D 
		FuncFit/W=2/q/H="00"/NTHR=0 QANT_Nexafs_Plane_9_17a W_coef  peakareas /I=1 /w=peakerror /X=angles /D 
		if(V_FitError)
			listofpeaks[i][2] = "fit error"
			ListOfPeaksSplitErr[i][3,4]="fit error"
		else
			errorout = w_sigma[0]
			angleout = abs(mod(w_coef[0],360))
			angleout = angleout>180 ? angleout-180 : angleout
			angleout = angleout>90 ? 180-angleout : angleout
			if(errorout < 1)
				sprintf tempstring, "%2.4g ± %2.1g", angleout, errorout
			else
				sprintf tempstring, "%2.3g ± %2.1g", angleout, errorout
			endif			
			listofpeaks[i][2] = tempstring
			ListOfPeaksSplitErr[i][3]=num2str(angleout)
			ListOfPeaksSplitErr[i][4]=num2str(errorout)
		endif
		FuncFit/W=2/q/H="00"/NTHR=0 QANT_Nexafs_Alignment_9_14a W_coef  peakareas /I=1 /w=peakerror /X=angles /D 
		if(V_FitError)
			listofpeaks[i][3] = "fit error"
			ListOfPeaksSplitErr[i][5,6]="fit error"
		else
			errorout = w_sigma[0]
			angleout = abs(mod(w_coef[0],360))
			angleout = angleout>180 ? angleout-180 : angleout
			angleout = angleout>90 ? 180-angleout : angleout
			if(errorout < 1)
				sprintf tempstring, "%2.4g ± %2.1g", angleout, errorout
			else
				sprintf tempstring, "%2.3g ± %2.1g", angleout, errorout
			endif			
			listofpeaks[i][3] = tempstring
			ListOfPeaksSplitErr[i][5]=num2str(angleout)
			ListOfPeaksSplitErr[i][6]=num2str(errorout)
		endif
	endfor
	setdatafolder root:NEXAFS:fitting
	string cwaves = wavelist("cwave*",",","")
	for(i=0;i<itemsinlist(cwaves,",");i+=1)
		killwaves $stringfromlist(i,cwaves,",")
	endfor
	
	setdatafolder foldersave
end

Function QANT_ExportSelData_but(ba) : ButtonControl
	STRUCT WMButtonAction &ba

	switch( ba.eventCode )
		case 2: // mouse up
			// click code here
			// get list of selected scans
			string whichitems = ""
			wave /t scanlist = root:NEXAFS:scanlist
			wave selwave = root:NEXAFS:selwavescanlist
			duplicate /free selwave, selwavescanlist
			selwavescanlist =selwave? 1 : 0
			variable i
			for(i=0;i<dimsize(scanlist,0);i+=1)
				if(selwavescanlist[i])
					whichitems += scanlist[i][0] + ";"
				endif
			endfor
			QANT_ExportData(whichitems)
			break
		case -1: // control being killed
			break
	endswitch

	return 0
End

Function QANT_tweakZeroSetVarProc(sva) : SetVariableControl
	STRUCT WMSetVariableAction &sva

	switch( sva.eventCode )
		case 1: // mouse up
		case 2: // Enter key
		case 3: // Live update
			Variable dval = sva.dval
			String sval = sva.sval
			QANT_CalcNormalizations("selected")
			break
		case -1: // control being killed
			break
	endswitch

	return 0
End

Function QANT_tweakZeroSliderProc(sa) : SliderControl
	STRUCT WMSliderAction &sa

	switch( sa.eventCode )
		case -1: // control being killed
			break
		default:
			if( sa.eventCode & 1 ) // value set
				Variable curval = sa.curval
				QANT_CalcNormalizations("selected")
			endif
			break
	endswitch

	return 0
End

function QANT_TweakZeroValuesfunc()
	dowindow /k QANT_TweakZeroValues
	variable /g root:NEXAFS:phdcorr
	variable /g root:NEXAFS:mcpcorr
	NewPanel /n=QANT_TweakZeroValues /W=(1139,146,1612,334) as "Tweak Zero Values"
	ModifyPanel fixedSize=1
	SetVariable QANT_MCPCORR,pos={1,2},size={150,16},proc=QANT_tweakZeroSetVarProc,title="MCP Correction"
	SetVariable QANT_MCPCORR,limits={-inf,inf,0.001},value= root:NEXAFS:mcpcorr,live= 1
	Slider slider0,pos={5,26},size={459,58},proc=QANT_tweakZeroSliderProc
	Slider slider0,limits={-1,1,0.01},variable= root:NEXAFS:mcpcorr,vert= 0
	SetVariable QANT_MCPCORR1,pos={3,109},size={150,16},proc=QANT_tweakZeroSetVarProc,title="PHD Correction"
	SetVariable QANT_MCPCORR1,limits={-inf,inf,0.001},value= root:NEXAFS:phdcorr,live= 1
	Slider slider1,pos={2,134},size={459,58},proc=QANT_tweakZeroSliderProc
	Slider slider1,limits={-1,1,0.01},variable= root:NEXAFS:phdcorr,vert= 0
EndMacro

Function QANT_adjoffsets(ba) : ButtonControl
	STRUCT WMButtonAction &ba

	switch( ba.eventCode )
		case 2: // mouse up
			// click code here
			QANT_TweakZeroValuesfunc()
			break
		case -1: // control being killed
			break
	endswitch

	return 0
End


function /s QANT_DarkList()
	string listout = ""
	string foldersave = getdatafolder(1)
	setdatafolder root:NEXAFS
	if(datafolderexists("darks"))
		setdatafolder darks
		variable num = countobjects("", 4)
		variable k
		for(k=0;k<num;k+=1)
			listout += getindexedobjName("", 4, k )+";"
		endfor
	endif
	listout += "Default;none" 
	setdatafolder foldersave
	return listout
end
function /s QANT_RefList()
	string listout = ""
	string foldersave = getdatafolder(1)
	setdatafolder root:NEXAFS
	if(datafolderexists("Refs"))
		setdatafolder refs
		variable num = countobjects("", 4)
		variable k
		for(k=0;k<num;k+=1)
			listout += getindexedobjName("", 4, k )+";"
		endfor
	endif
	listout += "Default;none"
	setdatafolder foldersave
	return listout
end
function QANT_ShowDarks()
	dowindow /k QANT_DarkScans_win
	NewPanel /K=1/n=QANT_DarkScans_win /W=(150,83,644,399) as "Dark Scans"
	ModifyPanel fixedSize=1
	string foldersave = getdatafolder(1)
	setdatafolder root:NEXAFS
	newdatafolder /o/s darks
	wave/t darks
	wave darkssel
	make/o/t /n=(3) labels = {"Name","Default?","Energy"} 
	make/o/t /n=(2) labelschan = {"Name","Value"} 
	string darklist = removefromlist("none",removefromlist("Default",QANT_Darklist()))
	variable numdarks = itemsinlist(darklist)
	if(numdarks<1)
		make/o/t /n=(1,3) darks = ""
		make/o /n=(1,3) darkssel =  {{2},{48},{2}}
	else
		make/o/t /n=(numdarks,3) darks 
		darks[][0] = stringfromlist(p,darklist)
		darks[][1] = ""
		darks[][2] = ""
		make/o /n=(numdarks,3) darkssel
		darkssel[][0] = 2
		darkssel[][1] = 32
		darkssel[][2] = 2
	endif
	make/o/t /n=(1,2) darkchannels = ""
	make/o /n=(1,2) darkchannelssel = {{2},{2}}
	
	SetDrawLayer UserBack
	DrawText 10,19,"Darks"
	DrawText 229,21,"Dark Values"
	ListBox Darkslist,pos={5,24},size={193,226},proc=QANT_Darks_ListBoxProc
	ListBox Darkslist,listWave=root:NEXAFS:darks:darks
	ListBox Darkslist,selWave=root:NEXAFS:darks:darkssel
	ListBox Darkslist,titleWave=root:NEXAFS:darks:labels,mode= 5,widths={25,18,18}
	ListBox DarkChannellist,pos={221,24},size={268,228},proc=QANT_DarkChannel_ListBoxProc
	ListBox DarkChannellist,listWave=root:NEXAFS:darks:darkchannels
	ListBox DarkChannellist,selWave=root:NEXAFS:darks:darkchannelssel
	ListBox DarkChannellist,titleWave=root:NEXAFS:darks:labelschan,mode= 5
	Slider slider0,pos={180,254},size={300,58},proc=QANT_Dark_SliderProc
	Slider slider0,limits={0,0.320531,0.00128213},vert= 0,DISABLE=1
	Button button1,pos={42,260},size={70,40},proc=QANT_RemoveDarkBut,title="Remove\rDark"
	QANT_UpdateDarks()
	setdatafolder foldersave
End

Function QANT_adjDarks(ba) : ButtonControl
	STRUCT WMButtonAction &ba

	switch( ba.eventCode )
		case 2: // mouse up
			// click code here
			QANT_ShowDarks()
			break
		case -1: // control being killed
			break
	endswitch

	return 0
End
Function QANT_adjRefs(ba) : ButtonControl
	STRUCT WMButtonAction &ba

	switch( ba.eventCode )
		case 2: // mouse up
			// click code here
			QANT_ShowRefs()
			break
		case -1: // control being killed
			break
	endswitch

	return 0
End
Function QANT_ExportGraph_but(ba) : ButtonControl
	STRUCT WMButtonAction &ba

	switch( ba.eventCode )
		case 2: // mouse up
			// click code here
			string windowlist = winlist("*",";","WIN:1")
			if(itemsinlist(windowlist)>0)
				QANT_ExportGraph()
			endif
			break
		case -1: // control being killed
			break
	endswitch

	return 0
End

function QANT_ExportGraph()
	string listoftraces = tracenamelist("",";",1)
	variable i
	string copystring="Energy	"
	string tracename = ""
	variable num = itemsinlist(listoftraces)
	make /free /wave /n=(num) ywaves, xwaves
	for(i=0;i<num;i+=1)
		tracename = stringfromlist(i,listoftraces)
		xwaves[i] = XWaveRefFromTrace("",tracename)
		ywaves[i] = TraceNameToWaveRef("",tracename)
		copystring += tracename + "	"
	endfor
	copystring += "\r"
	make /n=(dimsize(ywaves[0],0),num+1) /Free /d outputwave
	if(!waveexists(xwaves[0]))
		duplicate/o ywaves[0], x0wave
	else
		wave x0wave = xwaves[0]
	endif
	outputwave[][0] = x0wave[p]
	variable badscans=0
	for(i=0;i<dimsize(ywaves,0);i+=1)
		if(!waveexists(xwaves[i]))
			duplicate/o ywaves[i], tempxwave
			tempxwave=x
			xwaves[i] = tempxwave
		endif
		if(wavemax(xwaves[i]) < wavemin(x0wave) || wavemin(xwaves[i]) > wavemax(x0wave))
			print "Skipping "+stringfromlist(i,listoftraces) + " because the energy range is wrong, please copy different energy ranges seperately"
			outputwave[][i+1] = nan
			badscans=1
			continue
		endif
		outputwave[][i+1] = interp(x0wave[p],xwaves[i],ywaves[i])
	endfor
	string tempstr
	variable j
	for(i=0;i<dimsize(xwaves[0],0);i+=1)
		tempstr = num2str(outputwave[i][0]) + "	"
		for(j=0;j<num;j+=1)
			tempstr += num2str(outputwave[i][j+1]) + "	"
		endfor
		copystring += removeending(tempstr) + "\r"
	endfor
	PutScrapText copystring
	if(badscans)
		DoAlert /T="Exporting Graph" 0, "Please note that one or more of the scans were not in the same energy range, and so at least one export failed.\rPlease export different energy ranges seperately"
	endif
end

Function QANT_popRef(pa) : PopupMenuControl
	STRUCT WMPopupAction &pa

	switch( pa.eventCode )
		case 2: // mouse up
			Variable popNum = pa.popNum
			String popStr = pa.popStr
			string foldersave = getdatafolder(1)
			setdatafolder root:NEXAFS
			
			wave selwave = selwavescanlist
			duplicate /free selwave, selwavescanlist
			selwavescanlist = selwavescanlist>0 ? 1 : 0
			wave /t scanlist
			setdatafolder scans
			variable i
			for(i=0;i<sum(selwavescanlist);i+=1)
				if(i==0)
					findvalue /v=1 /T=.1 /z selwavescanlist // find selected Scan
				else
					findvalue /s=(v_value+1) /v=1 /T=.1 /z selwavescanlist // find next selected Scan
				endif
				setdatafolder $scanlist[v_value][0] // goto selected scan so we can set the notes variable
				svar refscan
				refscan = popStr
				setdatafolder ::
			endfor
			setdatafolder foldersave
			QANT_listNEXAFSscans()
			break
		case -1: // control being killed
			break
	endswitch

	return 0
End

Function QANT_ChangeEnergySel()
	// put up prompt to get the new energy value
	string foldersave = getdatafolder(1)
	setdatafolder root:NEXAFS
	QANT_listNEXAFSscans()
	wave selwave = selwavescanlist
	duplicate /free selwave, selwavescanlist
	selwavescanlist = selwavescanlist>0 ? 1 : 0
	wave /t scanlist
	setdatafolder scans
	variable i, newoffset
	prompt newoffset, "Set Energy Offset"
	doprompt /HELP="Choose the new energy offset for the selected scans" "Enter the new energy offset for the selected scans",newoffset
	
	if(v_flag || !(newoffset<100 && newoffset>-100))
		return 0
	endif
	for(i=0;i<sum(selwavescanlist);i+=1)
		if(i==0)
			findvalue /v=1 /T=.1 /z selwavescanlist // find selected Scan
		else
			findvalue /s=(v_value+1) /v=1 /T=.1 /z selwavescanlist // find next selected Scan
		endif
		setdatafolder $scanlist[v_value][0] // goto selected scan so we can set the notes variable
		svar enoffset
		enoffset = num2str(newoffset)
		setdatafolder ::
	endfor
	setdatafolder foldersave
	QANT_listNEXAFSscans()
End

Function QANT_popDark(pa) : PopupMenuControl
	STRUCT WMPopupAction &pa

	switch( pa.eventCode )
		case 2: // mouse up
			Variable popNum = pa.popNum
			String popStr = pa.popStr
			string foldersave = getdatafolder(1)
			setdatafolder root:NEXAFS
			wave selwave = root:NEXAFS:selwavescanlist
			duplicate /free selwave, selwavescanlist
			selwavescanlist =selwave? 1 : 0
			wave /t scanlist
			setdatafolder scans
			variable i
			for(i=0;i<sum(selwavescanlist);i+=1)
				if(i==0)
					findvalue /v=1 /T=.1 /z selwavescanlist // find selected Scan
				else
					findvalue /s=(v_value+1) /v=1 /T=.1 /z selwavescanlist // find next selected Scan
				endif
				setdatafolder $scanlist[v_value][0] // goto selected scan so we can set the notes variable
				svar darkscan
				darkscan = popStr
				setdatafolder ::
			endfor
			setdatafolder foldersave
			QANT_listNEXAFSscans()
			break
		case -1: // control being killed
			break
	endswitch

	return 0
End

Function QANT_Colorpop(pa) : PopupMenuControl
	STRUCT WMPopupAction &pa

	switch( pa.eventCode )
		case 2: // mouse up
			Variable popNum = pa.popNum
			String popStr = pa.popStr
			svar ctable = root:NEXAFS:Colortable
			ctable = popstr
			QANT_replotdata()
			break
		case -1: // control being killed
			break
	endswitch

	return 0
End

Function QANT_Darks_ListBoxProc(lba) : ListBoxControl
	STRUCT WMListboxAction &lba
	lba.BlockReentry = 1
	Variable row = lba.row
	Variable col = lba.col
	WAVE/T/Z listWave = lba.listWave
	WAVE/Z selWave = lba.selWave
	string foldersave = getdatafolder(1)
	setdatafolder root:nexafs:darks
	variable i
	string varlist 
	switch( lba.eventCode )
		case -1: // control being killed
			break
		case 1: // mouse down
			break
		case 3: // double click
			//add a new dark with no dark values
			if(row>=dimsize(listwave,0))
				newdatafolder $uniquename("dark",11,0)
				row = dimsize(listwave,0)
			endif
			
			QANT_updatedarks()
			break
		case 4: // cell selection
		case 5: // cell selection plus shift key
			// based on row, populate dark values 
			wave/t darkchannels
			wave darkchannelssel
			if(row<0 || row>=dimsize(listwave,0))
				break
			endif
			setdatafolder $listwave[row][0]
			varlist = VariableList("*_mean", ";", 4)
			if(strlen(varlist)>0)
				redimension /n=(itemsinlist(varlist),2) darkchannels, darkchannelssel
				darkchannelssel = 2
				darkchannels[][0] = removeending(stringfromlist(p,varlist),"_mean")
				for(i=0;i<itemsinlist(varlist);i+=1)
					nvar tempvar = $stringfromlist(i,varlist)
					darkchannels[i][1] = num2str(tempvar)
				endfor
			else
				darkchannels = {{""},{""}}
				darkchannelssel = {{2},{2}}
			endif
			break
		case 6: // begin edit
			break
		case 7: // finish edit
		// if column is 0, then change the folder name
			if(row<0 || row>=dimsize(listwave,0))
				break
			endif
			if(col==0)
				string foldername
				for(i=0;i<countobjects("",4);i+=1)
					foldername = getindexedobjname("",4,i)
					findvalue /Text=foldername/TXOP=4 /z listwave
					if(v_value==-1)
						renamedatafolder $foldername, $listwave[i][0]
					endif
				endfor
				QANT_CalcNormalizations("selected")
				break
			elseif(col==2)
		// if column is 2, then change energy range
				setdatafolder listwave[row][0]
				
				variable enrange = str2num(listwave[row][2])
				if(enrange*0==0)
					string /g en_range = listwave[row][2]
					selwave[row][1]=48
					// gothrough all other darks, and if they are selected, then unselect them
					for(i=0;i<dimsize(listwave,0);i+=1)
						if(i==row)
							continue
						endif
						if(strlen(listwave[i][2])>0 && abs(str2num(listwave[i][2])-enrange) < 1.5)
							setdatafolder ::
							setdatafolder listwave[i][0]
							string/g en_range=""
						endif
					endfor
				else
					string /g en_range = ""
				endif
				QANT_CalcNormalizations("selected")
				break
			endif
		case 13: // checkbox clicked (Igor 6.2 or later)
		// set that dark as default for the energy range
			if(row<0 || row>=dimsize(listwave,0))
				break
			endif
			if(selwave[row][1]==48)
				//selwave[row][1]=48
			// make sure that others are unchecked
			// set en_range in the correct folder to the starting energy
				setdatafolder listwave[row][0]
				string/g default_dark="yes"
				for(i=0;i<dimsize(listwave,0);i+=1)
					if(i==row)
						continue
					endif
					setdatafolder ::
					setdatafolder listwave[i][0]
					string/g default_dark=""
					
				endfor
			else
				//selwave[row][1]=32
				setdatafolder listwave[row][0]
				string/g default_dark=""
				// set en_range to nothing
			endif
			QANT_CalcNormalizations("selected")
			break
	endswitch
	
	
//	setdatafolder root:nexafs:darks
//	wave darkssel
//	wave/t darks
//	variable realrow
//	if(row<0)
//		darkssel[0][0]=3
//		realrow=0
//	elseif(row>=dimsize(darkssel,0))
//		darkssel[dimsize(darkssel,0)-1][0]=3
//		realrow = dimsize(darkssel,0)-1
//	else
//		darkssel[row][0]=3
//		realrow=row
//	endif
//	wave/t darkchannels
//	wave darkchannelssel
//	if(realrow<0 || realrow>=dimsize(darks,0))
//		setdatafolder foldersave
//		return 0
//	endif
//	setdatafolder $darks[realrow][0]
//	varlist = VariableList("*_mean", ";", 4)
//	if(strlen(varlist)>0)
//		redimension /n=(itemsinlist(varlist)+1,2) darkchannels, darkchannelssel
//		darkchannelssel = 2
//		darkchannels[][0] = removeending(stringfromlist(p,varlist),"_mean")
//		for(i=0;i<itemsinlist(varlist);i+=1)
//			nvar tempvar = $stringfromlist(i,varlist)
//			darkchannels[i][1] = num2str(tempvar)
//		endfor
//		darkchannelssel[i][0]=2
//		darkchannelssel[i][1]=0
//	else
//		darkchannels = {{""},{""}}
//		darkchannelssel = {{2},{0}}
//	endif
//	variable /g temp
//	Slider slider0, win=QANT_DarkScans_win, disable=1, value=0, variable=temp
//	setdatafolder foldersave
	return 0
End



Function QANT_DarkChannel_ListBoxProc(lba) : ListBoxControl
	STRUCT WMListboxAction &lba
	lba.BlockReentry = 1
	Variable row = lba.row
	Variable col = lba.col
	WAVE/T/Z listWave = lba.listWave
	WAVE/Z selWave = lba.selWave
	string foldersave = getdatafolder(1)
	setdatafolder root:NEXAFS:Darks
	wave /t darks
	wave darkssel
	variable i
	string darkname = ""
	for(i=0;i<dimsize(darks,0);i+=1)
		if(darkssel[i][0] &1)
			darkname = darks[i][0]
		endif
	endfor
	setdatafolder darkname
	string varlist = variablelist("*_mean",";",4)
	switch( lba.eventCode )
		case -1: // control being killed
			break
		case 1: // mouse down
			break
		case 3: // double click
			break
		case 4: // cell selection
		case 5: // cell selection plus shift key
			// update the slider to adjust that variable, make sure that the variable exists
			if(row<0 || row>=dimsize(selwave,0))
				Slider slider0, win=QANT_DarkScans_win, disable=1, value=0
				break
			endif
			nvar vartemp = $stringfromlist(row,varlist)
			Slider slider0, limits={0,max(2*vartemp,.01),abs(max(2*vartemp,.01)/100)},variable=$("root:NEXAFS:darks:"+darkname+":"+stringfromlist(row,varlist)),vert= 0, disable=0
			break
		case 6: // begin edit

			break
		case 7: // finish edit
			
			if(col==0)
				if(row<0 || row<dimsize(listwave,0)-1)
					rename $possiblyquotename(stringfromlist(row,varlist)) , $possiblyquotename(cleanupname(listwave[row][0]+"_mean",1))
				else
					variable /g $(listwave[row][0]+"_mean")
				endif
				
			else
				nvar tempvar = $stringfromlist(row,varlist)
				tempvar = str2num(listwave[row][1])
				Slider slider0, limits={0,max(2*tempvar,.01),abs(max(2*tempvar,.01)/250)}
			endif
			varlist = VariableList("*_mean", ";", 4)
			if(strlen(varlist)>0)
				redimension /n=(itemsinlist(varlist)+1,2) listwave, selwave
				selwave = 2
				listwave[][0] = removeending(stringfromlist(p,varlist),"_mean")
				for(i=0;i<itemsinlist(varlist);i+=1)
					nvar tempvar = $stringfromlist(i,varlist)
					listwave[i][1] = num2str(tempvar)
				endfor
				selwave[i][0]=2
				selwave[i][1]=0
			else
				listwave = {{""},{""}}
				selwave = {{2},{0}}
			endif
			selwave[row][0]=3
			QANT_CalcNormalizations("selected")
			break
		case 13: // checkbox clicked (Igor 6.2 or later)
			break
	endswitch
	
	setdatafolder foldersave
	return 0
End

Function QANT_Dark_SliderProc(sa) : SliderControl
	STRUCT WMSliderAction &sa

	switch( sa.eventCode )
		case -1: // control being killed
			break
		default:
			if( sa.eventCode & 1 ) // value set
				Variable curval = sa.curval
				string foldersave = getdatafolder(1)
				setdatafolder root:NEXAFS:darks
				wave/t darks, darkchannels
				wave darkssel, darkchannelssel
				string darkname = ""
				variable i
				variable darkselectedrow
				for(i=0;i<dimsize(darks,0);i+=1)
					if(darkssel[i][0] &1)
						darkname = darks[i][0]
						darkselectedrow = i
					endif
				endfor
				setdatafolder $darkname
				string varlist = VariableList("*_mean", ";", 4)
				for(i=0;i<itemsinlist(varlist);i+=1)
					nvar tempvar = $stringfromlist(i,varlist)
					darkchannels[i][1] = num2str(tempvar)
				endfor
				setdatafolder foldersave
				QANT_CalcNormalizations("selected")
				darkssel[darkselectedrow][0] = 3
				dowindow/F  QANT_DarkScans_win
			endif
			if( sa.eventCode & 4 )
				Slider slider0, limits={0,max(2*sa.curval,.01),abs(max(2*sa.curval,.01)/250)}
				
			endif
			break
	endswitch

	return 0
End

Function QANT_popDarkref(pa) : PopupMenuControl // on the reference management panel
	STRUCT WMPopupAction &pa

	switch( pa.eventCode )
		case 2: // mouse up
			Variable popNum = pa.popNum
			String popStr = pa.popStr
			string foldersave = getdatafolder(1)
			setdatafolder root:NEXAFS
			wave selwave = root:NEXAFS:selwavescanlist
			duplicate /free selwave, selwavescanlist
			selwavescanlist =selwave? 1 : 0
			wave /t scanlist
			setdatafolder refs
			wave/t refs
			wave refssel
			setdatafolder ::
			
			setdatafolder scans
			variable i
			for(i=0;i<dimsize(refs,0);i+=1)
				if(refssel[i][0] & 1)
					findvalue /text=refs[i][0] scanlist
				endif
			endfor
			setdatafolder $scanlist[v_value][0] // goto selected scan so we can set the notes variable
			svar darkscan
			darkscan = popStr
			setdatafolder ::
			setdatafolder foldersave
			QANT_ListNEXAFSScans()
			QANT_CalcNormalizations("selected")
			break
		case -1: // control being killed
			break
	endswitch

	return 0
End

function QANT_ShowRefs()
	dowindow /k QANT_RefScans_win
	NewPanel /K=1/n=QANT_RefScans_win /W=(217,330,1042,676) as "Reference Scans"
	ModifyPanel fixedSize=1
	string foldersave = getdatafolder(1)
	setdatafolder root:NEXAFS
	newdatafolder /o/s refs
	wave/t /z refs
	wave /z refssel
	make/o/t /n=(3) labels = {"Name","Default?","Energy"} 
	variable/g minsearch, maxsearch, peakloc, smsize
	minsearch = minsearch<1 ? 288 : minsearch
	maxsearch = maxsearch<1 ? 294 : maxsearch
	peakloc = peakloc < 1 ? 291.65 : peakloc
	
	SetDrawLayer UserBack
	DrawText 27,54,"References"
	DrawText 514,312,"New scans loaded will be calibrated by these values"
	DrawText 514,326,"Change the search values to 0 for this to NOT happen"
	DrawText 252,56,"I0 Correction Value (Contamination on I0)"
	GroupBox group1,pos={9,14},size={497,323},title="Intensity Calibration"
	GroupBox group1,labelBack=(65280,59904,48896)
	ListBox refslist,pos={22,59},size={193,226},proc=QANT_refs_ListBoxProc
	ListBox refslist,listWave=root:NEXAFS:refs:refs,selWave=root:NEXAFS:refs:refssel
	ListBox refslist,titleWave=root:NEXAFS:refs:labels,mode= 5,widths={25,18,18}
	PopupMenu QANT_popup_darkSelref,pos={238,306},size={239,21},bodyWidth=96,proc=QANT_popdarkref,title="Dark to use for this reference:"
	PopupMenu QANT_popup_darkSelref,mode=5,popvalue="Default",value= #"QANT_darkList()"
	Button QANT_RemRef_But,pos={59,295},size={70,40},proc=QANT_RemoveRefBut,title="Remove\rReference"
	GroupBox group0,pos={512,12},size={302,323},title="Energy Calibration"
	GroupBox group0,labelBack=(48896,65280,57344)
	SetVariable QANT_Var_EnCal_MinSearch,pos={569,41},size={214,16},bodyWidth=80,title="Minimum X value for search"
	SetVariable QANT_Var_EnCal_MinSearch,value= root:NEXAFS:refs:minsearch
	SetVariable QANT_Var_EnCal_MaxSearch,pos={566,63},size={217,16},bodyWidth=80,title="Maximum X value for search"
	SetVariable QANT_Var_EnCal_MaxSearch,value= root:NEXAFS:refs:maxsearch
	SetVariable QANT_Var_EnCal_CorrectLoc,pos={555,85},size={228,16},bodyWidth=80,title="Calibrated X Location for Peak"
	SetVariable QANT_Var_EnCal_CorrectLoc,value= root:NEXAFS:refs:peakloc
	SetVariable QANT_Var_EnCal_Smoothing,pos={599,107},size={184,16},bodyWidth=80,title="Smoothing size (pnts)"
	SetVariable QANT_Var_EnCal_Smoothing,value= root:NEXAFS:refs:smsize
	Button QANT_EnCal_but,pos={520,160},size={140,50},proc=QANT_butUpdateEnCal,title="Update Calibrations for\rEach Individual Scan in\rChosen Energy Range"
	Button QANT_EnCal_rem_but,pos={520,230},size={140,50},proc=QANT_butUpdateEnCal,title="Reset Calibrations of all\rScans in Energy Range\rto 0"
	Button QANT_EnCal_remAll_but,pos={670,230},size={140,50},proc=QANT_butUpdateEnCal,title="Reset Calibration Values of\rALL Scans to 0"
	Button QANT_EnCalAvg_but,pos={670,160},size={140,50},proc=QANT_butUpdateEnCal,title="Set Calibration Values\rto Average of Scans in\rChosen Energy Range"
	Display/W=(220,61,498,296)/HOST=# 
	SetDrawLayer UserFront
	DrawText 0.0539568345323741,-0.255208333333333,"Correction Value (contamination on I0)"
	RenameWindow #,G0
	SetActiveSubwindow ##
	QANT_CalcNormalizations("selected")
	SetDataFolder foldersave
End

function QANT_UpdateRefs()
	string foldersave = getdatafolder(1)
	setdatafolder root:NEXAFS
	svar normchan
	svar dnormchan
	svar x_axis
	newdatafolder /o/s Refs
	wave/t/z refs
	wave/z refssel
	variable i, row=0
	if(waveexists(refssel))
		for(i=0;i<dimsize(refs,0);i+=1)
			if(refssel[i][0] & 1 || refssel[i][1] & 1 || refssel[i][2] & 1)
				row = i
			endif
		endfor
	endif
	string reflist = removefromlist("none",removefromlist("Default",QANT_reflist()))
	variable numrefs = itemsinlist(reflist)
	variable energyoffset 
	if(numrefs<1)
		make/o/t /n=(1,3) refs=""
		refs[0][0]="none"
		make/o /n=(1,3) refssel =  {{0},{0},{0}}
	else
		make/o/t /n=(numrefs,3) refs 
		make/o /n=(numrefs,3) refssel
		variable defaultfound=0
		variable count=0
		variable j
		for(i=0;i<numrefs;i+=1)
			newdatafolder /o/s $stringfromlist(i,reflist)
			string/g en_range, default_reference
			//calculate norm over ref and put it in this folder
			if(datafolderexists("root:nexafs:EnergyCorrected:"+possiblyquotename(stringfromlist(i,reflist)) ) )
				wave xnormwave = $("root:nexafs:EnergyCorrected:"+possiblyquotename(stringfromlist(i,reflist))+":" + possiblyquotename(x_axis) )
				wave normwave = $("root:nexafs:EnergyCorrected:"+possiblyquotename(stringfromlist(i,reflist))+":" + possiblyquotename(normchan) )
				wave dnormwave = $("root:nexafs:EnergyCorrected:"+possiblyquotename(stringfromlist(i,reflist))+":" + possiblyquotename(dnormchan) )
			elseif(datafolderexists("root:nexafs:darkcorrected:"+possiblyquotename(stringfromlist(i,reflist)) ) )
				wave xnormwave = $("root:nexafs:darkcorrected:"+possiblyquotename(stringfromlist(i,reflist))+":" + possiblyquotename(x_axis) )
				wave normwave = $("root:nexafs:darkcorrected:"+possiblyquotename(stringfromlist(i,reflist))+":" + possiblyquotename(normchan) )
				wave dnormwave = $("root:nexafs:darkcorrected:"+possiblyquotename(stringfromlist(i,reflist))+":" + possiblyquotename(dnormchan) )
			else
				wave xnormwave = $("root:nexafs:scans:"+possiblyquotename(stringfromlist(i,reflist))+":" + possiblyquotename(x_axis) )
				wave normwave = $("root:nexafs:scans:"+possiblyquotename(stringfromlist(i,reflist))+":" + possiblyquotename(normchan) )
				wave dnormwave = $("root:nexafs:scans:"+possiblyquotename(stringfromlist(i,reflist))+":" + possiblyquotename(dnormchan) )
			endif

			if(!waveexists(xnormwave) || !waveexists(normwave) || !waveexists(dnormwave) )
				//setdatafolder ::
				//killdatafolder /z $stringfromlist(i,reflist)
				continue
			endif
			duplicate/o normwave, $("normoverref")
			duplicate/o xnormwave, $("xnormoverref")
			wave xnormoverref // correct the x values of the reference scan appropriately (this will change with the calibration settings, so this should be run again after each calibration
//			svar enoffset = $("root:nexafs:scans:"+possiblyquotename(stringfromlist(i,reflist))+":enoffset")
//			if(svar_exists(enoffset))
//				energyoffset = str2num(enoffset)
//				if(energyoffset *0==0)
//					xnormoverref -=energyoffset
//				endif
//			endif
			wave normoverref
			normoverref = normwave/dnormwave
			//
			
			// CHECK FOR INFS AND NANS
			for(j=dimsize(normoverref,0)-1;j>=0;j-=1)
				if(numtype(normoverref[j]) || numtype(xnormoverref[j]))
					deletepoints j , 1, normoverref, xnormoverref
				endif
			endfor
			
			setdatafolder "root:nexafs:refs"
			refs[count][0] = stringfromlist(i,reflist)
			refs[count][1] = ""
			refs[count][2] = en_range
			
			refssel[count][0] = 0
			if(!cmpstr(default_reference,"yes"))
				refssel[count][1] = 48
				defaultfound=1
			else
				refssel[count][1] = 32
			endif
			refssel[count][2] = 2
			count +=1
		endfor
		if(defaultfound==0)
			refssel[0][1] = 48
		endif
	endif
	string tracelist = TraceNameList("QANT_RefScans_win#G0",";",1)
	for(i=itemsinlist(tracelist)-1;i>=0;i-=1)
		removefromgraph/z /w=QANT_RefScans_win#G0 $stringfromlist(i,tracelist)
	endfor
	if(numrefs>0)
		refssel[row][0] = 1
		wave xnormoverref = $("root:nexafs:refs:"+possiblyquotename(stringfromlist(row,reflist))+":xnormoverref" )
		wave normoverref = $("root:nexafs:refs:"+possiblyquotename(stringfromlist(row,reflist))+":normoverref" )
		if(strlen(winlist("QANT_RefScans_win",";",""))>0)
			appendtograph /w=QANT_RefScans_win#G0  normoverref vs xnormoverref
		endif
	endif
	if(datafolderexists(("root:nexafs:scans:"+possiblyquotename(refs[row][0]))))
		setdatafolder $("root:nexafs:scans:"+possiblyquotename(refs[row][0]))
		svar darkscan
		string list = QANT_darklist()
		variable num = WhichListItem(darkscan, list) +1
		num = num<1? 0 : num
		popupmenu/z QANT_popup_DarkSelref win=QANT_RefScans_win, mode=(num)
	endif
	SetDataFolder foldersave
end

Function QANT_Refs_ListBoxProc(lba) : ListBoxControl
	STRUCT WMListboxAction &lba
	lba.BlockReentry = 1
	Variable row = lba.row
	Variable col = lba.col
	WAVE/T/Z listWave = lba.listWave
	WAVE/Z selWave = lba.selWave
	string foldersave = getdatafolder(1)
	setdatafolder root:nexafs:refs
	variable i
	switch( lba.eventCode )
		case -1: // control being killed
			break
		case 1: // mouse down
			break
		case 3: // double click
			break
		case 4: // cell selection
		case 5: // cell selection plus shift key
			// based on row, change the dark popup menu accordingly

			QANT_CalcNormalizations("selected")
			break
		case 6: // begin edit
			break
		case 7: // finish edit
		// if column is 0, then change the folder name
			if(row<0 || row>=dimsize(listwave,0))
				break
			endif
		// column is 2, then change energy range
			if(col==2)
				setdatafolder listwave[row][0]
				variable enrange = str2num(listwave[row][2])
				if(enrange*0==0) // it is a valid number
					string /g en_range = listwave[row][2]
					// gothrough all other references, and if they are set to this range, then unset them
					for(i=0;i<dimsize(listwave,0);i+=1)
						if(i==row)
							continue
						endif
						if(strlen(listwave[i][2])>0 && abs(str2num(listwave[i][2])-enrange) < 1.5)
							setdatafolder ::
							setdatafolder listwave[i][0]
							string/g en_range=""
						endif
					endfor
				else
					string /g en_range = ""
				endif
			endif
			
			QANT_CalcNormalizations("selected")
			break
		case 13: // checkbox clicked (Igor 6.2 or later)
		// set that dark as default for the energy range
			if(row<0 || row>=dimsize(listwave,0))
				break
			endif
			if(selwave[row][1]==48)
				//selwave[row][1]=48 // check the checkbox
			// make sure that others are unchecked
				selwave[][1]= p==row ? 48 : 32
			// set en_range in the correct folder to the starting energy
				setdatafolder listwave[row][0]
				string/g default_reference="yes"
				for(i=0;i<dimsize(listwave,0);i+=1)
					if(i==row)
						continue
					endif
					setdatafolder ::
					setdatafolder listwave[i][0]
					string/g default_reference=""
				endfor
			else
				selwave[row][1]=32
				setdatafolder listwave[row][0]
				string/g default_reference=""
			endif
			QANT_CalcNormalizations("selected")
			break
	endswitch

	setdatafolder foldersave
	return 0
End

function QANT_UpdateDarks()
	string foldersave = getdatafolder(1)
	if(!datafolderexists("root:NEXAFS:Darks"))
		return 0
	endif
	setdatafolder root:NEXAFS:Darks
	
	wave/t darks
	wave darkssel
	variable i, row=0
	if(waveexists(darkssel))
		for(i=0;i<dimsize(darks,0);i+=1)
			if(darkssel[i][0] & 1 || darkssel[i][1] & 1 || darkssel[i][2] & 1)
				row = i
			endif
		endfor
	endif

	string darklist = removefromlist("none",removefromlist("Default",QANT_Darklist()))
	variable numdarks = itemsinlist(darklist)
	if(numdarks<1)
		make/o/t /n=(1,3) darks = ""
		make/o /n=(1,3) darkssel =  {{2},{48},{2}}
	else
		make/o/t /n=(numdarks,3) darks 
		make/o /n=(numdarks,3) darkssel

		darks[][0] = stringfromlist(p,darklist)
		darks[][1] = ""
		variable defaultset
		for(i=0;i<dimsize(darks,0);i+=1)
			setdatafolder stringfromlist(i,darklist)
			string /g en_range
			string /g default_dark
			darks[i][2] = en_range
			if(!defaultset)
				darkssel[i][1] = !cmpstr(default_dark,"yes") ? 48 : 32
				defaultset = !cmpstr(default_dark,"yes") ? 1 : 0
			else
				darkssel[i][1] = 32
			endif
			setdatafolder ::
		endfor
		if(defaultset == 0)
			darkssel[0][1] = 48
		endif
		darkssel[][0] = 2
		darkssel[][2] = 2
		if(strlen(winlist("QANT_DarkScans_win",";",""))<5)
			Slider/z slider0, win=QANT_DarkScans_win, disable=1, value=0
		endif
	endif
	if(numdarks>0)
		darkssel[min(row,dimsize(darkssel,0)-1)][0] = 3
	endif
	setdatafolder foldersave
end

function QANT_addPeaksettoPlot(peakset)
	wave/t peakset
	dowindow/k peaksetview
	edit /W=(4.8,42.2,166.8,309.2)/n=PeaksetView /k=1 peakset
	string traces = TraceNameList("QANT_Plot",";",1)
	if(strlen(traces)<1)
		return 0
	endif
	string originaltraces = TraceNameList("QANT_Plot",";",1)
	wave xwaveplot = XWaveRefFromTrace("QANT_Plot",stringfromlist(0,traces))
	if(!waveexists(xwaveplot))
		return 0
	endif
	if(wavemax(xwaveplot)-wavemin(xwaveplot) < 1)
		return 0
	endif
	variable xmin = wavemin(xwaveplot)
	variable xmax = wavemax(xwaveplot)
	variable numpoints = 1000
	variable i, num = dimsize(peakset,0)
	string dataname = stringfromlist(0,traces)
	make/o /n=(numpoints) xwave
	setscale /i x, xmin, xmax, xwave
	xwave = x
	string blstr = peakset[0]
	duplicate/o xwave, blwave
	string name = QANT_WhooskaNametoMPF2(stringfromlist(0,peakset[0]))
	FUNCREF MPF2_FuncInfoTemplate BLinfoFunc=$(name+BL_INFO_SUFFIX)
	String PeakFuncName = 	BLinfoFunc(PeakFuncInfo_PeakFName)
	struct MPF2_BLFitStruct BLStruct
	BlStruct.xend = xmax
	Blstruct.xstart = xmin
	wave BLStruct.cWave = $QANT_MakeCwaveFromPeakSet(peakset[0],1) 
	funcref MPF2_BaselineFunctionTemplate BLfunc = $PeakFuncName
	
	for(i=0;i<numpoints;i+=1)
		BlStruct.x=xwave[i]
		blwave[i] = BLfunc(BLStruct)
	endfor
	colortab2wave SpectrumBlack
	wave m_colors
	make/o /n=(dimsize(m_colors,0)) colorxwave, redwave = m_colors[p][0], greenwave = m_colors[p][1], bluewave = m_colors[p][2] 
	setscale /i x,0,num*1.3, colorxwave, redwave, greenwave, bluewave 
	colorxwave = x
	make/o /n=(num) rwave = interp(p,colorxwave, redwave), gwave =  interp(p,colorxwave, greenwave), bwave =  interp(p,colorxwave, bluewave)
	appendtograph /w=QANT_Plot blwave /TN=$name
	modifygraph /w=QANT_Plot rgb($name) = (rwave[0], gwave[0], bwave[0]), lsize($name) = 1, lstyle($name) = 3
	Legend/K/N=text0/w=QANT_Plot
	//Legend/C/N=text0/w=QANT_Plot
	//Legend/C/N=text0/J/w=QANT_Plot
	string peakname
	string listofpeaktraces = ""
	for(i=1;i<num;i+=1)
		peakname = QANT_WhooskaNametoMPF2(stringfromlist(0,peakset[i]))
		FUNCREF MPF2_FuncInfoTemplate PeakinfoFunc=$(peakname+PEAK_INFO_SUFFIX)
		PeakFuncName = 	PeakinfoFunc(PeakFuncInfo_PeakFName)
		funcref MPF2_PeakFunctionTemplate Peakfunc = $PeakFuncName
		wave cWave = $QANT_MakeCwaveFromPeakSet(peakset[i],1) 
		funcref MPF2_PeakFunctionTemplate Peakfunc = $PeakFuncName
		duplicate /o xwave, $("Peak_"+num2str(i))
		Peakfunc(cwave,$("Peak_"+num2str(i)),xwave)
		appendtograph /w=QANT_Plot /l=peaks $("Peak_"+num2str(i)) /TN=$(peakname+stringfromlist(2,Peakset[i]))
// comment these out for cleaner graph
		appendtograph /w=QANT_Plot $("Peak_"+num2str(i)) /TN=$(peakname+stringfromlist(2,Peakset[i])+"_h")
		listofpeaktraces += (peakname+stringfromlist(2,Peakset[i])+"_h") + ";"
// to here
		reordertraces/w=QANT_Plot $(stringfromlist(0,traces)), {$(peakname+stringfromlist(2,Peakset[i])) }
		doupdate
		modifygraph /w=QANT_Plot  lstyle($(peakname+stringfromlist(2,Peakset[i])) )=0, lsize($(peakname+stringfromlist(2,Peakset[i])) )=2, rgb($(peakname+stringfromlist(2,Peakset[i]))) = (rwave[i], gwave[i], bwave[i])
// and these lines as well
		modifygraph /w=QANT_Plot  rgb($(peakname+stringfromlist(2,Peakset[i]) + "_h")) = (rwave[i], gwave[i], bwave[i],20000), lsize($(peakname+stringfromlist(2,Peakset[i]) + "_h"))=1, lstyle($(peakname+stringfromlist(2,Peakset[i]) + "_h"))=3
		ModifyGraph standoff(peaks)=0,axisEnab(left)={0.33,1},axisEnab(peaks)={0,0.3};DelayUpdate
		ModifyGraph freePos(peaks)=0
	endfor

	ModifyGraph /w=QANT_Plot mode($name)=7, hbFill($name)=4
	traces = TraceNameList("QANT_Plot",";",1)
	reordertraces/w=QANT_Plot $(stringfromlist(0,traces)), {$name }
	string tracename
	for(i=0;i<num-1;i+=1)
		tracename = stringfromlist(i,listofpeaktraces)
		reordertraces /w=QANT_Plot $name , { $stringfromlist(i,listofpeaktraces) }
		ModifyGraph /w=QANT_Plot mode($tracename)=7,toMode($tracename)=3, hbFill($tracename)=4
	endfor
	traces = TraceNameList("QANT_Plot",";",1)
	
	for(i=itemsinlist(originaltraces)-1;i>=0;i-=1)
		if(stringmatch(stringfromlist(i,originaltraces),"fit_*"))
			originaltraces = removefromlist(stringfromlist(i,originaltraces), originaltraces)
		endif
	endfor
	string traceinfront = (stringfromlist(0,traces))
	string tracestomove = removeending(replacestring(";",originaltraces,", "),", ") 
	execute/z/q "reordertraces/w=QANT_Plot " +traceinfront+ ", {" +tracestomove+"}"
	Legend/C/N=text0/w=QANT_Plot
	QANT_ExportGraph()
end
'
function QANT_CalcEnergyCalibrationAll(enmin, enmax, peakloc, smsize,[avg])
	variable enmin, enmax, peakloc, smsize,avg
	avg = paramisdefault(avg) ? 0 : avg
	QANT_CalcNormalizations("all")
	string foldersave = getdatafolder(1)
	setdatafolder root:NEXAFS:
	wave/t Scans = scanlist
	svar x_axis
	variable i, num= dimsize(scans,0), j
	variable minx, maxx, energyoffset=nan, acqtime, guess
	string fname
	make/free /n=(num) energyoffsets, energyscantimes
	make/free /n=(num)/t enoffscannames
	if(datafolderexists("RefCorrectedData"))
		setdatafolder $"RefCorrectedData"
	else
		print "Error finding corrected data, please load a reference"
		return 0
	endif
	for(i=0;i<num;i+=1)
		if(datafolderexists(scans[i][0]))
			setdatafolder scans[i][0]
		else
			continue
		endif
		wave xwave = $("root:Nexafs:Scans:"+possiblyquotename(scans[i][0])+":" + possiblyquotename(x_axis))
		wave refwave = Ref_Foil_VF
		
		if(!waveexists(xwave) || !waveexists(refwave))
			setdatafolder ::
			continue
		endif
		if(wavemin(xwave) > enmin || wavemax(xwave) < enmax)
			setdatafolder ::
			continue
		endif
		wavestats/z/q refwave
		minx = binarysearch(xwave,enmin)
		maxx = binarysearch(xwave,enmax)
		findpeak/Q/B=(smsize)/r=[minx,maxx] refwave
		if(!V_flag)
			energyoffset = xwave(V_PeakLoc) - peakloc
		else
			setdatafolder ::
			continue
		endif
		energyoffsets[j] = energyoffset
		svar mdate = $("root:Nexafs:Scans:"+possiblyquotename(scans[i][0])+":mdate")
		if(svar_exists(mdate))
			acqtime = str2num(mdate)
			energyscantimes[j] = acqtime
		else
			energyscantimes[j] = nan
		endif
		enoffscannames[j] = scans[i][0]
		j+=1
		setdatafolder ::
	endfor
	redimension /n=(j) energyoffsets, energyscantimes, enoffscannames
	
	duplicate/free energyoffsets, badoffsets
	wavestats/q/z energyoffsets
	if(avg)
		energyoffsets = v_avg
	else
		badoffsets *= energyoffsets[p] > v_avg+3*v_sdev || energyoffsets[p] < v_avg-3*v_sdev ? 1 : 0
		energyoffsets = badoffsets[p] ? v_avg : energyoffsets[p]
	endif
	setdatafolder root:NEXAFS:
	for(i=0;i<dimsize(enoffscannames,0);i+=1)
		setdatafolder root:NEXAFS:Scans:
		setdatafolder enoffscannames(i)
		string /g enoffset = num2str(energyoffsets[i])
	endfor
	setdatafolder foldersave
	QANT_listNEXAFSscans()
end

function QANT_RmEnCalibration(enmin, enmax)
	variable enmin, enmax
	QANT_CalcNormalizations("all")
	string foldersave = getdatafolder(1)
	setdatafolder root:NEXAFS:
	wave/t Scans = scanlist
	svar x_axis
	variable i, num= dimsize(scans,0), j
	variable minx, maxx, energyoffset=nan, acqtime, guess
	string fname
	make/free /n=(num)/t enoffscannames
	if(datafolderexists("RefCorrectedData"))
		setdatafolder $"RefCorrectedData"
	else
		print "Error finding corrected data, please load a reference"
		return 0
	endif
	for(i=0;i<num;i+=1)
		if(datafolderexists(scans[i][0]))
			setdatafolder scans[i][0]
		else
			continue
		endif
		wave xwave = $x_axis
		wave refwave = Ref_Foil_VF
		
		if(!waveexists(xwave) || !waveexists(refwave))
			setdatafolder ::
			continue
		endif
		if(wavemin(xwave) > enmin || wavemax(xwave) < enmax)
			setdatafolder ::
			continue
		endif
		enoffscannames[j] = scans[i][0]
		j+=1
		setdatafolder ::
	endfor
	redimension /n=(j) enoffscannames
	setdatafolder root:NEXAFS:
	for(i=0;i<dimsize(enoffscannames,0);i+=1)
		setdatafolder root:NEXAFS:Scans:
		setdatafolder enoffscannames(i)
		string /g enoffset = "0"
	endfor
	setdatafolder foldersave
	QANT_listNEXAFSscans()
end
function QANT_RmEnCalibrationAll()
	QANT_CalcNormalizations("all")
	string foldersave = getdatafolder(1)
	setdatafolder root:NEXAFS:
	wave/t Scans = scanlist
	variable i
	for(i=0;i<dimsize(Scans,0);i+=1)
		setdatafolder root:NEXAFS:Scans:
		setdatafolder Scans[i][0]
		string /g enoffset = "0"
	endfor
	setdatafolder foldersave
	QANT_listNEXAFSscans()
end

Function QANT_butUpdateEnCal(ba) : ButtonControl
	STRUCT WMButtonAction &ba

	switch( ba.eventCode )
		case 2: // mouse up
			// click code here
			string foldersave = getdatafolder(1)
			if(datafolderexists("root:NEXAFS:refs"))
				setdatafolder root:NEXAFS:refs
			else
				break
			endif
			nvar minsearch, maxsearch, peakloc, smsize 
			if(nvar_exists(minsearch) &&nvar_exists(maxsearch) &&nvar_exists(peakloc) &&nvar_exists(smsize) )
				if(StringMatch(ba.ctrlName,"QANT_EnCal_but"))
					QANT_CalcEnergyCalibrationAll(minsearch, maxsearch, peakloc, smsize,avg=0)
					QANT_CalcNormalizations("selected")
				elseif(StringMatch(ba.ctrlName,"QANT_EnCal_rem_but"))
					QANT_RmEnCalibration(minsearch,maxsearch)
					QANT_CalcNormalizations("selected")
				elseif(StringMatch(ba.ctrlName,"QANT_EnCal_remAll_but"))
					QANT_RmEnCalibrationAll()
					QANT_CalcNormalizations("selected")
				elseif(StringMatch(ba.ctrlName,"QANT_EnCalAvg_but"))
					QANT_CalcEnergyCalibrationAll(minsearch, maxsearch, peakloc, smsize,avg=1)
					QANT_CalcNormalizations("selected")
				endif
			endif
			
			setdatafolder foldersave
			break
		case -1: // control being killed
			break
	endswitch

	return 0
End

Function QANT_linethickness(pa) : PopupMenuControl
	STRUCT WMPopupAction &pa

	switch( pa.eventCode )
		case 2: // mouse up
			Variable popNum = pa.popNum
			String popStr = pa.popStr
			string foldersave = getdatafolder(1)
			setdatafolder root:NEXAFS
			variable /g thickness = str2num(popstr)
			QANT_replotdata()
			
			setdatafolder foldersave
			break
		case -1: // control being killed
			break
	endswitch

	return 0
End

Function QANT_Matchstr(sva) : SetVariableControl
	STRUCT WMSetVariableAction &sva

	switch( sva.eventCode )
		case 1: // mouse up
		case 2: // Enter key
		case 3: // Live update
			Variable dval = sva.dval
			String sval = sva.sval
			QANT_listNEXAFSscans()
			break
		case -1: // control being killed
			break
	endswitch

	return 0
End

Function QANT_SubCursorsCheckProc(cba) : CheckBoxControl
	STRUCT WMCheckboxAction &cba

	switch( cba.eventCode )
		case 2: // mouse up
			Variable checked = cba.checked
			nvar subCursors = root:NEXAFS:subCursors
			subcursors = checked
			if(checked==0)
				dowindow /k QANT_plot
				killdatafolder /z root:NEXAFS:NormalizedData
				QANT_listNEXAFSscans()
				//QANT_CalcNormalizations("selected")
				//QANT_listNEXAFSscans()
			else
				QANT_listNEXAFSscans()
				//QANT_CalcNormalizations("selected")
				//QANT_listNEXAFSscans()
			endif
			break
		case -1: // control being killed
			break
	endswitch

	return 0
End

structure decompfitstruct
	wave/d coefw
	wave/d yw
	wave/d xw
	wave/d dw //data (multidimensional, number of rows is the number of elements to fit)
	wave/d fw
	variable numrefwaves
	variable lengthofdatasets
	variable numberofdatasets
	wave datasetstartlocations
EndStructure

function fitdecomp(s) : FitFunc
	struct decompfitstruct &s
	wave y = s.yw
	wave x = s.xw
//	s.dw // the two reference data waves [[wave1][wave2]]
//	s.coefw // the coef wave weightings of reference data wave 1, 2  {ref1 trace1, ref2 trace 1, ref1 trace2 ....}
	variable len = s.lengthofdatasets  
	variable numrefwaves = s.numrefwaves
	variable num = s.numberofdatasets  
	make /d/o /n=(len,num) tempdata=0
	variable i
	for(i=0;i<numrefwaves;i+=1)
		tempdata += s.dw[i][p]*s.coefw[numrefwaves*q+i]
	endfor
	if(dimsize(s.coefw,0)>numrefwaves)
		tempdata += s.coefw[numrefwaves]
	endif
	redimension /n=(len*num) tempdata
	y = tempdata
end
Function QANT_but_AddscantoMaterials(ba) : ButtonControl
	STRUCT WMButtonAction &ba

	switch( ba.eventCode )
		case 2: // mouse up
			// click code here
			// read the currently displayed scans and channels, and save those to the list, 
			string foldersave = getdatafolder(1)
			setdatafolder root:NEXAFS
			wave selwave = selwavescanlist, materialslistsel, channelSel
			wave/T scanlist, materialslist, channels
			variable j, start=0,k, chanstart=0, m, alreadyinlist
			string scan, name, channel

			for(j=0;j<sum(selwave);j+=1)
				findvalue /s=(start)/v=1 selwave
				if(v_value>=0)
					start = v_value+1
					scan = scanlist[v_value][0]
					name = scanlist[v_value][1]
					chanstart=0
					for(k=0;k<sum(channelsel);k+=1)
						findvalue /s=(chanstart)/v=1 channelSel
						chanstart = v_value+1
						if(v_value<0)
							break
						endif
						channel = channels[v_value]
						alreadyinlist = 0
						for(m=0;m<dimsize(materialslist,0);m+=1)
							if(stringmatch(scan,materialslist[m][1]) && stringmatch(channel,materialslist[m][2]))
								alreadyinlist = 1
							endif
						endfor
						if(alreadyinlist)
							continue
						endif
						InsertPoints /M=0 dimsize(materialslist,0),1 , materialslist, materialslistsel
						if(dimsize(materialslist,1)<3)
							redimension /n=(1,3) materialslist
						endif
						materialslistsel[dimsize(materialslist,0)-1]=1
						materialslist[dimsize(materialslist,0)-1][0] = name +"_"+ channel[0,3]
						materialslist[dimsize(materialslist,0)-1][1] = scan
						materialslist[dimsize(materialslist,0)-1][2] = channel
					endfor
				else
					break
				endif
			endfor
			if(dimsize(materialslist,0)>1 && strlen(materialslist[0][1])==0)
				deletepoints /M=0 0, 1, materialslist, materialslistsel
			endif
			setdatafolder foldersave
			break
		case -1: // control being killed
			break
	endswitch

	return 0
End



Function QANT_delMaterial(ba) : ButtonControl
	STRUCT WMButtonAction &ba

	switch( ba.eventCode )
		case 2: // mouse up
			string foldersave = getdatafolder(1)
			setdatafolder root:NEXAFS
			wave materialslistsel,  materialstofitlistsel
			wave/T materialslist, materialsToFitList
			variable j, materialfound, startloc
			string materialtodelete
			for(j=dimsize(materialslistsel,0)-1; j>=0 ; j-=1)
				if(materialslistsel[j])
					materialtodelete = materialslist[j][0]
					materialfound=1
					startloc=0
					do
						findvalue /s=(startloc) /text=materialtodelete /txop=(6) materialsToFitList
						if(v_value >=0)
							startloc = max(v_value-1,0)
							deletepoints /m=0 v_value, 1,  materialsToFitList, materialstofitlistsel
							materialfound=1
						else
							materialfound=0
						endif
					while(materialfound==1)
					deletepoints /m=0 j , 1, materialslist, materialslistsel
				endif
			endfor
			setvariable QANT_strval_Materialname value=_STR:"", disable =1
			setdatafolder foldersave
			// click code here
			break
		case -1: // control being killed
			break
	endswitch

	return 0
End

Function QANT_AddMaterialtoFit(ba) : ButtonControl
	STRUCT WMButtonAction &ba

	switch( ba.eventCode )
		case 2: // mouse up
			string foldersave = getdatafolder(1)
			setdatafolder root:NEXAFS
			wave materialslistsel,  materialstofitlistsel
			wave/T materialslist, materialsToFitList
			variable j
			for(j=dimsize(materialslistsel,0)-1; j>=0 ; j-=1)
				if(materialslistsel[j])
					findvalue /s=0 /TEXT=materialslist[j][0] materialstofitlist
					if(v_value == -1)
						insertpoints /M=0 dimsize(materialstofitlist,0), 1, materialstofitlist, materialstofitlistsel
						materialstofitlist[dimsize(materialstofitlist,0)-1] = materialslist[j][0]
						materialstofitlistsel[dimsize(materialstofitlist,0)-1] = 1
					endif
				endif
			endfor
			setdatafolder foldersave
			// click code here
			break
		case -1: // control being killed
			break
	endswitch

	return 0
End

Function QANT_rmMaterialsFromFit(ba) : ButtonControl
	STRUCT WMButtonAction &ba

	switch( ba.eventCode )
		case 2: // mouse up
			string foldersave = getdatafolder(1)
			setdatafolder root:NEXAFS
			wave materialstofitlistsel
			wave/T materialsToFitList
			variable j
			for(j=dimsize(materialstofitlistsel,0)-1; j>=0 ; j-=1)
				if(materialstofitlistsel[j])
					deletepoints /M=0 j, 1, materialstofitlistsel, materialstofitlist
				endif
			endfor
			setdatafolder foldersave
			// click code here
			break
		case -1: // control being killed
			break
	endswitch

	return 0
End

Function QANT_list_MaterialsAvailable(lba) : ListBoxControl
	STRUCT WMListboxAction &lba

	Variable row = lba.row
	Variable col = lba.col
	WAVE/T/Z listWave = lba.listWave
	WAVE/Z selWave = lba.selWave

	switch( lba.eventCode )
		case -1: // control being killed
			break
		case 1: // mouse down
			break
		case 3: // double click
			break
		case 4: // cell selection
		case 5: // cell selection plus shift key
			if(sum(selwave)==1)
				findvalue /v=1 selwave
				setvariable QANT_strval_Materialname value=_STR:listwave[v_value][0], disable=0
			else
				setvariable QANT_strval_Materialname value=_STR:"", disable =1
			endif
			break
		case 6: // begin edit
			break
		case 7: // finish edit
			break
		case 13: // checkbox clicked (Igor 6.2 or later)
			break
	endswitch

	return 0
End

Function QANT_strset_materialname(sva) : SetVariableControl
	STRUCT WMSetVariableAction &sva

	switch( sva.eventCode )
		case 1: // mouse up
		case 2: // Enter key
		case 3: // Live update
			Variable dval = sva.dval
			String sval = sva.sval
			wave/t listwave = root:NEXAFS:MaterialsList, listfitwave = root:NEXAFS:MaterialsToFitList
			wave selwave = root:NEXAFS:MaterialsListSel, listfitwavesel = root:NEXAFS:MaterialsToFitListsel
			variable k, j
			string name2change
			for(j=dimsize(listwave,0)-1;j>=0;j-=1)
				if(selwave[j][0] ==1)
					name2change = listwave[j][0]
					listwave[j][0] = sval
					for(k=dimsize(listfitwave,0)-1;k>=0;k-=1)
						if(stringmatch(listfitwave[k],name2change))
							listfitwave[k] = sval
						endif
					endfor
				endif
			endfor
			
			break
		case -1: // control being killed
			break
	endswitch

	return 0
End

function QANT_updatePeaksetDisp()
	string foldersave = getdatafolder(1)
	svar peaksetfit =  root:NEXAFS:peaksetfit
	setdatafolder root:NEXAFS:fitting
	wave /t peakset = $peaksetfit
	newdatafolder /o/s peaksetdisp
	make /t/o/n=(dimsize(peakset,0)+1,7) peaklist
	make /o/n=(dimsize(peakset,0)+1,7) peaklistsel
	make /t/o/n=7 peaklistcols = {"View","Peak Type", "Width","X-Loc","Height","Other","Other"}
	variable j
	for(j=0;j<dimsize(peakset,0);j+=1)
		peaklistsel[j][0]= peaklistsel[j][0]==48 || peaklistsel[j][0] == 32 ? peaklistsel[j][0] : 32
		peaklistsel[j][1,]=2
		peaklist[j][0]=""
		peaklist[j][1] = stringfromlist(0,peakset[j])
		peaklist[j][2] = stringfromlist(1,peakset[j])
		peaklist[j][3] = stringfromlist(2,peakset[j])
		peaklist[j][4] = stringfromlist(3,peakset[j])
		peaklist[j][5] = stringfromlist(4,peakset[j])
		peaklist[j][6] = stringfromlist(5,peakset[j])
		
		//append the peak to the graph, if it exists
		
	endfor
	peaklist[j]=""
	peaklistsel[j][1,]=2
	peaklistsel[j][0]=32
	
	setdatafolder foldersave
end

Function QANT_List_PeakManager(lba) : ListBoxControl
	STRUCT WMListboxAction &lba

	Variable row = lba.row
	Variable col = lba.col
	WAVE/T/Z listWave = lba.listWave
	WAVE/Z selWave = lba.selWave

	switch( lba.eventCode )
		case -1: // control being killed
			break
		case 1: // mouse down
			if(row==-1)
				svar peaksetfit =  root:NEXAFS:peaksetfit
				string foldersave1 = getdatafolder(1)
				setdatafolder root:NEXAFS:fitting:peaksetdisp
				variable /g order
				variable /g lastorder1
				variable /g lastorder2
				variable /g lastorder3
				variable /g lastsort1
				variable /g lastsort2
				variable /g lastsort3
				variable /g numsorts
				if(col == lastsort1)
					order = lastorder1==0 ? 1 : 0 // we are switching the order, so we are keeping order
					lastsort1 = lastsort2
					lastorder1 = lastorder2
					lastsort2 = lastsort3 // we only every use the last to sorts, but incase we are just flipping the order of the last one, we need an extra slot
					lastorder2 = lastorder3
				else
					order = 0
				endif
				wave /t peakset = $("root:nexafs:fitting:"+possiblyquotename(peaksetfit))
				make /n=(dimsize(peakset,0)) /free checked
				checked = selwave[p][0]
				
				if(numsorts>1 && lastsort2*0==0 && lastsort1*0==0) // we have done more than one sort previously, so last sort 1 and 2 should be valid
					make /free /n=(dimsize(peakset,0)) /t sortrow, sortrow1, sortrow2
					sortrow= stringfromlist(col-1,peakset[p])
					if(lastorder1==order)
						sortrow1= stringfromlist(lastsort1-1,peakset[p])
					else
						sortrow1= stringfromlist(lastsort1-1,peakset[dimsize(peakset,0)-1-p])
					endif
					if(lastorder2==order)
						sortrow2= stringfromlist(lastsort2-1,peakset[p])
					else
						sortrow2= stringfromlist(lastsort2-1,peakset[dimsize(peakset,0)-1-p])
					endif
					if(order)
						sort /A {sortrow,sortrow1,sortrow2}, peakset, checked, sortrow2,sortrow1,sortrow
					else
						sort /A /R {sortrow,sortrow1,sortrow2} , peakset, checked, sortrow2,sortrow1,sortrow
					endif
				elseif(numsorts>0 && lastsort1*0==0)
					make /free /n=(dimsize(peakset,0)) /t sortrow, sortrow1
					sortrow = stringfromlist(col-1,peakset[p])
					if(lastorder1==order)
						sortrow1= stringfromlist(lastsort1-1,peakset[p])
					else
						sortrow1= stringfromlist(lastsort1-1,peakset[dimsize(peakset,0)-1-p])
					endif
					if(order)
						sort /A {sortrow,sortrow1}, peakset, checked, sortrow1,sortrow
					else
						sort /A /R {sortrow,sortrow1}, peakset, checked, sortrow1,sortrow
					endif
				else
					make /free /n=(dimsize(peakset,0)) /t sortrow
					sortrow = stringfromlist(col-1,peakset[p])
					if(order)
						sort /A sortrow, peakset, checked,sortrow
					else
						sort /A /R sortrow, peakset, checked,sortrow
					endif
				endif
				
				selwave[][0] = checked[min(p,dimsize(checked,0)-1)]
				QANT_updatePeaksetDisp()
				QANT_PeakEdit_UpdatePlot()
				lastsort3 = lastsort2
				lastsort2 = lastsort1
				lastsort1 = col
				lastorder3 = lastorder2
				lastorder2 = lastorder1
				lastorder1 = order
				if(numsorts*0!=0)
					numsorts=0
				endif
				numsorts +=1
				setdatafolder foldersave1
			endif
			break
		case 3: // double click
			break
		case 4: // cell selection
		case 5: // cell selection plus shift key
			string foldersave = getdatafolder(1)
			setdatafolder root:NEXAFS:fitting:peaksetdisp
			variable /g selrow
			variable /g selcol
			selcol = col
			selrow = row
			setdatafolder foldersave
			break
		case 6: // begin edit
			break
		case 7: // finish edit
			string newstring = listwave[row][col]
			svar peaksetfit =  root:NEXAFS:peaksetfit
			wave /t peakset = $("root:nexafs:fitting:"+possiblyquotename(peaksetfit))
			variable makenewrow=0
			if(row<dimsize(peakset,0))
				make /o/t /n=5 peakcomponents = stringfromlist(p,peakset[row])
			else
				make /o/t /n=5 peakcomponents = ""
				makenewrow=1
			endif
			if(col==1)
				if(stringmatch(newstring,"G*"))
					peakcomponents[0] = "GAUSSIAN"
				elseif(stringmatch(newstring,"AS*"))
					peakcomponents[0] = "ASYM_GAUS"
				elseif(stringmatch(newstring,"*edge*"))
					peakcomponents[0] = "NEXAFS_EDGE"
				else
					peakcomponents[0] = ""
				endif
			else
				variable newvar = str2num(newstring)
				if(newvar*0==0)
					peakcomponents[col-1] = num2str(newvar)
				else
					peakcomponents[col-1] = ""
				endif
			endif
			QANT_Cleanuppeakcomponents(peakcomponents)
			variable j
			string newpeak=""
			for(j=dimsize(peakcomponents,0)-1;j>=0;j-=1)
				newpeak = addlistitem(peakcomponents[j],newpeak)
			endfor
			if(makenewrow)
				redimension /n=(row+1) peakset
			endif
			peakset[row] = newpeak
			QANT_updatePeaksetDisp()
			QANT_PeakEdit_UpdatePlot()
			break
		case 13: // checkbox clicked (Igor 6.2 or later)
		
			QANT_PeakEdit_UpdatePlot()
			break
		case 22:
			print row
			break
	endswitch

	return 0
End
function QANT_Cleanuppeakcomponents(peakcomp)
	wave /t peakcomp
	if(stringmatch(peakcomp[0],"*Edge*"))
		peakcomp[0] = "NEXAFS_EDGE"
		if(str2num(peakcomp[1])*0!=0)
			peakcomp[1] =  "0"
		else
			peakcomp[1] = num2str(str2num(peakcomp[1]))
		endif
		if(str2num(peakcomp[2])*0!=0)
			peakcomp[2] =  "0"
		else
			peakcomp[2] = num2str(str2num(peakcomp[2]))
		endif
		if(str2num(peakcomp[3])*0!=0)
			peakcomp[3] =  "0"
		else
			peakcomp[3] = num2str(str2num(peakcomp[3]))
		endif
		if(str2num(peakcomp[4])*0!=0)
			peakcomp[4] = "0"
		else
			peakcomp[4] = num2str(str2num(peakcomp[4]))
		endif
		redimension /n=5 peakcomp
	elseif(stringmatch(peakcomp[0],"*asym*"))
		peakcomp[0] = "ASYM_GAUS"
		if(str2num(peakcomp[1])*0!=0)
			peakcomp[1] = "0"
		else
			peakcomp[1] = num2str(str2num(peakcomp[1]))
		endif
		if(str2num(peakcomp[2])*0!=0)
			peakcomp[2] =  "0"
		else
			peakcomp[2] = num2str(str2num(peakcomp[2]))
		endif
		if(str2num(peakcomp[3])*0!=0)
			peakcomp[3] =  "0"
		else
			peakcomp[3] = num2str(str2num(peakcomp[3]))
		endif
		if(str2num(peakcomp[4])*0!=0)
			peakcomp[4] = "0"
		else
			peakcomp[4] = num2str(str2num(peakcomp[4]))
		endif
		redimension /n=5 peakcomp
	else
		peakcomp[0] = "GAUSSIAN"
		if(str2num(peakcomp[1])*0!=0)
			peakcomp[1] =  "0"
		else
			peakcomp[1] = num2str(str2num(peakcomp[1]))
		endif
		if(str2num(peakcomp[2])*0!=0)
			peakcomp[2] =  "0"
		else
			peakcomp[2] = num2str(str2num(peakcomp[2]))
		endif
		if(str2num(peakcomp[3])*0!=0)
			peakcomp[3] =  "0"
		else
			peakcomp[3] = num2str(str2num(peakcomp[3]))
		endif
		redimension /n=4 peakcomp
	endif
end

Function QANT_Button_View(ba) : ButtonControl
	STRUCT WMButtonAction &ba
	
	switch( ba.eventCode )
		case 2: // mouse up
			wave peaklistsel = root:NEXAFS:fitting:peaksetdisp:peaklistsel
			if(stringmatch(ba.ctrlname,"QANT_but_ViewAllPeaks"))
				peaklistsel[][0] = 48
			else
				peaklistsel[][0] = 32
			endif
			
			QANT_updatePeaksetDisp()
			QANT_PeakEdit_UpdatePlot()
			// click code here
			break
		case -1: // control being killed
			break
	endswitch

	return 0
End

Function QANT_Fitting_DupPeak(ba) : ButtonControl
	STRUCT WMButtonAction &ba

	switch( ba.eventCode )
		case 2: // mouse up
			nvar selrow =  root:NEXAFS:fitting:peaksetdisp:selrow
			svar peaksetfit =  root:NEXAFS:peaksetfit
			wave /t peakset = $("root:nexafs:fitting:"+possiblyquotename(peaksetfit))
			if(nvar_exists(selrow) && selrow *0==0 && selrow < dimsize(peakset,0))
				insertpoints selrow+1, 1, peakset
				peakset[selrow+1] = peakset[selrow]
			endif
			QANT_updatePeaksetDisp()
			QANT_PeakEdit_UpdatePlot()
			break
		case -1: // control being killed
			break
	endswitch

	return 0
End

Function QANT_fitting_RmPeak(ba) : ButtonControl
	STRUCT WMButtonAction &ba

	switch( ba.eventCode )
		case 2: // mouse up
			nvar selrow =  root:NEXAFS:fitting:peaksetdisp:selrow
			svar peaksetfit =  root:NEXAFS:peaksetfit
			wave /t peakset = $("root:nexafs:fitting:"+possiblyquotename(peaksetfit))
			if(nvar_exists(selrow) && selrow *0==0 && selrow < dimsize(peakset,0))
				deletepoints selrow, 1, peakset
			endif
			QANT_updatePeaksetDisp()
			QANT_PeakEdit_UpdatePlot()
			break
		case -1: // control being killed
			break
	endswitch

	return 0
End

Window PeaksetEditWindow()
	PauseUpdate; Silent 1		// building window...
	NewPanel /W=(44,407,755,777) as "Peak Set Editing"
	ModifyPanel frameInset=1
	ListBox list0,pos={4,38},size={312,258},proc=QANT_List_PeakManager
	ListBox list0,listWave=root:NEXAFS:fitting:peaksetdisp:peaklist
	ListBox list0,selWave=root:NEXAFS:fitting:peaksetdisp:peaklistsel
	ListBox list0,titleWave=root:NEXAFS:fitting:peaksetdisp:peaklistcols,row= 4
	ListBox list0,mode= 2,selRow= 11,widths={32,77,62,49,55,39,37}
	ListBox list0,userColumnResize= 1
	PopupMenu QANT_popup_PeakSet,pos={4,6},size={241,26},bodyWidth=207,proc=QANT_PeakSetPOP,title="Peak  \rSet:"
	
	PopupMenu QANT_popup_PeakSet,mode=2,popvalue="CPF4",value= #"QANT_ListPeakSets()"
	Button button0,pos={426,332},size={127,35},title="Add Scan to Plot\rfor comparison"
	Button button1,pos={581,311},size={112,53},title="Remove Scans"
	Button QANT_but_RemPeak,pos={207,318},size={89,38},proc=QANT_fitting_RmPeak,title="Remove Peak"
	PopupMenu QANT_Fitting_NewFromGraphPop,pos={391,309},size={174,21},bodyWidth=143,title="Scan:"
	PopupMenu QANT_Fitting_NewFromGraphPop,mode=1,popvalue="none",value= #"QANT_ListTraces()"
	Button QANT_but_DuplicatePeak,pos={106,318},size={89,38},proc=QANT_Fitting_DupPeak,title="Duplicate Peak"
	Button QANT_but_ViewAllPeaks,pos={14,304},size={64,30},proc=QANT_Button_View,title="View All"
	Button QANT_but_ViewNoPeaks,pos={14,334},size={64,30},proc=QANT_Button_View,title="View None"
	Display/W=(320,6,706,301)/HOST=# 
	ModifyGraph margin(right)=14,gfSize=14
	RenameWindow #,G0
	SetActiveSubwindow ##
EndMacro

function QANT_PeakEdit_UpdatePlot()
	svar peaksetfit =  root:NEXAFS:peaksetfit
	wave /t peakset = $("root:nexafs:fitting:"+possiblyquotename(peaksetfit))
	wave peaklistsel = root:NEXAFS:fitting:peaksetdisp:peaklistsel
	variable j
	make /free/n=(0) /t peakstoplot
	variable numpeaks=0
	for(j=dimsize(peaklistsel,0)-1;j>=0;j-=1)
		if(peaklistsel[j][0]==48)
			insertpoints /M=0 0,1, peakstoplot
			peakstoplot[0] = peakset[j]
		endif
	endfor
	// check if window exists first
	dowindow QANT_PeaksetEditWindow
	if(v_flag==0)
		return 0
	endif
	string tracenames = TraceNameList("QANT_PeaksetEditWindow#G0",";",1)
	variable axismin = -inf
	variable axismax=inf
	if(strlen(tracenames)>2)
		getaxis/Q /W=QANT_PeaksetEditWindow#G0 bottom
		if(v_flag==0)
			axismin = v_min
			axismax = v_max
		else
			
			print "no axis"
		endif
	endif
	do
		removefromgraph /W=QANT_PeaksetEditWindow#G0 /Z $stringfromlist(0,tracenames)
		tracenames = TraceNameList("QANT_PeaksetEditWindow#G0",";",1)
	while(itemsinlist(tracenames) >0)
	svar scaninplot = root:NEXAFS:fitting:peaksetdisp:scaninplot
	nvar addscantoplot = root:NEXAFS:fitting:peaksetdisp:addscantoplot
	if(cmpstr(scaninplot,"none") && addscantoplot)
		if(waveexists(tracenametowaveref("QANT_plot",scaninplot)))
			appendtograph /w=QANT_PeaksetEditWindow#G0 tracenametowaveref("QANT_plot",scaninplot) vs xwavereffromtrace("QANT_plot",scaninplot)
		endif
	endif
	QANT_AddPeakstoPlotEdit(peakstoplot)
	variable /g xmin, xmax
	//getaxis /Q/W=QANT_PeaksetEditWindow#G0 bottom
	axismin = max(axismin, xmin)
	axismax = axismax==0 || xmax==0 ? max(axismax, xmax) : min(axismax, xmax)
	setaxis /W=QANT_PeaksetEditWindow#G0 bottom, axismin, axismax

end

function QANT_AddPeakstoPlotEdit(peakset)
	wave/t peakset
	string traces = TraceNameList("QANT_PeaksetEditWindow#G0",";",1)
	variable i,j, num = dimsize(peakset,0), center, width
	variable /g xmin = inf
	variable /g xmax = -inf
	variable numpoints =1000
	string dataname 
	variable dataplotted = 0
	if(itemsinlist(traces)<1)
		for(i=0;i<num;i+=1)
			center = str2num(stringfromlist(2,peakset[i]))
			width = str2num(stringfromlist(3,peakset[i]))
			xmin = min(center-1*abs(width), xmin)
			xmax = max(center+1*abs(width), xmax)
		endfor
		dataname = ""
		dataplotted = 0
		if(xmin>xmax)
			return 0
		endif
	else
		wave xwaveplot = XWaveRefFromTrace("QANT_PeaksetEditWindow#G0",stringfromlist(0,traces))
		if(!waveexists(xwaveplot))
			return 0
		endif
		if(wavemax(xwaveplot)-wavemin(xwaveplot) < 1)
			return 0
		endif
		xmin = wavemin(xwaveplot)
		xmax = wavemax(xwaveplot)
		dataname = stringfromlist(0,traces)
		dataplotted = 1
	endif
	make/o /n=(numpoints) xwave
	setscale /i x, xmin, xmax, xwave
	xwave = x
	colortab2wave Rainbow
	wave m_colors
	make/o /n=(dimsize(m_colors,0)) colorxwave, redwave = m_colors[p][0], greenwave = m_colors[p][1], bluewave = m_colors[p][2] 
	setscale /i x,0,num, colorxwave, redwave, greenwave, bluewave 
	colorxwave = x
	make/o /n=(num) rwave = interp(p,colorxwave, redwave), gwave =  interp(p,colorxwave, greenwave), bwave =  interp(p,colorxwave, bluewave)
	string peakname, blstr
	string blname
	string listofpeaktraces = ""
	String PeakFuncName
	variable BLplotted=0
	for(i=0;i<num;i+=1)
		peakname = QANT_WhooskaNametoMPF2(stringfromlist(0,peakset[i]))
		if(stringmatch(peakname,"*Edge*") || stringmatch(peakname,"*cubic*")|| stringmatch(peakname,"*linear*")|| stringmatch(peakname,"*constant*") )
			blstr = peakset[0]
			duplicate/o xwave, blwave
			blname = QANT_WhooskaNametoMPF2(stringfromlist(0,peakset[0]))
			FUNCREF MPF2_FuncInfoTemplate BLinfoFunc=$(blname+BL_INFO_SUFFIX)
			PeakFuncName = 	BLinfoFunc(PeakFuncInfo_PeakFName)
			struct MPF2_BLFitStruct BLStruct
			BlStruct.xend = xmax
			Blstruct.xstart = xmin
			wave BLStruct.cWave = $QANT_MakeCwaveFromPeakSet(peakset[0],1) 
			funcref MPF2_BaselineFunctionTemplate BLfunc = $PeakFuncName
			for(j=0;j<numpoints;j+=1)
				BlStruct.x=xwave[j]
				blwave[j] = BLfunc(BLStruct)
			endfor
			blname = "Peak_"+num2str(i)
			appendtograph /w=QANT_PeaksetEditWindow#G0 blwave /TN=$(blname)
			modifygraph /w=QANT_PeaksetEditWindow#G0 rgb($blname) = (rwave[0], gwave[0], bwave[0])
			ModifyGraph /w=QANT_PeaksetEditWindow#G0 mode($blname)=7, hbFill($blname)=4
			BLplotted=1
		else
			FUNCREF MPF2_FuncInfoTemplate PeakinfoFunc=$(peakname+PEAK_INFO_SUFFIX)
			PeakFuncName = 	PeakinfoFunc(PeakFuncInfo_PeakFName)
			funcref MPF2_PeakFunctionTemplate Peakfunc = $PeakFuncName
			wave cWave = $QANT_MakeCwaveFromPeakSet(peakset[i],1) 
			funcref MPF2_PeakFunctionTemplate Peakfunc = $PeakFuncName
			duplicate /o xwave, $("Peak_"+num2str(i))
			Peakfunc(cwave,$("Peak_"+num2str(i)),xwave)
			appendtograph /w=QANT_PeaksetEditWindow#G0 $("Peak_"+num2str(i)) /TN=$("Peak_"+num2str(i))//$(peakname+stringfromlist(2,Peakset[i]))
			appendtograph /w=QANT_PeaksetEditWindow#G0 $("Peak_"+num2str(i)) /TN=$("Peak_"+num2str(i)+"_h")//$(peakname+stringfromlist(2,Peakset[i])+"_h")
			listofpeaktraces += "Peak_"+num2str(i)+"_h;"
			if(dataplotted)
				reordertraces/w=QANT_PeaksetEditWindow#G0 $(stringfromlist(0,traces)), {$("Peak_"+num2str(i)) }
			endif
			modifygraph /w=QANT_PeaksetEditWindow#G0  lstyle($("Peak_"+num2str(i)) )=0, rgb($("Peak_"+num2str(i))) = (rwave[i], gwave[i], bwave[i])
			modifygraph /w=QANT_PeaksetEditWindow#G0  rgb($("Peak_"+num2str(i)+ "_h")) = (rwave[i], gwave[i], bwave[i])
			modifygraph /w=QANT_PeaksetEditWindow#G0  lsize($("Peak_"+num2str(i) )) = 2 // weight of normal plots
			modifygraph /w=QANT_PeaksetEditWindow#G0  lsize($("Peak_"+num2str(i) + "_h")) = 0 // weight of stacked plots
		endif
	endfor

	traces = TraceNameList("QANT_PeaksetEditWindow#G0",";",1)
	if(blplotted && dataplotted)
		reordertraces/w=QANT_PeaksetEditWindow#G0 $(stringfromlist(0,traces)), {$blname }
	endif
	string tracename
	for(i=0;i<num-1;i+=1)
		tracename = stringfromlist(i,listofpeaktraces)
		if(blplotted)
			reordertraces /w=QANT_PeaksetEditWindow#G0 $blname , { $stringfromlist(i,listofpeaktraces) }
		else
			reordertraces /w=QANT_PeaksetEditWindow#G0 $stringfromlist(num,listofpeaktraces) , { $stringfromlist(i,listofpeaktraces) }
		endif
		ModifyGraph /w=QANT_PeaksetEditWindow#G0 mode($tracename)=7,toMode($tracename)=3, hbFill($tracename)=5
	endfor
end

Function QANT_Slider_PeakAdjust(sa) : SliderControl
	STRUCT WMSliderAction &sa

	switch( sa.eventCode )
		case -1: // control being killed
			break
		default:
			Variable curval = sa.curval
			if( sa.eventCode & 1 ) // value set
				// when dragging, this will be actively set
				// look at the remembered "center" value, and calculate how much the current setting should be from there
				// set the "movement weight" based on the column that is selected (ie very small percentages for energy, .01 eV or so per pixel)
				// non linear scale so moderate movements move small ammounts, but large movements move moderate ammounts (possibly a x^3 scale?)
				// set the row and column accordingly
				// update peakset and graph
				sa.blockreentry=0
				wave/t listwave =  root:NEXAFS:fitting:peaksetdisp:peaklist
				nvar row =  root:NEXAFS:fitting:peaksetdisp:selrow
				nvar col =  root:NEXAFS:fitting:peaksetdisp:selcol
				nvar centerval =  root:NEXAFS:fitting:peaksetdisp:centervariable
				svar peaksetfit =  root:NEXAFS:peaksetfit // the name of the peakset we will be editing
				if(!waveexists(listwave) || !nvar_exists(centerval) || !svar_exists(peaksetfit) || !nvar_exists(row) || !nvar_exists(col)) // do the variables exist? (has a cell been selected?)
					break
				elseif(row<0 || row>=dimsize(listwave,0)-1 || col<=1 || col>5 || row*col*centerval*0!=0)
					break // exit now if any of the paramenters aren't valid or real numbers
				endif
				wave /t peakset = $("root:nexafs:fitting:"+possiblyquotename(peaksetfit)) // get the wave of the peakset
				if(!waveexists(peakset))
					break
				endif
				make /o/t /n=5 peakcomponents = stringfromlist(p,peakset[row]) // get the row of interest from the peakset
				if(col==3)
					peakcomponents[col-1] = num2str((((curval/2)^3)+1)*centerval) // here is where we set the new value based on the slider value and the center value
				else
					peakcomponents[col-1] = num2str(((curval^3)+1)*centerval) 
				endif
				QANT_Cleanuppeakcomponents(peakcomponents)
				variable j
				string newpeak=""
				for(j=dimsize(peakcomponents,0)-1;j>=0;j-=1)
					newpeak = addlistitem(peakcomponents[j],newpeak)
				endfor
				peakset[row] = newpeak
				QANT_updatePeaksetDisp()
				QANT_PeakEdit_UpdatePlot()
			endif
			if( sa.eventCode & 2 ) // mouse down
				wave/t listwave =  root:NEXAFS:fitting:peaksetdisp:peaklist
				nvar row =  root:NEXAFS:fitting:peaksetdisp:selrow
				nvar col =  root:NEXAFS:fitting:peaksetdisp:selcol
				if(!nvar_exists(row) || !nvar_exists(col)) // do the variables exist? (has a cell been selected?)
					break
				elseif(row<0 || row>=dimsize(listwave,0)-1 || col<=1 || col>5) // is the selected row/col valid (does it exist in the peakset)?
						//if col is 1, it is the peak type, which doesn't work for a slider, so don't do anything
					break
				endif
				string newstring = listwave[row][col] // the current value of the cell (string)
				string foldersave = getdatafolder(1)
				setdatafolder root:NEXAFS:fitting:peaksetdisp
				variable /g centervariable = str2num(newstring) // store right now the "center" value, which dragging the slider will adjust around
				
			
				// find the current value that we are changing, and set that as the "center"
				// find the row and column we are changing now...
				//
			endif
			if( sa.eventCode & 4 ) // mouse up
				// move the value back to 1
				slider $sa.ctrlName value=0
				QANT_PeakEdit_UpdatePlot()
				//sa.curval=1
				//
			endif
			if( sa.eventCode & 8 ) // mouse moved
				// not needed, this is taken care of though the value set bit
				//
			endif
			break
	endswitch

	return 0
End

Function QANT_Chk_peakset_addscan(cba) : CheckBoxControl
	STRUCT WMCheckboxAction &cba

	switch( cba.eventCode )
		case 2: // mouse up
			Variable checked = cba.checked
			QANT_PeakEdit_UpdatePlot()
			break
		case -1: // control being killed
			break
	endswitch

	return 0
End

Function QANT_fitting_duppeakset(ba) : ButtonControl
	STRUCT WMButtonAction &ba

	switch( ba.eventCode )
		case 2: // mouse up
			// click code here
			string foldersave = getdatafolder(1)
			setdatafolder root:NEXAFS:fitting
			svar peaksetfit =  root:NEXAFS:peaksetfit // the name of the peakset we will be editing
			if(!cmpstr("none",peaksetfit))
				break // don't duplicate anything
			endif
			wave /t peakset = $("root:nexafs:fitting:"+possiblyquotename(peaksetfit)) // get the wave of the peakset
			string newavename
			if(stringmatch(peaksetfit, "*_copy*"))
				string basename
				splitstring /e="(.*)_copy[1234567890]*$" peaksetfit, basename
			else
				basename = peaksetfit[0, min(strlen(peaksetfit)-1,15)]
			endif
			string newwavename = uniquename(Cleanupname(basename+"_copy",1),1,0)
			make /n=(dimsize(peakset,0)) /t $newwavename
			wave /t newpeakset = $newwavename
			newpeakset = peakset[p]
			variable popnum = findlistitem(newwavename,QANT_ListPeakSets())
			peaksetfit = newwavename
			popupmenu QANT_popup_PeakSet win=QANTLoaderPanel, mode=(popnum),popvalue=peaksetfit
			popupmenu QANT_popup_PeakSet win=QANT_PeaksetEditWindow, mode=(popnum),popvalue=peaksetfit
			QANT_updatePeaksetDisp()
			QANT_PeakEdit_UpdatePlot()
			break
		case -1: // control being killed
			break
	endswitch

	return 0
End

Function QANT_Popup_fitting_ScanToPlot(pa) : PopupMenuControl
	STRUCT WMPopupAction &pa

	switch( pa.eventCode )
		case 2: // mouse up
			Variable popNum = pa.popNum
			String popStr = pa.popStr
			svar scaninplot = root:NEXAFS:fitting:peaksetdisp:scaninplot
			scaninplot = popstr
			QANT_PeakEdit_UpdatePlot()
			break
		case -1: // control being killed
			break
	endswitch

	return 0
End

function QANT_PeaksetEdit()
	dowindow QANT_PeaksetEditWindow
	if(v_flag)
		dowindow /k QANT_peakseteditwindow
	endif
	String fldrSav0= GetDataFolder(1)
	setdatafolder root:NEXAFS
	newdatafolder /o/s fitting
	newdatafolder /o/s peaksetdisp
	variable/g addscantoplot
	string/g scaninplot
	variable/g scannuminplot
	if(!(strlen(scaninplot)>0))
		scaninplot = stringfromlist(scannuminplot,QANT_ListTraces())
	endif
	
	NewPanel /k=1/n=QANT_PeaksetEditWindow/W=(111,237,822,607) as "Peak Set Editing"
	ModifyPanel fixedSize=1, frameInset=1
	ListBox QANT_PeakSetEdit_list,pos={4,38},size={312,258},proc=QANT_List_PeakManager
	ListBox QANT_PeakSetEdit_list,listWave=root:NEXAFS:fitting:peaksetdisp:peaklist
	ListBox QANT_PeakSetEdit_list,selWave=root:NEXAFS:fitting:peaksetdisp:peaklistsel
	ListBox QANT_PeakSetEdit_list,titleWave=root:NEXAFS:fitting:peaksetdisp:peaklistcols
	ListBox QANT_PeakSetEdit_list,mode= 2,selRow= 10,widths={32,77,62,49,55,39,37}
	ListBox QANT_PeakSetEdit_list,userColumnResize= 1,font="Arial",fSize=10
	PopupMenu QANT_popup_PeakSet,pos={4,6},size={241,26},bodyWidth=207,proc=QANT_PeakSetPOP,title="Peak  \rSet:"
	svar peaksetfit =  root:NEXAFS:peaksetfit
	variable modenum = whichlistitem(peaksetfit,QANT_ListPeakSets())+1
	PopupMenu QANT_popup_PeakSet,mode=modenum,popvalue=peaksetfit,value= #"QANT_ListPeakSets()"
	
	PopupMenu QANT_popup_PeakSet,mode=modenum,popvalue=peaksetfit,value= #"QANT_ListPeakSets()"
	Button QANT_but_RemPeak,pos={203,328},size={89,38},proc=QANT_fitting_RmPeak,title="Remove Peak",font="Arial",fSize=10
	PopupMenu QANT_Fitting_NewFromGraphPop,pos={500,341},size={174,21},bodyWidth=143,proc=QANT_Popup_fitting_ScanToPlot,title="Scan:"
	PopupMenu QANT_Fitting_NewFromGraphPop,mode=scannuminplot+1,popvalue=scaninplot,value= #"QANT_ListTraces()"
	Button QANT_but_DuplicatePeak,pos={102,328},size={89,38},proc=QANT_Fitting_DupPeak,title="Duplicate Peak",font="Arial",fSize=10
	Button QANT_but_ViewAllPeaks,pos={14,304},size={64,30},proc=QANT_Button_View,title="View All",font="Arial",fSize=10
	Button QANT_but_ViewNoPeaks,pos={14,334},size={64,30},proc=QANT_Button_View,title="View None",font="Arial",fSize=10
	Slider QANT_PeakAdjustSlider,pos={92,303},size={291,19},proc=QANT_Slider_PeakAdjust
	Slider QANT_PeakAdjustSlider,limits={-1,1,0},value= 0,vert= 0,ticks= 0
	CheckBox QANT_peakset_Chk_addscan,pos={538,319},size={110,14},proc=QANT_Chk_peakset_addscan,title="Add Scan to Plot ? ",font="Arial",fSize=10
	CheckBox QANT_peakset_Chk_addscan,variable=addscantoplot
	Button QANT_but_DuplicatePeakset,pos={246,4},size={69,33},proc=QANT_fitting_duppeakset,title="Duplicate\rPeak Set",font="Arial",fSize=10
	Display/W=(320,6,706,301)/HOST=#
	RenameWindow #,G0
	SetActiveSubwindow ##
	SetDataFolder fldrSav0
	QANT_updatePeaksetDisp()
	QANT_PeakEdit_UpdatePlot()
	setwindow QANT_PeaksetEditWindow hook(clicking)=peakwindowclickhook
End
Function QANT_EditPeaksetWindowOpen(ba) : ButtonControl
	STRUCT WMButtonAction &ba

	switch( ba.eventCode )
		case 2: // mouse up
			// click code here
			QANT_PeaksetEdit()
			break
		case -1: // control being killed
			break
	endswitch

	return 0
End
function peakwindowclickhook(hs)
	struct WMWinHookStruct &hs
	
	variable ret=0
	if(stringmatch(hs.eventname,"mousedown") && hs.eventmod==1)
		string traceclickedinfo = tracefrompixel(hs.mouseloc.h, hs.mouseLoc.v, "")
		string peaknum = ""
		splitstring /e="^Peak_([0123456789]*)(_h)?$" stringbykey("trace",traceclickedinfo), peaknum
		variable row
		if(strlen(peaknum))
			row = str2num(peaknum)
			listbox QANT_PeakSetEdit_list selrow=row
			nvar selrow=root:NEXAFS:fitting:peaksetdisp:selrow
			selrow = row
			ret=1
		endif
	endif
	return ret
end


/// code for reading MDA files : 
//__________________________________________________________________________
structure QANT_mda_header
	float version
	int32 scannum
	int16 datarank
	int16 datarank2
	int32 dimension1
	int16 regular
	int16 regular2
	int32 extraPVsOffset
endstructure

structure QANT_mda_scan

	int16  scan_rank
	int16 scan_rank2
	int32  requested_points
	int32  last_point
	int32  offset1
endstructure

function /s QANT_readstring(fileref,extra)
	variable fileref
	variable extra
	variable templen
	fbinread /B /F=3 fileref, templen
	if(templen && extra)
		fbinread /B /F=3 fileref, templen
	endif
	string name = padstring("",ceil(templen/4)*4,0)
	FBinRead /B fileref, name
	name = name[0,templen-1]
	return name
end

function /s QANT_readpositioner(fileref)
	variable fileref
	variable num
	variable templen
	fbinread /B /F=3 fileref, num
	string name = QANT_readstring(fileref,1)
	string description = QANT_readstring(fileref,1)
	string step_mode = QANT_readstring(fileref,1)
	string unit = QANT_readstring(fileref,1)
	string readback_name = QANT_readstring(fileref,1)
	string readback_description = QANT_readstring(fileref,1)
	string readback_unit = QANT_readstring(fileref,1)
	return num2str(num)+ "," + name + "," + description + "," + step_mode + "," +unit  + "," + readback_name + "," + readback_description + "," + readback_unit
end

function /s QANT_readdetector(fileref)
	variable fileref
	variable num
	variable templen
	fbinread /B /F=3 fileref, num
	string name = QANT_readstring(fileref,1)
	string description = QANT_readstring(fileref,1)
	string unit = QANT_readstring(fileref,1)
	return num2str(num)+ "," + name + "," + description + "," + unit
end

function /s QANT_readPV(fileref)
	variable fileref
	string name = QANT_readstring(fileref,1)
	string description = QANT_readstring(fileref,1)
	variable type, num
	fbinread /B /F=3 fileref, type
	num=1
	string unit=""
	if(type)
		fbinread /B /F=3 fileref, num
		num=1
		unit = QANT_readstring(fileref,1)
	endif
	variable i, value
	string output = ""
	if(type==0)
		output += QANT_readstring(fileref,1)+";"
	elseif(type==32)
		for(i=0;i<num;i+=1)
			fbinread /B /F=1 fileref, value
			output += num2str(value)+";"
			fbinread /B /F=1 fileref, value
			fbinread /B /F=1 fileref, value
			fbinread /B /F=1 fileref, value
		endfor
	elseif(type==29)
		for(i=0;i<num;i+=1)
			fbinread /B /F=2 fileref, value
			output += num2str(value)+";"
			fbinread /B /F=2 fileref, value
		endfor
	elseif(type==33)
		for(i=0;i<num;i+=1)
			fbinread /B /F=3 fileref, value
			output += num2str(value)+";"
		endfor
	elseif(type==30)
		for(i=0;i<num;i+=1)
			fbinread /B /F=4 fileref, value
			output += num2str(value)+";"
		endfor
	elseif(type==34)
		for(i=0;i<num;i+=1)
			fbinread /B /F=5 fileref, value
			output += num2str(value)+";"
		endfor
	else
		output=""
	endif
	return name + " , " + description + " , " + output + " , " + unit
end

function /s QANT_readtrigger(fileref)
	variable fileref
	variable num
	variable command
	variable templen
	fbinread /B /F=3 fileref, num
	string name = QANT_readstring(fileref,1)
	fbinread /B /F=4 fileref, command
	return num2str(num)+ " , " + name + " , " + num2str(command)
end

function /s QANT_LoadNEXAFSfile(pathn) // MDA
	string pathn
	variable fileref
	open/r/F="NEXAFS files (*.mda,):.mda;" fileref as pathn
	string fullpath = s_filename
	FStatus fileref
	if(V_flag==0)
		return ""
	endif
	
	struct QANT_mda_header header
	struct QANT_mda_scan startofscan
	FBinRead /B fileref, header
	FBinRead /B fileref, startofscan
	variable testval
	string name = QANT_readstring(fileref,0)
	string scantime = QANT_readstring(fileref,1)
	string year, month, day,hour,minute,second
	splitstring /e="^([[:alpha:]]{3})\\s([[:digit:]]{1,2}),\\s([[:digit:]]{4})\\s([[:digit:]]{1,2}):([[:digit:]]{2}):([[:digit:]]*[.][[:digit:]]*)" scantime, month, day, year, hour, minute, second
	//print "\""+month+ "\""
	variable monv = !cmpstr("Jan",month) ? 1 : monv
	monv = !cmpstr("Feb",month) ? 2 : monv
	monv = !cmpstr("Mar",month) ? 3 : monv
	monv = !cmpstr("Apr",month) ? 4 : monv
	monv = !cmpstr("May",month) ? 5 : monv
	monv = !cmpstr("Jun",month) ? 6 : monv
	monv = !cmpstr("Jul",month) ? 7 : monv
	monv = !cmpstr("Aug",month) ? 8 : monv
	monv = !cmpstr("Sep",month) ? 9 : monv
	monv = !cmpstr("Oct",month) ? 10 : monv
	monv = !cmpstr("Nov",month) ? 11 : monv
	monv = !cmpstr("Dec",month) ? 12 : monv
	scantime = year + " " + num2str(monv) + " " + Day+ " " +hour+ ":" +minute+ ":" +second
	
	variable number_positioners, number_detectors, number_triggers
	fbinread /B /F=3 fileref, number_positioners
	fbinread /B /F=3 fileref, number_detectors
	fbinread /B /F=3 fileref, number_triggers
	make /t/o/n=(number_positioners) positioners
	variable i
	for(i=0;i<number_positioners;i+=1)
		positioners[i] = QANT_readpositioner(fileref)
	endfor
	make /t/o/n=(number_detectors) detectors
	for(i=0;i<number_detectors;i+=1)
		detectors[i] = QANT_readdetector(fileref)
	endfor
	make /t/o/n=(number_triggers) triggers
	for(i=0;i<number_triggers;i+=1)
		triggers[i] = QANT_readtrigger(fileref)
	endfor
	//
	
	if(startofscan.last_point<5 || startofscan.last_point==0)
		//print "Aborted Scan Detected"
		close fileref
		return ""
	endif
	
	string scanname = ParseFilePath(3, fullpath, ":", 1, 0)
	string foldersave = getdatafolder(1)
	
	setdatafolder root:
	newdatafolder /O/S NEXAFS

	wave /T QANT_LUT
	newdatafolder /O/S Scans
	newdatafolder /O/S $cleanupname(scanname,1)

	killwaves /Z/A
	string /g filename = fullpath
	string /g acqtime = scantime
	getfilefolderinfo /p=NEXAFSPath /q/z scanname+".mda"
	string /g filesize
	sprintf filesize, "%d" ,v_logEOF
	string /g cdate
	sprintf cdate, "%d" ,v_creationdate
	string /g mdate
	sprintf mdate, "%d" ,v_modificationdate
	
	string /g notes
	if(strlen(notes)*0!=0)
		notes = ""
	endif
	string /g anglestr
	if(strlen(anglestr)*0!=0)
		anglestr = ""
	endif
	string /g otherstr
	if(strlen(otherstr)*0!=0)
		otherstr = ""
	endif
	string /g SampleName
	if(strlen(SampleName)*0!=0)
		SampleName = ""
	endif
	string /g SampleSet
	if(strlen(SampleSet)*0!=0)
		SampleSet = ""
	endif
	string /g refscan
	if(strlen(refscan)*0!=0)
		refscan = "Default"
	endif
	string /g darkscan
	if(strlen(darkscan)*0!=0)
		darkscan = "Default"
	endif
	string /g enoffset
	if(strlen(enoffset)*0!=0)
		enoffset = "Default"
	endif
	
	string columnname,nametouse
	variable columnnum=0
	make /o/n=(number_positioners+number_detectors) /T Columnnames
	for(i=0;i<number_positioners;i+=1)
		columnname = stringfromlist(1,positioners[i],",")
		FindValue /TEXT=columnname /TXOP=3 QANT_LUT
		if(v_value>=0) // use the look up table if it exists
			nametouse = QANT_LUT[v_value][1]
		else // if not, try to find an english name in the description
			if(strlen(replacestring(" ",stringfromlist(2,positioners[i],","),""))>0)
				nametouse = replacestring(" ",stringfromlist(2,positioners[i],","),"")
			else // otherwise just use the full PVname
				nametouse = columnname
			endif
		endif
		if(checkname(nametouse,1)==0) // is the name valid?
			columnname = nametouse // if so, use it
		else				
			columnname= uniquename(cleanupname(nametouse,1),1,0) // if not, clean it up
		endif
		make /n=(header.dimension1) $columnname
		fbinread /B/F=5 fileref, $columnname
		redimension /n=(startofscan.last_point) $columnname
		DeletePoints 0,2,$columnname
		Columnnames[columnnum] = columnname
		columnnum+=1
		
	endfor
	for(i=0;i<number_detectors;i+=1)
		columnname = stringfromlist(1,detectors[i],",")
		FindValue /TEXT=columnname /TXOP=3 QANT_LUT
		if(v_value>=0) // use the look up table if it exists
			nametouse = QANT_LUT[v_value][1]
		else // if not, try to find an english name in the description
			if(strlen(replacestring(" ",stringfromlist(2,detectors[i],","),""))>0)
				nametouse = replacestring(" ",stringfromlist(2,detectors[i],","),"")
			else // otherwise just use the full PVname
				nametouse = columnname
			endif
		endif
		if(checkname(nametouse,1)==0) // is the name valid?
			columnname = nametouse // if so, use it
		else				
			columnname= uniquename(cleanupname(nametouse,1),1,0) // if not, clean it up
		endif
		make /n=(header.dimension1) $columnname
		fbinread /B/F=4 fileref, $columnname
		redimension /n=(startofscan.last_point) $columnname
		DeletePoints 0,2,$columnname
		
		Columnnames[columnnum] = columnname
		columnnum+=1
	endfor
	variable num_extrapv
	Fsetpos fileref, header.extraPVsOffset
	fbinread /B /F=3 fileref, num_extrapv
	if(num_extrapv > 500)
		print "Error with PVs, not loaded for NEXAFS file : " + cleanupname(scanname,1)
		close fileref
		return 	cleanupname(scanname,1)
	endif
	make /t/o/n=(num_extrapv,4) ExtraPVs
	string pvstring
	for(i=0;i<num_extrapv;i+=1)
		pvstring = QANT_readPV(fileref)
		ExtraPVs[i]= removeending(removeending(stringfromlist(q,pvstring,", "),"; ")," ")
	endfor
	close fileref
	if(dimsize(extrapvs,0)>0)
		//make /o/t/n=(dimsize(extrapvs,0),4) extrainfo
		duplicate /t /o extrapvs, extrainfo
		variable k
		//string pvname, realname, value, units
		//for(k=0;k<dimsize(extrapvs,0);k+=1)
		//	splitstring /e="^\\s*([^,\\s]{1,})\\s*,\\s*([^,]*)\\s*,\\s*\"?([^\"]*)\"?\\s*,?\\s*([^\\s]*)?" extrapvs[k], pvname, realname, value, units
		//	//splitstring /e="^#[\\s]*Extra PV [[:digit:]]+:\\s+([^,\\s]{1,})\\s*,\\s*([^,]*)\\s*,\\s*\"?([^\"]*)\"?\\s*,?\\s*([^\\s]*)?" extrapvs[k], pvname, realname, value, units
		//	extrainfo[k][0] = pvname
		//	extrainfo[k][1] = realname
		//	extrainfo[k][2] = value
		//	extrainfo[k][3] = units
		//endfor
		variable xloc=nan, yloc=nan, zloc=nan, r1loc=nan, r2loc=nan
		findvalue /text="SR14ID01TEMPSCAN:saveData_comment1" extrainfo
		if(v_value >=0)
			samplename = cleanupname(replacestring(" ",extrainfo[v_value][2],"",1,1),0)
			notes = extrainfo[v_value][2]
		endif
		findvalue /text="SR14ID01TEMPSCAN:saveData_comment2" extrainfo
		if(v_value >=0)
			notes += " " +extrainfo[v_value][2]
		endif
		
		findvalue /text="SR14ID01MCS02FAM:X.RBV" extrainfo
		if(v_value >=0)
			xloc=str2num(extrainfo[v_value][2])
		endif
		findvalue /text="SR14ID01MCS02FAM:Y.RBV" extrainfo
		if(v_value >=0)
			yloc=str2num(extrainfo[v_value][2])
		endif
		findvalue /text="SR14ID01MCS02FAM:Z.RBV" extrainfo
		if(v_value >=0)
			zloc=str2num(extrainfo[v_value][2])
		endif
		findvalue /text="SR14ID01MCS02FAM:R1.RBV" extrainfo
		if(v_value >=0)
			R1loc=str2num(extrainfo[v_value][2])
			anglestr = num2str(str2num(extrainfo[v_value][2])-45)
		endif
		findvalue /text="SR14ID01MCS02FAM:R2.RBV" extrainfo
		if(v_value >=0)
			R2loc=str2num(extrainfo[v_value][2])
			otherstr = num2str(str2num(extrainfo[v_value][2]))
		endif
		if(xloc*yloc*zloc*r1loc*r2loc*0==0)
			notes += "( X="+num2str(xloc)+", Y="+num2str(yloc)+", Z="+num2str(zloc)+", R1="+num2str(r1loc)+", R2="+num2str(r2loc)+")"
		endif
		
	endif
	
	setdatafolder foldersave
	print "Loaded NEXAFS file : " + cleanupname(scanname,1)
	return 	cleanupname(scanname,1)
end
function /s QANT_NEXAFSfileEXt_AUMain() // MDA
	return ".mda"
end
function /s QANT_LoadNEXAFSfile_AUMain(pathn) // MDA
	string pathn
	variable fileref
	open/r/F="NEXAFS files (*.mda,):.mda;" fileref as pathn
	string fullpath = s_filename
	FStatus fileref
	if(V_flag==0)
		return ""
	endif
	
	struct QANT_mda_header header
	struct QANT_mda_scan startofscan
	FBinRead /B fileref, header
	FBinRead /B fileref, startofscan
	variable testval
	string name = QANT_readstring(fileref,0)
	string scantime = QANT_readstring(fileref,1)
	string year, month, day,hour,minute,second
	splitstring /e="^([[:alpha:]]{3})\\s([[:digit:]]{1,2}),\\s([[:digit:]]{4})\\s([[:digit:]]{1,2}):([[:digit:]]{2}):([[:digit:]]*[.][[:digit:]]*)" scantime, month, day, year, hour, minute, second
	//print "\""+month+ "\""
	variable monv = !cmpstr("Jan",month) ? 1 : monv
	monv = !cmpstr("Feb",month) ? 2 : monv
	monv = !cmpstr("Mar",month) ? 3 : monv
	monv = !cmpstr("Apr",month) ? 4 : monv
	monv = !cmpstr("May",month) ? 5 : monv
	monv = !cmpstr("Jun",month) ? 6 : monv
	monv = !cmpstr("Jul",month) ? 7 : monv
	monv = !cmpstr("Aug",month) ? 8 : monv
	monv = !cmpstr("Sep",month) ? 9 : monv
	monv = !cmpstr("Oct",month) ? 10 : monv
	monv = !cmpstr("Nov",month) ? 11 : monv
	monv = !cmpstr("Dec",month) ? 12 : monv
	scantime = year + " " + num2str(monv) + " " + Day+ " " +hour+ ":" +minute+ ":" +second
	
	variable number_positioners, number_detectors, number_triggers
	fbinread /B /F=3 fileref, number_positioners
	fbinread /B /F=3 fileref, number_detectors
	fbinread /B /F=3 fileref, number_triggers
	make /t/o/n=(number_positioners) positioners
	variable i
	for(i=0;i<number_positioners;i+=1)
		positioners[i] = QANT_readpositioner(fileref)
	endfor
	make /t/o/n=(number_detectors) detectors
	for(i=0;i<number_detectors;i+=1)
		detectors[i] = QANT_readdetector(fileref)
	endfor
	make /t/o/n=(number_triggers) triggers
	for(i=0;i<number_triggers;i+=1)
		triggers[i] = QANT_readtrigger(fileref)
	endfor
	//
	
	if(startofscan.last_point<5 || startofscan.last_point==0)
		//print "Aborted Scan Detected"
		close fileref
		return ""
	endif
	
	string scanname = ParseFilePath(3, fullpath, ":", 1, 0)
	string foldersave = getdatafolder(1)
	
	setdatafolder root:
	newdatafolder /O/S NEXAFS

	wave /T QANT_LUT
	newdatafolder /O/S Scans
	newdatafolder /O/S $cleanupname(scanname,1)

	killwaves /Z/A
	string /g filename = fullpath
	string /g acqtime = scantime
	getfilefolderinfo /p=NEXAFSPath /q/z scanname+".mda"
	string /g filesize
	sprintf filesize, "%d" ,v_logEOF
	string /g cdate
	sprintf cdate, "%d" ,v_creationdate
	string /g mdate
	sprintf mdate, "%d" ,v_modificationdate
	
	string /g notes
	if(strlen(notes)*0!=0)
		notes = ""
	endif
	string /g anglestr
	if(strlen(anglestr)*0!=0)
		anglestr = ""
	endif
	string /g otherstr
	if(strlen(otherstr)*0!=0)
		otherstr = ""
	endif
	string /g SampleName
	if(strlen(SampleName)*0!=0)
		SampleName = ""
	endif
	string /g SampleSet
	if(strlen(SampleSet)*0!=0)
		SampleSet = ""
	endif
	string /g refscan
	if(strlen(refscan)*0!=0)
		refscan = "Default"
	endif
	string /g darkscan
	if(strlen(darkscan)*0!=0)
		darkscan = "Default"
	endif
	string /g enoffset
	if(strlen(enoffset)*0!=0)
		enoffset = "Default"
	endif
	
	string columnname,nametouse
	variable columnnum=0
	make /o/n=(number_positioners+number_detectors) /T Columnnames
	for(i=0;i<number_positioners;i+=1)
		columnname = stringfromlist(1,positioners[i],",")
		FindValue /TEXT=columnname /TXOP=3 QANT_LUT
		if(v_value>=0) // use the look up table if it exists
			nametouse = QANT_LUT[v_value][1]
		else // if not, try to find an english name in the description
			if(strlen(replacestring(" ",stringfromlist(2,positioners[i],","),""))>0)
				nametouse = replacestring(" ",stringfromlist(2,positioners[i],","),"")
			else // otherwise just use the full PVname
				nametouse = columnname
			endif
		endif
		if(checkname(nametouse,1)==0) // is the name valid?
			columnname = nametouse // if so, use it
		else				
			columnname= uniquename(cleanupname(nametouse,1),1,0) // if not, clean it up
		endif
		make /n=(header.dimension1) $columnname
		fbinread /B/F=5 fileref, $columnname
		redimension /n=(startofscan.last_point) $columnname
		DeletePoints 0,2,$columnname
		Columnnames[columnnum] = columnname
		columnnum+=1
		
	endfor
	for(i=0;i<number_detectors;i+=1)
		columnname = stringfromlist(1,detectors[i],",")
		FindValue /TEXT=columnname /TXOP=3 QANT_LUT
		if(v_value>=0) // use the look up table if it exists
			nametouse = QANT_LUT[v_value][1]
		else // if not, try to find an english name in the description
			if(strlen(replacestring(" ",stringfromlist(2,detectors[i],","),""))>0)
				nametouse = replacestring(" ",stringfromlist(2,detectors[i],","),"")
			else // otherwise just use the full PVname
				nametouse = columnname
			endif
		endif
		if(checkname(nametouse,1)==0) // is the name valid?
			columnname = nametouse // if so, use it
		else				
			columnname= uniquename(cleanupname(nametouse,1),1,0) // if not, clean it up
		endif
		make /n=(header.dimension1) $columnname
		fbinread /B/F=4 fileref, $columnname
		redimension /n=(startofscan.last_point) $columnname
		DeletePoints 0,2,$columnname
		
		Columnnames[columnnum] = columnname
		columnnum+=1
	endfor
	variable num_extrapv
	Fsetpos fileref, header.extraPVsOffset
	fbinread /B /F=3 fileref, num_extrapv
	if(num_extrapv > 500)
		print "Error with PVs, not loaded for NEXAFS file : " + cleanupname(scanname,1)
		close fileref
		return 	cleanupname(scanname,1)
	endif
	make /t/o/n=(num_extrapv,4) ExtraPVs
	string pvstring
	for(i=0;i<num_extrapv;i+=1)
		pvstring = QANT_readPV(fileref)
		ExtraPVs[i]= removeending(removeending(stringfromlist(q,pvstring,", "),"; ")," ")
	endfor
	close fileref
	if(dimsize(extrapvs,0)>0)
		//make /o/t/n=(dimsize(extrapvs,0),4) extrainfo
		duplicate /t /o extrapvs, extrainfo
		variable k
		//string pvname, realname, value, units
		//for(k=0;k<dimsize(extrapvs,0);k+=1)
		//	splitstring /e="^\\s*([^,\\s]{1,})\\s*,\\s*([^,]*)\\s*,\\s*\"?([^\"]*)\"?\\s*,?\\s*([^\\s]*)?" extrapvs[k], pvname, realname, value, units
		//	//splitstring /e="^#[\\s]*Extra PV [[:digit:]]+:\\s+([^,\\s]{1,})\\s*,\\s*([^,]*)\\s*,\\s*\"?([^\"]*)\"?\\s*,?\\s*([^\\s]*)?" extrapvs[k], pvname, realname, value, units
		//	extrainfo[k][0] = pvname
		//	extrainfo[k][1] = realname
		//	extrainfo[k][2] = value
		//	extrainfo[k][3] = units
		//endfor
		variable xloc=nan, yloc=nan, zloc=nan, r1loc=nan, r2loc=nan
		findvalue /text="SR14ID01TEMPSCAN:saveData_comment1" extrainfo
		if(v_value >=0)
			samplename = cleanupname(replacestring(" ",extrainfo[v_value][2],"",1,1),0)
			notes = extrainfo[v_value][2]
		endif
		findvalue /text="SR14ID01TEMPSCAN:saveData_comment2" extrainfo
		if(v_value >=0)
			notes += " " +extrainfo[v_value][2]
		endif
		
		findvalue /text="SR14ID01MCS02FAM:X.RBV" extrainfo
		if(v_value >=0)
			xloc=str2num(extrainfo[v_value][2])
		endif
		findvalue /text="SR14ID01MCS02FAM:Y.RBV" extrainfo
		if(v_value >=0)
			yloc=str2num(extrainfo[v_value][2])
		endif
		findvalue /text="SR14ID01MCS02FAM:Z.RBV" extrainfo
		if(v_value >=0)
			zloc=str2num(extrainfo[v_value][2])
		endif
		findvalue /text="SR14ID01MCS02FAM:R1.RBV" extrainfo
		if(v_value >=0)
			R1loc=str2num(extrainfo[v_value][2])
			anglestr = num2str(str2num(extrainfo[v_value][2])-45)
		endif
		findvalue /text="SR14ID01MCS02FAM:R2.RBV" extrainfo
		if(v_value >=0)
			R2loc=str2num(extrainfo[v_value][2])
			otherstr = num2str(str2num(extrainfo[v_value][2]))
		endif
		if(xloc*yloc*zloc*r1loc*r2loc*0==0)
			notes += "( X="+num2str(xloc)+", Y="+num2str(yloc)+", Z="+num2str(zloc)+", R1="+num2str(r1loc)+", R2="+num2str(r2loc)+")"
		endif
		
	endif
	
	setdatafolder foldersave
	print "Loaded NEXAFS file : " + cleanupname(scanname,1)
	return 	cleanupname(scanname,1)
end
function /s QANT_NEXAFSfileEXt_AUFast() // MDA
	return ".mda"
end
function /s QANT_LoadNEXAFSfile_AUFast(pathn) // MDA
	string pathn
	variable fileref
	open/r/F="NEXAFS files (*.mda,):.mda;" fileref as pathn
	string fullpath = s_filename
	FStatus fileref
	if(V_flag==0)
		return ""
	endif
	
	struct QANT_mda_header header
	struct QANT_mda_scan startofscan
	FBinRead /B fileref, header
	FBinRead /B fileref, startofscan
	variable testval
	string name = QANT_readstring(fileref,0)
	string scantime = QANT_readstring(fileref,1)
	string year, month, day,hour,minute,second
	splitstring /e="^([[:alpha:]]{3})\\s([[:digit:]]{1,2}),\\s([[:digit:]]{4})\\s([[:digit:]]{1,2}):([[:digit:]]{2}):([[:digit:]]*[.][[:digit:]]*)" scantime, month, day, year, hour, minute, second
	//print "\""+month+ "\""
	variable monv = !cmpstr("Jan",month) ? 1 : monv
	monv = !cmpstr("Feb",month) ? 2 : monv
	monv = !cmpstr("Mar",month) ? 3 : monv
	monv = !cmpstr("Apr",month) ? 4 : monv
	monv = !cmpstr("May",month) ? 5 : monv
	monv = !cmpstr("Jun",month) ? 6 : monv
	monv = !cmpstr("Jul",month) ? 7 : monv
	monv = !cmpstr("Aug",month) ? 8 : monv
	monv = !cmpstr("Sep",month) ? 9 : monv
	monv = !cmpstr("Oct",month) ? 10 : monv
	monv = !cmpstr("Nov",month) ? 11 : monv
	monv = !cmpstr("Dec",month) ? 12 : monv
	scantime = year + " " + num2str(monv) + " " + Day+ " " +hour+ ":" +minute+ ":" +second
	
	variable number_positioners, number_detectors, number_triggers
	fbinread /B /F=3 fileref, number_positioners
	fbinread /B /F=3 fileref, number_detectors
	fbinread /B /F=3 fileref, number_triggers
	make /t/o/n=(number_positioners) positioners
	variable i
	for(i=0;i<number_positioners;i+=1)
		positioners[i] = QANT_readpositioner(fileref)
	endfor
	make /t/o/n=(number_detectors) detectors
	for(i=0;i<number_detectors;i+=1)
		detectors[i] = QANT_readdetector(fileref)
	endfor
	make /t/o/n=(number_triggers) triggers
	for(i=0;i<number_triggers;i+=1)
		triggers[i] = QANT_readtrigger(fileref)
	endfor
	//
	
	if(startofscan.last_point<5 || startofscan.last_point==0)
		//print "Aborted Scan Detected"
		close fileref
		return ""
	endif
	
	string scanname = ParseFilePath(3, fullpath, ":", 1, 0)
	string foldersave = getdatafolder(1)
	
	setdatafolder root:
	newdatafolder /O/S NEXAFS

	wave /T QANT_LUT
	newdatafolder /O/S Scans
	newdatafolder /O/S $cleanupname(scanname,1)

	killwaves /Z/A
	string /g filename = fullpath
	string /g acqtime = scantime
	getfilefolderinfo /p=NEXAFSPath /q/z scanname+".mda"
	string /g filesize
	sprintf filesize, "%d" ,v_logEOF
	string /g cdate
	sprintf cdate, "%d" ,v_creationdate
	string /g mdate
	sprintf mdate, "%d" ,v_modificationdate
	
	string /g notes
	if(strlen(notes)*0!=0)
		notes = ""
	endif
	string /g anglestr
	if(strlen(anglestr)*0!=0)
		anglestr = ""
	endif
	string /g otherstr
	if(strlen(otherstr)*0!=0)
		otherstr = ""
	endif
	string /g SampleName
	if(strlen(SampleName)*0!=0)
		SampleName = ""
	endif
	string /g SampleSet
	if(strlen(SampleSet)*0!=0)
		SampleSet = ""
	endif
	string /g refscan
	if(strlen(refscan)*0!=0)
		refscan = "Default"
	endif
	string /g darkscan
	if(strlen(darkscan)*0!=0)
		darkscan = "Default"
	endif
	string /g enoffset
	if(strlen(enoffset)*0!=0)
		enoffset = "Default"
	endif
	
	string columnname,nametouse
	variable columnnum=0
	make /o/n=(number_positioners+number_detectors) /T Columnnames
	for(i=0;i<number_positioners;i+=1)
		columnname = stringfromlist(1,positioners[i],",")
		FindValue /TEXT=columnname /TXOP=3 QANT_LUT
		if(v_value>=0) // use the look up table if it exists
			nametouse = QANT_LUT[v_value][1]
		else // if not, try to find an english name in the description
			if(strlen(replacestring(" ",stringfromlist(2,positioners[i],","),""))>0)
				nametouse = replacestring(" ",stringfromlist(2,positioners[i],","),"")
			else // otherwise just use the full PVname
				nametouse = columnname
			endif
		endif
		if(checkname(nametouse,1)==0) // is the name valid?
			columnname = nametouse // if so, use it
		else				
			columnname= uniquename(cleanupname(nametouse,1),1,0) // if not, clean it up
		endif
		make /n=(header.dimension1) $columnname
		fbinread /B/F=5 fileref, $columnname
		redimension /n=(startofscan.last_point) $columnname
		DeletePoints 0,2,$columnname
		Columnnames[columnnum] = columnname
		columnnum+=1
		
	endfor
	for(i=0;i<number_detectors;i+=1)
		columnname = stringfromlist(1,detectors[i],",")
		FindValue /TEXT=columnname /TXOP=3 QANT_LUT
		if(v_value>=0) // use the look up table if it exists
			nametouse = QANT_LUT[v_value][1]
		else // if not, try to find an english name in the description
			if(strlen(replacestring(" ",stringfromlist(2,detectors[i],","),""))>0)
				nametouse = replacestring(" ",stringfromlist(2,detectors[i],","),"")
			else // otherwise just use the full PVname
				nametouse = columnname
			endif
		endif
		if(checkname(nametouse,1)==0) // is the name valid?
			columnname = nametouse // if so, use it
		else				
			columnname= uniquename(cleanupname(nametouse,1),1,0) // if not, clean it up
		endif
		make /n=(header.dimension1) $columnname
		fbinread /B/F=4 fileref, $columnname
		redimension /n=(startofscan.last_point) $columnname
		DeletePoints 0,2,$columnname
		
		Columnnames[columnnum] = columnname
		columnnum+=1
	endfor
	variable num_extrapv
	Fsetpos fileref, header.extraPVsOffset
	fbinread /B /F=3 fileref, num_extrapv
	if(num_extrapv > 500)
		print "Error with PVs, not loaded for NEXAFS file : " + cleanupname(scanname,1)
		close fileref
		return 	cleanupname(scanname,1)
	endif
	make /t/o/n=(num_extrapv,4) ExtraPVs
	string pvstring
	for(i=0;i<num_extrapv;i+=1)
		pvstring = QANT_readPV(fileref)
		ExtraPVs[i]= removeending(removeending(stringfromlist(q,pvstring,", "),"; ")," ")
	endfor
	close fileref
	if(dimsize(extrapvs,0)>0)
		//make /o/t/n=(dimsize(extrapvs,0),4) extrainfo
		duplicate /t /o extrapvs, extrainfo
		variable k
		//string pvname, realname, value, units
		//for(k=0;k<dimsize(extrapvs,0);k+=1)
		//	splitstring /e="^\\s*([^,\\s]{1,})\\s*,\\s*([^,]*)\\s*,\\s*\"?([^\"]*)\"?\\s*,?\\s*([^\\s]*)?" extrapvs[k], pvname, realname, value, units
		//	//splitstring /e="^#[\\s]*Extra PV [[:digit:]]+:\\s+([^,\\s]{1,})\\s*,\\s*([^,]*)\\s*,\\s*\"?([^\"]*)\"?\\s*,?\\s*([^\\s]*)?" extrapvs[k], pvname, realname, value, units
		//	extrainfo[k][0] = pvname
		//	extrainfo[k][1] = realname
		//	extrainfo[k][2] = value
		//	extrainfo[k][3] = units
		//endfor
		variable xloc=nan, yloc=nan, zloc=nan, r1loc=nan, r2loc=nan
		findvalue /text="SR14ID01NEXSCAN:saveData_comment1" extrainfo
		if(v_value >=0)
			samplename = cleanupname(replacestring(" ",extrainfo[v_value][2],"",1,1),0)
			notes = extrainfo[v_value][2]
		endif
		findvalue /text="SR14ID01NEXSCAN:saveData_comment2" extrainfo
		if(v_value >=0)
			notes += " " +extrainfo[v_value][2]
		endif
		
		findvalue /text="SR14ID01NEX01:X_MTR.RBV" extrainfo
		if(v_value >=0)
			xloc=str2num(extrainfo[v_value][2])
		endif
		findvalue /text="SR14ID01NEX01:Y_MTR.RBV" extrainfo
		if(v_value >=0)
			yloc=str2num(extrainfo[v_value][2])
		endif
		findvalue /text="SR14ID01NEX01:Z_MTR.RBV" extrainfo
		if(v_value >=0)
			zloc=str2num(extrainfo[v_value][2])
		endif
		findvalue /text="SR14ID01NEX01:R_MTR.RBV" extrainfo
		if(v_value >=0)
			R1loc=str2num(extrainfo[v_value][2])
			anglestr = num2str(str2num(extrainfo[v_value][2]))
		endif
		findvalue /text="SR14ID01NEX01:C_MTR.RBV" extrainfo
		if(v_value >=0)
			R2loc=str2num(extrainfo[v_value][2])
			otherstr = num2str(str2num(extrainfo[v_value][2]))
		endif
		if(xloc*yloc*zloc*r1loc*r2loc*0==0)
			notes += "( X="+num2str(xloc)+", Y="+num2str(yloc)+", Z="+num2str(zloc)+", R="+num2str(r1loc)+", C="+num2str(r2loc)+")"
		endif
		
	endif
	
	setdatafolder foldersave
	print "Loaded NEXAFS file : " + cleanupname(scanname,1)
	return 	cleanupname(scanname,1)
end
function /s QANT_NEXAFSfileEXt_SimpleCSV() // MDA
	return ".csv"
end
function /s QANT_LoadNEXAFSfile_SimpleCSV(pathn) // MDA
	string pathn
	variable fileref
	open/r/F="NEXAFS files (*.csv,):.csv;" fileref as pathn
	string fullpath = s_filename
	FStatus fileref
	if(V_flag==0)
		return ""
	endif
	
	string scanname = ParseFilePath(3, fullpath, ":", 1, 0)
	string foldersave = getdatafolder(1)
	
	setdatafolder root:
	newdatafolder /O/S NEXAFS

	wave /T QANT_LUT
	newdatafolder /O/S Scans
	newdatafolder /O/S $cleanupname(scanname,1)

	killwaves /Z/A
	string /g filename = fullpath
	getfilefolderinfo /p=NEXAFSPath /q/z scanname+".csv"
	string /g filesize
	sprintf filesize, "%d" ,v_logEOF
	string /g cdate
	sprintf cdate, "%d" ,v_creationdate
	string /g mdate
	sprintf mdate, "%d" ,v_modificationdate
	string /g acqtime = SECS2date(v_creationdate,1) +"  "+ SECS2Time(v_creationdate,1)
	
	string /g notes
	if(strlen(notes)*0!=0)
		notes = ""
	endif
	string /g anglestr
	if(strlen(anglestr)*0!=0)
		anglestr = ""
	endif
	string /g otherstr
	if(strlen(otherstr)*0!=0)
		otherstr = ""
	endif
	string /g SampleName
	if(strlen(SampleName)*0!=0)
		SampleName = ""
	endif
	string /g SampleSet
	if(strlen(SampleSet)*0!=0)
		SampleSet = ""
	endif
	string /g refscan
	if(strlen(refscan)*0!=0)
		refscan = "Default"
	endif
	string /g darkscan
	if(strlen(darkscan)*0!=0)
		darkscan = "Default"
	endif
	string /g enoffset
	if(strlen(enoffset)*0!=0)
		enoffset = "Default"
	endif
	close fileref
	loadwave /W/J/K=0/L={0,0,0,0,0}/N/O/Q filename
	
	Make/ n=(itemsinlist(S_waveNames)) /T ColumnNames = stringfromlist(p,S_waveNames)
		
	setdatafolder foldersave
	print "Loaded NEXAFS file : " + cleanupname(scanname,1)
	return 	cleanupname(scanname,1)
end

function QANT_PLOTPARAM(paramname)
	//QANT_CalcNormalizations("all")
	string paramname
	string foldersave = getdatafolder(1)
	setdatafolder root:NEXAFS:
	wave/t Scans = scanlist
	variable i
	make/o /n=(dimsize(Scans,0)) param
	for(i=0;i<dimsize(Scans,0);i+=1)
		setdatafolder root:NEXAFS:Scans:
		setdatafolder Scans[i][0]
		//string /g enoffset = "0"
		wave /t extrainfo
		findvalue /text=paramname extrainfo
		if(v_value>=0)
			param[i] = str2num(extrainfo[mod(v_value,dimsize(extrainfo,0))][2])
		else
			param[i]=nan
		endif
	endfor
	display param
	setdatafolder foldersave
	QANT_listNEXAFSscans()
end

Function QANT_saveExperiment_but(ba) : ButtonControl
	STRUCT WMButtonAction &ba

	switch( ba.eventCode )
		case 2: // mouse up
			saveexperiment
			break
		case -1: // control being killed
			break
	endswitch

	return 0
End




function /wave calcdelta(betawave, enwave,chemformula,density)
	// the output of this function is a wave the same length and over the same energy scale of f2, which will discribe
	// the real part of the index of refraction, calculated by extending the spectrum to span 10 and 30000 eV
	// with bare atom absorption calculations
	
	// during the calculation, however, f1 and f2, delta and beta will all be calculated and stored over the range 0-30000 eV
	// the calculation will also create subdirectories for scaled beta (pre edge and post edge scaled to the molecular scattering levels) and delta
	wave betawave // datawave of absorption (this will be scaled, so absolute scale doesn't matter
	wave enwave // X-ray energy wave the same length as f2, which will be used as the basis for f1
	string chemformula // standard chemical formula, this will be used to calculate the bare atom spectrum
	variable density // single number which will be used to calculate the bare atom spectrum
	if(!datafolderexists("root:AtomicScatteringFactors"))
		loadelementlibrary()
	endif
	wave bareatommu = GetBareAtomMu(chemformula) // creates and links to a wave in the nexafs/bateatomapectra direectory
	wave FullRangeF2 = SpliceintoF2(bareatommu, betawave, enwave) // creates new directory in NEXAFS/spliced/ that has the same scan name as the beta wave, with the same name as the beta wave
	wave FullRangeF1 = f1wavefromf2(FullRangeF2, density) // the energy wave is in the x scaling of the wave, so no need to keep that
	//display /k=1 FullRangeF2 /TN=f2, FullRangeF1 /TN=f1
	//modifygraph log(bottom)=1, lsize=2
	//modifygraph rgb(F1)=(0,0,50000)
	//Legend/C/N=text0/A=RT
	duplicate /free FullRangeF1, FullRangeEnergy
	Fullrangeenergy=x
	wave FullRangeBeta = F2toBeta(FullRangeF2, FullRangeEnergy, density)
	wave FullRangeDelta = F1toDelta(FullRangeF1, FullRangeEnergy, density)
	wave ScaledBeta = EnRangeBeta(FullRangeBeta, FullRangeEnergy, enwave)
	wave ScaledDelta = EnRangeDelta(FullRangeDelta, FullRangeEnergy, enwave)
	display /k=1 ScaledBeta /TN=beta, ScaledDelta /TN=delta vs enwave
	modifygraph lsize=2, log(bottom)=1
	modifygraph rgb(beta)=(0,0,50000)
	Legend/C/N=text0/A=RT
	return ScaledDelta
end

function /wave GetBareAtomMu(chemformula) // calculate the molecular absorption coefficient for the given chemical formula (the bare-atom spectra)
	string chemformula
	if(strlen(ChemFormula)<2)
		print "Error with Formula, please ensure formula is the usual ElementSymbolNumberElementSymbolNumber... format"
		wave/z null
		return null
	endif
	string foldersave = getdatafolder(1)
	setdatafolder root:
	newdatafolder /o/s NEXAFS
	newdatafolder /o/s BareAtomSpectra
	newdatafolder /o/s $ChemFormula
	wave /z BareAtomMu
	if(waveexists(BareAtomMu))
		// we have already created this formula, so we will just return the already calculated spectra
		setdatafolder foldersave
		return BareatomMu
	endif
	make /o/n=(2^20) BareAtomMu=0,BareAtomF2=0, lambda
	string workingchemformula = chemformula
	string element // name of the given element
	string NumberAtoms // number of atoms of a given element in the molecule
	string foldersave2 = getdatafolder(1)
	variable/g zstar=0 // relativity corrected atomic number (for molecule)
	variable/g MolWeight // molecular weight (for molecule)
	setdatafolder root:AtomicScatteringFactors
	wave /t Names // loaded elements
	wave AtomicWeights // loaded atomic weights
	wave AtomicNumber // loaded atomic numbers
	wave energy // Full energy scale (2^20 points)
	variable totalatoms
	variable numatoms
	variable numcarbons=0
	do
		splitstring /e="^([[:alpha:]]*)\\s?([[:digit:].]*)\\s?(.*)$" workingchemformula, element, numberatoms, workingchemformula // find and remove the first element and number of atoms from the chemical formula
		if(!datafolderexists(element))
			print "Element is not in Library, please update library or chemical formula to continue"
			return BareAtomMu
		endif
		setdatafolder $element // open the data folder corresponding to this element
		wave f2interp // this is the loaded f2 interpolated onto the full energy scale (2^20 points) (unitless)
		findvalue /text=element Names // find the element in the list of loaded elements (it should be there, because the folder exists)
		numatoms = str2num(numberatoms)
		if(stringmatch(element,"C"))
			numcarbons += numatoms
		endif
		BareAtomF2 += numatoms * f2interp // add in the effective F2s from these atoms
		MolWeight +=numatoms * AtomicWeights[v_value]  // add the weights of these atoms to the total molecular weight
		zStar+=numatoms * (AtomicNumber[v_value]-((AtomicNumber[v_value])/82.5)^2.37) // add the relativistic atomic numbers of these atoms to the effective molecular atomic number
		totalatoms += numatoms
		setdatafolder root:AtomicScatteringFactors
	while(strlen(workingchemformula)>1)
	//zstar /= totalatoms*5
	Variable Na=6.0221415e23 //Avogadro's number [at/mol]
	Variable re=2.81794e-13 //classical electron radius [cm]
	lambda=1.23984e-4/energy //wavelength [cm]
	BareAtomMu = 2 * re * lambda * Na * BareAtomF2 / MolWeight //calculation of mu [cm^2/g]  (From Brian Collins)
					// cm * cm * At/mol * /g/mol
	note /k BareatomMu ("\rBare Atomic Mu calculated by Henke data and ;ChemicalFormula:"+ChemFormula+";MolecularWeight:"+num2str(MolWeight)+";Zstar:"+num2str(zStar)+";NumCarbons:"+num2str(numcarbons)+";")
	setscale /i x,10,30000,"eV",  BareAtomMu, BareAtomF2
	setdatafolder foldersave
	return BareAtomMu
end

function /wave SpliceintoF2(BareAtomMu, BetaWave, EnWave)
	wave BareAtomMu, BetaWave, EnWave
	string nameofscan = getwavesdatafolder(betawave,0)
	string nameofchannel = nameofwave(betawave)
	string foldersave = getdatafolder(1)
	redimension/D BareAtomMu, BetaWave, EnWave
	setdatafolder root:NEXAFS
	newdatafolder /o/s SplicedMu
	newdatafolder /o/s $nameofscan
	if(waveexists($nameofchannel))
		// we have already done this calculation, do don't repeat it
		wave outputMu = $nameofchannel
	else
		make /free/n=(2^20) spliceddata
		setscale /i x,10,30000,"eV",  spliceddata
	
	//This section Scales the data to the bare atom spectra
	// use the graph cursors if they are available
		variable CuA=hcsr(A,"QANT_Plot")
		variable CuB=hcsr(B,"QANT_Plot")
		variable CuC=hcsr(C,"QANT_Plot")
		variable CuD=hcsr(D,"QANT_Plot")
		variable bareoffset,dataoffset,barescale,datascale,preedgeoffset,postedgeoffset
	
		variable cursortest = CuA*CuB*CuC*CuD
		if(cursortest *0==0)
			variable numpre=abs(binarysearch(Enwave,CuB)-binarysearch(Enwave,CuA))
			variable numpost=abs(binarysearch(Enwave,CuD)-binarysearch(Enwave,CuC))
			
			preedgeoffset = min(binarysearch(Enwave,CuB),binarysearch(Enwave,CuA))
			postedgeoffset = max(binarysearch(Enwave,CuD),binarysearch(Enwave,CuC))
			
			make /free/d/o/n=(numpre+numpost) enfitwave, bareatomfitwave, datafitwave
			enfitwave[0,numpre-1]=enwave[min(binarysearch(Enwave,CuB),binarysearch(Enwave,CuA)) + p]
			enfitwave[numpre,numpre+numpost-1]=enwave[min(binarysearch(Enwave,CuD),binarysearch(Enwave,CuC)) + p - numpre]
			datafitwave[0,numpre-1]=Betawave[min(binarysearch(Enwave,CuB),binarysearch(Enwave,CuA)) + p]
			datafitwave[numpre,numpre+numpost-1]=BetaWave[min(binarysearch(Enwave,CuD),binarysearch(Enwave,CuC)) + p - numpre]
			wave energy = root:AtomicScatteringFactors:energy
			bareatomfitwave = interp(enfitwave,energy,BareAtomMu)
			bareoffset = mean(bareatomfitwave,0,numpre-1)
			dataoffset = mean(datafitwave,0,numpre-1)
			bareatomfitwave -=bareoffset	
			datafitwave -= dataoffset
			barescale = mean(bareatomfitwave,numpre,numpre+numpost-1)
			datascale = mean(datafitwave,numpre,numpre+numpost-1)
		else
			make /free/d/o/n=20 enfitwave, bareatomfitwave, datafitwave
			preedgeoffset = binarysearch(enwave,280)
			postedgeoffset = binarysearch(enwave,315)
			enfitwave[0,9] = enwave[p+preedgeoffset] // the first 10 points(skipping the 5 points, which is probably bad)
			datafitwave[0,9] = Betawave[p+preedgeoffset] // the first 10 points of Beta wave
			enfitwave[10,19] = enwave[p-31+dimsize(enwave,0)] // the last 10 points of Betawave
			datafitwave[10,19] = Betawave[p-31+dimsize(Betawave,0)] // the last 10 points of Betawave
			wave energy = root:AtomicScatteringFactors:energy
			bareatomfitwave = interp(enfitwave,energy,BareAtomMu)
			bareoffset = mean(bareatomfitwave,0,9)
			dataoffset = mean(datafitwave,0,9)
			bareatomfitwave -=bareoffset	
			datafitwave -= dataoffset
			barescale = mean(bareatomfitwave,10,19)
			datascale = mean(datafitwave,10,19)
		endif
		duplicate /free betawave, scaledbeta
		scaledbeta = ((betawave-dataoffset)/datascale) * barescale + bareoffset // scales the data to the bare atom spectra
	
	// This section splices the data into the bare atom spectra
		variable lowercutoffindex = binarysearch(energy,enwave[preedgeoffset])
		variable uppercutoffindex = binarysearch(energy,enwave[postedgeoffset])//dimsize(enwave,0)-121]) // changed from 21 to 11
		duplicate /o energy, theoryvsexperiment
		theoryvsexperiment[0,lowercutoffindex]=0 
		theoryvsexperiment[lowercutoffindex,uppercutoffindex]=1
		theoryvsexperiment[uppercutoffindex,2^20-1]=0
		smooth /b=5 /F 100,theoryvsexperiment
		spliceddata[0,lowercutoffindex-100] =  BareAtomMu
		spliceddata[lowercutoffindex-100,uppercutoffindex+100] =(1-theoryvsexperiment)*BareAtomMu + theoryvsexperiment * interp(energy[p],enwave,scaledbeta)
		spliceddata[uppercutoffindex+100,2^20-1] =  BareAtomMu
	
	// we want to interpolate the data all the way to 0 to 30000, with 2^20 points (easy to FFT)
		make/D/O/N=(2^20) Ev // the output energy
		setscale /i x, 0, 30000, "eV",  Ev
		Ev=x
	
	// interpolate the data (in spliced data, energy in enwave) onto the output energy wave
		duplicate /free energy, energywave
		InsertPoints 0,2, EnergyWave
		EnergyWave[0]=0
		EnergyWave[1]=10-1e-10
		InsertPoints 0,2, spliceddata 
		Interpolate2/T=1/N=2000/I=3/Y=$nameofchannel /X=Ev EnergyWave, spliceddata
		wave outputMu =$nameofchannel
		note /k outputMu, note(BareAtomMu) +";"+ note(betawave) // append the wavenote from Mu calculation (including zstar and molecular weight) and whatever data was in the original data wave
		setscale /i x, 0, 30000, "eV",  outputMu
	endif
	// convert mu to f2 for the fft
	
	
	setdatafolder root:NEXAFS
	newdatafolder /o/s ExtendedF2
	newdatafolder /o/s $nameofscan
	if(waveexists($nameofchannel))
		// we have already done this calculation, do don't repeat it
		wave F2 = $nameofchannel
		return F2
	endif
	Variable Na=6.0221415e23 //Avogadro's number [at/d.mol]
	Variable re=2.81794e-13 //classical electron radius [cm]
	Variable Mw=NumberByKey("MolecularWeight",Note(BareAtomMu))
	Variable zstar=NumberByKey("Zstar",Note(BareAtomMu))
	make /d/n=(2^20)/free lambda
	make /o/d/n=(2^20) $nameofchannel
	wave f2 = $nameofchannel
	note /k f2, note(outputMu) + "\rf2 spectra spliced into bare atom f2 between "+num2str(energy[lowercutoffindex])+ " eV and "+num2str(energy[uppercutoffindex])+ " eV"
	setscale/i x, 0,30000,"eV",lambda, f2
	lambda=1.23984e-4/x // wavelength [cm]
	f2 = Mw*outputMu[p]/(2*re*lambda[p]*Na) 
	f2[0]=0
	setdatafolder foldersave
	return F2
end



function /wave f1wavefromf2(F2, density) // algorithm from Hongping Yan
	wave F2
	variable density
	Variable zstar=NumberByKey("Zstar",Note(F2))
	
	
	// make a folder for the resulting extended F1
	setdatafolder root:NEXAFS
	newdatafolder /o/s ExtendedF1
	newdatafolder /o/s $getwavesdatafolder(F2,0)
	if(waveexists($nameofwave(F2)))
		// we have already done this calculation, do don't repeat it
		return $nameofwave(F2)
	endif
	
	
	duplicate /free f2, cf2 // make a complex version of f2 for the calculation
	//redimension /c cf2
	// first fft f2
	//FFT  /PAD={(2^21)} /DEST=tempf2intpFFT cf2  // removed /out=1
	redimension /c/n=(2^21) CF2
	//redimension /c cf2
	matrixop/free/o/C/S tempf2intpFFT = fft(cf2,0)
	duplicate/free tempf2intpFFT tempf2intpFFTimag
	redimension/R tempf2intpFFTimag
	// take the imaginary component, set the padded values to -1
	tempf2intpFFTimag=imag(tempf2intpFFT)
	//killwaves tempf2intpFFT
	tempf2intpFFTimag[(2^20), (2^21)-1]*=-1
	redimension/C tempf2intpFFTimag
	// inverse fft the imaginary component
	//IFFT/DEST=$nameofwave(F2) tempf2intpFFTimag
	matrixop/o/C/S $nameofwave(F2) = ifft(tempf2intpFFTimag,0)
	wave tempf2intpIFFT = $nameofwave(F2)
	Redimension/R tempf2intpIFFT
	//remove the extra padded component
	DeletePoints (2^20),(2^20), tempf2intpIFFT
	setscale /i x, 0, 30000, "eV",  tempf2intpIFFT
	tempf2intpIFFT=tempf2intpIFFT*2+zstar
	note /k tempf2intpIFFT, note(F2) + "\rConverted from f2 to f1 by Kramers Kronig relation and z*=" + num2str(zstar)
	return tempf2intpIFFT
end


function /wave F2toBeta(fwave, enwave, density)
	wave fwave, enwave
	variable density
	Variable Na=6.0221415e23 //Avogadro's number [at/mol]
	Variable re=2.81794e-13 //classical electron radius [cm]
	Variable Mw=NumberByKey("MolecularWeight",Note(fwave))
	
	duplicate /free enwave, lambda
	lambda=1.23984e-4/enwave //wavelength [cm]
	lambda[0]=99999
	setdatafolder root:NEXAFS
	newdatafolder /o/s ExtendedBeta
	newdatafolder /o/s $getwavesdatafolder(fwave,0)
	duplicate /o fwave,$nameofwave(fwave) // put this is the right folder and name it depending on if we are converting F2 or F1
	wave fullrangeBeta = $nameofwave(fwave)
	note /k fullrangeBeta, note(fwave) + "\rConverted from F2 to Beta with Molecular Weight = " + num2str(MW) + " g/mol and density = " + num2str(density) + " g/ml"
	fullrangeBeta= re*lambda^2*density*Na/(2*pi*Mw) * fwave
	return fullrangeBeta
end

function /wave F1toDelta(fwave, enwave, density)
	wave fwave, enwave
	variable density
	Variable Na=6.0221415e23 //Avogadro's number [at/mol]
	Variable re=2.81794e-13 //classical electron radius [cm]
	Variable Mw=NumberByKey("MolecularWeight",Note(fwave))
	
	duplicate /free enwave, lambda
	lambda=1.23984e-4/enwave //wavelength [cm]
	lambda[0]=99999
	setdatafolder root:NEXAFS
	newdatafolder /o/s ExtendedDelta
	newdatafolder /o/s $getwavesdatafolder(fwave,0)
	duplicate /o fwave,$nameofwave(fwave) // put this is the right folder and name it depending on if we are converting F2 or F1
	wave fullrangeDelta = $nameofwave(fwave)
	note /k fullrangeDelta, note(fwave) + "\rConverted from f1 to delta with Molecular Weight = "+ num2str(MW) + " g/mol and density = " + num2str(density) + " g/ml"
	fullrangeDelta= re*lambda^2*density*Na/(2*pi*Mw) * fwave
	return fullrangeDelta
end

function /wave EnRangeBeta(FullRangeBeta, FullRangeEnergy, enwave)
	wave FullRangeBeta, FullRangeEnergy, enwave
	setdatafolder root:NEXAFS
	newdatafolder /o/s ScaledBeta
	newdatafolder /o/s $getwavesdatafolder(FullRangeBeta,0)
	duplicate /o enwave,$nameofwave(FullRangeBeta) // put this is the right folder and name it depending on if we are converting F2 or F1
	duplicate /o enwave,$nameofwave(enwave)
	wave enrangeBeta = $nameofwave(FullRangeBeta)
	enrangebeta = interp(enwave, FullRangeEnergy, FullRangeBeta)
	note /k enrangebeta, note(FullRangeBeta) + "\rInterpolated back to original energy range"
	return enrangebeta
end

function /wave EnRangeDelta(FullRangeDelta, FullRangeEnergy, enwave)
	wave FullRangeDelta, FullRangeEnergy, enwave
	setdatafolder root:NEXAFS
	newdatafolder /o/s ScaledDelta
	newdatafolder /o/s $getwavesdatafolder(FullRangeDelta,0)
	duplicate /o enwave,$nameofwave(FullRangeDelta) // put this is the right folder and name it depending on if we are converting F2 or F1
	duplicate /o enwave,$nameofwave(enwave)
	wave enrangeDelta = $nameofwave(FullRangeDelta)
	enrangeDelta = interp(enwave, FullRangeEnergy, FullRangeDelta)
	note /k enrangedelta, note(FullRangeDelta) + "\rInterpolated back to original energy range"
	return enrangeDelta
end
function Init_QANT_AdvPanel()
	PauseUpdate; Silent 1		// building window...
	dowindow /k QANT_AdvPanel
	NewPanel /K=1 /W=(795,70,1171,252) /n=QANT_AdvPanel as "AU NEXAFS Advanced Options"
	ModifyPanel fixedSize=1
	SetDrawLayer UserBack
	SetDrawEnv fsize= 10
	DrawText 26,47,"Specify in the \"Notes\" as \"ChemForm:AaXBbY\" and \"Density:X\""
	SetDrawEnv fsize= 10
	DrawText 26,61,"Note: Optical Constants will be plotted - cursor scaling will no longer work"
	CheckBox QANT_Norm2Mu_chk,pos={8,7},size={272,26},proc=QANT_AdvPanel_CheckProc,title="Do Kramers-Kronig and Norm data to Mass Absorption\r(needs Chemical Formula and density)"
	CheckBox QANT_Norm2Mu_chk,variable= root:NEXAFS:calcKK
	CheckBox QANT_DispStitched_chk,pos={33,71},size={229,14},proc=QANT_AdvPanel_CheckProc,title="Display Stitched Optical Constants (0-30keV)"
	CheckBox QANT_DispStitched_chk,variable= root:NEXAFS:DispStitched
	CheckBox QANT_DispDelta_chk,pos={33,89},size={80,14},proc=QANT_AdvPanel_CheckProc,title="Display Delta"
	CheckBox QANT_DispDelta_chk,variable= root:NEXAFS:DispDelta
	CheckBox QANT_CorrectPhotodiode_chk,pos={8,113},size={216,14},proc=QANT_AdvPanel_CheckProc,title="Correct Spectra for Photodiode Responce"
	CheckBox QANT_CorrectPhotodiode_chk,variable= root:NEXAFS:correctphotodiode
	CheckBox QANT_LinearBackground_chk,pos={8,136},size={215,14},proc=QANT_AdvPanel_CheckProc,title="Use Functional Pre Edge rather than Constant (Disable debugger if using Igor6)"
	CheckBox QANT_LinearBackground_chk,variable= root:NEXAFS:LinearPreEdge
	CheckBox QANT_ExpBackground_chk,pos={33,159},size={228,14},proc=QANT_AdvPanel_CheckProc,title="Use Exponential Pre Edge (check) rather than Linear (unchecked)"
	CheckBox QANT_ExpBackground_chk,variable= root:NEXAFS:ExpPreEdge
	nvar LinearPreEdge = root:NEXAFS:LinearPreEdge
	if(LinearPreEdge)
		CheckBox QANT_ExpBackground_chk disable=0
	else
		CheckBox QANT_ExpBackground_chk disable=2
	endif
	
EndMacro

Function QANT_AdvPanel_CheckProc(cba) : CheckBoxControl
	STRUCT WMCheckboxAction &cba

	switch( cba.eventCode )
		case 2: // mouse up
			
			
			
			nvar calcKK= root:NEXAFS:calcKK
			nvar DispStitched= root:NEXAFS:DispStitched
			nvar DispDelta= root:NEXAFS:DispDelta
			if(!calcKK)
				dowindow /k QANT_plot
				dowindow /k QANT_Contrast
				dowindow /k QANT_deltabeta
				
				killdatafolder /Z root:NEXAFS:splicedMu
				killdatafolder /Z root:NEXAFS:ExtendedF2
				killdatafolder /Z root:NEXAFS:ExtendedF1
				killdatafolder /Z root:NEXAFS:ExtendedBeta
				killdatafolder /Z root:NEXAFS:ExtendedDelta
				killdatafolder /Z root:NEXAFS:ScaledBeta
				killdatafolder /Z root:NEXAFS:ScaledDelta
				DispStitched=0
				DispDelta=0
			endif
			nvar LinearPreEdge = root:NEXAFS:LinearPreEdge
			nvar ExpPreEdge = root:NEXAFS:ExpPreEdge
			if(LinearPreEdge)
				CheckBox QANT_ExpBackground_chk disable=0
			else
				CheckBox QANT_ExpBackground_chk disable=2
			endif
			QANT_CalcNormalizations("selected")
			QANT_replotdata(ontop=0)

			
			
			dowindow /F QANT_AdvPanel
			
			
			
			
			break
		case -1: // control being killed
			break
	endswitch

	return 0
End


Function QANT_X_axis_pop(pa) : PopupMenuControl
	STRUCT WMPopupAction &pa

	switch( pa.eventCode )
		case 2: // mouse up
			Variable popNum = pa.popNum
			String popStr = pa.popStr
			variable modenum = whichlistitem(popStr,QANT_channellistxaxis())+1
			PopupMenu QANT_popup_X_xais win=QANTLoaderPanel,mode=modenum
			PopupMenu QANT_popup_X_xais win=QANTLoaderPanel, fSize=12,fstyle=0,fColor=(0,0,0)
			svar X_axis = root:NEXAFS:x_axis
			X_axis = popstr
			QANT_cleanupXAxis()
			QANT_listNEXAFSscans()
			QANT_CalcNormalizations("selected")
			break
		case -1: // control being killed
			break
	endswitch

	return 0
End

Function QANT_AngSet(sva) : SetVariableControl
	STRUCT WMSetVariableAction &sva

	switch( sva.eventCode )
		case 1: // mouse up
		case 2: // Enter key
		case 3: // Live update
			Variable dval = sva.dval,i
			String sval = sva.sval
			string foldersave = getdatafolder(1)
			setdatafolder root:NEXAFS
			wave selwave = root:NEXAFS:selwavescanlist
			duplicate /free selwave, selwavescanlist
			selwavescanlist =selwave? 1 : 0
			wave /t scanlist
			setdatafolder scans
			variable numericalvalue = str2num(sval)
			string cleanedstring
			if(numericalvalue*0==0)
				setvariable QANT_strval_scanAngle win=QANTLoaderPanel,value=_NUM:numericalvalue
				cleanedstring = num2str(numericalvalue)
			else
				setvariable QANT_strval_scanAngle win=QANTLoaderPanel,value=_STR:""
				cleanedstring = ""
			endif
			// popup warning if multiple scans are selected
			if(sum(selwavescanlist)>1)
				doalert /t="Warning" 1, "The changes you have made will apply to multiple scans! Continue?"
				if(v_flag==2)
					break
				endif
			endif
			for(i=0;i<sum(selwavescanlist);i+=1)
				if(i==0)
					findvalue /v=1 /T=.1 /z selwavescanlist
				else
					findvalue /s=(v_value+1) /v=1 /T=.1 /z selwavescanlist
				endif
				setdatafolder $scanlist[v_value][0]
				svar Anglestr
				Anglestr = cleanedstring
				setdatafolder ::
			endfor
			setdatafolder foldersave
			QANT_listNEXAFSscans()
			listbox QANT_listbox_loadedfiles activate
			break
		case -1: // control being killed
			break
	endswitch

	return 0
End

Function QANT_OtherSet(sva) : SetVariableControl
	STRUCT WMSetVariableAction &sva

	switch( sva.eventCode )
		case 1: // mouse up
		case 2: // Enter key
		case 3: // Live update
			Variable dval = sva.dval,i
			String sval = sva.sval
			string foldersave = getdatafolder(1)
			setdatafolder root:NEXAFS
			wave selwave = root:NEXAFS:selwavescanlist
			duplicate /free selwave, selwavescanlist
			selwavescanlist =selwave? 1 : 0
			wave /t scanlist
			setdatafolder scans
			variable numericalvalue = str2num(sval)
			string cleanedstring
			if(numericalvalue*0==0 && strlen(sval) <= strlen(num2str(numericalvalue)))
				setvariable QANT_strval_ScanOther win=QANTLoaderPanel,value=_NUM:numericalvalue
				cleanedstring = num2str(numericalvalue)
			else
				cleanedstring = sval
				setvariable QANT_strval_ScanOther win=QANTLoaderPanel,value=_STR:cleanedstring
				
			endif
			// popup warning if multiple scans are selected
			if(sum(selwavescanlist)>1)
				doalert /t="Warning" 1, "The changes you have made will apply to multiple scans! Continue?"
				if(v_flag==2)
					break
				endif
			endif
			for(i=0;i<sum(selwavescanlist);i+=1)
				if(i==0)
					findvalue /v=1 /T=.1 /z selwavescanlist
				else
					findvalue /s=(v_value+1) /v=1 /T=.1 /z selwavescanlist
				endif
				setdatafolder $scanlist[v_value][0]
				svar/z otherstr
				if(!svar_exists(otherstr))
					string/g otherstr
				endif
				otherstr = cleanedstring
				setdatafolder ::
			endfor
			setdatafolder foldersave
			QANT_listNEXAFSscans()
			listbox QANT_listbox_loadedfiles activate
			break
		case -1: // control being killed
			break
	endswitch

	return 0
End


Function QANT_FitMaterials(ba) : ButtonControl
	STRUCT WMButtonAction &ba

	switch( ba.eventCode )
		case 2: // mouse up
			loadelementlibrary()
			string foldersave = getdatafolder(1)
			setdatafolder root:NEXAFS
			nvar MatFittingXMax, MatFittingXMin
			if(nvar_exists(MatFittingXMax) && nvar_exists(MatFittingXMin))
				if(MatFittingXMax<=MatFittingXMin)
					MatFittingxmax=inf
					matFittingXMin=-inf
				endif
			else
				variable /g MatFittingxmax=inf
				variable /g MatFittingxmin=-inf
			endif
			wave selwave = root:NEXAFS:selwavescanlist
			duplicate /free selwave, selwavescanlist
			selwavescanlist =selwave? 1 : 0
			wave channelSel, materialstofitlistsel
			wave/T scanlist, materialslist, channels, materialstofitlist
			// get x and y waves for the materials
			variable j,k
			if(dimsize(materialstofitlist,0)<1)
				doalert /T="Materials Fit with less than one component is impossible" 0, "Please Choose at least one material to fit"
				return 0
			endif
			make /free/o/wave/n=(dimsize(materialstofitlist,0)) refxwaves, refywaves
			make /free/n=(dimsize(materialstofitlist,0)) RefMolWeights=nan, RefNumCarbons=nan, RefDensities=nan 
			svar x_axis,normchan,darkscan
			make /free/t/n=(dimsize(materialslist,0)) materialsnames = materialslist[p][0]
			if(datafolderexists("Normalizeddata"))
				setdatafolder NormalizedData
			elseif(datafolderexists("RefCorrecteddata") && cmpstr(normchan,"none"))
				setdatafolder RefCorrectedData
			elseif(datafolderexists("DarkCorrected"))
				setdatafolder DarkCorrected
			else
				setdatafolder scans
			endif
			k=0
			string datafoldertouse = getdatafolder(1)
			variable refmin, refmax
			string namesOfMaterials = "", Chemformula, densitystr
			struct decompfitstruct s
			make /free /t /n=(dimsize(refxwaves,0)) ChemForms
			for(j=0;j<dimsize(refxwaves,0);j+=1)
				findvalue /text=materialstofitlist[j] materialsnames
				namesOfMaterials += materialstofitlist[j] + "_"
				if(v_value<0)
					print "Warning! the material \"" + materialstofitlist[j] + "\" was not found and will not be used in this fit" 
					continue
				endif
				setdatafolder datafoldertouse
				setdatafolder materialslist[v_value][1]
				refxwaves[k] = $x_axis
				refywaves[k] = $materialslist[v_value][2]
				//get chemical formula and density for later
				svar/z notes = root:NEXAFS:Scans:$materialslist[v_value][1]:notes
				if(svar_exists(notes))
					splitstring /e="ChemForm:([[:alpha:][:digit:].]*)" notes, Chemformula
					ChemForms[j]=Chemformula
					if(strlen(Chemformula)>1)
						wave atomicmu = GetBareAtomMu(Chemformula)
						if(waveexists(atomicmu))
							RefMolWeights[k] = numberbykey("MolecularWeight",note(atomicmu),":",";")
							RefNumCarbons[k] = numberbykey("NumCarbons",note(atomicmu),":",";")
						endif
					endif
					splitstring /e="Density:([[:digit:].]*)" notes, densitystr
					if(strlen(densitystr)>0)
						refDensities[k] = str2num(densitystr)
					endif
				endif
				// if no value is found, it will be nan
				setdatafolder datafoldertouse
				if(!waveexists(refxwaves[k]) || !waveexists(refywaves[k]))
					print "Warning! the raw scans for material \"" + materialstofitlist[j] + "\" was not found and will not be used in this fit" 
					continue
				endif
				if(k==0)
					refmin = wavemin(refxwaves[k])
					refmax = wavemax(refxwaves[k])
				else
					refmin = max(wavemin(refxwaves[k]), refmin)
					refmax = min(wavemax(refxwaves[k]), refmax)
				endif
				k+=1
			endfor
			s.numrefwaves = k
			redimension /n=(s.numrefwaves) refxwaves, refywaves, RefMolWeights, RefNumCarbons, refDensities
			// get x and y waves for the waves to fit
			// Use the top graph, as usual // note that this means that any user produced window can be used, not just QANT windows
			string winstr = winname(0,1)
			string tracesstr = tracenamelist(winstr,";",1+4)
			string tracename
			//set number of datasets to the number of traces on the graph
			variable numdatasets = itemsinlist(tracesstr,";")
			// but we're only fitting a single trace at a time, so for the structure, we set the number to 1
			s.numberofdatasets =1
			
			make /o/wave/n=(numdatasets) fitxwaves, fitywaves
			k=0
			variable minloc, maxloc, len
			setdatafolder root:NEXAFS
			newdatafolder /o/s Materials_Fitting
			newdatafolder /o/s $uniquename(cleanupname(namesofMaterials,0),11,0)
			make /o/t /n=(8*s.numrefwaves+1,numdatasets+1) dataout
			dataout[0][0] = "DataSet"
			for(j=0;j<s.numrefwaves;j+=1)
				dataout[2*j+1][0] = "Raw Spectral Composition of "+ materialstofitlist[j]
				dataout[2*j+2][0] = "Error for "+ materialstofitlist[j]
			endfor
			for(j=0;j<s.numrefwaves;j+=1)
				dataout[2*s.numrefwaves+2*j+1][0] = "Normalized Spectral Composition of "+ materialstofitlist[j]
				dataout[2*s.numrefwaves+2*j+2][0] = "Error for "+ materialstofitlist[j]
			endfor
			for(j=0;j<s.numrefwaves;j+=1)
				dataout[4*s.numrefwaves+2*j+1][0] = "Weight Composition of "+ materialstofitlist[j]
				dataout[4*s.numrefwaves+2*j+2][0] = "Error for "+ materialstofitlist[j]
			endfor
			for(j=0;j<s.numrefwaves;j+=1)
				dataout[6*s.numrefwaves+2*j+1][0] = "Volume Composition of "+ materialstofitlist[j]
				dataout[6*s.numrefwaves+2*j+2][0] = "Error for "+ materialstofitlist[j]
			endfor
			variable goodsets = 0, results = 0, MolWeight, NumCarbons, Density
			variable totcomp, totcarbon, totweight, m
			string textforlabel
			for(j=0;j<numdatasets;j+=1)
				MolWeight=nan
				NumCarbons=nan
				Density=nan
				make /o/d /n=(s.numrefwaves) coefw =1
				wave s.coefw = coefw 
				make /o/d/t /n=(s.numrefwaves) constraints = "K"+num2str(p) + " > 0"
				duplicate/o s.coefw, ew
				ew=.0000000001
				tracename = stringfromlist(j,tracesstr)
				if(stringmatch(tracename,"*ref_*") || stringmatch(tracename,"*fit_*") || stringmatch(tracename,"*fitx_*"))
					continue
				endif
				wave ywave = tracenametowaveref(winstr,tracename)
				wave xwave = XWaveRefFromTrace(winstr,tracename)
				if(!waveexists(ywave) || !waveexists(xwave))
					print "Bad wave found in graph, skipping:" + tracename
					dataout[0][0] = tracename
					for(j=0;j<s.numrefwaves;j+=1)
						dataout[2*j+1][0] = "BAD"
						dataout[2*j+2][0] = "BAD"
					endfor
					results +=1
					continue
				endif
				maxloc = min(min(wavemax(xwave),refmax), MatFittingXMax)
				minloc = max(max(wavemin(xwave),refmin), MatFittingXMin)
				duplicate/o xwave, testwave
				testwave = xwave[p]<maxloc && xwave[p] > minloc ? 1 : 0
				len = sum(testwave) 
				s.lengthofdatasets = len
				if(len<3)
					Print "ERROR!  too little points found in "+tracename + ".  This wave will not be fit"
					dataout[0][0] = tracename
					for(j=0;j<s.numrefwaves;j+=1)
						dataout[2*j+1][0] = "Too few points"
						dataout[2*j+2][0] = "Too few points"
					endfor
					results +=1
					continue
				elseif(len < 20)
					print "WARNING!  the overlap between "+tracename+" and reference scans is very small, and may result in a bad fit"
				endif
				findvalue /v=1 /s=0 testwave
				make /o/n=(len) fitxwave = xwave[p+v_value]
				make /o/n=(len) fitywave = ywave[p+v_value], $cleanupname("fit_"+tracename,1)
				wave fitdestwave = $cleanupname("fit_"+tracename,1)
				make /d/o/n=(s.numrefwaves, len) s.dw
				for(k=0;k<s.numrefwaves;k+=1)
					wave refxwave = refxwaves[k]
					wave refywave = refywaves[k]
					s.dw[k][] = interp(fitxwave[q],refxwave,refywave)
				endfor
				funcfit /m=2  fitdecomp, coefw,  fitywave /strc=s /d=fitdestwave /e=ew /C=constraints
				wave w_sigma
				duplicate fitxwave, $cleanupname("fitx_"+tracename,1)
				totcomp=0
				for(k=0;k<s.numrefwaves;k+=1)
					totcomp += coefw[k]
				endfor
				duplicate /free coefw, normcoefw, weightcoef, volcoef
				duplicate /free w_sigma, normsigma, weightsigma, volsigma
				normcoefw /=  totcomp
				normsigma /= totcomp
				if(numtype(mean(RefMolWeights)*mean(RefNumCarbons))==0)
					// we can calculate the carbon composition and the molecular weight composition
					for(k=0;k<s.numrefwaves;k+=1)
						weightcoef[k]=refmolWeights[k]*coefw[k]
						for(m=0;m<s.numrefwaves;m+=1)
							weightcoef[k] *= m==k || RefNumCarbons[m]==0 ? 1 : RefNumCarbons[m]
						endfor
						if(refnumcarbons[k]==0)
							weightcoef[k]=0
						endif
					endfor
					totcomp = sum(weightcoef)
					weightcoef /= totcomp
					weightsigma = w_sigma * weightcoef / coefw
					setChemFormfromMaterials(ywave,chemforms,weightcoef,materialstofitlist)
					if(numtype(mean(refDensities))==0)
						//we can also calculate the volume percentage of components
						volcoef = weightcoef / refDensities
						totcomp = sum(volcoef)
						volcoef /= totcomp
						volsigma = w_sigma * volcoef / coefw
					else
						volcoef=nan
						volsigma=nan
					endif
				else
					weightcoef=nan
					weightsigma=nan
					volcoef=nan
					volsigma=nan
				endif
				
				//making a new window for each fit
				display /w=(0,300,500,600)/k=1 ywave /TN=$tracename vs xwave
				ModifyGraph lsize($tracename)=3
				ModifyGraph rgb($tracename)=(0,0,0)
				Legend/C/N=text0/F=0/B=1/J/A=RC/X=5.00/Y=0.00
				wave fitxwave = $cleanupname("fitx_"+tracename,1)
				wave fitywave = $cleanupname("fit_"+tracename,1)
				appendtograph fitywave /TN=Fit vs fitxwave
				modifygraph rgb(fit) = (65000,0,0), lsize(fit)=1.5
				colortab2wave Spectrum
				wave m_colors
				make/free /n=(dimsize(m_colors,0)) colorxwave, redwave = m_colors[p][0], greenwave = m_colors[p][1], bluewave = m_colors[p][2] 
				setscale /i x,0,s.numrefwaves*1.3, colorxwave, redwave, greenwave, bluewave 
				colorxwave = x
				make/free /n=(s.numrefwaves) rwave = interp(p,colorxwave, redwave), gwave =  interp(p,colorxwave, greenwave), bwave =  interp(p,colorxwave, bluewave)
	
				for(k=0;k<s.numrefwaves;k+=1)
					duplicate/o fitxwave, $("comp_"+materialstofitlist[k])
					wave comp = $("comp_"+materialstofitlist[k])
					comp = interp(fitxwave,refxwaves[k],refywaves[k]) * coefw[k]
					appendtograph /l=components comp /tn=$materialstofitlist[k] vs fitxwave
					modifygraph rgb($materialstofitlist[k]) = (rwave[k],bwave[k],gwave[k]), lsize($materialstofitlist[k])=1.5
					if(numtype(volcoef[k])==0)
						sprintf textforlabel, " vol%% = %2.1f +/- %2.1f",volcoef[k]*100, volsigma[k]*100
					elseif(numtype(weightcoef[k])==0)
						sprintf textforlabel, " weight%% = %2.1f +/- %2.1f",weightcoef[k]*100, weightsigma[k]*100
					else
						sprintf textforlabel, " spectral%% = %2.1f +/- %2.1f",normcoefw[k]*100, normsigma[k]*100
					endif
					AppendText/N=text0 /nocr textforlabel
				endfor
				ModifyGraph standoff(components)=0,axisEnab(left)={0.4,1}
				ModifyGraph axisEnab(components)={0,0.35},freePos(components)=0
				ModifyGraph tick=2,mirror=1,standoff=0
				ModifyGraph lblPosMode(components)=1;DelayUpdate
				Label left "Normalized Spectra";DelayUpdate
				Label bottom "X-ray Energy [eV]";DelayUpdate
				Label components "Components"
				dataout[0][j+1] = tracename
				for(k=0;k<s.numrefwaves;k+=1)
					dataout[2*k+1][j+1] = num2str(coefw[k])
					dataout[2*k+2][j+1] = num2str(w_sigma[k])
					dataout[2*s.numrefwaves+2*k+1][j+1] = num2str(normcoefw[k])
					dataout[2*s.numrefwaves+2*k+2][j+1] = num2str(normsigma[k])
					if(numtype(weightcoef[k])==0)
						dataout[4*s.numrefwaves+2*k+1][j+1] = num2str(weightcoef[k])
						dataout[4*s.numrefwaves+2*k+2][j+1] = num2str(weightsigma[k])
					else
						dataout[4*s.numrefwaves+2*k+1][j+1] = "Define Chemical Formulas"
						dataout[4*s.numrefwaves+2*k+2][j+1] = "N/A"
					endif
					if(numtype(volcoef[k])==0)
						dataout[6*s.numrefwaves+2*k+1][j+1] = num2str(volcoef[k])
						dataout[6*s.numrefwaves+2*k+2][j+1] = num2str(volsigma[k])
					else
						dataout[6*s.numrefwaves+2*k+1][j+1] = "Define Density and Chemical Formulas"
						dataout[6*s.numrefwaves+2*k+2][j+1] = "N/A"
					endif
				endfor
				results +=1
			endfor
			edit /k=1 dataout
			setdatafolder foldersave
			// click code here
			break
		case -1: // control being killed
			break
	endswitch

	return 0
End

function setChemFormfromMaterials(ywave,chemforms,weightcoef,materials)
	wave ywave, weightcoef
	wave/t chemforms, materials
	svar notes=root:NEXAFS:scans:$getwavesdatafolder(ywave,0):notes
	if(!svar_exists(notes))
		print "problem with notes"
		return 0
	endif
	make /n=0 /t /free elements
	make /n=0 /free weightednum
	variable j
	string chemform, element, natoms, concentrations="Concentrations:("
	for(j=0;j<dimsize(Chemforms,0);j+=1)
		chemform = chemforms[j]
		Concentrations += Materials[j]+":"+num2str(0.01 * round(weightcoef[j]*100))+","
		do
			splitstring /e="^([[:alpha:]]*)([[:digit:].]*)(.*)$" chemform, element, natoms, chemform
			if(strlen(element)==0 || strlen(natoms)==0)
				break
			endif
			findvalue /text=element /TXOP=4 elements
			if(v_value>=0)
				weightednum[v_value] += 0.01 * round(weightcoef[j]*100*str2num(natoms))
			else
				insertpoints dimsize(elements,0),1,elements, weightednum
				elements[dimsize(elements,0)-1] = element
				weightednum[dimsize(weightednum,0)-1]  += 0.01 * round(weightcoef[j]*100*str2num(natoms))
			endif
		while(1)
	endfor
	concentrations = removeending(concentrations,",") + ")"
	// assemble new ChemForm:... string and concentrations string
	string newChemform = "ChemForm:"
	for(j=0;j<dimsize(elements,0);j+=1)
		if(weightednum[j]>0)
			newchemform += elements[j]+num2str(weightednum[j])
		endif
	endfor
	//remove chemform from the note if it exists
	string oldchemform
	splitstring /e="(ChemForm:[[:alpha:][:digit:].]*)" notes, oldchemform
	notes = replacestring(oldchemform,notes,"")
	//remove ratio from note if it exists
	string oldconcentrations
	splitstring /e="(Concentrations:[(][^)]*[)])" notes, oldconcentrations
	notes = replacestring(oldconcentrations,notes,"")
	
	notes = removeending(notes," ")
	notes = removeending(notes," ")
	notes = removeending(notes," ")
	notes = removeending(notes," ")
	notes = removeending(notes," ")
	notes = removeending(notes," ")
	notes = removeending(notes," ")
	//add chemform to the note
	notes += " "+newchemform
	//add ratio to the note if it exists
	notes += " "+concentrations
	setvariable QANT_strval_notes win=QANTLoaderPanel,value=_STR:notes, disable=0,title=""
end


Function TagWindowHook(s)
// to set up, use the following command
//setwindow graph0, hook(taghook) = TagWindowHook // graph0 is the name of the graph you want to hook
	STRUCT WMWinHookStruct &s
	Switch(s.eventcode)
		case 4: // mousemove
			string foldersave = getdatafolder(1)
			variable mouseX = s.mouseloc.h
			variable mouseY = s.mouseloc.v
			string tracestr = TraceFromPixel(mouseX, mouseY,s.winname)
			//if(strlen(tracestr)>0 && s.eventmod==2)
				variable point = numberbykey("HITPOINT",tracestr)
				wave trace = TraceNameToWaveRef(s.winname, stringbykey("TRACE",tracestr))
				wave xwave = xwavereffromtrace(s.winname, stringbykey("TRACE",tracestr))
			if(waveexists(trace) && point>-1 && s.eventmod==2)
				Tag/w=$(s.winname) /TL={lThick=1.5,lineRGB=(3000,3000,3000)}/L=1/C/N=tag0/I=0/X=0/Y=10.00 $stringbykey("TRACE",tracestr), point, "\\Z08( \OX , \OY )"
			else
				Tag/w=$(s.winname) /K /N=Tag0
			endif
			break
		case 3:
			variable mouseX1 = s.mouseloc.h
			variable mouseY1 = s.mouseloc.v
			string tracestr1 = TraceFromPixel(mouseX1, mouseY1,"")
			if(strlen(tracestr1)>0 && s.eventmod==3) // shift key
				string tagname = uniquename("tag",14,0)
				string colorstr = stringbykey("RGB(x)",traceinfo(s.winname,stringbykey("TRACE",tracestr1),0),"=",";")
				variable red, blue, green
				sscanf colorstr, "(%d,%d,%d)",red,blue,green
				Tag/w=$(s.winname)/TL={fat=1,lThick=1.5,lineRGB=(red,blue,green)}/P=1/L=2/C/N=$tagname/I=0/X=0/Y=10.00 $stringbykey("TRACE",tracestr1), numberbykey("HITPOINT",tracestr1), "\\Z08( \OX , \OY )"
			endif
			break
	EndSwitch
	return 0
end


function /wave findpeaks(ywave,[dontplot])
	wave ywave
	variable dontplot
	killwaves /z w_coef
	wave/z w_coef
	RemoveFromGraph /z peaklocs
	make /free/o/n=(50,3) peaklocs=0//, peakvalues=0, peakwidths=0
	variable i
	variable minx, maxx, peakgood
	getaxis /q Bottom
	minx = v_min
	maxx = v_max
	findpeak /b=4/q/R=(v_min,v_max) ywave
	if(v_flag==0)
		peakgood=1
	endif
	variable j=0
	for(i=0;i<50;i+=1)
		if(peakgood)
			peaklocs[i][0] = v_peakloc
			peaklocs[i][1] = v_peakVal
			if(waveexists(w_coef))
				peaklocs[i][2] = w_coef[3]/2
			else
				peaklocs[i][2] = v_peakWidth
			endif
		else
			i=i-1
		endif
		j+=1
		if(j>100)
			break
		endif
		minx=v_peakloc+.2*peaklocs[i][2]
		findpeak /b=4/q/R=(minx,maxx) ywave
		if(v_flag!=0) // no peaks found
			break
		endif
		//check if it is a big peak (which find peaks doesn't do well, if so use the gaussian fit to refine)
		variable v_fiterror=0
		CurveFit/q/M=2/W=2 gauss, ywave(v_peakloc-5*v_peakwidth,v_peakloc+5*v_peakwidth) // check the peak location if there is a gaussian fit
		wave w_coef
		if(v_fiterror || w_coef[2]<v_peakloc-v_peakwidth || w_coef[2]>v_peakloc+v_peakwidth || w_coef[1]<0.003*wavemax(ywave)) // there is no peak within the range
			v_fiterror=0
			CurveFit/q/M=2/W=2 gauss, ywave(v_peakloc-3*v_peakwidth,v_peakloc+3*v_peakwidth)// check the peak location if there is a gaussian fit
			wave w_coef
			if(v_fiterror || w_coef[2]<v_peakloc-v_peakwidth || w_coef[2]>v_peakloc+v_peakwidth || w_coef[1]<0.005*wavemax(ywave)) // there is no peak within the range
				v_fiterror=0
				CurveFit/q/M=2/W=2 gauss, ywave(v_peakloc-.6*v_peakwidth,v_peakloc+.6*v_peakwidth) // check the peak location if there is a gaussian fit
				wave w_coef
				if(v_fiterror || w_coef[2]<v_peakloc-v_peakwidth || w_coef[2]>v_peakloc+v_peakwidth || w_coef[1]<0.02*wavemax(ywave)) // there is no peak within the range
					peakgood=0
					continue
				else
					peakgood=1
					killwaves /z w_coef
				endif
			else
				peakgood=1
			endif
		else
			peakgood=1
		endif
	endfor
	redimension /n=(i+1,3) peaklocs//, peakvalues, peakwidths
	
	
	redimension /n=(i+1,3) peaklocs//, peakvalues, peakwidths
	make /n=(i+1) /free col0 = peaklocs[p][0],col1 = peaklocs[p][1],col2 = peaklocs[p][2]
	sort/r col1,col1,col0,col2
	peaklocs[][0] = col0[p]
	peaklocs[][1] = col1[p]
	peaklocs[][2] = col2[p]
	redimension /n=(min(i+1,3),3) peaklocs//, peakvalues, peakwidths
	
	if(!dontplot)
		appendtograph peaklocs[][1] vs peaklocs[][0]
		ModifyGraph mode(peaklocs)=3,marker(peaklocs)=19
		ErrorBars peaklocs X,wave=(peaklocs[][2],peaklocs[][2])
	endif
	killwaves /z M_covar, w_coef, w_sigma, w_autopeakinfo
	return peaklocs // dimension0 location dim1 value dim3 width in location
end

function /wave findminima(ywave,[dontplot])
	wave ywave
	variable dontplot
	killwaves /z w_coef
	wave/z w_coef
	RemoveFromGraph /z minlocs
	make /free/o/n=(50,3) minlocs=0//, peakvalues=0, peakwidths=0
	variable i
	variable minx, maxx, peakgood
	getaxis /q Bottom
	minx = v_min
	maxx = v_max
	findpeak /n/b=4/q/R=(v_min,v_max) ywave
	if(v_flag==0)
		peakgood=1
	endif
	variable j=0
	for(i=0;i<50;i+=1)
		if(peakgood)
			minlocs[i][0] = v_peakloc
			minlocs[i][1] = v_peakVal
			if(waveexists(w_coef))
				minlocs[i][2] = w_coef[3]/2
			else
				minlocs[i][2] = v_peakWidth
			endif
		else
			i=i-1
		endif
		j+=1
		if(j>100)
			break
		endif
		minx=v_peakloc+.4*minlocs[i][2]
		findpeak /n/b=4/q/R=(minx,maxx) ywave
		if(v_flag!=0) // no peaks found
			break
		endif
		//check if it is a big peak (which find peaks doesn't do well, if so use the gaussian fit to refine)
		variable v_fiterror=0
		CurveFit/q/M=2/W=2 gauss, ywave(v_peakloc-3*v_peakwidth,v_peakloc+3*v_peakwidth) // check the peak location if there is a gaussian fit
		wave w_coef
		if(v_fiterror || w_coef[2]<v_peakloc-v_peakwidth || w_coef[2]>v_peakloc+v_peakwidth || -w_coef[1]<0.005*wavemax(ywave)) // there is no peak within the range
			v_fiterror=0
			CurveFit/q/M=2/W=2 gauss, ywave(v_peakloc-.5*v_peakwidth,v_peakloc+.5*v_peakwidth) // check the peak location if there is a gaussian fit
			wave w_coef
			if(v_fiterror || w_coef[2]<v_peakloc-v_peakwidth || w_coef[2]>v_peakloc+v_peakwidth || -w_coef[1]<0.05*wavemax(ywave)) // there is no peak within the range
				peakgood=0
				continue
			else
				peakgood=1
			endif
		else
			peakgood=1
		endif
	endfor
	
	redimension /n=(i+1,3) minlocs//, peakvalues, peakwidths
	make /n=(i+1) /free col0 = minlocs[p][0],col1 = minlocs[p][1],col2 = minlocs[p][2]
	sort col1,col1,col0,col2
	minlocs[][0] = col0[p]
	minlocs[][1] = col1[p]
	minlocs[][2] = col2[p]
	redimension /n=(3,3) minlocs//, peakvalues, peakwidths
	
	if(!dontplot)
		appendtograph minlocs[][1] vs minlocs[][0]
		ModifyGraph mode(minlocs)=3,marker(minlocs)=19
		ErrorBars minlocs X,wave=(minlocs[][2],minlocs[][2])
	endif
	
	killwaves /z M_covar, w_coef, w_sigma, w_autopeakinfo
	return minlocs // dimension0 location dim1 value dim3 width in location
end

function /wave QANT_FindInterestingContrasts([graph,graphname])
// this procedure will operate on the calculated contrast functions and delta/beta contrast space maps which QANT creates
	// this procedure will act on a graph of contrasts, finding the maxima and minima as well as the points where each wave is highest relative to all of the other contrasts (isolation points)
	//  all of these points will be displayed in the color of the relative trace with full circles indicating maxima, empty circles indicating minima, and squares inticating isolation points.
	
	// all calculations assume the top graph is a bunch of contrasts which are displayed over the same range and with the same offsets and spacings (no x waves)
	
	// gather all waves into a wave of waves, make sum wave
	variable graph
	string graphname
	graph = paramisdefault(graph)? 1 : graph
	if(paramisdefault(graphname))
		graphname = stringfromlist(0,winlist("*",";","WIN:1"))
	endif
	string tracelist = tracenamelist(graphname,";",1)
	
	variable num = itemsinlist(tracelist)
	make /free/o/n=(num) /wave plottedwaves = tracenametowaveref(graphname,stringfromlist(p,tracelist))
	string outputname = uniquename("Output",1,0)
	make /t /o /n=(num*9+1,6) $outputname
	make /t /free /n=(num*9) tempenergies, tempnames, temperrors, temprank, tempints, temptype
	
	
	wave /t output = $outputname
	//edit /k output
	output[0][0]="Contrast"
	output[0][1]="type"
	output[0][2]="Energy"
	output[0][3]="Uncertainty"
	output[0][4]="Rank"
	output[0][5]="Relative Intensity"
	
//	tempnames[0] = "none"
//	tempenergies[0]="0000"
	duplicate /free plottedwaves[0] , sumwave
	variable i
	for(i=1;i<num;i+=1)
		wave tempwave = plottedwaves[i]
		sumwave += tempwave[p]
	endfor 
	for(i=0;i<num*9;i+=1)
		if(mod(i,9)<3)
			temptype[i] = "Peak"
		elseif(mod(i,9)<6)
			temptype[i] = "Minimum"
		else
			temptype[i] = "Isolated Maxima"
		endif
	endfor
	//make the sum wave
	variable  red,blue,green
	string colorstr, maxwname,minwname,isowname, tempstring
	// for each plotted wave
	for(i=0;i<num;i+=1)
		// get color of trace for current wave
		colorstr = stringbykey("RGB(x)",traceinfo(graphname,stringfromlist(i,tracelist),0),"=",";")
		sscanf colorstr, "(%d,%d,%d)",red,blue,green
		// find maxima of current wave, and plot them
		maxwname = uniquename("Maxima",1,0)
		minwname = uniquename("Minima",1,0)
		isowname = uniquename("Isolation",1,0)
		//output[3*i+1][0]=stringfromlist(i,tracelist)+" Maxima"
		tempnames[9*i,9*i+2] = stringfromlist(i,tracelist)//+" Maxima"
		//output[3*i+2][0]=stringfromlist(i,tracelist)+" Minima"
		tempnames[9*i+3,9*i+5] = stringfromlist(i,tracelist)//+" Minima"
		//output[3*i+3][0]=stringfromlist(i,tracelist)+" Isolated Maxima"
		tempnames[9*i+6,9*i+8] = stringfromlist(i,tracelist)//+" Isolated Maxima"
		
		
		wave peaklocs = findpeaks(plottedwaves[i],dontplot=1)
		duplicate peaklocs, $maxwname
		wave maxwave = $maxwname
		
		wave minlocs = findminima(plottedwaves[i],dontplot=1)
		duplicate minlocs, $minwname
		wave minwave = $minwname
		
		duplicate /free plottedwaves[i], tempwave
		tempwave /= (sumwave - tempwave)/(num-1)
		wave isolocs = findpeaks(tempwave,dontplot=1)
		duplicate isolocs, $isowname
		wave isowave = $isowname
		//output[3*i+1][1,3] = num2str(0.1*round(10*maxwave[q-1][0]))+ " +/- "+num2str(0.1*round(10*maxwave[q-1][2]))
		tempenergies[9*i+0] = num2str(0.1*round(10*maxwave[0][0]))
		tempenergies[9*i+1] = num2str(0.1*round(10*maxwave[1][0]))
		tempenergies[9*i+2] = num2str(0.1*round(10*maxwave[2][0]))
		temperrors[9*i+0] = num2str(0.1*round(10*maxwave[0][2]))
		temperrors[9*i+1] = num2str(0.1*round(10*maxwave[1][2]))
		temperrors[9*i+2] = num2str(0.1*round(10*maxwave[2][2]))
		temprank[9*i+0] = "1"
		temprank[9*i+1] = "2"
		temprank[9*i+2] = "3"
		tempints[9*i+0] = num2str(0.1*round(10*maxwave[0][1]))
		tempints[9*i+1] = num2str(0.1*round(10*maxwave[1][1]))
		tempints[9*i+2] = num2str(0.1*round(10*maxwave[2][1]))
		//output[3*i+2][1,3] = num2str(0.1*round(10*minwave[q-1][0]))+ " +/- "+num2str(0.1*round(10*minwave[q-1][2]))
		tempenergies[9*i+3] = num2str(0.1*round(10*minwave[0][0]))
		tempenergies[9*i+4] = num2str(0.1*round(10*minwave[1][0]))
		tempenergies[9*i+5] = num2str(0.1*round(10*minwave[2][0]))
		temperrors[9*i+3] = num2str(0.1*round(10*minwave[0][2]))
		temperrors[9*i+4] = num2str(0.1*round(10*minwave[1][2]))
		temperrors[9*i+5] = num2str(0.1*round(10*minwave[2][2]))
		temprank[9*i+3] = "1"
		temprank[9*i+4] = "2"
		temprank[9*i+5] = "3"
		tempints[9*i+3] = num2str(0.1*round(10*minwave[0][1]))
		tempints[9*i+4] = num2str(0.1*round(10*minwave[1][1]))
		tempints[9*i+5] = num2str(0.1*round(10*minwave[2][1]))
		//output[3*i+3][1,3] = num2str(0.1*round(10*isowave[q-1][0]))+ " +/- "+num2str(0.1*round(10*isowave[q-1][2]))
		tempenergies[9*i+6] = num2str(0.1*round(10*isowave[0][0]))
		tempenergies[9*i+7] = num2str(0.1*round(10*isowave[1][0]))
		tempenergies[9*i+8] = num2str(0.1*round(10*isowave[2][0]))
		temperrors[9*i+6] = num2str(0.1*round(10*isowave[0][2]))
		temperrors[9*i+7] = num2str(0.1*round(10*isowave[1][2]))
		temperrors[9*i+8] = num2str(0.1*round(10*isowave[2][2]))
		temprank[9*i+6] = "1"
		temprank[9*i+7] = "2"
		temprank[9*i+8] = "3"
		tempints[9*i+6] = num2str(0.1*round(10*isowave[0][1]))
		tempints[9*i+7] = num2str(0.1*round(10*isowave[1][1]))
		tempints[9*i+8] = num2str(0.1*round(10*isowave[2][1]))
	
		if(graph)
			appendtograph maxwave[][1] /tn=$maxwname vs maxwave[][0]
			ModifyGraph mode($maxwname)=3,marker($maxwname)=19,rgb($maxwname)=(red,blue,green)
			ErrorBars $maxwname X,wave=(maxwave[][2],maxwave[][2])
			appendtograph minwave[][1] /tn=$minwname vs minwave[][0]
			ModifyGraph mode($minwname)=3,marker($minwname)=8,rgb($minwname)=(red,blue,green)
			ErrorBars $minwname X,wave=(minwave[][2],minwave[][2])
			appendtograph /r isowave[][1] /tn=$isowname vs isowave[][0]
			ModifyGraph mode($isowname)=3,marker($isowname)=17,rgb($isowname)=(red,blue,green)
			ErrorBars $isowname X,wave=(isowave[][2],isowave[][2])
		endif
	endfor
	dowindow /k QANT_contrast_table
	sort/DIML {temptype,tempenergies}, tempenergies, tempnames, temperrors, temprank, tempints, temptype
	output[1,][0] = tempnames[p-1]
	output[1,][1] = temptype[p-1]
	output[1,][2] = tempenergies[p-1]
	output[1,][3] = temperrors[p-1]
	output[1,][4] = temprank[p-1]
	output[1,][5] = tempints[p-1]
	edit/n=QANT_contrast_table /W=(761,249,1416,724)/k=1 output as "Potentially interesting Energies"
	ModifyTable/Z /w=QANT_contrast_table autosize={0,0,-1,0,0}
	return output
end


function QANT_emphasizeXval(graphname,xval)
// plots contrasts (connections between) points and emphasizez certain points on a graph
	string graphname
	variable xval
	string tracelist = tracenamelist(graphname,";",1)
	variable num = itemsinlist(tracelist)
	variable i,j,k
	string tracename
	for(i=num-1;i>-1;i-=1)
		tracename = stringfromlist(i,tracelist)
		if(stringmatch(tracename,"em_*") || stringmatch(tracename,"contrasts"))
			removefromgraph/z /w=$graphname $tracename
		endif
	endfor
	tracelist = tracenamelist(graphname,";",1)
	num = itemsinlist(tracelist)
	variable pval,pxval, red, blue, green
	string colorstr, newtracename
	for(i=0;i<num;i+=1)
		tracename = stringfromlist(i,tracelist)
		wave plottedwave = tracenametowaveref(graphname, tracename)
		wave plottedxwave = xwavereffromtrace(graphname, tracename)
		pval = x2pnt(plottedwave,xval)
		pxval = x2pnt(plottedxwave,xval)
		colorstr = stringbykey("RGB(x)",traceinfo(graphname,tracename,0),"=",";")
		sscanf colorstr, "(%d,%d,%d)",red,blue,green
		newtracename = cleanupname("em_"+tracename,0)
		appendtograph /w=$graphname plottedwave[pval,pval] /tn=$newtracename vs plottedxwave[pxval,pxval]
		ModifyGraph /w=$graphname mode($newtracename)=3,marker($newtracename)=19,rgb($newtracename)=(red,blue,green)
	endfor
	
	make /o/n=(num*(num+1),2) connections
	make /o/n=(num*(num+1),3) connectioncolors
	variable del1, del2, bet1, bet2
	for(i=0;i<num;i+=1)
		for(j=num;j>i;j-=1)
			colorstr = stringbykey("RGB(x)",traceinfo("QANT_contrast","#"+num2str(k/2),0),"=",";")
			sscanf colorstr, "(%d,%d,%d)",red,blue,green
			wave d1wave = tracenametowaveref(graphname, stringfromlist(i,tracelist))
			wave b1wave = xwavereffromtrace(graphname, stringfromlist(i,tracelist))
			wave d2wave = tracenametowaveref(graphname, stringfromlist(min(j,num),tracelist))
			wave b2wave = xwavereffromtrace(graphname, stringfromlist(min(j,num),tracelist))
			
			connections[k][0] = d1wave(xval)
			connections[k][1] = b1wave(xval)
			connectioncolors[k][0] = red
			connectioncolors[k][1] = blue
			connectioncolors[k][2] = green
			//connectioncolors[k][3] = 65000
			
			k+=1
			
			connections[k][0] = j==num ? 0 : d2wave(xval)
			connections[k][1] = j==num ? 0 : b2wave(xval)
			connectioncolors[k][0] = 0
			connectioncolors[k][1] = 0
			connectioncolors[k][2] = 0
			connectioncolors[k][0] = red
			connectioncolors[k][1] = blue
			connectioncolors[k][2] = green
			//connectioncolors[k][3] = 0
			
			k+=1
		endfor
	endfor
	setdrawlayer/w=QANT_plot /k userback
	setdrawlayer/w=QANT_plot userback
	SetDrawEnv/w=QANT_plot xcoord= bottom,dash= 6
	DrawLine/w=QANT_plot xval,0,xval,1
	setdrawlayer/w=QANT_contrast /k userback
	setdrawlayer/w=QANT_contrast userback
	SetDrawEnv/w=QANT_contrast xcoord= bottom,dash= 6
	DrawLine/w=QANT_contrast xval,0,xval,1
	appendtograph /w=$graphname connections[][0] /tn=contrasts vs connections[][1]
	ModifyGraph /w=$graphname zColor(contrasts)={connectioncolors,*,*,directRGB,0},lsize(contrasts)=2
	TextBox /w=$graphname /C/N=text0/F=0/A=RT/X=2/Y=1.00 num2str(xval) + " eV"
end

Function QANT_popFType(pa) : PopupMenuControl
	STRUCT WMPopupAction &pa

	switch( pa.eventCode )
		case 2: // mouse up
			Variable popNum = pa.popNum
			String popStr = pa.popStr
			svar FileType = root:NEXAFS:FileType
			FileType = popStr
			break
		case -1: // control being killed
			break
	endswitch

	return 0
End

function /s QANT_FTypeList()
	string listout="", funcname, listtemp = functionlist("QANT_loadNEXAFSfile_*",";","")
	variable j
	for(j=0;j<itemsinlist(listtemp);j+=1)
		funcname = replacestring("QANT_loadNEXAFSfile_",stringfromlist(j,listtemp),"")
		listout = addlistitem(funcname,listout)
	endfor
	return listout
end


function /s QANT_NEXAFSfileEXt_Dean() // Dean's XDAC
	return "????"
end
function /s QANT_LoadNEXAFSfile_Dean(pathn) // Dean's XDAC
	string pathn
	variable fileref
	open/r/F="NEXAFS files (*.*,):*.*;" fileref as pathn
	string fullpath = s_filename
	FStatus fileref
	if(V_flag==0)
		return ""
	endif
	close fileref

	string scantime, scanname
	grep/Q/LIST/E="created on " fullpath
	splitstring /e="^\"([^\"]*)\" created on (.*) on 07-ID1" s_value, scanname, scantime
	
	
	if(strlen(scantime)<1)
		return ""
	endif
	
	string foldersave = getdatafolder(1)
	
	setdatafolder root:
	newdatafolder /O/S NEXAFS

	wave /T QANT_LUT
	newdatafolder /O/S Scans
	newdatafolder /O/S $cleanupname(scanname,0)

	
	
	killwaves /Z/A
	string /g filename = fullpath
	getfilefolderinfo /p=NEXAFSPath /q/z scanname
	string /g filesize
	sprintf filesize, "%d" ,v_logEOF
	string /g cdate
	sprintf cdate, "%d" ,v_creationdate
	string /g mdate
	sprintf mdate, "%d" ,v_modificationdate
	string syear, smonth, sday, shour, sminute, ssecond, sampm
	
	
	
	
	splitstring /e="^([1234567890]{1,2})/([1234567890]{1,2})/([1234567890]{4}) at ([1234567890]{1,2}):([1234567890]{2}):([1234567890.]*) ([A|P]M)" scantime, smonth, sday, syear, shour, sminute,ssecond,sampm
	
	variable year = str2num(syear)
	variable month = str2num(smonth)
	variable day = str2num(sday)
	variable hour = str2num(shour)
	hour += stringmatch(sampm,"AM")? 0 : 12
	variable minute = str2num(sminute)
	variable second = str2num(ssecond)
	
	string /g acqtime = num2str(year) + " " + num2str(month) + " " + num2str(day) + " " + num2str(hour)+":" + num2str(minute) +":" + num2str(second)
	
	
	string samp, angle, bias
	grep/Q/LIST/E="/Angle [1234567890]*/Bias" fullpath
	splitstring /e="^([^/]*)/Angle ([-.1234567890]*)/Bias ([-.1234567890]*)" s_value, samp, angle, bias
	
	string notes2add =""
	
	grep/Q/LIST/E="XDAC" fullpath
	notes2add += s_value
	grep/Q/LIST/E="created on" fullpath
	notes2add += " - " +  s_value
	grep/Q/LIST/E="element" fullpath
	notes2add += " - " + s_value
	
	string /g notes = notes2add
	string /g anglestr = angle
	string /g otherstr = bias
	string /g SampleName = samp
	string /g SampleSet
	if(strlen(SampleSet)*0!=0)
		SampleSet = ""
	endif
	string /g refscan
	if(strlen(refscan)*0!=0)
		refscan = "Default"
	endif
	string /g darkscan
	if(strlen(darkscan)*0!=0)
		darkscan = "Default"
	endif
	string /g enoffset
	if(strlen(enoffset)*0!=0)
		enoffset = "Default"
	endif
	grep /INDX /Q /E="-----------------------" fullpath
	wave /z w_index
	if(w_index[0] < 1)
		setdatafolder ::
		killdatafolder /z $cleanupname(scanname,1)
		return ""
	endif
	try
		LoadWave/o/J/D/W/A/K=1/Q/V={"\t, "," $",0,2}/L={w_index[0]+1,w_index[0]+2,0,0,0} filename
	catch
		setdatafolder ::
		killdatafolder /z $cleanupname(scanname,1)
		return ""
	endtry
	wave /z Energy
	if(waveexists(Energy))
		duplicate Energy, EnergySetpoint
		string listofwaves = addlistitem("EnergySetpoint",S_wavenames)
		listofwaves = removelistitem(whichlistitem("Blank", listofwaves),listofwaves)
	else
		listofwaves = S_wavenames
	endif
	Make/ n=(itemsinlist(S_waveNames)) /T ColumnNames = stringfromlist(p,S_waveNames)
	
	
	
	
	setdatafolder foldersave
	print "Loaded NEXAFS file : " + cleanupname(scanname,1)
	return 	cleanupname(scanname,1)
end

Function QANT_CloneWindow([win,newwindowname,thisfolder])
	String win
	String newwindowname // The new name for the window
	variable thisfolder // if non zero, copy waves to current datafolder
	if(ParamIsDefault(win))
		win=WinName(0,1)
	endif
	string rawwindowname = newwindowname
	if(ParamIsDefault(newwindowname))
		newwindowname=UniqueName(win,6,0)
	else
		newwindowname=CleanupName(newwindowname,0)
		if(wintype(newwindowname))
			newwindowname = uniquename(newwindowname,6,0)
		endif
	endif
	thisfolder = paramisdefault(thisfolder)? 0 : thisfolder
	String curr_folder=GetDataFolder(1)
	if(!thisfolder)
		NewDataFolder /O/S root:savedgraphs
		if(datafolderexists(newwindowname))
			newwindowname = uniqueName(newwindowname,11,0)
		endif
		NewDataFolder /O/S $newwindowname
	endif
	String traces=TraceNameList(win,";",3)
	string nameofnewwave
	Variable i,j
	
	String win_rec=WinRecreation(win,0)
 	// Copy error bars if they exist.  Won't work with subrange display syntax.  
	for(i=0;i<ItemsInList(win_rec,"\r");i+=1)
		String line=StringFromList(i,win_rec,"\r")
		if(StringMatch(line,"*ErrorBars*"))
			String errorbar_names
			splitstring /e="[^=]*=\(([^)]*)" line,errorbar_names
			for(j=0;j<2;j+=1)
				String errorbar_path=StringFromList(j,errorbar_names,",")
				String errorbar_name = StringFromList(ItemsInList(errorbar_path,":")-1,errorbar_path,":")
				if(strlen(errorbar_name)>0)
					errorbar_name = cleanupname(errorbar_name,1)
					wave testwave = $errorbar_name
					if(waveexists(testwave))
						errorbar_name = uniquename(errorbar_name,1,0)
					endif
					Duplicate $("root"+errorbar_path) $cleanupname(errorbar_name,1)
					wave testwave = $cleanupname(errorbar_name,1)
					if(waveexists(testwave))
						win_rec = replaceString(errorbar_path,win_rec,getwavesDataFolder(testwave,2))
					else
						print "error with errorbars :)"
					endif
				endif
			endfor
		endif
		if(stringmatch(line,"*cursor*"))
			win_rec = removelistitem(i,win_rec,"\r")
			i=i-1
		endif
		if(stringmatch(line,"*Display* as \"*"))
			string title
			splitstring /e=" as \"(.*)\"" line, title
			win_rec = replacestring(title,win_rec,rawwindowname + " cloned from " + title)
		endif
	endfor
	
	Execute /Q win_rec
	DoWindow /C $newwindowname
	
	for(i=0;i<ItemsInList(traces);i+=1)
		String trace=StringFromList(i,traces)
		Wave TraceWave=TraceNameToWaveRef(win,trace)
		nameofnewwave = nameofwave(TraceWave)
		wave testwave = $nameofnewwave
		if(waveexists(testwave))
			nameofnewwave = uniquename(nameofnewwave,1,0)
		endif
		Duplicate TraceWave $nameofnewwave
		
		replacewave /W=$newwindowname trace=$trace , $nameofnewwave 
		
		Wave /Z TraceXWave=XWaveRefFromTrace(win,trace)
		if(waveexists(TraceXWave))
			nameofnewwave = nameofwave(TraceXWave)
			wave testwave = $nameofnewwave
			if(waveexists(testwave))
				nameofnewwave = uniquename(nameofnewwave,1,0)
			endif
			Duplicate /o TraceXWave $nameofnewwave
			
			
			replacewave /X/W=$newwindowname trace=$trace , $nameofnewwave 
		endif
	endfor
	
	
	SetDataFolder $curr_folder
End

Function QANT_Clone_but(ba) : ButtonControl
	STRUCT WMButtonAction &ba

	switch( ba.eventCode )
		case 2: // mouse up
			svar clonename = root:Nexafs:CloneName
			QANT_CloneWindow(newwindowname=CloneName,thisfolder = 0)
			
			break
		case -1: // control being killed
			break
	endswitch

	return 0
End

Window QANT_About_QANT() : Panel
	PauseUpdate; Silent 1		// building window...
	killwindow /z About_QANT
	NewPanel /W=(824,354,1188,683) /n=About_QANT as "About QANT"
	SetDrawLayer UserBack
	SetDrawEnv fsize= 24,fstyle= 3,textxjust= 1,textyjust= 1
	DrawText 176,32,"QANT"
	SetDrawEnv fsize= 14,fstyle= 1,textxjust= 1,textyjust= 1
	DrawText 181,60,"(Q)uick (A)ussietron (N)EXAFS (T)ool"
	DrawText 222,40,"v1.12"
	SetDrawEnv textxjust= 1,textyjust= 1
	DrawText 183,101,"\\JCDeveloped by Eliot Gann (eliot.gann@nist.gov)\rPreviously at Australian Synchrotron\rCurrently National Institute of Standards and Technology"
	SetDrawEnv textxjust= 1,textyjust= 1
	DrawText 175,151,"\\JCPlease cite us if you use QANT for \ryour scientific publication"
	TitleBox title0,pos={13.00,176.00},size={344.00,136.00}
	TitleBox title0,labelBack=(65535,65535,65535),font="Courier",frame=5
	TitleBox title0,variable= root:NEXAFS:CitationText
	//DrawText 14,308,"\\JCQuick AS NEXAFS Tool (QANT): \ra program for NEXAFS loading and analysis \rdeveloped at the Australian Synchrotron\nE Gann, CR McNeill, A Tadich,\r BCC Cowie, L Thomsen\rJournal of synchrotron radiation, 2016\r\rdoi.org/10.1107/S1600577515018688"
	//SVAR citationtext = root:NEXAFS:CitationText

EndMacro