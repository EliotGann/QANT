# QANT
Quick AS NEXAFS Tool
developed by Eliot Gann of the Australian Synchrotron and currently NIST (eliot.gann@nist.gov)
an Igor Pro set of procedures, best working on Igor Pro v 8+, but compatible with Igor Pro 6+

For installation, QANT.ipf goes somewhere in user procedures, AUNEXAFS.ipf goes in igor procedures. NOTE these directories exist both in the program directory and in the documents folder.  These files (and in general all procedures) should go in the documents directory only.  Download the atomic scattering factors from henke (http://henke.lbl.gov/optical_constants/asf.html) put them in a directory "{Documents directory}\Wavemetrics\{relevant Igor Pro folder}\User Procedures\Atomic Scattering Factors" along with the elementlibrary.ipf and atomicweights.txt files (note these will not work in the program user procedures folder).  Also download the latest version of Optical Constants Library (seperate github repository) for optical constants integration.

please cite us if you use QANT to help analyze your data:

https://doi.org/10.1107/S1600577515018688

Quick AS NEXAFS Tool (QANT): a program for NEXAFS loading and analysis developed at the Australian Synchrotron
E. Gann, C. R. McNeill, A. Tadich, B. C. C. Cowie and L. Thomsen
J. Synchrotron Rad. (2016). 23, 374-380
