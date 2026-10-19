import Foundation

extension URL {
    /// Runs `body` with this URL's security scope open, and closes the scope after.
    func withSecurityScope<T>(_ body: () throws -> T) rethrows -> T {
        let isScoped = startAccessingSecurityScopedResource()
        defer {
            if isScoped {
                stopAccessingSecurityScopedResource()
            }
        }

        return try body()
    }

    /// Runs `body` with this URL's security scope open, and closes the scope after.
    func withSecurityScope<T>(_ body: () async throws -> T) async rethrows -> T {
        let isScoped = startAccessingSecurityScopedResource()
        defer {
            if isScoped {
                stopAccessingSecurityScopedResource()
            }
        }

        return try await body()
    }
}
