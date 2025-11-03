import SwiftUI
import SwiftData

struct HomeView: View {
    @Query(sort: \Boat.name) private var boats: [Boat]
    @Binding var currentBoat: Boat
    
    @State private var showingAddRigDataView = false
    @State private var isAddingBoat = false
    @State private var showingHistory = false
    @State private var showingFabOptions = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                if boats.count > 1 {
                    Picker("ボートを選択", selection: $currentBoat) {
                        ForEach(boats) { boat in
                            Text(boat.name).tag(boat)
                        }
                    }
                    .pickerStyle(.segmented)
                    .padding(.horizontal)
                }

                ScrollView {
                    VStack(spacing: 16) {
                        if currentBoat.rigDataSets.isEmpty {
                            VStack(spacing: 12) {
                                Image(systemName: "chart.line.uptrend.xyaxis")
                                    .font(.system(size: 40))
                                    .foregroundColor(.secondary)
                                
                                Text("リグデータがありません")
                                    .font(.headline)
                                    .foregroundColor(.secondary)
                                
                                Text("最初のリグデータを記録しましょう")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                
                                Button("リグデータを記録") {
                                    showingAddRigDataView = true
                                }
                                .buttonStyle(.borderedProminent)
                                .padding(.top, 8)
                            }
                            .padding()
                        } else {
                            // 最新のリグデータを取得
                            if let latestDataSet = currentBoat.rigDataSets.sorted(by: { $0.date > $1.date }).first {
                                VStack(spacing: 12) {
                                    // メモを表示
                                    if !latestDataSet.memo.isEmpty {
                                        VStack(alignment: .leading, spacing: 8) {
                                            HStack {
                                                Image(systemName: "note.text")
                                                    .foregroundColor(.blue)
                                                    .font(.title3)
                                                Text("メモ")
                                                    .font(.headline)
                                                    .fontWeight(.semibold)
                                                Spacer()
                                            }
                                            
                                            Text(latestDataSet.memo)
                                                .font(.body)
                                                .foregroundColor(.primary)
                                                .multilineTextAlignment(.leading)
                                                .frame(maxWidth: .infinity, alignment: .leading)
                                        }
                                        .padding(16)
                                        .background(
                                            RoundedRectangle(cornerRadius: 12)
                                                .fill(Color(.systemBackground))
                                                .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
                                        )
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 12)
                                                .stroke(Color.blue.opacity(0.2), lineWidth: 1)
                                        )
                                    }
                                    
                                    // リグアイテムをカード形式で表示
                                    LazyVGrid(columns: [
                                        GridItem(.flexible()),
                                        GridItem(.flexible())
                                    ], spacing: 12) {
                                        ForEach(latestDataSet.rigItems, id: \.id) { item in
                                            RigItemCard(item: item)
                                        }
                                    }
                                }
                            }
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle("My Rig")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    if !currentBoat.rigDataSets.isEmpty {
                        Button("履歴") { showingHistory = true }
                    }
                }
            }
            .sheet(isPresented: $isAddingBoat) {
                AddBoatView()
            }
            .sheet(isPresented: $showingAddRigDataView) {
                AddRigDataView(boat: currentBoat)
            }
            .sheet(isPresented: $showingHistory) {
                RigHistoryView(currentBoat: $currentBoat)
            }
            .overlay(alignment: .bottom) {
                Button(action: { showingFabOptions = true }) {
                    Image(systemName: "plus")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(.white)
                        .frame(width: 56, height: 56)
                        .background(
                            Circle()
                                .fill(Color.accentColor)
                        )
                        .shadow(color: .black.opacity(0.2), radius: 6, x: 0, y: 4)
                }
                .padding(.bottom, 24)
            }
            // Compact options popup at bottom (no full-screen dim)
            .overlay(alignment: .bottom) {
                if showingFabOptions {
                    ZStack(alignment: .bottom) {
                        // Invisible hit-area to dismiss when tapping outside
                        Color.clear
                            .ignoresSafeArea()
                            .contentShape(Rectangle())
                            .onTapGesture { withAnimation(.spring()) { showingFabOptions = false } }

                        VStack(spacing: 8) {
                        Button(action: {
                            showingFabOptions = false
                            showingAddRigDataView = true
                        }) {
                            HStack(spacing: 10) {
                                Image(systemName: "square.and.pencil")
                                    .font(.system(size: 18, weight: .semibold))
                                    .foregroundColor(.accentColor)
                                Text("リグデータを記録")
                                    .font(.subheadline)
                                    .foregroundColor(.primary)
                                Spacer(minLength: 0)
                            }
                            .padding(.vertical, 10)
                            .padding(.horizontal, 14)
                            .background(
                                RoundedRectangle(cornerRadius: 14, style: .continuous)
                                    .fill(.ultraThinMaterial)
                            )
                        }

                        Button(action: {
                            showingFabOptions = false
                            isAddingBoat = true
                        }) {
                            HStack(spacing: 10) {
                                Image(systemName: "person.badge.plus")
                                    .font(.system(size: 18, weight: .semibold))
                                    .foregroundColor(.accentColor)
                                Text("ボートを追加")
                                    .font(.subheadline)
                                    .foregroundColor(.primary)
                                Spacer(minLength: 0)
                            }
                            .padding(.vertical, 10)
                            .padding(.horizontal, 14)
                            .background(
                                RoundedRectangle(cornerRadius: 14, style: .continuous)
                                    .fill(.ultraThinMaterial)
                            )
                        }
                        }
                        .padding(.bottom, 100)
                        .padding(.horizontal, 24)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                        .animation(.spring(response: 0.35, dampingFraction: 0.9), value: showingFabOptions)
                    }
                }
            }
        }
    }
}

// 2隻目以降のボート追加用のビュー
struct AddBoatView: View {
    @Environment(\.dismiss) var dismiss
    @Environment(\.modelContext) private var modelContext
    @State private var boatName: String = ""
    
    var body: some View {
        NavigationView {
            Form {
                Section { TextField("ボート名", text: $boatName) }
                Section {
                    Button("保存") { addBoat(); dismiss() }
                    .disabled(boatName.isEmpty)
                }
            }
            .navigationTitle("新しいボート")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("キャンセル") { dismiss() } }
            }
        }
    }
    
    private func addBoat() {
        let newBoat = Boat(name: boatName)
        modelContext.insert(newBoat)
    }
}
