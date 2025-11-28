import SwiftUI

/// 分と秒を分けて入力できる時間入力コンポーネント
struct TimeInputView: View {
    @Binding var totalSeconds: Int
    let label: String
    
    @State private var minutes: Int = 0
    @State private var seconds: Int = 0
    
    var body: some View {
        HStack {
            Text(label)
            Spacer()
            
            HStack(spacing: 4) {
                TextField("分", value: $minutes, format: .number)
                    .keyboardType(.numberPad)
                    .textFieldStyle(.roundedBorder)
                    .frame(width: 60)
                    .onChange(of: minutes) { oldValue, newValue in
                        updateTotalSeconds()
                    }
                
                Text("分")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                TextField("秒", value: $seconds, format: .number)
                    .keyboardType(.numberPad)
                    .textFieldStyle(.roundedBorder)
                    .frame(width: 60)
                    .onChange(of: seconds) { oldValue, newValue in
                        if newValue >= 60 {
                            minutes += newValue / 60
                            seconds = newValue % 60
                        }
                        updateTotalSeconds()
                    }
                
                Text("秒")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .onAppear {
            updateFromTotalSeconds()
        }
        .onChange(of: totalSeconds) { oldValue, newValue in
            if oldValue != newValue {
                updateFromTotalSeconds()
            }
        }
    }
    
    private func updateTotalSeconds() {
        totalSeconds = minutes * 60 + seconds
    }
    
    private func updateFromTotalSeconds() {
        minutes = totalSeconds / 60
        seconds = totalSeconds % 60
    }
}

/// ペース（MM:SS / 500m）を分と秒で入力できるコンポーネント
struct PaceInputView: View {
    @Binding var totalSeconds: Int // 秒/500m
    let label: String
    
    @State private var minutes: Int = 0
    @State private var seconds: Int = 0
    
    var body: some View {
        HStack {
            Text(label)
            Spacer()
            
            HStack(spacing: 4) {
                TextField("分", value: $minutes, format: .number)
                    .keyboardType(.numberPad)
                    .textFieldStyle(.roundedBorder)
                    .frame(width: 60)
                    .onChange(of: minutes) { oldValue, newValue in
                        updateTotalSeconds()
                    }
                
                Text(":")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                TextField("秒", value: $seconds, format: .number)
                    .keyboardType(.numberPad)
                    .textFieldStyle(.roundedBorder)
                    .frame(width: 60)
                    .onChange(of: seconds) { oldValue, newValue in
                        if newValue >= 60 {
                            minutes += newValue / 60
                            seconds = newValue % 60
                        }
                        updateTotalSeconds()
                    }
                
                Text("/ 500m")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .onAppear {
            updateFromTotalSeconds()
        }
        .onChange(of: totalSeconds) { oldValue, newValue in
            if oldValue != newValue {
                updateFromTotalSeconds()
            }
        }
    }
    
    private func updateTotalSeconds() {
        totalSeconds = minutes * 60 + seconds
    }
    
    private func updateFromTotalSeconds() {
        minutes = totalSeconds / 60
        seconds = totalSeconds % 60
    }
}

