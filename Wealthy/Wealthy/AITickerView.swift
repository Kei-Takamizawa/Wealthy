//
//  AITickerView.swift
//  Wealthy
//
//  Created by Harrison on 12/28/25.
//

// `SwiftUI` の機能をこのファイルで使えるように読み込みます。
import SwiftUI

// `AITickerView` という構造体を定義し、関連する値や処理をまとめます。
struct AITickerView: View {
    // `text`を変更できない値として作り、右辺の結果を保存します。
    let text: String
    // `onTapSparkle`を変更できない値として作り、右辺の結果を保存します。
    let onTapSparkle: () -> Void
    // `onFinish`を変更できない値として作り、右辺の結果を保存します。
    let onFinish: () -> Void // Callback when animation ends
    
    // 横方向の表示位置を画面の状態として保持し、変更時に表示を更新します。
    @State private var offsetX: CGFloat = 0
    // `contentWidth`を画面の状態として保持し、変更時に表示を更新します。
    @State private var contentWidth: CGFloat = 0
    // `containerWidth`を画面の状態として保持し、変更時に表示を更新します。
    @State private var containerWidth: CGFloat = 0
    
    // 画面に表示する部品の並びを返す `body` を定義します。
    var body: some View {
        // 利用できる画面サイズを `geometry` で受け取り、表示位置の計算に使います。
        GeometryReader { geometry in
            // 要素を手前と奥に重ねます。
            ZStack(alignment: .leading) {
                // Background
                // 角の丸い長方形を描きます。
                RoundedRectangle(cornerRadius: 12)
                    // 図形の内側を暗い灰色で塗ります。
                    .fill(Color(white: 0.12))
                
                // Scrolling Text
                // 内容をスクロールできる領域を作ります。
                ScrollView(.horizontal, showsIndicators: false) {
                    // 文字列を画面に表示します。
                    Text(text)
                        // 文字の大きさや書体を設定します。
                        .font(.subheadline)
                        // 文字の太さを設定します。
                        .fontWeight(.medium)
                        // 文字やアイコンの色を設定します。
                        .foregroundStyle(.white)
                        // 表示の周囲に余白を設けます。
                        .padding(.horizontal, 16)
                        // 横幅は内容に合わせ、高さは表示に合わせて決めます。
                        .fixedSize(horizontal: true, vertical: false)
                        // 背景の色や形を設定します。
                        .background(GeometryReader { textGeo -> Color in
                            // `width`を変更できない値として作り、右辺の結果を保存します。
                            let width = textGeo.size.width
                            // 測定した文字列の幅が前回と1ポイントより大きく違う場合だけ、幅を更新します。
                            if abs(self.contentWidth - width) > 1 {
                                // 画面の更新をメインスレッドで実行します。
                                DispatchQueue.main.async {
                                    // `self.contentWidth`へ `width` の結果を代入します。
                                    self.contentWidth = width
                                    // `resetAnimation` を呼び出し、括弧内の値を使って処理します。
                                    resetAnimation()
                                // DispatchQueue.main.asyncの範囲をここで閉じます。
                                }
                            // 条件分岐の範囲をここで閉じます。
                            }
                            // `Color.clear` の結果を呼び出し元へ返します。
                            return Color.clear
                        // 直前の処理の範囲をここで閉じます。
                        })
                        // 表示位置をずらします。
                        .offset(x: offsetX)
                // 開いていた画面部品や処理の範囲を閉じます。
                }
                // 条件に応じて操作を無効にします。
                .disabled(true) 
                // 指定した形だけを表示するためのマスクを設定します。
                .mask(
                    // 要素を左から右へ並べます。
                    HStack(spacing: 0) {
                        // 色が段階的に変わる背景を作ります。
                        LinearGradient(gradient: Gradient(colors: [.clear, .black]), startPoint: .leading, endPoint: .trailing)
                            // 表示領域の幅や高さを設定します。
                            .frame(width: 20)
                        // 長方形を描きます。
                        Rectangle().fill(.black)
                        // 色が段階的に変わる背景を作ります。
                        LinearGradient(gradient: Gradient(colors: [.black, .clear]), startPoint: .leading, endPoint: .trailing)
                            // 表示領域の幅や高さを設定します。
                            .frame(width: 20)
                    // 横並びの表示の範囲をここで閉じます。
                    }
                // 重ねた表示の範囲をここで閉じます。
                )
                // この画面が現れたときの処理を登録します。
                .onAppear {
                    // `self.containerWidth`へ `geometry.size.width` の結果を代入します。
                    self.containerWidth = geometry.size.width
                    // `startAnimation` を呼び出し、括弧内の値を使って処理します。
                    startAnimation()
                // 画面表示時の処理の範囲をここで閉じます。
                }
                
                // Icon Overlay (Interactive)
                // 要素を左から右へ並べます。
                HStack {
                    // タップで処理を実行するボタンを配置します。
                    Button(action: {
                        // `onTapSparkle` を呼び出し、括弧内の値を使って処理します。
                        onTapSparkle()
                    // ボタンの処理の範囲をここで閉じます。
                    }) {
                        // 画像またはシステムアイコンを表示します。
                        Image(systemName: "sparkles")
                            // 文字やアイコンの色を設定します。
                            .foregroundStyle(.yellow)
                            // 表示の周囲に余白を設けます。
                            .padding(.leading, 12)
                            // 表示の周囲に余白を設けます。
                            .padding(.vertical, 8) // Hit area
                    // })の範囲をここで閉じます。
                    }
                    // 空き領域を使って要素間の距離を広げます。
                    Spacer()
                // 横並びの表示の範囲をここで閉じます。
                }
            // 重ねた表示の範囲をここで閉じます。
            }
        // 直前の処理の範囲をここで閉じます。
        }
        // 表示領域の幅や高さを設定します。
        .frame(height: 44)
    // 画面構成の範囲をここで閉じます。
    }
    
    // `resetAnimation` という関数を定義し、括弧内の入力を使って処理します。
    private func resetAnimation() {
        // `transaction`を表す変更可能な値または計算結果を定義します。
        var transaction = Transaction(animation: nil)
        // `transaction.disablesAnimations`をオンにし、対応する状態を更新します。
        transaction.disablesAnimations = true
        // この中で変える画面状態にアニメーション設定を適用します。
        withTransaction(transaction) {
             // 横方向の表示位置へ `containerWidth` の結果を代入します。
             offsetX = containerWidth
        // withTransaction(transaction)の範囲をここで閉じます。
        }
        
        // 指定した時間が過ぎたら、画面更新の処理を実行します。
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            // `startAnimation` を呼び出し、括弧内の値を使って処理します。
            startAnimation()
        // 開いていた画面部品や処理の範囲を閉じます。
        }
    // 関数の範囲をここで閉じます。
    }
    
    // `startAnimation` という関数を定義し、括弧内の入力を使って処理します。
    private func startAnimation() {
        // 文字と表示領域の幅が両方とも正の値か確認し、測定前なら動きを開始しません。
        guard contentWidth > 0, containerWidth > 0 else { return }
        
        // Start position
        // `transaction`を表す変更可能な値または計算結果を定義します。
        var transaction = Transaction(animation: nil)
        // `transaction.disablesAnimations`をオンにし、対応する状態を更新します。
        transaction.disablesAnimations = true
        // この中で変える画面状態にアニメーション設定を適用します。
        withTransaction(transaction) {
            // 横方向の表示位置へ `containerWidth` の結果を代入します。
            offsetX = containerWidth
        // withTransaction(transaction)の範囲をここで閉じます。
        }
        
        // `distance`を変更できない値として作り、右辺の結果を保存します。
        let distance = containerWidth + contentWidth
        // `duration`を変更できない値として作り、右辺の結果を保存します。
        let duration = Double(distance) / 50.0 // Constant speed
        
        // One-shot animation
        // この中で変える画面状態にアニメーション設定を適用します。
        withAnimation(.linear(duration: duration)) {
            // 横方向の表示位置へ `-contentWidth` の結果を代入します。
            offsetX = -contentWidth
        // 開いていた画面部品や処理の範囲を閉じます。
        }
        
        // Callback after completion
        // 指定した時間が過ぎたら、画面更新の処理を実行します。
        DispatchQueue.main.asyncAfter(deadline: .now() + duration) {
            // `onFinish` を呼び出し、括弧内の値を使って処理します。
            onFinish()
        // 開いていた画面部品や処理の範囲を閉じます。
        }
    // 関数の範囲をここで閉じます。
    }
// 構造体の範囲をここで閉じます。
}

// Xcodeのプレビューで確認するための見本画面を定義します。
#Preview {
    // AIの助言を流れる表示として配置します。
    AITickerView(text: "Today's Advice: You spent a bit more on Food than usual. Try cooking at home tomorrow! 🍳", onTapSparkle: {}, onFinish: {})
        // 表示領域の幅や高さを設定します。
        .frame(width: 350)
        // 表示の周囲に余白を設けます。
        .padding()
        // 背景の色や形を設定します。
        .background(.black)
// #Previewの範囲をここで閉じます。
}
