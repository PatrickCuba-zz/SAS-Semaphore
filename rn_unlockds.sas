%Macro RN_UnLockDS(DS=);
	Lock &DS. Clear;

%Mend;
