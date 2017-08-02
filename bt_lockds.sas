%Macro BT_LockDS(DS=);
	%Let BT_LibTable=%Upcase(&DS.);

	* Step 1 ;
	%Let BT_Table=%scan(&BT_LibTable.,1,.)_%scan(&BT_LibTable.,-1,.); 
	* Filename will include library and table name ;

	Filename SemaFile "&BT_Semaphore_Dir./&BT_Table..lck";

	%Let BT_ContinueProcessing=N;

	/*Loop */
	%Do %Until(&BT_ContinueProcessing.=Y);
		* Step 2 ;
		* Scan directory for semaphore files ;
		Filename BT_dir PIPE "ls -l &BT_Semaphore_Dir. | awk '{print $9}'";
		
		%Let BT_FileExist=0;
		Data BT_Files;
			Infile BT_dir dsd firstobs=2 truncover;
			Input Filename $256.;
			Retain FileExist 0;

			* File exists - with a lock, we wait and try again  ;
			If Filename="&BT_Table..lck" Then Do;
				FileExist=1;
			End;

			Call Symput('BT_FileExist', FileExist);
		Run;

		* File never existed, create lock file and continue processing ;
		%If &BT_FileExist.=0 %Then %Do;
			%Put NOTE: Semaphore file created and locked ...;
			Data _Null_;
				File SemaFile ;
			Run;
		
			%Let BT_ContinueProcessing=Y;
		%End;

		* Lock file exists, apply semaphore action ;
		%If &BT_FileExist.=1 %Then %Do;
			%Put NOTE: Table &BT_LibTable. is locked;
			%Put NOTE: &BT_Table. locked, waiting 3 seconds ; 

			Data _Null_;
				Rc=Sleep(3,1);
			Run;
		%End;
	%End;
%Mend;

