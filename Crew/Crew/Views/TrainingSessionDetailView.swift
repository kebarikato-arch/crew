import SwiftUI
import SwiftData

struct TrainingSessionDetailView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context
    @Bindable var session: TrainingSession
    @Binding var currentBoat: Boat
    
    @State private var showingEditView = false
    
    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("基本情報")) {
                    HStack {
                        Text("日時")
                        Spacer()
                        Text(session.date, style: .date)
                            .foregroundColor(.secondary)
                        Text(session.date, style: .time)
                            .foregroundColor(.secondary)
                    }
                    
                    HStack {
                        Text("タイプ")
                        Spacer()
                        Text(session.sessionType.rawValue)
                            .foregroundColor(.secondary)
                    }
                    
                    if let workout = session.workoutTemplate {
                        HStack {
                            Text("ワークアウト")
                            Spacer()
                            Text(workout.name)
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    if let boat = session.boat {
                        HStack {
                            Text("ボート")
                            Spacer()
                            Text(boat.name)
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    if session.isShared {
                        HStack {
                            Text("共有")
                            Spacer()
                            Image(systemName: "person.2.fill")
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    if !session.memo.isEmpty {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("メモ")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Text(session.memo)
                        }
                    }
                }
                
                if let data = session.workoutImageData, let uiImage = UIImage(data: data) {
                    Section(header: Text("添付画像")) {
                        Image(uiImage: uiImage)
                            .resizable()
                            .scaledToFit()
                            .cornerRadius(8)
                            .frame(maxHeight: 240)
                    }
                }
                
                // Workout Summary
                if let summary = session.workoutSummary {
                    Section(header: Text("ワークアウトサマリー")) {
                        HStack {
                            Text("総距離")
                            Spacer()
                            Text("\(summary.totalDistance) m")
                                .foregroundColor(.secondary)
                        }
                        HStack {
                            Text("総時間")
                            Spacer()
                            Text(summary.formattedElapsedTime)
                                .foregroundColor(.secondary)
                        }
                        HStack {
                            Text("平均ペース")
                            Spacer()
                            Text(summary.formattedPace)
                                .foregroundColor(.secondary)
                        }
                        HStack {
                            Text("平均SPM")
                            Spacer()
                            Text("\(summary.averageSPM, specifier: "%.1f") spm")
                                .foregroundColor(.secondary)
                        }
                        HStack {
                            Text("平均パワー")
                            Spacer()
                            Text("\(summary.averageWatts) W")
                                .foregroundColor(.secondary)
                        }
                        if let restTime = summary.restTime {
                            HStack {
                                Text("レスト時間")
                                Spacer()
                                Text("\(restTime) 秒")
                                    .foregroundColor(.secondary)
                            }
                        }
                        HStack {
                            Text("ターゲット値")
                            Spacer()
                            Text("\(summary.targetValue)")
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    // Split Data
                    if !summary.splits.isEmpty {
                        Section(header: Text("スプリットデータ")) {
                            ForEach(summary.splits.sorted { $0.ordinalNumber < $1.ordinalNumber }) { split in
                                VStack(alignment: .leading, spacing: 4) {
                                    HStack {
                                        Text("スプリット \(split.ordinalNumber)")
                                            .font(.headline)
                                        Spacer()
                                    }
                                    HStack {
                                        Text("距離:")
                                        Spacer()
                                        Text("\(split.distance) m")
                                            .foregroundColor(.secondary)
                                    }
                                    HStack {
                                        Text("経過時間:")
                                        Spacer()
                                        Text(split.formattedElapsedTime)
                                            .foregroundColor(.secondary)
                                    }
                                    HStack {
                                        Text("平均ペース:")
                                        Spacer()
                                        Text(split.formattedPace)
                                            .foregroundColor(.secondary)
                                    }
                                    HStack {
                                        Text("平均SPM:")
                                        Spacer()
                                        Text("\(split.averageSPM, specifier: "%.1f") spm")
                                            .foregroundColor(.secondary)
                                    }
                                    HStack {
                                        Text("平均パワー:")
                                        Spacer()
                                        Text("\(split.averageWatts) W")
                                            .foregroundColor(.secondary)
                                    }
                                }
                                .padding(.vertical, 4)
                            }
                        }
                    }
                } else {
                    Section(header: Text("ワークアウトデータ")) {
                        Text("データがありません")
                            .foregroundColor(.secondary)
                    }
                }
            }
            .navigationTitle("トレーニング詳細")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        Button("編集") {
                            showingEditView = true
                        }
                        
                        if session.sessionType == .ergo {
                            Button(session.isShared ? "共有を解除" : "共有する") {
                                toggleSharing()
                            }
                        }
                        
                        Button("削除", role: .destructive) {
                            deleteSession()
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                    }
                }
            }
            .sheet(isPresented: $showingEditView) {
                AddTrainingSessionView(currentBoat: currentBoat, sessionToEdit: session)
            }
        }
    }
    
    private func toggleSharing() {
        if session.isShared {
            // Unshare: associate with current boat
            if let oldBoat = session.boat {
                oldBoat.trainingSessions.removeAll { $0.id == session.id }
            }
            session.boat = currentBoat
            currentBoat.trainingSessions.append(session)
            session.isShared = false
        } else {
            // Share: remove boat relationship
            if let oldBoat = session.boat {
                oldBoat.trainingSessions.removeAll { $0.id == session.id }
            }
            session.boat = nil
            session.isShared = true
        }
        
        do {
            try context.save()
        } catch {
            print("Failed to toggle sharing: \(error)")
        }
    }
    
    private func deleteSession() {
        context.delete(session)
        dismiss()
    }
    
}

