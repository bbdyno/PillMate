import ProjectDescription

// MARK: - Module Names
public enum ModuleName: String, CaseIterable {
    case designSystem = "DMateDesignSystem"
    case resource = "DMateResource"

    /// 타겟 이름
    public var targetName: String {
        return self.rawValue
    }

    /// 번들 ID
    public var bundleId: String {
        return "com.bbdyno.app.doseMate.\(self.rawValue)"
    }

    /// 프로젝트 경로
    public var path: Path {
        return .relativeToRoot(self.rawValue)
    }

    /// 프로젝트 경로 (String)
    public var pathString: String {
        return self.rawValue
    }
}

// MARK: - Workspace Extension
extension Array where Element == ModuleName {
    /// 모든 모듈의 프로젝트 경로 배열 반환
    public var projectPaths: [Path] {
        return self.map { $0.path }
    }
}

// MARK: - TargetDependency Extension
extension TargetDependency {
    /// 모듈 프로젝트 의존성
    public static func module(_ module: ModuleName) -> TargetDependency {
        return .project(target: module.targetName, path: module.path)
    }
}
