import AVFoundation
import Combine
import SwiftUI

/// 使用系统 `AVSpeechSynthesizer` 朗读诗词（中文语音包随系统语言设置）。
@MainActor
final class PoemSpeechService: NSObject, ObservableObject, AVSpeechSynthesizerDelegate {
    static let shared = PoemSpeechService()

    private let synthesizer = AVSpeechSynthesizer()
    private let tencentTTSService = TencentStreamTTSService()
    private let tencentSettings = TencentTTSSettings.shared

    @Published private(set) var activePoemId: Int?
    @Published private(set) var lastTencentErrorMessage: String?

    override private init() {
        super.init()
        synthesizer.delegate = self
    }

    /// 朗读标题、作者与正文；再次点击同一首则停止。
    func toggleSpeak(poem: Poem) {
        if activePoemId == poem.id {
            stop()
            return
        }
        stop()
        lastTencentErrorMessage = nil
        let text = "\(poem.title)。作者\(poem.author)。\(poem.contents.replacingOccurrences(of: "\n", with: "，"))"
        activePoemId = poem.id

        if tencentSettings.enabled && tencentSettings.hasCredentials {
            let configuration = tencentSettings.snapshot
            tencentTTSService.speak(
                text: text,
                configuration: configuration,
                onFinish: { [weak self] in
                    self?.activePoemId = nil
                },
                onError: { [weak self] error in
                    #if DEBUG
                    let nsError = error as NSError
                    print("[PoemSpeechService] Tencent TTS failed, code=\(nsError.code), domain=\(nsError.domain), userInfo=\(nsError.userInfo)")
                    #endif
                    self?.lastTencentErrorMessage = TencentStreamTTSService.userFacingMessage(for: error)
                    self?.speakWithSystemVoice(text: text)
                }
            )
            return
        }

        speakWithSystemVoice(text: text)
    }

    private func speakWithSystemVoice(text: String) {
        let utterance = AVSpeechUtterance(string: text)
        utterance.voice = AVSpeechSynthesisVoice(language: "zh-CN")
            ?? AVSpeechSynthesisVoice(language: "zh-Hans")
        utterance.rate = Float(AVSpeechUtteranceDefaultSpeechRate * 0.45)
        utterance.preUtteranceDelay = 0.08
        synthesizer.speak(utterance)
    }

    func stop() {
        tencentTTSService.stop()
        if synthesizer.isSpeaking {
            synthesizer.stopSpeaking(at: .immediate)
        }
        activePoemId = nil
    }

    nonisolated func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        Task { @MainActor in self.activePoemId = nil }
    }

    nonisolated func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didCancel utterance: AVSpeechUtterance) {
        Task { @MainActor in self.activePoemId = nil }
    }
}
