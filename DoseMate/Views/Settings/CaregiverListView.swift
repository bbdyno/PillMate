//
//  CaregiverListView.swift
//  DoseMate
//
//  Created by bbdyno on 12/6/25.
//

import Foundation
import SwiftData
import SwiftUI

// MARK: - Caregiver List View

struct CaregiverListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var caregivers: [Caregiver]
    
    @State private var showAddSheet = false
    @State private var caregiverToDelete: Caregiver?
    @State private var showDeleteConfirmation = false
    
    var body: some View {
        List {
            ForEach(caregivers) { caregiver in
                CaregiverRow(caregiver: caregiver)
                    .swipeActions {
                        Button(role: .destructive) {
                            caregiverToDelete = caregiver
                            showDeleteConfirmation = true
                        } label: {
                            Label("삭제", systemImage: "trash")
                        }
                    }
            }
        }
        .navigationTitle("보호자 관리")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    showAddSheet = true
                } label: {
                    Image(systemName: "plus")
                }
            }
        }
        .overlay {
            if caregivers.isEmpty {
                ContentUnavailableView(
                    "보호자 없음",
                    systemImage: "person.2.slash",
                    description: Text("보호자를 추가하면 복약 누락 시 알림을 보낼 수 있습니다")
                )
            }
        }
        .sheet(isPresented: $showAddSheet) {
            AddCaregiverView { caregiver in
                modelContext.insert(caregiver)
                try? modelContext.save()
            }
        }
        .alert("보호자 삭제", isPresented: $showDeleteConfirmation) {
            Button("취소", role: .cancel) {}
            Button("삭제", role: .destructive) {
                if let caregiver = caregiverToDelete {
                    modelContext.delete(caregiver)
                    try? modelContext.save()
                }
            }
        }
    }
}
