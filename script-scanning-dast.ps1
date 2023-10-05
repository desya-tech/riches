# Trigger Scan DAST
# Fullscan 2 hours: 1424f24b-9219-4ff8-a50a-60d1a6e5eb2e
# 7b4762ba-7c4e-45f8-a2ca-ba3a1f903f09
# crawl only: afe773a5-08ce-4821-adcc-84ecece5e5ce

Param (
	$URL_DAST_API = "https://10.30.100.57:85/api", 
	$URL_SSC = "https://10.30.100.55:8443/ssc", 
	$APITokenSSC = "NzNkYmQyNDMtMmZlYi00ZTQwLWEwMGUtZTVhYWFjMzZlNWJi", 
	$cicdToken="88c1853d-ce99-40fb-a836-aea40c68792e"
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
$statusscan = ""
$selesai = 1
$runstatus = Invoke-RestMethod -Method Get -Headers $Header -ContentType "application/json" -uri $getstatus
$projectVersionId = $runstatus.item.applicationVersionId
$projectVersionName = $runstatus.item.applicationVersionName
$appn = $runstatus.item.applicationName
$appid = $runstatus.item.applicationId
Invoke-Expression(Start-Process -FilePath "C:\Program Files\Fortify\Fortify_SCA_and_Apps_22.1.0\bin\scancentral.bat" -ArgumentList '-url "https://10.30.100.56:8443/scancentral-ctrl/" start -bt none -application "$appn" -version "$appid" -b riches_azure -upload -uptoken 63770e04-fd31-465e-89e3-45336433095c' -NoNewWindow -Wait)

