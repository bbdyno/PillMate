//
//  MedicationListViewModel.swift
//  DoseMate
//
//  Created by bbdyno on 11/30/25.
//

import Foundation
import SwiftUI
import SwiftData

/// 정렬 옵션
enum MedicationSortOption: String, CaseIterable, Identifiable {
    case name = "이름순"
    case createdAt = "추가순"
    case nextDose = "다음 복용순"
    case stockCount = "재고순"
    
    var id: String { rawValue }
}

/// 필터 옵션
enum MedicationFilterOption: String, CaseIterable, Identifiable {
    case all = "전체"
    case active = "복용 중"
    case inactive = "중단됨"
    case lowStock = "재고 부족"
    
    var id: String { rawValue }
}

/// 약물 목록 ViewModel
@MainActor
@Observable
final class MedicationListViewModel {
    // MARK: - Properties
    
    /// 약물 목록
    var medications: [Medication] = []
    
    /// 필터링된 약물 목록
    var filteredMedications: [Medication] = []
    
    /// 검색어
    var searchText: String = "" {
        didSet {
            applyFiltersAndSort()
        }
    }
    
    /// 현재 정렬 옵션
    var sortOption: MedicationSortOption = .name {
        didSet {
            applyFiltersAndSort()
        }
    }
    
    /// 현재 필터 옵션
    var filterOption: MedicationFilterOption = .all {
        didSet {
            applyFiltersAndSort()
        }
    }
    
    /// 로딩 상태
    var isLoading: Bool = false
    
    /// 에러 메시지
    var errorMessage: String?
    
    /// 선택된 약물 (편집용)
    var selectedMedication: Medication?
    
    /// 삭제 확인 표시 여부
    var showDeleteConfirmation: Bool = false
    
    /// 삭제할 약물
    var medicationToDelete: Medication?
    
    /// 약물 추가 시트 표시 여부
    var showAddMedicationSheet: Bool = false
    
    // MARK: - Private Properties
    
    private var modelContext: ModelContext?
    
    // MARK: - Initialization
    
    init() {}
    
    // MARK: - Setup
    
    /// ModelContext 설정
    func setup(with context: ModelContext) {
        self.modelContext = context
        Task {
            await loadMedications()
        }
    }
    
    // MARK: - Data Loading
    
    /// 약물 목록 로드
    func loadMedications() async {
        guard let context = modelContext else { return }
        
        isLoading = true
        errorMessage = nil
        
        defer { isLoading = false }
        
        let descriptor = FetchDescriptor<Medication>(
            sortBy: [SortDescriptor(\.name)]
        )
        
        do {
            medications = try context.fetch(descriptor)
            applyFiltersAndSort()
        } catch {
            errorMessage = "약물 목록을 불러오는데 실패했습니다."
        }
    }
    
    // MARK: - Filtering & Sorting
    
    /// 필터 및 정렬 적용
    private func applyFiltersAndSort() {
        var result = medications
        
        // 필터 적용
        switch filterOption {
        case .all:
            break
        case .active:
            result = result.filter { $0.isActive }
        case .inactive:
            result = result.filter { !$0.isActive }
        case .lowStock:
            result = result.filter { $0.isLowStock }
        }
        
        // 검색어 적용
        if !searchText.isEmpty {
            result = result.filter { medication in
                medication.name.localizedCaseInsensitiveContains(searchText) ||
                medication.purpose.localizedCaseInsensitiveContains(searchText) ||
                medication.prescribingDoctor.localizedCaseInsensitiveContains(searchText)
            }
        }
        
        // 정렬 적용
        switch sortOption {
        case .name:
            result.sort { $0.name < $1.name }
        case .createdAt:
            result.sort { $0.createdAt > $1.createdAt }
        case .nextDose:
            result.sort { med1, med2 in
                let time1 = med1.nextDoseTime ?? .distantFuture
                let time2 = med2.nextDoseTime ?? .distantFuture
                return time1 < time2
            }
        case .stockCount:
            result.sort { $0.stockCount < $1.stockCount }
        }
        
        filteredMedications = result
    }
    
    // MARK: - CRUD Operations
    
    /// 약물 추가 가능 여부
    /// 💡 프리미엄 정책: 무료 사용자는 3개까지만 추가 가능
    var canAddMedication: Bool {
        PremiumFeatures.canAddMedication(currentCount: medications.count)
    }
    
    /// 남은 무료 슬롯 수
    var remainingFreeSlots: Int {
        max(0, PremiumFeatures.freeMedicationLimit - medications.count)
    }
    
    /// 약물 추가
    func addMedication(_ medication: Medication) async {
        guard let context = modelContext else { return }
        
        // 💎 프리미엄 체크
        guard canAddMedication else {
            errorMessage = "무료 버전에서는 약물을 \(PremiumFeatures.freeMedicationLimit)개까지만 등록할 수 있습니다. 프리미엄으로 업그레이드하세요."
            return
        }
        
        context.insert(medication)
        
        do {
            try context.save()
            await loadMedications()
        } catch {
            errorMessage = "약물 추가에 실패했습니다."
        }
    }
    
    /// 약물 삭제
    func deleteMedication(_ medication: Medication) async {
        guard let context = modelContext else { return }
        
        // 관련 알림 취소
        let schedules = medication.schedules
        for schedule in schedules {
            await NotificationManager.shared.cancelNotification(for: schedule)
        }
        
        context.delete(medication)
        
        do {
            try context.save()
            await loadMedications()
        } catch {
            errorMessage = "약물 삭제에 실패했습니다."
        }
    }
    
    /// 약물 삭제 확인
    func confirmDelete(_ medication: Medication) {
        medicationToDelete = medication
        showDeleteConfirmation = true
    }
    
    /// 삭제 실행
    func executeDelete() async {
        guard let medication = medicationToDelete else { return }
        await deleteMedication(medication)
        medicationToDelete = nil
        showDeleteConfirmation = false
    }
    
    /// 약물 활성/비활성 토글
    func toggleActive(_ medication: Medication) async {
        medication.isActive.toggle()
        
        // 비활성화 시 알림 취소
        if !medication.isActive {
            let schedules = medication.schedules
            for schedule in schedules {
                await NotificationManager.shared.cancelNotification(for: schedule)
            }
        }
        
        try? modelContext?.save()
        await loadMedications()
    }
    
    /// 재고 업데이트
    func updateStock(_ medication: Medication, amount: Int) async {
        if amount > 0 {
            medication.increaseStock(by: amount)
        } else {
            medication.decreaseStock(by: abs(amount))
        }
        
        // 재고 부족 알림 확인
        if medication.isLowStock {
            do {
                try await NotificationManager.shared.sendLowStockNotification(for: medication)
            } catch {
                print("재고 부족 알림 전송 실패: \(error)")
            }
        }
        
        try? modelContext?.save()
        await loadMedications()
    }
    
    // MARK: - Search
    
    /// 검색 초기화
    func clearSearch() {
        searchText = ""
    }
    
    // MARK: - Computed Properties
    
    /// 활성 약물 수
    var activeMedicationsCount: Int {
        medications.filter { $0.isActive }.count
    }
    
    /// 재고 부족 약물 수
    var lowStockMedicationsCount: Int {
        medications.filter { $0.isLowStock }.count
    }
    
    /// 총 약물 수
    var totalMedicationsCount: Int {
        medications.count
    }
    
    /// 검색 결과 없음
    var hasNoSearchResults: Bool {
        !searchText.isEmpty && filteredMedications.isEmpty
    }
    
    /// 빈 상태 여부
    var isEmpty: Bool {
        medications.isEmpty
    }
    
    /// 필터링된 빈 상태 여부
    var isFilteredEmpty: Bool {
        filteredMedications.isEmpty && !medications.isEmpty
    }
    
    // MARK: - Form Categories
    
    /// 형태별 그룹화된 약물
    var medicationsByForm: [(form: MedicationForm, medications: [Medication])] {
        let grouped = Dictionary(grouping: filteredMedications) { medication in
            MedicationForm(rawValue: medication.form) ?? .other
        }
        
        return grouped
            .map { (form: $0.key, medications: $0.value) }
            .sorted { $0.form.displayName < $1.form.displayName }
    }
}
