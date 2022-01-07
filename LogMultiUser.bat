REM Logon mulitple users for some load testing.
@Echo Off
SetLocal EnableDelayedExpansion
SET "server=10.20.1.115"
SET "var0=user"
SET "var1=user"
SET "var2=user"
SET "var3=user"
SET "var4=user"
SET "var5=user"
SET "var6=user"
SET "var7=user"
SET "var8=user"
SET "var9=user"
SET "var10=user"
SET "password=*****"
set max=11
For /L %%i in (1,1,%max%) Do ( 
  cmdkey /generic:TERMSRV/%Server% /user:!var%%i! /pass:%password%
  start mstsc /v:%Server%
  ping 1.1.1.1 -n 1 -w 5000 > nul
)
EndLocal 
