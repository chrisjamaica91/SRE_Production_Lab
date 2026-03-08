# Traffic Generator for SLO Testing
# Generates a realistic mix of successful requests and errors

param(
    [int]$TotalRequests = 100,
    [int]$ErrorRate = 20,  # Percentage of requests that should error (0-100)
    [string]$BaseUrl = "http://localhost:8080"
)

Write-Host "🚀 Starting Traffic Generator" -ForegroundColor Cyan
Write-Host "Target: $BaseUrl" -ForegroundColor Cyan
Write-Host "Total Requests: $TotalRequests" -ForegroundColor Cyan
Write-Host "Error Rate: $ErrorRate%" -ForegroundColor Cyan
Write-Host "=" * 60

$successCount = 0
$errorCount = 0
$endpoints = @(
    @{ path = "/health"; weight = 30 },
    @{ path = "/api"; weight = 20 },
    @{ path = "/"; weight = 15 },
    @{ path = "/api/users"; weight = 15 },
    @{ path = "/ready"; weight = 10 },
    @{ path = "/api/simulate-latency?ms=500"; weight = 10 }
)

for ($i = 1; $i -le $TotalRequests; $i++) {
    # Determine if this request should be an error
    $shouldError = (Get-Random -Minimum 1 -Maximum 100) -le $ErrorRate
    
    if ($shouldError) {
        # Generate error
        try {
            $response = curl.exe -s -o $null -w "%{http_code}" "$BaseUrl/api/simulate-error" 2>$null
            $errorCount++
            Write-Host "[$i/$TotalRequests] ❌ Error: /api/simulate-error → $response" -ForegroundColor Red
        } catch {
            $errorCount++
            Write-Host "[$i/$TotalRequests] ❌ Error: /api/simulate-error → Failed" -ForegroundColor Red
        }
    } else {
        # Generate successful request - pick random endpoint
        $randomValue = Get-Random -Minimum 1 -Maximum 100
        $cumulative = 0
        $selectedEndpoint = $endpoints[0].path
        
        foreach ($endpoint in $endpoints) {
            $cumulative += $endpoint.weight
            if ($randomValue -le $cumulative) {
                $selectedEndpoint = $endpoint.path
                break
            }
        }
        
        try {
            $response = curl.exe -s -o $null -w "%{http_code}" "$BaseUrl$selectedEndpoint" 2>$null
            $successCount++
            Write-Host "[$i/$TotalRequests] ✅ Success: $selectedEndpoint → $response" -ForegroundColor Green
        } catch {
            Write-Host "[$i/$TotalRequests] ⚠️  Warning: $selectedEndpoint → Failed" -ForegroundColor Yellow
        }
    }
    
    # Small delay to avoid overwhelming the service
    Start-Sleep -Milliseconds 100
}

Write-Host ""
Write-Host "=" * 60
Write-Host "📊 Traffic Generation Complete" -ForegroundColor Cyan
Write-Host "✅ Successful Requests: $successCount" -ForegroundColor Green
Write-Host "❌ Failed Requests: $errorCount" -ForegroundColor Red
Write-Host "📈 Actual Error Rate: $([math]::Round(($errorCount / $TotalRequests) * 100, 2))%" -ForegroundColor Yellow
Write-Host ""
Write-Host "💡 Tip: Wait 30-60 seconds for Prometheus to scrape metrics, then check Grafana!" -ForegroundColor Cyan
