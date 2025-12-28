//
//  NotificationManager.swift
//  家計簿
//
//  Created by Harrison on 12/26/25.
//

import UserNotifications
import UIKit

class NotificationManager {
    static let shared = NotificationManager()
    
    // 1. 許可を求める
    func requestPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, _ in
            print("Permission granted: \(granted)")
        }
    }
    
    // 2. スケジュール登録（定期アイテムを受け取って通知セット）
    func scheduleNotifications(for items: [RecurringItem]) {
        let center = UNUserNotificationCenter.current()
        center.removeAllPendingNotificationRequests() // 古いのは消す
        
        for item in items {
            let content = UNMutableNotificationContent()
            content.title = item.isIncome ? "💰 入金予定日" : "💸 支払予定日"
            content.body = "\(item.title) (¥\(item.amount)) の予定日です。"
            content.sound = .default
            
            // 毎月 指定日 の 朝9:00 に通知
            var dateComponents = DateComponents()
            dateComponents.day = item.dayOfMonth
            dateComponents.hour = 9
            dateComponents.minute = 0
            
            let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
            let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: trigger)
            
            center.add(request)
        }
    }
}
