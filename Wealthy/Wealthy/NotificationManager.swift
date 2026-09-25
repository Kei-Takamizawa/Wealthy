//
//  NotificationManager.swift
//  家計簿
//
//  Created by Harrison on 12/26/25.
//

// UserNotificationsの機能を、このファイルから使えるように読み込みます。
import UserNotifications
// UIKitの機能を、このファイルから使えるように読み込みます。
import UIKit

// 毎月の予定通知を登録する型を定義します。
class NotificationManager {
    // アプリ内で共有する、この管理クラスのインスタンスを一つ作ります。
    static let shared = NotificationManager()
    
    // 1. 許可を求める
    // 通知を表示するための許可をOSに求める入口を定義します。
    func requestPermission() {
        // 直前に定義した処理へ、この設定または引数を追加します。
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, _ in
            // 処理の状況を開発用ログへ出力します。
            print("Permission granted: \(granted)")
        // ここまでの処理またはデータ定義を閉じます。
        }
    // ここまでの処理またはデータ定義を閉じます。
    }
    
    // 2. スケジュール登録（定期アイテムを受け取って通知セット）
    // 定期収支に応じた毎月の通知を登録する入口を定義します。
    func scheduleNotifications(for items: [RecurringItem]) {
        // OSの通知センターを取得します。
        let center = UNUserNotificationCenter.current()
        // 直前に定義した処理へ、この設定または引数を追加します。
        center.removeAllPendingNotificationRequests() // 古いのは消す
        
        // 配列の各要素を順番に取り出して処理します。
        for item in items {
            // 通知に表示する題名と本文を入れる値を作ります。
            let content = UNMutableNotificationContent()
            // content.titleに、右辺の計算結果または取得結果を設定します。
            content.title = item.isIncome ? "💰 入金予定日" : "💸 支払予定日"
            // content.bodyに、右辺の計算結果または取得結果を設定します。
            content.body = "\(item.title) (¥\(item.amount)) の予定日です。"
            // content.soundに、右辺の計算結果または取得結果を設定します。
            content.sound = .default
            
            // 毎月 指定日 の 朝9:00 に通知
            // 毎月の通知時刻を組み立てる値を作ります。
            var dateComponents = DateComponents()
            // dateComponents.dayに、右辺の計算結果または取得結果を設定します。
            dateComponents.day = item.dayOfMonth
            // dateComponents.hourに、右辺の計算結果または取得結果を設定します。
            dateComponents.hour = 9
            // dateComponents.minuteに、右辺の計算結果または取得結果を設定します。
            dateComponents.minute = 0
            
            // 指定した日付に毎月通知する条件を作ります。
            let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
            // 文字認識または通知登録の要求を作ります。
            let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: trigger)
            
            // 組み立てた通知をOSの通知センターへ登録します。
            center.add(request)
        // ここまでの処理またはデータ定義を閉じます。
        }
    // ここまでの処理またはデータ定義を閉じます。
    }
// ここまでの処理またはデータ定義を閉じます。
}
