# MCP 服务器批量启动脚本使用指南

## 📁 脚本文件说明

本项目包含三个 PowerShell 脚本，用于管理基于 `@ivotoby/openapi-mcp-server` 的 MCP 服务器：

| 文件名 | 用途 | 适用场景 |
|--------|------|----------|
| `start_mcp_servers.ps1` | 交互式启动工具 | 需要选择性启动、查看状态 |
| `start_all_mcp_quick.ps1` | 一键快速启动 | 快速启动全部 14 个服务 |
| `stop_mcp_servers.ps1` | 停止所有服务 | 清理所有运行中的 MCP 服务器 |

---

## 🚀 使用方法

### 方式一：交互式启动（推荐）

**适用场景**：需要灵活选择启动哪些模块

```powershell
cd docker
.\start_mcp_servers.ps1
```

**菜单选项**：
1. **启动所有核心模块**（13 个，端口 3000-3012）
   - 包含 Platform_CodeSystem、Meta、Platform_Employee 等大模块
   
2. **仅启动 Others 模块**（1 个，端口 3013）
   - 包含 34 个小模块的集合
   
3. **启动全部模块**（14 个，端口 3000-3013）
   - 同时启动核心模块 + Others
   
4. **启动指定模块**（自定义）
   - 可以精确选择要启动的模块编号
   
5. **停止所有 MCP 服务器**
   - 一键清理所有运行中的服务
   
6. **停止指定端口的 MCP 服务器**
   - 输入端口号精准停止
   
7. **查看运行状态**
   - 显示每个端口的运行状态

**示例**：
```
请输入选项 (0-7): 1

🚀 开始启动核心模块...
🚀 启动 [Platform_CodeSystem] MCP 服务器...
   端口：3000
   文件：swagger-Platform_CodeSystem.json
   命令：npx -y @ivotoby/openapi-mcp-server --transport http --port 3000 ...
   
✅ 启动完成！成功：13, 失败：0
```

---

### 方式二：一键快速启动

**适用场景**：快速启动全部 14 个服务

```powershell
cd docker
.\start_all_mcp_quick.ps1
```

**执行效果**：
```
============================================
  一键启动所有 MCP 服务器
  总计：14 个服务 (端口 3000-3013)
============================================

🚀 [Platform_CodeSystem] 端口 3000...
🚀 [Meta] 端口 3001...
🚀 [Platform_Employee] 端口 3002...
...

✅ 启动完成！
   成功：14 / 总计：14

📋 服务列表:
┌───────────────────────────────┬──────┐
│ 业务域                        │ 端口 │
├───────────────────────────────┼──────┤
│ Platform_CodeSystem           │ 3000 │
│ Meta                          │ 3001 │
│ Platform_Employee             │ 3002 │
...
└───────────────────────────────┴──────┘
```

---

### 方式三：停止所有服务

**适用场景**：清理所有运行中的 MCP 服务器

```powershell
cd docker
.\stop_mcp_servers.ps1
```

**执行效果**：
```
============================================
  停止所有 MCP 服务器
  扫描端口范围：3000-3013
============================================

🛑 端口 3000 - node (PID: 12345)
   ✅ 已停止
🛑 端口 3001 - node (PID: 12346)
   ✅ 已停止
...

============================================
  执行结果
============================================
  已停止：14 个服务
  未运行：0 个端口
============================================

✅ 所有 MCP 服务器已成功停止！
```

---

## 📊 端口分配表

| 端口 | 业务域 | API 数量 | 文件大小 |
|------|--------|---------|----------|
| 3000 | Platform_CodeSystem | 120 | 160.4KB |
| 3001 | Meta | 114 | 141.2KB |
| 3002 | Platform_Employee | 80 | 77.6KB |
| 3003 | Platform_Permissions | 72 | 102.6KB |
| 3004 | Platform_Orginization | 68 | 86.2KB |
| 3005 | Employee_Sync | 38 | 77.2KB |
| 3006 | CommonLib_Info | 31 | 57.6KB |
| 3007 | Form | 31 | 53.9KB |
| 3008 | Platform_Authority | 26 | 35.9KB |
| 3009 | Module | 25 | 38.2KB |
| 3010 | Platform_Account | 19 | 25.8KB |
| 3011 | Form_Share | 18 | 28.1KB |
| 3012 | System_DataItem | 15 | 21.0KB |
| 3013 | Others | 167 | 256.6KB |

---

## 🔧 环境变量配置

脚本中已预配置以下环境变量：

```powershell
$env:NODE_TLS_REJECT_UNAUTHORIZED="0"
$env:API_BASE_URL="https://huawei.yiban.com.cn/platform"
$env:API_HEADERS='{"Authorization":"Bearer ..."}'
```

**如需修改**：
1. 编辑对应的 `.ps1` 文件
2. 修改顶部的 `$env:API_BASE_URL` 和 `$env:API_HEADERS`
3. 保存后重新运行

---

## 💡 常见问题

### Q1: 提示"权限不足"错误？
**A**: 以管理员身份运行 PowerShell：
- 右键点击 PowerShell
- 选择"以管理员身份运行"
- 再执行脚本

### Q2: 端口被占用怎么办？
**A**: 
1. 运行 `.\stop_mcp_servers.ps1` 清理旧进程
2. 或者修改脚本中的 `$BASE_PORT` 变量更改起始端口

### Q3: 如何验证服务是否正常？
**A**: 
```powershell
# 检查端口监听状态
Get-NetTCPConnection -LocalPort 3000..3013

# 访问 Swagger UI
http://localhost:3000/docs
```

### Q4: 某些服务启动失败？
**A**: 
1. 检查 Swagger 文件是否存在：
   ```powershell
   Test-Path split_strategy_domain_threshold15\swagger-Platform_CodeSystem.json
   ```
2. 查看详细错误信息（每个服务会打开独立的 PowerShell 窗口）
3. 手动测试单个服务：
   ```powershell
   npx -y @ivotoby/openapi-mcp-server --transport http --port 3000 --openapi-spec "split_strategy_domain_threshold15\swagger-Platform_CodeSystem.json"
   ```

### Q5: 如何后台静默运行？
**A**: 修改 `Start-Process` 参数：
```powershell
# 将 WindowStyle 改为 Hidden
Start-Process powershell -ArgumentList "-NoExit", "-Command", $cmd -WindowStyle Hidden
```

---

## 📝 最佳实践

### 1. 开发环境
建议只启动需要的模块：
```powershell
.\start_mcp_servers.ps1
# 选择选项 4，启动特定模块
```

### 2. 测试环境
可以启动全部模块：
```powershell
.\start_all_mcp_quick.ps1
```

### 3. 生产环境
建议使用 Docker Compose 部署（参考 README.md）

### 4. 日常维护
每天下班前清理所有服务：
```powershell
.\stop_mcp_servers.ps1
```

---

## 🔗 相关文档

- [拆分报告](split_strategy_domain_threshold15/SPLIT_REPORT.md)
- [使用指南](split_strategy_domain_threshold15/README.md)
- [MCP Server 官方文档](https://github.com/ApifoxIO/apifox-mcp-server)

---

## 📞 技术支持

如有问题，请检查：
1. Node.js 是否安装（`node --version`）
2. npx 是否可用（`npx --version`）
3. PowerShell 版本（建议 5.1+）
4. 端口是否被占用（`netstat -ano | findstr :3000`）

---

**最后更新**: 2026-03-18  
**适用版本**: 阈值=15 拆分策略  
**支持系统**: Windows 10/11 with PowerShell
