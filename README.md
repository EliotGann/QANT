# QANT
Quick AS NEXAFS Tool
developed by Eliot Gann of the Australian Synchrotron and currently NIST (eliot.gann@nist.gov)
an Igor Pro set of procedures, best working on Igor Pro v 8+, but compatible with Igor Pro 6+

For installation, it is suggested that you follow these instructions:

Install Github Desktop, create a github account if you haven't already

1.) Clone this repository to your local computer (doesn't matter where you store it, the default location is probaby fine)

2.) Create a shortcut (windows) or alias (mac) of the the "QANT_Igor" directory in the "Igor Procedures" folder (within Igor, go to  Help -> Igor Pro User Files)

3.) within the "user procedures" (within Igor, go to  Help -> Igor Pro User Files) folder create a folder called "Atomic Scattering Factors".

4.) Download the atomic scattering factors from henke (http://henke.lbl.gov/optical_constants/asf.html)  and place the unzipped files in this directory, along with a copy of the "AtomicWeight.txt" file from the github folder (note an alias/shortcut of this files does not work).

5.) create a shortcut/alias of "QANT_users" girhub directory somewhere in "user procedures".  

Also download and install the latest version of Optical Constants Library (seperate github repository https://github.com/EliotGann/Optical-Constants-Database) for optical constants integration.


If you install QANT in this way, to update to the latest version all you have to do is go into github desktop and fetch the latest master version which will always be updated here.  You can also make changes to QANT and github will let us merge them nicely!

With newer versions, you also need to install the HDF5 XOP which is included in igor pro.  for that, follow these instructions:

a.) open up Igor Pro  go to Help-> "Show Igor Pro Folder"

b.) from Igor Pro, also go to Help-> "Show Igor Pro User Files"

basically you will be copying or creating links of things in the "igor pro folder" which is in the applications directory on you computer, into your local igor pro user files directory, which is generally in your documents folder.  you should have these two locations open in separate windows now.

c.) from the applications window, go to "more extensions/File Loaders/" and copy the HDF5.xop into the "igor extensions" folder in the documents window (or create a short cut)

d.) copy the HDF5.ihf to the "igor help files" folder in the documents window (or create a shortcut)

e.) repeat for the "more extensions (64-bit)" and "igor extensions (64 bit)" respectively.


For more details on QANT, how it works, and how you should use it, including some videos please see the official publication:
https://doi.org/10.1107/S1600577515018688

and cite us if you use QANT to help analyze your data:

Quick AS NEXAFS Tool (QANT): a program for NEXAFS loading and analysis developed at the Australian Synchrotron
E. Gann, C. R. McNeill, A. Tadich, B. C. C. Cowie and L. Thomsen
J. Synchrotron Rad. (2016). 23, 374-380
