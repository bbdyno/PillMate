//
//  AppointmentListView.swift
//  DoseMate
//
//  Created by tngtng on 12/6/25.
//

import Foundation
import SwiftData
import SwiftUI
import DMateDesignSystem
import DMateResource

// MARK: - Appointment List View

struct AppointmentListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Appointment.appointmentDate) private var appointments: [Appointment]
    
    @State private var showAddSheet = false
    
    var body: some View {
        List {
            if !upcomingAppointments.isEmpty {
                Section(DMateResourceStrings.Appointments.upcomingSection) {
                    ForEach(upcomingAppointments) { appointment in
                        AppointmentCard(appointment: appointment)
                            .listRowInsets(EdgeInsets(top: 8, leading: 0, bottom: 8, trailing: 0))
                            .listRowBackground(Color.clear)
                            .swipeActions {
                                Button(role: .destructive) {
                                    modelContext.delete(appointment)
                                    try? modelContext.save()
                                } label: {
                                    Label(DMateResourceStrings.Appointments.delete, systemImage: "trash")
                                }

                                Button {
                                    appointment.markAsCompleted()
                                    try? modelContext.save()
                                } label: {
                                    Label(DMateResourceStrings.Appointments.complete, systemImage: "checkmark")
                                }
                                .tint(.green)
                            }
                    }
                }
            }

            if !pastAppointments.isEmpty {
                Section(DMateResourceStrings.Appointments.pastSection) {
                    ForEach(pastAppointments) { appointment in
                        AppointmentCard(appointment: appointment)
                            .listRowInsets(EdgeInsets(top: 8, leading: 0, bottom: 8, trailing: 0))
                            .listRowBackground(Color.clear)
                            .swipeActions {
                                Button(role: .destructive) {
                                    modelContext.delete(appointment)
                                    try? modelContext.save()
                                } label: {
                                    Label(DMateResourceStrings.Appointments.delete, systemImage: "trash")
                                }
                            }
                    }
                }
            }
        }
        .navigationTitle(DMateResourceStrings.Appointments.title)
        .toolbarBackground(.clear, for: .navigationBar)
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
            if appointments.isEmpty {
                ContentUnavailableView(
                    DMateResourceStrings.Appointments.emptyTitle,
                    systemImage: "calendar.badge.exclamationmark",
                    description: Text(DMateResourceStrings.Appointments.emptyDescription)
                )
            }
        }
        .sheet(isPresented: $showAddSheet) {
            AddAppointmentView { appointment in
                modelContext.insert(appointment)
                try? modelContext.save()
            }
        }
    }
    
    private var upcomingAppointments: [Appointment] {
        appointments.filter { $0.isUpcoming || $0.isToday }
    }
    
    private var pastAppointments: [Appointment] {
        appointments.filter { $0.isPast }
    }
}
