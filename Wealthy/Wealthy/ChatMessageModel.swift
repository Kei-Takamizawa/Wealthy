//
//  ChatMessageModel.swift
//  Wealthy
//
//  Created by Harrison on 12/28/25.
//

import Foundation
import SwiftData

@Model
class ChatMessageModel {
    var id: UUID
    var roleRaw: String // "user", "assistant", "system"
    var content: String
    var timestamp: Date
    
    init(role: String, content: String) {
        self.id = UUID()
        self.roleRaw = role
        self.content = content
        self.timestamp = Date()
    }
    
    var role: LocalLLMService.ChatMessage.MessageRole {
        switch roleRaw {
        case "user": return .user
        case "assistant": return .assistant
        case "system": return .system
        default: return .system
        }
    }
}
