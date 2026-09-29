import Foundation
import QCloudStreamTTS

final class TencentStreamTTSService: NSObject, QCloudStreamTTSListener {
    private var controller: QCloudStreamTTSController?
    private var player: TencentPCMStreamPlayer?
    private var pendingText = ""
    private var finishHandler: (() -> Void)?
    private var errorHandler: ((Error) -> Void)?
    private var didFinish = false

    func speak(
        text: String,
        configuration: TencentTTSConfigurationSnapshot,
        onFinish: @escaping () -> Void,
        onError: @escaping (Error) -> Void
    ) {
        stop(notify: false)

        let trimmedText = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedText.isEmpty else {
            onError(TencentTTSError.emptyText)
            return
        }

        guard configuration.hasCredentials else {
            onError(TencentTTSError.missingCredentials)
            return
        }

        do {
            player = try TencentPCMStreamPlayer()
        } catch {
            onError(error)
            return
        }

        pendingText = trimmedText
        finishHandler = onFinish
        errorHandler = onError
        didFinish = false

        let config = QCloudStreamTTSConfig()
        config.appID = configuration.appID
        config.secretID = configuration.secretID
        config.secretKey = configuration.secretKey
        config.token = configuration.token
        config.connectTimeout = Int32(configuration.connectTimeout)
        config.setApiParam(kVoiceType, ivalue: configuration.voiceType)
        config.setApiParam(kVolume, fvalue: configuration.volume)
        config.setApiParam(kSpeed, fvalue: configuration.speed)
        config.setApiParam(kSampleRate, ivalue: 16_000)
        config.setApiParam(kCodec, value: "pcm")

        let emotion = configuration.emotionCategory.trimmingCharacters(in: .whitespacesAndNewlines)
        if !emotion.isEmpty {
            config.setApiParam(kEmotionCategory, value: emotion)
            config.setApiParam(kEmotionIntensity, ivalue: configuration.emotionIntensity)
        }

        #if DEBUG
        print("[TencentStreamTTS] start appID=\(configuration.appID), secretIDPrefix=\(configuration.secretID.prefix(8)), hasToken=\(!configuration.token.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty), voiceType=\(configuration.voiceType)")
        #endif
        controller = config.build(self)
    }

    func stop() {
        stop(notify: false)
    }

    private func stop(notify: Bool) {
        controller?.stop()
        controller = nil
        player?.stop()
        player = nil
        pendingText = ""
        if notify, !didFinish {
            didFinish = true
            finishHandler?()
        }
        finishHandler = nil
        errorHandler = nil
    }

    func onReady() {
        controller?.synthesis(pendingText)
    }

    func onData(_ data: Data) {
        guard !data.isEmpty else { return }

        do {
            try player?.put(data: data)
        } catch {
            onError(error as NSError)
        }
    }

    func onMessage(_ msg: String) {
        #if DEBUG
        print("[TencentStreamTTS] \(msg)")
        #endif
    }

    func onLog(_ value: String, level: Int32) {
        #if DEBUG
        print("[TencentStreamTTS][\(level)] \(value)")
        #endif
    }

    func onFinish() {
        DispatchQueue.main.async { [weak self] in
            guard let self else { return }
            self.didFinish = true
            let finish = self.finishHandler
            self.stop(notify: false)
            finish?()
        }
    }

    func onError(_ error: Error) {
        DispatchQueue.main.async { [weak self] in
            guard let self else { return }
            let nsError = error as NSError
            #if DEBUG
            print("[TencentStreamTTS] error code=\(nsError.code), domain=\(nsError.domain), userInfo=\(nsError.userInfo)")
            #endif
            let handler = self.errorHandler
            self.stop(notify: false)
            handler?(error)
        }
    }

    static func userFacingMessage(for error: Error) -> String {
        let nsError = error as NSError
        if let message = nsError.userInfo["Message"] as? String {
            if message.contains("\"code\":3022") || message.contains("resource pack allowance has been exhausted") {
                return "腾讯云语音资源包额度已用尽，请在腾讯云控制台检查资源包或开通后付费。"
            }
            if message.contains("Signature") || message.contains("Authorization") {
                return "腾讯云语音鉴权失败，请检查 AppID、临时密钥、Token 和密钥有效期。"
            }
            return message
        }

        if nsError.domain == "QCloudStreamTTS", nsError.code == 2003 {
            return "腾讯云语音服务端返回错误，请查看控制台日志中的 Message。"
        }

        return error.localizedDescription
    }
}
