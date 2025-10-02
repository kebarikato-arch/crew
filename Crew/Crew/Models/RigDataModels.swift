import Foundation
import SwiftData
import SwiftUI

@Model
class Boat {
    @Attribute(.unique) var id = UUID()
    var name: String
    
    @Relationship(deleteRule: .cascade) var rigDataSets = [RigDataSet]()
    @Relationship(deleteRule: .cascade) var checklist = [CheckListItem]() // checklistItems -> checklist に統一
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
    
    @Relationship(deleteRule: .cascade, inverse: \RigItem.dataSet)
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
    
    // RigItemTemplateとのリレーションシップ
    var template: RigItemTemplate?
    
    var dataSet: RigDataSet?
    
    init(name: String, value: Double, stringValue: String? = nil, unit: String, status: RigItemStatus, template: RigItemTemplate?) {
        self.name = name
        self.value = value
        self.stringValue = stringValue
        self.unit = unit
        self.status = status
        self.template = template
    }
    
    var statusColor: Color {
        switch status {
        case .normal: .green
        case .caution: .yellow
        case .critical: .red
        }
    }
}

enum RigItemStatus: String, Codable, CaseIterable {
    case normal = "正常"
    case caution = "確認推奨"
    case critical = "要交換/調整"
}

@Model
class CheckListItem {
    @Attribute(.unique) var id = UUID()
    var task: String
    var isCompleted: Bool
    var category: String
    
    init(task: String, isCompleted: Bool, category: String) {
        self.task = task
        self.isCompleted = isCompleted
        self.category = category
    }
    
    enum Category: String, CaseIterable {
        case beforeSail = "セーリング前"
        case afterSail = "セーリング後"
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
