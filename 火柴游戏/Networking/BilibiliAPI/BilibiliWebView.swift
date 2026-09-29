import SwiftUI
import WebKit

// MARK: - B站网页容器（横屏全屏：浮动返回 + 边缘到边缘播放器）

struct BilibiliWebView: View {
    let title: String
    let urlString: String
    let onDismiss: () -> Void
    var fallbackURLString: String? = nil

    @State private var showingDetail = false

    private var currentURL: String {
        showingDetail ? (fallbackURLString ?? urlString) : urlString
    }

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            BilibiliWKWebView(urlString: currentURL)
                .ignoresSafeArea()

            // 浮动控制（避开刘海/灵动岛）
            VStack {
                HStack(spacing: 10) {
                    floatingButton(systemName: "chevron.left") {
                        onDismiss()
                    }

                    if let fallbackURLString, !fallbackURLString.isEmpty {
                        floatingButton(systemName: showingDetail ? "play.rectangle.fill" : "safari") {
                            showingDetail.toggle()
                        }
                    }
                    Spacer()
                }
                .padding(.top, 4)
                Spacer()
            }
            .padding(.horizontal, 10)
            .safeAreaPadding(.horizontal)
        }
    }

    private func floatingButton(systemName: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: systemName)
                .font(.system(size: 16, weight: .bold))
                .foregroundStyle(.white)
                .frame(width: 38, height: 38)
                .background(Color.black.opacity(0.45), in: Circle())
        }
        .buttonStyle(.plain)
    }
}

// MARK: - WKWebView 包装

private struct BilibiliWKWebView: UIViewRepresentable {
    let urlString: String

    func makeCoordinator() -> Coordinator { Coordinator() }

    func makeUIView(context: Context) -> WKWebView {
        let configuration = WKWebViewConfiguration()
        // 允许自动播放（嵌入式播放器 autoplay=1 生效）
        configuration.mediaTypesRequiringUserActionForPlayback = []
        configuration.allowsInlineMediaPlayback = true

        let webView = WKWebView(frame: .zero, configuration: configuration)
        webView.navigationDelegate = context.coordinator
        webView.uiDelegate = context.coordinator
        webView.allowsBackForwardNavigationGestures = true
        webView.scrollView.showsVerticalScrollIndicator = false
        webView.scrollView.showsHorizontalScrollIndicator = false
        webView.isOpaque = false
        webView.backgroundColor = .black
        webView.scrollView.backgroundColor = .black
        load(webView)
        return webView
    }

    func updateUIView(_ webView: WKWebView, context: Context) {
        if webView.url?.absoluteString != urlString {
            load(webView)
        }
    }

    static func dismantleUIView(_ webView: WKWebView, coordinator: Coordinator) {
        webView.navigationDelegate = nil
        webView.uiDelegate = nil
        webView.stopLoading()
    }

    private func load(_ webView: WKWebView) {
        guard let url = URL(string: urlString) else { return }
        webView.load(URLRequest(url: url))
    }

    final class Coordinator: NSObject, WKNavigationDelegate, WKUIDelegate {
        func webView(
            _ webView: WKWebView,
            createWebViewWith configuration: WKWebViewConfiguration,
            for navigationAction: WKNavigationAction,
            windowFeatures: WKWindowFeatures
        ) -> WKWebView? {
            if navigationAction.targetFrame == nil, let url = navigationAction.request.url {
                webView.load(URLRequest(url: url))
            }
            return nil
        }
    }
}