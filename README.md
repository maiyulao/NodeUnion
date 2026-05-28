# 机场联盟

基于 [FlClash](https://github.com/chen08209/FlClash) 二次开发的机场代理客户端，使用 Clash.Meta (mihomo) 内核，支持 Android、iOS、macOS、Windows 和 Linux。

## 特性

- 继承 FlClash 的完整代理能力：配置管理、节点选择、规则/DNS、流量统计等
- **内置机场 WebView**：通过远程品牌配置加载机场服务页面
- **远程品牌配置**：编译时注入加密配置 URL，支持多源竞速拉取
- 多语言支持：中文、英文、日文、俄文

## 与 FlClash 的关系

本项目 fork 自 FlClash，在保留其核心功能的基础上，增加了机场场景所需的远程品牌配置与 WebView 集成。原项目致谢见应用内「关于」页面。

## 构建

### 环境要求

- Flutter SDK >= 3.8.0
- Go（用于编译内核）
- 各平台原生构建工具链

### 基础构建

```bash
flutter pub get
dart run setup.dart
flutter build apk
```

### 品牌配置（BrandConfig）

编译时需通过 `--dart-define` 注入远程品牌配置参数：

```bash
flutter build apk \
  --dart-define=BRAND_CONFIG_URLS=https://example.com/config1.json,https://example.com/config2.json \
  --dart-define=BRAND_CONFIG_KEY=your_hex_encryption_key
```

| 参数 | 说明 |
|------|------|
| `BRAND_CONFIG_URLS` | 逗号分隔的配置 URL 列表，支持多源竞速 |
| `BRAND_CONFIG_KEY` | AES 解密密钥（十六进制字符串） |

配置 JSON 格式：

```json
{
  "airportName": "机场名称",
  "airportUrl": "https://example.com"
}
```

### Android Release 签名

1. 复制 `android/key.properties.example` 为 `android/key.properties`
2. 填入 keystore 路径与密码
3. 执行 `flutter build apk --release`

未配置 `key.properties` 时，Release 构建将回退到 debug 签名（仅供本地测试）。

## CI 示例

```yaml
- name: Build APK
  run: |
    flutter pub get
    dart run setup.dart
    flutter build apk --release \
      --dart-define=BRAND_CONFIG_URLS=${{ secrets.BRAND_CONFIG_URLS }} \
      --dart-define=BRAND_CONFIG_KEY=${{ secrets.BRAND_CONFIG_KEY }}
```

## 许可证

本项目基于 FlClash 二次开发，请遵循原项目及相关依赖的开源许可证。
