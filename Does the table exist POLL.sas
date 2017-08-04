options nomprint nomlogic;

%Let _INPUT=WHTARGET.CC_Vault_Complete;
%Let ___MaxIterations=2;

%Macro Check_TablenPoll;

	%Let ___CheckTable=&_INPUT.;
	%Let ___CheckCount=0;
	%Let ___TableExists=%Sysfunc(Exist(&___CheckTable.));
	%Let ___MacError=0;

	%Do %While(^&___TableExists.);
		%Let ___TableExists=%Sysfunc(Exist(&___CheckTable.));
		%Let ___CheckCount=%Eval(&___CheckCount.+1);
		
		%Put NOTE: Table Exists &___TableExists.;

		%Put NOTE: &___CheckTable. Not Found;
		%Put NOTE: Waiting 5 minutes ...;
		%Put NOTE: Waited &___CheckCount. times;
		Data _Null_;
			Rc=Sleep(300,1);
		Run;

		%If &___MaxIterations.=&___CheckCount. %Then %Do;
			%Put ERROR: Exceeded allowable iterations ;
			%Let ___MacError=1;

			%Goto EndofMac;
		%End;
	%End;

%EndofMac:
	%If &___MacError. %Then %Do;
		%ABORT ABEND;
	%End;

	%Put NOTE: Found &___CheckTable., Continue... ;
%Mend;

%Check_TablenPoll;