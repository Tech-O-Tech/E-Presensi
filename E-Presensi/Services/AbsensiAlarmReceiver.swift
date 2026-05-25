//
//  AbsensiAlarmReceiver.swift
//  E-Presensi
//
//  Setara id.go.pringsewukab.presensi.ui.AbsensiAlarmReceiver (Android)
//

import Foundation
import UserNotifications

enum AbsensiAlarmReceiver {

    /// Setara onReceive — dipanggil saat notifikasi akan/telah ditampilkan
    static func onAlarmFired(type: String) {
        if AbsensiReminderManager.isWeekend() {
            #if DEBUG
            print("[AbsensiAlarm] Weekend — skip notifikasi \(type)")
            #endif
            AbsensiReminderManager.rescheduleNextDay(type: type)
            return
        }
        AbsensiReminderManager.rescheduleNextDay(type: type)
    }

    /// Setara ACTION_STOP_ALARM
    static func onStopAlarm() {
        AbsensiReminderManager.stopAlarm()
    }

    static func handleResponse(_ response: UNNotificationResponse) {
        if response.actionIdentifier == AbsensiReminderManager.actionStop {
            onStopAlarm()
            return
        }
        if let type = response.notification.request.content.userInfo[AbsensiReminderManager.extraType] as? String {
            onAlarmFired(type: type)
        }
        if response.actionIdentifier == UNNotificationDefaultActionIdentifier {
            onStopAlarm()
        }
    }

    static func presentationOptions(for notification: UNNotification) -> UNNotificationPresentationOptions? {
        guard AbsensiReminderManager.shouldPresentBanner(for: notification) else {
            return nil
        }
        if AbsensiReminderManager.isWeekend() {
            onStopAlarm()
            return []
        }
        if let type = notification.request.content.userInfo[AbsensiReminderManager.extraType] as? String {
            onAlarmFired(type: type)
        }
        return [.banner, .sound, .badge]
    }
}
