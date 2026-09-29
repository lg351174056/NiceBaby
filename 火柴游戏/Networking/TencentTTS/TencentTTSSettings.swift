import Foundation
import Combine

struct TencentTTSVoice: Identifiable, Hashable {
    let id: Int
    let name: String
    let detail: String

    var displayName: String {
        "\(name) \(id)"
    }
}

struct TencentTTSConfigurationSnapshot {
    let appID: String
    let secretID: String
    let secretKey: String
    let token: String
    let voiceType: Int
    let speed: Float
    let volume: Float
    let emotionCategory: String
    let emotionIntensity: Int
    let connectTimeout: Int

    var hasCredentials: Bool {
        missingCredentialNames.isEmpty
    }

    var missingCredentialNames: [String] {
        var names: [String] = []
        if appID.trimmed.isEmpty { names.append("AppID") }
        if secretID.trimmed.isEmpty { names.append("TmpSecretId") }
        if secretKey.trimmed.isEmpty { names.append("TmpSecretKey") }
        return names
    }
}

@MainActor
final class TencentTTSSettings: ObservableObject {
    static let shared = TencentTTSSettings()

    static let voices: [TencentTTSVoice] = [
        TencentTTSVoice(id: 1001, name: "智瑜", detail: "温和女声"),
        TencentTTSVoice(id: 1002, name: "智聆", detail: "通用女声"),
        TencentTTSVoice(id: 1003, name: "智美", detail: "明亮女声"),
        TencentTTSVoice(id: 1004, name: "智云", detail: "稳重男声"),
        TencentTTSVoice(id: 1005, name: "智莉", detail: "亲和女声"),
        TencentTTSVoice(id: 1007, name: "智娜", detail: "自然女声"),
        TencentTTSVoice(id: 1008, name: "智琪", detail: "清亮女声"),
        TencentTTSVoice(id: 1009, name: "智芸", detail: "柔和女声"),
        TencentTTSVoice(id: 1010, name: "智华", detail: "标准男声"),
        TencentTTSVoice(id: 1017, name: "智蓉", detail: "沉稳女声"),
        TencentTTSVoice(id: 1018, name: "智靖", detail: "平实男声"),
        TencentTTSVoice(id: 101001, name: "智瑜精品", detail: "精品女声")
    ]

    @Published var enabled: Bool { didSet { save() } }
    @Published var appID: String { didSet { save() } }
    @Published var secretID: String { didSet { save() } }
    @Published var secretKey: String { didSet { save() } }
    @Published var token: String { didSet { save() } }
    @Published var voiceType: Int { didSet { save() } }
    @Published var speed: Float { didSet { save() } }
    @Published var volume: Float { didSet { save() } }
    @Published var emotionCategory: String { didSet { save() } }
    @Published var emotionIntensity: Int { didSet { save() } }
    @Published var connectTimeout: Int { didSet { save() } }

    var hasCredentials: Bool {
        missingCredentialNames.isEmpty
    }

    var missingCredentialNames: [String] {
        var names: [String] = []
        if appID.trimmed.isEmpty { names.append("AppID") }
        if secretID.trimmed.isEmpty { names.append("TmpSecretId") }
        if secretKey.trimmed.isEmpty { names.append("TmpSecretKey") }
        return names
    }

    var selectedVoice: TencentTTSVoice {
        Self.voices.first { $0.id == voiceType } ?? Self.voices[0]
    }

    var snapshot: TencentTTSConfigurationSnapshot {
        TencentTTSConfigurationSnapshot(
            appID: appID,
            secretID: secretID,
            secretKey: secretKey,
            token: token,
            voiceType: voiceType,
            speed: speed,
            volume: volume,
            emotionCategory: emotionCategory,
            emotionIntensity: emotionIntensity,
            connectTimeout: connectTimeout
        )
    }

    private let defaults = UserDefaults.standard
    private let prefix = "TencentTTSSettings."
    private var isLoading = true

    private init() {
        let local = Self.loadLocalConfig()
        enabled = defaults.object(forKey: prefix + "enabled") as? Bool ?? false
        appID = Self.nonEmptyValue(local["AppID"], fallback: defaults.string(forKey: prefix + "appID"))
        secretID = Self.nonEmptyValue(local["TmpSecretId"], fallback: defaults.string(forKey: prefix + "secretID"))
        secretKey = Self.nonEmptyValue(local["TmpSecretKey"], fallback: defaults.string(forKey: prefix + "secretKey"))
        token = Self.nonEmptyValue(local["Token"], fallback: defaults.string(forKey: prefix + "token"))
        voiceType = defaults.object(forKey: prefix + "voiceType") as? Int ?? 1001
        speed = defaults.object(forKey: prefix + "speed") as? Float ?? 0
        volume = defaults.object(forKey: prefix + "volume") as? Float ?? 0
        emotionCategory = defaults.string(forKey: prefix + "emotionCategory") ?? ""
        emotionIntensity = defaults.object(forKey: prefix + "emotionIntensity") as? Int ?? 100
        connectTimeout = defaults.object(forKey: prefix + "connectTimeout") as? Int ?? 8_000
        isLoading = false
    }

    func resetTuning() {
        voiceType = 1001
        speed = 0
        volume = 0
        emotionCategory = ""
        emotionIntensity = 100
        connectTimeout = 8_000
    }

    private func save() {
        guard !isLoading else { return }
        defaults.set(enabled, forKey: prefix + "enabled")
        defaults.set(appID, forKey: prefix + "appID")
        defaults.set(secretID, forKey: prefix + "secretID")
        defaults.set(secretKey, forKey: prefix + "secretKey")
        defaults.set(token, forKey: prefix + "token")
        defaults.set(voiceType, forKey: prefix + "voiceType")
        defaults.set(speed, forKey: prefix + "speed")
        defaults.set(volume, forKey: prefix + "volume")
        defaults.set(emotionCategory, forKey: prefix + "emotionCategory")
        defaults.set(emotionIntensity, forKey: prefix + "emotionIntensity")
        defaults.set(connectTimeout, forKey: prefix + "connectTimeout")
    }

    private static func loadLocalConfig() -> [String: String] {
        guard let url = Bundle.main.url(forResource: "TencentTTSConfig.local", withExtension: "plist"),
              let data = try? Data(contentsOf: url),
              let plist = try? PropertyListSerialization.propertyList(from: data, format: nil) as? [String: String] else {
            return [:]
        }
        return plist
    }

    private static func nonEmptyValue(_ value: String?, fallback: String?) -> String {
        if let value, !value.trimmed.isEmpty {
            return value
        }
        return fallback ?? ""
    }
}

private extension String {
    var trimmed: String {
        trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
