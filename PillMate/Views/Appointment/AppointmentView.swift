//
//  AppointmentView.swift
//  PillMate
//
//  Created by bbdyno on 11/30/25.
//

import SwiftUI
import SwiftData

/// 진료 예약 화면
struct AppointmentView: View {
    // MARK: - Properties
    
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Appointment.appointmentDate) private var appointments: [Appointment]
    
    @State private var showAddSheet = false
    @State private var selectedAppointment: Appointment?
    @State private var showDeleteConfirmation = false
    @State private var appointmentToDelete: Appointment?
    
    // MARK: - Body
    
    var body: some View {
        NavigationStack {
            Group {
                if appointments.isEmpty {
                    emptyStateView
                } else {
                    appointmentList
                }
            }
            .background(Color.appBackground)
            .navigationTitle("진료 예약")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showAddSheet = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showAddSheet) {
                AddAppointmentView { appointment in
                    modelContext.insert(appointment)
                    try? modelContext.save()
                }
            }
            .sheet(item: $selectedAppointment) { appointment in
                AppointmentDetailView(appointment: appointment)
            }
            .alert("예약 삭제", isPresented: $showDeleteConfirmation) {
                Button("취소", role: .cancel) {}
                Button("삭제", role: .destructive) {
                    if let appointment = appointmentToDelete {
                        modelContext.delete(appointment)
                        try? modelContext.save()
                    }
                }
            } message: {
                Text("이 예약을 삭제하시겠습니까?")
            }
        }
    }
    
    // MARK: - Empty State
    
    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Image(systemName: "calendar.badge.clock")
                .font(.system(size: 60))
                .foregroundColor(.gray)
            
            Text("등록된 예약이 없습니다")
                .font(.title3)
                .fontWeight(.medium)
            
            Text("진료 예약을 추가하여\n알림을 받아보세요")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            Button {
                showAddSheet = true
            } label: {
                Label("예약 추가", systemImage: "plus")
                    .padding(.horizontal, 20)
                    .padding(.vertical, 12)
            }
            .buttonStyle(.borderedProminent)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    // MARK: - Appointment List
    
    private var appointmentList: some View {
        List {
            // 다가오는 예약
            let upcoming = appointments.filter { $0.isUpcoming }
            if !upcoming.isEmpty {
                Section("다가오는 예약") {
                    ForEach(upcoming) { appointment in
                        AppointmentRow(appointment: appointment)
                            .onTapGesture {
                                selectedAppointment = appointment
                            }
                            .swipeActions(edge: .trailing) {
                                Button(role: .destructive) {
                                    appointmentToDelete = appointment
                                    showDeleteConfirmation = true
                                } label: {
                                    Label("삭제", systemImage: "trash")
                                }
                                
                                if !appointment.isCompleted {
                                    Button {
                                        appointment.markAsCompleted()
                                        try? modelContext.save()
                                    } label: {
                                        Label("완료", systemImage: "checkmark")
                                    }
                                    .tint(.green)
                                }
                            }
                    }
                }
            }
            
            // 지난 예약
            let past = appointments.filter { $0.isPast }
            if !past.isEmpty {
                Section("지난 예약") {
                    ForEach(past) { appointment in
                        AppointmentRow(appointment: appointment)
                            .onTapGesture {
                                selectedAppointment = appointment
                            }
                            .swipeActions(edge: .trailing) {
                                Button(role: .destructive) {
                                    appointmentToDelete = appointment
                                    showDeleteConfirmation = true
                                } label: {
                                    Label("삭제", systemImage: "trash")
                                }
                            }
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
    }
}

// MARK: - Appointment Row

struct AppointmentRow: View {
    let appointment: Appointment
    
    var body: some View {
        HStack(spacing: 12) {
            // 날짜 표시
            VStack(spacing: 2) {
                Text(dayText)
                    .font(.caption2)
                    .foregroundColor(.secondary)
                
                Text("\(Calendar.current.component(.day, from: appointment.appointmentDate))")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(appointment.isToday ? .blue : .primary)
                
                Text(monthText)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            .frame(width: 50)
            
            Divider()
            
            // 예약 정보
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(appointment.doctorName)
                        .fontWeight(.medium)
                    
                    if appointment.isCompleted {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                            .font(.caption)
                    }
                }
                
                if let specialty = appointment.specialty, !specialty.isEmpty {
                    Text(specialty)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                HStack(spacing: 8) {
                    Label(formatTime(appointment.appointmentDate), systemImage: "clock")
                    
                    if let location = appointment.location, !location.isEmpty {
                        Label(location, systemImage: "mappin")
                    }
                }
                .font(.caption)
                .foregroundColor(.secondary)
            }
            
            Spacer()
            
            // 남은 시간
            if appointment.isUpcoming, let text = appointment.timeRemainingText {
                Text(text)
                    .font(.caption)
                    .foregroundColor(appointment.isToday ? .blue : .secondary)
            }
        }
        .padding(.vertical, 4)
        .opacity(appointment.isCompleted ? 0.6 : 1)
    }
    
    private var dayText: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ko_KR")
        formatter.dateFormat = "E"
        return formatter.string(from: appointment.appointmentDate)
    }
    
    private var monthText: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ko_KR")
        formatter.dateFormat = "M월"
        return formatter.string(from: appointment.appointmentDate)
    }
}

// MARK: - Add Appointment View

struct AddAppointmentView: View {
    @Environment(\.dismiss) private var dismiss
    
    let onSave: (Appointment) -> Void
    
    @State private var doctorName = ""
    @State private var specialty = ""
    @State private var appointmentDate = Date()
    @State private var location = ""
    @State private var notes = ""
    @State private var notificationEnabled = true
    @State private var notificationMinutesBefore = 60
    
    var body: some View {
        NavigationStack {
            Form {
                Section("기본 정보") {
                    TextField("의사 이름 *", text: $doctorName)
                    TextField("진료과", text: $specialty)
                }
                
                Section("예약 일시") {
                    DatePicker(
                        "날짜 및 시간",
                        selection: $appointmentDate,
                        in: Date()...,
                        displayedComponents: [.date, .hourAndMinute]
                    )
                }
                
                Section("장소") {
                    TextField("병원/위치", text: $location)
                }
                
                Section("알림") {
                    Toggle("알림 받기", isOn: $notificationEnabled)
                    
                    if notificationEnabled {
                        Picker("알림 시간", selection: $notificationMinutesBefore) {
                            Text("정각에").tag(0)
                            Text("30분 전").tag(30)
                            Text("1시간 전").tag(60)
                            Text("2시간 전").tag(120)
                            Text("1일 전").tag(1440)
                        }
                    }
                }
                
                Section("메모") {
                    TextField("추가 메모", text: $notes, axis: .vertical)
                        .lineLimit(3...5)
                }
            }
            .navigationTitle("예약 추가")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("취소") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .topBarTrailing) {
                    Button("저장") {
                        saveAppointment()
                    }
                    .disabled(doctorName.isEmpty)
                }
            }
        }
    }
    
    private func saveAppointment() {
        let appointment = Appointment(
            doctorName: doctorName,
            specialty: specialty.isEmpty ? nil : specialty,
            appointmentDate: appointmentDate,
            location: location.isEmpty ? nil : location,
            notes: notes.isEmpty ? nil : notes
        )
        appointment.notificationEnabled = notificationEnabled
        appointment.notificationMinutesBefore = notificationMinutesBefore
        
        onSave(appointment)
        
        // 알림 설정
        if notificationEnabled {
            Task {
                try? await NotificationManager.shared.scheduleAppointmentNotification(for: appointment)
            }
        }
        
        dismiss()
    }
}

// MARK: - Appointment Detail View

struct AppointmentDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    let appointment: Appointment
    
    var body: some View {
        NavigationStack {
            List {
                Section {
                    HStack {
                        Text("의사")
                        Spacer()
                        Text(appointment.doctorName)
                            .foregroundColor(.secondary)
                    }
                    
                    if let specialty = appointment.specialty {
                        HStack {
                            Text("진료과")
                            Spacer()
                            Text(specialty)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                
                Section {
                    HStack {
                        Text("날짜")
                        Spacer()
                        Text(appointment.dateDisplayText)
                            .foregroundColor(.secondary)
                    }
                    
                    HStack {
                        Text("시간")
                        Spacer()
                        Text(formatTime(appointment.appointmentDate))
                            .foregroundColor(.secondary)
                    }
                    
                    if let location = appointment.location {
                        HStack {
                            Text("장소")
                            Spacer()
                            Text(location)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                
                if let notes = appointment.notes, !notes.isEmpty {
                    Section("메모") {
                        Text(notes)
                    }
                }
                
                if !appointment.isCompleted {
                    Section {
                        Button {
                            appointment.markAsCompleted()
                            try? modelContext.save()
                            dismiss()
                        } label: {
                            Label("완료로 표시", systemImage: "checkmark.circle")
                        }
                    }
                }
            }
            .navigationTitle("예약 상세")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("닫기") {
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - Preview

#Preview {
    AppointmentView()
        .modelContainer(for: Appointment.self, inMemory: true)
}
