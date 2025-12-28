//
//  EditExpenseView.swift
//  家計簿
//
//  Created by Harrison on 12/26/25.
//

import SwiftUI
import SwiftData
import UIKit

struct EditExpenseView: View {
    @Environment(\.dismiss) var dismiss
    @Environment(\.modelContext) var modelContext
    @EnvironmentObject var lm: LanguageManager
    @Bindable var expense: Expense
    
    // ■ 修正1: カテゴリ一覧と財布一覧を取得するコードを追加
    @Query var assets: [Asset]
    @Query var categories: [Category]
    
    // 画像表示用
    @State private var showingFullScreenImage = false
    @State private var previewImage: UIImage? = nil
    
    // 残高調整用
    @State private var initialAmount: Int = 0
    @State private var initialAssetName: String? = nil
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 25) {
                        
                        // 1. 画像エリア
                        if let filename = expense.imageFilename {
                            imageButton(filename: filename)
                        }
                        
                        // 2. 入力フォーム群
                        VStack(spacing: 20) {
                            
                            // 店名
                            InputGroup(label: lm.t(.shopName), icon: "building.2.fill") {
                                TextField(lm.t(.shopName), text: $expense.title)
                                    .foregroundStyle(.white)
                            }
                            
                            // 金額
                            InputGroup(label: lm.t(.amount), icon: "yen.circle.fill") {
                                TextField("0", value: $expense.amount, format: .number)
                                    .keyboardType(.numberPad)
                                    .foregroundStyle(.white)
                                    .font(.title2.bold())
                            }
                            
                            // ■ カテゴリ選択（エラー対策のため構造を整理）
                            InputGroup(label: lm.t(.category), icon: "tag.fill") {
                                Menu {
                                    // 選択肢一覧
                                    ForEach(categories) { cat in
                                        Button {
                                            expense.categoryName = cat.name
                                        } label: {
                                            HStack {
                                                if expense.categoryName == cat.name {
                                                    Image(systemName: "checkmark")
                                                }
                                                // カテゴリ名を翻訳
                                                Text(lm.translateCategory(name: cat.name))
                                                Image(systemName: cat.icon)
                                            }
                                        }
                                    }
                                } label: {
                                    // 選択中の表示
                                    HStack {
                                        if let cat = categories.first(where: { $0.name == expense.categoryName }) {
                                            // カテゴリ名を翻訳
                                            Text(lm.translateCategory(name: cat.name)).foregroundStyle(.white).bold()
                                            Spacer()
                                            // 修正: AssetViewのエラー回避のため、ここでは色は白かグレーにする
                                            Image(systemName: cat.icon).foregroundStyle(.gray)
                                        } else {
                                            Text(expense.categoryName ?? lm.t(.unclassified)).foregroundStyle(.white).bold()
                                            Spacer()
                                        }
                                        Image(systemName: "chevron.up.chevron.down").foregroundStyle(.gray)
                                    }
                                }
                            }
                            
                            // 財布選択
                            InputGroup(label: lm.t(.wallet), icon: "creditcard.fill") {
                                Menu {
                                    ForEach(assets) { asset in
                                        Button {
                                            expense.assetName = asset.name
                                        } label: {
                                            HStack {
                                                if expense.assetName == asset.name {
                                                    Image(systemName: "checkmark")
                                                }
                                                Text(asset.name)
                                            }
                                        }
                                    }
                                } label: {
                                    HStack {
                                        Text(expense.assetName ?? lm.t(.unselected))
                                            .foregroundStyle(.white)
                                            .bold()
                                        Spacer()
                                        Image(systemName: "chevron.up.chevron.down")
                                            .foregroundStyle(.gray)
                                    }
                                }
                            }
                            
                            // 日付
                            InputGroup(label: lm.t(.date), icon: "calendar") {
                                DatePicker("", selection: $expense.date, displayedComponents: .date)
                                    .labelsHidden()
                                    .colorInvert()
                            }
                        }
                        .padding(.horizontal)
                    }
                    .padding(.vertical)
                }
            }
            .navigationTitle(lm.t(.editTitle))
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(lm.t(.done)) {
                        updateAssetBalance()
                        dismiss()
                    }
                    .foregroundStyle(.orange)
                    .bold()
                }
            }
            .fullScreenCover(isPresented: $showingFullScreenImage) {
                if let filename = expense.imageFilename {
                    AsyncFullScreenImageView(filename: filename, isPresented: $showingFullScreenImage)
                }
            }
            .onAppear {
                initialAmount = expense.amount
                initialAssetName = expense.assetName
            }
        }
    }
    
    // 画像ボタン部分を切り出してコードを軽くする
    @ViewBuilder
    private func imageButton(filename: String) -> some View {
        Button {
            self.showingFullScreenImage = true
        } label: {
            ZStack {
                RoundedRectangle(cornerRadius: 15)
                    .fill(Color(white: 0.1))
                    .stroke(Color.orange, lineWidth: 1)
                
                VStack {
                    if let img = previewImage {
                        Image(uiImage: img)
                            .resizable()
                            .scaledToFit()
                            .frame(maxHeight: 200)
                            .cornerRadius(10)
                    } else {
                        VStack(spacing: 10) {
                            Image(systemName: "photo")
                                .font(.largeTitle)
                            Text(lm.t(.loading))
                                .font(.caption)
                        }
                        .frame(height: 150)
                        .foregroundStyle(.gray)
                    }
                    
                    HStack {
                        Image(systemName: "magnifyingglass")
                        Text(lm.t(.tapToExpand))
                    }
                    .font(.caption)
                    .foregroundStyle(.orange)
                    .padding(.bottom, 8)
                }
                .padding(8)
            }
        }
        .padding(.horizontal)
        .onAppear {
            if previewImage == nil { loadPreviewImage(filename: filename) }
        }
    }
    
    private func updateAssetBalance() {
        if let oldName = initialAssetName,
           let oldAsset = assets.first(where: { $0.name == oldName }) {
            oldAsset.balance += initialAmount
        }
        if let newName = expense.assetName,
           let newAsset = assets.first(where: { $0.name == newName }) {
            newAsset.balance -= expense.amount
        }
    }
    
    private func loadPreviewImage(filename: String) {
        Task.detached(priority: .background) {
            let url = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0].appendingPathComponent(filename)
            if let image = UIImage(contentsOfFile: url.path) {
                await MainActor.run { self.previewImage = image }
            }
        }
    }
}

// MARK: - Subviews

struct AsyncFullScreenImageView: View {
    let filename: String
    @Binding var isPresented: Bool
    @State private var image: UIImage? = nil
    @State private var isLoading = true
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            if let img = image {
                ZoomableImageView(image: img).ignoresSafeArea()
            } else if isLoading {
                ProgressView().scaleEffect(2.0).tint(.orange)
            } else {
                Text("Error").foregroundStyle(.red)
            }
            VStack {
                HStack {
                    Spacer()
                    Button { isPresented = false } label: {
                        Image(systemName: "xmark.circle.fill")
                            .symbolRenderingMode(.palette).foregroundStyle(.black, .orange)
                            .font(.system(size: 40)).padding()
                    }
                }
                Spacer()
            }
        }
        .onAppear {
            Task.detached {
                let url = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0].appendingPathComponent(filename)
                if let loaded = UIImage(contentsOfFile: url.path) {
                    await MainActor.run { self.image = loaded; self.isLoading = false }
                }
            }
        }
    }
}

struct ZoomableImageView: UIViewRepresentable {
    var image: UIImage
    func makeUIView(context: Context) -> UIScrollView {
        let scrollView = UIScrollView()
        scrollView.delegate = context.coordinator
        scrollView.maximumZoomScale = 5.0
        scrollView.minimumZoomScale = 1.0
        scrollView.backgroundColor = .black
        let imageView = UIImageView(image: image)
        imageView.contentMode = .scaleAspectFit
        imageView.tag = 999
        imageView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(imageView)
        NSLayoutConstraint.activate([
            imageView.widthAnchor.constraint(equalTo: scrollView.widthAnchor),
            imageView.heightAnchor.constraint(equalTo: scrollView.heightAnchor),
            imageView.centerXAnchor.constraint(equalTo: scrollView.centerXAnchor),
            imageView.centerYAnchor.constraint(equalTo: scrollView.centerYAnchor)
        ])
        let doubleTap = UITapGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.handleDoubleTap))
        doubleTap.numberOfTapsRequired = 2
        scrollView.addGestureRecognizer(doubleTap)
        return scrollView
    }
    func updateUIView(_ uiView: UIScrollView, context: Context) {}
    func makeCoordinator() -> Coordinator { Coordinator() }
    class Coordinator: NSObject, UIScrollViewDelegate {
        func viewForZooming(in scrollView: UIScrollView) -> UIView? { scrollView.viewWithTag(999) }
        func scrollViewDidZoom(_ scrollView: UIScrollView) {
            guard let imageView = scrollView.viewWithTag(999) else { return }
            let offsetX = max((scrollView.bounds.width - scrollView.contentSize.width) * 0.5, 0)
            let offsetY = max((scrollView.bounds.height - scrollView.contentSize.height) * 0.5, 0)
            imageView.center = CGPoint(x: scrollView.contentSize.width * 0.5 + offsetX, y: scrollView.contentSize.height * 0.5 + offsetY)
        }
        @objc func handleDoubleTap(_ gesture: UITapGestureRecognizer) {
            guard let scrollView = gesture.view as? UIScrollView else { return }
            if scrollView.zoomScale > 1 { scrollView.setZoomScale(1, animated: true) }
            else {
                let tapPoint = gesture.location(in: scrollView.viewWithTag(999))
                let newZoomScale: CGFloat = 3.0
                let size = scrollView.bounds.size
                let w = size.width / newZoomScale
                let h = size.height / newZoomScale
                let rect = CGRect(x: tapPoint.x - w/2, y: tapPoint.y - h/2, width: w, height: h)
                scrollView.zoom(to: rect, animated: true)
            }
        }
    }
}

struct InputGroup<Content: View>: View {
    let label: String
    let icon: String
    let content: Content
    init(label: String, icon: String, @ViewBuilder content: () -> Content) {
        self.label = label; self.icon = icon; self.content = content()
    }
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Label(label, systemImage: icon).font(.caption2).bold().foregroundStyle(.gray).tracking(1)
            HStack { content }
                .padding()
                .background(Color(white: 0.12))
                .cornerRadius(12)
                .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.white.opacity(0.1), lineWidth: 0.5))
        }
    }
}
