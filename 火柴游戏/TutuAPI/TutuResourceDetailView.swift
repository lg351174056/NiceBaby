import Photos
import SwiftUI

struct TutuResourceDetailView: View {
    let resource: TutuResource
    @State private var detail: TutuResourceDetail?
    @State private var isLoading = false
    @State private var permission: TutuDownloadPermission?
    @State private var appeared = false
    @State private var isSaving = false
    @State private var saveProgress: Double = 0
    @State private var saveResult: SaveResult?
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private enum SaveResult {
        case success
        case failure(String)
    }

    var body: some View {
        Group {
            if isLoading {
                loadingAnimation
            } else if let detail {
                detailContent(detail)
            } else {
                VStack(spacing: 12) {
                    Image(systemName: "exclamationmark.triangle")
                        .font(.system(size: 40))
                        .foregroundStyle(AppTheme.accentTerracotta)
                    Text("加载失败")
                        .foregroundStyle(AppTheme.textPrimary)
                    Button {
                        Task { await loadDetail() }
                    } label: {
                        Text("重试")
                            .font(.system(size: 14, weight: .bold, design: .rounded))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 20)
                            .padding(.vertical, 10)
                            .background(AppTheme.accentBlue)
                            .clipShape(Capsule())
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .navigationTitle(resource.title)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(.hidden, for: .tabBar)
        .background(AppTheme.background)
        .overlay(alignment: .bottom) {
            if let detail, !detail.documents.isEmpty {
                saveButton(detail)
            }
        }
        .overlay {
            if isSaving {
                savingOverlay
            }
            if let result = saveResult {
                resultToast(result)
            }
        }
        .task {
            if detail == nil {
                await loadDetail()
            }
        }
    }

    // MARK: - Save Button

    private func saveButton(_ detail: TutuResourceDetail) -> some View {
        Button {
            Task { await saveToPhotos(detail) }
        } label: {
            HStack(spacing: 10) {
                Image(systemName: "square.and.arrow.down.fill")
                    .font(.system(size: 16, weight: .bold))
                Text("保存到相册")
                    .font(.system(size: 16, weight: .bold, design: .rounded))
            }
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                LinearGradient(
                    colors: [AppTheme.accentBlue, AppTheme.accentPurple],
                    startPoint: .leading, endPoint: .trailing
                )
            )
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .shadow(color: AppTheme.accentBlue.opacity(0.3), radius: 10, x: 0, y: 4)
        }
        .disabled(isSaving)
        .padding(.horizontal, AppTheme.paddingScreen)
        .padding(.bottom, 16)
        .background(
            LinearGradient(
                colors: [AppTheme.background.opacity(0), AppTheme.background],
                startPoint: .top, endPoint: .bottom
            )
            .frame(height: 100)
            .allowsHitTesting(false)
        )
    }

    // MARK: - Saving Overlay

    private var savingOverlay: some View {
        ZStack {
            Color.black.opacity(0.3)
                .ignoresSafeArea()

            VStack(spacing: 16) {
                ZStack {
                    Circle()
                        .stroke(Color.white.opacity(0.3), lineWidth: 4)
                        .frame(width: 60, height: 60)
                    Circle()
                        .trim(from: 0, to: saveProgress)
                        .stroke(Color.white, style: StrokeStyle(lineWidth: 4, lineCap: .round))
                        .frame(width: 60, height: 60)
                        .rotationEffect(.degrees(-90))
                    Text("\(Int(saveProgress * 100))%")
                        .font(.system(size: 14, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                }
                Text("正在保存...")
                    .font(.system(size: 15, weight: .medium, design: .rounded))
                    .foregroundStyle(.white)
            }
            .padding(32)
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        }
    }

    // MARK: - Result Toast

    private func resultToast(_ result: SaveResult) -> some View {
        VStack {
            Spacer()
            HStack(spacing: 10) {
                switch result {
                case .success:
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(AppTheme.accentSage)
                    Text("已保存到相册")
                        .font(.system(size: 15, weight: .semibold, design: .rounded))
                        .foregroundStyle(AppTheme.textPrimary)
                case .failure(let msg):
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(AppTheme.accentTerracotta)
                    Text(msg)
                        .font(.system(size: 15, weight: .semibold, design: .rounded))
                        .foregroundStyle(AppTheme.textPrimary)
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 14)
            .background(AppTheme.card)
            .clipShape(Capsule())
            .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 4)
            .padding(.bottom, 100)
        }
        .transition(.move(edge: .bottom).combined(with: .opacity))
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                withAnimation { saveResult = nil }
            }
        }
    }

    // MARK: - Save Logic

    private func saveToPhotos(_ detail: TutuResourceDetail) async {
        let docs = detail.documents.filter { !$0.previewDocuments.isEmpty }
        guard !docs.isEmpty else { return }

        isSaving = true
        saveProgress = 0

        let totalDocs = docs.count
        var successCount = 0

        for (index, doc) in docs.enumerated() {
            let urlString = TutuAPIService.shared.fullImageURL(doc.previewDocuments)
            guard let url = URL(string: urlString) else { continue }

            do {
                let (data, _) = try await URLSession.shared.data(from: url)
                guard let image = UIImage(data: data) else { continue }

                try await saveImageToPhotoLibrary(image)
                successCount += 1
            } catch {
                // continue to next doc
            }

            withAnimation {
                saveProgress = Double(index + 1) / Double(totalDocs)
            }
        }

        isSaving = false

        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
            if successCount > 0 {
                saveResult = .success
            } else {
                saveResult = .failure("保存失败，请检查相册权限")
            }
        }
    }

    private func saveImageToPhotoLibrary(_ image: UIImage) async throws {
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            PHPhotoLibrary.requestAuthorization(for: .addOnly) { status in
                guard status == .authorized || status == .limited else {
                    continuation.resume(throwing: NSError(domain: "Photos", code: -1))
                    return
                }
                PHPhotoLibrary.shared().performChanges {
                    PHAssetChangeRequest.creationRequestForAsset(from: image)
                } completionHandler: { success, error in
                    if success {
                        continuation.resume()
                    } else {
                        continuation.resume(throwing: error ?? NSError(domain: "Photos", code: -2))
                    }
                }
            }
        }
    }

    // MARK: - Content Views

    private var loadingAnimation: some View {
        VStack(spacing: 16) {
            ZStack {
                Circle()
                    .stroke(AppTheme.accentBlue.opacity(0.2), lineWidth: 4)
                    .frame(width: 50, height: 50)
                Circle()
                    .trim(from: 0, to: 0.3)
                    .stroke(AppTheme.accentBlue, style: StrokeStyle(lineWidth: 4, lineCap: .round))
                    .frame(width: 50, height: 50)
                    .rotationEffect(.degrees(isLoading ? 360 : 0))
                    .animation(.linear(duration: 1).repeatForever(autoreverses: false), value: isLoading)
            }
            Text("加载资料详情...")
                .font(.system(size: 14, weight: .medium, design: .rounded))
                .foregroundStyle(AppTheme.textSecondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func detailContent(_ detail: TutuResourceDetail) -> some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 20) {
                infoHeader(detail)
                    .opacity(appeared ? 1 : 0)
                    .offset(y: appeared ? 0 : 15)

                if let perm = permission {
                    permissionBadge(perm)
                        .opacity(appeared ? 1 : 0)
                        .offset(y: appeared ? 0 : 15)
                        .animation(
                            reduceMotion ? .none : .spring(response: 0.5, dampingFraction: 0.8).delay(0.1),
                            value: appeared
                        )
                }

                if !detail.documents.isEmpty {
                    documentsSection(detail.documents)
                        .opacity(appeared ? 1 : 0)
                        .offset(y: appeared ? 0 : 20)
                        .animation(
                            reduceMotion ? .none : .spring(response: 0.5, dampingFraction: 0.8).delay(0.2),
                            value: appeared
                        )
                }
            }
            .padding(.bottom, 100)
        }
    }

    private func infoHeader(_ detail: TutuResourceDetail) -> some View {
        HStack(spacing: 16) {
            ZStack {
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [AppTheme.accentBlue.opacity(0.15), AppTheme.accentPurple.opacity(0.08)],
                            startPoint: .topLeading, endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 72, height: 72)

                if !detail.image.isEmpty, let url = URL(string: TutuAPIService.shared.fullImageURL(detail.image)) {
                    AsyncImage(url: url) { image in
                        image.resizable().aspectRatio(contentMode: .fill)
                    } placeholder: {
                        Image(systemName: "doc.text.fill")
                            .font(.system(size: 28))
                            .foregroundStyle(AppTheme.accentBlue.opacity(0.5))
                    }
                    .frame(width: 72, height: 72)
                    .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                } else {
                    Image(systemName: "doc.text.fill")
                        .font(.system(size: 28))
                        .foregroundStyle(AppTheme.accentBlue.opacity(0.5))
                }
            }
            .shadow(color: AppTheme.accentBlue.opacity(0.15), radius: 8, x: 0, y: 4)

            VStack(alignment: .leading, spacing: 6) {
                Text(detail.title)
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .foregroundStyle(AppTheme.textPrimary)
                    .lineLimit(2)
                if !detail.categoryName.isEmpty {
                    Text(detail.categoryName)
                        .font(.system(size: 13, weight: .medium, design: .rounded))
                        .foregroundStyle(AppTheme.textSecondary)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(AppTheme.accentBlue.opacity(0.08))
                        .clipShape(Capsule())
                }
            }
        }
        .padding(.horizontal, AppTheme.paddingScreen)
        .padding(.top, 12)
    }

    private func permissionBadge(_ perm: TutuDownloadPermission) -> some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(
                        perm.isVIP
                            ? LinearGradient(colors: [AppTheme.accentYellow, Color(hex: "f97316")], startPoint: .top, endPoint: .bottom)
                            : LinearGradient(colors: [AppTheme.accentBlue, AppTheme.accentPurple], startPoint: .top, endPoint: .bottom)
                    )
                    .frame(width: 40, height: 40)
                Image(systemName: perm.isVIP ? "crown.fill" : "person.fill")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(.white)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(perm.isVIP ? "VIP 会员" : "普通用户")
                    .font(.system(size: 15, weight: .bold, design: .rounded))
                    .foregroundStyle(AppTheme.textPrimary)
                Text(perm.quantityLimitCondition ? "可以查看此资料" : "今日查看次数已用完")
                    .font(.system(size: 12, weight: .medium, design: .rounded))
                    .foregroundStyle(perm.quantityLimitCondition ? AppTheme.accentSage : AppTheme.accentTerracotta)
            }
            Spacer()

            if perm.quantityLimitCondition {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 24))
                    .foregroundStyle(AppTheme.accentSage)
            } else {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 24))
                    .foregroundStyle(AppTheme.accentTerracotta)
            }
        }
        .padding(16)
        .background(AppTheme.card)
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .shadow(color: .black.opacity(0.05), radius: 10, x: 0, y: 4)
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(.white.opacity(0.6), lineWidth: 1.5)
        )
        .padding(.horizontal, AppTheme.paddingScreen)
    }

    private func documentsSection(_ documents: [TutuDocument]) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text("资料预览")
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .foregroundStyle(AppTheme.textPrimary)
                Spacer()
                Text("\(documents.count) 份文件")
                    .font(.system(size: 12, weight: .medium, design: .rounded))
                    .foregroundStyle(AppTheme.textSecondary)
            }
            .padding(.horizontal, AppTheme.paddingScreen)

            ForEach(documents) { doc in
                VStack(alignment: .leading, spacing: 8) {
                    if !doc.fileName.isEmpty {
                        HStack(spacing: 6) {
                            Image(systemName: "doc.fill")
                                .font(.system(size: 12))
                                .foregroundStyle(AppTheme.accentBlue)
                            Text(doc.fileName)
                                .font(.system(size: 13, weight: .medium, design: .rounded))
                                .foregroundStyle(AppTheme.textSecondary)
                                .lineLimit(1)
                        }
                        .padding(.horizontal, AppTheme.paddingScreen)
                    }

                    if !doc.previewDocuments.isEmpty, let url = URL(string: TutuAPIService.shared.fullImageURL(doc.previewDocuments)) {
                        AsyncImage(url: url) { phase in
                            switch phase {
                            case .success(let image):
                                image
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                                    .shadow(color: .black.opacity(0.08), radius: 12, x: 0, y: 6)
                            case .failure:
                                previewErrorView
                            case .empty:
                                previewLoadingView
                            @unknown default:
                                previewErrorView
                            }
                        }
                        .padding(.horizontal, AppTheme.paddingScreen)
                    }
                }
            }
        }
    }

    private var previewLoadingView: some View {
        RoundedRectangle(cornerRadius: 16, style: .continuous)
            .fill(AppTheme.card)
            .frame(height: 200)
            .overlay(
                ProgressView()
                    .scaleEffect(1.2)
            )
            .shadow(color: .black.opacity(0.04), radius: 8, x: 0, y: 4)
    }

    private var previewErrorView: some View {
        RoundedRectangle(cornerRadius: 16, style: .continuous)
            .fill(AppTheme.card)
            .frame(height: 160)
            .overlay(
                VStack(spacing: 8) {
                    Image(systemName: "photo")
                        .font(.system(size: 28))
                        .foregroundStyle(AppTheme.textSecondary.opacity(0.4))
                    Text("预览不可用")
                        .font(.system(size: 13, weight: .medium, design: .rounded))
                        .foregroundStyle(AppTheme.textSecondary)
                }
            )
    }

    private func loadDetail() async {
        isLoading = true
        async let detailTask = TutuAPIService.shared.fetchResourceDetail(id: resource.id)
        async let permTask = TutuAPIService.shared.verifyDownload(resourceId: resource.id)
        detail = await detailTask
        permission = await permTask
        isLoading = false
        withAnimation(reduceMotion ? .none : .spring(response: 0.5, dampingFraction: 0.8)) {
            appeared = true
        }
    }
}
