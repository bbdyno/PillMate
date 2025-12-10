//
//  DoseMateSchemaV1.swift
//  DoseMate
//
//  Created by bbdyno on 12/09/25.
//

import Foundation
import SwiftData

/// DoseMate 스키마 버전 1 (현재 버전)
enum DoseMateSchemaV1: VersionedSchema {
    static var versionIdentifier = Schema.Version(1, 0, 0)

    static var models: [any PersistentModel.Type] {
        [
            Medication.self,
            MedicationSchedule.self,
            MedicationLog.self,
            HealthMetric.self,
            Appointment.self,
            Patient.self
        ]
    }
}
