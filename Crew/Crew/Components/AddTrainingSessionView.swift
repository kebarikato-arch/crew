import SwiftUI
import SwiftData
import PhotosUI

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
    @State private var workoutImageData: Data?
    @State private var selectedImageItem: PhotosPickerItem?
    
    // PM5 Workout Summary states
    @State private var totalDistance: Int = 0
    @State private var totalTime: Int = 0 // seconds
    @State private var averagePace: Int = 0 // seconds per 500m
    @State private var averageSPM: Double = 0.0
    @State private var averageWatts: Int = 0
    
    // Split data states
    @State private var splits: [SplitDataInput] = []
    @State private var splitInterval: Int = 500 // meters for distance, seconds for time
    
    // Interval-specific states
    @State private var numberOfIntervals: Int = 1
    @State private var restTime: Int = 0 // seconds
    
    struct TrainingMetricData: Identifiable {
        let id = UUID()
        var name: String
        var value: Double
        var unit: String
    }
    
    struct SplitDataInput: Identifiable {
        let id = UUID()
        var ordinalNumber: Int
        var distance: Int = 0 // meters
        var elapsedTime: Int = 0 // seconds
        var averagePace: Int = 0 // seconds per 500m
        var averageSPM: Double = 0.0
        var averageWatts: Int = 0
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
                        totalDistance = 0
                        totalTime = 0
                        averagePace = 0
                        averageSPM = 0.0
                        averageWatts = 0
                        splits = []
                        numberOfIntervals = 1
                        restTime = 0
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
                    
                    PhotosPicker(selection: $selectedImageItem, matching: .images, photoLibrary: .shared()) {
                        Label(workoutImageData == nil ? "写真を添付" : "写真を変更", systemImage: "photo")
                    }
                    .onChange(of: selectedImageItem) { oldItem, newItem in
                        guard let newItem else { return }
                        Task {
                            if let data = try? await newItem.loadTransferable(type: Data.self) {
                                await MainActor.run {
                                    workoutImageData = data
                                }
                            }
                        }
                    }
                    
                    if let data = workoutImageData, let uiImage = UIImage(data: data) {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("添付画像プレビュー")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Image(uiImage: uiImage)
                                .resizable()
                                .scaledToFit()
                                .cornerRadius(8)
                                .frame(maxHeight: 180)
                            Button("画像を削除", role: .destructive) {
                                workoutImageData = nil
                                selectedImageItem = nil
                            }
                        }
                        .padding(.top, 4)
                    }
                    
                    if sessionType == .ergo {
                        Toggle("共有する", isOn: $isShared)
                    }
                }
                
                // セクション4: PM5ワークアウトタイプ別入力
                if let workout = selectedWorkoutTemplate {
                    // Single Distance
                    if workout.category == .singleDistance {
                        singleDistanceSection()
                    }
                    // Single Time
                    else if workout.category == .singleTime {
                        singleTimeSection()
                    }
                    // Distance Interval
                    else if workout.category == .distanceInterval {
                        distanceIntervalSection()
                    }
                    // Time Interval
                    else if workout.category == .timeInterval {
                        timeIntervalSection()
                    }
                }
            }
            .environment(\.locale, Locale(identifier: "ja_JP"))
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
                    .disabled(selectedWorkoutTemplate == nil || !isValidInput())
                }
            }
            .onAppear {
                if let session = sessionToEdit, let summary = session.workoutSummary {
                    date = session.date
                    sessionType = session.sessionType
                    selectedWorkoutTemplate = session.workoutTemplate
                    selectedBoat = session.boat
                    memo = session.memo
                    isShared = session.isShared
                    workoutImageData = session.workoutImageData
                    
                    // Load WorkoutSummary data
                    totalDistance = summary.totalDistance
                    totalTime = summary.totalTime
                    averagePace = summary.averagePace
                    averageSPM = summary.averageSPM
                    averageWatts = summary.averageWatts
                    restTime = summary.restTime ?? 0
                    
                    // Load SplitData
                    splits = summary.splits.sorted { $0.ordinalNumber < $1.ordinalNumber }.map {
                        SplitDataInput(
                            ordinalNumber: $0.ordinalNumber,
                            distance: $0.distance,
                            elapsedTime: $0.elapsedTime,
                            averagePace: $0.averagePace,
                            averageSPM: $0.averageSPM,
                            averageWatts: $0.averageWatts
                        )
                    }
                    
                    // Load target value and rest time from metrics
                    if let workout = session.workoutTemplate {
                        metrics = workout.metricTemplates
                            .sorted { $0.order < $1.order }
                            .map { template in
                                if template.name == "レスト時間" {
                                    TrainingMetricData(name: template.name, value: Double(restTime), unit: template.unit)
                                } else {
                                    TrainingMetricData(name: template.name, value: Double(summary.targetValue), unit: template.unit)
                                }
                            }
                    }
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
        
        // リセット
        totalDistance = 0
        totalTime = 0
        averagePace = 0
        averageSPM = 0.0
        averageWatts = 0
        splits = []
        numberOfIntervals = 1
        restTime = 0
        
        // デフォルトのスプリット間隔を設定
        if workout.category == .singleDistance {
            splitInterval = 500 // meters
        } else if workout.category == .singleTime {
            splitInterval = 300 // 5 minutes in seconds
        }
    }
    
    private func isValidInput() -> Bool {
        guard selectedWorkoutTemplate != nil else { return false }
        
        // ターゲット値が設定されているか確認
        if metrics.isEmpty || metrics.allSatisfy({ $0.value == 0.0 }) {
            return false
        }
        
        // サマリーデータが設定されているか確認
        if totalDistance == 0 && totalTime == 0 {
            return false
        }
        
        return true
    }
    
    // MARK: - Single Distance Section
    @ViewBuilder
    private func singleDistanceSection() -> some View {
        // ターゲット距離設定
        Section(header: Text("ターゲット設定")) {
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
                        .keyboardType(.numberPad)
                        .textFieldStyle(.roundedBorder)
                }
                .padding(.vertical, 4)
            }
        }
        
        // ワークアウトサマリー
        Section(header: Text("ワークアウトサマリー")) {
            HStack {
                Text("総距離 (m)")
                Spacer()
                TextField("0", value: $totalDistance, format: .number)
                    .keyboardType(.numberPad)
                    .textFieldStyle(.roundedBorder)
                    .frame(width: 100)
            }
            TimeInputView(totalSeconds: $totalTime, label: "総時間")
            PaceInputView(totalSeconds: $averagePace, label: "平均ペース")
            HStack {
                Text("平均SPM")
                Spacer()
                TextField("0.0", value: $averageSPM, format: .number)
                    .keyboardType(.decimalPad)
                    .textFieldStyle(.roundedBorder)
                    .frame(width: 100)
            }
            HStack {
                Text("平均パワー (W)")
                Spacer()
                TextField("0", value: $averageWatts, format: .number)
                    .keyboardType(.numberPad)
                    .textFieldStyle(.roundedBorder)
                    .frame(width: 100)
            }
        }
        
        // スプリットデータ（固定距離ごと、例：500m）
        Section(header: Text("スプリットデータ")) {
            Picker("スプリット間隔", selection: $splitInterval) {
                Text("100m").tag(100)
                Text("200m").tag(200)
                Text("500m").tag(500)
            }
            
            Button("スプリットを追加") {
                let newOrdinal = splits.count + 1
                splits.append(SplitDataInput(ordinalNumber: newOrdinal))
            }
            
            ForEach($splits) { $split in
                VStack(alignment: .leading, spacing: 8) {
                    Text("スプリット \(split.ordinalNumber)")
                        .font(.headline)
                    
                    HStack {
                        Text("距離 (m)")
                        Spacer()
                        TextField("0", value: $split.distance, format: .number)
                            .keyboardType(.numberPad)
                            .textFieldStyle(.roundedBorder)
                            .frame(width: 100)
                    }
                    TimeInputView(totalSeconds: Binding(
                        get: { split.elapsedTime },
                        set: { split.elapsedTime = $0 }
                    ), label: "経過時間")
                    PaceInputView(totalSeconds: Binding(
                        get: { split.averagePace },
                        set: { split.averagePace = $0 }
                    ), label: "平均ペース")
                    HStack {
                        Text("平均SPM")
                        Spacer()
                        TextField("0.0", value: $split.averageSPM, format: .number)
                            .keyboardType(.decimalPad)
                            .textFieldStyle(.roundedBorder)
                            .frame(width: 100)
                    }
                    HStack {
                        Text("平均パワー (W)")
                        Spacer()
                        TextField("0", value: $split.averageWatts, format: .number)
                            .keyboardType(.numberPad)
                            .textFieldStyle(.roundedBorder)
                            .frame(width: 100)
                    }
                }
                .padding(.vertical, 4)
            }
            .onDelete(perform: deleteSplits)
        }
    }
    
    // MARK: - Single Time Section
    @ViewBuilder
    private func singleTimeSection() -> some View {
        // ターゲット時間設定
        Section(header: Text("ターゲット設定")) {
            ForEach($metrics) { $metric in
                if metric.unit == "sec" {
                    // 時間系メトリクスは分と秒で入力
                    TimeInputView(totalSeconds: Binding(
                        get: { Int(metric.value) },
                        set: { metric.value = Double($0) }
                    ), label: metric.name)
                } else {
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
                            .keyboardType(.numberPad)
                            .textFieldStyle(.roundedBorder)
                    }
                    .padding(.vertical, 4)
                }
            }
        }
        
        // ワークアウトサマリー
        Section(header: Text("ワークアウトサマリー")) {
            HStack {
                Text("総距離 (m)")
                Spacer()
                TextField("0", value: $totalDistance, format: .number)
                    .keyboardType(.numberPad)
                    .textFieldStyle(.roundedBorder)
                    .frame(width: 100)
            }
            TimeInputView(totalSeconds: $totalTime, label: "総時間")
            PaceInputView(totalSeconds: $averagePace, label: "平均ペース")
            HStack {
                Text("平均SPM")
                Spacer()
                TextField("0.0", value: $averageSPM, format: .number)
                    .keyboardType(.decimalPad)
                    .textFieldStyle(.roundedBorder)
                    .frame(width: 100)
            }
            HStack {
                Text("平均パワー (W)")
                Spacer()
                TextField("0", value: $averageWatts, format: .number)
                    .keyboardType(.numberPad)
                    .textFieldStyle(.roundedBorder)
                    .frame(width: 100)
            }
        }
        
        // スプリットデータ（固定時間ごと、例：5分）
        Section(header: Text("スプリットデータ")) {
            Picker("スプリット間隔", selection: $splitInterval) {
                Text("1分").tag(60)
                Text("5分").tag(300)
                Text("10分").tag(600)
            }
            
            Button("スプリットを追加") {
                let newOrdinal = splits.count + 1
                splits.append(SplitDataInput(ordinalNumber: newOrdinal))
            }
            
            ForEach($splits) { $split in
                VStack(alignment: .leading, spacing: 8) {
                    Text("スプリット \(split.ordinalNumber)")
                        .font(.headline)
                    
                    HStack {
                        Text("距離 (m)")
                        Spacer()
                        TextField("0", value: $split.distance, format: .number)
                            .keyboardType(.numberPad)
                            .textFieldStyle(.roundedBorder)
                            .frame(width: 100)
                    }
                    TimeInputView(totalSeconds: Binding(
                        get: { split.elapsedTime },
                        set: { split.elapsedTime = $0 }
                    ), label: "経過時間")
                    PaceInputView(totalSeconds: Binding(
                        get: { split.averagePace },
                        set: { split.averagePace = $0 }
                    ), label: "平均ペース")
                    HStack {
                        Text("平均SPM")
                        Spacer()
                        TextField("0.0", value: $split.averageSPM, format: .number)
                            .keyboardType(.decimalPad)
                            .textFieldStyle(.roundedBorder)
                            .frame(width: 100)
                    }
                    HStack {
                        Text("平均パワー (W)")
                        Spacer()
                        TextField("0", value: $split.averageWatts, format: .number)
                            .keyboardType(.numberPad)
                            .textFieldStyle(.roundedBorder)
                            .frame(width: 100)
                    }
                }
                .padding(.vertical, 4)
            }
            .onDelete(perform: deleteSplits)
        }
    }
    
    // MARK: - Distance Interval Section
    @ViewBuilder
    private func distanceIntervalSection() -> some View {
        // パラメータ設定
        Section(header: Text("パラメータ設定")) {
            ForEach($metrics) { $metric in
                if metric.unit == "sec" && metric.name == "レスト時間" {
                    // レスト時間は分と秒で入力
                    TimeInputView(totalSeconds: Binding(
                        get: { restTime },
                        set: { 
                            restTime = $0
                            metric.value = Double($0)
                        }
                    ), label: metric.name)
                } else if metric.unit == "sec" && metric.name == "設定時間" {
                    // 設定時間は分と秒で入力
                    TimeInputView(totalSeconds: Binding(
                        get: { Int(metric.value) },
                        set: { metric.value = Double($0) }
                    ), label: metric.name)
                } else {
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
                            .keyboardType(.numberPad)
                            .textFieldStyle(.roundedBorder)
                            .onChange(of: metric.value) { oldValue, newValue in
                                if metric.name == "設定距離" {
                                    // 設定距離が変更された場合の処理
                                } else if metric.name == "レスト時間" {
                                    restTime = Int(newValue)
                                }
                            }
                    }
                    .padding(.vertical, 4)
                }
            }
            
            HStack {
                Text("インターバル数")
                Spacer()
                TextField("1", value: $numberOfIntervals, format: .number)
                    .keyboardType(.numberPad)
                    .textFieldStyle(.roundedBorder)
                    .frame(width: 100)
                    .onChange(of: numberOfIntervals) { oldValue, newValue in
                        if newValue > splits.count {
                            // 新しいスプリットを追加（各インターバル = 1スプリット）
                            for i in (splits.count + 1)...newValue {
                                splits.append(SplitDataInput(ordinalNumber: i))
                            }
                        } else if newValue < splits.count {
                            // スプリットを削除
                            splits.removeLast(splits.count - newValue)
                        }
                    }
            }
        }
        
        // ワークアウトサマリー（作業時間のみ）
        Section(header: Text("ワークアウトサマリー（作業時間のみ）")) {
            HStack {
                Text("総距離 (m)")
                Spacer()
                TextField("0", value: $totalDistance, format: .number)
                    .keyboardType(.numberPad)
                    .textFieldStyle(.roundedBorder)
                    .frame(width: 100)
            }
            TimeInputView(totalSeconds: $totalTime, label: "総時間")
            PaceInputView(totalSeconds: $averagePace, label: "平均ペース")
            HStack {
                Text("平均SPM")
                Spacer()
                TextField("0.0", value: $averageSPM, format: .number)
                    .keyboardType(.decimalPad)
                    .textFieldStyle(.roundedBorder)
                    .frame(width: 100)
            }
            HStack {
                Text("平均パワー (W)")
                Spacer()
                TextField("0", value: $averageWatts, format: .number)
                    .keyboardType(.numberPad)
                    .textFieldStyle(.roundedBorder)
                    .frame(width: 100)
            }
        }
        
        // スプリットデータ（各インターバル = 1スプリット）
        Section(header: Text("スプリットデータ（各インターバル）")) {
            ForEach($splits) { $split in
                VStack(alignment: .leading, spacing: 8) {
                    Text("インターバル \(split.ordinalNumber)")
                        .font(.headline)
                    
                    HStack {
                        Text("距離 (m)")
                        Spacer()
                        TextField("0", value: $split.distance, format: .number)
                            .keyboardType(.numberPad)
                            .textFieldStyle(.roundedBorder)
                            .frame(width: 100)
                    }
                    TimeInputView(totalSeconds: Binding(
                        get: { split.elapsedTime },
                        set: { split.elapsedTime = $0 }
                    ), label: "経過時間")
                    PaceInputView(totalSeconds: Binding(
                        get: { split.averagePace },
                        set: { split.averagePace = $0 }
                    ), label: "平均ペース")
                    HStack {
                        Text("平均SPM")
                        Spacer()
                        TextField("0.0", value: $split.averageSPM, format: .number)
                            .keyboardType(.decimalPad)
                            .textFieldStyle(.roundedBorder)
                            .frame(width: 100)
                    }
                    HStack {
                        Text("平均パワー (W)")
                        Spacer()
                        TextField("0", value: $split.averageWatts, format: .number)
                            .keyboardType(.numberPad)
                            .textFieldStyle(.roundedBorder)
                            .frame(width: 100)
                    }
                }
                .padding(.vertical, 4)
            }
        }
    }
    
    // MARK: - Time Interval Section
    @ViewBuilder
    private func timeIntervalSection() -> some View {
        // パラメータ設定
        Section(header: Text("パラメータ設定")) {
            ForEach($metrics) { $metric in
                if metric.unit == "sec" && metric.name == "レスト時間" {
                    // レスト時間は分と秒で入力
                    TimeInputView(totalSeconds: Binding(
                        get: { restTime },
                        set: { 
                            restTime = $0
                            metric.value = Double($0)
                        }
                    ), label: metric.name)
                } else if metric.unit == "sec" && metric.name == "設定時間" {
                    // 設定時間は分と秒で入力
                    TimeInputView(totalSeconds: Binding(
                        get: { Int(metric.value) },
                        set: { metric.value = Double($0) }
                    ), label: metric.name)
                } else {
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
                            .keyboardType(.numberPad)
                            .textFieldStyle(.roundedBorder)
                            .onChange(of: metric.value) { oldValue, newValue in
                                if metric.name == "設定時間" {
                                    // 設定時間が変更された場合の処理
                                } else if metric.name == "レスト時間" {
                                    restTime = Int(newValue)
                                }
                            }
                    }
                    .padding(.vertical, 4)
                }
            }
            
            HStack {
                Text("インターバル数")
                Spacer()
                TextField("1", value: $numberOfIntervals, format: .number)
                    .keyboardType(.numberPad)
                    .textFieldStyle(.roundedBorder)
                    .frame(width: 100)
                    .onChange(of: numberOfIntervals) { oldValue, newValue in
                        if newValue > splits.count {
                            // 新しいスプリットを追加（各インターバル = 1スプリット）
                            for i in (splits.count + 1)...newValue {
                                splits.append(SplitDataInput(ordinalNumber: i))
                            }
                        } else if newValue < splits.count {
                            // スプリットを削除
                            splits.removeLast(splits.count - newValue)
                        }
                    }
            }
        }
        
        // ワークアウトサマリー（作業時間のみ）
        Section(header: Text("ワークアウトサマリー")) {
            HStack {
                Text("総距離 (m)")
                Spacer()
                TextField("0", value: $totalDistance, format: .number)
                    .keyboardType(.numberPad)
                    .textFieldStyle(.roundedBorder)
                    .frame(width: 100)
            }
            TimeInputView(totalSeconds: $totalTime, label: "総時間")
            PaceInputView(totalSeconds: $averagePace, label: "平均ペース")
            HStack {
                Text("平均SPM")
                Spacer()
                TextField("0.0", value: $averageSPM, format: .number)
                    .keyboardType(.decimalPad)
                    .textFieldStyle(.roundedBorder)
                    .frame(width: 100)
            }
            HStack {
                Text("平均パワー (W)")
                Spacer()
                TextField("0", value: $averageWatts, format: .number)
                    .keyboardType(.numberPad)
                    .textFieldStyle(.roundedBorder)
                    .frame(width: 100)
            }
        }
        
        // スプリットデータ（各インターバル = 1スプリット）
        Section(header: Text("スプリットデータ（各インターバル）")) {
            ForEach($splits) { $split in
                VStack(alignment: .leading, spacing: 8) {
                    Text("インターバル \(split.ordinalNumber)")
                        .font(.headline)
                    
                    HStack {
                        Text("距離 (m)")
                        Spacer()
                        TextField("0", value: $split.distance, format: .number)
                            .keyboardType(.numberPad)
                            .textFieldStyle(.roundedBorder)
                            .frame(width: 100)
                    }
                    TimeInputView(totalSeconds: Binding(
                        get: { split.elapsedTime },
                        set: { split.elapsedTime = $0 }
                    ), label: "経過時間")
                    PaceInputView(totalSeconds: Binding(
                        get: { split.averagePace },
                        set: { split.averagePace = $0 }
                    ), label: "平均ペース")
                    HStack {
                        Text("平均SPM")
                        Spacer()
                        TextField("0.0", value: $split.averageSPM, format: .number)
                            .keyboardType(.decimalPad)
                            .textFieldStyle(.roundedBorder)
                            .frame(width: 100)
                    }
                    HStack {
                        Text("平均パワー (W)")
                        Spacer()
                        TextField("0", value: $split.averageWatts, format: .number)
                            .keyboardType(.numberPad)
                            .textFieldStyle(.roundedBorder)
                            .frame(width: 100)
                    }
                }
                .padding(.vertical, 4)
            }
        }
    }
    
    // MARK: - Helper Functions
    private func formatSplit(_ value: Double) -> String {
        // Convert seconds to m:s format
        let minutes = Int(value) / 60
        let seconds = Int(value) % 60
        return "\(minutes):\(String(format: "%02d", seconds))"
    }
    
    private func parseSplit(_ text: String) -> Double {
        // Parse m:s format to seconds
        let components = text.split(separator: ":")
        if components.count == 2,
           let minutes = Double(components[0]),
           let seconds = Double(components[1]) {
            return minutes * 60 + seconds
        }
        return 0.0
    }
    
    private func deleteSplits(at offsets: IndexSet) {
        splits.remove(atOffsets: offsets)
        // スプリット番号を再割り当て
        for (index, _) in splits.enumerated() {
            splits[index].ordinalNumber = index + 1
        }
    }
    
    private func saveSession() {
        guard let workout = selectedWorkoutTemplate else { return }
        
        // Get target value from metrics
        let targetValue = Int(metrics.first?.value ?? 0)
        
        // Determine rest time for intervals
        let restTimeValue: Int? = (workout.category == .distanceInterval || workout.category == .timeInterval) ? restTime : nil
        
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
            session.workoutTemplate = workout
            session.workoutImageData = workoutImageData
            
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
            
            // Update or create WorkoutSummary
            if let existingSummary = session.workoutSummary {
                existingSummary.totalDistance = totalDistance
                existingSummary.totalTime = totalTime
                existingSummary.averagePace = averagePace
                existingSummary.averageSPM = averageSPM
                existingSummary.averageWatts = averageWatts
                existingSummary.workoutType = workout.category
                existingSummary.targetValue = targetValue
                existingSummary.restTime = restTimeValue
                existingSummary.date = date
                
                // Update splits
                existingSummary.splits.removeAll()
                for splitInput in splits {
                    let split = SplitData(
                        ordinalNumber: splitInput.ordinalNumber,
                        distance: splitInput.distance,
                        elapsedTime: splitInput.elapsedTime,
                        averagePace: splitInput.averagePace,
                        averageSPM: splitInput.averageSPM,
                        averageWatts: splitInput.averageWatts,
                        summary: existingSummary
                    )
                    existingSummary.splits.append(split)
                }
            } else {
                // Create new WorkoutSummary
                let summary = WorkoutSummary(
                    totalDistance: totalDistance,
                    totalTime: totalTime,
                    averagePace: averagePace,
                    averageSPM: averageSPM,
                    averageWatts: averageWatts,
                    workoutType: workout.category,
                    targetValue: targetValue,
                    restTime: restTimeValue,
                    date: date,
                    session: session
                )
                
                // Add splits
                for splitInput in splits {
                    let split = SplitData(
                        ordinalNumber: splitInput.ordinalNumber,
                        distance: splitInput.distance,
                        elapsedTime: splitInput.elapsedTime,
                        averagePace: splitInput.averagePace,
                        averageSPM: splitInput.averageSPM,
                        averageWatts: splitInput.averageWatts,
                        summary: summary
                    )
                    summary.splits.append(split)
                }
                
                session.workoutSummary = summary
            }
            
            do {
                try context.save()
            } catch {
                print("Failed to update training session: \(error)")
            }
        } else {
            // Create new session
            let boat = sessionType == .boat ? selectedBoat : (isShared ? nil : currentBoat)
            let newSession = TrainingSession(
                date: date,
                sessionType: sessionType,
                memo: memo,
                isShared: isShared,
                boat: boat,
                workoutTemplate: workout,
                workoutImageData: workoutImageData
            )
            
            // Create WorkoutSummary
            let summary = WorkoutSummary(
                totalDistance: totalDistance,
                totalTime: totalTime,
                averagePace: averagePace,
                averageSPM: averageSPM,
                averageWatts: averageWatts,
                workoutType: workout.category,
                targetValue: targetValue,
                restTime: restTimeValue,
                date: date,
                session: newSession
            )
            
            // Add splits
            for splitInput in splits {
                let split = SplitData(
                    ordinalNumber: splitInput.ordinalNumber,
                    distance: splitInput.distance,
                    elapsedTime: splitInput.elapsedTime,
                    averagePace: splitInput.averagePace,
                    averageSPM: splitInput.averageSPM,
                    averageWatts: splitInput.averageWatts,
                    summary: summary
                )
                summary.splits.append(split)
            }
            
            newSession.workoutSummary = summary
            
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

