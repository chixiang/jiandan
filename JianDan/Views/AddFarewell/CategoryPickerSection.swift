import SwiftUI

/// 分类选择器
struct CategoryPickerSection: View {
    @Binding var selection: Category

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("分类")
                .font(.headline)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(Category.allCases) { category in
                        CategoryChip(
                            category: category,
                            isSelected: category == selection,
                            onTap: { selection = category }
                        )
                    }
                }
                .padding(.horizontal, 1)
            }
        }
    }
}

private struct CategoryChip: View {
    let category: Category
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 6) {
                Image(systemName: category.icon)
                Text(category.rawValue)
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
    }
}

#Preview {
    @Previewable @State var selection: Category = .clothing
    return CategoryPickerSection(selection: $selection)
        .padding()
}