import SwiftUI
import PDFKit

struct PDFKitView: UIViewRepresentable {
    let document: PDFDocument
    @Binding var currentPage: Int
    @Binding var totalPages: Int
    var onTap: () -> Void

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    func makeUIView(context: Context) -> PDFView {
        let pdfView = PDFView()
        pdfView.autoScales = true
        pdfView.displayMode = .singlePage
        pdfView.displayDirection = .horizontal
        pdfView.usePageViewController(true, withViewOptions: [
            UIPageViewController.OptionsKey.interPageSpacing: 0
        ])
        pdfView.displaysPageBreaks = false
        pdfView.pageShadowsEnabled = false
        pdfView.backgroundColor = UIColor(red: 250/255.0, green: 248/255.0, blue: 245/255.0, alpha: 1.0)
        pdfView.document = document

        DispatchQueue.main.async {
            totalPages = document.pageCount
        }

        if currentPage > 0, currentPage < document.pageCount,
           let page = document.page(at: currentPage) {
            pdfView.go(to: page)
        }

        NotificationCenter.default.addObserver(
            context.coordinator,
            selector: #selector(Coordinator.pageChanged(_:)),
            name: .PDFViewPageChanged,
            object: pdfView
        )

        let tapGesture = UITapGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.handleTap(_:)))
        tapGesture.numberOfTapsRequired = 1
        pdfView.addGestureRecognizer(tapGesture)

        return pdfView
    }

    func updateUIView(_ pdfView: PDFView, context: Context) {}

    class Coordinator: NSObject {
        let parent: PDFKitView

        init(_ parent: PDFKitView) {
            self.parent = parent
        }

        @objc func pageChanged(_ notification: Notification) {
            guard let pdfView = notification.object as? PDFView,
                  let currentPage = pdfView.currentPage,
                  let document = pdfView.document else { return }
            let index = document.index(for: currentPage)
            DispatchQueue.main.async {
                self.parent.currentPage = index
            }
        }

        @objc func handleTap(_ gesture: UITapGestureRecognizer) {
            parent.onTap()
        }
    }
}

struct BookReaderView: View {
    let bookTitle: String
    let bookURL: URL

    @Environment(\.dismiss) private var dismiss
    @State private var document: PDFDocument?
    @State private var loadFailed = false
    @State private var currentPage: Int = 0
    @State private var totalPages: Int = 0
    @State private var showControls = true

    var body: some View {
        ZStack {
            Color(red: 250/255.0, green: 248/255.0, blue: 245/255.0).ignoresSafeArea()

            if let document {
                PDFKitView(document: document, currentPage: $currentPage, totalPages: $totalPages) {
                    withAnimation(.easeInOut(duration: 0.25)) {
                        showControls.toggle()
                    }
                }
                .ignoresSafeArea(edges: .bottom)
            } else if loadFailed {
                errorView
            } else {
                loadingView
            }

            if showControls {
                controlsOverlay
            }
        }
        .navigationBarBackButtonHidden(true)
        .toolbar(.hidden, for: .tabBar)
        .statusBarHidden(!showControls)
        .task {
            loadDocument()
        }
        .onDisappear {
            saveProgress()
        }
    }

    private var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.5)
            Text("正在打开绘本…")
                .font(.system(size: 16, weight: .medium, design: .rounded))
                .foregroundStyle(.secondary)
        }
    }

    private var errorView: some View {
        VStack(spacing: 12) {
            Image(systemName: "doc.badge.exclamationmark")
                .font(.system(size: 48))
                .foregroundStyle(.orange)
            Text("无法加载这本绘本")
                .font(.system(size: 18, weight: .semibold, design: .rounded))
                .foregroundStyle(.primary)
            Text(bookTitle)
                .font(.system(size: 14, design: .rounded))
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var controlsOverlay: some View {
        VStack {
            HStack {
                Button {
                    dismiss()
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 32))
                        .foregroundStyle(.white, .black.opacity(0.5))
                        .shadow(color: .black.opacity(0.2), radius: 4, x: 0, y: 2)
                }

                Spacer()

                Text(bookTitle)
                    .font(.system(size: 15, weight: .semibold, design: .rounded))
                    .foregroundStyle(.white)
                    .shadow(color: .black.opacity(0.3), radius: 2, x: 0, y: 1)
                    .lineLimit(1)

                Spacer()

                Color.clear.frame(width: 32, height: 32)
            }
            .padding(.horizontal, 20)
            .padding(.top, 12)
            .padding(.bottom, 8)
            .background(
                LinearGradient(
                    colors: [.black.opacity(0.5), .clear],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea(edges: .top)
            )

            Spacer()

            if totalPages > 0 {
                HStack(spacing: 8) {
                    Text("\(currentPage + 1) / \(totalPages)")
                        .font(.system(size: 14, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 6)
                        .background(.black.opacity(0.5), in: Capsule())
                }
                .padding(.bottom, 16)
            }
        }
        .transition(.opacity)
    }

    private func loadDocument() {
        print("📕 loadDocument called")
        print("📕 bookURL: \(bookURL)")
        print("📕 bookURL.path: \(bookURL.path)")
        print("📕 file exists: \(FileManager.default.fileExists(atPath: bookURL.path))")

        let loaded = PDFDocument(url: bookURL)
        print("📕 PDFDocument result: \(loaded == nil ? "nil ❌" : "success ✅")")

        if let loaded {
            print("📕 pageCount: \(loaded.pageCount)")
            let savedPage = AppProgressStore.shared.bookProgress(for: bookURL.lastPathComponent)
            currentPage = min(savedPage, max(loaded.pageCount - 1, 0))
            document = loaded
            print("📕 document assigned, currentPage=\(currentPage)")
        } else {
            loadFailed = true
            print("📕 loadFailed = true")
        }
    }

    private func saveProgress() {
        guard totalPages > 0 else { return }
        AppProgressStore.shared.saveBookProgress(page: currentPage, for: bookURL.lastPathComponent)
    }
}
