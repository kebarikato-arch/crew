import SwiftUI
import SwiftData

struct AddTrainingSessionView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context
    @Query(sort: \Boat.name) private var boats: [Boat]
    
    @Bindable var currentBoat: Boat
    var sessionToEdit: TrainingSession?
    
    @State private var date: Date = .now
    @State private var sessionType: SessionType = .ergo
    @State private var selectedWorkoutTemplate: WorkoutTemplate?
    @State private var selectedBoat: Boat?
    @State private var memo: String = ""
    @State private var isShared: Bool = false
    @State private var metrics: [TrainingMetricData] = []
    
    struct TrainingMetricData: Identifiable {
        let id = UUID()
        var name: String
        var value: Double
        var unit: String
    }
    
    // セッションタイプに応じたワークアウト一覧
    private var availableWorkouts: [WorkoutTemplate] {
        let workouts = currentBoat.workoutTemplates.filter { 
            $0.sessionType == sessionType && ($0.boat == nil || $0.boat?.id == currentBoat.id)
        }
        return workouts.sorted { 
            // デフォルトを先に、その後名前順
            if $0.isDefault != $1.isDefault {
                return $0.isDefault
            }
            return $0.name < $1.name
        }
    }
    
    var body: some View {
        NavigationStack {
            Form {
                // セクション1: セッションタイプ
                Section(header: Text("セッションタイプ")) {
                    Picker("タイプ", selection: $sessionType) {
                        Text("エルゴ").tag(SessionType.ergo)
                        Text("ボート").tag(SessionType.boat)
                    }
                    .pickerStyle(.segmented)
                    .onChange(of: sessionType) { oldValue, newValue in
                        // タイプ変更時、ワークアウト選択をリセット
                        selectedWorkoutTemplate = nil
                        metrics = []
                    }
                }
                
                // セクション2: ワークアウト選択
                Section(header: Text("ワークアウトを選択")) {
                    if availableWorkouts.isEmpty {
                        Text("利用可能なワークアウトがありません")
                            .foregroundColor(.secondary)
                            .font(.caption)
                    } else {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 12) {
                                ForEach(availableWorkouts) { workout in
                                    WorkoutSelectionCard(
                                        workout: workout,
                                        isSelected: selectedWorkoutTemplate?.id == workout.id
                                    ) {
                                        selectWorkout(workout)
                                    }
                                }
                            }
                            .padding(.horizontal)
                        }
                        .frame(height: 140)
                    }
                }
                
                // セクション3: 基本情報
                Section(header: Text("基本情報")) {
                    DatePicker("日時", selection: $date)
                    
                    if sessionType == .boat {
                        Picker("ボート", selection: $selectedBoat) {
                            Text("選択してください").tag(nil as Boat?)
                            ForEach(boats) { boat in
                                Text(boat.name).tag(boat as Boat?)
                            }
                        }
                    }
                    
                    TextField("メモ", text: $memo, axis: .vertical)
                        .lineLimit(3...6)
                    
                    if sessionType == .ergo {
                        Toggle("共有する", isOn: $isShared)
                    }
                }
                
                // セクション4: メトリクス入力
                if selectedWorkoutTemplate != nil {
                    Section(header: Text("メトリクス")) {
                        ForEach($metrics) { $metric in
                            VStack(alignment: .leading, spacing: 8) {
                                HStack {
                                    Text(metric.name)
                                        .font(.headline)
                                    Spacer()
                                    Text(metric.unit)
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                
                                TextField("値を入力", value: $metric.value, format: .number)
                                    .keyboardType(.decimalPad)
                                    .textFieldStyle(.roundedBorder)
                            }
                            .padding(.vertical, 4)
                        }
                    }
                }
            }
            .navigationTitle(sessionToEdit == nil ? "トレーニング記録" : "トレーニング編集")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("キャンセル") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("保存") {
                        saveSession()
                        dismiss()
                    }
                    .disabled(selectedWorkoutTemplate == nil || metrics.isEmpty || metrics.allSatisfy { $0.value == 0.0 })
                }
            }
            .onAppear {
                if let session = sessionToEdit {
                    date = session.date
                    sessionType = session.sessionType
                    selectedWorkoutTemplate = session.workoutTemplate
                    selectedBoat = session.boat
                    memo = session.memo
                    isShared = session.isShared
                    metrics = session.metrics.map { TrainingMetricData(name: $0.name, value: $0.value, unit: $0.unit) }
                } else {
                    selectedBoat = currentBoat
                }
            }
        }
    }
    
    private func deleteMetrics(at offsets: IndexSet) {
        metrics.remove(atOffsets: offsets)
    }
    
    private func selectWorkout(_ workout: WorkoutTemplate) {
        selectedWorkoutTemplate = workout
        // メトリクスを自動生成
        metrics = workout.metricTemplates
            .sorted { $0.order < $1.order }
            .map { metricTemplate in
                TrainingMetricData(
                    name: metricTemplate.name,
                    value: 0.0,
                    unit: metricTemplate.unit
                )
            }
    }
    
    private func saveSession() {
        if let session = sessionToEdit {
            // Remove from old boat if needed
            if let oldBoat = session.boat {
                oldBoat.trainingSessions.removeAll { $0.id == session.id }
            }
            
            // Update existing session
            session.date = date
            session.sessionType = sessionType
            session.memo = memo
            session.isShared = isShared
            session.workoutTemplate = selectedWorkoutTemplate
            
            // Update boat relationship
            if sessionType == .boat {
                session.boat = selectedBoat
                if let boat = selectedBoat, !boat.trainingSessions.contains(where: { $0.id == session.id }) {
                    boat.trainingSessions.append(session)
                }
            } else {
                // For Ergo, boat is nil if shared
                if isShared {
                    session.boat = nil
                } else {
                    session.boat = currentBoat
                    if !currentBoat.trainingSessions.contains(where: { $0.id == session.id }) {
                        currentBoat.trainingSessions.append(session)
                    }
                }
            }
            
            // Update metrics
            session.metrics.removeAll()
            for metricData in metrics {
                let metric = TrainingMetric(name: metricData.name, value: metricData.value, unit: metricData.unit, session: session)
                session.metrics.append(metric)
            }
            
            do {
                try context.save()
            } catch {
                print("Failed to update training session: \(error)")
            }
        } else {
            // Create new session
            let boat = sessionType == .boat ? selectedBoat : (isShared ? nil : currentBoat)
            let newSession = TrainingSession(date: date, sessionType: sessionType, memo: memo, isShared: isShared, boat: boat, workoutTemplate: selectedWorkoutTemplate)
            
            // Add metrics
            for metricData in metrics {
                let metric = TrainingMetric(name: metricData.name, value: metricData.value, unit: metricData.unit, session: newSession)
                newSession.metrics.append(metric)
            }
            
            // Add to boat if not shared, otherwise insert directly (shared sessions have boat = nil)
            if let boat = boat {
                boat.trainingSessions.append(newSession)
            } else {
                // Shared Ergo session - insert directly into context
                context.insert(newSession)
            }
            
            do {
                try context.save()
            } catch {
                print("Failed to save training session: \(error)")
            }
        }
    }
}

