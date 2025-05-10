#!/bin/bash

# Log File Analyzer Script
# This script analyzes a log file and generates statistics and insights

# Configuration
LOG_FILE="logs.txt"
OUTPUT_FILE="log_analysis_report.txt"

# Clear the output file if it exists
if [ -f "$OUTPUT_FILE" ]; then
    rm "$OUTPUT_FILE"
fi

# Function to count occurrences based on a pattern
count_pattern() {
    grep -c "$1" "$LOG_FILE"
}

# Start writing to the output file
echo "LOG FILE ANALYSIS REPORT" > "$OUTPUT_FILE"
echo "=======================" >> "$OUTPUT_FILE"
echo "" >> "$OUTPUT_FILE"
echo "Generated on: $(date)" >> "$OUTPUT_FILE"
echo "" >> "$OUTPUT_FILE"

# 1. Request Counts
echo "1. REQUEST COUNTS" >> "$OUTPUT_FILE"
echo "-----------------" >> "$OUTPUT_FILE"

TOTAL_REQUESTS=$(wc -l < "$LOG_FILE")
echo "Total Requests: $TOTAL_REQUESTS" >> "$OUTPUT_FILE"

GET_REQUESTS=$(count_pattern "\"GET")
echo "GET Requests: $GET_REQUESTS" >> "$OUTPUT_FILE"

POST_REQUESTS=$(count_pattern "\"POST")
echo "POST Requests: $POST_REQUESTS" >> "$OUTPUT_FILE"
echo "" >> "$OUTPUT_FILE"

# 2. Unique IP Addresses
echo "2. UNIQUE IP ADDRESSES" >> "$OUTPUT_FILE"
echo "---------------------" >> "$OUTPUT_FILE"

# Extract all unique IP addresses
IP_ADDRESSES=$(grep -o "^[0-9]\+\.[0-9]\+\.[0-9]\+\.[0-9]\+" "$LOG_FILE" | sort -u)
UNIQUE_IPS=$(echo "$IP_ADDRESSES" | wc -l)

echo "Total Unique IP Addresses: $UNIQUE_IPS" >> "$OUTPUT_FILE"
echo "" >> "$OUTPUT_FILE"
echo "Requests by IP Address:" >> "$OUTPUT_FILE"

# Loop through each unique IP to count requests
echo "$IP_ADDRESSES" | while read -r ip; do
    IP_TOTAL=$(grep -c "^$ip" "$LOG_FILE")
    IP_GET=$(grep "^$ip" "$LOG_FILE" | grep -c "\"GET")
    IP_POST=$(grep "^$ip" "$LOG_FILE" | grep -c "\"POST")
    
    echo "IP: $ip - Total: $IP_TOTAL, GET: $IP_GET, POST: $IP_POST" >> "$OUTPUT_FILE"
done
echo "" >> "$OUTPUT_FILE"

# 3. Failure Requests
echo "3. FAILURE REQUESTS" >> "$OUTPUT_FILE"
echo "------------------" >> "$OUTPUT_FILE"

FAILURE_REQUESTS=$(grep -E " [45][0-9][0-9] " "$LOG_FILE" | wc -l)
FAILURE_PERCENTAGE=$(echo "scale=2; ($FAILURE_REQUESTS / $TOTAL_REQUESTS) * 100" | bc)

echo "Total Failure Requests (4xx and 5xx): $FAILURE_REQUESTS" >> "$OUTPUT_FILE"
echo "Failure Percentage: $FAILURE_PERCENTAGE%" >> "$OUTPUT_FILE"
echo "" >> "$OUTPUT_FILE"

# 4. Top User
echo "4. TOP USER" >> "$OUTPUT_FILE"
echo "----------" >> "$OUTPUT_FILE"

TOP_USER=$(grep -o "^[0-9]\+\.[0-9]\+\.[0-9]\+\.[0-9]\+" "$LOG_FILE" | sort | uniq -c | sort -nr | head -1)
TOP_USER_IP=$(echo "$TOP_USER" | awk '{print $2}')
TOP_USER_COUNT=$(echo "$TOP_USER" | awk '{print $1}')

echo "Most Active IP: $TOP_USER_IP with $TOP_USER_COUNT requests" >> "$OUTPUT_FILE"
echo "" >> "$OUTPUT_FILE"

# 5. Daily Request Averages
echo "5. DAILY REQUEST AVERAGES" >> "$OUTPUT_FILE"
echo "-------------------------" >> "$OUTPUT_FILE"

# Extract all unique dates
DATES=$(grep -o "\[[0-9]\+/[A-Za-z]\+/[0-9]\+" "$LOG_FILE" | sort -u | wc -l)
DAILY_AVERAGE=$(echo "scale=2; $TOTAL_REQUESTS / $DATES" | bc)

echo "Number of Days: $DATES" >> "$OUTPUT_FILE"
echo "Average Requests per Day: $DAILY_AVERAGE" >> "$OUTPUT_FILE"
echo "" >> "$OUTPUT_FILE"

# 6. Failure Analysis
echo "6. FAILURE ANALYSIS" >> "$OUTPUT_FILE"
echo "------------------" >> "$OUTPUT_FILE"

# Find the day with highest failures
HIGHEST_FAILURE_DAY=$(grep -E " [45][0-9][0-9] " "$LOG_FILE" | grep -o "\[[0-9]\+/[A-Za-z]\+/[0-9]\+" | sort | uniq -c | sort -nr | head -1)
HIGHEST_FAILURE_DAY_DATE=$(echo "$HIGHEST_FAILURE_DAY" | awk '{print $2}' | sed 's/\[//')
HIGHEST_FAILURE_DAY_COUNT=$(echo "$HIGHEST_FAILURE_DAY" | awk '{print $1}')

echo "Day with Highest Failures: $HIGHEST_FAILURE_DAY_DATE with $HIGHEST_FAILURE_DAY_COUNT failures" >> "$OUTPUT_FILE"
echo "" >> "$OUTPUT_FILE"

# Additional Analysis

# Request by Hour
echo "ADDITIONAL ANALYSIS" >> "$OUTPUT_FILE"
echo "===================" >> "$OUTPUT_FILE"
echo "" >> "$OUTPUT_FILE"
echo "REQUESTS BY HOUR" >> "$OUTPUT_FILE"
echo "---------------" >> "$OUTPUT_FILE"

# Count requests by hour
for hour in $(seq -w 0 23); do
    HOUR_COUNT=$(grep -o "\[[0-9]\+/[A-Za-z]\+/[0-9]\+:$hour:" "$LOG_FILE" | wc -l)
    echo "Hour $hour: $HOUR_COUNT requests" >> "$OUTPUT_FILE"
done
echo "" >> "$OUTPUT_FILE"

# Status Codes Breakdown
echo "STATUS CODES BREAKDOWN" >> "$OUTPUT_FILE"
echo "---------------------" >> "$OUTPUT_FILE"

# Extract all status codes and count them
grep -o " [0-9]\{3\} " "$LOG_FILE" | sort | uniq -c | sort -k2n | while read -r line; do
    STATUS_CODE_COUNT=$(echo "$line" | awk '{print $1}')
    STATUS_CODE=$(echo "$line" | awk '{print $2}')
    PERCENTAGE=$(echo "scale=2; ($STATUS_CODE_COUNT / $TOTAL_REQUESTS) * 100" | bc)
    
    echo "Status Code $STATUS_CODE: $STATUS_CODE_COUNT requests ($PERCENTAGE%)" >> "$OUTPUT_FILE"
done
echo "" >> "$OUTPUT_FILE"

# Most Active User by Method
echo "MOST ACTIVE USER BY METHOD" >> "$OUTPUT_FILE"
echo "-------------------------" >> "$OUTPUT_FILE"

# Most active GET user
TOP_GET_USER=$(grep "\"GET" "$LOG_FILE" | grep -o "^[0-9]\+\.[0-9]\+\.[0-9]\+\.[0-9]\+" | sort | uniq -c | sort -nr | head -1)
TOP_GET_USER_IP=$(echo "$TOP_GET_USER" | awk '{print $2}')
TOP_GET_USER_COUNT=$(echo "$TOP_GET_USER" | awk '{print $1}')

# Most active POST user
TOP_POST_USER=$(grep "\"POST" "$LOG_FILE" | grep -o "^[0-9]\+\.[0-9]\+\.[0-9]\+\.[0-9]\+" | sort | uniq -c | sort -nr | head -1)
TOP_POST_USER_IP=$(echo "$TOP_POST_USER" | awk '{print $2}')
TOP_POST_USER_COUNT=$(echo "$TOP_POST_USER" | awk '{print $1}')

echo "Most Active GET User: $TOP_GET_USER_IP with $TOP_GET_USER_COUNT GET requests" >> "$OUTPUT_FILE"
echo "Most Active POST User: $TOP_POST_USER_IP with $TOP_POST_USER_COUNT POST requests" >> "$OUTPUT_FILE"
echo "" >> "$OUTPUT_FILE"

# Patterns in Failure Requests
echo "PATTERNS IN FAILURE REQUESTS" >> "$OUTPUT_FILE"
echo "--------------------------" >> "$OUTPUT_FILE"

# Failures by hour
HIGHEST_FAILURE_HOUR=$(grep -E " [45][0-9][0-9] " "$LOG_FILE" | grep -o "\[[0-9]\+/[A-Za-z]\+/[0-9]\+:\([0-9]\+\)" | awk -F: '{print $NF}' | sort | uniq -c | sort -nr | head -1)
HIGHEST_FAILURE_HOUR_TIME=$(echo "$HIGHEST_FAILURE_HOUR" | awk '{print $2}')
HIGHEST_FAILURE_HOUR_COUNT=$(echo "$HIGHEST_FAILURE_HOUR" | awk '{print $1}')

echo "Hour with Highest Failures: $HIGHEST_FAILURE_HOUR_TIME with $HIGHEST_FAILURE_HOUR_COUNT failures" >> "$OUTPUT_FILE"

# Failures by IP
HIGHEST_FAILURE_IP=$(grep -E " [45][0-9][0-9] " "$LOG_FILE" | grep -o "^[0-9]\+\.[0-9]\+\.[0-9]\+\.[0-9]\+" | sort | uniq -c | sort -nr | head -1)
HIGHEST_FAILURE_IP_ADDR=$(echo "$HIGHEST_FAILURE_IP" | awk '{print $2}')
HIGHEST_FAILURE_IP_COUNT=$(echo "$HIGHEST_FAILURE_IP" | awk '{print $1}')

echo "IP with Most Failures: $HIGHEST_FAILURE_IP_ADDR with $HIGHEST_FAILURE_IP_COUNT failures" >> "$OUTPUT_FILE"
echo "" >> "$OUTPUT_FILE"

# Request Trends and Analysis Suggestions
echo "ANALYSIS SUGGESTIONS" >> "$OUTPUT_FILE"
echo "====================" >> "$OUTPUT_FILE"
echo "" >> "$OUTPUT_FILE"
echo "Based on the log analysis, here are some insights and suggestions:" >> "$OUTPUT_FILE"
echo "" >> "$OUTPUT_FILE"
echo "1. Traffic Patterns:" >> "$OUTPUT_FILE"
echo "   - Peak hours: Look at the hourly distribution to identify high traffic periods" >> "$OUTPUT_FILE"
echo "   - Consider scaling resources during peak hours to handle increased load" >> "$OUTPUT_FILE"
echo "" >> "$OUTPUT_FILE"
echo "2. Error Management:" >> "$OUTPUT_FILE"
echo "   - Focus on reducing errors during hour $HIGHEST_FAILURE_HOUR_TIME, which has the highest failure rate" >> "$OUTPUT_FILE"
echo "   - Investigate common causes for status codes with high occurrence rates" >> "$OUTPUT_FILE"
echo "" >> "$OUTPUT_FILE"
echo "3. Security Considerations:" >> "$OUTPUT_FILE"
echo "   - Monitor IP $TOP_USER_IP making $TOP_USER_COUNT requests for potential abuse or bot activity" >> "$OUTPUT_FILE"
echo "   - Check IP $HIGHEST_FAILURE_IP_ADDR with high failure counts for potential malicious activity" >> "$OUTPUT_FILE"
echo "" >> "$OUTPUT_FILE"
echo "4. System Improvements:" >> "$OUTPUT_FILE"
echo "   - Consider implementing rate limiting for IPs with unusually high request counts" >> "$OUTPUT_FILE"
echo "   - Review server configuration on days with high failure rates ($HIGHEST_FAILURE_DAY_DATE)" >> "$OUTPUT_FILE"
echo "   - Monitor POST requests closely, especially from $TOP_POST_USER_IP" >> "$OUTPUT_FILE"
echo "" >> "$OUTPUT_FILE"

echo "Analysis complete! Report has been saved to $OUTPUT_FILE" 