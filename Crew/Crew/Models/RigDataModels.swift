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

// MARK: - WorkoutCategory
enum WorkoutCategory: String, Codable {
    case singleDistance = "Single Distance"
    case singleTime = "Single Time"
    case distanceInterval = "Distance Interval"
    case timeInterval = "Time Interval"
}

// MARK: - WorkoutTemplate
@Model
final class WorkoutTemplate {
    var id: UUID
    var name: String
    var sessionType: SessionType
    var category: WorkoutCategory
    var boat: Boat?
    var isDefault: Bool
    @Relationship(deleteRule: .cascade, inverse: \WorkoutMetricTemplate.workoutTemplate)
    var metricTemplates: [WorkoutMetricTemplate] = []
    
    init(name: String, sessionType: SessionType, category: WorkoutCategory, boat: Boat?, isDefault: Bool = false) {
        self.id = UUID()
        self.name = name
        self.sessionType = sessionType
        self.category = category
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

// MARK: - LapData
@Model
final class LapData {
    var id: UUID
    var lapNumber: Int
    var lapInterval: Int // 100, 200, or 500 meters
    var time: Double // seconds
    var split: String // m:s/500m format
    var strokeRate: Double // spm
    var session: TrainingSession?
    
    init(lapNumber: Int, lapInterval: Int, time: Double, split: String, strokeRate: Double, session: TrainingSession?) {
        self.id = UUID()
        self.lapNumber = lapNumber
        self.lapInterval = lapInterval
        self.time = time
        self.split = split
        self.strokeRate = strokeRate
        self.session = session
    }
}

// MARK: - IntervalRep
@Model
final class IntervalRep {
    var id: UUID
    var repNumber: Int
    var distance: Double // meters
    var strokeRate: Double // spm
    var averageSplit: String // m:s/500m format
    var session: TrainingSession?
    
    init(repNumber: Int, distance: Double, strokeRate: Double, averageSplit: String, session: TrainingSession?) {
        self.id = UUID()
        self.repNumber = repNumber
        self.distance = distance
        self.strokeRate = strokeRate
        self.averageSplit = averageSplit
        self.session = session
    }
}

// MARK: - WorkoutSummary
@Model
final class WorkoutSummary {
    var id: UUID
    var totalDistance: Int // meters, integer
    var totalTime: Int // seconds (work time only, excludes rest)
    var averagePace: Int // seconds per 500m
    var averageSPM: Double // strokes per minute
    var averageWatts: Int // watts, integer
    var workoutType: WorkoutCategory
    var targetValue: Int // target distance (m) or time (sec) depending on type
    var restTime: Int? // seconds, only for intervals
    var date: Date
    var session: TrainingSession?
    @Relationship(deleteRule: .cascade, inverse: \SplitData.summary)
    var splits: [SplitData] = []
    
    init(totalDistance: Int, totalTime: Int, averagePace: Int, averageSPM: Double, averageWatts: Int, workoutType: WorkoutCategory, targetValue: Int, restTime: Int? = nil, date: Date, session: TrainingSession?) {
        self.id = UUID()
        self.totalDistance = totalDistance
        self.totalTime = totalTime
        self.averagePace = averagePace
        self.averageSPM = averageSPM
        self.averageWatts = averageWatts
        self.workoutType = workoutType
        self.targetValue = targetValue
        self.restTime = restTime
        self.date = date
        self.session = session
    }
    
    // Computed property for formatted elapsed time (HH:MM:SS)
    var formattedElapsedTime: String {
        let hours = totalTime / 3600
        let minutes = (totalTime % 3600) / 60
        let seconds = totalTime % 60
        return String(format: "%02d:%02d:%02d", hours, minutes, seconds)
    }
    
    // Computed property for formatted pace (MM:SS / 500m)
    var formattedPace: String {
        let minutes = averagePace / 60
        let seconds = averagePace % 60
        return String(format: "%02d:%02d / 500m", minutes, seconds)
    }
}

// MARK: - SplitData
@Model
final class SplitData {
    var id: UUID
    var ordinalNumber: Int // index (1, 2, 3, ...)
    var distance: Int // meters, integer
    var elapsedTime: Int // seconds
    var averagePace: Int // seconds per 500m
    var averageSPM: Double // strokes per minute
    var averageWatts: Int // watts, integer
    var summary: WorkoutSummary?
    
    init(ordinalNumber: Int, distance: Int, elapsedTime: Int, averagePace: Int, averageSPM: Double, averageWatts: Int, summary: WorkoutSummary?) {
        self.id = UUID()
        self.ordinalNumber = ordinalNumber
        self.distance = distance
        self.elapsedTime = elapsedTime
        self.averagePace = averagePace
        self.averageSPM = averageSPM
        self.averageWatts = averageWatts
        self.summary = summary
    }
    
    // Computed property for formatted elapsed time (HH:MM:SS)
    var formattedElapsedTime: String {
        let hours = elapsedTime / 3600
        let minutes = (elapsedTime % 3600) / 60
        let seconds = elapsedTime % 60
        return String(format: "%02d:%02d:%02d", hours, minutes, seconds)
    }
    
    // Computed property for formatted pace (MM:SS / 500m)
    var formattedPace: String {
        let minutes = averagePace / 60
        let seconds = averagePace % 60
        return String(format: "%02d:%02d / 500m", minutes, seconds)
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
    /// 保存されたワークアウト画像（例：PM5の写真）
    @Attribute(.externalStorage)
    var workoutImageData: Data?
    @Relationship(deleteRule: .cascade, inverse: \WorkoutSummary.session)
    var workoutSummary: WorkoutSummary? // One-to-one relationship
    var boat: Boat?
    var workoutTemplate: WorkoutTemplate?
    
    init(date: Date, sessionType: SessionType, memo: String = "", isShared: Bool = false, boat: Boat?, workoutTemplate: WorkoutTemplate? = nil, workoutImageData: Data? = nil) {
        self.id = UUID()
        self.date = date
        self.sessionType = sessionType
        self.memo = memo
        self.isShared = isShared
        self.boat = boat
        self.workoutTemplate = workoutTemplate
        self.workoutImageData = workoutImageData
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

// MARK: - Boat Extension
extension Boat {
    /// デフォルトのリギングテンプレートを追加
    func addDefaultRigTemplates() {
        let defaultTemplates = [
            // クラッチ
            ("スパン", "mm", "クラッチ"),
            ("前傾", "°", "クラッチ"),
            ("後傾", "°", "クラッチ"),
            ("ブッシュ", "選択", "クラッチ"),
            ("ワークハイトB", "mm", "クラッチ"),
            ("ワークハイトS", "mm", "クラッチ"),
            
            // ストレッチャー
            ("アングル", "°", "ストレッチャー"),
            ("デプス", "mm", "ストレッチャー"),
            ("ピンヒール", "mm", "ストレッチャー"),
            ("ワークスルー", "mm", "ストレッチャー"),
            
            // オール
            ("全長", "mm", "オール"),
            ("インボード", "mm", "オール")
        ]
        
        for (name, unit, category) in defaultTemplates {
            let template = RigItemTemplate(name: name, unit: unit, category: category, boat: self)
            rigItemTemplates.append(template)
        }
    }
    
    /// デフォルトのワークアウトテンプレートを追加
    func addDefaultWorkoutTemplates() {
        // Single Distance (Ergo)
        let singleDistanceTemplate = WorkoutTemplate(
            name: "Single Distance",
            sessionType: .ergo,
            category: .singleDistance,
            boat: self,
            isDefault: true
        )
        singleDistanceTemplate.metricTemplates.append(WorkoutMetricTemplate(
            name: "目標距離",
            unit: "m",
            order: 0,
            workoutTemplate: singleDistanceTemplate
        ))
        workoutTemplates.append(singleDistanceTemplate)
        
        // Single Time (Ergo)
        let singleTimeTemplate = WorkoutTemplate(
            name: "Single Time",
            sessionType: .ergo,
            category: .singleTime,
            boat: self,
            isDefault: true
        )
        singleTimeTemplate.metricTemplates.append(WorkoutMetricTemplate(
            name: "目標時間",
            unit: "sec",
            order: 0,
            workoutTemplate: singleTimeTemplate
        ))
        workoutTemplates.append(singleTimeTemplate)
        
        // Distance Interval (Ergo)
        let distanceIntervalTemplate = WorkoutTemplate(
            name: "Distance Interval",
            sessionType: .ergo,
            category: .distanceInterval,
            boat: self,
            isDefault: true
        )
        distanceIntervalTemplate.metricTemplates.append(WorkoutMetricTemplate(
            name: "設定距離",
            unit: "m",
            order: 0,
            workoutTemplate: distanceIntervalTemplate
        ))
        distanceIntervalTemplate.metricTemplates.append(WorkoutMetricTemplate(
            name: "レスト時間",
            unit: "sec",
            order: 1,
            workoutTemplate: distanceIntervalTemplate
        ))
        workoutTemplates.append(distanceIntervalTemplate)
        
        // Time Interval (Ergo)
        let timeIntervalTemplate = WorkoutTemplate(
            name: "Time Interval",
            sessionType: .ergo,
            category: .timeInterval,
            boat: self,
            isDefault: true
        )
        timeIntervalTemplate.metricTemplates.append(WorkoutMetricTemplate(
            name: "設定時間",
            unit: "sec",
            order: 0,
            workoutTemplate: timeIntervalTemplate
        ))
        timeIntervalTemplate.metricTemplates.append(WorkoutMetricTemplate(
            name: "レスト時間",
            unit: "sec",
            order: 1,
            workoutTemplate: timeIntervalTemplate
        ))
        workoutTemplates.append(timeIntervalTemplate)
        
        // Single Distance (Boat)
        let boatSingleDistanceTemplate = WorkoutTemplate(
            name: "Single Distance",
            sessionType: .boat,
            category: .singleDistance,
            boat: self,
            isDefault: true
        )
        boatSingleDistanceTemplate.metricTemplates.append(WorkoutMetricTemplate(
            name: "目標距離",
            unit: "m",
            order: 0,
            workoutTemplate: boatSingleDistanceTemplate
        ))
        workoutTemplates.append(boatSingleDistanceTemplate)
        
        // Single Time (Boat)
        let boatSingleTimeTemplate = WorkoutTemplate(
            name: "Single Time",
            sessionType: .boat,
            category: .singleTime,
            boat: self,
            isDefault: true
        )
        boatSingleTimeTemplate.metricTemplates.append(WorkoutMetricTemplate(
            name: "目標時間",
            unit: "sec",
            order: 0,
            workoutTemplate: boatSingleTimeTemplate
        ))
        workoutTemplates.append(boatSingleTimeTemplate)
        
        // Distance Interval (Boat)
        let boatDistanceIntervalTemplate = WorkoutTemplate(
            name: "Distance Interval",
            sessionType: .boat,
            category: .distanceInterval,
            boat: self,
            isDefault: true
        )
        boatDistanceIntervalTemplate.metricTemplates.append(WorkoutMetricTemplate(
            name: "設定距離",
            unit: "m",
            order: 0,
            workoutTemplate: boatDistanceIntervalTemplate
        ))
        boatDistanceIntervalTemplate.metricTemplates.append(WorkoutMetricTemplate(
            name: "レスト時間",
            unit: "sec",
            order: 1,
            workoutTemplate: boatDistanceIntervalTemplate
        ))
        workoutTemplates.append(boatDistanceIntervalTemplate)
        
        // Time Interval (Boat)
        let boatTimeIntervalTemplate = WorkoutTemplate(
            name: "Time Interval",
            sessionType: .boat,
            category: .timeInterval,
            boat: self,
            isDefault: true
        )
        boatTimeIntervalTemplate.metricTemplates.append(WorkoutMetricTemplate(
            name: "設定時間",
            unit: "sec",
            order: 0,
            workoutTemplate: boatTimeIntervalTemplate
        ))
        boatTimeIntervalTemplate.metricTemplates.append(WorkoutMetricTemplate(
            name: "レスト時間",
            unit: "sec",
            order: 1,
            workoutTemplate: boatTimeIntervalTemplate
        ))
        workoutTemplates.append(boatTimeIntervalTemplate)
    }
}
