# ============================================
# 停止所有 MCP 服务器
# 功能：清理端口 3000-3013 上运行的所有进程
# ============================================

Write-Host "`n============================================" -ForegroundColor Yellow
Write-Host "  停止所有 MCP 服务器" -ForegroundColor Yellow
Write-Host "  扫描端口范围：3000-3013" -ForegroundColor Yellow
Write-Host "============================================`n" -ForegroundColor Yellow

$ports = 3000..3013
$stopped = 0
$not_found = 0
$errors = 0

foreach ($port in $ports) {
    try {
        # 查找占用端口的进程
        $connection = Get-NetTCPConnection -LocalPort $port -ErrorAction SilentlyContinue
        
        if ($connection) {
            $processId = $connection.OwningProcess
            $processName = (Get-Process -Id $processId -ErrorAction SilentlyContinue).ProcessName
            
            Write-Host "🛑 端口 $port - $processName (PID: $processId)" -ForegroundColor Yellow
            
            # 停止进程
            Stop-Process -Id $processId -Force -ErrorAction Stop
            Write-Host "   ✅ 已停止" -ForegroundColor Green
            $stopped++
        } else {
            Write-Host "❌ 端口 $port - 未运行" -ForegroundColor Gray
            $not_found++
        }
    }
    catch {
        Write-Host "   ❌ 错误：$_" -ForegroundColor Red
        $errors++
    }
}

Write-Host "`n============================================" -ForegroundColor Cyan
Write-Host "  执行结果" -ForegroundColor Cyan
Write-Host "============================================" -ForegroundColor Cyan
Write-Host "  已停止：$stopped 个服务" -ForegroundColor Green
Write-Host "  未运行：$not_found 个端口" -ForegroundColor Gray
if ($errors -gt 0) {
    Write-Host "  错误：$errors 个" -ForegroundColor Red
}
Write-Host "============================================`n" -ForegroundColor Cyan

# 验证是否还有残留进程
Write-Host "🔍 验证剩余进程..." -ForegroundColor Cyan
Start-Sleep -Milliseconds 500

$remaining = 0
foreach ($port in $ports) {
    $connection = Get-NetTCPConnection -LocalPort $port -ErrorAction SilentlyContinue
    if ($connection) {
        Write-Host "⚠️  端口 $port 仍有进程运行 (PID: $($connection.OwningProcess))" -ForegroundColor Yellow
        $remaining++
    }
}

if ($remaining -eq 0) {
    Write-Host "✅ 所有 MCP 服务器已成功停止！" -ForegroundColor Green
} else {
    Write-Host "⚠️  仍有 $remaining 个端口未被清理，请手动检查" -ForegroundColor Yellow
}

Write-Host "`n💡 提示：" -ForegroundColor Yellow
Write-Host "- 如需重新启动，请运行：.\start_all_mcp_quick.ps1" -ForegroundColor Gray
Write-Host "- 如需选择性启动，请运行：.\start_mcp_servers.ps1" -ForegroundColor Gray
