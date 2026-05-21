import SwiftUI

struct TokenInputView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var api = VideoAPIService.shared
    @State private var inputToken = ""

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                VStack(spacing: 12) {
                    Image(systemName: "key.horizontal.fill")
                        .font(.system(size: 40))
                        .foregroundStyle(AppTheme.accentPurple)
                    Text("设置 API Token")
                        .font(AppTheme.titleSection())
                        .foregroundStyle(AppTheme.textPrimary)
                    Text("从 Proxyman 抓包获取 Authorization 头中\nBearer 后面的内容")
                        .font(.system(size: 13, weight: .medium, design: .rounded))
                        .foregroundStyle(AppTheme.textSecondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.top, 20)

                TextEditor(text: $inputToken)
                    .font(.system(size: 13, design: .monospaced))
                    .frame(height: 120)
                    .padding(12)
                    .background(AppTheme.background)
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .stroke(AppTheme.separator, lineWidth: 1)
                    )

                Button {
                    let cleaned = inputToken
                        .trimmingCharacters(in: .whitespacesAndNewlines)
                        .replacingOccurrences(of: "Bearer ", with: "")
                    api.token = cleaned
                    dismiss()
                } label: {
                    Text("保存")
                        .font(.system(size: 17, weight: .bold, design: .rounded))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                }
                .buttonStyle(.borderedProminent)
                .disabled(inputToken.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)

                Spacer()
            }
            .padding(.horizontal, AppTheme.paddingScreen)
            .navigationTitle("Token 设置")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("取消") { dismiss() }
                }
            }
            .onAppear {
                inputToken = api.token
            }
        }
    }
}
