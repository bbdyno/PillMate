import ProjectDescription

// MARK: - Module Names
enum ModuleName: String {
    case designSystem = "DMateDesignSystem"
    case resource = "DMateResource"

    var path: Path {
        return .relativeToRoot(self.rawValue)
    }
}

let workspace = Workspace(
    name: "DoseMate",
    projects: [
        ".",
        ModuleName.designSystem.path,
        ModuleName.resource.path
    ]
)
