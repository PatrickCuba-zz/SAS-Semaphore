%Macro RN_LockDS(DS=);

	%Put NOTE: Attempting to lock &DS. for exclusive use ;
	Lock &DS.;
	%Let ___Syslockcount=0;
	%Put syslckrc=&syslckrc.;

	%Do %While(&syslckrc.^=0);
		%Put NOTE: Attempting to lock &DS. for exclusive use again (count=&___Syslockcount.) ;

		Data _Null_;
			Rc=Sleep(3,1);
		Run;
		%Let ___Syslockcount=%Eval(&___Syslockcount.+1);

		Lock &DS.;
		%Put syslckrc=&syslckrc. ;

		%If &___Syslockcount.=10 %Then %Do;
			%Put ERROR: Cannot lock &DS., existing...;
			%Goto ExistMac;
		%End;
	%End;

%ExistMac:
%Mend;

