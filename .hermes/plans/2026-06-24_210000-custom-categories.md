# 告别清单 · 自定义分类 实施计划

**日期：** 2026-06-24
**作者：** Hermes Agent
**前置：** task15 收尾完成（5054c61），月报统计阶段 1 完成（4b8fa70）

---

## 一、目标

1. **丰富**：内置分类从 6 个扩展到 12 个
2. **自定义**：用户可创建自定义分类（名称 + SF Symbol 图标）
3. **统一**：内置 + 自定义在 UI 层无差别显示，统计聚合按"分类项"统一处理
4. **保护**：已有 8 条样本数据 / 用户数据不丢失（schema 兼容迁移）

## 二、内置分类清单（12 个）

| case | rawValue | SF Symbol | 备注 |
|---|---|---|---|
| `clothing` | 衣物 | `tshirt` | 原 |
| `shoesAccessories` | 鞋包配饰 | `bag` | 新 |
| `books` | 书籍 | `book` | 原 |
| `electronics` | 电子 | `laptopcomputer` | 原 |
| `furniture` | 家具 | `sofa` | 原 |
| `homeStorage` | 家居收纳 | `shippingbox.and.arrow.backward` | 新 |
| `beauty` | 美妆护肤 | `sparkles` | 新 |
| `documents` | 票据文件 | `doc.text` | 新 |
| `toysCollectibles` | 玩具收藏 | `gamecontroller` | 新 |
| `tools` | 工具器材 | `wrench.and.screwdriver` | 新 |
| `miscellaneous` | 杂物 | `shippingbox` | 原 |
| `other` | 其他 | `circle.grid.2x2` | 原 fallback |

**删除**：原计划中「食品调料」按用户要求去除。

## 三、数据建模

### 3.1 保留 `Category` enum

`Category` 仍是 `String, CaseIterable, Codable` enum，`rawValue` 是中文展示名（不变）。扩展到 12 case。

### 3.2 新增 `UserCategory` @Model

```swift
@Model
final class UserCategory {
    @Attribute(.unique) var id: UUID
    var name: String              // 显示名（trim 后非空，长度 1...10）
    var iconName: String          // SF Symbol
    var createdAt: Date
    var sortOrder: Int            // 自定义分类排序用

    init(name: String, iconName: String) { ... }
}
```

- SwiftData 自动建表，无须手动 migration plan
- `iconName` 校验：必须是 SF Symbol 中存在的（运行时查不出来 fallback 到 `circle.grid.2x2`）

### 3.3 FarewellRecord 字段语义扩展

`categoryRaw: String` 字段保留，**语义升级**为"分类 ID"：
- 内置分类：值 = `Category.rawValue`（如 `"衣物"`）—— 与旧数据完全兼容，0 迁移
- 自定义分类：值 = `UserCategory.id.uuidString`

`record.category` 计算属性改为返回 `AnyCategory` 枚举：
```swift
enum AnyCategory: Hashable {
    case builtin(Category)
    case custom(UserCategory)
    
    var displayName: String { ... }
    var iconName: String { ... }
}
```

- `FarewellRecord.category` 返回 `AnyCategory`
- 提供 `categoryID: String` getter（写）

### 3.4 兼容策略

- 旧 store 中所有 `categoryRaw` 都是 `Category.rawValue` —— **直接兼容**，不需要 migration
- 新增自定义分类后，新增记录的 `categoryRaw` 为 UUID 字符串
- 自定义分类被删除时，所有引用它的记录 fallback 到「其他」（写回）

## 四、UI 改造

### 4.1 `CategoryPickerSection`

- chip 横排：内置 12 个 + 用户自定义（按 sortOrder）
- 末尾追加「+」chip，点击弹 `NewCategorySheet`
- 长按自定义 chip → 删除确认（仅自定义可删，内置只读）

### 4.2 `NewCategorySheet`（新增）

- 名称输入：TextField，1-10 字，trim 后非空
- 图标选择：固定 24 个常用 SF Symbol 网格（避免 SF Symbol picker 过于发散）
- 实时预览 chip
- 「保存」按钮（置灰直到合法）

### 4.3 `FarewellDetailView`

- `CategoryPickerSection(selection:)` 接收 `Binding<AnyCategory>` 而非 `Category`
- 详情行 `Label(icon:, rawValue:)` 改为 `Label(iconName:displayName:)`

### 4.4 `FarewellCardView` / `PhotoThumbView`

- 接收 `AnyCategory` 替代 `Category`
- icon + rawValue 改为 displayName + iconName

### 4.5 `StatsCalculator` / `StatsView`

- `CategoryCount.category` 改为 `AnyCategory`
- 聚合按 `AnyCategory.displayName` 排序

### 4.6 `ProfileView` / `SettingsView`

- 在 SettingsView 末尾加「分类管理」入口
- 新页 `CategoryManagementView`：列出内置（只读）+ 自定义（可编辑/删除）
- 删除自定义时，弹确认 + 提示"关联 N 条记录将归入'其他'"

## 五、删除规则

| 场景 | 行为 |
|---|---|
| 内置分类 | 不允许删除（UI 不显示删除按钮） |
| 自定义分类 - 无引用 | 直接删除 |
| 自定义分类 - 有引用 | 弹确认 "关联 N 条记录将归入'其他'，是否继续？" → 全部改写 categoryID=「其他」的 rawValue |

## 六、测试

### 6.1 UserCategoryTests（新文件）

- 名称 trim 校验
- 名称长度校验（1-10）
- iconName 必填（默认 fallback）
- id 唯一性（SwiftData 自动保证，加注释）
- 排序：按 sortOrder asc

### 6.2 CategoryTests（更新）

- `testAllCases` 期望 12
- 新增 6 个 case 的 rawValue/icon 断言

### 6.3 FarewellRecordTests（更新）

- 新增 `testCustomCategoryRoundtrip`：写入 UUID 字符串，读出 AnyCategory.custom
- 新增 `testUnknownCategoryIDFallsBackToOther`：写入不存在的 ID，应 fallback 到 .other

### 6.4 StatsCalculatorTests（更新）

- `testCategoryBreakdownIsSortedByCountDescending` 改用 AnyCategory

### 6.5 DataImporterTests（更新）

- 样本 JSON 里的 category 字符串仍能解析（向后兼容）

### 6.6 UI 不加自动 UI 测试（手动截图验收）

## 七、风险与决策

| 风险 | 处理 |
|---|---|
| 已有数据中 categoryRaw 是「衣物」/「书籍」等枚举 rawValue | 直接兼容，无需 migration |
| SwiftData 加 UserCategory 表 | 自动建表，无 schema 迁移代码 |
| 删除自定义分类时写回 N 条记录 | 在 @MainActor 上做，避免后台线程写 SwiftData |
| 12 个内置 + 自定义可能让 chip 横排过长 | 现状就是横向滚动，无影响 |
| SF Symbol 名字拼错 | 24 个固定候选 + fallback |

## 八、实施步骤

1. TDD: UserCategoryTests → UserCategory @Model
2. Category 扩到 12 个（去食品调料）+ CategoryTests 同步
3. AnyCategory 枚举 + FarewellRecord.category 计算属性升级
4. FarewellRecordTests 加新 case
5. StatsCalculator 适配 AnyCategory
6. CategoryPickerSection 接收 AnyCategory + 加「+」chip + 长按删除
7. NewCategorySheet
8. FarewellDetailView / FarewellCardView / PhotoThumbView 接收 AnyCategory
9. SettingsView 加「分类管理」入口 + CategoryManagementView
10. 删除自定义分类时改写引用记录的逻辑
11. DataImporter 验证（无需改 JSON）
12. 全量测试 + 真机截图
13. commit

## 九、验证清单

- [ ] 单测全绿（含新增/更新）
- [ ] Build 干净
- [ ] 真机/模拟器：新增流程顺畅（新建 → 选 → 保存 → 出现在 chip）
- [ ] 真机/模拟器：旧数据正确显示（8 条样本）
- [ ] 真机/模拟器：删除自定义时引用记录改写为"其他"
- [ ] 真机/模拟器：统计页正确聚合（内置 + 自定义各自一行）
- [ ] pbxproj regen artifact 检查