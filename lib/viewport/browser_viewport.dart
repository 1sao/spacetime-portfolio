/// The browser's small and large viewport heights, in logical pixels.
///
/// This version lets the app compile off the web, where the tests run.
/// Nothing calls it there: `WebAddressBar` is active only in a browser.
({double small, double large}) measureBrowserViewport() =>
    throw UnsupportedError('Only a browser has viewport heights.');
