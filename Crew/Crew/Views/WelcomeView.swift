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
        // エルゴ用デフォルトワークアウト
        let ergoDefaults = [
            ("500mタイムトライアル", [
                ("タイム", "sec", 0),
                ("ストロークレート", "spm", 1),
                ("平均パワー", "W", 2)
            ]),
            ("2000mテスト", [
                ("タイム", "min:sec", 0),
                ("平均ストロークレート", "spm", 1),
                ("平均パワー", "W", 2),
                ("最大パワー", "W", 3)
            ]),
            ("インターバルトレーニング", [
                ("セット数", "回", 0),
                ("インターバル時間", "sec", 1),
                ("レスト時間", "sec", 2),
                ("平均パワー", "W", 3)
            ])
        ]
        
        // ボート用デフォルトワークアウト
        let boatDefaults = [
            ("スプリント練習", [
                ("距離", "m", 0),
                ("タイム", "sec", 1),
                ("ストロークレート", "spm", 2)
            ]),
            ("ロングディスタンス", [
                ("距離", "km", 0),
                ("タイム", "min", 1),
                ("平均ストロークレート", "spm", 2)
            ]),
            ("テクニック練習", [
                ("練習時間", "min", 0),
                ("フォーカス", "text", 1)
            ])
        ]
        
        // エルゴワークアウトを作成
        for (workoutName, metrics) in ergoDefaults {
            let template = WorkoutTemplate(
                name: workoutName,
                sessionType: .ergo,
                boat: boat,
                isDefault: true
            )
            for (metricName, unit, order) in metrics {
                let metricTemplate = WorkoutMetricTemplate(
                    name: metricName,
                    unit: unit,
                    order: order,
                    workoutTemplate: template
                )
                template.metricTemplates.append(metricTemplate)
            }
            boat.workoutTemplates.append(template)
        }
        
        // ボートワークアウトを作成
        for (workoutName, metrics) in boatDefaults {
            let template = WorkoutTemplate(
                name: workoutName,
                sessionType: .boat,
                boat: boat,
                isDefault: true
            )
            for (metricName, unit, order) in metrics {
                let metricTemplate = WorkoutMetricTemplate(
                    name: metricName,
                    unit: unit,
                    order: order,
                    workoutTemplate: template
                )
                template.metricTemplates.append(metricTemplate)
            }
            boat.workoutTemplates.append(template)
        }
    }
}
