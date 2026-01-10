//
//  DailyTodoList.swift
//  todoeveryday
//
//  Created by Gang Zhang on 1/6/26.
//

import Foundation
import SwiftData

@Model
final class DailyTodoList {
    var id: UUID
    var date: Date
    var summary: String
    var isDebugCreated: Bool  // Mark days created by debug mode

    @Relationship(deleteRule: .cascade)
    var items: [TodoItem]

    init(date: Date = Date(), summary: String = "", isDebugCreated: Bool = false) {
        self.id = UUID()
        self.date = Calendar.current.startOfDay(for: date)
        self.summary = summary
        self.isDebugCreated = isDebugCreated
        self.items = []
    }

    var dateString: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }

    var shortDateString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        return formatter.string(from: date)
    }

    var weekdayString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE"
        return formatter.string(from: date)
    }

    var isToday: Bool {
        Calendar.current.isDateInToday(date)
    }
}
