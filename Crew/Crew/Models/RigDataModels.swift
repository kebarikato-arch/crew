import Foundation
import SwiftUI
import SwiftData

// MARK: - Boat
@Model
final class Boat {
    @Attribute(.unique) var id: UUID
    var name: String
    
    // @Relationshipを持つプロパティは、SwiftDataが管理するため、手動で初期化する必要はありません。
    @Relationship(deleteRule: .cascade, inverse: \RigDataSet.boat)
    var rigDataSets: [RigDataSet] = []
    
    @Relationship(deleteRule: .cascade, inverse: \CheckListItem.boat)
    var checklist: [CheckListItem] = []
    
    @Relationship(deleteRule: .cascade, inverse: \RigItemTemplate.boat)
    var rigItemTemplates: [RigItemTemplate] = []
    
    // 【最重要修正点】
    // このinit(name:)メソッドが、アプリから新しいボートを作成する際に呼ばれます。
    // @Relationshipを持つ配列の初期化を削除し、nameとidの設定のみを行います。
    init(name: String) {
        self.id = UUID()
        self.name = name
    }
}

// (以下、他のモデルの定義は変更ありません)
// MARK: - RigDataSet
@Model
final class RigDataSet {
    @Attribute(.unique) var id: UUID
    var date: Date
    var memo: String
    @Relationship(deleteRule: .cascade, inverse: \RigItem.dataSet)
    var rigItems: [RigItem] = []
    var boat: Boat?
    
    init(date: Date, memo: String = "", boat: Boat?) {
        self.id = UUID()
        self.date = date
        self.memo = memo
        self.boat = boat
    }
}

// MARK: - RigItem
@Model
final class RigItem {
    @Attribute(.unique) var id: UUID
    var name: String
    var value: Double
    var stringValue: String?
    var unit: String
    var status: RigItemStatus
    var dataSet: RigDataSet?
    var template: RigItemTemplate?
    
    var statusColor: Color {
        switch status {
        case .normal: .green
        case .caution: .orange
        case .critical: .red
        }
    }
    
    init(name: String, value: Double, stringValue: String? = nil, unit: String, status: RigItemStatus = .normal, template: RigItemTemplate?) {
        self.id = UUID()
        self.name = name
        self.value = value
        self.stringValue = stringValue
        self.unit = unit
        self.status = status
        self.template = template
    }
}

enum RigItemStatus: String, Codable {
    case normal = "正常"
    case caution = "確認推奨"
    case critical = "要交換/調整"
}

// MARK: - CheckListItem
@Model
final class CheckListItem {
    @Attribute(.unique) var id: UUID
    var task: String
    var isCompleted: Bool
    var category: String
    var boat: Boat?
    
    init(task: String, isCompleted: Bool = false, category: String, boat: Boat?) {
        self.id = UUID()
        self.task = task
        self.isCompleted = isCompleted
        self.category = category
        self.boat = boat
    }
}

// MARK: - RigItemTemplate
@Model
final class RigItemTemplate {
    @Attribute(.unique) var id: UUID
    var name: String
    var unit: String
    var category: String
    var boat: Boat?
    
    init(name: String, unit: String, category: String, boat: Boat?) {
        self.id = UUID()
        self.name = name
        self.unit = unit
        self.category = category
        self.boat = boat
    }
}
