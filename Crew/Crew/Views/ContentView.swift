import SwiftUI
import SwiftData

struct ContentView: View {
    @Query(sort: \Boat.name) private var boats: [Boat]

    var body: some View {
        if boats.isEmpty {
            WelcomeView()
        } else {
            MainAppView(boats: boats)
        }
    }
}

struct MainAppView: View {
    let boats: [Boat]
    @AppStorage("selectedBoatId") private var selectedBoatId: String?

    private var currentBoat: Boat? {
        if let boatId = selectedBoatId,
           let boat = boats.first(where: { $0.id.uuidString == boatId }) {
            return boat
        }
        return boats.first
    }
    
    private var boatBinding: Binding<Boat> {
        Binding<Boat>(
            get: { currentBoat! },
            set: { newBoat in selectedBoatId = newBoat.id.uuidString }
        )
    }

    var body: some View {
        TabView {
            HomeView(currentBoat: boatBinding)
                .tabItem { Label("My Rig", systemImage: "ferry.fill") }

            CheckListView(currentBoat: boatBinding)
                .tabItem { Label("Checklist", systemImage: "list.bullet.clipboard.fill") }
            
            DataView(currentBoat: boatBinding)
                .tabItem { Label("Data", systemImage: "chart.xyaxis.line") }
            
            SettingView(currentBoat: boatBinding)
                .tabItem { Label("Setting", systemImage: "gear") }
        }
        .task(id: boats.count) {
            if !boats.contains(where: { $0.id.uuidString == selectedBoatId }) {
                selectedBoatId = boats.first?.id.uuidString
            }
        }
    }
}
