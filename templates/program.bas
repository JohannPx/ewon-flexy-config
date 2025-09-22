Rem --- eWON start section: Init Section
eWON_init_section:
Rem --- eWON user (start)
//************Configuration************
//{AccountName}
author$ = "{AccountAuthorization}"
//*****************Fin*****************
SETSYS INF, "LOAD"
SN$ = GETSYS INF, "SerNum"
SETSYS SYS, "LOAD"
SETSYS SYS, "UTCExport", "1"
SETSYS SYS, "PrgAutorun", "1"
SETSYS SYS, "BasicChunkedOff", "0"
SETSYS SYS, "save"
CFGSAVE
ONDATE 1,"*/10 * * * *","GOTO push"
push:
@Upload%(author$,SN$)
Rem --- eWON user (end)
End
Rem --- eWON end section: Init Section
Rem --- eWON start section: Function section
Rem --- eWON user (start)
//Upload DATA
FUNCTION Upload%($Author$,$id$)
  $EwonTime$ = TIME$
  $dt$ = $EwonTime$(1 To 2) + $EwonTime$(4 To 5) + $EwonTime$(7 To 10) + "_" + $EwonTime$(12 To 13) + $EwonTime$(15 To 16)+ $EwonTime$(18 To 19)
  $filename$ = $dt$ + "_" + $id$ + ".csv"
  $url$ = "https://push.myclauger.com/csv.php"
  $headers$ = "Authorization=Basic " + $Author$
  REQUESTHTTPX $url$,"POST",$headers$,"","file=[$dtHT$stL$et_0$ut$fn" + $filename$ + "]"
ENDFN
Rem --- eWON user (end)
End
Rem --- eWON end section: Function section