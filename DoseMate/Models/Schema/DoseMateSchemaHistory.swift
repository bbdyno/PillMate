//
//  DoseMateSchemaHistory.swift
//  DoseMate
//
//  Created by bbdyno on 12/09/25.
//

import Foundation
import SwiftData

/// DoseMate 스키마 마이그레이션 플랜
///
/// SwiftData는 이 플랜을 사용하여 자동으로 스키마를 마이그레이션합니다.
/// - Lightweight migration: 필드 추가/삭제, 타입 변경 등 자동 처리
/// - Custom migration: 복잡한 데이터 변환이 필요한 경우 직접 구현
enum DoseMateSchemaHistory: SchemaMigrationPlan {
    /// 모든 스키마 버전 (순서대로)
    static var schemas: [any VersionedSchema.Type] {
        [
            DoseMateSchemaV1.self,
            DoseMateSchemaV2.self,
            DoseMateSchemaV3.self
        ]
    }

    /// 버전 간 마이그레이션 단계
    static var stages: [MigrationStage] {
        [
            migrateV1toV2,
            migrateV2toV3,
        ]
    }

    static let migrateV1toV2 = MigrationStage.lightweight(
        fromVersion: DoseMateSchemaV1.self,
        toVersion: DoseMateSchemaV2.self
    )

    static let migrateV2toV3 = MigrationStage.lightweight(
        fromVersion: DoseMateSchemaV2.self,
        toVersion: DoseMateSchemaV3.self
    )
}
