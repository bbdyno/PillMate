//
//  AppointmentView.swift
//  DoseMate
//
//  Created by bbdyno on 11/30/25.
//

import SwiftUI
import DMateDesignSystem
import DMateResource
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
            ZStack {
                // 배경 그라데이션
                LinearGradient(
                    colors: [
                        Color.blue.opacity(0.05),
                        Color.purple.opacity(0.05)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()

                if appointments.isEmpty {
                    emptyStateView
                } else {
                    appointmentList
                }
            }
            .navigationTitle(DMateResourceStrings.Appointments.title)
            .toolbarBackground(.ultraThinMaterial, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showAddSheet = true
                    } label: {
                        ZStack {
                            Circle()
                                .fill(Color.blue.gradient)
                                .frame(width: 36, height: 36)

                            Image(systemName: "plus")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundStyle(.white)
                        }
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
            .alert(DMateResourceStrings.Appointments.deleteTitle, isPresented: $showDeleteConfirmation) {
                Button(DMateResourceStrings.Common.cancel, role: .cancel) {}
                Button(DMateResourceStrings.Appointments.delete, role: .destructive) {
                    if let appointment = appointmentToDelete {
                        modelContext.delete(appointment)
                        try? modelContext.save()
                    }
                }
            } message: {
                Text(DMateResourceStrings.Appointments.deleteMessage)
            }
        }
    }
    
    // MARK: - Empty State
    
    private var emptyStateView: some View {
        VStack(spacing: 24) {
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [Color.blue.opacity(0.2), Color.purple.opacity(0.2)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 120, height: 120)

                Image(systemName: "calendar.badge.clock")
                    .font(.system(size: 50))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.blue, .purple],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            }

            VStack(spacing: 8) {
                Text(DMateResourceStrings.Appointments.emptyTitle)
                    .font(.title3)
                    .fontWeight(.semibold)

                Text(DMateResourceStrings.Appointments.emptyDescription)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }

            Button {
                showAddSheet = true
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "plus.circle.fill")
                    Text(DMateResourceStrings.Appointments.addButton)
                        .fontWeight(.semibold)
                }
                .foregroundStyle(.white)
                .padding(.horizontal, 24)
                .padding(.vertical, 14)
                .background(
                    LinearGradient(
                        colors: [.blue, .purple],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .clipShape(Capsule())
                .shadow(color: .blue.opacity(0.3), radius: 8, x: 0, y: 4)
            }
            .padding(.top, 8)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    // MARK: - Appointment List
    
    private var appointmentList: some View {
        ScrollView {
            VStack(spacing: 16) {
                // 다가오는 예약
                let upcoming = appointments.filter { $0.isUpcoming }
                if !upcoming.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        Text(DMateResourceStrings.Appointments.upcomingSection)
                            .font(.headline)
                            .fontWeight(.semibold)
                            .padding(.horizontal)

                        ForEach(upcoming) { appointment in
                            AppointmentCard(appointment: appointment)
                                .onTapGesture {
                                    selectedAppointment = appointment
                                }
                                .contextMenu {
                                    if !appointment.isCompleted {
                                        Button {
                                            appointment.markAsCompleted()
                                            try? modelContext.save()
                                        } label: {
                                            Label(DMateResourceStrings.Appointments.markCompleted, systemImage: "checkmark.circle")
                                        }
                                    }

                                    Button(role: .destructive) {
                                        appointmentToDelete = appointment
                                        showDeleteConfirmation = true
                                    } label: {
                                        Label(DMateResourceStrings.Appointments.delete, systemImage: "trash")
                                    }
                                }
                        }
                    }
                }

                // 지난 예약
                let past = appointments.filter { $0.isPast }
                if !past.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        Text(DMateResourceStrings.Appointments.pastSection)
                            .font(.headline)
                            .fontWeight(.semibold)
                            .padding(.horizontal)

                        ForEach(past) { appointment in
                            AppointmentCard(appointment: appointment)
                                .onTapGesture {
                                    selectedAppointment = appointment
                                }
                                .contextMenu {
                                    Button(role: .destructive) {
                                        appointmentToDelete = appointment
                                        showDeleteConfirmation = true
                                    } label: {
                                        Label(DMateResourceStrings.Appointments.delete, systemImage: "trash")
                                    }
                                }
                        }
                    }
                }
            }
            .padding(.vertical)
        }
    }
}

// MARK: - Appointment Card

struct AppointmentCard: View {
    let appointment: Appointment

    var body: some View {
        HStack(spacing: 16) {
            // 날짜 박스
            VStack(spacing: 4) {
                Text(dayText)
                    .font(.caption2)
                    .fontWeight(.medium)
                    .foregroundStyle(.secondary)

                Text("\(Calendar.current.component(.day, from: appointment.appointmentDate))")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundStyle(
                        appointment.isToday
                            ? LinearGradient(colors: [.blue, .purple], startPoint: .topLeading, endPoint: .bottomTrailing)
                            : LinearGradient(colors: [.primary], startPoint: .topLeading, endPoint: .bottomTrailing)
                    )

                Text(monthText)
                    .font(.caption2)
                    .fontWeight(.medium)
                    .foregroundStyle(.secondary)
            }
            .frame(width: 60)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(appointment.isToday ? Color.blue.opacity(0.1) : Color.gray.opacity(0.05))
            )

            // 예약 정보
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text(appointment.doctorName)
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundStyle(.primary)

                    if appointment.isCompleted {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 14))
                            .foregroundStyle(.green)
                    }

                    Spacer()

                    // 남은 시간
                    if appointment.isUpcoming, let text = appointment.timeRemainingText {
                        Text(text)
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundStyle(appointment.isToday ? .blue : .secondary)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(
                                Capsule()
                                    .fill(appointment.isToday ? Color.blue.opacity(0.1) : Color.gray.opacity(0.1))
                            )
                    }
                }

                if let specialty = appointment.specialty, !specialty.isEmpty {
                    Text(specialty)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                HStack(spacing: 12) {
                    Label {
                        Text(formatTime(appointment.appointmentDate))
                    } icon: {
                        Image(systemName: "clock.fill")
                    }
                    .font(.caption)
                    .foregroundStyle(.secondary)

                    if let location = appointment.location, !location.isEmpty {
                        Label {
                            Text(location)
                        } icon: {
                            Image(systemName: "mappin.circle.fill")
                        }
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                    }
                }
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.background)
                .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .strokeBorder(
                    appointment.isToday
                        ? LinearGradient(colors: [.blue.opacity(0.3), .purple.opacity(0.3)], startPoint: .topLeading, endPoint: .bottomTrailing)
                        : LinearGradient(colors: [.clear], startPoint: .topLeading, endPoint: .bottomTrailing),
                    lineWidth: 1
                )
        )
        .padding(.horizontal)
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
            ZStack {
                // 배경 그라데이션
                LinearGradient(
                    colors: [
                        Color.blue.opacity(0.05),
                        Color.purple.opacity(0.05)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 20) {
                        // 헤더 아이콘
                        ZStack {
                            Circle()
                                .fill(
                                    LinearGradient(
                                        colors: [Color.blue.opacity(0.2), Color.purple.opacity(0.2)],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .frame(width: 80, height: 80)

                            Image(systemName: "calendar.badge.plus")
                                .font(.system(size: 35))
                                .foregroundStyle(
                                    LinearGradient(
                                        colors: [.blue, .purple],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                        }
                        .padding(.top, 8)

                        VStack(spacing: 16) {
                            // 기본 정보
                            VStack(alignment: .leading, spacing: 12) {
                                SectionHeaderView(title: DMateResourceStrings.Appointments.basicInfo, icon: "person.text.rectangle")

                                VStack(spacing: 12) {
                                    ModernTextField(
                                        icon: "stethoscope",
                                        placeholder: DMateResourceStrings.Appointments.doctorNameRequired,
                                        text: $doctorName
                                    )

                                    ModernTextField(
                                        icon: "cross.case",
                                        placeholder: DMateResourceStrings.Appointments.departmentPlaceholder,
                                        text: $specialty
                                    )
                                }
                            }

                            // 예약 일시
                            VStack(alignment: .leading, spacing: 12) {
                                SectionHeaderView(title: DMateResourceStrings.Appointments.datetime, icon: "calendar.circle")

                                DatePicker(
                                    "",
                                    selection: $appointmentDate,
                                    in: Date()...,
                                    displayedComponents: [.date, .hourAndMinute]
                                )
                                .datePickerStyle(.graphical)
                                .padding()
                                .background(
                                    RoundedRectangle(cornerRadius: 16)
                                        .fill(.background)
                                        .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
                                )
                            }

                            // 장소
                            VStack(alignment: .leading, spacing: 12) {
                                SectionHeaderView(title: DMateResourceStrings.Appointments.locationSection, icon: "mappin.circle")

                                ModernTextField(
                                    icon: "building.2",
                                    placeholder: DMateResourceStrings.Appointments.locationPlaceholder,
                                    text: $location
                                )
                            }

                            // 알림
                            VStack(alignment: .leading, spacing: 12) {
                                SectionHeaderView(title: DMateResourceStrings.Appointments.notificationSection, icon: "bell.badge")

                                VStack(spacing: 12) {
                                    HStack {
                                        Image(systemName: "bell.fill")
                                            .font(.system(size: 16))
                                            .foregroundStyle(.blue)
                                            .frame(width: 24)

                                        Text(DMateResourceStrings.Appointments.enableNotification)
                                            .font(.subheadline)

                                        Spacer()

                                        Toggle("", isOn: $notificationEnabled)
                                            .labelsHidden()
                                    }
                                    .padding()
                                    .background(
                                        RoundedRectangle(cornerRadius: 16)
                                            .fill(.background)
                                            .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
                                    )

                                    if notificationEnabled {
                                        Picker(DMateResourceStrings.Appointments.notificationTime, selection: $notificationMinutesBefore) {
                                            Text(DMateResourceStrings.Appointments.onTime).tag(0)
                                            Text("30분 전").tag(30)
                                            Text("1시간 전").tag(60)
                                            Text("2시간 전").tag(120)
                                            Text("1일 전").tag(1440)
                                        }
                                        .pickerStyle(.menu)
                                        .padding()
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                        .background(
                                            RoundedRectangle(cornerRadius: 16)
                                                .fill(.background)
                                                .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
                                        )
                                    }
                                }
                            }

                            // 메모
                            VStack(alignment: .leading, spacing: 12) {
                                SectionHeaderView(title: DMateResourceStrings.Appointments.notesSection, icon: "note.text")

                                TextField(DMateResourceStrings.Appointments.notesPlaceholder, text: $notes, axis: .vertical)
                                    .lineLimit(3...5)
                                    .padding()
                                    .background(
                                        RoundedRectangle(cornerRadius: 16)
                                            .fill(.background)
                                            .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
                                    )
                            }
                        }
                        .padding(.horizontal)

                        // 저장 버튼
                        Button {
                            saveAppointment()
                        } label: {
                            HStack(spacing: 8) {
                                Image(systemName: "checkmark.circle.fill")
                                Text(DMateResourceStrings.Appointments.saveButton)
                                    .fontWeight(.semibold)
                            }
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(
                                LinearGradient(
                                    colors: doctorName.isEmpty ? [.gray] : [.blue, .purple],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                            .shadow(color: doctorName.isEmpty ? .clear : .blue.opacity(0.3), radius: 8, x: 0, y: 4)
                        }
                        .disabled(doctorName.isEmpty)
                        .padding(.horizontal)
                        .padding(.bottom)
                    }
                }
            }
            .navigationTitle(DMateResourceStrings.Appointments.addTitle)
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(.ultraThinMaterial, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 20))
                            .foregroundStyle(.secondary)
                    }
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
            ZStack {
                // 배경 그라데이션
                LinearGradient(
                    colors: [
                        Color.blue.opacity(0.05),
                        Color.purple.opacity(0.05)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 20) {
                        // 헤더 카드
                        VStack(spacing: 16) {
                            // 날짜 표시
                            VStack(spacing: 8) {
                                Text("\(Calendar.current.component(.day, from: appointment.appointmentDate))")
                                    .font(.system(size: 48, weight: .bold))
                                    .foregroundStyle(
                                        LinearGradient(
                                            colors: [.blue, .purple],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )

                                Text(appointment.dateDisplayText)
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                            }
                            .padding(.top, 8)

                            Divider()

                            // 의사 정보
                            VStack(spacing: 8) {
                                HStack {
                                    Image(systemName: "stethoscope")
                                        .font(.title3)
                                        .foregroundStyle(.blue)

                                    Text(appointment.doctorName)
                                        .font(.title3)
                                        .fontWeight(.semibold)

                                    if appointment.isCompleted {
                                        Image(systemName: "checkmark.circle.fill")
                                            .foregroundStyle(.green)
                                    }
                                }

                                if let specialty = appointment.specialty, !specialty.isEmpty {
                                    Text(specialty)
                                        .font(.subheadline)
                                        .foregroundStyle(.secondary)
                                }
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 20)
                                .fill(.background)
                                .shadow(color: .black.opacity(0.05), radius: 10, x: 0, y: 4)
                        )
                        .padding(.horizontal)
                        .padding(.top, 8)

                        // 상세 정보
                        VStack(spacing: 12) {
                            DetailRow(
                                icon: "clock.fill",
                                title: DMateResourceStrings.Appointments.timeLabel,
                                value: formatTime(appointment.appointmentDate),
                                color: .blue
                            )

                            if let location = appointment.location, !location.isEmpty {
                                DetailRow(
                                    icon: "mappin.circle.fill",
                                    title: DMateResourceStrings.Appointments.locationLabel,
                                    value: location,
                                    color: .green
                                )
                            }

                            if appointment.isUpcoming, let timeRemaining = appointment.timeRemainingText {
                                DetailRow(
                                    icon: "hourglass",
                                    title: DMateResourceStrings.Appointments.timeRemaining,
                                    value: timeRemaining,
                                    color: .orange
                                )
                            }
                        }
                        .padding(.horizontal)

                        // 메모
                        if let notes = appointment.notes, !notes.isEmpty {
                            VStack(alignment: .leading, spacing: 12) {
                                HStack {
                                    Image(systemName: "note.text")
                                        .foregroundStyle(.blue)
                                    Text(DMateResourceStrings.Appointments.notesLabel)
                                        .font(.headline)
                                        .fontWeight(.semibold)
                                }

                                Text(notes)
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                            }
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(.background)
                                    .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
                            )
                            .padding(.horizontal)
                        }

                        // 완료 버튼
                        if !appointment.isCompleted {
                            Button {
                                withAnimation {
                                    appointment.markAsCompleted()
                                    try? modelContext.save()
                                }
                                dismiss()
                            } label: {
                                HStack(spacing: 8) {
                                    Image(systemName: "checkmark.circle.fill")
                                    Text(DMateResourceStrings.Appointments.markCompleted)
                                        .fontWeight(.semibold)
                                }
                                .foregroundStyle(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .background(
                                    LinearGradient(
                                        colors: [.green, .blue],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .clipShape(RoundedRectangle(cornerRadius: 16))
                                .shadow(color: .green.opacity(0.3), radius: 8, x: 0, y: 4)
                            }
                            .padding(.horizontal)
                            .padding(.top, 8)
                        }
                    }
                    .padding(.bottom)
                }
            }
            .navigationTitle(DMateResourceStrings.Appointments.detailTitle)
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(.ultraThinMaterial, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 20))
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
    }
}

// MARK: - Detail Row

struct DetailRow: View {
    let icon: String
    let title: String
    let value: String
    let color: Color

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundStyle(color)
                .frame(width: 32, height: 32)
                .background(
                    Circle()
                        .fill(color.opacity(0.1))
                )

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Text(value)
                    .font(.subheadline)
                    .fontWeight(.medium)
            }

            Spacer()
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.background)
                .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
        )
    }
}

// MARK: - Modern TextField

struct ModernTextField: View {
    let icon: String
    let placeholder: String
    @Binding var text: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundStyle(.blue)
                .frame(width: 24)

            TextField(placeholder, text: $text)
                .font(.subheadline)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.background)
                .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
        )
    }
}

// MARK: - Section Header View

struct SectionHeaderView: View {
    let title: String
    let icon: String

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .foregroundStyle(.blue)
            Text(title)
                .font(.headline)
                .fontWeight(.semibold)
        }
        .padding(.horizontal, 4)
    }
}

// MARK: - Preview

#Preview {
    AppointmentView()
        .modelContainer(for: Appointment.self, inMemory: true)
}
