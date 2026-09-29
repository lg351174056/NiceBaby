import AVFoundation
import Foundation

final class TencentPCMStreamPlayer {
    private let engine = AVAudioEngine()
    private let playerNode = AVAudioPlayerNode()
    private let inputFormat: AVAudioFormat
    private let outputFormat: AVAudioFormat
    private let converter: AVAudioConverter
    private var tail = Data()

    init() throws {
        let session = AVAudioSession.sharedInstance()
        try session.setCategory(.playback, mode: .spokenAudio, options: [.duckOthers])
        try session.setActive(true)

        guard let inputFormat = AVAudioFormat(commonFormat: .pcmFormatInt16, sampleRate: 16_000, channels: 1, interleaved: false),
              let outputFormat = AVAudioFormat(standardFormatWithSampleRate: 16_000, channels: 1),
              let converter = AVAudioConverter(from: inputFormat, to: outputFormat) else {
            throw TencentTTSError.audioSetupFailed
        }

        self.inputFormat = inputFormat
        self.outputFormat = outputFormat
        self.converter = converter

        engine.attach(playerNode)
        engine.connect(playerNode, to: engine.outputNode, format: outputFormat)
        try engine.start()
        playerNode.play()
    }

    func put(data: Data) throws {
        guard !data.isEmpty else { return }

        tail.append(data)
        var localData = tail

        if tail.count % 2 == 1 {
            tail = localData.subdata(in: localData.count - 1..<localData.count)
            localData.count -= 1
        } else {
            tail = Data()
        }

        guard !localData.isEmpty else { return }
        let bytesPerFrame = inputFormat.streamDescription.pointee.mBytesPerFrame
        let frameCapacity = AVAudioFrameCount(localData.count) / bytesPerFrame

        guard let inputBuffer = AVAudioPCMBuffer(pcmFormat: inputFormat, frameCapacity: frameCapacity),
              let outputBuffer = AVAudioPCMBuffer(pcmFormat: outputFormat, frameCapacity: frameCapacity) else {
            throw TencentTTSError.audioBufferFailed
        }

        inputBuffer.frameLength = frameCapacity
        localData.withUnsafeBytes { rawBuffer in
            guard let source = rawBuffer.baseAddress?.assumingMemoryBound(to: Int16.self),
                  let channels = inputBuffer.int16ChannelData else {
                return
            }
            channels[0].update(from: source, count: Int(frameCapacity))
        }

        try converter.convert(to: outputBuffer, from: inputBuffer)
        playerNode.scheduleBuffer(outputBuffer)
    }

    func stop() {
        tail.removeAll()
        playerNode.stop()
        engine.stop()
        try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
    }
}

enum TencentTTSError: LocalizedError {
    case audioSetupFailed
    case audioBufferFailed
    case emptyText
    case missingCredentials

    var errorDescription: String? {
        switch self {
        case .audioSetupFailed:
            return "腾讯云语音播放器初始化失败"
        case .audioBufferFailed:
            return "腾讯云语音音频缓冲区创建失败"
        case .emptyText:
            return "朗读文本为空"
        case .missingCredentials:
            return "腾讯云语音凭证未配置完整"
        }
    }
}
