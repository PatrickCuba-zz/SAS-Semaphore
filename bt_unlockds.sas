%Macro BT_UnLockDS(DS=);
	* General error checks, required input fields ;
	* Initialise error variable ;

	%Let BT_LibTable=%Upcase(&DS.);
	%Let BT_Table=%scan(&BT_LibTable.,1,.)_%scan(&BT_LibTable.,-1,.); 
	* Filename will include library and table name ;

	%Put NOTE: Removing semaphore lock ...;
	%Sysexec(rm &BT_Semaphore_Dir./&BT_Table..lck);
	%If &sysrc. ne 0 %then %put WARNING: Something went wrong with semaphore removal, &BT_Table. not deleted.;
	%Else %Put NOTE: Semaphore removed.;

%Mend;

