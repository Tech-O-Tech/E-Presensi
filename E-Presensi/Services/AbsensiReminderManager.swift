//
//  AbsensiReminderManager.swift
//  E-Presensi
//
//  Setara AbsensiReminderManager + AbsensiAlarmReceiver Android
//  Jadwal: 07:15 pagi, 12:00 siang, 16:00 sore (Sen–Jum)
//

import Foundation
import UserNotifications
import UIKit
import Combine

enum AbsensiReminderManager {

    static let channelId = "ch_presensi_reminder_v2"
    static let idPrefix = "absensi_reminder_"

    static let extraType = "absen_type"
    static let typePagi = "pagi"
    static let typeSiang = "siang"
    static let typeSore = "sore"

    static let actionStop = "ACTION_STOP_ALARM"
    static let categoryId = "CAT_PRESENSI_REMINDER"

    private static let jadwal: [String: (hour: Int, minute: Int)] = [
        typePagi: (7, 15),
        typeSiang: (12, 0),
        typeSore: (16, 0)
    ]

  /// Senin=2 … Jumat=6 (Calendar weekday, Minggu=1)
    private static let weekdays = [2, 3, 4, 5, 6]

    // MARK: - Public

    static func scheduleAll() {
        registerCategories()
        requestAuthorization { granted in
            guard granted else {
                #if DEBUG
                print("[AbsensiReminder] Izin notifikasi ditolak — alarm tidak dijadwalkan")
                #endif
                return
            }
            cancelAllPending {
                scheduleWeekdayAlarms()
            }
        }
    }

    static func cancelAll() {
        cancelAllPending(completion: nil)
        stopAlarm()
    }

    /// Setara rescheduleNextDay — pada iOS trigger mingguan sudah mengulang otomatis
    static func rescheduleNextDay(type: String) {
        #if DEBUG
        print("[AbsensiReminder] rescheduleNextDay(\(type)) — tidak diperlukan (repeating weekday)")
        #endif
    }

    static func stopAlarm() {
        UNUserNotificationCenter.current().removeAllDeliveredNotifications()
        UNUserNotificationCenter.current().removePendingNotificationRequests(
            withIdentifiers: pendingStopIdentifiers()
        )
    }

    static func handleNotificationResponse(_ response: UNNotificationResponse) {
        if response.actionIdentifier == actionStop {
            stopAlarm()
            return
        }
        if response.actionIdentifier == UNNotificationDefaultActionIdentifier {
            stopAlarm()
        }
    }

    static func shouldPresentBanner(for notification: UNNotification) -> Bool {
        notification.request.identifier.hasPrefix(idPrefix)
    }

    // MARK: - Authorization

    private static func requestAuthorization(completion: @escaping (Bool) -> Void) {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, _ in
            DispatchQueue.main.async { completion(granted) }
        }
    }

    // MARK: - Categories

    private static func registerCategories() {
        let stop = UNNotificationAction(
            identifier: actionStop,
            title: "Matikan Alarm",
            options: [.destructive]
        )
        let category = UNNotificationCategory(
            identifier: categoryId,
            actions: [stop],
            intentIdentifiers: [],
            options: [.customDismissAction]
        )
        UNUserNotificationCenter.current().setNotificationCategories([category])
    }

    // MARK: - Scheduling

    private static func scheduleWeekdayAlarms() {
        let center = UNUserNotificationCenter.current()
        for (type, time) in jadwal {
            let content = buildContent(type: type)
            for weekday in weekdays {
                var components = DateComponents()
                components.weekday = weekday
                components.hour = time.hour
                components.minute = time.minute
                components.second = 0

                let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)
                let id = identifier(type: type, weekday: weekday)
                let request = UNNotificationRequest(identifier: id, content: content, trigger: trigger)
                center.add(request) { error in
                    #if DEBUG
                    if let error {
                        print("[AbsensiReminder] Gagal jadwal \(id): \(error.localizedDescription)")
                    }
                    #endif
                }
            }
        }
    }

    private static func buildContent(type: String) -> UNMutableNotificationContent {
        let info = notificationCopy(type: type)
        let content = UNMutableNotificationContent()
        content.title = "\(info.emoji)  \(info.title)"
        content.body = info.body
        content.sound = .default
        content.categoryIdentifier = categoryId
        content.userInfo = [extraType: type]
        if #available(iOS 15.0, *) {
            content.interruptionLevel = .timeSensitive
        }
        return content
    }

    private static func notificationCopy(type: String) -> (title: String, body: String, emoji: String) {
        switch type {
        case typePagi:
            return (
                "Waktunya Absen Pagi!",
                "Sudah pukul 07.15 — segera lakukan presensi pagi.",
                "🌅"
            )
        case typeSiang:
            return (
                "Waktunya Absen Siang!",
                "Sudah pukul 12.00 — jangan lupa presensi siang.",
                "☀️"
            )
        case typeSore:
            return (
                "Waktunya Absen Pulang!",
                "Sudah pukul 16.00 — segera lakukan presensi pulang.",
                "🌇"
            )
        default:
            return ("Pengingat Presensi", "Segera lakukan presensi.", "📋")
        }
    }

    private static func identifier(type: String, weekday: Int) -> String {
        "\(idPrefix)\(type)_wd\(weekday)"
    }

    private static func allIdentifiers() -> [String] {
        jadwal.keys.flatMap { type in
            weekdays.map { identifier(type: type, weekday: $0) }
        }
    }

    private static func cancelAllPending(completion: (() -> Void)?) {
        UNUserNotificationCenter.current().removePendingNotificationRequests(
            withIdentifiers: allIdentifiers()
        )
        DispatchQueue.main.async { completion?() }
    }

    private static func pendingStopIdentifiers() -> [String] {
        allIdentifiers()
    }

    /// Dipanggil saat notifikasi akan tampil (setara cek weekend di receiver Android)
    static func isWeekend() -> Bool {
        let calendar = Calendar.current
        let weekday = calendar.component(.weekday, from: Date())
        // In Gregorian calendars, weekday: 1=Sunday ... 7=Saturday
        return weekday == 1 || weekday == 7
    }
}

