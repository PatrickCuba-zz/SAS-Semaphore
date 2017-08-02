%Macro ULT_SemphoreRls(ULT_LibTable=);
	* General error checks, required input fields ;
	* Initialise error variable ;

	%Let ULT_LibTable=%Upcase(&ULT_LibTable.);

	%Let ULT_SemError=0;
	%If &ULT_LibTable.= %Then %Do;
		%Put ERROR: No Target table specified... ;
		%Let ULT_SemError=1; 
		%Goto ULT_EndOfMac;
	%End;
	%Let ULT_Table=%scan(&ULT_LibTable.,1,.)_%scan(&ULT_LibTable.,-1,.); 
	* Filename will include library and table name ;

	%Put NOTE: Removing semaphore lock ...;
	%Sysexec(rm &ULT_Semaphore_Dir./&ULT_Table..lck);
	%If &sysrc. ne 0 %then %put WARNING: Something went wrong with semaphore removal, &ULT_Table. not deleted.;
	%Else %Put NOTE: Semaphore removed.;

%ULT_EndOfMac:
	%If &ULT_SemError.=1 %then %Do;
		%Put ERROR: Aboring..; 
	%End;

%Mend;
