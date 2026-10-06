//
//  ChatMessageModel.swift
//  Wealthy
//
//  Created by Harrison on 12/28/25.
//

// Foundationの機能を、このファイルから使えるように読み込みます。
import Foundation
// SwiftDataの機能を、このファイルから使えるように読み込みます。
import SwiftData

// このクラスをSwiftDataで保存できるデータとして登録します。
@Model
// 会話履歴を保存する型を定義します。
class ChatMessageModel {
    // 各データを識別するIDを保持するプロパティを定義します。
    var id: UUID
    // 保存用の発言者名を保持するプロパティを定義します。
    var roleRaw: String // "user", "assistant", "system"
    // 通知に表示する題名と本文を入れる値を作ります。
    var content: String
    // 作成または保存した日時を保持するプロパティを定義します。
    var timestamp: Date
    
    // 渡された引数で新しい値を初期化する入口を定義します。
    init(role: String, content: String) {
        // 新しい会話を区別するためのIDを発行します。
        self.id = UUID()
        // roleRawに、右辺で指定した値を設定します。
        self.roleRaw = role
        // contentに、右辺で指定した値を設定します。
        self.content = content
        // この会話を作った現在の日時を保存します。
        self.timestamp = Date()
    // ここまでの処理またはデータ定義を閉じます。
    }
    
    // 保存済みの文字列をAI用の発言者に変換する入口を定義します。
    var role: LocalLLMService.ChatMessage.MessageRole {
        // 値に応じて実行する処理を選びます。
        switch roleRaw {
        // "user"に一致した場合の変換先または処理を選びます。
        case "user": return .user
        // "assistant"に一致した場合の変換先または処理を選びます。
        case "assistant": return .assistant
        // "system"に一致した場合の変換先または処理を選びます。
        case "system": return .system
        // どの個別条件にも当てはまらない場合の値を返します。
        default: return .system
        // ここまでの処理またはデータ定義を閉じます。
        }
    // ここまでの処理またはデータ定義を閉じます。
    }
// ここまでの処理またはデータ定義を閉じます。
}
