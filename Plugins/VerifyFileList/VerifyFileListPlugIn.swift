import PackagePlugin
import Foundation

@main
public struct VerifyFileListPlugIn: BuildToolPlugin {
    public init() {
    }   

    public func createBuildCommands(context: PackagePlugin.PluginContext, target: PackagePlugin.Target) async throws -> [Command] {
        guard let target = target as? SourceModuleTarget else {
            return []
        }

        let swiftSourceFiles = target.sourceFiles(withSuffix: "swift").map(\.path.lastComponent)
        Diagnostics.remark("swiftSourceFiles: \(swiftSourceFiles)")

        let actualSwiftSourceFiles = try FileManager.default.contentsOfDirectory(atPath: target.directory.string).filter({ $0.hasSuffix(".swift") })
        Diagnostics.remark("actualSwiftSourceFiles: \(actualSwiftSourceFiles)")

        if Set(swiftSourceFiles) != Set(actualSwiftSourceFiles) {
            Diagnostics.error("PackagePlugin.Target returned wrong results")
        }

        // the plugin doesn't actually do anything, it just verifies that the input file list is correct
        return []
    }
}
