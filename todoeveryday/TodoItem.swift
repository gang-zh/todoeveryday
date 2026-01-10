//
//  TodoItem.swift
//  todoeveryday
//
//  Created by Gang Zhang on 1/6/26.
//

import Foundation
import SwiftData

@Model
final class TodoItem {
    var id: UUID
    var title: String
    var itemDescription: String
    var isCompleted: Bool
    var createdDate: Date
    var completedDate: Date?
    var deadline: Date?
    var isExpanded: Bool
    var sortOrder: Int
    var taskGroupId: UUID  // Links all instances of the same task across days

    @Relationship(deleteRule: .nullify, inverse: \DailyTodoList.items)
    var dailyList: DailyTodoList?

    @Relationship(deleteRule: .nullify, inverse: \TodoItem.children)
    var parent: TodoItem?

    @Relationship(deleteRule: .cascade)
    var children: [TodoItem]

    init(title: String, itemDescription: String = "", isCompleted: Bool = false, createdDate: Date = Date(), deadline: Date? = nil, parent: TodoItem? = nil, sortOrder: Int = 0, taskGroupId: UUID? = nil) {
        self.id = UUID()
        self.title = title
        self.itemDescription = itemDescription
        self.isCompleted = isCompleted
        self.createdDate = createdDate
        self.completedDate = nil
        self.deadline = deadline
        self.isExpanded = true
        self.children = []
        self.parent = parent
        self.sortOrder = sortOrder
        self.taskGroupId = taskGroupId ?? UUID()  // If not provided, create a new group
    }

    var isOverdue: Bool {
        guard let deadline = deadline, !isCompleted else { return false }
        return deadline < Date()
    }

    var deadlineString: String? {
        guard let deadline = deadline else { return nil }
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d, h:mm a"
        return formatter.string(from: deadline)
    }
}

// MARK: - Array Extension for Sorting

extension Array where Element == TodoItem {
    /// Sorts items for display with smart prioritization:
    /// 1. Incomplete items before completed items
    /// 2. For incomplete items, sort by deadline (items with deadlines first, then by date)
    /// 3. Fall back to creation date for items in the same category
    func sortedForDisplay() -> [TodoItem] {
        sorted { item1, item2 in
            // Rule 1: Incomplete items first
            if item1.isCompleted != item2.isCompleted {
                return !item1.isCompleted
            }

            // Rule 2: For incomplete items, prioritize by deadline
            if !item1.isCompleted {
                switch (item1.deadline, item2.deadline) {
                case (.some(let d1), .some(let d2)):
                    return d1 < d2  // Earlier deadline first
                case (.some, .none):
                    return true  // Items with deadlines before items without
                case (.none, .some):
                    return false  // Items without deadlines after items with
                default:
                    break  // Both nil, fall through to creation date
                }
            }

            // Rule 3: Fall back to creation date (older first)
            return item1.createdDate < item2.createdDate
        }
    }
}
