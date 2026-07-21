# Linux 运维工具

> 专为 Linux 服务器场景设计：监控资源、分析日志、稳定远程连接、同步文件

---

## 这些工具是 Linux 专属

> 本文档从 homeup 历史提交（`a4f81d7~1`）恢复，原本对应旧的 `Brewfile.linux`。在本仓库里，这些
> 工具由 `scripts/packages/apt-packages.txt`（glances/bmon/lnav 等）安装，用法说明依然适用。

适用场景：SSH 到服务器、VPS 管理、容器环境调试。

---

## glances — 全能系统监控

> 一屏看完所有：CPU、内存、磁盘、网络、进程、容器

```bash
glances                        # 打开 TUI 界面
glances -w                     # Web 模式（浏览器访问 :61208）
glances --disable-plugin docker # 不显示 Docker 信息

# 在 TUI 界面里
a      自动排序进程（按占用资源）
c      按 CPU 排序
m      按内存排序
i/o    按 I/O 排序
/      搜索进程
q      退出
```

和 `bottom`（btm）的区别：glances 更适合服务器全局监控，bottom 更适合本地交互式分析。

---

## bmon — 网络带宽监控

> 实时看每个网卡的流量，排查网络带宽问题

```bash
bmon                    # 打开 TUI，显示所有网卡的实时带宽
bmon -p eth0            # 只看指定网卡
```

TUI 里有流量图表，直观看流量突增/下降的时机，排查网络问题比 `iftop` 更直观。

---

## lnav — 日志查看器

> 多文件日志高亮浏览，支持 SQL 查询日志，比 `tail -f | grep` 强大得多

```bash
lnav /var/log/nginx/access.log      # 查看单个日志
lnav /var/log/nginx/*.log           # 多个日志文件（合并时间线）
lnav /var/log/syslog /var/log/auth.log  # 不同来源合并查看

# 实时追踪（等同于 tail -f，但有高亮）
lnav -t /var/log/app.log

# 在 lnav TUI 里
/         搜索
n/N       下一个/上一个搜索结果
;         输入 SQL 查询（! 是日志表）
:         输入 lnav 命令
i         切换时间线视图
q         退出

# SQL 查询示例（在 lnav 的 ; 提示符里）
SELECT count(*), log_level FROM logline GROUP BY log_level;
SELECT * FROM logline WHERE log_body LIKE '%error%' LIMIT 20;
```

---

## mosh — 稳定的远程 Shell（替代 SSH）

> 网络切换、断网重连不掉线，移动场景的 SSH 救星

```bash
mosh user@server.com            # 替代 ssh，连接方式相同
mosh --port 60001 user@server   # 指定 UDP 端口
mosh --ssh="ssh -p 2222" user@server  # SSH 走非标准端口时
```

**和 SSH 的区别**：
- SSH：TCP 连接，网络断了就断了，重连需要重新建 session
- mosh：UDP + 本地回显，网络切换（WiFi → 4G）自动重连，延迟高时也能流畅输入

**前提**：服务器也要安装 mosh，并开放 UDP 60000-61000 端口（或指定端口）。

---

## rsync — 高效文件同步

> 只传差异部分，大目录同步用这个，不用每次全量传输

```bash
# 本地同步（备份）
rsync -av src/ dst/                     # 同步目录
rsync -av --delete src/ dst/            # 镜像（删除目标里多余的文件）

# 远程同步
rsync -avz src/ user@server:/dst/       # 本地 → 远程（-z 压缩传输）
rsync -avz user@server:/src/ dst/       # 远程 → 本地

# 常用选项
-a        归档模式（保留权限、时间戳、符号链接）
-v        显示详情
-z        压缩传输
-n / --dry-run   预览，不实际执行
--exclude .git   排除目录
--progress       显示进度

# 实用场景
rsync -avz --exclude node_modules --exclude .git \
    ./myproject user@server:/home/user/
```

---

## htop — 交互式进程查看

> 比 top 好用，有颜色，支持鼠标，能直接 kill 进程

```bash
htop                    # 打开

# 在 htop 里
F3 / /    搜索进程
F4        过滤（只显示匹配的进程）
F5        树状视图
F6        排序方式
F9        kill 选中进程（选择信号）
F10 / q   退出
Space     标记进程
u         按用户过滤
```

---

## ncdu — 磁盘占用分析（TUI 版 du）

```bash
ncdu                    # 分析当前目录
ncdu /                  # 分析根目录（找大文件）
ncdu ~                  # 分析 home 目录

# 在 ncdu TUI 里
方向键      导航
Enter       进入目录
d           删除（有确认）
n/s/C       按名称/大小/条目数排序
i           显示文件信息
q           退出
```

---

## sysstat — 系统性能历史

```bash
# sar：系统活动报告（需要 sysstat 服务在运行）
sar -u 1 5              # 每秒一次 CPU 统计，共 5 次
sar -r 1 5              # 内存统计
sar -n DEV 1 5          # 网络统计

# iostat：磁盘 I/O
iostat -x 1             # 扩展磁盘统计，每秒刷新
iostat -d sda 1 5       # 指定磁盘

# mpstat：多核 CPU
mpstat -P ALL 1         # 每个 CPU 核的统计
```

---

## 典型工作流

**服务器排查性能问题**：
```bash
# 整体情况
glances

# 看是哪个进程吃 CPU
htop
# → F6 排序，找到元凶

# 看磁盘 I/O 是否是瓶颈
iostat -x 1

# 看是不是磁盘快满了
ncdu /
```

**远程日志分析**：
```bash
# SSH 进服务器（用 mosh 防止断线）
mosh user@server

# 分析最近的错误日志
lnav /var/log/nginx/error.log /var/log/app/*.log

# 同步日志到本地分析
rsync -avz user@server:/var/log/app/ ./logs/
```

**定期备份**：
```bash
# 增量备份到远程（只传变化的文件）
rsync -avz --delete ~/workspace/ backup@nas:/backups/workspace/
```

---

## 最佳实践

- **mosh 做日常 SSH**：只要服务器安装了 mosh，就用 mosh 代替 ssh，免去断线烦恼
- **lnav 比 grep 更适合日志分析**：日志有时间线、可以 SQL 查询，比 `grep error app.log` 强很多
- **rsync 的 `--dry-run`**：第一次同步前先跑 dry-run，确认不会误删东西
- **glances 的 Web 模式**：`glances -w` 启动后，在本机浏览器通过 SSH 端口转发访问，不需要图形界面
