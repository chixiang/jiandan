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

    @Environment(\.modelContext) private var modelContext
    @Query(sort: \UserCategory.sortOrder, order: .forward) private var customCategories: [UserCategory]
    @State private var showingNewCategorySheet = false

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("分类")
                .font(.headline)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    // 1. 内置分类
                    ForEach(Category.allCases) { category in
                        CategoryChip(
                            label: category.rawValue,
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
                            .padding(.horizontal, 4)
                    }

                    // 2. 自定义分类
                    ForEach(customCategories, id: \.id) { custom in
                        CategoryChip(
                            label: custom.name,
                            iconName: custom.iconName,
                            isSelected: selection == .custom(custom),
                            isDeletable: true,
                            onTap: { selection = .custom(custom) },
                            onLongPress: { onRequestDelete?(.custom(custom)) }
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
    let label: String
    let iconName: String
    let isSelected: Bool
    let isDeletable: Bool
    let onTap: () -> Void
    let onLongPress: (() -> Void)?

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 6) {
                Image(systemName: iconName)
                Text(label)
            }
            .font(.subheadline)
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(isSelected ? Color.accentColor.opacity(0.2) : Color.secondary.opacity(0.1))
            .foregroundStyle(isSelected ? Color.accentColor : Color.primary)
            .clipShape(Capsule())
            .overlay(
                Capsule()
                    .strokeBorder(isSelected ? Color.accentColor : Color.clear, lineWidth: 1)
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
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: "plus")
                Text("新分类")
            }
            .font(.subheadline)
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(Color.clear)
            .foregroundStyle(Color.accentColor)
            .overlay(
                Capsule()
                    .strokeBorder(Color.accentColor.opacity(0.5), style: StrokeStyle(lineWidth: 1, dash: [4, 3]))
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