# 减单 JianDan

一个用 SwiftUI + SwiftData 打造的个人极简生活 iOS App。

## 环境要求

- Xcode 15.3+
- iOS 17.0+ 部署目标
- [XcodeGen](https://github.com/yonaskolb/XcodeGen)（可选，用于重新生成 `.xcodeproj`）

## 工程结构

```
JianDan/
├── App/                 # @main 入口
├── Models/              # SwiftData @Model 数据模型
├── Views/               # SwiftUI 视图
├── Theme/               # 主题与设计系统
├── Services/            # 服务层（导入导出、通知等）
├── Components/          # 可复用 UI 组件
└── Resources/           # 资源（Assets.xcassets 等）
```

## 如何打开

### 方式 A：直接打开 Xcode 工程（推荐）

```bash
open JianDan.xcodeproj
```

### 方式 B：从 project.yml 重新生成

```bash
xcodegen generate
open JianDan.xcodeproj
```

## 构建

```bash
xcodebuild -project JianDan.xcodeproj \
  -scheme JianDan \
  -destination 'generic/platform=iOS Simulator' \
  -configuration Debug \
  CODE_SIGNING_ALLOWED=NO \
  build
```

## 测试

```bash
xcodebuild test \
  -project JianDan.xcodeproj \
  -scheme JianDan \
  -destination 'platform=iOS Simulator,name=iPhone 15' \
  CODE_SIGNING_ALLOWED=NO
```

## 外部依赖

无（Phase 1）。所有能力均使用 iOS 原生框架（SwiftUI + SwiftData）。
