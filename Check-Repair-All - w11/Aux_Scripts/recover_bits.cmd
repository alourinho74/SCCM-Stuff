netsh http add iplisten ipaddress=127.0.0.1
sc.exe sdset PeerDistSvc D:(A;;CCLCSWRPWPDTLOCRRC;;;SY)(A;;CCDCLCSWRPWPDTLOCRSDRCWDWO;;;BA)(A;;CCLCSWLOCRRC;;;AU)(A;;CCLCSWRPWPDTLOCRRC;;;PU) 
netsh branchcache set service mode=DISTRIBUTED

