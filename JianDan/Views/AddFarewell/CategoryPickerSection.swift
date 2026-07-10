import SwiftUI
import SwiftData

/// 分类选择器
///
/// 显示：
/// 1. 12 个内置分类 chip
/// 2. 用户自定义分类 chip（按 sortOrder 升序）
/// 3. 末尾「+」chip → 新建分类
///
/// 选中态由 binding 控制；外部用 `record.categoryID` 读写。
struct CategoryPickerSection: View {
    @Binding var selection: AnyCategory
    /// 提供给 chip 的删除回调（仅自定义 chip 显示删除）
    var onRequestDelete: ((AnyCategory) -> Void)? = nil

    @Environment(\.appTheme) private var theme
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \UserCategory.sortOrder, order: .forward) private var customCategories: [UserCategory]
    @State private var showingNewCategorySheet = false

    var body: some View {
        VStack(alignment: .leading, spacing: .sm) {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: .xs) {
                    // 1. 内置分类
                    ForEach(Category.allCases) { category in
                        CategoryChip(
                            label: category.localizedName,
                            iconName: category.icon,
                            isSelected: selection == .builtin(category),
                            isDeletable: false,
                            onTap: { selection = .builtin(category) },
                            onLongPress: nil
                        )
                    }

                    // 分隔点
                    if !customCategories.isEmpty {
                        Divider()
                            .frame(height: 24)
                            .background(theme.divider)
                            .padding(.horizontal, .xs)
                    }

                    // 2. 自定义分类
                    ForEach(customCategories, id: \.id) { custom in
                        CategoryChip(
                            label: custom.name,
                            iconName: custom.iconName,
                            isSelected: selection == AnyCategory.from(userCategory: custom),
                            isDeletable: true,
                            onTap: { selection = AnyCategory.from(userCategory: custom) },
                            onLongPress: { onRequestDelete?(AnyCategory.from(userCategory: custom)) }
                        )
                    }

                    // 3. 新增按钮
                    NewCategoryChip {
                        showingNewCategorySheet = true
                    }
                }
                .padding(.horizontal, 1)
            }
        }
        .sheet(isPresented: $showingNewCategorySheet) {
            NewCategorySheet()
        }
    }
}

/// 单个分类 chip
private struct CategoryChip: View {
    @Environment(\.appTheme) private var theme
    let label: String
    let iconName: String
    let isSelected: Bool
    let isDeletable: Bool
    let onTap: () -> Void
    let onLongPress: (() -> Void)?

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: .xs) {
                Image(systemName: iconName)
                Text(label)
            }
            .appFont(.body)
            .padding(.horizontal, .sm)
            .padding(.vertical, .xs)
            .background(isSelected ? theme.accent.opacity(0.2) : theme.divider.opacity(0.3))
            .foregroundStyle(isSelected ? theme.accent : theme.primaryText)
            .clipShape(Capsule())
            .overlay(
                Capsule()
                    .strokeBorder(isSelected ? theme.accent : Color.clear, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
        .if(isDeletable && onLongPress != nil) { view in
            view.onLongPressGesture(minimumDuration: 0.5, perform: { onLongPress?() })
        }
    }
}

/// 「+」chip
private struct NewCategoryChip: View {
    @Environment(\.appTheme) private var theme
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: .xs) {
                Image(systemName: "plus")
                Text("新分类")
            }
            .appFont(.body)
            .padding(.horizontal, .sm)
            .padding(.vertical, .xs)
            .background(Color.clear)
            .foregroundStyle(theme.accent)
            .overlay(
                Capsule()
                    .strokeBorder(theme.accent.opacity(0.5), style: StrokeStyle(lineWidth: 1, dash: [4, 3]))
            )
        }
        .buttonStyle(.plain)
    }
}

// SwiftUI 条件修饰器辅助
private extension View {
    @ViewBuilder
    func `if`<Transform: View>(_ condition: Bool, transform: (Self) -> Transform) -> some View {
        if condition {
            transform(self)
        } else {
            self
        }
    }
}

#Preview {
    @Previewable @State var selection: AnyCategory = .builtin(.clothing)
    return CategoryPickerSection(selection: $selection)
        .padding()
        .modelContainer(for: [UserCategory.self, FarewellRecord.self], inMemory: true)
}