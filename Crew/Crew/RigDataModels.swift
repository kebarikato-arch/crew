// RigDataModels.swift の全文

import Foundation
import SwiftUI
import SwiftData

// MARK: - 4. CheckListItem モデル
@Model
final class CheckListItem: Identifiable {
    var name: String
    var isCompleted: Bool
    var category: Category
    
    enum Category: String, CaseIterable, Codable {
        case beforeSail = "セーリング前"
        case afterSail = "セーリング後"
    }
    
    init(name: String, isCompleted: Bool, category: Category) {
        self.name = name
        self.isCompleted = isCompleted
        self.category = category
    }
}

// MARK: - 3. RigItem モデル (リグの個別設定)
@Model
final class RigItem: Identifiable {
    let name: String
    var value: String
    let unit: String
    
    var status: Status
    
    // RigItemのメンバー型としてStatusを定義
    enum Status: String, CaseIterable, Codable {
        case normal = "正常"
        case maintenance = "確認推奨"
        case expired = "要交換/調整"
    }
    
    init(name: String, value: String, unit: String, status: Status) {
        self.name = name
        self.value = value
        self.unit = unit
        self.status = status
    }
    
    // 計算プロパティはそのまま
    var progressRatio: Double {
        switch status {
        case .normal: return 1.0
        case .maintenance: return 0.5
        case .expired: return 0.2
        }
    }
    
    var statusColor: Color {
        switch status {
        case .normal: return .green
        case .maintenance: return .orange
        case .expired: return .red
        }
    }
}

// MARK: - 2. RigDataSet モデル (ログセット)
@Model
final class RigDataSet: Identifiable, Comparable {
    var date: Date
    var memo: String
    
    @Relationship(deleteRule: .cascade)
    var elements: [RigItem]

    init(date: Date, memo: String, elements: [RigItem]) {
        self.date = date
        self.memo = memo
        self.elements = elements
    }
    
    // Comparable プロトコルの実装
    static func < (lhs: RigDataSet, rhs: RigDataSet) -> Bool {
        lhs.date > rhs.date
    }
    
    var latestModifiedDate: Date {
        return date
    }
}

// MARK: - 1. Boat モデル (メインデータ)
@Model
final class Boat: Identifiable {
    // ✅ 複数ボート管理のためにユニークIDを追加
    @Attribute(.unique) var id: UUID
    var name: String
    
    @Relationship(deleteRule: .cascade)
    var dataSets: [RigDataSet]
    
    @Relationship(deleteRule: .cascade)
    var checklist: [CheckListItem]
    
    // ✅ イニシャライザを更新
    init(id: UUID = UUID(), name: String, dataSets: [RigDataSet], checklist: [CheckListItem]) {
        self.id = id
        self.name = name
        self.dataSets = dataSets
        self.checklist = checklist
    }
    
    var latestDataSet: RigDataSet? {
        return dataSets.sorted().first
    }
    
    var rigItemTemplate: [RigItem] {
        return [
            RigItem(name: "フォアステイ", value: "0", unit: "%", status: .normal),
            RigItem(name: "D1シュラウド", value: "0", unit: "%", status: .normal),
            RigItem(name: "V2シュラウド", value: "0", unit: "%", status: .normal),
            RigItem(name: "スプレッダー角度", value: "0", unit: "°", status: .normal),
            RigItem(name: "バックステイ", value: "0", unit: "lbs", status: .normal)
        ]
    }
    
    // ✅ ダミーデータ生成ロジックを更新
    static var dummy: Boat {
        let items1: [RigItem] = [
            RigItem(name: "フォアステイ", value: "30", unit: "%", status: .normal),
            RigItem(name: "D1シュラウド", value: "28", unit: "%", status: .normal),
            RigItem(name: "V2シュラウド", value: "25", unit: "%", status: .normal),
            RigItem(name: "スプレッダー角度", value: "15", unit: "°", status: .expired)
        ]
        
        let initialChecklist: [CheckListItem] = [
            CheckListItem(name: "マストフットの状態確認", isCompleted: false, category: .beforeSail),
            CheckListItem(name: "シャックルの緩み確認", isCompleted: true, category: .beforeSail),
            CheckListItem(name: "ログブックへの記録", isCompleted: true, category: .afterSail)
        ]
        
        let dataSet1 = RigDataSet(date: Calendar.current.date(byAdding: .day, value: -7, to: Date())!, memo: "強風用セッティング", elements: items1)
        
        return Boat(name: "あしけり100", dataSets: [dataSet1], checklist: initialChecklist)
    }
}
