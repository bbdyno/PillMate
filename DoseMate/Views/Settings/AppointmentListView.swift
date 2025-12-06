//
//  AppointmentListView.swift
//  DoseMate
//
//  Created by tngtng on 12/6/25.
//

import Foundation
import SwiftData
import SwiftUI

// MARK: - Appointment List View

struct AppointmentListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Appointment.appointmentDate) private var appointments: [Appointment]
    
    @State private var showAddSheet = false
    
    var body: some View {
        List {
            if !upcomingAppointments.isEmpty {
                Section(DoseMateStrings.Appointments.upcomingSection) {
                    ForEach(upcomingAppointments) { appointment in
                        AppointmentRow(appointment: appointment)
                            .swipeActions {
                                Button(role: .destructive) {
                                    modelContext.delete(appointment)
                                    try? modelContext.save()
                                } label: {
                                    Label(DoseMateStrings.Appointments.delete, systemImage: "trash")
                                }
                                
                                Button {
                                    appointment.markAsCompleted()
                                    try? modelContext.save()
                                } label: {
                                    Label(DoseMateStrings.Appointments.complete, systemImage: "checkmark")
                                }
                                .tint(.green)
                            }
                    }
                }
            }
            
            if !pastAppointments.isEmpty {
                Section(DoseMateStrings.Appointments.pastSection) {
                    ForEach(pastAppointments) { appointment in
                        AppointmentRow(appointment: appointment)
                            .swipeActions {
                                Button(role: .destructive) {
                                    modelContext.delete(appointment)
                                    try? modelContext.save()
                                } label: {
                                    Label(DoseMateStrings.Appointments.delete, systemImage: "trash")
                                }
                            }
                    }
                }
            }
        }
        .navigationTitle(DoseMateStrings.Appointments.title)
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
                    DoseMateStrings.Appointments.emptyTitle,
                    systemImage: "calendar.badge.exclamationmark",
                    description: Text(DoseMateStrings.Appointments.emptyDescription)
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
