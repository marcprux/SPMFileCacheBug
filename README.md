# SPMFileCacheBug

This repository demonstrates a bug whereby the SPM `PackagePlugin.Target`'s `sourceFiles` list is incorrectly cached, and doesn't accurately reflect external changes to the project's build graph until Xcode is quit or restarted. This means that SPM build plugins cannot be used for projects that add, remove, or rename files in their projects.

`BuildToolPlugin.createBuildCommands(context:target:)` is passed a stale file list for `PackagePlugin.SourceModuleTarget.sourceFiles`. The contents are not up-to-date with changes to the project files. New files are not present, and deleted files are still included in the list. Quitting and restarting Xcode works around this problem, indicating that this is a caching issue.

The bug has been present since SPM 5.8 and Xcode 14 and persists through SPM 5.9 and Xcode 15.0 beta 6 (15A5219j). 

To reproduce:

  1. Open the Package.swift in Xcode (`xed Package.swift`)
  2. Build the "SPMFileCacheBug" target successfully
  3. Select the Sources/SPMFileCacheBug/SPMFileCacheBug.swift file and run the File->Duplicate… menu
  4. Build the "SPMFileCacheBug" target, observing the plugin fail with the error:

```error
swiftSourceFiles: ["SPMFileCacheBug.swift"]
actualSwiftSourceFiles: ["SPMFileCacheBug.swift", "SPMFileCacheBug copy.swift"]
PackagePlugin.Target returned wrong results
```

Quitting and restarting Xcode works around the problem, but this is unworkable for projects that need to add, remove, or or rename files with any frequency.

The `VerifyFileListPlugIn` plugin itself merely verifies that the list of files it is handed correctly reflects the project's files (by comparing it to a manual file list obtained from `Foundation.FileManager`). The failure demonstrates that this file list is mis-cached, and is not updated when the rest of the build graph is updated.


```
├── Package.swift
├── Plugins
│   └── VerifyFileList
│       └── VerifyFileListPlugIn.swift
├── README.md
└── Sources
    └── SPMFileCacheBug
        └── SPMFileCacheBug.swift
```

Contents of `VerifyFileListPlugIn.swift`:

```
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
```



<img width="1320" alt="Screenshot 2023-08-15 at 13 43 06" src="https://github.com/marcprux/SPMFileCacheBug/assets/659086/77036642-f4d2-42ba-a780-ee2c7608411a">

Feedback for the issue has been submitted to the Xcode team as `FB12969712`: "Xcode SPM Build plugins are given stale PackagePlugin.SourceModuleTarget.sourceFiles", as well as with the SPM project at https://github.com/apple/swift-package-manager/issues/6816.




