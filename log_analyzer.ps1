# Log File Analyzer Script
# This script analyzes a log file and generates statistics and insights

# Configuration
$logFile = "logs.txt"
$outputFile = "log_analysis_report.txt"

# Function to count occurrences based on a pattern
function Count-Pattern {
    param (
        [string]$pattern
    )
    
    return (Select-String -Path $logFile -Pattern $pattern | Measure-Object).Count
}

# Clear the output file if it exists
if (Test-Path $outputFile) {
    Remove-Item $outputFile
}

# Start writing to the output file
Add-Content -Path $outputFile -Value "LOG FILE ANALYSIS REPORT"
Add-Content -Path $outputFile -Value "======================="
Add-Content -Path $outputFile -Value ""
Add-Content -Path $outputFile -Value "Generated on: $(Get-Date)"
Add-Content -Path $outputFile -Value ""

# 1. Request Counts
Add-Content -Path $outputFile -Value "1. REQUEST COUNTS"
Add-Content -Path $outputFile -Value "-----------------"

$totalRequests = (Get-Content $logFile | Measure-Object).Count
Add-Content -Path $outputFile -Value "Total Requests: $totalRequests"

$getRequests = Count-Pattern '"GET'
Add-Content -Path $outputFile -Value "GET Requests: $getRequests"

$postRequests = Count-Pattern '"POST'
Add-Content -Path $outputFile -Value "POST Requests: $postRequests"
Add-Content -Path $outputFile -Value ""

# 2. Unique IP Addresses
Add-Content -Path $outputFile -Value "2. UNIQUE IP ADDRESSES"
Add-Content -Path $outputFile -Value "---------------------"

# Extract all IP addresses
$ipAddresses = Get-Content $logFile | ForEach-Object {
    if ($_ -match "^(\d+\.\d+\.\d+\.\d+)") {
        $matches[1]
    }
} | Sort-Object -Unique

$uniqueIPs = $ipAddresses.Count
Add-Content -Path $outputFile -Value "Total Unique IP Addresses: $uniqueIPs"
Add-Content -Path $outputFile -Value ""
Add-Content -Path $outputFile -Value "Requests by IP Address:"

foreach ($ip in $ipAddresses) {
    $ipTotalRequests = (Select-String -Path $logFile -Pattern "^$ip" | Measure-Object).Count
    $ipGetRequests = (Select-String -Path $logFile -Pattern "^$ip.*GET" | Measure-Object).Count
    $ipPostRequests = (Select-String -Path $logFile -Pattern "^$ip.*POST" | Measure-Object).Count
    
    Add-Content -Path $outputFile -Value "IP: $ip - Total: $ipTotalRequests, GET: $ipGetRequests, POST: $ipPostRequests"
}
Add-Content -Path $outputFile -Value ""

# 3. Failure Requests
Add-Content -Path $outputFile -Value "3. FAILURE REQUESTS"
Add-Content -Path $outputFile -Value "------------------"

$failureRequests = Count-Pattern ' 4\d\d | 5\d\d '
$failurePercentage = [math]::Round(($failureRequests / $totalRequests) * 100, 2)

Add-Content -Path $outputFile -Value "Total Failure Requests (4xx and 5xx): $failureRequests"
Add-Content -Path $outputFile -Value "Failure Percentage: $failurePercentage%"
Add-Content -Path $outputFile -Value ""

# 4. Top User
Add-Content -Path $outputFile -Value "4. TOP USER"
Add-Content -Path $outputFile -Value "----------"

$topUser = $null
$maxRequests = 0

foreach ($ip in $ipAddresses) {
    $requestCount = (Select-String -Path $logFile -Pattern "^$ip" | Measure-Object).Count
    if ($requestCount -gt $maxRequests) {
        $maxRequests = $requestCount
        $topUser = $ip
    }
}

Add-Content -Path $outputFile -Value "Most Active IP: $topUser with $maxRequests requests"
Add-Content -Path $outputFile -Value ""

# 5. Daily Request Averages
Add-Content -Path $outputFile -Value "5. DAILY REQUEST AVERAGES"
Add-Content -Path $outputFile -Value "-------------------------"

# Extract all dates
$dates = Get-Content $logFile | ForEach-Object {
    if ($_ -match "\[(\d+/\w+/\d+)") {
        $matches[1]
    }
} | Sort-Object -Unique

$dayCount = $dates.Count
$dailyAverage = [math]::Round($totalRequests / $dayCount, 2)

Add-Content -Path $outputFile -Value "Number of Days: $dayCount"
Add-Content -Path $outputFile -Value "Average Requests per Day: $dailyAverage"
Add-Content -Path $outputFile -Value ""

# 6. Failure Analysis
Add-Content -Path $outputFile -Value "6. FAILURE ANALYSIS"
Add-Content -Path $outputFile -Value "------------------"

# Extract failure lines first
$failureLines = Get-Content $logFile | Where-Object { $_ -match " 4\d\d " -or $_ -match " 5\d\d " }

$dailyFailures = @{}

foreach ($line in $failureLines) {
    if ($line -match "\[(\d+/\w+/\d+)") {
        $date = $matches[1]
        if ($dailyFailures.ContainsKey($date)) {
            $dailyFailures[$date]++
        } else {
            $dailyFailures[$date] = 1
        }
    }
}

$highestFailureDay = $dailyFailures.GetEnumerator() | Sort-Object -Property Value -Descending | Select-Object -First 1

Add-Content -Path $outputFile -Value "Day with Highest Failures: $($highestFailureDay.Key) with $($highestFailureDay.Value) failures"
Add-Content -Path $outputFile -Value ""

# Additional Analysis

# Request by Hour
Add-Content -Path $outputFile -Value "ADDITIONAL ANALYSIS"
Add-Content -Path $outputFile -Value "==================="
Add-Content -Path $outputFile -Value ""
Add-Content -Path $outputFile -Value "REQUESTS BY HOUR"
Add-Content -Path $outputFile -Value "---------------"

$hourlyRequests = @{}

Get-Content $logFile | ForEach-Object {
    if ($_ -match "\[\d+/\w+/\d+:(\d+)") {
        $hour = $matches[1]
        if ($hourlyRequests.ContainsKey($hour)) {
            $hourlyRequests[$hour]++
        } else {
            $hourlyRequests[$hour] = 1
        }
    }
}

foreach ($hour in (0..23)) {
    $formattedHour = $hour.ToString("00")
    $count = if ($hourlyRequests.ContainsKey($formattedHour)) { $hourlyRequests[$formattedHour] } else { 0 }
    Add-Content -Path $outputFile -Value ("Hour {0}: {1} requests" -f $formattedHour, $count)
}
Add-Content -Path $outputFile -Value ""

# Status Codes Breakdown
Add-Content -Path $outputFile -Value "STATUS CODES BREAKDOWN"
Add-Content -Path $outputFile -Value "---------------------"

$statusCodes = @{}

Get-Content $logFile | ForEach-Object {
    if ($_ -match " (\d\d\d) ") {
        $statusCode = $matches[1]
        if ($statusCodes.ContainsKey($statusCode)) {
            $statusCodes[$statusCode]++
        } else {
            $statusCodes[$statusCode] = 1
        }
    }
}

foreach ($code in ($statusCodes.Keys | Sort-Object)) {
    $percentage = [math]::Round(($statusCodes[$code] / $totalRequests) * 100, 2)
    Add-Content -Path $outputFile -Value ("Status Code {0}: {1} requests ({2}%)" -f $code, $statusCodes[$code], $percentage)
}
Add-Content -Path $outputFile -Value ""

# Most Active User by Method
Add-Content -Path $outputFile -Value "MOST ACTIVE USER BY METHOD"
Add-Content -Path $outputFile -Value "-------------------------"

$topGetUser = $null
$maxGetRequests = 0
$topPostUser = $null
$maxPostRequests = 0

foreach ($ip in $ipAddresses) {
    $getCount = (Select-String -Path $logFile -Pattern "^$ip.*GET" | Measure-Object).Count
    if ($getCount -gt $maxGetRequests) {
        $maxGetRequests = $getCount
        $topGetUser = $ip
    }
    
    $postCount = (Select-String -Path $logFile -Pattern "^$ip.*POST" | Measure-Object).Count
    if ($postCount -gt $maxPostRequests) {
        $maxPostRequests = $postCount
        $topPostUser = $ip
    }
}

Add-Content -Path $outputFile -Value "Most Active GET User: $topGetUser with $maxGetRequests GET requests"
Add-Content -Path $outputFile -Value "Most Active POST User: $topPostUser with $maxPostRequests POST requests"
Add-Content -Path $outputFile -Value ""

# Patterns in Failure Requests
Add-Content -Path $outputFile -Value "PATTERNS IN FAILURE REQUESTS"
Add-Content -Path $outputFile -Value "--------------------------"

# Failures by hour
$hourlyFailures = @{}

foreach ($line in $failureLines) {
    if ($line -match "\[\d+/\w+/\d+:(\d+)") {
        $hour = $matches[1]
        if ($hour -ne $null) {
            if ($hourlyFailures.ContainsKey($hour)) {
                $hourlyFailures[$hour]++
            } else {
                $hourlyFailures[$hour] = 1
            }
        }
    }
}

$highestFailureHour = $hourlyFailures.GetEnumerator() | Sort-Object -Property Value -Descending | Select-Object -First 1

if ($highestFailureHour) {
    Add-Content -Path $outputFile -Value "Hour with Highest Failures: $($highestFailureHour.Key) with $($highestFailureHour.Value) failures"
} else {
    Add-Content -Path $outputFile -Value "No hour with failures found"
}

# Failures by IP
$ipFailures = @{}

# Extract IPs associated with failure requests
foreach ($line in $failureLines) {
    if ($line -match "^(\d+\.\d+\.\d+\.\d+)") {
        $ip = $matches[1]
        if ($ip -ne $null) {
            if ($ipFailures.ContainsKey($ip)) {
                $ipFailures[$ip]++
            } else {
                $ipFailures[$ip] = 1
            }
        }
    }
}

$highestFailureIP = $ipFailures.GetEnumerator() | Sort-Object -Property Value -Descending | Select-Object -First 1

if ($highestFailureIP) {
    Add-Content -Path $outputFile -Value "IP with Most Failures: $($highestFailureIP.Key) with $($highestFailureIP.Value) failures"
} else {
    Add-Content -Path $outputFile -Value "No IPs with failures found"
}

Add-Content -Path $outputFile -Value ""

# Request Trends and Analysis Suggestions
Add-Content -Path $outputFile -Value "ANALYSIS SUGGESTIONS"
Add-Content -Path $outputFile -Value "===================="
Add-Content -Path $outputFile -Value ""
Add-Content -Path $outputFile -Value "Based on the log analysis, here are some insights and suggestions:"
Add-Content -Path $outputFile -Value ""
Add-Content -Path $outputFile -Value "1. Traffic Patterns:"
Add-Content -Path $outputFile -Value "   - Peak hours: Look at the hourly distribution to identify high traffic periods"
Add-Content -Path $outputFile -Value "   - Consider scaling resources during peak hours to handle increased load"
Add-Content -Path $outputFile -Value ""
Add-Content -Path $outputFile -Value "2. Error Management:"

if ($highestFailureHour) {
    Add-Content -Path $outputFile -Value "   - Focus on reducing errors during hour $($highestFailureHour.Key), which has the highest failure rate"
}
Add-Content -Path $outputFile -Value "   - Investigate common causes for status codes with high occurrence rates"
Add-Content -Path $outputFile -Value ""
Add-Content -Path $outputFile -Value "3. Security Considerations:"
Add-Content -Path $outputFile -Value "   - Monitor IP $topUser making $maxRequests requests for potential abuse or bot activity"

if ($highestFailureIP) {
    Add-Content -Path $outputFile -Value "   - Check IP $($highestFailureIP.Key) with high failure counts for potential malicious activity"
}

Add-Content -Path $outputFile -Value ""
Add-Content -Path $outputFile -Value "4. System Improvements:"
Add-Content -Path $outputFile -Value "   - Consider implementing rate limiting for IPs with unusually high request counts"

if ($highestFailureDay) {
    Add-Content -Path $outputFile -Value "   - Review server configuration on days with high failure rates ($($highestFailureDay.Key))"
}
Add-Content -Path $outputFile -Value "   - Monitor POST requests closely, especially from $topPostUser"
Add-Content -Path $outputFile -Value ""

Write-Host "Analysis complete! Report has been saved to $outputFile" 