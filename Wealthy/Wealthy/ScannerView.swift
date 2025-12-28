//
//  ScannerView.swift
//  家計簿
//
//  Created by Harrison on 12/26/25.
//

import SwiftUI
import VisionKit

struct ScannerView: UIViewControllerRepresentable {
    @Binding var scannedImage: UIImage?
    @Environment(\.dismiss) var dismiss
    
    func makeUIViewController(context: Context) -> VNDocumentCameraViewController {
        // iPhone標準の「書類スキャナ」を起動
        let scanner = VNDocumentCameraViewController()
        scanner.delegate = context.coordinator
        return scanner
    }
    
    func updateUIViewController(_ uiViewController: VNDocumentCameraViewController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(parent: self)
    }
    
    class Coordinator: NSObject, VNDocumentCameraViewControllerDelegate {
        let parent: ScannerView
        
        init(parent: ScannerView) {
            self.parent = parent
        }
        
        // スキャン完了時の処理
        func documentCameraViewController(_ controller: VNDocumentCameraViewController, didFinishWith scan: VNDocumentCameraScan) {
            // 1ページ目の画像を取得
            if scan.pageCount > 0 {
                let image = scan.imageOfPage(at: 0)
                parent.scannedImage = image
            }
            parent.dismiss()
        }
        
        // キャンセル時
        func documentCameraViewControllerDidCancel(_ controller: VNDocumentCameraViewController) {
            parent.dismiss()
        }
        
        // エラー時
        func documentCameraViewController(_ controller: VNDocumentCameraViewController, didFailWithError error: Error) {
            print("スキャンエラー: \(error)")
            parent.dismiss()
        }
    }
}
