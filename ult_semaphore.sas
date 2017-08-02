%Macro ULT_Semphore(ULT_LibTable=, ULT_SemaAction=, ULT_SemaWaitTime=, ULT_SemaWait=);
    * If ULT_SemaWait is set to 0 then we wait forever if there is a lock ;
	
	%Let ULT_LibTable=%Upcase(&ULT_LibTable.);

	* Step 1 ;
	* General error checks, required input fields ;
	* Initialise error variable ;
	%Let ULT_SemError=0;
	%If &ULT_SemaWaitTime= %Then %Let ULT_SemaWaitTime=3;

	%If &ULT_LibTable.= %Then %Do;
		%Put ERROR: No Target table specified... ;
		%Let ULT_SemError=1; 
		%Goto ULT_EndOfMac;
	%End;

	%Let ULT_Table=%scan(&ULT_LibTable.,1,.)_%scan(&ULT_LibTable.,-1,.); 
	* Filename will include library and table name ;

	Filename SemaFile "&ULT_Semaphore_Dir./&ULT_Table..lck";

	%If &ULT_SemaAction. ne 1 
	  and &ULT_SemaAction. ne 2
	    and &ULT_SemaAction. ne 3 %Then %Do;
		%Put ERROR: Semaphore action not specified... ;
		%Let ULT_SemError=1; 
		%Goto ULT_EndOfMac;
	%End;

	%Let ULT_WaitCount=0; * Initialise Loop Count - might be required if we have to wait ;
	%Let ULT_ContinueProcessing=N;

	/*Loop */
	%Do %Until(&ULT_ContinueProcessing.=Y);
		%Let ULT_WaitCount=%eval(&ULT_WaitCount.+1); * Add to loop count ;

		* Step 2 ;
		* Scan directory for semaphore files ;
		* If we find a lock then we apply semaphore action ;
		* If we do not find a lock then we continue ;
		Filename ULT_dir PIPE "ls -l &ULT_Semaphore_Dir. | awk '{print $9}'";
		
		%Let ULT_FileExist=0;
		Data ULT_Files;
			Infile ULT_dir dsd firstobs=2 truncover;
			Input Filename $256.;
			Retain FileExist 0;

			* File exists - with a lock, we wait and try again  ;
			If Filename="&ULT_Table..lck" Then Do;
				FileExist=1;
			End;

			Call Symput('ULT_FileExist', FileExist);
		Run;

		* File never existed, create lock file and continue processing ;
		%If &ULT_FileExist.=0 %Then %Do;
			%Put NOTE: Semaphore file created and locked ...;
			* Create semphore table with the job name inside * ;
			Data _Null_;
				Length FileOut $50.;
				File SemaFile ;
				FileOut="&etls_jobName.";
				Put FileOut;
			Run;
		
			%Let ULT_ContinueProcessing=Y;
		%End;

		* Lock file exists, apply semaphore action ;
		%If &ULT_FileExist.=1 %Then %Do;
			%Put NOTE: Table &ULT_LibTable. is locked;

			* Semaphore Action 1 = We wait ;
			%If &ULT_SemaAction.=1 %Then %Do;
				
				* Read file contents, if it contains the same job name then delete the semaphore ;
			    * (Assumes that the job failed and left a semaphore behind) ;
			    * Continue Polling regardless - second iteration should lock the table ;
			    Data _Null_;
					Infile SemaFile Truncover DSD;
					Input FileIn $50.;

					Put "NOTE: Job that locked &ULT_LibTable. is &etls_jobName.";

					If FileIn="&etls_jobName." Then Do;
					   Put 'NOTE: Assumed failed job left behind a semaphore file... deleting... ';
					   File_RC=Resolve('%ULT_SemphoreRls(ULT_LibTable=&ULT_LibTable.)');
					End;
				Run;

				%Put NOTE: &ULT_Table. locked, waiting &ULT_SemaWaitTime. seconds ; 
				%Put NOTE: Iteration: &ULT_WaitCount. / &ULT_SemaWait.;

				Data _Null_;
					Rc=Sleep(&ULT_SemaWaitTime.,1);
				Run;

				* If we wait too long then we default to semaphore action 3 - Error;
				%If &ULT_SemaWait.>0 %then %Do;
					%If %eval(&ULT_WaitCount.>&ULT_SemaWait.) %Then %do;
						%Let ULT_SemaAction=3;
					%End;
				%End;
			%End;
			* Semaphore Action 2 = Continue processing ... ;
			%IF &ULT_SemaAction.=2 %Then %Do;
				%Put NOTE: No lock attained for &ULT_Table., continuing...; 
				%Let ULT_ContinueProcessing=Y;
			%End;
			* Semaphore Action 3 = Go to error ; 
			%IF &ULT_SemaAction.=3 %Then %Do;
				%Put ERROR: Lock not available for &ULT_Table.; 
				%Let ULT_SemError=1;
				%Goto ULT_EndOfMac;
			%End;
		%End;
	%End;

%ULT_EndOfMac:
	%If &ULT_SemError.=1 %then %Do;
		%Put ERROR: Aboring..; 
		data _null_;
			ABORT ABEND;
    	run;
	%End;

%Mend;
