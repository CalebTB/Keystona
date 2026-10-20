/// App-wide retry policy for Riverpod providers: never retry automatically.
///
/// Riverpod 3 retries a failed provider by default, with exponential backoff
/// (200 ms, 400 ms, ... up to 6.4 s). While it waits, the provider stays in
/// the loading state, so an offline screen keeps showing its skeleton for many
/// seconds instead of the error view with "Try again". Every screen already
/// has an explicit retry action, so failures should surface at once.
Duration? noAutomaticRetry(int retryCount, Object error) => null;
