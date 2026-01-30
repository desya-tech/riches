#!/bin/bash
# LAB Kantor
#URL_DAST_API="https://fortify-dast.kikoichi.dev/api"
#URL_SSC="http://10.100.34.250:8280/ssc"
#SSC_TOKEN="NTc2MmRjMjktZDljYS00MTQzLTg3MmQtMzg4NjdlYTk1MjQ0"
#CICD_TOKEN="0089792b-7449-4d6d-b57e-d6a842b340f0"

#Local Lab Desya
URL_DAST_API="http://192.168.0.11:9191/api"
URL_SSC="http://192.168.0.11:9090/ssc"
SSC_TOKEN="ZWRlMTY2MGUtNTJlZS00OGMwLThiMzUtNWRlZWNmNGQ4MzQ4"
CICD_TOKEN="ca9b7286-620a-4f2b-931d-f7819f8abea2"

echo "--- Start DAST Scan ---"

# Trigger DAST scan
url_dast="$URL_DAST_API/v2/scans/start-scan-cicd"
body="{\"cicdToken\": \"$CICD_TOKEN\", \"name\": \"Scanning from GitLab CI/CD\"}"

output=$(curl --insecure -s -X POST "$url_dast" \
    -H "Authorization: FortifyToken $SSC_TOKEN" \
    -H "Content-Type: application/json" \
    -d "$body")

echo "Log Output:"
echo "$output"

# Ambil Scan ID dari output
pattern='"id":([0-9]+)'
if [[ $output =~ $pattern ]]; then
    scan_id="${BASH_REMATCH[1]}"
    echo "Scan ID: $scan_id"
else
    scan_id=$(echo "$output" | grep -oP '"id":\K[0-9]+')
    if [[ -n "$scan_id" ]]; then
        echo "Scan ID (grep method): $scan_id"
    else
        echo "No Scan ID found."
        exit 1
    fi
fi

# Cek status scan
status_url="$URL_DAST_API/v2/scans/$scan_id/scan-summary"
status="Running"

echo "Menunggu hasil scan..."
sleep 60
while [[ "$status" != "Complete" ]]; do
    sleep 30
    runstatus=$(curl --insecure -s -X GET "$status_url" \
        -H "Authorization: FortifyToken $SSC_TOKEN" \
        -H "Content-Type: application/json")
    status=$(echo "$runstatus" | grep -oP '"scanStatusTypeDescription":"\K[^"]+')
    projectVersionId=$(echo "$runstatus" | grep -oP '"applicationVersionId":\K[0-9]+')
    projectVersionName=$(echo "$runstatus" | grep -oP '"applicationVersionName":"\K[^"]+')
    projectName=$(echo "$runstatus" | grep -oP '"applicationName":"\K[^"]+')

    echo "Status Scan: $status"
done

echo "Scan selesai dengan status: $status"
echo "Project Version ID: $projectVersionId"
echo "Project Version Name: $projectVersionName"
echo "Project Name: $projectName"

# Publish hasil scan ke SSC
echo "--- Publish Scan ---"
curl --insecure -s -X POST "$URL_DAST_API/v2/scans/$scan_id/scan-action" \
    -H "Authorization: FortifyToken $SSC_TOKEN" \
    -H "Content-Type: application/json" \
    -d '{"ScanActionType":5}'
sleep 60

# Cek hasil severity dari SSC
cekssc="$URL_SSC/api/v1/projectVersions/$projectVersionId/issueSummaries?seriestype=ISSUE_FRIORITY&groupaxistype=ISSUE_FRIORITY"
runscan=$(curl --insecure -s -X GET \
        -H "Authorization: FortifyToken $SSC_TOKEN" \
        -H "Content-Type: application/json" \
        "$cekssc")

critical=$(echo "$runscan" | grep -oP '"Critical","y":\K[0-9]+')
high=$(echo "$runscan" | grep -oP '"High","y":\K[0-9]+')
medium=$(echo "$runscan" | grep -oP '"Medium","y":\K[0-9]+')
low=$(echo "$runscan" | grep -oP '"Low","y":\K[0-9]+')
total_issue=$(echo "$runscan" | grep -oP '"totalIssueCount":\K[0-9]+')

echo "Critical: $critical"
echo "High: $high"
echo "Medium: $medium"
echo "Low: $low"
echo "Total Issue Count: $total_issue"

echo "Untuk detail vulnerability dapat dilihat pada: $URL_SSC/html/ssc/version/$projectVersionId/audit"

if [[ "$critical" -gt 50 ]]; then
        echo "ERROR: Jumlah isu Critical ($critical) melebihi batas! Pipeline dihentikan."
        exit 1
elif [[ "$high" -gt 100 ]]; then
        echo "ERROR: Jumlah isu High ($high) melebihi batas! Pipeline dihentikan."
        exit 1
fi
