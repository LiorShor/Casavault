import Testing
import ComposableArchitecture
import CoreData
@testable import StorePass

@Suite("HomeKitImport")
@MainActor
struct HomeKitImportTests {
    typealias Reducer = HomeKitImport

    private let context = TestCoreDataStack.makeContext()

    private func makeStore(
        initialState: Reducer.State = .init(),
        dependencies: (inout DependencyValues) -> Void = { _ in }
    ) -> TestStoreOf<Reducer> {
        TestStore(initialState: initialState) {
            Reducer()
        } withDependencies: {
            $0.homeUseCases.importFromHomeKit = { [] }
            $0.homeUseCases.getDefaultHome = { nil }
            $0.homeUseCases.fetchHomes = { [] }
            $0.homeUseCases.addHome = { _ in }
            $0.homeUseCases.removeHome = { _ in }
            $0.homeUseCases.updateHome = { _ in }
            $0.homeUseCases.setDefaultHome = { _ in }
            $0.passwordsUseCases.fetchPasswords = { [] }
            $0.passwordsUseCases.fetchPasswordsForHome = { _ in [] }
            $0.passwordsUseCases.addPassword = { _ in }
            $0.passwordsUseCases.removePassword = { _ in }
            $0.passwordsUseCases.updatePassword = { _ in }
            $0.databaseService.context = { [context] in context }
            $0.databaseService.saveContext = {}
            $0.dismiss = DismissEffect {}
            dependencies(&$0)
        }
    }

    // MARK: - State: hasPassword(for:)

    @Test("hasPassword matches by homeKitUniqueIdentifier first")
    func testHasPasswordMatchesByUID() {
        let uid = UUID()
        let password = makeTestPassword(in: context, name: "Lock", homeKitUniqueIdentifier: uid)
        let device = HomeKitDevice(name: "Other Name", uniqueIdentifier: uid)

        var state = Reducer.State()
        state.existingPasswords = [password]

        #expect(state.hasPassword(for: device) == password)
    }

    @Test("hasPassword falls back to name matching")
    func testHasPasswordFallsBackToName() {
        let password = makeTestPassword(in: context, name: "Front Door")
        let device = HomeKitDevice(name: "Front Door", uniqueIdentifier: UUID())

        var state = Reducer.State()
        state.existingPasswords = [password]

        #expect(state.hasPassword(for: device) == password)
    }

    @Test("hasPassword prefers current home when name-matching")
    func testHasPasswordPrefersCurrentHome() {
        let homeId = UUID()
        let passwordOtherHome = makeTestPassword(in: context, name: "Light", homeId: UUID())
        let passwordCurrentHome = makeTestPassword(in: context, name: "Light", homeId: homeId)
        let device = HomeKitDevice(name: "Light", uniqueIdentifier: UUID())

        var state = Reducer.State()
        state.currentHomeId = homeId
        state.existingPasswords = [passwordOtherHome, passwordCurrentHome]

        #expect(state.hasPassword(for: device) == passwordCurrentHome)
    }

    @Test("hasPassword returns nil when no match")
    func testHasPasswordReturnsNil() {
        let password = makeTestPassword(in: context, name: "Lock")
        let device = HomeKitDevice(name: "Light", uniqueIdentifier: UUID())

        var state = Reducer.State()
        state.existingPasswords = [password]

        #expect(state.hasPassword(for: device) == nil)
    }

    // MARK: - State: areAllSelectableDevicesSelected

    @Test("areAllSelectableDevicesSelected is false when no selectable devices")
    func testAreAllSelectedFalseWhenNoSelectableDevices() {
        // All devices have passwords → none are selectable
        let uid = UUID()
        let password = makeTestPassword(in: context, name: "Light", homeKitUniqueIdentifier: uid)
        let device = HomeKitDevice(name: "Light", uniqueIdentifier: uid)

        var state = Reducer.State()
        state.devices = [device]
        state.existingPasswords = [password]
        state.selectedDeviceIds = [device.id]

        #expect(state.areAllSelectableDevicesSelected == false)
    }

    @Test("areAllSelectableDevicesSelected is true when all new devices selected")
    func testAreAllSelectedTrue() {
        let device = HomeKitDevice(name: "Light")

        var state = Reducer.State()
        state.devices = [device]
        state.selectedDeviceIds = [device.id]

        #expect(state.areAllSelectableDevicesSelected == true)
    }

    @Test("areAllSelectableDevicesSelected is false when some new devices unselected")
    func testAreAllSelectedFalseWhenSomeUnselected() {
        let device1 = HomeKitDevice(name: "Light")
        let device2 = HomeKitDevice(name: "Lock")

        var state = Reducer.State()
        state.devices = [device1, device2]
        state.selectedDeviceIds = [device1.id]

        #expect(state.areAllSelectableDevicesSelected == false)
    }

    // MARK: - Reducer: internal actions

    @Test("devicesLoaded sets devices and auto-selects matched ones")
    func testDevicesLoaded() async {
        let uid = UUID()
        let password = makeTestPassword(in: context, name: "Light", homeKitUniqueIdentifier: uid)
        let matchedDevice = HomeKitDevice(name: "Light", uniqueIdentifier: uid)
        let newDevice = HomeKitDevice(name: "Lock")

        let store = makeStore()

        // Seed passwords via action to avoid putting NSManagedObjects in TestStore's initial state
        await store.send(.internal(.existingPasswordsLoaded([password]))) {
            $0.existingPasswords = [password]
        }

        await store.send(.internal(.devicesLoaded([matchedDevice, newDevice]))) {
            $0.isLoading = false
            $0.devices = [matchedDevice, newDevice]
            $0.selectedDeviceIds = [matchedDevice.id]
        }
    }

    @Test("existingPasswordsLoaded late-matches already-loaded devices")
    func testExistingPasswordsLoadedLateMatch() async {
        let uid = UUID()
        let device = HomeKitDevice(name: "Light", uniqueIdentifier: uid)
        let password = makeTestPassword(in: context, name: "Light", homeKitUniqueIdentifier: uid)

        var initialState = Reducer.State()
        initialState.isLoading = false
        initialState.devices = [device]

        let store = makeStore(initialState: initialState)

        await store.send(.internal(.existingPasswordsLoaded([password]))) {
            $0.existingPasswords = [password]
            $0.selectedDeviceIds = [device.id]
        }
    }

    @Test("loadingFailed sets error and clears loading")
    func testLoadingFailed() async {
        var initialState = Reducer.State()
        initialState.isLoading = true

        let store = makeStore(initialState: initialState)

        await store.send(.internal(.loadingFailed("Connection error"))) {
            $0.isLoading = false
            $0.loadingError = "Connection error"
        }
    }

    @Test("permissionDenied clears loading and sets flag")
    func testPermissionDenied() async {
        var initialState = Reducer.State()
        initialState.isLoading = true

        let store = makeStore(initialState: initialState)

        await store.send(.internal(.permissionDenied)) {
            $0.isLoading = false
            $0.isPermissionDenied = true
        }
    }

    @Test("currentHomeLoaded stores home IDs")
    func testCurrentHomeLoaded() async {
        let homeKitId = UUID()
        let home = makeTestHome(in: context, name: "My Home", homeKitUniqueIdentifier: homeKitId)
        let store = makeStore()

        await store.send(.internal(.currentHomeLoaded(home))) {
            $0.currentHomeId = home.id
            $0.currentHomeKitHomeId = homeKitId
        }
    }

    @Test("currentHomeLoaded with nil clears home IDs")
    func testCurrentHomeLoadedNil() async {
        var initialState = Reducer.State()
        initialState.currentHomeId = UUID()
        initialState.currentHomeKitHomeId = UUID()

        let store = makeStore(initialState: initialState)

        await store.send(.internal(.currentHomeLoaded(nil))) {
            $0.currentHomeId = nil
            $0.currentHomeKitHomeId = nil
        }
    }

    // MARK: - Reducer: device toggling

    @Test("deviceToggled selects an unselected device without password")
    func testDeviceToggledSelectsNew() async {
        let device = HomeKitDevice(name: "Light")

        var initialState = Reducer.State()
        initialState.devices = [device]

        let store = makeStore(initialState: initialState)

        await store.send(.view(.deviceToggled(device.id))) {
            $0.selectedDeviceIds = [device.id]
        }
    }

    @Test("deviceToggled deselects a selected device without password")
    func testDeviceToggledDeselectsNew() async {
        let device = HomeKitDevice(name: "Light")

        var initialState = Reducer.State()
        initialState.devices = [device]
        initialState.selectedDeviceIds = [device.id]

        let store = makeStore(initialState: initialState)

        await store.send(.view(.deviceToggled(device.id))) {
            $0.selectedDeviceIds = []
        }
    }

    @Test("deviceToggled selects a device that already has a password")
    func testDeviceToggledSelectsWithExistingPassword() async {
        let uid = UUID()
        let password = makeTestPassword(in: context, name: "Lock", homeKitUniqueIdentifier: uid)
        let device = HomeKitDevice(name: "Lock", uniqueIdentifier: uid)

        var initialState = Reducer.State()
        initialState.devices = [device]
        initialState.existingPasswords = [password]
        // Device not selected yet

        let store = makeStore(initialState: initialState)

        await store.send(.view(.deviceToggled(device.id))) {
            $0.selectedDeviceIds = [device.id]
        }
    }

    @Test("deviceToggled shows delete confirmation when unchecking a device with password")
    func testDeviceToggledShowsDeleteConfirmation() async {
        let uid = UUID()
        let password = makeTestPassword(in: context, name: "Lock", homeKitUniqueIdentifier: uid)
        let device = HomeKitDevice(name: "Lock", uniqueIdentifier: uid)

        var initialState = Reducer.State()
        initialState.devices = [device]
        initialState.existingPasswords = [password]
        initialState.selectedDeviceIds = [device.id]

        let store = makeStore(initialState: initialState)
        store.exhaustivity = .off

        await store.send(.view(.deviceToggled(device.id)))

        #expect(store.state.deleteConfirmation?.device == device)
        #expect(store.state.deleteConfirmation?.password == password)
        #expect(store.state.selectedDeviceIds.contains(device.id))
    }

    // MARK: - Reducer: delete confirmation

    @Test("cancelDelete clears the confirmation")
    func testCancelDelete() async {
        let device = HomeKitDevice(name: "Lock")
        let password = makeTestPassword(in: context, name: "Lock")
        let confirmation = HomeKitImport.DeleteConfirmationState(device: device, password: password)

        var initialState = Reducer.State()
        initialState.deleteConfirmation = confirmation

        let store = makeStore(initialState: initialState)

        await store.send(.view(.cancelDelete)) {
            $0.deleteConfirmation = nil
        }
    }

    @Test("confirmDelete removes selection, deletes password, and refreshes")
    func testConfirmDelete() async {
        let uid = UUID()
        let device = HomeKitDevice(name: "Lock", uniqueIdentifier: uid)
        let password = makeTestPassword(in: context, name: "Lock", homeKitUniqueIdentifier: uid)
        let confirmation = HomeKitImport.DeleteConfirmationState(device: device, password: password)

        var initialState = Reducer.State()
        initialState.devices = [device]
        initialState.existingPasswords = [password]
        initialState.selectedDeviceIds = [device.id]
        initialState.deleteConfirmation = confirmation

        var removePasswordCalled = false
        let store = makeStore(initialState: initialState) {
            $0.passwordsUseCases.removePassword = { _ in removePasswordCalled = true }
            $0.passwordsUseCases.fetchPasswords = { [] }
        }

        await store.send(.view(.confirmDelete)) {
            $0.deleteConfirmation = nil
            $0.selectedDeviceIds = []
        }
        await store.receive(.internal(.passwordDeleted))
        await store.receive(.internal(.existingPasswordsLoaded([]))) {
            $0.existingPasswords = []
        }

        #expect(removePasswordCalled)
    }

    // MARK: - Reducer: select all

    @Test("selectAllButtonTapped selects all new devices")
    func testSelectAllSelectsNewDevices() async {
        let device1 = HomeKitDevice(name: "Light")
        let device2 = HomeKitDevice(name: "Lock")

        var initialState = Reducer.State()
        initialState.devices = [device1, device2]

        let store = makeStore(initialState: initialState)

        await store.send(.view(.selectAllButtonTapped)) {
            $0.selectedDeviceIds = [device1.id, device2.id]
        }
    }

    @Test("selectAllButtonTapped deselects all when already all selected")
    func testSelectAllDeselectsWhenAllSelected() async {
        let device1 = HomeKitDevice(name: "Light")
        let device2 = HomeKitDevice(name: "Lock")

        var initialState = Reducer.State()
        initialState.devices = [device1, device2]
        initialState.selectedDeviceIds = [device1.id, device2.id]

        let store = makeStore(initialState: initialState)

        await store.send(.view(.selectAllButtonTapped)) {
            $0.selectedDeviceIds = []
        }
    }

    @Test("selectAllButtonTapped skips devices that already have passwords")
    func testSelectAllSkipsDevicesWithPasswords() async {
        let uid = UUID()
        let password = makeTestPassword(in: context, name: "Existing", homeKitUniqueIdentifier: uid)
        let existingDevice = HomeKitDevice(name: "Existing", uniqueIdentifier: uid)
        let newDevice = HomeKitDevice(name: "New Device")

        var initialState = Reducer.State()
        initialState.devices = [existingDevice, newDevice]
        initialState.existingPasswords = [password]
        initialState.selectedDeviceIds = [existingDevice.id]

        let store = makeStore(initialState: initialState)

        await store.send(.view(.selectAllButtonTapped)) {
            $0.selectedDeviceIds = [existingDevice.id, newDevice.id]
        }
    }

    // MARK: - Reducer: import

    @Test("importCompleted dismisses")
    func testImportCompleted() async {
        var dismissCalled = false

        var initialState = Reducer.State()
        initialState.isImporting = true

        let store = makeStore(initialState: initialState) {
            $0.dismiss = DismissEffect { dismissCalled = true }
        }

        await store.send(.internal(.importCompleted)) {
            $0.isImporting = false
        }
        await store.finish()

        #expect(dismissCalled)
    }

    @Test("cancelButtonTapped dismisses")
    func testCancelButtonTapped() async {
        var dismissCalled = false
        let store = makeStore {
            $0.dismiss = DismissEffect { dismissCalled = true }
        }

        await store.send(.view(.cancelButtonTapped))
        await store.finish()

        #expect(dismissCalled)
    }
}
