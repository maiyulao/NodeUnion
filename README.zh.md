# NodeUnion

基于 [FlClash](https://github.com/chen08209/FlClash) 二次开发的跨平台代理客户端，面向「机场」运营场景：在保留 Clash.Meta (mihomo) 完整代理能力的同时，通过远程品牌配置接入机场门户与可选广告。

**语言：** 中文 · [English](README.md)

官方 Telegram 频道：[t.me/NodeUnion](http://t.me/NodeUnion)

| 平台 | 支持 |
|------|------|
| Android | ✅ |
| macOS | ✅ |
| Windows | ✅ |
| Linux | ✅ |
| iOS | 暂不支持 |

## 特性

- **完整代理能力**：配置导入/编辑、节点与策略组、规则与 DNS、连接与流量统计等（继承自 FlClash）
- **内置机场 WebView**：根据品牌配置加载机场站点，导航栏可显示自定义机场名称
- **远程品牌配置**：编译期注入加密配置地址与密钥；支持多 CDN 竞速拉取与本地缓存
- **可选 AdMob**：通过品牌配置远程开关 Banner / 插屏 / 原生 / 开屏广告及冷却策略
- **多语言**：中文、英文、日文、俄文

## 与 FlClash 的关系

本项目 fork 自 FlClash，在核心代理栈之上增加了机场 WebView、品牌配置与广告模块。上游致谢与依赖说明见应用内「关于」页面；使用与分发时请同时遵守 FlClash、Clash.Meta 及相关依赖的开源许可证。

## 快速开始

### 环境要求

- [Flutter](https://flutter.dev/) SDK **>= 3.8.0**
- [Go](https://go.dev/)（用于编译 Clash.Meta 内核）
- 目标平台对应的原生工具链（Android SDK / Visual Studio / Xcode（macOS 桌面）等）

### 克隆与依赖

```bash
git clone https://github.com/maiyulao/NodeUnion.git
cd NodeUnion
flutter pub get
```

### 编译内核

首次构建或更新 `core/` 子模块后，需要编译原生内核：

```bash
dart run setup.dart android   # 或 linux / windows / macos
```

`setup.dart` 会编译 Clash.Meta 并生成/更新 `env.json`（见下文）。

### 本地调试运行

未配置品牌参数时，代理功能仍可使用，但「机场」页会提示未配置：

```bash
flutter run
```

## 品牌配置（BrandConfig）

品牌配置用于下发机场名称、门户 URL，以及可选的广告参数。配置在**编译期**通过 `--dart-define` 注入，运行时从远程拉取** AES-GCM 加密**的 JSON。

### 1. 准备明文配置

复制示例并按需修改：

```bash
cp brand.plain.json.example brand.plain.json
```

明文 JSON 字段说明：

| 字段 | 类型 | 说明 |
|------|------|------|
| `airportName` | string | 机场显示名称（用于导航栏等） |
| `airportUrl` | string | 机场门户 URL（`http` / `https`） |
| `ads` | object | 可选；AdMob 单元 ID 与展示策略，默认 `enabled: false` |

`ads` 子字段见 `lib/models/brand_config_ads.dart` 与 `brand.plain.json.example`。

### 2. 生成加密配置并部署

使用项目自带工具加密（密钥为 **64 位十六进制**，即 32 字节 AES-256）：

```bash
dart run tools/encrypt_brand_config.dart \
  -i brand.plain.json \
  -k <your-64-hex-key> \
  -o brand.json
```

将生成的 `brand.json` 上传到 CDN 或静态存储。**不要将 `brand.plain.json`、`env.json` 或密钥提交到 Git**（已在 `.gitignore` 中忽略）。

### 3. 本地构建：env.json

复制环境配置模板：

```bash
cp env.json.example env.json
```

编辑 `env.json`：

```json
{
  "APP_ENV": "pre",
  "BRAND_CONFIG_URLS": "https://cdn-a.example.com/brand.json,https://cdn-b.example.com/brand.json",
  "BRAND_CONFIG_KEY": "<64-hex-aes-key>"
}
```

- `BRAND_CONFIG_URLS`：逗号分隔的加密配置 URL，客户端会并行请求并采用最先成功的结果
- `BRAND_CONFIG_KEY`：与加密时相同的十六进制密钥

使用 `dart-define-from-file` 构建：

```bash
dart run setup.dart android
flutter build apk --release --dart-define-from-file=env.json
```

也可直接传参：

```bash
flutter build apk --release \
  --dart-define=BRAND_CONFIG_URLS=https://cdn.example.com/brand.json \
  --dart-define=BRAND_CONFIG_KEY=<64-hex-key>
```

### 4. Android Release 签名

```bash
cp android/key.properties.example android/key.properties
# 编辑 keystore 路径与密码
flutter build apk --release --dart-define-from-file=env.json
```

未配置 `key.properties` 时，Release 构建会回退到 debug 签名，**仅适用于本地测试**。

## 各平台构建

在已执行 `dart run setup.dart <platform>` 的前提下：

| 平台 | 命令示例 |
|------|----------|
| Android APK | `dart run setup.dart android` |
| Windows | `dart run setup.dart windows` |
| Linux | `dart run setup.dart linux` |
| macOS | `dart run setup.dart macos` |

`setup.dart` 会通过 [flutter_distributor](https://github.com/leanflutter/flutter_distributor) 打包对应产物（如 `apk`、`exe`、`deb`、`dmg` 等），并自动把 `env.json` 中的 `dart-define` 传入 Flutter 构建。

仅编译内核、不打包应用：

```bash
dart run setup.dart android --out=core
```

## 项目结构（节选）

```
├── core/                 # Clash.Meta (mihomo) 子模块与 Go 构建
├── lib/                  # Flutter 应用代码
│   ├── common/brand.dart # 编译期品牌配置常量
│   ├── providers/        # 品牌配置拉取与状态
│   └── views/              # 含 airport_webview
├── setup.dart            # 内核编译与应用打包入口
├── tools/
│   └── encrypt_brand_config.dart
├── brand.plain.json.example
└── env.json.example
```

## 安全与合规

- **密钥与明文配置**：`env.json`、`brand.json`、`brand.plain.json` 已加入 `.gitignore`；发布前请确认历史中未泄露真实密钥
- **广告**：启用 AdMob 需在 Google AdMob 控制台创建应用与广告单元，并在 `AndroidManifest.xml` 中配置应用 ID（见项目内现有配置位）
- **许可证**：Clash.Meta 内核为 [GPL-3.0](https://github.com/MetaCubeX/mihomo/blob/main/LICENSE)；二次分发与修改请遵守 GPL 及 FlClash 上游要求

## 致谢

- [FlClash](https://github.com/chen08209/FlClash) — 上游 UI 与架构
- [Clash.Meta / mihomo](https://github.com/MetaCubeX/mihomo) — 代理内核

## 许可证

本项目基于 FlClash 二次开发。请遵循 FlClash、Clash.Meta (mihomo) 及各依赖项的开源许可证；若你计划公开发布或商用分发，请自行完成合规审查。
