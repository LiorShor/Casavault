import Testing
import ComposableArchitecture
import CoreData
@testable import Casavault

@Suite("PasswordsCollection")
@MainActor
struct PasswordsCollectionTests {
    typealias Reducer = PasswordsCollection

    private let context = TestCoreDataStack.makeContext()

    private func makeStore(
        initialState: Reducer.State = .init(),
        dependencies: (inout DependencyValues) -> Void = { _ in }
    ) -> TestStoreOf<Reducer> {
        TestStore(initialState: initialState) {
            Reducer()
        } withDependencies: {
            $0.homeUseCases.fetchHomes = { [] }
            $0.homeUseCases.addHome = { _ in }
            $0.homeUseCases.removeHome = { _ in }
            $0.homeUseCases.updateHome = { _ in }
            $0.homeUseCases.setDefaultHome = { _ in }
            $0.homeUseCases.getDefaultHome = { nil }
            $0.homeUseCases.importFromHomeKit = { [] }
            $0.passwordsUseCases.fetchPasswords = { [] }
            $0.passwordsUseCases.fetchPasswordsForHome = { _ in [] }
            $0.passwordsUseCases.addPassword = { _ in }
            $0.passwordsUseCases.removePassword = { _ in }
            $0.passwordsUseCases.updatePassword = { _ in }
            $0.databaseService.context = { [context] in context }
            $0.databaseService.saveContext = {}
            dependencies(&$0)
        }
    }

    // MARK: - State: filteredPasswords

    @Test("filteredPasswords returns all when search is empty")
    func testFilteredPasswordsEmpty() {
        let p1 = makeTestPassword(in: context, name: "Lock")
        let p2 = makeTestPassword(in: context, name: "Light")
        var state = Reducer.State()
        state.passwords = [p1, p2]
        state.searchText = ""

        #expect(state.filteredPasswords == [p1, p2])
    }

    @Test("filteredPasswords filters by name (case-insensitive)")
    func testFilteredPasswordsByName() {
        let lock = makeTestPassword(in: context, name: "Smart Lock")
        let light = makeTestPassword(in: context, name: "Smart Light")
        let thermostat = makeTestPassword(in: context, name: "Thermostat")
        var state = Reducer.State()
        state.passwords = [lock, light, thermostat]
        state.searchText = "smart"

        #expect(state.filteredPasswords == [lock, light])
    }

    @Test("filteredPasswords filters by room")
    func testFilteredPasswordsByRoom() {
        let bedroomLight = makeTestPassword(in: context, name: "Light", room: "Bedroom")
        let kitchenLight = makeTestPassword(in: context, name: "Light", room: "Kitchen")
        var state = Reducer.State()
        state.passwords = [bedroomLight, kitchenLight]
        state.searchText = "Bedroom"

        #expect(state.filteredPasswords == [bedroomLight])
    }

    // MARK: - State: groupedPasswords

    @Test("groupedPasswords mode .all returns a single group")
    func testGroupedPasswordsAll() {
        let p1 = makeTestPassword(in: context, name: "Lock", room: "Entry")
        let p2 = makeTestPassword(in: context, name: "Light", room: "Bedroom")
        var state = Reducer.State()
        state.passwords = [p1, p2]
        state.groupingMode = .all

        let grouped = state.groupedPasswords
        #expect(grouped.keys.count == 1)
        #expect(grouped["All"]?.count == 2)
    }

    @Test("groupedPasswords mode .byRoom groups by room")
    func testGroupedPasswordsByRoom() {
        let bedroomLight = makeTestPassword(in: context, name: "Light", room: "Bedroom")
        let bedroomLock = makeTestPassword(in: context, name: "Lock", room: "Bedroom")
        let kitchenLight = makeTestPassword(in: context, name: "Light", room: "Kitchen")
        var state = Reducer.State()
        state.passwords = [bedroomLight, bedroomLock, kitchenLight]
        state.groupingMode = .byRoom

        let grouped = state.groupedPasswords
        #expect(grouped["Bedroom"]?.count == 2)
        #expect(grouped["Kitchen"]?.count == 1)
    }

    @Test("groupedPasswords puts passwords without a room under the no-room key")
    func testGroupedPasswordsNoRoom() {
        let noRoomDevice = makeTestPassword(in: context, name: "Sensor", room: nil)
        var state = Reducer.State()
        state.passwords = [noRoomDevice]
        state.groupingMode = .byRoom

        let grouped = state.groupedPasswords
        let noRoomKey = String.localized(.noRoom)
        #expect(grouped[noRoomKey]?.count == 1)
    }

    // MARK: - State: sortedRoomNames

    @Test("sortedRoomNames puts the no-room key last")
    func testSortedRoomNamesNoRoomLast() {
        let noRoomDevice = makeTestPassword(in: context, name: "Sensor", room: nil)
        let bedroomLight = makeTestPassword(in: context, name: "Light", room: "Bedroom")
        var state = Reducer.State()
        state.passwords = [noRoomDevice, bedroomLight]
        state.groupingMode = .byRoom

        let names = state.sortedRoomNames
        #expect(names.last == String.localized(.noRoom))
        #expect(names.first == "Bedroom")
    }

    // MARK: - Reducer: view mode

    @Test("toggleViewMode switches from list to grid")
    func testToggleViewModeListToGrid() async {
        let store = makeStore(initialState: .init(viewMode: .list))

        await store.send(.view(.toggleViewMode)) {
            $0.viewMode = .grid
        }
    }

    @Test("toggleViewMode switches from grid to list")
    func testToggleViewModeGridToList() async {
        let store = makeStore(initialState: .init(viewMode: .grid))

        await store.send(.view(.toggleViewMode)) {
            $0.viewMode = .list
        }
    }

    // MARK: - Reducer: grouping mode

    @Test("groupingModeChanged updates grouping mode")
    func testGroupingModeChanged() async {
        let store = makeStore()

        await store.send(.view(.groupingModeChanged(.byRoom))) {
            $0.groupingMode = .byRoom
        }
    }

    // MARK: - Reducer: edit mode

    @Test("toggleEditMode turns edit mode on")
    func testToggleEditModeOn() async {
        let store = makeStore()

        await store.send(.view(.toggleEditMode)) {
            $0.isEditMode = true
        }
    }

    @Test("toggleEditMode turns edit mode off and clears dragging")
    func testToggleEditModeOffClearsDragging() async {
        let password = makeTestPassword(in: context, name: "Lock")

        var initialState = Reducer.State()
        initialState.isEditMode = true
        initialState.draggingPassword = password

        let store = makeStore(initialState: initialState)

        await store.send(.view(.toggleEditMode)) {
            $0.isEditMode = false
            $0.draggingPassword = nil
        }
    }

    // MARK: - Reducer: dragging

    @Test("startDragging sets the dragging password")
    func testStartDragging() async {
        let password = makeTestPassword(in: context, name: "Lock")
        let store = makeStore()

        await store.send(.view(.startDragging(password))) {
            $0.draggingPassword = password
        }
    }

    @Test("endDragging clears the dragging password")
    func testEndDragging() async {
        let password = makeTestPassword(in: context, name: "Lock")

        var initialState = Reducer.State()
        initialState.draggingPassword = password

        let store = makeStore(initialState: initialState)

        await store.send(.view(.endDragging)) {
            $0.draggingPassword = nil
        }
    }

    // MARK: - Reducer: search

    @Test("searchTextChanged updates the search text")
    func testSearchTextChanged() async {
        let store = makeStore()

        await store.send(.view(.searchTextChanged("bedroom"))) {
            $0.searchText = "bedroom"
        }
    }

    // MARK: - Reducer: home selection

    @Test("homeSelected updates currentHomeId and loads passwords")
    func testHomeSelected() async {
        let homeId = UUID()
        let password = makeTestPassword(in: context, name: "Lock", homeId: homeId)

        let store = makeStore {
            $0.passwordsUseCases.fetchPasswordsForHome = { _ in [password] }
        }

        await store.send(.view(.homeSelected(homeId))) {
            $0.currentHomeId = homeId
        }
        await store.receive(.itemsLoaded([password])) {
            $0.passwords = [password]
        }
    }

    // MARK: - Reducer: defaultHomeLoaded

    @Test("defaultHomeLoaded with nil clears currentHomeId")
    func testDefaultHomeLoadedNil() async {
        var initialState = Reducer.State()
        initialState.currentHomeId = UUID()

        let store = makeStore(initialState: initialState)

        await store.send(.defaultHomeLoaded(nil)) {
            $0.currentHomeId = nil
        }
    }

    @Test("defaultHomeLoaded with a home sets currentHomeId and fetches passwords")
    func testDefaultHomeLoaded() async {
        let home = makeTestHome(in: context, name: "My Home")
        let password = makeTestPassword(in: context, name: "Lock", homeId: home.id)

        let store = makeStore {
            $0.passwordsUseCases.fetchPasswordsForHome = { _ in [password] }
        }

        await store.send(.defaultHomeLoaded(home)) {
            $0.currentHomeId = home.id
        }
        await store.receive(.itemsLoaded([password])) {
            $0.passwords = [password]
        }
    }

    // MARK: - Reducer: delete password

    @Test("onDeletePassword removes the password and reloads")
    func testOnDeletePassword() async {
        let homeId = UUID()
        let password = makeTestPassword(in: context, name: "Lock", homeId: homeId)
        var removedPassword: Password?

        var initialState = Reducer.State()
        initialState.passwords = [password]
        initialState.currentHomeId = homeId

        let store = makeStore(initialState: initialState) {
            $0.passwordsUseCases.removePassword = { p in removedPassword = p }
            $0.passwordsUseCases.fetchPasswordsForHome = { _ in [] }
        }

        await store.send(.view(.onDeletePassword(password)))
        await store.receive(.itemsLoaded([])) {
            $0.passwords = []
        }

        #expect(removedPassword == password)
    }

    // MARK: - Reducer: navigation

    @Test("onAddPasswordButtonTapped emits navigation action")
    func testOnAddPasswordButtonTapped() async {
        let store = makeStore()
        await store.send(.view(.onAddPasswordButtonTapped))
        await store.receive(.navigation(.onAddPassword))
    }

    @Test("onImportFromHomeKitButtonTapped emits navigation action")
    func testOnImportFromHomeKitButtonTapped() async {
        let store = makeStore()
        await store.send(.view(.onImportFromHomeKitButtonTapped))
        await store.receive(.navigation(.onImportFromHomeKit))
    }

    @Test("onPasswordTap emits navigation action with the tapped password")
    func testOnPasswordTap() async {
        let password = makeTestPassword(in: context, name: "Lock")
        let store = makeStore()

        await store.send(.view(.onPasswordTap(password)))
        await store.receive(.navigation(.presentPassword(password)))
    }
}
