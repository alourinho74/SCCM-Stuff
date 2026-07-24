echo "Starting WUA Recover" > c:\windows\temp\wua_recover.log

sc.exe sdset bits D:(A;;CCLCSWRPWPDTLOCRRC;;;SY)(A;;CCDCLCSWRPWPDTLOCRSDRCWDWO;;;BA)(A;;CCLCSWLOCRRC;;;AU)(A;;CCLCSWRPWPDTLOCRRC;;;PU)
sc.exe sdset wuauserv D:(A;;CCLCSWRPWPDTLOCRRC;;;SY)(A;;CCDCLCSWRPWPDTLOCRSDRCWDWO;;;BA)(A;;CCLCSWLOCRRC;;;AU)(A;;CCLCSWRPWPDTLOCRRC;;;PU)

cd /d %windir%\system32

regsvr32.exe atl.dll /s>> c:\windows\temp\wua_recover.log
regsvr32.exe urlmon.dll /s>> c:\windows\temp\wua_recover.log
regsvr32.exe mshtml.dll /s>> c:\windows\temp\wua_recover.log
regsvr32.exe shdocvw.dll /s>> c:\windows\temp\wua_recover.log
regsvr32.exe browseui.dll /s>> c:\windows\temp\wua_recover.log
regsvr32.exe jscript.dll /s>> c:\windows\temp\wua_recover.log
regsvr32.exe vbscript.dll /s>> c:\windows\temp\wua_recover.log
regsvr32.exe scrrun.dll /s>> c:\windows\temp\wua_recover.log
regsvr32.exe msxml.dll /s>> c:\windows\temp\wua_recover.log
regsvr32.exe msxml3.dll /s>> c:\windows\temp\wua_recover.log
regsvr32.exe msxml6.dll /s>> c:\windows\temp\wua_recover.log
regsvr32.exe actxprxy.dll /s>> c:\windows\temp\wua_recover.log
regsvr32.exe softpub.dll /s>> c:\windows\temp\wua_recover.log
regsvr32.exe wintrust.dll /s>> c:\windows\temp\wua_recover.log
regsvr32.exe dssenh.dll /s>> c:\windows\temp\wua_recover.log
regsvr32.exe rsaenh.dll /s>> c:\windows\temp\wua_recover.log
regsvr32.exe gpkcsp.dll /s>> c:\windows\temp\wua_recover.log
regsvr32.exe sccbase.dll /s>> c:\windows\temp\wua_recover.log
regsvr32.exe slbcsp.dll /s>> c:\windows\temp\wua_recover.log
regsvr32.exe cryptdlg.dll /s>> c:\windows\temp\wua_recover.log
regsvr32.exe oleaut32.dll /s>> c:\windows\temp\wua_recover.log
regsvr32.exe ole32.dll /s>> c:\windows\temp\wua_recover.log
regsvr32.exe shell32.dll /s>> c:\windows\temp\wua_recover.log
regsvr32.exe initpki.dll /s>> c:\windows\temp\wua_recover.log
regsvr32.exe wuapi.dll /s>> c:\windows\temp\wua_recover.log
regsvr32.exe wuaueng.dll /s>> c:\windows\temp\wua_recover.log
regsvr32.exe wuaueng1.dll /s>> c:\windows\temp\wua_recover.log
regsvr32.exe wucltui.dll /s>> c:\windows\temp\wua_recover.log
regsvr32.exe wups.dll /s>> c:\windows\temp\wua_recover.log
regsvr32.exe wups2.dll /s>> c:\windows\temp\wua_recover.log
regsvr32.exe wuweb.dll /s>> c:\windows\temp\wua_recover.log
regsvr32.exe qmgr.dll /s>> c:\windows\temp\wua_recover.log
regsvr32.exe qmgrprxy.dll /s>> c:\windows\temp\wua_recover.log
regsvr32.exe wucltux.dll /s>> c:\windows\temp\wua_recover.log
regsvr32.exe muweb.dll /s>> c:\windows\temp\wua_recover.log
regsvr32.exe wuwebv.dll /s>> c:\windows\temp\wua_recover.log

netsh winhttp reset proxy>> c:\windows\temp\wua_recover.log
