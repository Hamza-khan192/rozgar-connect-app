/// App-wide configuration.
///
/// [kUseApi] switches the data source used by the whole app:
/// - `false` -> in-memory [MockRepository] with realistic Pakistani demo data.
/// - `true`  -> [ApiRepository] talking to the Node.js/Express REST backend.
const bool kUseApi = false;

/// Base URL of the REST backend. `10.0.2.2` is the host loopback address
/// visible from the Android emulator.
const String kApiBaseUrl = 'http://10.0.2.2:3000';
