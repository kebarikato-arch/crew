import SwiftUI
import SwiftData

struct WelcomeView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var newBoatName = ""
    
    var body: some View {
        VStack(spacing: 20) {
            Spacer()
            
            Image(systemName: "sailboat.circle.fill")
                .font(.system(size: 80))
                .foregroundColor(.accentColor)
            
            Text("Crewへようこそ")
                .font(.largeTitle)
                .fontWeight(.bold)
            
            Text("まずはあなたのボートを登録しましょう。")
                .font(.headline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            TextField("ボート名", text: $newBoatName)
                .textFieldStyle(.roundedBorder)
                .padding(.horizontal, 40)

            Button("ボートを登録する", action: addBoat)
                .buttonStyle(.borderedProminent)
                .disabled(newBoatName.isEmpty)

            Spacer()
        }
        .padding()
    }
    
    private func addBoat() {
        guard !newBoatName.trimmingCharacters(in: .whitespaces).isEmpty else { return }
        // 修正された正しい初期化方法でBoatオブジェクトを作成します
        let newBoat = Boat(name: newBoatName)
        modelContext.insert(newBoat)
        
        // デフォルトのリグテンプレートを追加
        addDefaultRigTemplates(to: newBoat)
        
        // デフォルトのチェックリスト項目を追加
        addDefaultChecklistItems(to: newBoat)
        
        // デフォルトのワークアウトテンプレートを追加
        addDefaultWorkoutTemplates(to: newBoat)
        
        // 念のためdo-catchでエラーを捕捉します
        do {
            try modelContext.save()
            DispatchQueue.main.async { newBoatName = "" }
        } catch {
            print("ボートの保存に失敗しました: \(error.localizedDescription)")
        }
    }
    
    private func addDefaultRigTemplates(to boat: Boat) {
        let defaultTemplates = [
            // クラッチ
            ("スパン", "cm", "クラッチ"),
            ("前傾", "°", "クラッチ"),
            ("後傾", "°", "クラッチ"),
            ("ブッシュ", "選択", "クラッチ"),
            ("ワークハイトB", "cm", "クラッチ"),
            ("ワークハイトS", "cm", "クラッチ"),
            
            // ストレッチャー
            ("アングル", "°", "ストレッチャー"),
            ("デプス", "cm", "ストレッチャー"),
            ("ピンヒール", "cm", "ストレッチャー"),
            ("ワークスルー", "cm", "ストレッチャー"),
            
            // オール
            ("全長", "cm", "オール"),
            ("インボード", "cm", "オール")
        ]
        
        for (name, unit, category) in defaultTemplates {
            let template = RigItemTemplate(name: name, unit: unit, category: category, boat: boat)
            boat.rigItemTemplates.append(template)
        }
    }
    
    private func addDefaultChecklistItems(to boat: Boat) {
        let defaultItems = [
            // レース前チェック
            ("オールの確認", "レース前チェック"),
            ("リグの確認", "レース前チェック"),
            ("ボートの点検", "レース前チェック"),
            
            // 持ち物
            ("ユニフォーム", "持ち物"),
            ("シューズ", "持ち物"),
            ("水筒", "持ち物"),
            ("タオル", "持ち物"),
            ("着替え", "持ち物")
        ]
        
        for (task, category) in defaultItems {
            let item = CheckListItem(task: task, isCompleted: false, category: category, boat: boat)
            boat.checklist.append(item)
        }
    }
    
    private func addDefaultWorkoutTemplates(to boat: Boat) {
        // 4つのPM5ワークアウトタイプを作成
        // ユーザーが各タイプのパラメータを設定できるようにする
        
        // Single Distance
        let singleDistanceTemplate = WorkoutTemplate(
            name: "Single Distance",
            sessionType: .ergo,
            category: .singleDistance,
            boat: boat,
            isDefault: true
        )
        singleDistanceTemplate.metricTemplates.append(WorkoutMetricTemplate(
            name: "目標距離",
            unit: "m",
            order: 0,
            workoutTemplate: singleDistanceTemplate
        ))
        boat.workoutTemplates.append(singleDistanceTemplate)
        
        // Single Time
        let singleTimeTemplate = WorkoutTemplate(
            name: "Single Time",
            sessionType: .ergo,
            category: .singleTime,
            boat: boat,
            isDefault: true
        )
        singleTimeTemplate.metricTemplates.append(WorkoutMetricTemplate(
            name: "目標時間",
            unit: "sec",
            order: 0,
            workoutTemplate: singleTimeTemplate
        ))
        boat.workoutTemplates.append(singleTimeTemplate)
        
        // Distance Interval
        let distanceIntervalTemplate = WorkoutTemplate(
            name: "Distance Interval",
            sessionType: .ergo,
            category: .distanceInterval,
            boat: boat,
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
        boat.workoutTemplates.append(distanceIntervalTemplate)
        
        // Time Interval
        let timeIntervalTemplate = WorkoutTemplate(
            name: "Time Interval",
            sessionType: .ergo,
            category: .timeInterval,
            boat: boat,
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
        boat.workoutTemplates.append(timeIntervalTemplate)
        
        // ボート用も同様に作成
        let boatSingleDistanceTemplate = WorkoutTemplate(
            name: "Single Distance",
            sessionType: .boat,
            category: .singleDistance,
            boat: boat,
            isDefault: true
        )
        boatSingleDistanceTemplate.metricTemplates.append(WorkoutMetricTemplate(
            name: "目標距離",
            unit: "m",
            order: 0,
            workoutTemplate: boatSingleDistanceTemplate
        ))
        boat.workoutTemplates.append(boatSingleDistanceTemplate)
        
        let boatSingleTimeTemplate = WorkoutTemplate(
            name: "Single Time",
            sessionType: .boat,
            category: .singleTime,
            boat: boat,
            isDefault: true
        )
        boatSingleTimeTemplate.metricTemplates.append(WorkoutMetricTemplate(
            name: "目標時間",
            unit: "sec",
            order: 0,
            workoutTemplate: boatSingleTimeTemplate
        ))
        boat.workoutTemplates.append(boatSingleTimeTemplate)
        
        let boatDistanceIntervalTemplate = WorkoutTemplate(
            name: "Distance Interval",
            sessionType: .boat,
            category: .distanceInterval,
            boat: boat,
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
        boat.workoutTemplates.append(boatDistanceIntervalTemplate)
        
        let boatTimeIntervalTemplate = WorkoutTemplate(
            name: "Time Interval",
            sessionType: .boat,
            category: .timeInterval,
            boat: boat,
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
        boat.workoutTemplates.append(boatTimeIntervalTemplate)
    }
}
