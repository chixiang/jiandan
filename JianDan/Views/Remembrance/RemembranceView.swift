import SwiftUI
import SwiftData

/// 怀念 · 告别清单
///
/// 杂志感居中排版，图片作为卡片嵌入内容区而非通栏 hero，
/// 兼顾横竖图兼容与紧凑布局。
struct RemembranceView: View {
    @Environment(\.appTheme) private var theme
    @Environment(\.modelContext) private var modelContext
    @Environment(CurrencyManager.self) private var currencyManager

    @Query(sort: \FarewellRecord.farewellDate, order: .reverse) private var records: [FarewellRecord]

    @State private var record: FarewellRecord?
    @State private var showingEmptyAlert = false

    var body: some View {
        NavigationStack {
            Group {
                if records.isEmpty {
                    emptyView
                } else if let record {
                    detailView(record)
                        .id(record.id)
                        .transition(.opacity.combined(with: .scale(scale: 0.93)))
                } else {
                    emptyView
                }
            }
            .background(theme.background)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(action: {
                        if records.isEmpty {
                            showingEmptyAlert = true
                        } else {
                            pickRandom()
                        }
                    }) {
                        Image(systemName: "shuffle")
                            .font(.subheadline)
                            .foregroundStyle(theme.accent)
                    }
                }
            }
            .alert("还没有告别记录", isPresented: $showingEmptyAlert) {
                Button("好的", role: .cancel) { }
            } message: {
                Text("先去「告别清单」Tab 记下第一件物品吧")
            }
            .onAppear {
                if record == nil, !records.isEmpty { pickRandom() }
            }
            .onChange(of: records.count) { _, _ in
                if record == nil, !records.isEmpty { pickRandom() }
            }
            .animation(.easeInOut(duration: 0.35), value: record?.id)
        }
    }

    private func pickRandom() {
        guard !records.isEmpty else { return }
        withAnimation(.easeInOut(duration: 0.35)) {
            record = records.randomElement()
        }
    }

    // MARK: - 详情

    private func detailView(_ item: FarewellRecord) -> some View {
        ScrollView {
            VStack(spacing: 20) {
                // ---- 图片卡片（嵌入内容区） ----
                if let firstPhoto = item.photoFilenames.first,
                   let uiImage = ImageStore.loadImage(filename: firstPhoto) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(maxHeight: 220)
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                        .shadow(color: theme.needsShadow ? .black.opacity(0.06) : .clear, radius: 8, y: 2)
                        .padding(.horizontal, 16)
                        .padding(.top, item.photoFilenames.isEmpty ? 0 : 16)
                }

                // ---- 名称 ----
                Text(item.name)
                    .font(.system(size: 26, weight: .regular, design: .serif))
                    .foregroundStyle(theme.primaryText)
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
                    .padding(.horizontal, 32)
                    .padding(.top, item.photoFilenames.isEmpty ? 28 : 4)

                // ---- 装饰分隔 ----
                Rectangle()
                    .fill(theme.divider)
                    .frame(width: 32, height: 0.5)

                // ---- 日期 + 陪伴天数 ----
                HStack(spacing: 8) {
                    HStack(spacing: 4) {
                        if let purchase = item.purchaseDate {
                            Text(purchase, format: .dateTime.year().month().day())
                        } else {
                            Text("某天")
                        }
                        Text("~")
                        Text(item.farewellDate, format: .dateTime.year().month().day())
                    }
                    .font(.caption)
                    if let days = item.companionshipDays {
                        Text("·")
                        Text("陪伴我 \(days) 天")
                            .font(.caption)
                    }
                }
                .foregroundStyle(theme.secondary)

                // ---- 分类 · 方式 · 价格 ----
                HStack(spacing: 8) {
                    pill(item.category.displayName, icon: item.category.iconName)
                    pill(item.method.localizedName, icon: item.method.icon)
                    if let price = item.purchasePrice, price > 0 {
                        pill(String(format: "%.2f", price), icon: currencyManager.currency.icon)
                    }
                }

                // ---- 去向详情 ----
                if let detail = item.recipientDetail, !detail.isEmpty {
                    Label(detail, systemImage: "arrow.right")
                        .font(.caption)
                        .foregroundStyle(theme.secondary)
                }

                // ---- 当时心情 ----
                if let emotion = item.emotionValue {
                    HStack(spacing: 8) {
                        ForEach(1...3, id: \.self) { i in
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

                // ---- 告别留言（pull-quote） ----
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
                            .multilineTextAlignment(.center)
                            .frame(maxWidth: 300)
                            .fixedSize(horizontal: false, vertical: true)

                        Rectangle()
                            .fill(theme.divider)
                            .frame(width: 24, height: 0.5)
                    }
                }

                // 底部留白
                Color.clear
                    .frame(height: 8)
            }
            .frame(maxWidth: .infinity)
            .padding(.horizontal, 24)
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
        case 1: return String(localized: "平静")
        case 2: return String(localized: "复杂")
        case 3: return String(localized: "不舍")
        default: return ""
        }
    }

    private var emptyView: some View {
        VStack(spacing: 16) {
            Spacer()
            Image(systemName: "heart")
                .font(.system(size: 48, weight: .ultraLight))
                .foregroundStyle(theme.secondary)
            Text("还没有告别记录")
                .font(AppTypography.body)
                .foregroundStyle(theme.secondary)
            Text("在「告别清单」Tab 记下第一件物品，\n怀念就会出现在这里")
                .font(AppTypography.caption)
                .foregroundStyle(theme.secondary)
                .multilineTextAlignment(.center)
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

#Preview {
    RemembranceView()
        .environment(\.appTheme, AppTheme(mode: .light))
        .environment(CurrencyManager())
        .modelContainer(for: FarewellRecord.self, inMemory: true)
}