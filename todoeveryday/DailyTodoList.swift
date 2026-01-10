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
    // MARK: - Static DateFormatters (avoid repeated allocation)

    private static let mediumFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter
    }()

    private static let shortFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        return formatter
    }()

    private static let weekdayFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE"
        return formatter
    }()

    // MARK: - Properties

    var id: UUID
    var date: Date
    var summary: String
    var isDebugCreated: Bool  // Mark days created by debug mode

    @Relationship(deleteRule: .cascade)
    var items: [TodoItem]

    // MARK: - Initialization

    init(date: Date = Date(), summary: String = "", isDebugCreated: Bool = false) {
        self.id = UUID()
        self.date = Calendar.current.startOfDay(for: date)
        self.summary = summary
        self.isDebugCreated = isDebugCreated
        self.items = []
    }

    // MARK: - Computed Properties

    /// Top-level items (no parent) for display
    var topLevelItems: [TodoItem] {
        items.filter { $0.parent == nil }
    }

    var dateString: String {
        Self.mediumFormatter.string(from: date)
    }

    var shortDateString: String {
        Self.shortFormatter.string(from: date)
    }

    var weekdayString: String {
        Self.weekdayFormatter.string(from: date)
    }

    var isToday: Bool {
        Calendar.current.isDateInToday(date)
    }
}
