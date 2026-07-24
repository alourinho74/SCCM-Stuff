$global:aux_error = $false
$global:verify_monthly = $false
$global:verify_fu = $false
$global:chkdsk = $false
$global:userinfo = $false
$global:ComputerInfo = $false
#$global:restart_ccm_wua = $false

$global:win7 = "KB5022338" #WIn7 EOL
$global:WIn8= "KB5022352" # Win8_1 EOL
$global:Win101607 = "KB4503308"
$global:Win101703 = "KB4503308"
$global:Win101709 = "KB4580328"
$global:Win101803 = "KB5001339" #Win 10 1803 EOL
$global:Win101809 = "KB5099538" #Win 10 1809 (LTSC)
$global:Win101903 = "KB4574727"  #Win 10 1903 EOL
$global:Win101909 = "KB5013945" #Win 10  (EOL)
$global:Win102004 = "KB5010342" #Win 10 2004 (EOL)
$global:Win1020H2 = "KB5026361" #Win 10 20H2 (EOL)
$global:Win1021H1 = "KB5019959" #Win 10 21H1 (EOL)
$global:Win1021H2 = "KB5055518" #Win 10 21H2 (EOL)
$global:Win1021H2_LTSC = "KB5099539" #Win 10 21H2 (LTSC)
$global:Win1022H2 = "KB5066791" #Win 10 22H2 (EOL)
$global:Win1121H2 = "KB5022836" #Win 11 21H1 (EOL)
$global:Win1122H2 = "KB5032190" #Win 11 22H2 (EOL)
$global:Win1123H2 = "KB5053602" #Win 11 23H2 (EOL)
$global:Win1124H2 = "KB5101650" #Win 11 24H2
$global:Win1125H2 = "KB5101650" #Win 11 24H2


$global:catalogver = 3597

#Dezembro de 2022 não houve updates de office 2013 nem office 2016
#só houve de visio e project
#meti as variáveis de mês e last exatamente iguais
$global:Offices15 = ("KB5002514") #EOL
$global:Offices15_last = ("KB5002514") #EOL

$global:Offices16 = ("KB5002879","KB5002878","KB5002852","KB5002578","KB5002877")
$global:Offices16_last = ("KB5002865","KB5002866","KB5002858")

$global:dotnet_w11_higher25H2 = ("KB5100998")
$global:dotnet_w11_higher25H2_last = ("KB5087051")

$global:dotnet_w11_higher24H2 = ("KB5101001")
$global:dotnet_w11_higher24H2_last = ("KB5087054")

$global:dotnet_w11_higher23H2 = ("KB5049624")
$global:dotnet_w11_higher23H2_last = ("KB5045935")

$global:dotnet_w11_higher22H2 = ("KB5031323") #EOL
$global:dotnet_w11_higher22H2_last = ("KB5031217") #EOL

$global:dotnet_w11_higher21H2 = ("KB5022730") #EOL
$global:dotnet_w11_higher21H2_last = ("KB5021090") #EOL

$global:dotnet_w10_20H2 = ("KB5022727") #EOL
$global:dotnet_w10_20H2_last = ("KB5022727") #EOL

$global:dotnet_w10_21H1 = ("KB5022728") #EOL
$global:dotnet_w10_21H1_last = ("KB5020801") #EOL

$global:dotnet_w10_21H2 = ("KB5038284") #EOL
$global:dotnet_w10_21H2_last = ("KB5037035") #EOL

$global:dotnet_w10_21H2_LTSC = ("KB5088859")
$global:dotnet_w10_21H2_last_LTSC = ("KB5084067")

$global:dotnet_w10_22H2 = ("KB5066747")
$global:dotnet_w10_22H2_last = ("KB5065957")

$global:dotnet_w10_1909 = ("KB5013627") #EOL
$global:dotnet_w10_1909_last = ("KB5012120") #"KB5005541"

$global:dotnet_w10_1809 = ("KB5088864") #"KB5008879"
$global:dotnet_w10_1809_last = ("KB5084066") #"KB5005541"

$global:dotnet_w7 = ("KB5021091") #EOL
$global:dotnet_w7_last = ("KB5021091") #EOL

$global:dotnet_w8 = ("KB5021093") #EOL
$global:dotnet_w8_last = ("KB5021093") #EOL

#https://support.microsoft.com/en-us/topic/deploy-windows-malicious-software-removal-tool-in-an-enterprise-environment-kb891716-a10cc756-2b3b-32e3-9ee3-2c1298ea3538
#Subkey: HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\RemovalTools\MRT
#Entry name: Version
$global:Malicious = "5.142"
$global:Malicious_last = "5.141"
$global:Malicious_ID = "47387902-E7F0-4BD0-9AE0-66BB3FFB1831" #Version
$global:Malicious_Last_ID = "E5A88F48-4F1C-4AEA-90DD-3476F8988970"


#https://docs.microsoft.com/en-us/officeupdates/update-history-office-2013
$global:o365_current = "16.0.20026.20168"
$global:o365_current_last = "16.0.19929.20172"
$global:o365_monthly = "16.0.20026.20166"
$global:o365_monthly_last = "16.0.19929.20162"
$global:o365_C2R_v15 = "15.0.5589.1001" #EOL
$global:o365_C2R_v15_last = "15.0.5589.1001" #EOL

$global:office2007_last = "KB4018353"#EOL
$global:office2010_last = "KB4504738"#EOL
$global:office2013_last = "KB5002514"#EOL
$global:office2013_last_month = "KB5002514"#EOL
$global:office2016_last = "KB5002852"#EOL
$global:office2016_last_month = "KB5002866"#EOL



