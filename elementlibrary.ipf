#pragma rtGlobals=3		// Use modern global access method and strict wave access.
function loadelementlibrary()
	// first we will see if there is an element library to load
	NewPath/Z/Q/O ElementPath SpecialDirPath("Igor Pro User files",0,0,0)+"User Procedures:Atomic Scattering Factors"
	pathinfo elementpath
	if(v_flag==0)
		print "Error, no atomic scattering factors found.\rPlease create a directory in User Procedures called \"Atomic Scattering Factors\" \r and download download and extract the tar.gz available http://henke.lbl.gov/optical_constants/asf.html to that directory"
		return 0
	endif

	String fileList=IndexedFile( ElementPath, -1, ".nff")
	if(strlen(filelist)<1)
		print "Error, no element library found.","Please download and extract the tar.gz available http://henke.lbl.gov/optical_constants/asf.html to the \"Atomic Scattering Factors\" directory in User Procedures"
		pathinfo /show elementpath
		return 0
	endif
	variable i, numelements=itemsinlist(filelist)
	string elementname
	string foldersave = getdatafolder(1)
	setdatafolder root:
	newdatafolder /o/s AtomicScatteringFactors
	wave AtomicWeights
	if(waveexists(AtomicWeights))
		return 0
	endif
	make /o /t Names= {"H","He","Li","Be","B","C","N","O","F","Ne","Na","Mg","Al","Si","P","S","Cl","Ar","K","Ca","Sc","Ti","V","Cr","Mn","Fe","Co","Ni","Cu","Zn","Ga","Ge","As","Se","Br","Kr"}
	make /o /n=36 AtomicNumber = p+1
	make /o AtomicWeights = {1.00794,4.002602,6.94,9.012182,10.81,12.0107,14.00067,15.9994,18.9984,20.1797,22.98976928,24.305,26.9815386,28.0855,30.973762,32.065,35.45,39.948,39.0983,40.078,44.955912,47.867,50.9415,51.9961,54.938045,55.845,58.933195,58.6934,63.546,65.38,69.723,72.63,74.9216,78.96,79.904,83.798}
	make /n=(2^20) /o energy
	setscale /i x,10,30000,"eV",  energy
	energy=x
	
	for(i=0;i<numelements;i+=1)
		elementname = removeending(stringfromlist(i,filelist),".nff")
		if(strlen(elementname)<1)
			continue
		endif
		findvalue /text=elementname /txop=6 Names
		if(v_value<0)
			continue
		endif
		newdatafolder /o/s $elementname
		killwaves /a/z
		variable /g weight=Atomicweights[v_value]
		LoadWave/q/o/J/D/W/A/P=ElementPath/K=0 stringfromlist(i,filelist)
		wave/z f2interp
		duplicate energy, f2interp
		setscale /i x,10,30000,"eV",  f2interp
		wave /z e_ev_, f2
		if(!waveexists(e_ev_) || !waveexists(f2))
			killwaves /a/z
			setdatafolder root:AtomicScatteringFactors
			killdatafolder $elementname
			continue
		endif
		f2interp = interp(x,e_ev_,f2)
		rename e_ev_, Ev
		setdatafolder root:AtomicScatteringFactors
	endfor
	setdatafolder foldersave
end