# 减单 (JianDan) · 极简生活告别 App 实现规划

> **For Hermes:** Use subagent-driven-development skill to implement this plan task-by-task.

**项目名称：** 减单 (JianDan)
**英文名：** JianDan
**工作目录：** /Users/chixiang/workspace/jiandan
**项目类型：** iOS 原生 App（SwiftUI + SwiftData）
**创建日期：** 2026-06-22
**修订：** v2.0 — 改为 iOS 原生（SwiftUI）

---

## 一、产品定位

减单不是交易平台（不是闲鱼），不是清单工具（不是 Todoist），而是「**情感疗愈 + 极简生活**」的双重定位——让告别成为一个有仪式感的过程，让放下更释然。

**核心隐喻：** "减"则少，"单"则一。每一次告别，都是一次自我照见。

**目标用户：**
- 25-45 岁，崇尚极简生活、有断舍离意愿的城市人群
- 关注心理健康、追求内心安宁
- iPhone 用户（与定位契合）

---

## 二、技术栈（iOS 原生）

| 层 | 技术 |
|---|---|
| 最低系统 | iOS 17.0（SwiftData 要求） |
| UI 框架 | **SwiftUI**（声明式、现代） |
| 数据持久化 | **SwiftData**（Apple 全新 ORM，原生集成） |
| 图片存储 | 应用沙盒 + FileManager |
| 图片选择 | PhotosUI（PHPickerViewController 封装） |
| 图片处理 | Core Image（原生压缩、滤镜） |
| 本地通知 | UserNotifications（每日短文提醒） |
| PDF 导出 | PDFKit |
| 架构 | MVVM + SwiftUI 单向数据流 |
| 开发工具 | Xcode 15+ |
| 包管理 | Swift Package Manager (SPM) |
| 测试 | XCTest + Swift Testing |

**包体积预估：** 8-15 MB（远小于 Flutter）

---

## 三、用户故事

1. **告别单件：** 翻出旧物 → 打开减单 → 拍照 → 写告别信 → 选去处 → 完成
2. **回忆往昔：** 滑动时光轴，看自己送走 100 件物品的轨迹
3. **整理情绪：** 告别衣服时写下"它陪我度过第一次面试"

---

## 四、MVP 核心功能 (Phase 1)

### 模块 1 · 告别记录（核心）

| 字段 | 类型 | 必填 | SwiftData 映射 |
|---|---|---|---|
| 照片 | [Data] (1-3 张) | ✅ | @Attribute(.externalStorage) |
| 名称 | String (1-50) | ✅ | (验证在 init) |
| 分类 | Category 枚举 | ✅ | String raw value |
| 购入时间 | Date? | ❌ | Optional |
| 告别日期 | Date | ✅ (默认今日) | |
| 告别方式 | FarewellMethod 枚举 | ✅ | String raw value |
| 收件人/去向详情 | String? | ❌ | Optional |
| 购入价 | Double? | ❌ | Optional |
| 情感值 | Int? (1-5) | ❌ | Optional |
| 告别信 | String? (≤500) | ❌ | Optional |
| 创建时间 | Date | ✅ | 自动 |
| 更新时间 | Date | ✅ | 自动 |

### 模块 2 · 告别日记（时光轴）
按时间倒序展示所有告别卡片。卡片仿拍立得，色调温柔，留白多。

### 模块 3 · 极简之道（内容 Tab）
- 每日一条极简短文（本地预置 + 本地通知提醒）
- 断舍离方法论（断 / 舍 / 离 三步）
- 不消费挑战打卡

### 模块 4 · 我的
- 告别总数 / 陪伴累计时长 / 节省空间
- 主题切换（浅色 / 深色 / 墨色）
- 数据导出（JSON / PDF 告别册）
- iCloud 同步开关（Phase 3）

---

## 五、视觉与体验

**主色调：**
- 浅色：米白 (#FAF8F5) + 墨灰 (#3C3C3C) + 淡赭 (#C9A57B)
- 深色：墨黑 (#1A1A1A) + 米白 (#F5F0E8) + 淡青 (#7BA8A0)
- 墨色：纯黑 + 朱砂 (#B23A48) 点缀

**字体：**
- 标题：Source Han Serif（思源宋体）
- 正文：苹方（系统）

**留白哲学：** 大留白，缓动画，无推送轰炸。告别动画：物品淡出 + 一片花瓣飘落（450ms）。

**音效（可关闭）：** 极简钢琴或古琴片段

---

## 六、项目目录结构

```
jiandan/
├── project.yml                       # XcodeGen 配置（或直接 .xcodeproj）
├── Package.swift                     # SPM 依赖（如需）
├── README.md
├── .gitignore
├── JianDan/
│   ├── App/
│   │   ├── JianDanApp.swift         # @main 入口
│   │   └── AppEnvironment.swift
│   ├── Models/
│   │   ├── FarewellRecord.swift     # @Model
│   │   ├── Category.swift           # enum
│   │   └── FarewellMethod.swift     # enum
│   ├── Views/
│   │   ├── Root/
│   │   │   └── RootTabView.swift
│   │   ├── Diary/
│   │   │   ├── DiaryView.swift       # 时光轴
│   │   │   ├── FarewellCardView.swift
│   │   │   └── DiaryEmptyView.swift
│   │   ├── AddFarewell/
│   │   │   ├── AddFarewellView.swift
│   │   │   ├── PhotoPickerSection.swift
│   │   │   ├── CategoryPickerSection.swift
│   │   │   ├── MethodPickerSection.swift
│   │   │   └── EmotionStarsView.swift
│   │   ├── Detail/
│   │   │   └── FarewellDetailView.swift
│   │   ├── Wisdom/
│   │   │   ├── WisdomView.swift
│   │   │   ├── DailyQuoteView.swift
│   │   │   └── ChallengeView.swift
│   │   └── Profile/
│   │       ├── ProfileView.swift
│   │       ├── StatsView.swift
│   │       └── SettingsView.swift
│   ├── Theme/
│   │   ├── AppTheme.swift
│   │   ├── AppColors.swift
│   │   └── Typography.swift
│   ├── Services/
│   │   ├── ImageStore.swift          # 图片存储管理
│   │   ├── NotificationService.swift
│   │   ├── ExportService.swift       # PDF / JSON
│   │   └── QuoteRepository.swift     # 短文预置
│   ├── Components/
│   │   ├── PrimaryButton.swift
│   │   ├── EmptyState.swift
│   │   └── FarewellAnimation.swift   # 花瓣飘落动画
│   └── Resources/
│       ├── Assets.xcassets
│       │   ├── AppIcon.appiconset
│       │   └── Colors/
│       ├── Quotes/
│       │   └── daily_quotes.json     # 30+ 预置短文
│       └── Localizable.xcstrings
├── JianDanTests/
│   ├── Models/
│   │   └── FarewellRecordTests.swift
│   └── Services/
│       └── ExportServiceTests.swift
└── JianDanUITests/
    └── FarewellFlowUITests.swift
```

---

## 七、SwiftData Schema 草案

```swift
// Models/FarewellRecord.swift
import Foundation
import SwiftData

@Model
final class FarewellRecord {
    @Attribute(.unique) var id: UUID
    var name: String
    var categoryRaw: String
    var purchaseDate: Date?
    var farewellDate: Date
    var methodRaw: String
    var recipientDetail: String?
    var purchasePrice: Double?
    var emotionValue: Int?  // 1-5
    var farewellLetter: String?
    @Attribute(.externalStorage) var photoData: [Data]
    var createdAt: Date
    var updatedAt: Date

    init(
        name: String,
        category: Category,
        farewellDate: Date = .now,
        method: FarewellMethod,
        photos: [Data] = []
    ) {
        self.id = UUID()
        self.name = name
        self.categoryRaw = category.rawValue
        self.farewellDate = farewellDate
        self.methodRaw = method.rawValue
        self.photoData = photos
        self.createdAt = .now
        self.updatedAt = .now
    }

    var category: Category {
        Category(rawValue: categoryRaw) ?? .other
    }

    var method: FarewellMethod {
        FarewellMethod(rawValue: methodRaw) ?? .other
    }

    var companionshipDays: Int? {
        guard let purchase = purchaseDate else { return nil }
        return Calendar.current.dateComponents([.day], from: purchase, to: farewellDate).day
    }
}

// Models/Category.swift
enum Category: String, CaseIterable, Identifiable, Codable {
    case clothing = "衣物"
    case books = "书籍"
    case electronics = "电子"
    case furniture = "家具"
    case miscellaneous = "杂物"
    case other = "其他"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .clothing: return "tshirt"
        case .books: return "book"
        case .electronics: return "laptopcomputer"
        case .furniture: return "sofa"
        case .miscellaneous: return "shippingbox"
        case .other: return "circle.grid.2x2"
        }
    }
}

// Models/FarewellMethod.swift
enum FarewellMethod: String, CaseIterable, Identifiable, Codable {
    case gift = "送人"
    case discard = "扔掉"
    case donate = "捐赠"
    case resell = "二手出售"
    case store = "暂存"
    case other = "其他"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .gift: return "gift"
        case .discard: return "trash"
        case .donate: return "heart"
        case .resell: return "tag"
        case .store: return "archivebox"
        case .other: return "ellipsis.circle"
        }
    }
}
```

---

## 八、分期路线图

### Phase 1 · MVP（3-4 周）
- Xcode 工程初始化 + SwiftUI + SwiftData
- 告别记录 CRUD
- 告别日记（时光轴）
- 极简之道（占位 + 静态内容）
- 我的页面
- iPhone 适配

### Phase 2 · 体验打磨（2 周）
- 告别动画（花瓣飘落）
- 告别月报统计
- 每日短文本地通知
- 主题切换

### Phase 3 · 进阶（3-4 周）
- PDF 告别册导出
- iCloud 同步（SwiftData CloudKit）
- 录音告别
- 陪伴时长统计

### Phase 4 · 可选扩展
- Apple Watch 速记
- 小组件（WidgetKit）
- App Intents（Siri 录入）

---

## 九、Phase 1 任务拆分（可直接执行）

### Task 1: 初始化 Xcode 工程
- 创建 `JianDan.xcodeproj`
- 配置 iOS 17+ 部署目标
- 启用 SwiftData 能力
- 设置应用图标、启动屏占位

### Task 2: App 入口与根视图
- `JianDanApp.swift`（@main + ModelContainer）
- `RootTabView.swift`（三 Tab）
- 主题基础

### Task 3: 数据模型
- `FarewellRecord.swift`（@Model）
- `Category.swift`（enum）
- `FarewellMethod.swift`（enum）

### Task 4: 模型单元测试
- 测试初始化、companionshipDays 计算
- 测试枚举 rawValue

### Task 5: 主题系统
- `AppColors.swift`（Color Extension）
- `Typography.swift`
- `AppTheme.swift`（浅色 / 深色 / 墨色）

### Task 6: 告别日记页（时光轴）
- `DiaryView.swift`（@Query 按时间倒序）
- `FarewellCardView.swift`（拍立得样式）
- `DiaryEmptyView.swift`

### Task 7: 新建告别页
- `AddFarewellView.swift`（表单）
- `PhotoPickerSection.swift`（PhotosPicker）
- `CategoryPickerSection.swift`
- `MethodPickerSection.swift`
- `EmotionStarsView.swift`（1-5 星）

### Task 8: 图片存储服务
- `ImageStore.swift`（应用沙盒 FileManager）
- 图片压缩（最大 1920px，JPEG 0.85）
- 唯一 ID 命名

### Task 9: 告别详情页
- `FarewellDetailView.swift`
- 查看 / 编辑 / 删除 / 分享

### Task 10: 极简之道页
- `WisdomView.swift`
- `DailyQuoteView.swift`（每日轮换）
- `QuoteRepository.swift`（读取 JSON）

### Task 11: 每日短文 JSON
- `daily_quotes.json`（30 条精选断舍离短文）

### Task 12: 我的页
- `ProfileView.swift`（统计数据）
- `StatsView.swift`（告别数 / 陪伴累计）
- `SettingsView.swift`（主题切换占位）

### Task 13: 告别动画
- `FarewellAnimation.swift`（花瓣飘落）
- 集成到新建完成时

### Task 14: UI 测试
- `FarewellFlowUITests.swift`
- 完整流程：拍照 → 填表 → 保存 → 查看

### Task 15: 构建验证
- `xcodebuild -scheme JianDan -destination 'platform=iOS Simulator,name=iPhone 15'`
- 真机 / 模拟器运行

---

## 十、关键依赖

**零外部依赖**（iOS 原生最大优势）

仅需系统框架：
- SwiftUI（UI）
- SwiftData（数据）
- PhotosUI（图片选择）
- UserNotifications（通知）
- PDFKit（导出）
- CoreImage（图片处理）

---

## 十一、与 Flutter 方案对比

| 维度 | iOS 原生 | Flutter |
|---|---|---|
| 包体积 | 8-15 MB | 20-30 MB |
| 启动速度 | 极快 | 快 |
| 流畅度 | 100% | 95% |
| iOS 新特性 | 即时 | 滞后 6-18 月 |
| 开发速度 | 中 | 快 |
| 跨平台 | 仅 iOS | 多端 |
| 招人成本 | 低 | 高 |
| 代码量 | 中（SwiftUI 简洁） | 多 |

---

## 十二、风险与权衡

| 风险 | 应对 |
|---|---|
| 仅 iOS 用户 | 与目标用户契合；未来可扩展 Watch / iPad |
| SwiftData 是 iOS 17+ 新框架 | 文档相对少，遇坑可降级 Core Data |
| 池老板 Swift 经验 | 我会逐步解释；或在卡点时详述 |
| iCloud 同步 | Phase 3 引入，先做本地 |

---

## 十三、下一步

1. 池老板审阅本规划
2. 若认可，回复「**开始执行**」或「**执行 Phase 1**」
3. 我将循 subagent-driven-development 之法，逐任务委派子智能体，每任务两阶段审核（规范合规 + 代码质量）

---

*文档版本：v2.0 · 2026-06-22 · iOS 原生 SwiftUI + SwiftData*