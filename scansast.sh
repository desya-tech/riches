#!/bin/bash

# =====================================================
# Jalankan ScanCentral dan tangkap output
# =====================================================
SCANCENTRAL_BUILD_OPTS="-bt none"
SSC_APP="riches"
SSC_PV="v1"
SSC_URL="http://192.168.0.11:9090/ssc"
SSC_TOKEN="9c9f379e-78e8-403d-aad8-bb9034b5f3a9"
SCANCENTRAL_VM_OPTS="-Dclient_auth_token=P@ssw0rd*123456"
apikey="OWM5ZjM3OWUtNzhlOC00MDNkLWFhZDgtYmI5MDM0YjVmM2E5"

output=$(/opt/Fortify/ScanCentral_Client_25.4.0/bin/scancentral \
  -sscurl "$SSC_URL" \
  -ssctoken "$SSC_TOKEN" \
  start $SCANCENTRAL_BUILD_OPTS \
  -upload \
  -application "$SSC_APP" \
  -version "$SSC_PV" \
  -uptoken "$SSC_TOKEN" 2>&1
)

# Debug log
echo "========== Log Output =========="
echo "$output"
echo "================================"

# =====================================================
# Ambil Job Token
# =====================================================
pattern='Submitted job and received token:\s+([0-9a-fA-F\-]{36})'

if [[ $output =~ $pattern ]]; then
    token="${BASH_REMATCH[1]}"
    echo "Job Token: $token"
else
    token=$(echo "$output" | grep -oP '(?<=Submitted job and received token:\s*)[a-f0-9\-]+')

    if [[ -n "$token" ]]; then
        echo "Job Token (grep fallback): $token"
    else
        echo "ERROR: Token tidak ditemukan"
        exit 1
    fi
fi

# =====================================================
# Cek Status Scan via SSC API
# =====================================================
cek_sast_api="$SSC_URL/api/v1/cloudjobs/$token"
jobState="PENDING"

echo "Menunggu hasil scan..."
sleep 30

while [[ "$jobState" == "PENDING" || "$jobState" == "SCAN_RUNNING" ]]; do
    sleep 30

    runstatus=$(curl --insecure -s -X GET \
        -H "Authorization: FortifyToken ${apikey}" \
        -H "Content-Type: application/json" \
        "$cek_sast_api"
    )

    jobState=$(echo "$runstatus" | grep -oP '"jobState":"\K[^"]+')
    echo "Status Scan: $jobState"
done

echo "Scan selesai dengan status: $jobState"

# =====================================================
# Ambil Informasi Project
# =====================================================
pvId=$(echo "$runstatus" | grep -oP '"pvId":\K\d+')
pvName=$(echo "$runstatus" | grep -oP '"pvName":"\K[^"]+')
projectName=$(echo "$runstatus" | grep -oP '"projectName":"\K[^"]+')

echo "Project Name        : $projectName"
echo "Project Version ID  : $pvId"
echo "Project Version Name: $pvName"

# =====================================================
# Ambil Summary Issue
# =====================================================
cekssc="$SSC_URL/api/v1/projectVersions/$pvId/issueSummaries?seriestype=ISSUE_FRIORITY&groupaxistype=ISSUE_FRIORITY"

runscan=$(curl --insecure -s -X GET \
    -H "Authorization: FortifyToken ${apikey}" \
    -H "Content-Type: application/json" \
    "$cekssc"
)

critical=$(echo "$runscan" | grep -oP '"Critical","y":\K[0-9]+')
high=$(echo "$runscan" | grep -oP '"High","y":\K[0-9]+')
medium=$(echo "$runscan" | grep -oP '"Medium","y":\K[0-9]+')
low=$(echo "$runscan" | grep -oP '"Low","y":\K[0-9]+')
total_issue=$(echo "$runscan" | grep -oP '"totalIssueCount":\K[0-9]+')

echo "========== Issue Summary =========="
echo "Critical : $critical"
echo "High     : $high"
echo "Medium   : $medium"
echo "Low      : $low"
echo "Total    : $total_issue"
echo "=================================="

echo "Detail vulnerability:"
echo "$SSC_URL/html/ssc/version/$pvId/audit"

# =====================================================
# Quality Gate
# =====================================================
if [[ "$critical" -gt 100 ]]; then
    echo "ERROR: Critical issue ($critical) melebihi batas!"
    exit 1
elif [[ "$high" -gt 100 ]]; then
    echo "ERROR: High issue ($high) melebihi batas!"
    exit 1
fi
