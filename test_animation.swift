import SwiftUI

struct TestView: View {
    @State private var isTabBarHidden = false
    var body: some View {
        TabView {
            NavigationStack {
                VStack {
                    NavigationLink("Push", destination: Text("Detail").toolbar(isTabBarHidden ? .hidden : .visible, for: .tabBar))
                    Button("Toggle") {
                        withAnimation {
                            isTabBarHidden.toggle()
                        }
                    }
                }
            }
            .tabItem { Text("Tab") }
        }
    }
}
