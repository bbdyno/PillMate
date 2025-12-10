//
//  DoseMateSchemaV2.swift
//  DoseMate
//
//  Created by bbdyno on 12/09/25.
//

import Foundation
import SwiftData

/// DoseMate 스키마 버전 2 (향후 확장용)
///
/// 새로운 필드나 모델을 추가할 때 이 버전을 활성화하고
/// DoseMataSchemaMigrationPlan에 마이그레이션 단계를 추가
enum DoseMateSchemaV2: VersionedSchema {
    static var versionIdentifier = Schema.Version(2, 0, 0)

    static var models: [any PersistentModel.Type] {
        [
            Medication.self,
            MedicationSchedule.self,
            MedicationLog.self,
            HealthMetric.self,
            Appointment.self,
            Patient.self
            // 향후 새 모델 추가
        ]
    }
}
