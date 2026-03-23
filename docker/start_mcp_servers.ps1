# ============================================
# Swagger 文件批量启动脚本（基于 @ivotoby/openapi-mcp-server）
# 使用场景：批量启动按业务域拆分的 Swagger 文件
# 拆分策略：阈值=15 平衡模式
# ============================================

# ============================================
# 通用环境变量配置
# ============================================
$env:NODE_TLS_REJECT_UNAUTHORIZED="0"
$env:API_BASE_URL="https://huawei.yiban.com.cn/platform"
$env:API_HEADERS='{"Authorization":"Bearer eyJhbGciOiJodHRwOi8vd3d3LnczLm9yZy8yMDAxLzA0L3htbGRzaWctbW9yZSNobWFjLXNoYTI1NiIsInR5cCI6IkpXVCJ9.eyJVc2VyT2lkIjoiMzRlYjU1OTYtNTdiNy00MDU2LWE1Y2QtMjRlYmE3ODAxMzJhIiwiTG9naW5JZCI6InN5c2FkbWluIiwiVXNlck5hbWUiOiLns7vnu5_nrqHnkIblkZgiLCJUb2tlbiI6IjczMmRlZDg2LTI3NTQtNDE4Mi04MTQ3LTY4YmM3MTczOTIyMyIsIkNyZWF0b3IiOiJzeXMiLCJDcmVhdGVUaW1lIjoiMjAyNi0wMy0xNyAxODoxMzowOSIsIlNjaGVtYSI6InBsbSIsIlBsYXRmb3JtIjoicGMiLCJFeHBpcmVzIjoiMjAyNi0wMy0yOSAxODoxMzowOSIsIm5iZiI6MTc3Mzc0MjM4OSwiZXhwIjoxNzc0Nzc5MTg5LCJpc3MiOiJXZWJBcHBJc3N1ZXIiLCJhdWQiOiJXZWJBcHBBdWRpZW5jZSJ9.SRrZ8dWaLaUzlsWz7zYY_iYOVQFeM1HW3lUu44xv4QA"}'

# ============================================
# 配置参数
# ============================================
$SCRIPT_DIR = Split-Path -Parent $MyInvocation.MyCommand.Path
$SWAGGER_DIR = Join-Path $SCRIPT_DIR "split_strategy_domain_threshold15"
$BASE_PORT = 3000  # 起始端口号

# ============================================
# 核心大模块配置（13 个独立业务域）
# ============================================
$core_modules = @(
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
    @{Name="System_DataItem"; Port=3012; File="swagger-System_DataItem.json"}
)

# ============================================
# Others 模块配置（包含 34 个小模块）
# ============================================
$others_module = @{Name="Others"; Port=3013; File="swagger-Others.json"}

# ============================================
# 函数：启动单个 MCP 服务器
# ============================================
function Start-MCPServer {
    param(
        [string]$Name,
        [int]$Port,
        [string]$File
    )
    
    $specPath = Join-Path $SWAGGER_DIR $File
    
    if (-not (Test-Path $specPath)) {
        Write-Host "❌ 文件不存在：$specPath" -ForegroundColor Red
        return $false
    }
    
    Write-Host "`n🚀 启动 [$Name] MCP 服务器..." -ForegroundColor Cyan
    Write-Host "   端口：$Port" -ForegroundColor Gray
    Write-Host "   文件：$File" -ForegroundColor Gray
    
    # 构建启动命令
    $cmd = "npx -y @ivotoby/openapi-mcp-server --transport http --port $Port --openapi-spec `"$specPath`" --api-base-url `$env:API_BASE_URL --headers `$env:API_HEADERS"
    
    Write-Host "   命令：$cmd" -ForegroundColor Gray
    
    # 后台启动进程
    Start-Process powershell -ArgumentList "-NoExit", "-Command", $cmd -WindowStyle Normal
    
    Start-Sleep -Milliseconds 500  # 短暂延迟，避免端口冲突
    
    return $true
}

# ============================================
# 函数：停止指定端口的 MCP 服务器
# ============================================
function Stop-MCPServer {
    param([int]$Port)
    
    Write-Host "`n🛑 停止端口 $Port 的 MCP 服务器..." -ForegroundColor Yellow
    $process = Get-NetTCPConnection -LocalPort $Port -ErrorAction SilentlyContinue | Select-Object -ExpandProperty OwningProcess
    
    if ($process) {
        Stop-Process -Id $process -Force
        Write-Host "✅ 已停止进程 ID: $process" -ForegroundColor Green
    } else {
        Write-Host "⚠️  未找到运行中的进程" -ForegroundColor Yellow
    }
}

# ============================================
# 函数：停止所有 MCP 服务器
# ============================================
function Stop-AllMCPServers {
    Write-Host "`n🛑 停止所有 MCP 服务器..." -ForegroundColor Yellow
    
    $ports = 3000..3013
    
    foreach ($port in $ports) {
        $process = Get-NetTCPConnection -LocalPort $port -ErrorAction SilentlyContinue | Select-Object -ExpandProperty OwningProcess
        if ($process) {
            Stop-Process -Id $process -Force
            Write-Host "✅ 已停止端口 $port (进程 ID: $process)" -ForegroundColor Green
        }
    }
    
    Write-Host "✅ 所有 MCP 服务器已停止" -ForegroundColor Green
}

# ============================================
# 主程序
# ============================================
Write-Host "`n============================================" -ForegroundColor Green
Write-Host "  Swagger MCP 服务器批量启动工具" -ForegroundColor Green
Write-Host "  拆分策略：按业务域阈值=15" -ForegroundColor Green
Write-Host "  总文件数：14 (13 个核心模块 + 1 个 Others)" -ForegroundColor Green
Write-Host "============================================`n" -ForegroundColor Green

# 检查 Swagger 目录是否存在
if (-not (Test-Path $SWAGGER_DIR)) {
    Write-Host "❌ 错误：Swagger 目录不存在：$SWAGGER_DIR" -ForegroundColor Red
    Write-Host "提示：请先运行拆分脚本生成 Swagger 文件" -ForegroundColor Yellow
    exit 1
}

# 显示菜单
Write-Host "请选择启动模式:" -ForegroundColor Cyan
Write-Host "1. 启动所有核心模块（13 个，端口 3000-3012）" -ForegroundColor White
Write-Host "2. 仅启动 Others 模块（1 个，端口 3013）" -ForegroundColor White
Write-Host "3. 启动全部模块（14 个，端口 3000-3013）" -ForegroundColor White
Write-Host "4. 启动指定模块（自定义）" -ForegroundColor White
Write-Host "5. 停止所有 MCP 服务器" -ForegroundColor White
Write-Host "6. 停止指定端口的 MCP 服务器" -ForegroundColor White
Write-Host "7. 查看运行状态" -ForegroundColor White
Write-Host "0. 退出`n" -ForegroundColor White

$choice = Read-Host "请输入选项 (0-7)"

switch ($choice) {
    "1" {
        Write-Host "`n🚀 开始启动核心模块..." -ForegroundColor Green
        $success = 0
        $failed = 0
        
        foreach ($module in $core_modules) {
            if (Start-MCPServer -Name $module.Name -Port $module.Port -File $module.File) {
                $success++
            } else {
                $failed++
            }
        }
        
        Write-Host "`n✅ 启动完成！成功：$success, 失败：$failed" -ForegroundColor Green
    }
    
    "2" {
        Write-Host "`n🚀 启动 Others 模块..." -ForegroundColor Green
        Start-MCPServer -Name $others_module.Name -Port $others_module.Port -File $others_module.File
    }
    
    "3" {
        Write-Host "`n🚀 开始启动全部模块..." -ForegroundColor Green
        $success = 0
        $failed = 0
        
        # 启动核心模块
        foreach ($module in $core_modules) {
            if (Start-MCPServer -Name $module.Name -Port $module.Port -File $module.File) {
                $success++
            } else {
                $failed++
            }
        }
        
        # 启动 Others 模块
        if (Start-MCPServer -Name $others_module.Name -Port $others_module.Port -File $others_module.File) {
            $success++
        } else {
            $failed++
        }
        
        Write-Host "`n✅ 启动完成！总计：$($success + $failed), 成功：$success, 失败：$failed" -ForegroundColor Green
    }
    
    "4" {
        Write-Host "`n📋 可用模块列表:" -ForegroundColor Cyan
        for ($i = 0; $i -lt $core_modules.Count; $i++) {
            Write-Host "$($i+1). $($core_modules[$i].Name) (端口 $($core_modules[$i].Port))" -ForegroundColor White
        }
        Write-Host "$($core_modules.Count + 1). Others (端口 $($others_module.Port))" -ForegroundColor White
        
        $selection = Read-Host "`n请输入要启动的模块编号（多个用逗号分隔，如 1,3,5）"
        $selections = $selection -split ',' | ForEach-Object { [int]($_.Trim()) }
        
        Write-Host "`n🚀 开始启动选中的模块..." -ForegroundColor Green
        
        foreach ($sel in $selections) {
            if ($sel -ge 1 -and $sel -le $core_modules.Count) {
                $module = $core_modules[$sel - 1]
                Start-MCPServer -Name $module.Name -Port $module.Port -File $module.File
            } elseif ($sel -eq ($core_modules.Count + 1)) {
                Start-MCPServer -Name $others_module.Name -Port $others_module.Port -File $others_module.File
            } else {
                Write-Host "❌ 无效的选择：$sel" -ForegroundColor Red
            }
        }
    }
    
    "5" {
        Stop-AllMCPServers
    }
    
    "6" {
        $port = Read-Host "请输入要停止的端口号"
        Stop-MCPServer -Port ([int]$port)
    }
    
    "7" {
        Write-Host "`n📊 当前运行状态:" -ForegroundColor Cyan
        
        $ports = 3000..3013
        $running = 0
        $stopped = 0
        
        foreach ($port in $ports) {
            $process = Get-NetTCPConnection -LocalPort $port -ErrorAction SilentlyContinue | Select-Object -ExpandProperty OwningProcess
            if ($process) {
                Write-Host "✅ 端口 $port - 运行中 (进程 ID: $process)" -ForegroundColor Green
                $running++
            } else {
                Write-Host "❌ 端口 $port - 未运行" -ForegroundColor Red
                $stopped++
            }
        }
        
        Write-Host "`n📈 统计：运行中：$running, 已停止：$stopped" -ForegroundColor Cyan
    }
    
    "0" {
        Write-Host "👋 退出程序" -ForegroundColor Yellow
        exit 0
    }
    
    default {
        Write-Host "❌ 无效的选项，请重新运行脚本" -ForegroundColor Red
    }
}

Write-Host "`n💡 提示：" -ForegroundColor Yellow
Write-Host "- 每个 MCP 服务器将在独立的 PowerShell 窗口中运行" -ForegroundColor Gray
Write-Host "- 使用选项 5 可以一键停止所有服务器" -ForegroundColor Gray
Write-Host "- 可以通过 http://localhost:<PORT>/docs 访问 Swagger UI" -ForegroundColor Gray
Write-Host "- 日志文件位置：各 PowerShell 窗口" -ForegroundColor Gray
