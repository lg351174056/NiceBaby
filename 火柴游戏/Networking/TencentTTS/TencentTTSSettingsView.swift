import SwiftUI

struct TencentTTSSettingsView: View {
    @StateObject private var settings = TencentTTSSettings.shared
    @StateObject private var speechService = PoemSpeechService.shared
    @State private var showCredentials = false
    @State private var lastErrorMessage: String?

    private let samplePoem = Poem(
        id: -10_001,
        title: "静夜思",
        author: "李白",
        type: "唐诗",
        contents: "床前明月光\n疑是地上霜\n举头望明月\n低头思故乡"
    )

    var body: some View {
        Form {
            Section {
                Toggle("启用腾讯云语音", isOn: $settings.enabled)
                HStack {
                    Text("当前音色")
                    Spacer()
                    Text(settings.selectedVoice.displayName)
                        .foregroundStyle(.secondary)
                }
            } footer: {
                Text("关闭后会自动使用 iOS 系统语音。临时密钥过期或网络失败时，朗读也会回退到系统语音。")
            }

            Section("声音") {
                Picker("音色", selection: $settings.voiceType) {
                    ForEach(TencentTTSSettings.voices) { voice in
                        VStack(alignment: .leading) {
                            Text(voice.displayName)
                            Text(voice.detail)
                        }
                        .tag(voice.id)
                    }
                }

                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("语速")
                        Spacer()
                        Text(String(format: "%.1f", settings.speed))
                            .foregroundStyle(.secondary)
                    }
                    Slider(value: $settings.speed, in: -2...6, step: 0.5)
                }

                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("音量")
                        Spacer()
                        Text(String(format: "%.1f", settings.volume))
                            .foregroundStyle(.secondary)
                    }
                    Slider(value: $settings.volume, in: -10...10, step: 0.5)
                }

                Button("恢复默认声音参数") {
                    settings.resetTuning()
                }
            }

            Section {
                TextField("情感类型，可留空", text: $settings.emotionCategory)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()

                Stepper("情感强度 \(settings.emotionIntensity)", value: $settings.emotionIntensity, in: 0...200, step: 10)
            } header: {
                Text("情感")
            } footer: {
                Text("仅当服务端和所选音色支持对应情感参数时生效；留空则不传情感参数。")
            }

            Section("调试") {
                Button {
                    lastErrorMessage = nil
                    if settings.enabled && !settings.hasCredentials {
                        lastErrorMessage = "缺少配置：\(settings.missingCredentialNames.joined(separator: "、"))。"
                        return
                    }
                    if speechService.activePoemId == samplePoem.id {
                        speechService.stop()
                    } else {
                        speechService.toggleSpeak(poem: samplePoem)
                    }
                } label: {
                    Label(
                        speechService.activePoemId == samplePoem.id ? "停止测试朗读" : "测试朗读《静夜思》",
                        systemImage: speechService.activePoemId == samplePoem.id ? "stop.fill" : "play.fill"
                    )
                }

                if let lastErrorMessage {
                    Text(lastErrorMessage)
                        .font(.footnote)
                        .foregroundStyle(.red)
                }

                if let message = speechService.lastTencentErrorMessage {
                    Text(message)
                        .font(.footnote)
                        .foregroundStyle(.red)
                }
            }

            Section {
                DisclosureGroup("腾讯云凭证", isExpanded: $showCredentials) {
                    TextField("AppID", text: $settings.appID)
                        .keyboardType(.numberPad)
                    TextField("TmpSecretId", text: $settings.secretID)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                    SecureField("TmpSecretKey", text: $settings.secretKey)
                    TextField("Token", text: $settings.token, axis: .vertical)
                        .lineLimit(3...6)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                    Stepper("连接超时 \(settings.connectTimeout) ms", value: $settings.connectTimeout, in: 1_000...30_000, step: 1_000)
                }
            } footer: {
                Text("这里先用于本地调试。上线前建议改成从你自己的后端换取临时密钥。")
            }
        }
        .navigationTitle("语音合成")
        .navigationBarTitleDisplayMode(.inline)
        .onDisappear {
            if speechService.activePoemId == samplePoem.id {
                speechService.stop()
            }
        }
    }
}
