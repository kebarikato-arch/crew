import Foundation
import SwiftData

@Model
class Boat {
    @Attribute(.unique) var id = UUID()
    var name: String
    
    @Relationship(deleteRule: .cascade) var rigDataSets = [RigDataSet]()
    @Relationship(deleteRule: .cascade) var checklistItems = [CheckListItem]()
    @Relationship(deleteRule: .cascade) var rigItemTemplates = [RigItemTemplate]()
    
    init(name: String) {
        self.name = name
    }
}

@Model
class RigDataSet {
    @Attribute(.unique) var id = UUID()
    var date: Date
    var memo: String
    
    @Relationship(deleteRule: .cascade, inverse: \RigItem.rigDataSet)
    var rigItems = [RigItem]()
    
    init(date: Date, memo: String) {
        self.date = date
        self.memo = memo
    }
}

@Model
class RigItem {
    @Attribute(.unique) var id = UUID()
    var name: String
    var value: Double
    var stringValue: String?
    var unit: String
    var status: RigItemStatus
    var template: RigItemTemplate
    var rigDataSet: RigDataSet?
    
    init(name: String, value: Double, stringValue: String? = nil, unit: String, status: RigItemStatus, template: RigItemTemplate, rigDataSet: RigDataSet? = nil) {
        self.name = name
        self.value = value
        self.stringValue = stringValue
        self.unit = unit
        self.status = status
        self.template = template
        self.rigDataSet = rigDataSet
    }
}

enum RigItemStatus: String, Codable, CaseIterable {
    case normal = "正常"
    case caution = "確認推奨"
    case critical = "要交換/調整"
    
    var
    displayName: String {
        return self.rawValue
    }
}

@Model
class CheckListItem {
    @Attribute(.unique) var id = UUID()
    var task: String
    var isCompleted: Bool
    var category: String // "セーリング前" or "セーリング後"
    var order: Int // 表示順を管理するためのプロパティ
    
    init(task: String, isCompleted: Bool, category: String, order: Int) {
        self.task = task
        self.isCompleted = isCompleted
        self.category = category
        self.order = order
    }
}

@Model
class RigItemTemplate {
    @Attribute(.unique) var id = UUID()
    var name: String
    var unit: String
    var category: String
    
    init(name: String, unit: String, category: String) {
        self.name = name
        self.unit = unit
        self.category = category
    }
}
