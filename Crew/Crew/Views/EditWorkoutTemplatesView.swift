import SwiftUI
import SwiftData

struct EditWorkoutTemplatesView: View {
    @Environment(\.modelContext) private var context
    @Bindable var boat: Boat
    @State private var showingAddWorkout = false
    @State private var selectedSessionType: SessionType = .ergo
    
    private var ergoWorkouts: [WorkoutTemplate] {
        boat.workoutTemplates.filter { $0.sessionType == .ergo }
            .sorted { 
                if $0.isDefault != $1.isDefault {
                    return $0.isDefault
                }
                return $0.name < $1.name
            }
    }
    
    private var boatWorkouts: [WorkoutTemplate] {
        boat.workoutTemplates.filter { $0.sessionType == .boat }
            .sorted { 
                if $0.isDefault != $1.isDefault {
                    return $0.isDefault
                }
                return $0.name < $1.name
            }
    }
    
    var body: some View {
        Form {
            Picker("カテゴリー", selection: $selectedSessionType) {
                Text("エルゴ").tag(SessionType.ergo)
                Text("ボート").tag(SessionType.boat)
            }
            .pickerStyle(.segmented)
            
            Section(header: Text(selectedSessionType == .ergo ? "エルゴワークアウト" : "ボートワークアウト")) {
                ForEach(selectedSessionType == .ergo ? ergoWorkouts : boatWorkouts) { workout in
                    NavigationLink {
                        EditWorkoutDetailView(workout: workout)
                    } label: {
                        VStack(alignment: .leading, spacing: 4) {
                            HStack {
                                Text(workout.name)
                                    .font(.headline)
                                if workout.isDefault {
                                    Image(systemName: "star.fill")
                                        .font(.caption)
                                        .foregroundColor(.yellow)
                                }
                            }
                            Text("\(workout.metricTemplates.count) メトリクス")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                .onDelete { offsets in
                    deleteWorkouts(at: offsets)
                }
            }
        }
        .navigationTitle("ワークアウトテンプレート")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    showingAddWorkout = true
                } label: {
                    Image(systemName: "plus")
                }
            }
        }
        .sheet(isPresented: $showingAddWorkout) {
            AddWorkoutTemplateView(boat: boat, sessionType: selectedSessionType)
        }
    }
    
    private func deleteWorkouts(at offsets: IndexSet) {
        let workouts = selectedSessionType == .ergo ? ergoWorkouts : boatWorkouts
        for index in offsets {
            context.delete(workouts[index])
        }
    }
}

struct EditWorkoutDetailView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context
    @Bindable var workout: WorkoutTemplate
    @State private var showingAddMetric = false
    
    var body: some View {
        Form {
            Section(header: Text("ワークアウト情報")) {
                TextField("ワークアウト名", text: $workout.name)
            }
            
            Section(header: Text("メトリクス")) {
                ForEach(workout.metricTemplates.sorted { $0.order < $1.order }) { metric in
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(metric.name)
                                .font(.headline)
                            Text(metric.unit)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        Spacer()
                    }
                }
                .onDelete { offsets in
                    deleteMetrics(at: offsets)
                }
                
                Button("メトリクスを追加") {
                    showingAddMetric = true
                }
            }
        }
        .navigationTitle("ワークアウト編集")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showingAddMetric) {
            AddMetricTemplateView(workout: workout)
        }
    }
    
    private func deleteMetrics(at offsets: IndexSet) {
        let sortedMetrics = workout.metricTemplates.sorted { $0.order < $1.order }
        for index in offsets {
            context.delete(sortedMetrics[index])
        }
    }
}

struct AddWorkoutTemplateView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context
    @Bindable var boat: Boat
    let sessionType: SessionType
    
    @State private var workoutName = ""
    @State private var metrics: [MetricTemplateData] = []
    
    struct MetricTemplateData: Identifiable {
        let id = UUID()
        var name: String
        var unit: String
        var order: Int
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("ワークアウト情報")) {
                    TextField("ワークアウト名", text: $workoutName)
                }
                
                Section(header: Text("メトリクス")) {
                    ForEach($metrics) { $metric in
                        VStack(alignment: .leading, spacing: 8) {
                            TextField("メトリクス名", text: $metric.name)
                            TextField("単位", text: $metric.unit)
                        }
                    }
                    .onDelete { offsets in
                        metrics.remove(atOffsets: offsets)
                        // 順序を更新
                        for (index, _) in metrics.enumerated() {
                            metrics[index].order = index
                        }
                    }
                    
                    Button("メトリクスを追加") {
                        metrics.append(MetricTemplateData(name: "", unit: "", order: metrics.count))
                    }
                }
            }
            .navigationTitle("ワークアウト追加")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("キャンセル") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("保存") {
                        saveWorkout()
                        dismiss()
                    }
                    .disabled(workoutName.isEmpty || metrics.isEmpty || metrics.contains { $0.name.isEmpty || $0.unit.isEmpty })
                }
            }
        }
    }
    
    private func saveWorkout() {
        let template = WorkoutTemplate(
            name: workoutName,
            sessionType: sessionType,
            boat: boat,
            isDefault: false
        )
        
        for (index, metricData) in metrics.enumerated() {
            let metricTemplate = WorkoutMetricTemplate(
                name: metricData.name,
                unit: metricData.unit,
                order: index,
                workoutTemplate: template
            )
            template.metricTemplates.append(metricTemplate)
        }
        
        boat.workoutTemplates.append(template)
        
        do {
            try context.save()
        } catch {
            print("Failed to save workout template: \(error)")
        }
    }
}

struct AddMetricTemplateView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context
    @Bindable var workout: WorkoutTemplate
    
    @State private var metricName = ""
    @State private var metricUnit = ""
    
    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("メトリクス情報")) {
                    TextField("メトリクス名", text: $metricName)
                    TextField("単位", text: $metricUnit)
                }
            }
            .navigationTitle("メトリクス追加")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("キャンセル") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("保存") {
                        saveMetric()
                        dismiss()
                    }
                    .disabled(metricName.isEmpty || metricUnit.isEmpty)
                }
            }
        }
    }
    
    private func saveMetric() {
        let order = workout.metricTemplates.count
        let metricTemplate = WorkoutMetricTemplate(
            name: metricName,
            unit: metricUnit,
            order: order,
            workoutTemplate: workout
        )
        workout.metricTemplates.append(metricTemplate)
        
        do {
            try context.save()
        } catch {
            print("Failed to save metric template: \(error)")
        }
    }
}

