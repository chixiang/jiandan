import SwiftUI

/// 价格输入框（cents-first 风格）
///
/// 内部以整数 `cents`（分）运算，显示始终为 "X.XX"。
/// 每次按键相当于「在末尾追加一位数字」：
/// 输入 `5` → 0.05，输入 `2` → 0.52，输入 `3` → 5.23；
/// 退格反向，从右往左丢位：5.23 → 0.52 → 0.05 → 0.00。
struct PriceInputView: View {
    @Binding var price: Double?
    let symbol: String

    @Environment(\.appTheme) private var theme

    @State private var cents: Int = 0
    @State private var displayText: String = "0.00"
    @State private var isUpdating = false

    var body: some View {
        HStack(spacing: 0) {
            Text(symbol)
                .foregroundStyle(theme.secondary)
            TextField("0.00", text: $displayText)
                .keyboardType(.numberPad)
                .multilineTextAlignment(.trailing)
                .onChange(of: displayText) { _, newValue in
                    processInput(newValue)
                }
        }
        .frame(maxWidth: .infinity, alignment: .trailing)
        .onAppear {
            if let price, price > 0 {
                cents = Int(round(price * 100))
                displayText = String(format: "%.2f", Double(cents) / 100.0)
            }
        }
    }

    private func processInput(_ newValue: String) {
        guard !isUpdating else { return }
        isUpdating = true
        defer { isUpdating = false }

        let digits = newValue.filter { $0.isNumber }
        cents = min(Int(digits) ?? 0, 999_999_999)
        let formatted = String(format: "%.2f", Double(cents) / 100.0)
        if displayText != formatted {
            displayText = formatted
        }
        price = cents > 0 ? Double(cents) / 100.0 : nil
    }
}