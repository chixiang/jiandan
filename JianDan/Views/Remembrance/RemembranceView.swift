import SwiftUI
import SwiftData

/// 怀念 · 减单
///
/// 随机展示一件已告别物品的详情，居中排版、简洁高级。
struct RemembranceView: View {
    @Environment(\.appTheme) private var theme
    @Environment(\.modelContext) private var modelContext

    @Query(sort: \FarewellRecord.farewellDate, order: .reverse) private var records: [FarewellRecord]

    @State private var record: FarewellRecord?

    var body: some View {
        NavigationStack {
            Group {
                if records.isEmpty {
                    emptyView
                } else if let record {
                    detailView(record)
                } else {
                    emptyView
                }
            }
            .background(theme.background)
            .navigationTitle("怀念")
            .toolbar {
                if !records.isEmpty {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button(action: pickRandom) {
                            Image(systemName: "shuffle")
                                .foregroundStyle(theme.accent)
                        }
                    }
                }
            }
            .onAppear {
                if record == nil, !records.isEmpty { pickRandom() }
            }
            .onChange(of: records.count) { _, _ in
                if record == nil, !records.isEmpty { pickRandom() }
            }
        }
    }

    private func pickRandom() {
        guard !records.isEmpty else { return }
        record = records.randomElement()
    }

    // MARK: - 详情

    private func detailView(_ item: FarewellRecord) -> some View {
        ScrollView {
            VStack(spacing: 0) {
                // 照片 hero（固定高度 260）
                if let firstPhoto = item.photoFilenames.first,
                   let uiImage = ImageStore.loadImage(filename: firstPhoto) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(maxHeight: 320)
                        .clipped()
                }

                VStack(spacing: 24) {
                    // 名称（居中）
                    Text(item.name)
                        .font(.system(size: 26, weight: .regular, design: .serif))
                        .foregroundStyle(theme.primaryText)
                        .multilineTextAlignment(.center)
                        .lineSpacing(4)
                        .padding(.horizontal, 32)
                        .padding(.top, item.photoFilenames.isEmpty ? 24 : 28)

                    // 装饰分隔线
                    Rectangle()
                        .fill(theme.divider)
                        .frame(width: 32, height: 0.5)

                    // 日期 + 陪伴天数（居中）
                    HStack(spacing: 8) {
                        Text(item.farewellDate.formatted(.dateTime.year().month().day()))
                            .font(.caption)
                        if let days = item.companionshipDays {
                            Text("·")
                            Text("陪伴 \(days) 天")
                                .font(.caption)
                        }
                    }
                    .foregroundStyle(theme.secondary)

                    // 分类 · 方式 · 价格（居中）
                    HStack(spacing: 8) {
                        pill(item.category.displayName, icon: item.category.iconName)
                        pill(item.method.rawValue, icon: item.method.icon)
                        if let price = item.purchasePrice, price > 0 {
                            pill("¥\(String(format: "%.0f", price))", icon: "yensign")
                        }
                    }

                    // 去向详情
                    if let detail = item.recipientDetail, !detail.isEmpty {
                        Label(detail, systemImage: "arrow.right")
                            .font(.caption)
                            .foregroundStyle(theme.secondary)
                    }

                    // 当时心情
                    if let emotion = item.emotionValue {
                        HStack(spacing: 8) {
                            ForEach(1...5, id: \.self) { i in
                                Circle()
                                    .fill(i <= emotion ? theme.accent : theme.divider)
                                    .frame(width: 8, height: 8)
                            }
                            Text(emotionLabel(emotion))
                                .font(.caption)
                                .foregroundStyle(theme.secondary)
                                .padding(.leading, 4)
                        }
                    }

                    // 减单一言
                    if let letter = item.farewellLetter, !letter.isEmpty {
                        VStack(spacing: 16) {
                            Rectangle()
                                .fill(theme.divider)
                                .frame(width: 24, height: 0.5)

                            Text("“\(letter)”")
                                .font(.system(size: 16, design: .serif))
                                .italic()
                                .foregroundStyle(theme.primaryText)
                                .lineSpacing(8)
                                .frame(maxWidth: 300)
                                .multilineTextAlignment(.center)
                                .fixedSize(horizontal: false, vertical: true)

                            Rectangle()
                                .fill(theme.divider)
                                .frame(width: 24, height: 0.5)
                        }
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.horizontal, 24)
                .padding(.bottom, 40)
            }
        }
        .scrollIndicators(.hidden)
    }

    // MARK: - 辅助

    private func pill(_ text: String, icon: String) -> some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .font(.caption2)
            Text(text)
                .font(.caption)
        }
        .foregroundStyle(theme.secondary)
        .padding(.horizontal, 10)
        .padding(.vertical, 5)
        .background(theme.cardBackground)
        .clipShape(Capsule())
        .overlay(
            Capsule()
                .strokeBorder(theme.divider, lineWidth: 0.5)
        )
    }

    private func emotionLabel(_ value: Int) -> String {
        switch value {
        case 1: return "轻松"
        case 2: return "释然"
        case 3: return "平静"
        case 4: return "复杂"
        case 5: return "不舍"
        default: return ""
        }
    }

    // MARK: - 空态

    private var emptyView: some View {
        VStack(spacing: 16) {
            Image(systemName: "heart")
                .font(.system(size: 48, weight: .ultraLight))
                .foregroundStyle(theme.secondary)
            Text("还没有告别记录")
                .font(AppTypography.body)
                .foregroundStyle(theme.secondary)
            Text("在「减单」Tab 记下第一件物品，\\n怀念就会出现在这里")
                .font(AppTypography.caption)
                .foregroundStyle(theme.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxHeight: .infinity)
    }
}

#Preview {
    RemembranceView()
        .environment(\.appTheme, AppTheme(mode: .light))
        .modelContainer(for: FarewellRecord.self, inMemory: true)
}