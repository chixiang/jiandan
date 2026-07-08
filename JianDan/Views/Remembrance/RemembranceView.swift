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
    @State private var transitionEdge: Edge = .bottom
    @State private var revealedLetterCount = 0
    @State private var showingEdit = false
    @State private var photoViewerFilenames: [String]?

    var body: some View {
        NavigationStack {
            Group {
                if records.isEmpty {
                    emptyView
                } else if let record {
                    detailView(record)
                        .id(record.id)
                        .transition(.asymmetric(
                            insertion: .opacity.combined(with: .scale(scale: 0.95)).combined(with: .move(edge: transitionEdge)),
                            removal: .opacity.combined(with: .scale(scale: 0.95)).combined(with: .move(edge: transitionEdge.opposite))
                        ))
                } else {
                    emptyView
                }
            }
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    if record != nil {
                        Button {
                            showingEdit = true
                        } label: {
                            Image(systemName: "square.and.pencil")
                                .appFont(.caption)
                                .foregroundStyle(theme.accent)
                        }
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button(action: {
                        if records.isEmpty {
                            showingEmptyAlert = true
                        } else {
                            pickRandom()
                        }
                    }) {
                        Image(systemName: "shuffle")
                            .appFont(.caption)
                            .foregroundStyle(theme.accent)
                            .symbolEffect(.bounce, value: record?.id)
                    }
                }
            }
            .alert("还没有告别记录", isPresented: $showingEmptyAlert) {
                Button("好的", role: .cancel) { }
            } message: {
                Text("先去「告别清单」Tab 记下第一件物品吧")
            }
            .sheet(isPresented: $showingEdit) {
                if let r = record {
                    EditFarewellView(record: r)
                }
            }
            .fullScreenCover(item: Binding(
                get: { photoViewerFilenames.map { IdentifiableArray(value: $0) } },
                set: { photoViewerFilenames = $0?.value }
            )) { wrapper in
                PhotoViewerSheet(filenames: wrapper.value) {
                    photoViewerFilenames = nil
                }
            }
            .onAppear {
                if record == nil, !records.isEmpty { pickRandom() }
            }
            .onChange(of: records.count) { _, _ in
                if record == nil, !records.isEmpty { pickRandom() }
            }
            .animation(.spring(response: 0.6, dampingFraction: 0.7, blendDuration: 0.3), value: record?.id)
            .sensoryFeedback(.impact(weight: .light), trigger: record?.id)
        }
    }

    private func pickRandom() {
        guard !records.isEmpty else { return }
        let newRecord = records.randomElement()!
        // 根据新旧记录在排序列表中的相对位置决定翻页方向
        if let current = record,
           let oldIdx = records.firstIndex(where: { $0.id == current.id }),
           let newIdx = records.firstIndex(where: { $0.id == newRecord.id }) {
            // records 按 farewellDate desc 排序；index 大 = 时间更早
            // 视觉上：翻到「更旧」从左滑入，翻到「更新」从右滑入
            transitionEdge = newIdx > oldIdx ? .leading : .trailing
        } else {
            transitionEdge = .bottom  // 首次进入
        }
        withAnimation(.spring(response: 0.6, dampingFraction: 0.7, blendDuration: 0.3)) {
            record = newRecord
        }
    }

    // MARK: - 详情

    private func detailView(_ item: FarewellRecord) -> some View {
        RemembranceCardView(
            record: item,
            revealedLetterCount: $revealedLetterCount,
            onLongPress: {
                if !item.photoFilenames.isEmpty {
                    photoViewerFilenames = item.photoFilenames
                }
            }
        )
            .task(id: item.id) {
                revealedLetterCount = 0
                let letter = item.farewellLetter ?? ""
                let total = "\u{201C}\(letter)\u{201D}".count
                guard total > 0 else { return }
                for i in 0..<total {
                    try? await Task.sleep(for: .milliseconds(30))
                    revealedLetterCount = i + 1
                }
            }
    }

    // MARK: - 辅助

    private var emptyView: some View {
        VStack(spacing: .md) {
            Spacer()
            Image(systemName: "heart")
                .font(.system(size: 48, weight: .ultraLight))
                .foregroundStyle(theme.secondary)
            Text("还没有告别记录")
                .appFont(.body)
                .foregroundStyle(theme.secondary)
            Text("在「告别清单」Tab 记下第一件物品，\n怀念就会出现在这里")
                .appFont(.caption)
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

private struct IdentifiableArray: Identifiable {
    let value: [String]
    var id: String { value.joined(separator: ",") }
}

private extension Edge {
    /// 用于 #11C 翻页方向感：返回对侧 edge，让 transition 的 insertion/removal 方向相反。
    var opposite: Edge {
        switch self {
        case .leading: return .trailing
        case .trailing: return .leading
        case .top: return .bottom
        case .bottom: return .top
        }
    }
}