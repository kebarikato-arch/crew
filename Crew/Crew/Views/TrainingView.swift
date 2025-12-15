import SwiftUI
import SwiftData

struct TrainingView: View {
    @Binding var currentBoat: Boat
    @Environment(\.modelContext) private var context
    @State private var allSessions: [TrainingSession] = []
    @State private var selectedSessionType: SessionType? = nil
    @State private var showingAddSession = false
    @State private var sessionToEdit: TrainingSession?
    
    private var filteredSessions: [TrainingSession] {
        let sessions = allSessions.filter { (session: TrainingSession) -> Bool in
            // Show boat-specific sessions
            if let boat = session.boat, boat.id == currentBoat.id {
                return selectedSessionType == nil || session.sessionType == selectedSessionType
            }
            // Show shared Ergo sessions (boat is nil and isShared is true)
            if session.boat == nil && session.isShared && session.sessionType == SessionType.ergo {
                return selectedSessionType == nil || selectedSessionType == SessionType.ergo
            }
            return false
        }
        return sessions.sorted { (first: TrainingSession, second: TrainingSession) -> Bool in
            first.date > second.date
        }
    }
    
    private var sessionsByDate: [Date: [TrainingSession]] {
        Dictionary(grouping: filteredSessions) { (session: TrainingSession) -> Date in
            Calendar.current.startOfDay(for: session.date)
        }
    }
    
    private var sortedDates: [Date] {
        sessionsByDate.keys.sorted(by: >)
    }
    
    private var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ja_JP")
        formatter.dateStyle = .long
        return formatter
    }
    
    var body: some View {
        NavigationStack {
            Group {
                if filteredSessions.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "figure.rowing")
                            .font(.system(size: 60))
                            .foregroundColor(.secondary)
                        
                        Text("トレーニング記録がありません")
                            .font(.headline)
                            .foregroundColor(.secondary)
                        
                        Text("トレーニングセッションを記録しましょう")
                            .font(.body)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    List {
                        ForEach(sortedDates, id: \.self) { date in
                            Section(header: Text(dateFormatter.string(from: date))) {
                                ForEach(sessionsByDate[date] ?? [], id: \.id) { (session: TrainingSession) in
                                    TrainingSessionRow(session: session) {
                                        sessionToEdit = session
                                    }
                                }
                                .onDelete { offsets in
                                    deleteSessions(at: offsets, for: date)
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("トレーニング")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Menu {
                        Button("すべて") {
                            selectedSessionType = nil
                        }
                        Button("エルゴ") {
                            selectedSessionType = SessionType.ergo
                        }
                        Button("ボート") {
                            selectedSessionType = SessionType.boat
                        }
                    } label: {
                        Image(systemName: "line.3.horizontal.decrease.circle")
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        sessionToEdit = nil
                        showingAddSession = true
                    }) {
                        Image(systemName: "plus")
                    }
                }
            }
        }
        .onAppear {
            loadSessions()
        }
        .onChange(of: currentBoat.id.uuidString) { _, _ in
            loadSessions()
        }
        .sheet(isPresented: $showingAddSession) {
            AddTrainingSessionView(currentBoat: currentBoat, sessionToEdit: sessionToEdit)
                .onDisappear {
                    loadSessions()
                }
        }
        .sheet(item: $sessionToEdit) { session in
            TrainingSessionDetailView(session: session, currentBoat: $currentBoat)
                .onDisappear {
                    loadSessions()
                }
        }
    }
    
    private func loadSessions() {
        let keyPath = \TrainingSession.date
        let sortDescriptor = SortDescriptor<TrainingSession>(keyPath, order: .reverse)
        let descriptor = FetchDescriptor<TrainingSession>(
            sortBy: [sortDescriptor]
        )
        do {
            allSessions = try context.fetch(descriptor)
        } catch {
            print("Failed to fetch training sessions: \(error)")
            allSessions = []
        }
    }
    
    private func deleteSessions(at offsets: IndexSet, for date: Date) {
        guard let sessionsForDate = sessionsByDate[date] else { return }
        let sessionsToDelete = offsets.map { sessionsForDate[$0] }
        for session in sessionsToDelete {
            context.delete(session)
        }
        do {
            try context.save()
            loadSessions()
        } catch {
            print("Failed to delete sessions: \(error)")
        }
    }
}

struct TrainingSessionRow: View {
    let session: TrainingSession
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack {
                // Session type badge
                Text(session.sessionType.rawValue)
                    .font(.caption)
                    .fontWeight(.semibold)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(
                        Capsule()
                            .fill(session.sessionType == SessionType.ergo ? Color.orange.opacity(0.2) : Color.blue.opacity(0.2))
                    )
                    .foregroundColor(session.sessionType == SessionType.ergo ? .orange : .blue)
                
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(session.date, style: .time)
                            .font(.headline)
                        if session.isShared {
                            Image(systemName: "person.2.fill")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    // ワークアウト名を表示
                    if let workout = session.workoutTemplate {
                        Text(workout.name)
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(.primary)
                    }
                    
                    if !session.memo.isEmpty {
                        Text(session.memo)
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                    }
                    
                    if let summary = session.workoutSummary {
                        let totalDistance = summary.totalDistance
                        let elapsedTime = summary.formattedElapsedTime
                        let pace = summary.formattedPace
                        HStack(spacing: 8) {
                            Text("距離: \(totalDistance)m")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                            Text("時間: \(elapsedTime)")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                            Text("ペース: \(pace)")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                
                Spacer()
            }
            .padding(.vertical, 4)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

