import UIKit
import SwiftUI

// MARK: - 独立横屏播放窗口（全屏视频层）

final class BilibiliPlayerWindow {
    static let shared = BilibiliPlayerWindow()
    private var window: UIWindow?

    var isPresented: Bool { window != nil }

    func present(title: String, urlString: String, fallbackURLString: String?, onDismiss: @escaping () -> Void) {
        dismiss()
        guard let scene = Self.keyScene else { return }

        let window = UIWindow(windowScene: scene)
        window.windowLevel = .alert + 1

        let content = BilibiliWebView(
            title: title,
            urlString: urlString,
            onDismiss: { [weak self] in
                self?.dismiss()
                onDismiss()
            },
            fallbackURLString: fallbackURLString
        )
        .ignoresSafeArea()

        let host = UIHostingController(rootView: content)
        let container = LandscapeContainerViewController(root: host)
        window.rootViewController = container
        window.makeKeyAndVisible()
        self.window = window

        // 请求横屏
        if #available(iOS 16.0, *) {
            scene.requestGeometryUpdate(.iOS(interfaceOrientations: .landscape)) { _ in }
        } else {
            UIDevice.current.setValue(UIInterfaceOrientation.landscapeRight.rawValue, forKey: "orientation")
            UIViewController.attemptRotationToDeviceOrientation()
        }
    }

    func dismiss() {
        guard let window else { return }
        window.isHidden = true
        window.rootViewController = nil
        self.window = nil

        // 归还主窗口 key 状态
        Self.keyScene?.windows.first(where: { $0 !== window })?.makeKey()

        // 恢复竖屏
        if #available(iOS 16.0, *) {
            Self.keyScene?.requestGeometryUpdate(.iOS(interfaceOrientations: .portrait)) { _ in }
        } else {
            UIDevice.current.setValue(UIInterfaceOrientation.portrait.rawValue, forKey: "orientation")
            UIViewController.attemptRotationToDeviceOrientation()
        }
    }

    private static var keyScene: UIWindowScene? {
        UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .first(where: { $0.windows.contains(where: \.isKeyWindow) })
            ?? UIApplication.shared.connectedScenes
                .compactMap { $0 as? UIWindowScene }
                .first
    }
}

// MARK: - 横屏容器 VC

final class LandscapeContainerViewController: UIViewController {
    private let root: UIViewController

    init(root: UIViewController) {
        self.root = root
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override func viewDidLoad() {
        super.viewDidLoad()
        addChild(root)
        view.addSubview(root.view)
        root.view.frame = view.bounds
        root.view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        root.didMove(toParent: self)
    }

    override var supportedInterfaceOrientations: UIInterfaceOrientationMask { .landscape }
    override var shouldAutorotate: Bool { false }
}