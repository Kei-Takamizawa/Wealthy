//
//  ScannerView.swift
//  家計簿
//
//  Created by Harrison on 12/26/25.
//

// 画面部品やレイアウトを使うためのフレームワークを読み込みます。
import SwiftUI
// 書類スキャン画面を使うための仕組みを読み込みます。
import VisionKit

// ScannerViewという画面または補助部品の定義を始めます。
struct ScannerView: UIViewControllerRepresentable {
    // 読み取った画像を親画面へ渡すため、双方向の値として受け取ります。
    @Binding var scannedImage: UIImage?
    // この画面を閉じるための操作をSwiftUI環境から受け取ります。
    @Environment(\.dismiss) var dismiss
    
    // makeUIViewControllerを実行する処理を定義します。
    func makeUIViewController(context: Context) -> VNDocumentCameraViewController {
        // iPhone標準の「書類スキャナ」を起動
        // scannerという定数へ「VNDocumentCameraViewController()」の計算結果を保存します。
        let scanner = VNDocumentCameraViewController()
        // scanner.delegateへ右辺の値を代入し、状態または集計結果を更新します。
        scanner.delegate = context.coordinator
        // 計算結果を呼び出し元へ返し、この関数の処理を終えます。
        return scanner
    // ここで「makeUIViewController関数」の範囲を閉じます。
    }
    
    // updateUIViewControllerを実行する処理を定義します。
    func updateUIViewController(_ uiViewController: VNDocumentCameraViewController, context: Context) {}
    
    // UIKitとのイベント仲介役を作る処理を定義します。
    func makeCoordinator() -> Coordinator {
        // カメラ画面とSwiftUI側の状態をつなぐ調整役を作ります。
        Coordinator(parent: self)
    // ここで「makeCoordinator関数」の範囲を閉じます。
    }
    
    // Coordinatorというクラスの定義を始めます。
    class Coordinator: NSObject, VNDocumentCameraViewControllerDelegate {
        // parentに後から変更しない値を保持します。
        let parent: ScannerView
        
        // この型を作るときに実行する初期化処理を定義します。
        init(parent: ScannerView) {
            // このインスタンスが持つプロパティへ値を設定します。
            self.parent = parent
        // ここで「初期化処理」の範囲を閉じます。
        }
        
        // スキャン完了時の処理
        // documentCameraViewControllerを実行する処理を定義します。
        func documentCameraViewController(_ controller: VNDocumentCameraViewController, didFinishWith scan: VNDocumentCameraScan) {
            // 1ページ目の画像を取得
            // 「scan.pageCount > 0」の条件が真の場合にだけ、次の処理を実行します。
            if scan.pageCount > 0 {
                // imageという定数へ「scan.imageOfPage(at: 0)」の計算結果を保存します。
                let image = scan.imageOfPage(at: 0)
                // parent.scannedImageへ右辺の値を代入し、状態または集計結果を更新します。
                parent.scannedImage = image
            // ここで「条件分岐」の範囲を閉じます。
            }
            // 撮影画面を閉じて元の画面へ戻ります。
            parent.dismiss()
        // ここで「documentCameraViewController関数」の範囲を閉じます。
        }
        
        // キャンセル時
        // documentCameraViewControllerDidCancelを実行する処理を定義します。
        func documentCameraViewControllerDidCancel(_ controller: VNDocumentCameraViewController) {
            // 撮影画面を閉じて元の画面へ戻ります。
            parent.dismiss()
        // ここで「documentCameraViewControllerDidCancel関数」の範囲を閉じます。
        }
        
        // エラー時
        // documentCameraViewControllerを実行する処理を定義します。
        func documentCameraViewController(_ controller: VNDocumentCameraViewController, didFailWithError error: Error) {
            // エラー内容をデバッグ用ログへ出力します。
            print("スキャンエラー: \(error)")
            // 撮影画面を閉じて元の画面へ戻ります。
            parent.dismiss()
        // ここで「documentCameraViewController関数」の範囲を閉じます。
        }
    // ここで「Coordinatorクラス」の範囲を閉じます。
    }
// ここで「ScannerView型」の範囲を閉じます。
}
