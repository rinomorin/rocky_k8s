# roles/win_k8s_ad_promotion/files/install_cri.ps1
$source = Get-ChildItem -Path "C:\staging\" -Filter "cri-dockerd.exe" -Recurse | Select-Object -First 1
$dest = "C:\Program Files\cri-dockerd\cri-dockerd.exe"
if (!(Test-Path "C:\Program Files\cri-dockerd")) { New-Item -ItemType Directory -Path "C:\Program Files\cri-dockerd" -Force }
Copy-Item -Path $source.FullName -Destination $dest -Force

Stop-Service -Name "cri-dockerd" -Force -ErrorAction SilentlyContinue
sc.exe delete "cri-dockerd"
$binPath = "$dest --container-runtime-endpoint npipe:////./pipe/cri-dockerd"
sc.exe create "cri-dockerd" binPath= "`"$binPath`"" start= auto obj= "LocalSystem"

$tmpCfg = "C:\Windows\Temp\privs.inf"
secedit /export /cfg $tmpCfg /areas USER_RIGHTS
(Get-Content $tmpCfg) -replace 'SeCreateGlobalPrivilege =', 'SeCreateGlobalPrivilege = *S-1-5-18,' | Set-Content $tmpCfg
secedit /configure /db C:\windows\security\database\edb.db /cfg $tmpCfg /areas USER_RIGHTS

Set-ItemProperty -Path HKLM:\SYSTEM\CurrentControlSet\Control -Name "ServicesPipeTimeout" -Value 60000
Start-Service -Name "cri-dockerd"