#pragma rtGlobals=3		// Use modern global access method and strict wave access.
Menu "Macros"
	"QANT - Quick AS NEXAFS tool", /Q, Execute/P "DELETEINCLUDE \"SHEILA\"";Execute/P "DELETEINCLUDE \"NEXAFS Loader\"";Execute/P "INSERTINCLUDE \"QANT\"";Execute/P "COMPILEPROCEDURES ";Execute/P/Q "QANT_Loaderfunc()"
	help={"Load and Analyze NEXAFS files collected from the Australian Synchrotron"}
End