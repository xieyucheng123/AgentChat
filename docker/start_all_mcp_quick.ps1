# ============================================
# One-Click Quick Start for All MCP Servers
# Scenario: Quickly start all 14 Swagger files
# ============================================

# ============================================
# Configuration Parameters
# ============================================
$SCRIPT_DIR = Split-Path -Parent $MyInvocation.MyCommand.Path
$SWAGGER_DIR = Join-Path $SCRIPT_DIR "split_strategy_domain_threshold15"

# ============================================
# MCP Server List (14 files)
# ============================================
$mcp_servers = @(
    @{Name="Platform_CodeSystem"; Port=3000; File="swagger-Platform_CodeSystem.json"},
    @{Name="Meta"; Port=3001; File="swagger-Meta.json"},
    @{Name="Platform_Employee"; Port=3002; File="swagger-Platform_Employee.json"},
    @{Name="Platform_Permissions"; Port=3003; File="swagger-Platform_Permissions.json"},
    @{Name="Platform_Orginization"; Port=3004; File="swagger-Platform_Orginization.json"},
    @{Name="Employee_Sync"; Port=3005; File="swagger-Employee_Sync.json"},
    @{Name="CommonLib_Info"; Port=3006; File="swagger-CommonLib_Info.json"},
    @{Name="Form"; Port=3007; File="swagger-Form.json"},
    @{Name="Platform_Authority"; Port=3008; File="swagger-Platform_Authority.json"},
    @{Name="Module"; Port=3009; File="swagger-Module.json"},
    @{Name="Platform_Account"; Port=3010; File="swagger-Platform_Account.json"},
    @{Name="Form_Share"; Port=3011; File="swagger-Form_Share.json"},
    @{Name="System_DataItem"; Port=3012; File="swagger-System_DataItem.json"},
    @{Name="Others"; Port=3013; File="swagger-Others.json"}
)

# ============================================
# Main Program
# ============================================
Write-Host "`n============================================" -ForegroundColor Green
Write-Host "  One-Click Start All MCP Servers" -ForegroundColor Green
Write-Host "  Total: 14 Services (Ports 3000-3013)" -ForegroundColor Green
Write-Host "============================================`n" -ForegroundColor Green

# Check Swagger directory
if (-not (Test-Path $SWAGGER_DIR)) {
    Write-Host "Error: Swagger directory not found: $SWAGGER_DIR" -ForegroundColor Red
    exit 1
}

# Batch start
$success = 0
$failed = 0

foreach ($server in $mcp_servers) {
    $specPath = Join-Path $SWAGGER_DIR $server.File
    
    if (-not (Test-Path $specPath)) {
        Write-Host "File not found: $specPath" -ForegroundColor Red
        $failed++
        continue
    }
    
    Write-Host "`n[$($server.Name)] Starting on port $($server.Port)..." -ForegroundColor Cyan
    
    # Define parameters for the command
    $port = $server.Port
    $headers = '{"Authorization":"Bearer eyJhbGciOiJodHRwOi8vd3d3LnczLm9yZy8yMDAxLzA0L3htbGRzaWctbW9yZSNobWFjLXNoYTI1NiIsInR5cCI6IkpXVCJ9.eyJVc2VyT2lkIjoiMzRlYjU1OTYtNTdiNy00MDU2LWE1Y2QtMjRlYmE3ODAxMzJhIiwiTG9naW5JZCI6InN5c2FkbWluIiwiVXNlck5hbWUiOiLns7vnu5_nrqHnkIblkZgiLCJUb2tlbiI6IjczMmRlZDg2LTI3NTQtNDE4Mi04MTQ3LTY4YmM3MTczOTIyMyIsIkNyZWF0b3IiOiJzeXMiLCJDcmVhdGVUaW1lIjoiMjAyNi0wMy0xNyAxODoxMzowOSIsIlNjaGVtYSI6InBsbSIsIlBsYXRmb3JtIjoicGMiLCJFeHBpcmVzIjoiMjAyNi0wMy0yOSAxODoxMzowOSIsIm5iZiI6MTc3Mzc0MjM4OSwiZXhwIjoxNzc0Nzc5MTg5LCJpc3MiOiJXZWJBcHBJc3N1ZXIiLCJhdWQiOiJXZWJBcHBBdWRpZW5jZSJ9.SRrZ8dWaLaUzlsWz7zYY_iYOVQFeM1HW3lUu44xv4QA"}'
    $baseUrl = "https://huawei.yiban.com.cn/platform"
    
    # Create command using script block to avoid quote escaping issues
    $cmd = "& { npx -y @ivotoby/openapi-mcp-server --transport http --port $port --openapi-spec '$specPath' --api-base-url '$baseUrl' --headers '$headers' }"
    
    Write-Host "Starting service..." -ForegroundColor Gray
    
    # Start in background with ExecutionPolicy bypass and new window
    Start-Process powershell -ArgumentList "-ExecutionPolicy Bypass", "-WindowStyle Normal", "-NoExit", "-Command", $cmd
    
    Start-Sleep -Milliseconds 500  # Brief delay
    
    $success++
}

Write-Host "`n============================================" -ForegroundColor Green
Write-Host "  Start Complete!" -ForegroundColor Green
Write-Host "  Success: $success / Total: $($success + $failed)" -ForegroundColor Green
Write-Host "============================================`n" -ForegroundColor Green

Write-Host "Service List:" -ForegroundColor Cyan
Write-Host ""
foreach ($server in $mcp_servers) {
    Write-Host ("{0,-30} : Port {1}" -f $server.Name, $server.Port) -ForegroundColor White
}

Write-Host "`nTips:" -ForegroundColor Yellow
Write-Host "- Access Swagger UI: http://localhost:<PORT>/docs" -ForegroundColor Gray
Write-Host "- Stop all services: Run stop_mcp_servers.ps1" -ForegroundColor Gray
Write-Host "- Check processes: Get-NetTCPConnection -LocalPort 3000..3013" -ForegroundColor Gray
