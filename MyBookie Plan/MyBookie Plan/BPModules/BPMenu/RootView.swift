#Preview {
    RootView()
        .environmentObject(AppStore())
}
// MARK: - Root

struct RootView: View {
    @EnvironmentObject private var store: AppStore

    var body: some View {
        if store.isLoggedIn {
            MainTabView()
        } else {
            AuthenticationView()
        }
    }
}