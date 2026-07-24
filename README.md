# IDA 汉化工具箱

一个简洁高效的 macOS 辅助工具，用于为 [IDA Pro](https://hex-rays.com/ida-pro/) 提供中文界面支持和管理功能。

![Swift](https://img.shields.io/badge/Swift-5.0-orange.svg)
![Platform](https://img.shields.io/badge/platform-macOS-lightgrey.svg)
![License](https://img.shields.io/badge/license-MIT-blue.svg)

---

## ✨ 功能特性

### 🈶 汉化管理
- 自动扫描系统中的 IDA Professional 安装
- 一键安装/卸载中文界面补丁
- 支持多版本 IDA 共存管理
- 智能权限处理（自动请求管理员权限）

### 📚 翻译管理
- 内置 **3000+** 条专业翻译词条
- 支持实时搜索原文和译文
- 自定义翻译词条（支持增删改查）
- 自定义翻译持久化存储

### 🔑 IDA 激活
- 生成标准格式的 IDA 许可证文件
- 支持自定义用户名、邮箱、到期时间
- 自动为 IDA 核心库打补丁
- 完整的许可证验证机制

### 🛠️ 技术实现
- 基于 `DYLD_INSERT_LIBRARIES` 的动态库注入
- Wrapper 脚本机制，透明代理 IDA 启动
- 自动代码签名（`codesign --force --deep --sign -`）
- 智能权限提升（AppleScript `do shell script with administrator privileges`）

---

## 📸 界面预览

工具箱采用原生 SwiftUI 界面，包含四个主要功能模块：

| 模块 | 说明 |
|------|------|
| **汉化管理** | 安装或移除 IDA 的中文界面 |
| **翻译管理** | 浏览、搜索和自定义翻译词条 |
| **IDA 激活** | 生成许可证并激活 IDA |
| **关于** | 开发者信息和项目链接 |

---

## 🚀 快速开始

### 系统要求

- macOS 11.0 (Big Sur) 或更高版本
- Xcode 13.0+ （如需从源码编译）
- IDA Pro（任意版本）

### 安装方式

#### 方式一：直接运行（推荐）

1. 下载最新 Release 中的 `IDA汉化工具箱.app`
2. 拖入 `/Applications` 或任意位置
3. 双击启动

> ⚠️ 首次运行可能需要在「系统设置 → 隐私与安全性」中允许运行

#### 方式二：从源码编译

```bash
git clone https://github.com/Mac-XK/IDA-HanHua-Toolbox.git
cd IDA-HanHua-Toolbox
open IDA.xcodeproj
```

在 Xcode 中选择目标设备为「My Mac」，点击运行。

---

## 📖 使用指南

### 汉化 IDA

1. 打开「IDA 汉化工具箱」
2. 点击右上角「扫描」按钮，自动发现已安装的 IDA
3. 在顶部选择要汉化的 IDA 版本
4. 点击「安装汉化」按钮
5. 如需管理员权限，输入密码授权

安装完成后，重新启动 IDA 即可看到中文界面。

### 卸载汉化

在「汉化管理」页面，点击「卸载汉化」即可完全恢复原始文件。

### 管理翻译词条

1. 切换到「翻译管理」标签
2. 使用顶部搜索框查找词条
3. 点击右上角「添加翻译」创建自定义词条
4. 点击词条右侧的 🗑️ 图标可删除自定义词条

### 激活 IDA

1. 切换到「IDA 激活」标签
2. 配置许可证信息：
   - 用户名
   - 邮箱地址
   - 到期时间（格式：`2033-12-31 23:59:59`）
3. 点击「开始激活」
4. 重启 IDA 即可生效

---

## 🏗️ 项目结构

```
IDA/
├── IDAApp.swift                 # 应用入口
├── ViewModels/
│   └── AppState.swift           # 全局状态管理
├── Models/
│   └── IDAAppInfo.swift         # IDA 应用信息模型
├── Services/
│   ├── IDALocalizer.swift       # 汉化核心逻辑
│   ├── IDAActivator.swift       # 激活与许可证生成
│   ├── TranslationManager.swift # 翻译管理
│   └── IDABundle.swift          # 资源加载
├── Helpers/
│   └── PrivilegeHelper.swift    # 权限提升工具
├── Views/
│   ├── ContentView.swift        # 主界面
│   ├── LocalizationView.swift   # 汉化页面
│   ├── TranslationView.swift    # 翻译管理页面
│   ├── ActivationView.swift     # 激活页面
│   └── AboutView.swift          # 关于页面
└── Resources/
    └── Assets.xcassets/         # 应用图标和资源
```

---

## 🔧 技术细节

### 汉化原理

工具箱通过以下机制实现 IDA 中文界面：

1. **动态库注入**：将 `libIdaTranslateLib.dylib` 放置到 IDA 的 `Contents/MacOS` 目录
2. **Wrapper 脚本**：将原始 `ida`/`ida64` 等可执行文件重命名为 `*_orig`，创建 shell wrapper 脚本
3. **环境变量**：Wrapper 脚本通过 `DYLD_INSERT_LIBRARIES` 加载翻译动态库
4. **翻译文件**：`ida_translations.json` 包含所有 UI 字符串的中文翻译

### 激活原理

1. **许可证生成**：根据用户输入生成符合 IDA 格式的 JSON 许可证
2. **RSA 签名**：使用内置密钥对许可证进行签名
3. **二进制补丁**：修改 `libida.dylib` 和 `libida32.dylib` 中的验证逻辑
4. **插件解锁**：自动添加所有架构插件（HEXX86/HEXARM 等）和附加功能

### 权限处理

当 IDA 安装在受保护目录（如 `/Applications`）时，工具箱会：

1. 检测目标路径是否可写
2. 不可写时使用 AppleScript 请求管理员权限
3. 将操作脚本写入临时文件并以 root 身份执行
4. 操作完成后自动清理临时文件

---

## ⚠️ 注意事项

1. **备份重要数据**：本工具会修改 IDA 安装文件，建议先备份
2. **仅供学习研究**：本项目仅用于技术研究和学习目的
3. **遵守软件许可**：请遵守 IDA Pro 的官方许可协议
4. **macOS 安全提示**：首次运行可能需要手动授权，请在系统设置中允许
5. **版本兼容性**：不同版本的 IDA 可能需要重新汉化

---

## 🤝 贡献

欢迎提交 Issue 和 Pull Request！

1. Fork 本仓库
2. 创建特性分支 (`git checkout -b feature/AmazingFeature`)
3. 提交更改 (`git commit -m 'Add some AmazingFeature'`)
4. 推送到分支 (`git push origin feature/AmazingFeature`)
5. 开启 Pull Request

---

## 📄 许可证

本项目采用 MIT 许可证 - 详见 [LICENSE](LICENSE) 文件

---

## 👤 作者

- GitHub: [@Mac-XK](https://github.com/Mac-XK) | [@pxx917144686](https://github.com/pxx917144686)

---

## 🙏 致谢

- [Hex-Rays](https://hex-rays.com/) - IDA Pro 开发团队
- 所有为中文本地化做出贡献的开发者

---

**免责声明**：本软件仅供技术交流和学习研究使用。使用者应自行承担因使用本软件而产生的任何后果。开发者不对任何直接或间接损失负责。
