import Foundation
import SwiftUI
import SwiftData

// MARK: - Boat
@Model
final class Boat {
    var id: UUID
    var name: String
    
    // @Relationshipを持つプロパティは、SwiftDataが管理するため、手動で初期化する必要はありません。
    @Relationship(deleteRule: .cascade, inverse: \RigDataSet.boat)
    var rigDataSets: [RigDataSet] = []
    
    @Relationship(deleteRule: .cascade, inverse: \CheckListItem.boat)
    var checklist: [CheckListItem] = []
    
    @Relationship(deleteRule: .cascade, inverse: \RigItemTemplate.boat)
    var rigItemTemplates: [RigItemTemplate] = []
    
    @Relationship(deleteRule: .cascade, inverse: \TrainingSession.boat)
    var trainingSessions: [TrainingSession] = []
    
    @Relationship(deleteRule: .cascade, inverse: \WorkoutTemplate.boat)
    var workoutTemplates: [WorkoutTemplate] = []
    
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
    var id: UUID
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
    var id: UUID
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
    var id: UUID
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
    var id: UUID
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

// MARK: - SessionType
enum SessionType: String, Codable {
    case ergo = "エルゴ"
    case boat = "ボート"
}

// MARK: - WorkoutTemplate
@Model
final class WorkoutTemplate {
    var id: UUID
    var name: String
    var sessionType: SessionType
    var boat: Boat?
    var isDefault: Bool
    @Relationship(deleteRule: .cascade, inverse: \WorkoutMetricTemplate.workoutTemplate)
    var metricTemplates: [WorkoutMetricTemplate] = []
    
    init(name: String, sessionType: SessionType, boat: Boat?, isDefault: Bool = false) {
        self.id = UUID()
        self.name = name
        self.sessionType = sessionType
        self.boat = boat
        self.isDefault = isDefault
    }
}

// MARK: - WorkoutMetricTemplate
@Model
final class WorkoutMetricTemplate {
    var id: UUID
    var name: String
    var unit: String
    var order: Int
    var workoutTemplate: WorkoutTemplate?
    
    init(name: String, unit: String, order: Int = 0, workoutTemplate: WorkoutTemplate?) {
        self.id = UUID()
        self.name = name
        self.unit = unit
        self.order = order
        self.workoutTemplate = workoutTemplate
    }
}

// MARK: - TrainingSession
@Model
final class TrainingSession {
    var id: UUID
    var date: Date
    var sessionType: SessionType
    var memo: String
    var isShared: Bool
    @Relationship(deleteRule: .cascade, inverse: \TrainingMetric.session)
    var metrics: [TrainingMetric] = []
    var boat: Boat?
    var workoutTemplate: WorkoutTemplate?
    
    init(date: Date, sessionType: SessionType, memo: String = "", isShared: Bool = false, boat: Boat?, workoutTemplate: WorkoutTemplate? = nil) {
        self.id = UUID()
        self.date = date
        self.sessionType = sessionType
        self.memo = memo
        self.isShared = isShared
        self.boat = boat
        self.workoutTemplate = workoutTemplate
    }
}

// MARK: - TrainingMetric
@Model
final class TrainingMetric {
    var id: UUID
    var name: String
    var value: Double
    var unit: String
    var session: TrainingSession?
    
    init(name: String, value: Double, unit: String, session: TrainingSession?) {
        self.id = UUID()
        self.name = name
        self.value = value
        self.unit = unit
        self.session = session
    }
}
