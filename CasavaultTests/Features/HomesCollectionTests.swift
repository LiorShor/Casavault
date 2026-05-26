import Testing
import ComposableArchitecture
import CoreData
@testable import StorePass

@Suite("HomesCollection")
@MainActor
struct HomesCollectionTests {
    typealias Reducer = HomesCollection

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

    // MARK: - State: computed properties

    @Test("isHomeNameValid is true for a unique non-empty name")
    func testIsHomeNameValidTrue() {
        let home = makeTestHome(in: context, name: "Home A")
        var state = Reducer.State(homes: [home])
        state.newHomeName = "Home B"

        #expect(state.isHomeNameValid == true)
    }

    @Test("isHomeNameValid is false for an empty name")
    func testIsHomeNameValidFalseWhenEmpty() {
        var state = Reducer.State()
        state.newHomeName = ""

        #expect(state.isHomeNameValid == false)
    }

    @Test("isHomeNameValid is false when name already exists (case-insensitive)")
    func testIsHomeNameValidFalseDuplicate() {
        let home = makeTestHome(in: context, name: "My Home")
        var state = Reducer.State(homes: [home])
        state.newHomeName = "my home"

        #expect(state.isHomeNameValid == false)
    }

    @Test("homeNameExists is true when name already exists")
    func testHomeNameExistsTrue() {
        let home = makeTestHome(in: context, name: "My Home")
        var state = Reducer.State(homes: [home])
        state.newHomeName = "MY HOME"

        #expect(state.homeNameExists == true)
    }

    @Test("homeNameExists is false when name is new")
    func testHomeNameExistsFalse() {
        let home = makeTestHome(in: context, name: "My Home")
        var state = Reducer.State(homes: [home])
        state.newHomeName = "Other Home"

        #expect(state.homeNameExists == false)
    }

    // MARK: - Reducer: add/cancel home

    @Test("onAddHomeButtonTapped opens the add home sheet")
    func testOnAddHomeButtonTapped() async {
        let store = makeStore()

        await store.send(.view(.onAddHomeButtonTapped)) {
            $0.isAddingNewHome = true
            $0.newHomeName = ""
        }
    }

    @Test("cancelAddingHome dismisses the sheet")
    func testCancelAddingHome() async {
        var initialState = Reducer.State()
        initialState.isAddingNewHome = true
        initialState.newHomeName = "Draft"

        let store = makeStore(initialState: initialState)

        await store.send(.view(.cancelAddingHome)) {
            $0.isAddingNewHome = false
            $0.newHomeName = ""
        }
    }

    @Test("saveNewHome with empty name just dismisses sheet")
    func testSaveNewHomeEmptyName() async {
        var initialState = Reducer.State()
        initialState.isAddingNewHome = true
        initialState.newHomeName = ""

        let store = makeStore(initialState: initialState)

        await store.send(.view(.saveNewHome)) {
            $0.isAddingNewHome = false
        }
    }

    @Test("saveNewHome creates home and reloads list")
    func testSaveNewHome() async {
        let newHome = makeTestHome(in: context, name: "My Home", isDefault: true)
        var addedHome: Home?

        var initialState = Reducer.State()
        initialState.isAddingNewHome = true
        initialState.newHomeName = "My Home"

        let store = makeStore(initialState: initialState) {
            $0.homeUseCases.addHome = { home in addedHome = home }
            $0.homeUseCases.fetchHomes = { [newHome] }
        }

        await store.send(.view(.saveNewHome)) {
            $0.isAddingNewHome = false
            $0.newHomeName = ""
        }
        await store.receive(.homesLoaded([newHome])) {
            $0.homes = [newHome]
            $0.defaultHomeId = newHome.id
        }

        #expect(addedHome != nil)
        #expect(addedHome?.name == "My Home")
    }

    // MARK: - Reducer: HomeKit import

    @Test("onImportFromHomeKitTapped succeeds and reloads homes")
    func testImportFromHomeKitSuccess() async {
        let importedHome = makeTestHome(in: context, name: "Imported Home", isDefault: true)
        let store = makeStore {
            $0.homeUseCases.importFromHomeKit = { [] }
            $0.homeUseCases.fetchHomes = { [importedHome] }
        }

        await store.send(.view(.onImportFromHomeKitTapped)) {
            $0.isImporting = true
        }
        await store.receive(.importCompleted) {
            $0.isImporting = false
        }
        await store.receive(.homesLoaded([importedHome])) {
            $0.homes = [importedHome]
            $0.defaultHomeId = importedHome.id
        }
    }

    @Test("onImportFromHomeKitTapped shows alert on permission denied")
    func testImportFromHomeKitPermissionDenied() async {
        let store = makeStore {
            $0.homeUseCases.importFromHomeKit = { throw HomeKitError.permissionDenied }
        }

        await store.send(.view(.onImportFromHomeKitTapped)) {
            $0.isImporting = true
        }
        await store.receive(.internal(.importPermissionDenied)) {
            $0.isImporting = false
            $0.showPermissionDeniedAlert = true
        }
    }

    @Test("onImportFromHomeKitTapped treats generic errors as completion")
    func testImportFromHomeKitGenericError() async {
        struct SomeError: Error {}
        let store = makeStore {
            $0.homeUseCases.importFromHomeKit = { throw SomeError() }
            $0.homeUseCases.fetchHomes = { [] }
        }

        await store.send(.view(.onImportFromHomeKitTapped)) {
            $0.isImporting = true
        }
        await store.receive(.importCompleted) {
            $0.isImporting = false
        }
        await store.receive(.homesLoaded([]))
    }

    // MARK: - Reducer: homes loaded

    @Test("homesLoaded updates homes and defaultHomeId")
    func testHomesLoaded() async {
        let home1 = makeTestHome(in: context, name: "Home A", isDefault: true)
        let home2 = makeTestHome(in: context, name: "Home B")

        let store = makeStore()

        await store.send(.homesLoaded([home1, home2])) {
            $0.homes = [home1, home2]
            $0.defaultHomeId = home1.id
        }
    }

    @Test("homesLoaded auto-sets default when there is exactly one non-default home")
    func testHomesLoadedAutoSetsDefault() async {
        let home = makeTestHome(in: context, name: "Only Home", isDefault: false)
        var setDefaultCalled = false

        let store = makeStore {
            $0.homeUseCases.setDefaultHome = { home in
                setDefaultCalled = true
                home.isDefault = true
            }
            $0.homeUseCases.fetchHomes = { [home] }
        }

        store.exhaustivity = .off

        await store.send(.homesLoaded([home]))
        // Receives a second homesLoaded after setDefaultHome + fetchHomes
        await store.receive(.homesLoaded([home]))

        #expect(setDefaultCalled)
    }

    @Test("homesLoaded with one already-default home does NOT re-set default")
    func testHomesLoadedSkipsAlreadyDefaultHome() async {
        let home = makeTestHome(in: context, name: "Only Home", isDefault: true)
        var setDefaultCalled = false

        let store = makeStore {
            $0.homeUseCases.setDefaultHome = { _ in setDefaultCalled = true }
        }

        await store.send(.homesLoaded([home])) {
            $0.homes = [home]
            $0.defaultHomeId = home.id
        }

        #expect(setDefaultCalled == false)
    }

    // MARK: - Reducer: delete home

    @Test("onDeleteHome removes home and reloads list")
    func testOnDeleteHome() async {
        let home = makeTestHome(in: context, name: "Home A")
        var removedHome: Home?

        let store = makeStore(initialState: .init(homes: [home])) {
            $0.homeUseCases.removeHome = { home in removedHome = home }
            $0.homeUseCases.fetchHomes = { [] }
        }

        await store.send(.view(.onDeleteHome(home)))
        await store.receive(.homesLoaded([])) {
            $0.homes = []
            $0.defaultHomeId = nil
        }

        #expect(removedHome == home)
    }

    // MARK: - Reducer: toggle default

    @Test("toggleDefaultHome gives immediate visual feedback")
    func testToggleDefaultHomeImmediateFeedback() async {
        let home1 = makeTestHome(in: context, name: "Home A", isDefault: true)
        let home2 = makeTestHome(in: context, name: "Home B")

        let store = makeStore(initialState: .init(homes: [home1, home2])) {
            $0.homeUseCases.setDefaultHome = { _ in }
            $0.homeUseCases.fetchHomes = { [home1, home2] }
        }

        store.exhaustivity = .off

        await store.send(.view(.toggleDefaultHome(home2))) {
            $0.defaultHomeId = home2.id
        }
        await store.receive(.homesLoaded([home1, home2]))
    }

    // MARK: - Reducer: settings

    @Test("onSettingsButtonTapped emits navigation action")
    func testOnSettingsButtonTapped() async {
        let store = makeStore()

        await store.send(.view(.onSettingsButtonTapped))
        await store.receive(.navigation(.presentSettings))
    }
}
