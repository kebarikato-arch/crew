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
                
                Section(header: Text("メトリクス")) {
                    if session.metrics.isEmpty {
                        Text("メトリクスがありません")
                            .foregroundColor(.secondary)
                    } else {
                        ForEach(session.metrics) { metric in
                            HStack {
                                Text(metric.name)
                                Spacer()
                                Text("\(metric.value, specifier: "%.2f") \(metric.unit)")
                                    .foregroundColor(.secondary)
                            }
                        }
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

