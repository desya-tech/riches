Write-Host "Mulai Trigger Scanning Fortify"
# ------------==================== Fortify Parameter ====================------------ 
# SSC
Param (
	$URL_DAST_API = "https://10.30.100.57:85/api", 
	$URL_SSC = "https://10.30.100.55:8443/ssc", 
	$APITokenSSC = "NzNkYmQyNDMtMmZlYi00ZTQwLWEwMGUtZTVhYWFjMzZlNWJi", 
	$cicdToken="88c1853d-ce99-40fb-a836-aea40c68792e",
	$sc_url = "https://10.30.100.55:8443/scancentral-ctrl",
	$CIToken = "63770e04-fd31-465e-89e3-45336433095c"
	)

Write-Host "--- Start Script for Scanning Fortify DAST ---"
Write-Host "URL_DAST_API: $URL_DAST_API"
Write-Host "URL_SSC: $URL_SSC"
Write-Host "APITokenSSC: $APITokenSSC"
Write-Host "cicdToken: $cicdToken"

$url_dast="$URL_DAST_API/scans/start-scan-cicd"
$body='{
	"cicdToken": "' + $cicdToken + '"
}'
$Header= @{"Authorization" = "FortifyToken $APITokenSSC"}
$dastscanapp = Invoke-RestMethod -Method Post -Headers $Header -ContentType "application/json" -Body $body -uri $url_dast
$hasil_dastscanapp = $dastscanapp.id
Write-Host ("Scan ID: " + $hasil_dastscanapp)


# Cek Status scan WIE
$getstatus = "$URL_DAST_API/v2/scans/$hasil_dastscanapp/scan-summary"
$runstatus = Invoke-RestMethod -Method Get -Headers $Header -ContentType "application/json" -uri $getstatus
$projectVersionId = $runstatus.item.applicationVersionId
$projectVersionName = $runstatus.item.applicationVersionName
$appn = $runstatus.item.applicationName
$appid = $runstatus.item.applicationId
