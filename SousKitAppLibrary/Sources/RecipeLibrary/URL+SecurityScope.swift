import Foundation

extension URL {
    /// Runs `body` with this URL's security scope open, and closes the scope after.
    ///
    /// - Parameter body: The work that needs the scope.
    /// - Returns: What `body` returns.
    /// - Throws: Whatever `body` throws.
    func withSecurityScope<T>(_ body: () throws -> T) rethrows -> T {
        let isScoped = startAccessingSecurityScopedResource()
        defer {
            if isScoped {
                stopAccessingSecurityScopedResource()
            }
        }

        return try body()
    }
}
