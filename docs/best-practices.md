# Homeup 最佳实践指南

本指南提供基于 Homeup 工具集的实战场景和工作流程，帮助开发者和运维人员充分发挥现代化工具的优势。

**目录结构**:

- [Dev 场景 (7 个)](#dev-场景)
- [Ops 场景 (6 个)](#ops-场景)
- [通用工作流 (3 个)](#通用工作流)

---

## Dev 场景

### 1. 前端开发 (React/Vue/Angular)

#### 适用人群

- 专注于 Web 前端开发的工程师
- 全栈开发者的前端部分
- UI/UX 开发者需要快速原型验证

#### 推荐工具组合

```bash
# 核心工具
mise          # Node.js 版本管理
pnpm          # 高效的包管理器
neovim        # 编辑器 (或 VS Code)
lazygit       # Git 可视化操作

# 辅助工具
watchexec     # 文件监控自动重载
httpie        # API 测试
bruno         # API 客户端 (macOS GUI)
```

#### 工作流程

**1. 项目初始化**

```bash
# 创建项目目录
mkdir my-frontend-app && cd my-frontend-app

# 使用 mise 安装 Node.js
mise use node@20
mise install

# 使用 pnpm 初始化项目
pnpm create vite@latest . --template react-ts
pnpm install
```

**2. 开发环境配置**

```bash
# 使用 direnv 管理环境变量
cat > .envrc << EOF
export NODE_ENV=development
export API_BASE_URL=http://localhost:3000
EOF

# 激活 direnv
direnv allow

# 配置 mise 本地配置
cat > .mise.toml << EOF
[tools]
node = "20"

[env]
NODE_OPTIONS = "--max-old-space-size=4096"
EOF
```

**3. 开发实时预览**

```bash
# 使用 watchexec 监控文件变化并执行构建
watchexec -e ts,tsx,css -r pnpm dev

# 或者使用 just 定义任务
cat > justfile << EOF
dev:
    pnpm dev

build:
    pnpm build

lint:
    pnpm eslint . --ext ts,tsx --fix

preview:
    pnpm preview
EOF

just dev
```

**4. Git 工作流**

```bash
# 使用 lazygit 进行可视化操作
lazygit

# 或使用 gh CLI 创建 PR
git add .
git commit -m "feat: add new dashboard component"
gh pr create --title "Add Dashboard" --body "New analytics dashboard"
```

**5. API 调试**

```bash
# 使用 httpie 测试 API
http POST localhost:3000/api/users name=John email=john@example.com

# 使用 xh (更快的 Rust 替代品)
xh post localhost:3000/api/users name=John email=john@example.com

# 使用 Bruno (macOS) 进行复杂 API 测试
open -a Bruno
```

#### 配置建议

**VS Code 配置** (`.vscode/settings.json`):

```json
{
  "editor.formatOnSave": true,
  "editor.defaultFormatter": "esbenp.prettier-vscode",
  "typescript.tsdk": "node_modules/typescript/lib",
  "terminal.integrated.shell.osx": "/bin/zsh"
}
```

**Neovim 配置技巧**:

```bash
# 使用 LazyVim 或 NvChad 作为现代化配置基础
# 确保安装了 LSP 支持
:Mason  # 打开 Mason 安装 typescript-language-server
```

#### 社区最佳实践

1. **使用 pnpm workspace** 管理 Monorepo:

   ```yaml
   # pnpm-workspace.yaml
   packages:
     - "packages/*"
     - "apps/*"
   ```

2. **使用 Vite** 而非 Webpack: 更快的构建速度和开发体验

3. **启用 TypeScript strict 模式**: 提前发现类型错误

4. **使用 git-delta** 查看清晰的代码差异:
   ```bash
   git diff  # 自动使用 delta 高亮显示
   ```

---

### 2. 后端开发 (Go/Python/Node.js)

#### 适用人群

- 后端 API 开发工程师
- 微服务架构开发者
- 需要处理数据库和缓存的开发者

#### 推荐工具组合

```bash
# 核心工具
mise          # 多语言运行时管理 (Go, Python, Node.js)
uv            # Python 包管理器
docker        # 容器运行
lazydocker    # Docker 可视化管理

# 数据库工具
pgcli         # PostgreSQL 命令行客户端
DBeaver       # 数据库 GUI (macOS)

# API 工具
httpie        # HTTP 客户端
grpcurl       # gRPC 测试工具
evans         # gRPC 交互式客户端
```

#### 工作流程

**1. 多语言项目设置**

```bash
# Go 项目
mise use go@1.21
cat > .mise.toml << EOF
[tools]
go = "1.21"
golangci-lint = "latest"
EOF

# Python 项目
mise use python@3.12
uv venv
source .venv/bin/activate
uv pip install fastapi uvicorn sqlalchemy

# Node.js 项目
mise use node@20
pnpm init
pnpm add express @types/express
```

**2. 本地开发环境 (Docker Compose)**

```bash
# 使用 just 管理 Docker 环境
cat > justfile << EOF
# 启动所有服务
up:
    docker-compose up -d

# 查看日志
logs:
    docker-compose logs -f

# 进入容器
shell service:
    docker-compose exec {{service}} bash

# 停止服务
down:
    docker-compose down
EOF

# 使用 lazydocker 可视化管理
lazydocker
```

**3. 数据库操作**

```bash
# 使用 pgcli 连接数据库
pgcli postgresql://user:password@localhost:5432/mydb

# 在 pgcli 中使用自动补全和语法高亮
\dt          # 列出所有表
\d users     # 查看表结构
SELECT * FROM users LIMIT 10;

# 使用 DBeaver (macOS) 进行复杂查询和数据可视化
open -a "DBeaver Community"
```

**4. API 开发和测试**

```bash
# 测试 REST API
http POST localhost:8000/api/users \
  name=Alice \
  email=alice@example.com \
  age:=30

# 测试 gRPC API
grpcurl -plaintext \
  -d '{"name": "Alice"}' \
  localhost:50051 \
  UserService/CreateUser

# 使用 evans 进行交互式 gRPC 调试
evans --host localhost --port 50051 repl
```

**5. 性能测试和优化**

```bash
# 使用 hyperfine 基准测试
hyperfine 'curl http://localhost:8000/api/health'

# 监控进程性能
procs --tree | grep my-app

# 监控网络带宽使用
bandwhich
```

#### 配置建议

**Go 项目配置** (`.mise.toml`):

```toml
[tools]
go = "1.21"
golangci-lint = "latest"

[env]
CGO_ENABLED = "0"
GOOS = "linux"
GOARCH = "amd64"

[tasks.build]
run = "go build -o bin/app ./cmd/server"

[tasks.test]
run = "go test -v -race ./..."
```

**Python 项目配置** (`pyproject.toml`):

```toml
[project]
name = "my-backend"
version = "0.1.0"
requires-python = ">=3.12"
dependencies = [
    "fastapi>=0.104.0",
    "uvicorn[standard]>=0.24.0",
    "sqlalchemy>=2.0.0",
]

[tool.uv]
dev-dependencies = [
    "pytest>=7.4.0",
    "httpx>=0.25.0",
]
```

#### 社区最佳实践

1. **使用 mise 统一团队运行时版本**: 避免 "在我机器上可以运行" 问题

2. **容器化开发环境**: 使用 Docker Compose 定义依赖服务

3. **API 优先设计**: 先定义 OpenAPI/gRPC schema，再实现代码

4. **使用 just 而非 Makefile**: 更简洁的语法和更好的错误提示

---

### 3. 全栈开发

#### 适用人群

- 同时负责前后端的全栈工程师
- 独立开发者构建完整产品
- 创业团队快速原型开发

#### 推荐工具组合

```bash
# 开发环境
mise          # 统一管理所有运行时
pnpm          # Monorepo 包管理
VS Code       # IDE (支持前后端)
Ghostty       # 现代化终端

# 容器和数据库
lazydocker    # Docker 可视化
pgcli         # 数据库 CLI
DBeaver       # 数据库 GUI

# 辅助工具
zellij        # 终端多窗口管理
httpie        # API 测试
```

#### 工作流程

**1. Monorepo 项目结构**

```bash
# 创建 Monorepo
mkdir fullstack-app && cd fullstack-app

# 初始化 pnpm workspace
cat > pnpm-workspace.yaml << EOF
packages:
  - 'apps/*'
  - 'packages/*'
EOF

# 创建项目结构
mkdir -p apps/web apps/api packages/shared
```

**2. 统一运行时管理**

```bash
# 根目录配置 mise
cat > .mise.toml << EOF
[tools]
node = "20"
go = "1.21"
python = "3.12"

[tasks.dev]
run = "pnpm dev"

[tasks.build]
run = "pnpm build"

[tasks.docker]
run = "docker-compose up -d"
EOF

mise install
```

**3. 前端项目设置** (`apps/web`)

```bash
cd apps/web
pnpm create vite@latest . --template react-ts
pnpm install

# 配置 package.json
cat > package.json << EOF
{
  "name": "@my-app/web",
  "version": "0.1.0",
  "scripts": {
    "dev": "vite",
    "build": "tsc && vite build",
    "preview": "vite preview"
  },
  "dependencies": {
    "react": "^18.2.0",
    "@my-app/shared": "workspace:*"
  }
}
EOF
```

**4. 后端项目设置** (`apps/api`)

```bash
cd apps/api
go mod init github.com/yourname/fullstack-app/api

cat > main.go << EOF
package main

import (
    "github.com/gin-gonic/gin"
)

func main() {
    r := gin.Default()
    r.GET("/api/health", func(c *gin.Context) {
        c.JSON(200, gin.H{"status": "ok"})
    })
    r.Run(":8000")
}
EOF
```

**5. 使用 Zellij 管理多个终端会话**

```bash
# 启动 Zellij 并创建布局
zellij --layout fullstack

# 创建自定义布局 (~/.config/zellij/layouts/fullstack.kdl)
layout {
    pane split_direction="vertical" {
        pane name="Frontend" {
            command "sh"
            args "-c" "cd apps/web && pnpm dev"
        }
        pane split_direction="horizontal" {
            pane name="Backend" {
                command "sh"
                args "-c" "cd apps/api && go run main.go"
            }
            pane name="Docker" {
                command "lazydocker"
            }
        }
    }
}
```

#### 配置建议

**VS Code Workspace** (`fullstack-app.code-workspace`):

```json
{
  "folders": [
    { "path": "apps/web", "name": "Frontend" },
    { "path": "apps/api", "name": "Backend" },
    { "path": "packages/shared", "name": "Shared" }
  ],
  "settings": {
    "typescript.tsdk": "apps/web/node_modules/typescript/lib",
    "go.useLanguageServer": true,
    "editor.formatOnSave": true
  }
}
```

**Docker Compose** (`docker-compose.yml`):

```yaml
version: "3.8"

services:
  postgres:
    image: postgres:16-alpine
    environment:
      POSTGRES_DB: myapp
      POSTGRES_USER: developer
      POSTGRES_PASSWORD: dev_password
    ports:
      - "5432:5432"
    volumes:
      - postgres_data:/var/lib/postgresql/data

  redis:
    image: redis:7-alpine
    ports:
      - "6379:6379"

volumes:
  postgres_data:
```

#### 社区最佳实践

1. **使用 pnpm workspace 共享代码**: 创建 `packages/shared` 存放公共类型定义

2. **前后端类型安全**: 使用 TypeScript + Go 生成器 (如 `tygo`) 同步类型

3. **使用 Zellij 而非 tmux**: 更友好的键绑定和配置

4. **统一代码风格**: 使用 lefthook 在 commit 前运行 lint

---

### 4. 移动开发 (React Native/Flutter)

#### 适用人群

- 移动应用开发工程师
- 跨平台应用开发者
- 需要同时支持 iOS 和 Android 的团队

#### 推荐工具组合

```bash
# 核心工具
mise          # Node.js/Dart 版本管理
pnpm          # 包管理器 (React Native)
VS Code       # IDE (支持 RN/Flutter)

# 辅助工具
watchexec     # 文件监控
httpie        # API 调试
lazygit       # Git 操作
```

#### 工作流程

**1. React Native 项目初始化**

```bash
# 安装 Node.js
mise use node@20
mise install

# 创建项目
npx react-native@latest init MyApp
cd MyApp
pnpm install

# 配置 mise
cat > .mise.toml << EOF
[tools]
node = "20"
ruby = "3.2"  # for CocoaPods

[tasks.ios]
run = "pnpm react-native run-ios"

[tasks.android]
run = "pnpm react-native run-android"

[tasks.start]
run = "pnpm react-native start"
EOF
```

**2. Flutter 项目初始化**

```bash
# 使用 mise 安装 Dart
mise use dart@latest
mise install

# 创建项目
flutter create my_flutter_app
cd my_flutter_app

# 配置 mise
cat > .mise.toml << EOF
[tools]
dart = "latest"

[tasks.run]
run = "flutter run"

[tasks.build]
run = "flutter build apk"

[tasks.test]
run = "flutter test"
EOF
```

**3. 开发调试**

```bash
# 使用 just 管理任务
cat > justfile << EOF
# 启动 Metro bundler (RN)
start:
    pnpm react-native start

# 运行 iOS 模拟器
ios:
    pnpm react-native run-ios

# 运行 Android 模拟器
android:
    pnpm react-native run-android

# 清理缓存
clean:
    rm -rf node_modules ios/Pods
    pnpm install
    cd ios && pod install
EOF

# 监控文件变化自动重载
watchexec -e js,jsx,ts,tsx -r pnpm react-native start
```

**4. API 集成测试**

```bash
# 测试后端 API
http GET https://api.example.com/users \
  Authorization:"Bearer token"

# 使用 httpie 调试 JSON 响应
http POST https://api.example.com/login \
  username=user \
  password=pass
```

**5. 版本管理和发布**

```bash
# 使用 git-cliff 生成 Changelog
git cliff --output CHANGELOG.md

# 创建 Git tag
git tag -a v1.0.0 -m "Release version 1.0.0"

# 使用 gh 创建 Release
gh release create v1.0.0 --notes "$(git cliff --latest)"
```

#### 配置建议

**VS Code 配置** (`.vscode/settings.json`):

```json
{
  "typescript.tsdk": "node_modules/typescript/lib",
  "react-native.runAndroid": "pnpm react-native run-android",
  "react-native.runIos": "pnpm react-native run-ios",
  "dart.flutterSdkPath": "${HOME}/.local/share/mise/installs/dart/latest"
}
```

**React Native 环境变量** (`.envrc`):

```bash
export ANDROID_HOME=$HOME/Library/Android/sdk
export PATH=$ANDROID_HOME/platform-tools:$PATH
export JAVA_HOME=$(/usr/libexec/java_home -v 17)
```

#### 社区最佳实践

1. **使用 mise 管理 Node 和 Ruby 版本**: 确保团队环境一致

2. **使用 pnpm**: 比 npm/yarn 更快的安装速度和更少的磁盘占用

3. **使用 Expo**: 对于新项目，考虑使用 Expo 简化开发流程

4. **使用 React Native Debugger**: 更好的调试体验

---

### 5. 数据科学/ML

#### 适用人群

- 数据科学家
- 机器学习工程师
- 数据分析师

#### 推荐工具组合

```bash
# Python 环境
mise          # Python 版本管理
uv            # 快速的 Python 包管理器

# 数据工具
miller        # CSV/JSON 数据处理
jq            # JSON 查询
yq            # YAML 查询
gron          # JSON 扁平化

# 开发工具
jupyter       # 交互式笔记本
neovim        # 脚本编辑
bat           # 代码查看
```

#### 工作流程

**1. Python 环境设置**

```bash
# 创建项目目录
mkdir ml-project && cd ml-project

# 使用 mise 安装 Python
mise use python@3.12
mise install

# 使用 uv 创建虚拟环境
uv venv
source .venv/bin/activate

# 使用 uv 快速安装包
uv pip install numpy pandas scikit-learn matplotlib jupyter
```

**2. Jupyter Notebook 开发**

```bash
# 启动 Jupyter Lab
jupyter lab --no-browser --port=8888

# 使用 just 管理任务
cat > justfile << EOF
# 启动 Jupyter
jupyter:
    jupyter lab --no-browser

# 安装包
install package:
    uv pip install {{package}}

# 导出依赖
freeze:
    uv pip freeze > requirements.txt

# 运行脚本
run script:
    python {{script}}
EOF
```

**3. 数据处理**

```bash
# 使用 miller 处理 CSV
mlr --csv filter '$age > 30' data.csv

# 转换 CSV 到 JSON
mlr --icsv --ojson cat data.csv > data.json

# 使用 jq 查询 JSON
cat data.json | jq '.[] | select(.age > 30)'

# 使用 gron 查看 JSON 结构
gron data.json | grep age

# 统计数据
mlr --csv stats1 -a mean,median,stddev -f age data.csv
```

**4. 代码分析和可视化**

```bash
# 使用 bat 查看 Python 代码 (语法高亮)
bat model.py

# 查看代码统计
tokei .

# 查看大文件前几行
bat --paging=never train.py | head -n 50

# 使用 glow 渲染 Markdown 报告
glow README.md
```

**5. 模型训练和监控**

```bash
# 使用 hyperfine 测试训练性能
hyperfine 'python train.py --epochs 10'

# 监控系统资源
btop

# 监控 GPU 使用 (如果有 NVIDIA GPU)
watch -n 1 nvidia-smi

# 使用 watchexec 自动重新训练
watchexec -e py -r python train.py
```

#### 配置建议

**项目配置** (`pyproject.toml`):

```toml
[project]
name = "ml-project"
version = "0.1.0"
requires-python = ">=3.12"
dependencies = [
    "numpy>=1.26.0",
    "pandas>=2.1.0",
    "scikit-learn>=1.3.0",
    "matplotlib>=3.8.0",
    "jupyter>=1.0.0",
]

[tool.uv]
dev-dependencies = [
    "pytest>=7.4.0",
    "black>=23.10.0",
    "ruff>=0.1.0",
]
```

**Jupyter 配置** (`~/.jupyter/jupyter_lab_config.py`):

```python
c.ServerApp.ip = '0.0.0.0'
c.ServerApp.open_browser = False
c.ServerApp.token = ''
c.ServerApp.password = ''
```

**Neovim 配置** (安装 Jupyter 内核支持):

```bash
# 使用 jupytext 编辑 .ipynb 为 .py
uv pip install jupytext

# 在 Neovim 中编辑 Python 脚本，同步到 Notebook
jupytext --set-formats ipynb,py:percent notebook.ipynb
```

#### 社区最佳实践

1. **使用 uv 而非 pip**: 安装速度提升 10-100 倍

2. **使用 miller 而非 pandas**: 对于简单数据操作，更快且占用更少内存

3. **使用 jupytext**: 将 Notebook 转为纯文本，便于版本控制

4. **使用 DVC (Data Version Control)**: 管理大型数据集和模型版本

```bash
# 安装 DVC
uv pip install dvc

# 初始化 DVC
dvc init

# 跟踪数据
dvc add data/train.csv
git add data/train.csv.dvc .gitignore
```

---

### 6. 系统编程 (Rust/C++)

#### 适用人群

- 系统级开发工程师
- 性能关键应用开发者
- 底层工具和库开发者

#### 推荐工具组合

```bash
# 编译器和工具链
mise          # Rust/C++ 版本管理
neovim        # 编辑器 (支持 LSP)
tmux          # 终端复用

# 性能分析
hyperfine     # 基准测试
btop          # 系统监控
bandwhich     # 网络带宽监控

# Git 工作流
lazygit       # Git 可视化
git-delta     # 代码差异查看
```

#### 工作流程

**1. Rust 项目初始化**

```bash
# 安装 Rust
mise use rust@stable
mise install

# 创建项目
cargo new my-rust-app
cd my-rust-app

# 配置 mise
cat > .mise.toml << EOF
[tools]
rust = "stable"

[tasks.build]
run = "cargo build --release"

[tasks.test]
run = "cargo test"

[tasks.bench]
run = "cargo bench"

[tasks.fmt]
run = "cargo fmt && cargo clippy"
EOF
```

**2. C++ 项目设置**

```bash
# 安装 C++ 工具链
mise use cpp@latest
mise install

# 创建 CMake 项目
mkdir build
cmake -B build -S .

# 配置 mise
cat > .mise.toml << EOF
[tools]
cmake = "latest"
ninja = "latest"

[tasks.build]
run = "cmake --build build"

[tasks.test]
run = "ctest --test-dir build"
EOF
```

**3. 开发环境 (tmux + neovim)**

```bash
# 启动 tmux 会话
tmux new -s dev

# 创建多窗口布局
# Ctrl+b % (垂直分屏)
# Ctrl+b " (水平分屏)

# 左侧: neovim 编辑
nvim src/main.rs

# 右上: 自动编译
watchexec -e rs -r cargo build

# 右下: 运行测试
watchexec -e rs -r cargo test
```

**4. 性能分析和优化**

```bash
# 使用 hyperfine 基准测试
hyperfine './target/release/my-app' './target/release/my-app-optimized'

# 对比不同实现
hyperfine -n 'hashmap' './bench-hashmap' \
          -n 'btree' './bench-btree'

# 使用 cargo bench
cargo bench

# 监控系统资源
btop

# 监控网络带宽 (网络应用)
sudo bandwhich
```

**5. 调试和测试**

```bash
# 使用 lldb 调试 (macOS)
lldb target/debug/my-app

# 使用 gdb 调试 (Linux)
gdb target/debug/my-app

# 使用 cargo 测试
cargo test

# 使用 just 自动化测试
cat > justfile << EOF
# 运行所有测试
test:
    cargo test

# 运行集成测试
test-integration:
    cargo test --test '*'

# 运行基准测试
bench:
    cargo bench

# 性能分析
profile:
    cargo build --release
    hyperfine './target/release/my-app'
EOF
```

#### 配置建议

**Rust 项目** (`Cargo.toml`):

```toml
[package]
name = "my-rust-app"
version = "0.1.0"
edition = "2021"

[dependencies]
tokio = { version = "1", features = ["full"] }
serde = { version = "1", features = ["derive"] }

[profile.release]
opt-level = 3
lto = true
codegen-units = 1
strip = true
```

**Neovim LSP 配置** (`~/.config/nvim/lua/lsp.lua`):

```lua
-- Rust LSP
require('lspconfig').rust_analyzer.setup({
  settings = {
    ['rust-analyzer'] = {
      cargo = { allFeatures = true },
      checkOnSave = { command = "clippy" },
    }
  }
})

-- C++ LSP
require('lspconfig').clangd.setup({})
```

**Git 钩子** (`lefthook.yml`):

```yaml
pre-commit:
  commands:
    fmt:
      run: cargo fmt --check
    clippy:
      run: cargo clippy -- -D warnings
    test:
      run: cargo test
```

#### 社区最佳实践

1. **使用 Rust 的 cargo 工作区**: 管理多 crate 项目

2. **使用 clippy**: 捕获常见错误和非惯用代码

3. **使用 rustfmt**: 保持代码风格一致

4. **使用 criterion**: 更准确的基准测试

```bash
# 安装 criterion
cargo add --dev criterion

# 创建 benchmark
mkdir benches
cat > benches/my_bench.rs << EOF
use criterion::{black_box, criterion_group, criterion_main, Criterion};

fn fibonacci(n: u64) -> u64 {
    match n {
        0 => 1,
        1 => 1,
        n => fibonacci(n-1) + fibonacci(n-2),
    }
}

fn criterion_benchmark(c: &mut Criterion) {
    c.bench_function("fib 20", |b| b.iter(|| fibonacci(black_box(20))));
}

criterion_group!(benches, criterion_benchmark);
criterion_main!(benches);
EOF
```

---

### 7. Web3/区块链开发

#### 适用人群

- 智能合约开发者
- DApp 前端工程师
- 区块链协议开发者

#### 推荐工具组合

```bash
# 开发工具链
mise          # Node.js/Solidity 版本管理
pnpm          # 包管理器
Hardhat       # 智能合约开发框架
Foundry       # Rust 工具链 (forge, cast, anvil)

# 调试工具
httpie        # RPC 调试
xh            # 快速 HTTP 客户端
jq            # JSON 处理

# 编辑器
VS Code       # IDE (Solidity 支持)
neovim        # 脚本编辑
```

#### 工作流程

**1. Hardhat 项目初始化**

```bash
# 安装 Node.js
mise use node@20
mise install

# 创建项目
mkdir my-dapp && cd my-dapp
pnpm init

# 安装 Hardhat
pnpm add --save-dev hardhat @nomicfoundation/hardhat-toolbox
pnpx hardhat init

# 配置 mise
cat > .mise.toml << EOF
[tools]
node = "20"

[tasks.compile]
run = "pnpm hardhat compile"

[tasks.test]
run = "pnpm hardhat test"

[tasks.deploy]
run = "pnpm hardhat run scripts/deploy.js"

[tasks.node]
run = "pnpm hardhat node"
EOF
```

**2. Foundry 项目设置** (可选)

```bash
# 安装 Foundry
curl -L https://foundry.paradigm.xyz | bash
foundryup

# 初始化项目
forge init my-foundry-project
cd my-foundry-project

# 编译合约
forge build

# 运行测试
forge test

# 配置 mise
cat > .mise.toml << EOF
[tasks.build]
run = "forge build"

[tasks.test]
run = "forge test -vvv"

[tasks.deploy]
run = "forge script script/Deploy.s.sol:DeployScript --rpc-url $RPC_URL --broadcast"
EOF
```

**3. 智能合约开发**

```bash
# 创建合约 (contracts/MyToken.sol)
cat > contracts/MyToken.sol << EOF
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract MyToken is ERC20 {
    constructor() ERC20("MyToken", "MTK") {
        _mint(msg.sender, 1000000 * 10 ** decimals());
    }
}
EOF

# 编译
pnpm hardhat compile

# 运行测试
pnpm hardhat test

# 使用 watchexec 监控文件变化
watchexec -e sol -r pnpm hardhat test
```

**4. RPC 调试和交互**

```bash
# 启动本地节点
pnpm hardhat node

# 使用 httpie 调用 RPC
http POST localhost:8545 \
  jsonrpc=2.0 \
  method=eth_blockNumber \
  params:='[]' \
  id=1

# 使用 xh (更快)
xh POST localhost:8545 \
  jsonrpc=2.0 \
  method=eth_getBalance \
  params:='["0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266", "latest"]' \
  id=1

# 使用 cast (Foundry 工具)
cast block-number --rpc-url http://localhost:8545
cast balance 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266 --rpc-url http://localhost:8545
```

**5. 前端集成**

```bash
# 创建前端应用
cd ..
pnpm create vite@latest frontend -- --template react-ts
cd frontend
pnpm install

# 安装 Web3 库
pnpm add ethers wagmi viem

# 配置环境变量
cat > .env << EOF
VITE_RPC_URL=http://localhost:8545
VITE_CONTRACT_ADDRESS=0x5FbDB2315678afecb367f032d93F642f64180aa3
EOF
```

#### 配置建议

**Hardhat 配置** (`hardhat.config.js`):

```javascript
require("@nomicfoundation/hardhat-toolbox");

module.exports = {
  solidity: {
    version: "0.8.20",
    settings: {
      optimizer: {
        enabled: true,
        runs: 200,
      },
    },
  },
  networks: {
    hardhat: {
      chainId: 31337,
    },
    sepolia: {
      url: process.env.SEPOLIA_RPC_URL,
      accounts: [process.env.PRIVATE_KEY],
    },
  },
  etherscan: {
    apiKey: process.env.ETHERSCAN_API_KEY,
  },
};
```

**Foundry 配置** (`foundry.toml`):

```toml
[profile.default]
src = "src"
out = "out"
libs = ["lib"]
optimizer = true
optimizer_runs = 200

[rpc_endpoints]
mainnet = "${MAINNET_RPC_URL}"
sepolia = "${SEPOLIA_RPC_URL}"

[etherscan]
mainnet = { key = "${ETHERSCAN_API_KEY}" }
sepolia = { key = "${ETHERSCAN_API_KEY}" }
```

**VS Code 配置** (`.vscode/settings.json`):

```json
{
  "solidity.compileUsingRemoteVersion": "v0.8.20",
  "solidity.formatter": "prettier",
  "editor.formatOnSave": true,
  "[solidity]": {
    "editor.defaultFormatter": "NomicFoundation.hardhat-solidity"
  }
}
```

#### 社区最佳实践

1. **使用 Foundry 进行测试**: 比 Hardhat 快 10-100 倍

2. **使用 OpenZeppelin 合约库**: 安全的合约模板

```bash
pnpm add @openzeppelin/contracts
```

3. **使用 Slither 进行安全审计**:

```bash
# 安装 Slither
uv pip install slither-analyzer

# 运行分析
slither .
```

4. **使用 gas-reporter**: 优化 gas 消耗

```javascript
// hardhat.config.js
require("hardhat-gas-reporter");

module.exports = {
  gasReporter: {
    enabled: true,
    currency: "USD",
  },
};
```

---

## Ops 场景

### 1. 容器化部署 (Docker/Kubernetes)

#### 适用人群

- DevOps 工程师
- 容器平台管理员
- 微服务架构运维人员

#### 推荐工具组合

```bash
# 容器管理
lazydocker    # Docker 可视化管理
dive          # 镜像分析工具

# Kubernetes
k9s           # K8s 集群管理
helm          # 包管理器
kubectx       # 上下文切换
stern         # 多 Pod 日志聚合
kustomize     # 配置管理

# 监控
btop          # 系统监控
bandwhich     # 网络监控
```

#### 工作流程

**1. Docker 开发环境**

```bash
# 使用 lazydocker 管理容器
lazydocker

# 快捷键:
# e - 进入容器
# l - 查看日志
# s - 停止容器
# r - 重启容器
# d - 删除容器

# 使用 just 管理 Docker 任务
cat > justfile << EOF
# 构建镜像
build:
    docker build -t myapp:latest .

# 运行容器
run:
    docker-compose up -d

# 查看日志
logs service:
    docker-compose logs -f {{service}}

# 进入容器
shell service:
    docker-compose exec {{service}} sh

# 清理
clean:
    docker-compose down -v
    docker system prune -af
EOF
```

**2. 镜像优化**

```bash
# 使用 dive 分析镜像层
dive myapp:latest

# 在 dive 中:
# Tab - 切换视图
# Ctrl+Space - 显示/隐藏未修改文件
# Ctrl+A - 显示聚合层变化

# 多阶段构建示例
cat > Dockerfile << EOF
# 构建阶段
FROM node:20-alpine AS builder
WORKDIR /app
COPY package*.json ./
RUN npm ci
COPY . .
RUN npm run build

# 运行阶段
FROM node:20-alpine
WORKDIR /app
COPY --from=builder /app/dist ./dist
COPY --from=builder /app/node_modules ./node_modules
EXPOSE 3000
CMD ["node", "dist/server.js"]
EOF

# 构建并分析
docker build -t myapp:optimized .
dive myapp:optimized
```

**3. Kubernetes 集群管理**

```bash
# 使用 k9s 管理集群
k9s

# k9s 常用快捷键:
# :pods - 查看 Pods
# :svc - 查看 Services
# :deploy - 查看 Deployments
# d - 查看详情
# l - 查看日志
# s - 进入 Shell
# Ctrl+d - 删除资源

# 使用 kubectx 切换集群
kubectx                    # 列出所有上下文
kubectx staging            # 切换到 staging
kubectx -                  # 切换回上一个上下文

# 使用 kubens 切换命名空间
kubens                     # 列出所有命名空间
kubens production          # 切换到 production
```

**4. 日志聚合和调试**

```bash
# 使用 stern 查看多个 Pod 日志
stern myapp --tail 10

# 根据标签过滤
stern -l app=myapp,env=production

# 使用正则表达式
stern "^myapp-.*" --since 15m

# 使用 lnav 分析日志文件
kubectl logs myapp-pod > app.log
lnav app.log

# 在 lnav 中:
# / - 搜索
# i - 显示直方图
# t - 切换文本视图
```

**5. Helm Chart 管理**

```bash
# 创建 Helm Chart
helm create myapp

# 验证 Chart
helm lint myapp

# 渲染模板
helm template myapp ./myapp

# 安装 Chart
helm install myapp ./myapp \
  --namespace production \
  --create-namespace

# 升级 Chart
helm upgrade myapp ./myapp \
  --set image.tag=v2.0.0

# 回滚
helm rollback myapp
```

#### 配置建议

**Docker Compose** (`docker-compose.yml`):

```yaml
version: "3.8"

services:
  app:
    build:
      context: .
      dockerfile: Dockerfile
      cache_from:
        - myapp:latest
    ports:
      - "3000:3000"
    environment:
      NODE_ENV: production
    depends_on:
      - postgres
      - redis
    restart: unless-stopped
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:3000/health"]
      interval: 30s
      timeout: 10s
      retries: 3

  postgres:
    image: postgres:16-alpine
    volumes:
      - postgres_data:/var/lib/postgresql/data
    environment:
      POSTGRES_PASSWORD: ${DB_PASSWORD}

  redis:
    image: redis:7-alpine
    volumes:
      - redis_data:/var/lib/redis

volumes:
  postgres_data:
  redis_data:
```

**Kubernetes Deployment** (`k8s/deployment.yaml`):

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: myapp
  labels:
    app: myapp
spec:
  replicas: 3
  selector:
    matchLabels:
      app: myapp
  template:
    metadata:
      labels:
        app: myapp
    spec:
      containers:
        - name: myapp
          image: myapp:latest
          ports:
            - containerPort: 3000
          resources:
            requests:
              memory: "128Mi"
              cpu: "100m"
            limits:
              memory: "256Mi"
              cpu: "200m"
          livenessProbe:
            httpGet:
              path: /health
              port: 3000
            initialDelaySeconds: 30
            periodSeconds: 10
          readinessProbe:
            httpGet:
              path: /ready
              port: 3000
            initialDelaySeconds: 5
            periodSeconds: 5
```

#### 社区最佳实践

1. **使用 lazydocker 而非 docker 命令**: 更直观的界面和操作

2. **使用 dive 优化镜像大小**: 减少镜像层数和大小

3. **使用 k9s 而非 kubectl**: 更快的集群管理和调试

4. **使用 stern 聚合日志**: 比 `kubectl logs` 更强大

---

### 2. CI/CD 流水线

#### 适用人群

- DevOps 工程师
- 平台工程师
- 负责自动化部署的开发者

#### 推荐工具组合

```bash
# GitHub 工作流
gh            # GitHub CLI

# 任务自动化
just          # 命令运行器
lefthook      # Git 钩子管理

# 测试和监控
entr          # 文件监控
watchexec     # 命令自动执行
```

#### 工作流程

**1. GitHub Actions 工作流**

```bash
# 创建工作流目录
mkdir -p .github/workflows

# 使用 gh 管理工作流
gh workflow list
gh workflow view ci.yml
gh run list
gh run view <run-id>

# 查看工作流日志
gh run view <run-id> --log

# 重新运行失败的工作流
gh run rerun <run-id>
```

**2. 本地 CI/CD 流程**

```bash
# 使用 just 定义任务
cat > justfile << EOF
# 默认任务: 运行所有检查
default: lint test build

# 代码格式化
fmt:
    prettier --write .
    cargo fmt

# 代码检查
lint:
    eslint src
    cargo clippy

# 运行测试
test:
    npm test
    cargo test

# 构建
build:
    npm run build
    cargo build --release

# 部署到 staging
deploy-staging:
    gh workflow run deploy.yml -f environment=staging

# 部署到 production
deploy-production:
    gh workflow run deploy.yml -f environment=production

# CI 模拟 (本地运行所有 CI 步骤)
ci: fmt lint test build
    @echo "✅ All CI checks passed!"
EOF

# 运行本地 CI
just ci
```

**3. Git Hooks 管理**

```bash
# 安装 lefthook
lefthook install

# 配置 lefthook.yml
cat > lefthook.yml << EOF
pre-commit:
  parallel: true
  commands:
    fmt:
      glob: "*.{js,ts,tsx}"
      run: prettier --write {staged_files}
      stage_fixed: true

    lint:
      glob: "*.{js,ts,tsx}"
      run: eslint {staged_files}

    test:
      run: npm test -- --bail --findRelatedTests {staged_files}

pre-push:
  commands:
    test-all:
      run: npm test

    build:
      run: npm run build

commit-msg:
  commands:
    conventional:
      run: |
        if ! grep -qE '^(feat|fix|docs|style|refactor|test|chore)(\(.+\))?: .+' {1}; then
          echo "❌ Commit message must follow Conventional Commits format"
          exit 1
        fi
EOF

# 运行钩子
lefthook run pre-commit
```

**4. 监控文件变化自动测试**

```bash
# 使用 entr 监控文件变化
ls src/**/*.ts | entr -c npm test

# 使用 watchexec (更强大)
watchexec -e ts,tsx -r npm test

# 监控并运行自定义命令
watchexec -e go -r just test

# 使用 just 定义监控任务
cat > justfile << EOF
# 监控模式: 自动测试
watch-test:
    watchexec -e ts,tsx -r npm test

# 监控模式: 自动构建
watch-build:
    watchexec -e ts,tsx -r npm run build

# 监控模式: 自动格式化
watch-fmt:
    watchexec -e ts,tsx -r prettier --write .
EOF
```

**5. GitHub CLI 自动化**

```bash
# 创建 PR
gh pr create \
  --title "feat: add new feature" \
  --body "$(cat CHANGELOG.md)" \
  --label enhancement \
  --reviewer @me

# 查看 PR 检查状态
gh pr checks

# 合并 PR
gh pr merge --squash --delete-branch

# 创建 Release
gh release create v1.0.0 \
  --title "Release v1.0.0" \
  --notes "$(git cliff --latest)" \
  --target main

# 使用 just 自动化 release 流程
cat > justfile << EOF
# 创建新版本
release version:
    git tag -a {{version}} -m "Release {{version}}"
    git push origin {{version}}
    gh release create {{version}} \
      --title "Release {{version}}" \
      --notes "$(git cliff --latest)"
EOF
```

#### 配置建议

**GitHub Actions** (`.github/workflows/ci.yml`):

```yaml
name: CI

on:
  push:
    branches: [main]
  pull_request:
    branches: [main]

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - name: Setup Node.js
        uses: actions/setup-node@v4
        with:
          node-version: 20
          cache: "pnpm"

      - name: Install dependencies
        run: pnpm install

      - name: Run linter
        run: pnpm lint

      - name: Run tests
        run: pnpm test

      - name: Build
        run: pnpm build

  deploy:
    needs: test
    if: github.ref == 'refs/heads/main'
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - name: Deploy to production
        run: |
          echo "Deploying to production..."
```

**Just 配置** (`justfile`):

```just
# 设置默认 shell
set shell := ["zsh", "-cu"]

# 列出所有任务
default:
    @just --list

# 代码质量检查
lint:
    eslint src
    prettier --check .

# 自动修复
fix:
    eslint src --fix
    prettier --write .

# 运行测试
test:
    npm test

# 构建
build:
    npm run build

# 完整 CI 流程
ci: lint test build

# 部署
deploy environment:
    @echo "Deploying to {{environment}}..."
    gh workflow run deploy.yml -f environment={{environment}}
```

#### 社区最佳实践

1. **使用 lefthook 而非 husky**: 更快的 Git hooks，支持并行执行

2. **使用 just 而非 Makefile**: 更简洁的语法，更好的跨平台支持

3. **使用 gh CLI**: 直接在终端管理 GitHub 资源

4. **使用 watchexec 而非 nodemon**: 更通用，支持任何语言

---

### 3. 基础设施即代码 (Terraform/Ansible)

#### 适用人群

- 基础设施工程师
- 云平台管理员
- DevOps 自动化专家

#### 推荐工具组合

```bash
# IaC 工具
terraform     # 基础设施管理
ansible       # 配置管理

# 版本控制
lazygit       # Git 可视化
git-delta     # 差异查看

# 辅助工具
jq            # JSON 处理
yq            # YAML 处理
```

#### 工作流程

**1. Terraform 项目初始化**

```bash
# 创建项目结构
mkdir -p terraform/{modules,environments/{dev,staging,prod}}
cd terraform

# 初始化 Terraform
terraform init

# 使用 just 管理 Terraform 任务
cat > justfile << EOF
# 格式化代码
fmt:
    terraform fmt -recursive

# 验证配置
validate:
    terraform validate

# 规划变更 (dev)
plan env="dev":
    cd environments/{{env}} && terraform plan

# 应用变更
apply env="dev":
    cd environments/{{env}} && terraform apply

# 销毁资源
destroy env="dev":
    cd environments/{{env}} && terraform destroy

# 显示状态
show env="dev":
    cd environments/{{env}} && terraform show
EOF
```

**2. Terraform 模块开发**

```bash
# 创建模块
mkdir -p modules/vpc
cat > modules/vpc/main.tf << EOF
variable "vpc_cidr" {
  description = "CIDR block for VPC"
  type        = string
  default     = "10.0.0.0/16"
}

resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name = "main-vpc"
  }
}

output "vpc_id" {
  value = aws_vpc.main.id
}
EOF

# 使用 watchexec 监控变化并验证
watchexec -e tf -r just validate
```

**3. Ansible Playbook 开发**

```bash
# 创建项目结构
mkdir -p ansible/{playbooks,roles,inventory}
cd ansible

# 创建 inventory
cat > inventory/hosts.yml << EOF
all:
  children:
    webservers:
      hosts:
        web1:
          ansible_host: 192.168.1.10
        web2:
          ansible_host: 192.168.1.11

    databases:
      hosts:
        db1:
          ansible_host: 192.168.1.20
EOF

# 创建 playbook
cat > playbooks/setup.yml << EOF
---
- name: Setup web servers
  hosts: webservers
  become: true

  tasks:
    - name: Install nginx
      apt:
        name: nginx
        state: present
        update_cache: yes

    - name: Start nginx
      service:
        name: nginx
        state: started
        enabled: yes
EOF

# 使用 just 管理 Ansible
cat > justfile << EOF
# 检查语法
lint:
    ansible-playbook playbooks/setup.yml --syntax-check

# 测试 (check mode)
check:
    ansible-playbook playbooks/setup.yml --check

# 执行 playbook
run playbook:
    ansible-playbook playbooks/{{playbook}}.yml

# 限制到特定主机
run-host playbook host:
    ansible-playbook playbooks/{{playbook}}.yml --limit {{host}}
EOF
```

**4. 状态管理和变更追踪**

```bash
# 使用 lazygit 管理 IaC 代码
lazygit

# 查看 Terraform 计划差异
terraform plan | bat

# 使用 git-delta 查看代码变更
git diff main.tf  # 自动使用 delta 高亮

# 使用 jq 处理 Terraform 输出
terraform show -json | jq '.values.root_module.resources[]'

# 使用 yq 处理 Ansible 配置
yq eval '.all.children.webservers.hosts' inventory/hosts.yml
```

**5. 多环境管理**

```bash
# 使用 direnv 管理环境变量
cat > .envrc << EOF
# Dev environment
export TF_VAR_environment=dev
export AWS_PROFILE=dev

# Staging (uncomment when needed)
# export TF_VAR_environment=staging
# export AWS_PROFILE=staging

# Production (uncomment when needed)
# export TF_VAR_environment=production
# export AWS_PROFILE=production
EOF

direnv allow

# 使用 just 切换环境
cat > justfile << EOF
# 切换到 dev
env-dev:
    sed -i '' 's/^# export TF_VAR_environment=dev/export TF_VAR_environment=dev/' .envrc
    direnv allow

# 切换到 staging
env-staging:
    sed -i '' 's/^# export TF_VAR_environment=staging/export TF_VAR_environment=staging/' .envrc
    direnv allow

# 显示当前环境
env-show:
    @echo "Current environment: $TF_VAR_environment"
EOF
```

#### 配置建议

**Terraform 后端配置** (`backend.tf`):

```hcl
terraform {
  backend "s3" {
    bucket         = "my-terraform-state"
    key            = "prod/terraform.tfstate"
    region         = "us-east-1"
    encrypt        = true
    dynamodb_table = "terraform-locks"
  }

  required_version = ">= 1.6.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}
```

**Ansible 配置** (`ansible.cfg`):

```ini
[defaults]
inventory = inventory/hosts.yml
remote_user = ansible
host_key_checking = False
retry_files_enabled = False

[privilege_escalation]
become = True
become_method = sudo
become_user = root
become_ask_pass = False

[ssh_connection]
pipelining = True
```

#### 社区最佳实践

1. **使用 Terraform workspaces**: 管理多环境

```bash
terraform workspace new dev
terraform workspace new staging
terraform workspace new prod
terraform workspace list
terraform workspace select dev
```

2. **使用 Ansible roles**: 复用配置

```bash
ansible-galaxy init roles/nginx
ansible-galaxy install geerlingguy.docker
```

3. **使用 pre-commit hooks**: 自动格式化和验证

```yaml
# .pre-commit-config.yaml
repos:
  - repo: https://github.com/antonbabenko/pre-commit-terraform
    rev: v1.83.0
    hooks:
      - id: terraform_fmt
      - id: terraform_validate
```

---

### 4. 监控和可观测性

#### 适用人群

- SRE 工程师
- 运维监控专家
- 性能分析工程师

#### 推荐工具组合

```bash
# 系统监控
btop          # 系统资源监控
glances       # 跨平台监控
bottom        # Rust 系统监控

# 网络监控
gping         # 可视化 ping
trippy        # 网络诊断
bandwhich     # 带宽监控

# 日志分析
lnav          # 日志浏览器
bat           # 日志查看
```

#### 工作流程

**1. 系统监控**

```bash
# 使用 btop 监控系统
btop

# btop 快捷键:
# f - 过滤进程
# k - 杀死进程
# s - 排序
# m - 菜单

# 使用 glances (更适合服务器)
glances

# 远程监控
glances -s  # 服务端
glances -c <server-ip>  # 客户端

# 使用 bottom (Rust 实现)
btm

# 自定义配置
btm --color default-light --tree
```

**2. 进程监控**

```bash
# 使用 procs 替代 ps
procs

# 树形显示
procs --tree

# 监控特定进程
procs --watch --or node nginx postgres

# 监控 CPU 使用率
procs --sortd cpu

# 使用 bandwhich 监控网络
sudo bandwhich

# bandwhich 快捷键:
# Space - 暂停
# Tab - 切换视图
# Esc - 退出
```

**3. 网络诊断**

```bash
# 使用 gping 可视化 ping
gping google.com cloudflare.com

# 使用 trippy 追踪路由
trip google.com

# 高级选项
trip google.com --mode paris  # Paris traceroute
trip google.com --protocol udp

# 使用 doggo 查询 DNS
doggo google.com

# 查询特定记录
doggo google.com A AAAA MX
doggo @8.8.8.8 google.com  # 指定 DNS 服务器
```

**4. 日志分析**

```bash
# 使用 lnav 分析日志
lnav /var/log/nginx/access.log

# lnav 快捷键:
# / - 搜索
# i - 显示直方图
# t - 切换文本视图
# q - 过滤查询
# Shift+p - 显示分析

# 合并多个日志文件
lnav /var/log/nginx/*.log

# 使用 bat 查看日志 (语法高亮)
bat /var/log/nginx/error.log

# 实时监控日志
tail -f /var/log/nginx/access.log | bat --paging=never -l log

# 使用 just 管理监控任务
cat > justfile << EOF
# 查看 nginx 访问日志
nginx-access:
    lnav /var/log/nginx/access.log

# 查看 nginx 错误日志
nginx-error:
    bat /var/log/nginx/error.log

# 实时监控应用日志
watch-logs service:
    tail -f /var/log/{{service}}/*.log | bat --paging=never -l log
EOF
```

**5. 性能分析**

```bash
# 使用 hyperfine 测试性能
hyperfine 'curl http://localhost:8000/api/health'

# 对比不同实现
hyperfine \
  --warmup 3 \
  'curl http://localhost:8000/v1/users' \
  'curl http://localhost:8000/v2/users'

# 导出结果
hyperfine \
  --export-markdown benchmark.md \
  --export-json benchmark.json \
  'curl http://localhost:8000/api'

# 监控磁盘使用
dust
duf

# 使用 just 定义基准测试
cat > justfile << EOF
# 运行性能测试
bench:
    hyperfine \
      --warmup 5 \
      --runs 100 \
      'curl http://localhost:8000/api/health'

# 对比性能
bench-compare:
    hyperfine \
      --warmup 3 \
      'node server.js' \
      'deno run server.ts' \
      'bun server.ts'
EOF
```

#### 配置建议

**btop 配置** (`~/.config/btop/btop.conf`):

```ini
color_theme = "Default"
theme_background = True
truecolor = True
force_tty = False
vim_keys = True
rounded_corners = True
graph_symbol = "braille"
update_ms = 2000
proc_sorting = "cpu lazy"
proc_tree = False
```

**glances 配置** (`~/.config/glances/glances.conf`):

```ini
[global]
check_update=false
refresh=2

[cpu]
user_careful=50
user_warning=70
user_critical=90

[mem]
careful=50
warning=70
critical=90

[fs]
careful=50
warning=70
critical=90
```

**lnav 配置** (`~/.lnav/formats/myapp.json`):

```json
{
  "myapp_log": {
    "title": "MyApp Log Format",
    "description": "Custom log format for MyApp",
    "regex": {
      "std": {
        "pattern": "^(?<timestamp>\\d{4}-\\d{2}-\\d{2}T\\d{2}:\\d{2}:\\d{2}\\.\\d{3}Z) \\[(?<level>\\w+)\\] (?<message>.*)$"
      }
    },
    "level-field": "level",
    "timestamp-field": "timestamp",
    "value": {
      "level": {
        "kind": "string",
        "identifier": true
      },
      "message": {
        "kind": "string"
      }
    }
  }
}
```

#### 社区最佳实践

1. **使用 btop 替代 htop**: 更现代的界面和更多功能

2. **使用 lnav 分析日志**: 比 less/tail 更强大

3. **使用 gping 而非 ping**: 可视化网络延迟

4. **使用 trippy 诊断网络**: 比 traceroute 更详细

---

### 5. 安全和合规

#### 适用人群

- 安全工程师
- DevSecOps 专家
- 合规审计人员

#### 推荐工具组合

```bash
# 安全扫描
trivy         # 容器镜像扫描
grype         # 漏洞扫描
syft          # SBOM 生成
gitleaks      # 密钥泄露扫描

# 加密工具
age           # 现代加密
gpg           # GPG 加密 (macOS)
```

#### 工作流程

**1. 容器镜像安全扫描**

```bash
# 使用 trivy 扫描镜像
trivy image myapp:latest

# 扫描特定严重级别
trivy image --severity HIGH,CRITICAL myapp:latest

# 生成报告
trivy image --format json --output report.json myapp:latest

# 扫描文件系统
trivy fs .

# 使用 grype 扫描
grype myapp:latest

# 对比两个工具
trivy image myapp:latest > trivy-report.txt
grype myapp:latest > grype-report.txt
bat trivy-report.txt grype-report.txt
```

**2. SBOM (软件物料清单) 生成**

```bash
# 使用 syft 生成 SBOM
syft myapp:latest

# 生成不同格式
syft myapp:latest -o json > sbom.json
syft myapp:latest -o spdx-json > sbom.spdx.json
syft myapp:latest -o cyclonedx-json > sbom.cyclonedx.json

# 扫描目录
syft dir:.

# 使用 just 自动化
cat > justfile << EOF
# 生成 SBOM
sbom:
    syft . -o spdx-json > sbom.spdx.json
    syft . -o cyclonedx-json > sbom.cyclonedx.json

# 扫描漏洞
scan:
    trivy image --severity HIGH,CRITICAL myapp:latest
    grype myapp:latest

# 完整安全检查
security-check: sbom scan
    @echo "✅ Security check complete"
EOF
```

**3. 代码密钥扫描**

```bash
# 使用 gitleaks 扫描仓库
gitleaks detect --verbose

# 扫描特定分支
gitleaks detect --source . --branch main

# 生成报告
gitleaks detect --report-path gitleaks-report.json

# 扫描历史提交
gitleaks detect --log-opts="--all"

# 使用 lefthook 在 commit 前扫描
cat > lefthook.yml << EOF
pre-commit:
  commands:
    gitleaks:
      run: gitleaks protect --staged --verbose
EOF

lefthook install
```

**4. 加密和密钥管理**

```bash
# 使用 age 加密文件
age-keygen -o key.txt
age -r $(cat key.txt.pub) -o secrets.enc secrets.txt

# 解密
age -d -i key.txt secrets.enc > secrets.txt

# 使用 gpg (macOS)
gpg --gen-key
gpg --encrypt --recipient your@email.com secrets.txt
gpg --decrypt secrets.txt.gpg > secrets.txt

# 使用 just 管理密钥
cat > justfile << EOF
# 加密文件
encrypt file:
    age -r $(cat ~/.age/key.pub) -o {{file}}.enc {{file}}
    rm {{file}}

# 解密文件
decrypt file:
    age -d -i ~/.age/key.txt {{file}}.enc > {{file}}
    rm {{file}}.enc

# 生成随机密钥
gen-key:
    openssl rand -base64 32
EOF
```

**5. 合规审计**

```bash
# 使用 just 创建审计报告
cat > justfile << EOF
# 生成完整审计报告
audit:
    @echo "=== Security Audit Report ==="
    @echo ""
    @echo "## Container Scanning"
    trivy image --severity HIGH,CRITICAL myapp:latest
    @echo ""
    @echo "## Secret Scanning"
    gitleaks detect --verbose
    @echo ""
    @echo "## SBOM"
    syft . -o spdx-json
    @echo ""
    @echo "## Dependencies"
    npm audit
    @echo ""
    @echo "=== Audit Complete ==="

# 导出审计报告
audit-export:
    mkdir -p audit-reports/$(date +%Y-%m-%d)
    trivy image --format json myapp:latest > audit-reports/$(date +%Y-%m-%d)/trivy.json
    gitleaks detect --report-path audit-reports/$(date +%Y-%m-%d)/gitleaks.json
    syft . -o spdx-json > audit-reports/$(date +%Y-%m-%d)/sbom.spdx.json
EOF
```

#### 配置建议

**Trivy 配置** (`.trivy.yaml`):

```yaml
severity:
  - HIGH
  - CRITICAL

ignore-unfixed: true

vulnerability:
  type:
    - os
    - library

cache:
  backend: fs
  dir: .trivy-cache
```

**Gitleaks 配置** (`.gitleaks.toml`):

```toml
title = "Gitleaks Config"

[extend]
useDefault = true

[[rules]]
id = "custom-api-key"
description = "Custom API Key"
regex = '''(?i)(api[_-]?key|apikey)['\"]?\s*[:=]\s*['\"]?([0-9a-zA-Z]{32,})'''

[[rules]]
id = "custom-token"
description = "Custom Token"
regex = '''(?i)(token|secret)['\"]?\s*[:=]\s*['\"]?([0-9a-zA-Z]{32,})'''
```

#### 社区最佳实践

1. **使用 trivy 作为 CI/CD 一部分**: 自动扫描容器镜像

```yaml
# .github/workflows/security.yml
- name: Run Trivy
  uses: aquasecurity/trivy-action@master
  with:
    image-ref: "myapp:${{ github.sha }}"
    format: "sarif"
    output: "trivy-results.sarif"
```

2. **使用 gitleaks 防止密钥泄露**: 在 pre-commit hook 中运行

3. **使用 age 而非 gpg**: 对于新项目，age 更简单易用

4. **定期生成 SBOM**: 使用 syft 跟踪依赖关系

---

### 6. 数据库管理

#### 适用人群

- 数据库管理员
- 后端开发工程师
- 数据工程师

#### 推荐工具组合

```bash
# SQL 客户端
pgcli         # PostgreSQL CLI (自动补全)
DBeaver       # 数据库 GUI (macOS)

# 备份工具
restic        # 快速安全备份

# 辅助工具
jq            # JSON 处理
bat           # SQL 文件查看
```

#### 工作流程

**1. 数据库连接和查询**

```bash
# 使用 pgcli 连接数据库
pgcli postgresql://user:password@localhost:5432/mydb

# 使用环境变量
export PGHOST=localhost
export PGPORT=5432
export PGDATABASE=mydb
export PGUSER=user
export PGPASSWORD=password
pgcli

# pgcli 特性:
# - 自动补全 (表名、列名、SQL 关键字)
# - 语法高亮
# - 智能历史记录
# - 多行编辑

# 常用命令
\dt          # 列出所有表
\d users     # 查看表结构
\dv          # 列出视图
\di          # 列出索引
\timing      # 显示查询时间
```

**2. 数据导入导出**

```bash
# 导出数据
pgcli -c "COPY users TO STDOUT CSV HEADER" > users.csv

# 导出 JSON 格式
pgcli -c "SELECT json_agg(t) FROM users t" > users.json

# 导入数据
pgcli -c "COPY users FROM STDIN CSV HEADER" < users.csv

# 使用 just 管理数据库任务
cat > justfile << EOF
# 导出表
export table:
    pgcli -c "COPY {{table}} TO STDOUT CSV HEADER" > {{table}}.csv

# 导入表
import table:
    pgcli -c "COPY {{table}} FROM STDIN CSV HEADER" < {{table}}.csv

# 备份数据库
backup:
    pg_dump -Fc mydb > backup_$(date +%Y%m%d).dump

# 恢复数据库
restore file:
    pg_restore -d mydb {{file}}
EOF
```

**3. 数据库备份**

```bash
# 初始化 restic 仓库
restic init --repo /backup/postgres

# 备份数据库
pg_dump -Fc mydb | restic backup --stdin --stdin-filename mydb.dump

# 或备份整个数据目录 (需要停止数据库)
restic backup /var/lib/postgresql/data

# 查看快照
restic snapshots

# 恢复备份
restic restore latest --target /tmp/restore

# 使用 just 自动化备份
cat > justfile << EOF
# 每日备份
backup-daily:
    pg_dump -Fc mydb | \
    restic backup --stdin \
      --stdin-filename mydb_$(date +%Y%m%d).dump \
      --tag daily

# 每周备份
backup-weekly:
    pg_dump -Fc mydb | \
    restic backup --stdin \
      --stdin-filename mydb_$(date +%Y%m%d).dump \
      --tag weekly

# 查看备份
backup-list:
    restic snapshots

# 恢复最新备份
backup-restore:
    restic restore latest --target /tmp/restore
    pg_restore -d mydb_restored /tmp/restore/mydb.dump

# 清理旧备份 (保留 7 天日备份, 4 周周备份)
backup-cleanup:
    restic forget --keep-daily 7 --keep-weekly 4 --prune
EOF
```

**4. 查询分析和优化**

```bash
# 使用 pgcli 分析查询
EXPLAIN ANALYZE SELECT * FROM users WHERE age > 30;

# 查看慢查询
SELECT query, calls, total_time, mean_time
FROM pg_stat_statements
ORDER BY mean_time DESC
LIMIT 10;

# 查看表大小
SELECT
  tablename,
  pg_size_pretty(pg_total_relation_size(schemaname||'.'||tablename)) AS size
FROM pg_tables
WHERE schemaname = 'public'
ORDER BY pg_total_relation_size(schemaname||'.'||tablename) DESC;

# 使用 just 定义常用查询
cat > justfile << EOF
# 查看慢查询
slow-queries:
    pgcli -c "SELECT query, calls, total_time, mean_time FROM pg_stat_statements ORDER BY mean_time DESC LIMIT 10"

# 查看表大小
table-sizes:
    pgcli -c "SELECT tablename, pg_size_pretty(pg_total_relation_size(schemaname||'.'||tablename)) AS size FROM pg_tables WHERE schemaname = 'public' ORDER BY pg_total_relation_size(schemaname||'.'||tablename) DESC"

# 查看索引使用情况
index-usage:
    pgcli -c "SELECT schemaname, tablename, indexname, idx_scan FROM pg_stat_user_indexes ORDER BY idx_scan"
EOF
```

**5. DBeaver GUI 管理** (macOS)

```bash
# 启动 DBeaver
open -a "DBeaver Community"

# DBeaver 特性:
# - 可视化查询构建器
# - ER 图生成
# - 数据导入导出向导
# - SQL 编辑器 (自动补全, 语法高亮)
# - 多数据库支持
```

#### 配置建议

**pgcli 配置** (`~/.config/pgcli/config`):

```ini
[main]
multi_line = True
syntax_style = monokai
key_bindings = vi
enable_pager = True
auto_expand = False

[colors]
Token.Menu.Completions.Completion.Current = 'bg:#00aaaa #000000'
Token.Menu.Completions.Completion = 'bg:#008888 #ffffff'
Token.Menu.Completions.Meta.Current = 'bg:#44aaaa #000000'
Token.Menu.Completions.Meta = 'bg:#448888 #ffffff'
```

**Restic 备份配置** (`~/.config/restic/backup.sh`):

```bash
#!/usr/bin/env bash

# 备份配置
export RESTIC_REPOSITORY="/backup/postgres"
export RESTIC_PASSWORD_FILE="~/.config/restic/password.txt"

# 备份前钩子: 创建数据库转储
pg_dump -Fc mydb > /tmp/mydb.dump

# 执行备份
restic backup /tmp/mydb.dump \
  --tag postgres \
  --tag daily

# 清理
rm /tmp/mydb.dump

# 保留策略
restic forget \
  --keep-daily 7 \
  --keep-weekly 4 \
  --keep-monthly 12 \
  --prune
```

#### 社区最佳实践

1. **使用 pgcli 而非 psql**: 更好的用户体验

2. **使用 restic 备份**: 增量备份，去重，加密

3. **定期运行 VACUUM**: 保持数据库性能

```sql
-- 自动 VACUUM (推荐)
ALTER TABLE users SET (autovacuum_enabled = true);

-- 手动 VACUUM
VACUUM ANALYZE users;
```

4. **使用连接池**: 减少连接开销

```bash
# 安装 pgbouncer
brew install pgbouncer

# 配置 pgbouncer
cat > pgbouncer.ini << EOF
[databases]
mydb = host=localhost port=5432 dbname=mydb

[pgbouncer]
listen_addr = 127.0.0.1
listen_port = 6432
auth_type = md5
auth_file = userlist.txt
pool_mode = transaction
max_client_conn = 100
default_pool_size = 20
EOF
```

---

## 通用工作流

### 1. Git 工作流

#### 适用人群

- 所有开发者
- 协作团队成员
- 开源贡献者

#### 推荐工具组合

```bash
# Git 工具
lazygit       # 可视化 Git 操作
git-delta     # 差异查看
gh            # GitHub CLI
git-cliff     # Changelog 生成
onefetch      # 仓库信息展示

# Git 钩子
lefthook      # Git hooks 管理
```

#### 工作流程

**1. 日常 Git 操作**

```bash
# 使用 lazygit 进行可视化操作
lazygit

# lazygit 常用快捷键:
# 1 - 文件面板
# 2 - 分支面板
# 3 - 提交面板
# 4 - Stash 面板
# Space - 暂存/取消暂存
# c - 提交
# P - 推送
# p - 拉取
# x - 打开菜单
# ? - 帮助

# 查看差异 (自动使用 delta)
git diff
git diff --staged

# 查看日志
git log  # 使用 delta 美化显示
```

**2. 分支管理**

```bash
# 在 lazygit 中:
# - 按 2 进入分支面板
# - Space 切换分支
# - n 创建新分支
# - M 合并分支
# - r 变基
# - d 删除分支

# 命令行操作
git switch -c feature/new-feature
git switch main

# 查看分支图
git log --graph --oneline --all
```

**3. 提交管理**

```bash
# 使用 Conventional Commits 格式
git commit -m "feat: add new dashboard component"
git commit -m "fix: resolve login issue"
git commit -m "docs: update API documentation"
git commit -m "refactor: simplify authentication logic"

# 使用 lefthook 自动验证提交信息
cat > lefthook.yml << EOF
commit-msg:
  commands:
    conventional:
      run: |
        if ! grep -qE '^(feat|fix|docs|style|refactor|test|chore)(\(.+\))?: .+' {1}; then
          echo "❌ Commit message must follow Conventional Commits"
          exit 1
        fi
EOF

lefthook install
```

**4. 生成 Changelog**

```bash
# 使用 git-cliff 生成 Changelog
git cliff --output CHANGELOG.md

# 只生成最新版本
git cliff --latest

# 生成指定范围
git cliff --tag v1.0.0..v2.0.0

# 配置 git-cliff
cat > cliff.toml << EOF
[changelog]
header = """
# Changelog
All notable changes to this project will be documented in this file.
"""
body = """
{% for group, commits in commits | group_by(attribute="group") %}
### {{ group | upper_first }}
{% for commit in commits %}
- {{ commit.message | upper_first }} ({{ commit.id | truncate(length=7, end="") }})
{%- endfor %}
{% endfor %}
"""

[git]
conventional_commits = true
filter_unconventional = true
commit_parsers = [
  { message = "^feat", group = "Features" },
  { message = "^fix", group = "Bug Fixes" },
  { message = "^docs", group = "Documentation" },
  { message = "^perf", group = "Performance" },
  { message = "^refactor", group = "Refactoring" },
  { message = "^style", group = "Styling" },
  { message = "^test", group = "Testing" },
  { message = "^chore", group = "Miscellaneous" },
]
EOF
```

**5. GitHub 工作流**

```bash
# 使用 gh CLI
gh auth login

# 创建 PR
gh pr create \
  --title "Add new feature" \
  --body "This PR adds..." \
  --label enhancement \
  --reviewer @teammate

# 查看 PR 状态
gh pr list
gh pr view 123
gh pr checks

# 合并 PR
gh pr merge 123 --squash --delete-branch

# 创建 Issue
gh issue create \
  --title "Bug: login fails" \
  --body "Steps to reproduce..."

# 查看仓库信息
gh repo view

# 使用 onefetch 显示仓库统计
onefetch
```

#### 配置建议

**Git 配置** (`~/.gitconfig`):

```ini
[user]
    name = Your Name
    email = your@email.com

[core]
    pager = delta

[interactive]
    diffFilter = delta --color-only

[delta]
    navigate = true
    line-numbers = true
    side-by-side = true
    syntax-theme = Monokai Extended

[merge]
    conflictstyle = diff3

[diff]
    colorMoved = default

[alias]
    lg = log --graph --oneline --all
    st = status -sb
    co = checkout
    br = branch
    cm = commit -m
    aa = add --all
```

**Lazygit 配置** (`~/.config/lazygit/config.yml`):

```yaml
gui:
  theme:
    activeBorderColor:
      - "#ff9e64"
      - bold
    inactiveBorderColor:
      - "#27a1b9"

  showIcons: true
  nerdFontsVersion: "3"

git:
  paging:
    colorArg: always
    pager: delta --dark --paging=never

  commit:
    signOff: false

  merging:
    args: --no-ff

customCommands:
  - key: "C"
    command: "git cliff --output CHANGELOG.md"
    description: "Generate changelog"
    context: "global"
```

#### 社区最佳实践

1. **使用 Conventional Commits**: 标准化提交信息

2. **使用 lazygit**: 提升 Git 操作效率

3. **使用 git-cliff**: 自动生成 Changelog

4. **使用 gh CLI**: 直接在终端管理 GitHub

```bash
# 创建 Release
gh release create v1.0.0 \
  --title "Release v1.0.0" \
  --notes "$(git cliff --latest)" \
  --target main
```

---

### 2. 终端工作流

#### 适用人群

- 所有开发者
- 系统管理员
- 重度命令行用户

#### 推荐工具组合

```bash
# Shell 环境
zsh           # 强大的 shell
starship      # 美观的提示符
sheldon       # 插件管理器
atuin         # 历史记录同步

# 终端复用
tmux          # 传统终端复用
zellij        # 现代终端工作区

# 文件管理
yazi          # 终端文件管理器
eza           # 现代 ls
bat           # 现代 cat
fd            # 现代 find
ripgrep       # 现代 grep
```

#### 工作流程

**1. Shell 配置**

```bash
# Starship 配置 (~/.config/starship/starship.toml)
cat > ~/.config/starship/starship.toml << EOF
format = """
[╭─](#9ece6a)\$username\$hostname\$directory\$git_branch\$git_status
[╰─](#9ece6a)\$character
"""

[username]
format = "[$user]($style)@"
style_user = "bold #7aa2f7"
show_always = true

[hostname]
format = "[$hostname]($style) "
style = "bold #bb9af7"
ssh_only = false

[directory]
format = "[$path]($style) "
style = "bold #7dcfff"
truncation_length = 3

[git_branch]
format = "[$symbol$branch]($style) "
symbol = " "
style = "bold #9ece6a"

[git_status]
format = '([\[$all_status$ahead_behind\]]($style) )'
style = "bold #f7768e"

[character]
success_symbol = "[➜](#9ece6a)"
error_symbol = "[➜](#f7768e)"
EOF

# 测试配置
starship preset tokyo-night
```

**2. Zellij 工作区**

```bash
# 启动 Zellij
zellij

# Zellij 常用快捷键 (默认 Ctrl+g 前缀):
# Ctrl+g, p - 面板管理模式
# Ctrl+g, t - 标签管理模式
# Ctrl+g, n - 新建面板
# Ctrl+g, c - 新建标签
# Ctrl+g, w - 写入文件
# Ctrl+g, q - 退出

# 创建自定义布局 (~/.config/zellij/layouts/dev.kdl)
layout {
    default_tab_template {
        pane size=1 borderless=true {
            plugin location="zellij:tab-bar"
        }
        children
        pane size=2 borderless=true {
            plugin location="zellij:status-bar"
        }
    }

    tab name="Editor" {
        pane split_direction="vertical" {
            pane command="nvim"
            pane split_direction="horizontal" {
                pane
                pane
            }
        }
    }

    tab name="Git" {
        pane command="lazygit"
    }

    tab name="Monitor" {
        pane command="btop"
    }
}

# 使用布局启动
zellij --layout dev
```

**3. 文件管理**

```bash
# 使用 yazi 文件管理器
yazi

# yazi 快捷键:
# h/j/k/l - 导航
# Space - 选择
# Enter - 打开
# y - 复制
# x - 剪切
# p - 粘贴
# d - 删除
# / - 搜索
# : - 命令模式

# 使用 eza 列出文件
eza --long --git --icons
eza --tree --level=2

# 使用 bat 查看文件
bat README.md
bat --style=numbers,changes src/main.rs

# 使用 fd 查找文件
fd '\.js$'
fd -e py -x wc -l

# 使用 ripgrep 搜索内容
rg "TODO" --type rust
rg -i "error" --context 3
```

**4. 历史记录管理**

```bash
# 使用 atuin 同步历史记录
atuin login
atuin sync

# Atuin 快捷键 (默认 Ctrl+r):
# Ctrl+r - 搜索历史
# Up - 向上导航
# Down - 向下导航
# Tab - 切换过滤模式

# 配置 atuin (~/.config/atuin/config.toml)
cat > ~/.config/atuin/config.toml << EOF
auto_sync = true
sync_frequency = "5m"
search_mode = "fuzzy"
filter_mode = "global"
style = "compact"
inline_height = 20
show_preview = true
EOF
```

**5. 使用 tmux (备选)**

```bash
# 启动 tmux
tmux new -s dev

# tmux 常用快捷键 (默认 Ctrl+b 前缀):
# Ctrl+b, c - 新建窗口
# Ctrl+b, % - 垂直分屏
# Ctrl+b, " - 水平分屏
# Ctrl+b, o - 切换面板
# Ctrl+b, [ - 进入复制模式
# Ctrl+b, d - 分离会话

# 恢复会话
tmux attach -t dev

# 列出会话
tmux ls
```

#### 配置建议

**Zsh 配置** (`~/.zshrc`):

```bash
# 启用 Starship
eval "$(starship init zsh)"

# 启用 zoxide
eval "$(zoxide init zsh)"

# 启用 atuin
eval "$(atuin init zsh)"

# 启用 direnv
eval "$(direnv hook zsh)"

# 启用 mise
eval "$(mise activate zsh)"

# 加载 sheldon 插件
eval "$(sheldon source)"

# 别名
alias ls='eza --icons'
alias ll='eza -l --git --icons'
alias la='eza -la --git --icons'
alias lt='eza --tree --level=2 --icons'
alias cat='bat'
alias find='fd'
alias grep='rg'
alias vim='nvim'
alias g='lazygit'

# 函数
function mkcd() {
    mkdir -p "$1" && cd "$1"
}

function extract() {
    if [ -f "$1" ]; then
        ouch decompress "$1"
    else
        echo "File not found: $1"
    fi
}
```

**Sheldon 配置** (`~/.config/sheldon/plugins.toml`):

```toml
shell = "zsh"

[plugins.zsh-syntax-highlighting]
github = "zsh-users/zsh-syntax-highlighting"

[plugins.zsh-autosuggestions]
github = "zsh-users/zsh-autosuggestions"

[plugins.zsh-completions]
github = "zsh-users/zsh-completions"

[plugins.fzf-tab]
github = "Aloxaf/fzf-tab"
```

**Yazi 配置** (`~/.config/yazi/yazi.toml`):

```toml
[manager]
show_hidden = true
sort_by = "modified"
sort_reverse = true
linemode = "size"

[preview]
tab_size = 2
max_width = 600
max_height = 900

[opener]
edit = [
    { run = 'nvim "$@"', block = true },
]
```

#### 社区最佳实践

1. **使用 zellij 而非 tmux**: 更友好的默认配置和键绑定

2. **使用 starship**: 快速、可定制的提示符

3. **使用 atuin**: 跨设备同步历史记录

4. **使用 yazi**: 强大的终端文件管理器

---

### 3. 文档工作流

#### 适用人群

- 技术文档编写者
- 项目维护者
- API 文档管理员

#### 推荐工具组合

```bash
# Markdown 工具
glow          # Markdown 渲染器
vhs           # 终端录制工具

# 笔记管理
Obsidian      # 知识管理 (macOS)

# API 文档
httpie        # HTTP 客户端
bruno         # API 客户端 (macOS)

# 编辑器
neovim        # 文本编辑器
```

#### 工作流程

**1. Markdown 文档编写**

```bash
# 使用 neovim 编写
nvim README.md

# 实时预览 (使用 glow)
watchexec -e md -r glow README.md

# 使用 just 管理文档
cat > justfile << EOF
# 预览 Markdown
preview file:
    glow {{file}}

# 预览所有文档
preview-all:
    glow docs/*.md

# 生成 HTML
export file:
    glow {{file}} > {{file}}.html
EOF
```

**2. 终端录制 (演示和教程)**

```bash
# 创建 VHS 脚本
cat > demo.tape << EOF
Output demo.gif

Set Shell "zsh"
Set FontSize 20
Set Width 1200
Set Height 600

Type "echo 'Hello, World!'"
Sleep 500ms
Enter

Sleep 1s

Type "ls -la"
Sleep 500ms
Enter

Sleep 2s
EOF

# 录制
vhs demo.tape

# 生成 GIF 或 MP4
vhs demo.tape --output demo.mp4
```

**3. API 文档和测试**

```bash
# 使用 httpie 测试 API
http GET https://api.example.com/users

# 保存请求
http --session=dev GET https://api.example.com/users

# 下次使用相同会话
http --session=dev POST https://api.example.com/users name=John

# 使用 Bruno (macOS) 管理 API 集合
# 1. 创建集合
# 2. 添加请求
# 3. 组织文件夹
# 4. 使用变量
# 5. 编写测试脚本

# 导出 Bruno 集合到 Git
cat > .gitignore << EOF
# Bruno
bruno/environments/local.bru
EOF
```

**4. 使用 Obsidian 管理知识库** (macOS)

```bash
# 启动 Obsidian
open -a Obsidian

# Obsidian 推荐插件:
# - Dataview: 查询笔记
# - Templater: 模板系统
# - Kanban: 看板视图
# - Git: Git 集成

# 创建项目文档结构
mkdir -p ObsidianVault/{Projects,Daily,Resources,Templates}

# 使用 just 快速创建笔记
cat > justfile << EOF
# 创建每日笔记
daily:
    @date=$(date +%Y-%m-%d) && \
    cat > ObsidianVault/Daily/$date.md << NOTE
    # Daily Note - $date

    ## Tasks
    - [ ]

    ## Notes

    ## Links
    NOTE

# 创建项目笔记
project name:
    @cat > ObsidianVault/Projects/{{name}}.md << NOTE
    # {{name}}

    ## Overview

    ## Tasks

    ## Resources
    NOTE
EOF
```

**5. 文档自动化**

```bash
# 使用 just 自动化文档工作流
cat > justfile << EOF
# 生成 API 文档
api-docs:
    @echo "# API Documentation" > docs/API.md
    @echo "" >> docs/API.md
    http --print=hb GET https://api.example.com/docs >> docs/API.md

# 生成 Changelog
changelog:
    git cliff --output CHANGELOG.md
    glow CHANGELOG.md

# 预览所有文档
preview:
    glow docs/*.md

# 录制演示
demo:
    vhs demo.tape

# 部署文档 (例如到 GitHub Pages)
deploy:
    mkdocs gh-deploy

# 完整文档构建流程
build: changelog api-docs
    @echo "✅ Documentation built successfully"
EOF
```

#### 配置建议

**Glow 配置** (`~/.config/glow/glow.yml`):

```yaml
# style: auto, dark, light
style: "auto"

# show local files only; no network
local: false

# mouse wheel support
mouse: true

# use pager for output
pager: true

# word-wrap at width
width: 80
```

**VHS 配置** (录制脚本模板):

```tape
# VHS 录制模板

Output demo.gif

# 设置
Set Shell "zsh"
Set FontSize 18
Set FontFamily "JetBrains Mono"
Set Width 1200
Set Height 600
Set Theme "Tokyo Night"
Set TypingSpeed 100ms
Set PlaybackSpeed 1.0

# 命令
Type "# 演示开始"
Sleep 1s
Enter

Type "ls -la"
Sleep 500ms
Enter

Sleep 2s

Type "# 演示结束"
Sleep 1s
```

**Neovim Markdown 配置**:

```lua
-- 安装 markdown 插件
return {
  {
    "preservim/vim-markdown",
    ft = "markdown",
    config = function()
      vim.g.vim_markdown_folding_disabled = 1
      vim.g.vim_markdown_frontmatter = 1
    end,
  },
  {
    "iamcco/markdown-preview.nvim",
    ft = "markdown",
    build = "cd app && npm install",
    config = function()
      vim.g.mkdp_auto_start = 0
      vim.g.mkdp_auto_close = 1
    end,
  },
}
```

#### 社区最佳实践

1. **使用 glow 预览 Markdown**: 比浏览器更快

2. **使用 VHS 录制终端**: 自动化演示生成

3. **使用 Obsidian 管理知识**: 双向链接和图谱

4. **使用 Bruno 而非 Postman**: 文件存储，便于版本控制

```bash
# Bruno 集合可以直接提交到 Git
git add bruno/
git commit -m "docs: add API collection"
```

5. **使用 httpie 生成文档示例**: 保存真实的 API 请求

```bash
# 保存请求示例
http --print=HhBb POST https://api.example.com/users \
  name=John email=john@example.com > docs/examples/create-user.txt
```

---

## 总结

本指南涵盖了基于 Homeup 工具集的 16 个实战场景:

**Dev 场景 (7 个)**:

1. 前端开发 - React/Vue/Angular
2. 后端开发 - Go/Python/Node.js
3. 全栈开发 - Monorepo
4. 移动开发 - React Native/Flutter
5. 数据科学/ML - Python/Jupyter
6. 系统编程 - Rust/C++
7. Web3/区块链 - Hardhat/Foundry

**Ops 场景 (6 个)**:

1. 容器化部署 - Docker/Kubernetes
2. CI/CD 流水线 - GitHub Actions
3. 基础设施即代码 - Terraform/Ansible
4. 监控和可观测性 - btop/lnav
5. 安全和合规 - trivy/gitleaks
6. 数据库管理 - pgcli/restic

**通用工作流 (3 个)**:

1. Git 工作流 - lazygit/git-cliff
2. 终端工作流 - zsh/zellij/yazi
3. 文档工作流 - glow/Obsidian/Bruno

每个场景都提供了:

- 适用人群
- 核心工具组合
- 详细工作流程
- 配置建议
- 社区最佳实践

希望这份指南能帮助你充分发挥 Homeup 工具集的优势，提升开发和运维效率。
