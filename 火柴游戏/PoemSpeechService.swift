import AVFoundation
import Combine
import SwiftUI

/// 使用系统 `AVSpeechSynthesizer` 朗读诗词（中文语音包随系统语言设置）。
final class PoemSpeechService: NSObject, ObservableObject, AVSpeechSynthesizerDelegate {
    static let shared = PoemSpeechService()

    private let synthesizer = AVSpeechSynthesizer()

    @Published private(set) var activePoemId: Int?

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
        let text = "\(poem.title)。作者\(poem.author)。\(poem.contents.replacingOccurrences(of: "\n", with: "，"))"
        let utterance = AVSpeechUtterance(string: text)
        utterance.voice = AVSpeechSynthesisVoice(language: "zh-CN")
            ?? AVSpeechSynthesisVoice(language: "zh-Hans")
        utterance.rate = Float(AVSpeechUtteranceDefaultSpeechRate * 0.45)
        utterance.preUtteranceDelay = 0.08
        synthesizer.speak(utterance)
        activePoemId = poem.id
    }

    func stop() {
        if synthesizer.isSpeaking {
            synthesizer.stopSpeaking(at: .immediate)
        }
        activePoemId = nil
    }

    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        DispatchQueue.main.async { [weak self] in self?.activePoemId = nil }
    }

    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didCancel utterance: AVSpeechUtterance) {
        DispatchQueue.main.async { [weak self] in self?.activePoemId = nil }
    }
}
