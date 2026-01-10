//
//  TodoViewModel.swift
//  todoeveryday
//
//  Created by Gang Zhang on 1/6/26.
//

import Foundation
import SwiftData

@Observable
class TodoViewModel {
    var modelContext: ModelContext
    var todaysList: DailyTodoList?
    var allLists: [DailyTodoList] = []
    var recentLists: [DailyTodoList] = []
    var olderLists: [DailyTodoList] = []

    // Cached statistics (updated when data changes)
    private var cachedAverageCompletionTime: Double = 0
    private var cachedDailyCompletionRates: [(date: Date, rate: Double)] = []

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
        cleanupDebugDays()  // Clean up debug days before loading lists
        loadAllLists()
        ensureTodaysList()
        separateRecentAndOlderLists()
    }

    // Clean up all debug-created days on app startup
    private func cleanupDebugDays() {
        let descriptor = FetchDescriptor<DailyTodoList>()
        do {
            let allLists = try modelContext.fetch(descriptor)
            let debugLists = allLists.filter { $0.isDebugCreated }
            for list in debugLists {
                modelContext.delete(list)
                print("DEBUG: Deleted debug-created list for \(list.date)")
            }
            try modelContext.save()
        } catch {
            print("Failed to cleanup debug days: \(error)")
        }
    }

    func loadAllLists() {
        let descriptor = FetchDescriptor<DailyTodoList>(
            sortBy: [SortDescriptor(\.date, order: .reverse)]
        )
        do {
            allLists = try modelContext.fetch(descriptor)
            recalculateStatistics()  // Calculate statistics after loading
        } catch {
            print("Failed to fetch lists: \(error)")
            allLists = []
        }
    }

    func separateRecentAndOlderLists() {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())

        recentLists = []
        olderLists = []

        for list in allLists {
            let daysDifference = calendar.dateComponents([.day], from: list.date, to: today).day ?? 0
            if daysDifference < 7 {
                recentLists.append(list)
            } else {
                olderLists.append(list)
            }
        }
    }

    // MARK: - Helper Methods

    /// Check if a date falls on a weekend (Saturday or Sunday)
    /// - Parameter date: The date to check
    /// - Returns: true if the date is Saturday (weekday 7) or Sunday (weekday 1)
    private func isWeekend(_ date: Date) -> Bool {
        let weekday = Calendar.current.component(.weekday, from: date)
        return weekday == 1 || weekday == 7  // 1 = Sunday, 7 = Saturday
    }

    func ensureTodaysList(createWeekendDays: Bool = true, autoCarryover: Bool = true) {
        let today = Calendar.current.startOfDay(for: Date())

        if let existingList = allLists.first(where: { Calendar.current.isDate($0.date, inSameDayAs: today) }) {
            todaysList = existingList
        } else {
            // Only create if it's not a weekend, or if weekend creation is enabled
            if !isWeekend(today) || createWeekendDays {
                createTodaysList(autoCarryover: autoCarryover)
            } else {
                let weekday = Calendar.current.component(.weekday, from: today)
                print("Skipping weekend day creation (today is \(weekday == 1 ? "Sunday" : "Saturday"))")
            }
        }
    }

    private func createTodaysList(autoCarryover: Bool = true) {
        let newList = DailyTodoList(date: Date())

        // Only carry over items if auto-carryover is enabled
        if autoCarryover {
            if let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: newList.date),
               let yesterdayList = allLists.first(where: { Calendar.current.isDate($0.date, inSameDayAs: yesterday) }) {
                // Only carry over top-level incomplete items (items without a parent)
                let incompleteTopLevelItems = yesterdayList.items.filter { !$0.isCompleted && $0.parent == nil }
                for item in incompleteTopLevelItems {
                    let newItem = copyItemWithChildren(item)
                    newList.items.append(newItem)
                    modelContext.insert(newItem)
                }
            }
        }

        modelContext.insert(newList)
        todaysList = newList
        allLists.insert(newList, at: 0)
        separateRecentAndOlderLists()

        saveContext()
    }

    // Helper function to recursively copy an item and its incomplete children
    // Preserves taskGroupId so all copies are linked together
    private func copyItemWithChildren(_ item: TodoItem, parent: TodoItem? = nil) -> TodoItem {
        let newItem = TodoItem(
            title: item.title,
            itemDescription: item.itemDescription,
            isCompleted: false,
            createdDate: Date(),
            deadline: item.deadline,
            parent: parent,
            sortOrder: item.sortOrder,
            taskGroupId: item.taskGroupId  // Preserve the task group ID!
        )

        // Recursively copy incomplete children, preserving their sortOrder and taskGroupId
        for child in item.children.sorted(by: { $0.sortOrder < $1.sortOrder }) where !child.isCompleted {
            let newChild = copyItemWithChildren(child, parent: newItem)
            newItem.children.append(newChild)
            modelContext.insert(newChild)
        }

        return newItem
    }
    
    // DEBUG: Manually create a day for a specific date (for testing carryover)
    // DEBUG: Manually create the next day after the most recent day
    func createNextDebugDay(autoCarryover: Bool = true, createWeekendDays: Bool = true) {
        // Find the most recent date (could be today or a future date if debug days exist)
        guard let mostRecentDate = allLists.map({ $0.date }).max() else {
            print("DEBUG: No lists exist, cannot create next day")
            return
        }

        // Create the next day after the most recent date
        guard let nextDay = Calendar.current.date(byAdding: .day, value: 1, to: mostRecentDate) else {
            print("DEBUG: Failed to calculate next day")
            return
        }

        let normalizedDate = Calendar.current.startOfDay(for: nextDay)

        // Skip if it's a weekend and weekend creation is disabled
        if isWeekend(normalizedDate) && !createWeekendDays {
            let weekday = Calendar.current.component(.weekday, from: normalizedDate)
            print("DEBUG: Skipping weekend day creation (next day is \(weekday == 1 ? "Sunday" : "Saturday"))")
            return
        }

        let calendar = Calendar.current

        // Check if a list already exists for this date (shouldn't happen, but be safe)
        if allLists.contains(where: { calendar.isDate($0.date, inSameDayAs: normalizedDate) }) {
            print("DEBUG: List already exists for \(normalizedDate)")
            return
        }

        // Create new list marked as debug-created
        let newList = DailyTodoList(date: normalizedDate, isDebugCreated: true)

        // Find the previous day's list to carry over incomplete items (if auto-carryover is enabled)
        if autoCarryover {
            if let previousList = allLists.first(where: { calendar.isDate($0.date, inSameDayAs: mostRecentDate) }) {
                // Only carry over top-level incomplete items
                let incompleteTopLevelItems = previousList.items.filter { !$0.isCompleted && $0.parent == nil }
                for item in incompleteTopLevelItems {
                    let newItem = copyItemWithChildren(item)
                    newList.items.append(newItem)
                    modelContext.insert(newItem)
                }
            }
        }

        modelContext.insert(newList)
        allLists.insert(newList, at: 0)
        allLists.sort { $0.date > $1.date }
        separateRecentAndOlderLists()

        // Make this new debug day the active "today" so items can be added to it
        todaysList = newList

        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        print("DEBUG: Created list for \(formatter.string(from: normalizedDate)) with \(newList.items.count) items")
        print("DEBUG: Set as active 'today' list for testing")

        saveContext()
    }

    // DEBUG: Create a day before the oldest day (for testing historical data)
    func createPreviousDebugDay(createWeekendDays: Bool = true) {
        // Find the oldest date
        guard let oldestDate = allLists.map({ $0.date }).min() else {
            print("DEBUG: No lists exist, cannot create previous day")
            return
        }

        // Create the day before the oldest date
        guard let previousDay = Calendar.current.date(byAdding: .day, value: -1, to: oldestDate) else {
            print("DEBUG: Failed to calculate previous day")
            return
        }

        let normalizedDate = Calendar.current.startOfDay(for: previousDay)

        // Skip if it's a weekend and weekend creation is disabled
        if isWeekend(normalizedDate) && !createWeekendDays {
            let weekday = Calendar.current.component(.weekday, from: normalizedDate)
            print("DEBUG: Skipping weekend day creation (previous day is \(weekday == 1 ? "Sunday" : "Saturday"))")
            return
        }

        let calendar = Calendar.current

        // Check if a list already exists for this date (shouldn't happen, but be safe)
        if allLists.contains(where: { calendar.isDate($0.date, inSameDayAs: normalizedDate) }) {
            print("DEBUG: List already exists for \(normalizedDate)")
            return
        }

        // Create new empty list marked as debug-created (no carryover since we're going backwards)
        let newList = DailyTodoList(date: normalizedDate, isDebugCreated: true)

        modelContext.insert(newList)
        allLists.append(newList)
        allLists.sort { $0.date > $1.date }
        separateRecentAndOlderLists()

        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        print("DEBUG: Created previous day list for \(formatter.string(from: normalizedDate))")

        saveContext()
    }

    func addTodoItem(title: String, deadline: Date? = nil) {
        guard let todaysList = todaysList, !title.isEmpty else { return }

        // Calculate the next sortOrder for top-level items
        let maxSortOrder = todaysList.items.filter { $0.parent == nil }.map { $0.sortOrder }.max() ?? -1
        let newItem = TodoItem(title: title, isCompleted: false, createdDate: Date(), deadline: deadline, sortOrder: maxSortOrder + 1)
        todaysList.items.append(newItem)
        modelContext.insert(newItem)

        saveContext()
    }

    func addSubItem(to parentItem: TodoItem, title: String) {
        guard !title.isEmpty else { return }

        // Increment sortOrder of all existing children to make room at the top
        for child in parentItem.children {
            child.sortOrder += 1
        }

        // Create new sub-item with sortOrder 0 (top position)
        let newSubItem = TodoItem(title: title, isCompleted: false, createdDate: Date(), deadline: nil, parent: parentItem, sortOrder: 0)
        parentItem.children.append(newSubItem)
        modelContext.insert(newSubItem)

        saveContext()
    }

    func moveSubItem(_ item: TodoItem, from oldIndex: Int, to newIndex: Int) {
        guard let parent = item.parent else { return }

        // Get sorted children
        let sortedChildren = parent.children.sorted { $0.sortOrder < $1.sortOrder }

        // Reorder based on the move
        if oldIndex < newIndex {
            // Moving down
            for i in (oldIndex + 1)...newIndex {
                sortedChildren[i].sortOrder -= 1
            }
        } else {
            // Moving up
            for i in newIndex..<oldIndex {
                sortedChildren[i].sortOrder += 1
            }
        }

        item.sortOrder = newIndex

        saveContext()
    }

    func toggleItemExpansion(_ item: TodoItem) {
        item.isExpanded.toggle()
        saveContext()
    }

    func updateItemDeadline(_ item: TodoItem, deadline: Date?) {
        item.deadline = deadline
        saveContext()
    }

    func updateItemTitle(_ item: TodoItem, title: String) {
        item.title = title
        saveContext()
    }

    func updateItemDescription(_ item: TodoItem, description: String) {
        item.itemDescription = description
        saveContext()
    }

    /// Check if an item is a carryover from a previous day
    /// Uses efficient contains(where:) for early exit instead of creating arrays
    func isCarryoverItem(_ item: TodoItem) -> Bool {
        guard let itemList = item.dailyList else { return false }

        // More efficient: use contains instead of creating arrays and filtering
        return allLists.contains { list in
            list.date < itemList.date &&
            list.items.contains { $0.taskGroupId == item.taskGroupId && $0.id != item.id }
        }
    }

    /// Get count of linked items across all days
    /// Uses reduce for efficient counting without intermediate arrays
    func linkedItemsCount(for item: TodoItem) -> Int {
        return allLists.reduce(0) { count, list in
            count + list.items.filter { $0.taskGroupId == item.taskGroupId }.count
        }
    }

    func toggleItemCompletion(_ item: TodoItem, markAllLinked: Bool = true) {
        let wasCompleted = item.isCompleted
        let newCompletionState = !item.isCompleted
        let completionDate = newCompletionState ? Date() : nil

        if markAllLinked {
            // More efficient: single pass through lists without creating intermediate arrays
            for list in allLists {
                for listItem in list.items where listItem.taskGroupId == item.taskGroupId {
                    listItem.isCompleted = newCompletionState
                    listItem.completedDate = completionDate
                }
            }
        } else {
            // Only update this specific item
            item.isCompleted = newCompletionState
            item.completedDate = completionDate
        }

        // Play sound only when marking as complete (not when uncompleting)
        if !wasCompleted && newCompletionState {
            SoundManager.shared.playCompletionSound()
        }

        saveContext()
    }

    func deleteItem(_ item: TodoItem) {
        modelContext.delete(item)
        saveContext()
    }

    // DEBUG: Delete a day list (including today if in debug mode)
    func deleteList(_ list: DailyTodoList) {
        modelContext.delete(list)
        allLists.removeAll { $0.id == list.id }

        // If we deleted todaysList, set it to nil and recalculate
        if todaysList?.id == list.id {
            todaysList = nil
            ensureTodaysList()
        }

        separateRecentAndOlderLists()
        saveContext()
    }

    func updateSummary(for list: DailyTodoList, summary: String) {
        list.summary = summary
        saveContext()
    }

    var totalCompletedTasks: Int {
        allLists.flatMap { $0.items }.filter { $0.isCompleted }.count
    }

    var totalPendingTasks: Int {
        allLists.flatMap { $0.items }.filter { !$0.isCompleted }.count
    }

    var todayCompletedTasks: Int {
        todaysList?.items.filter { $0.isCompleted }.count ?? 0
    }

    var todayPendingTasks: Int {
        todaysList?.items.filter { !$0.isCompleted }.count ?? 0
    }

    var todayOverdueTasks: Int {
        todaysList?.items.filter { $0.isOverdue }.count ?? 0
    }

    // Average completion time per day (in minutes)
    /// Average time to complete tasks (in minutes), cached for performance
    var averageCompletionTimePerDay: Double {
        return cachedAverageCompletionTime
    }

    /// Daily completion rates (percentage), cached for performance
    var dailyCompletionRates: [(date: Date, rate: Double)] {
        return cachedDailyCompletionRates
    }

    // Average daily completion rate
    var averageDailyCompletionRate: Double {
        let rates = dailyCompletionRates
        guard !rates.isEmpty else { return 0 }
        let sum = rates.reduce(0.0) { $0 + $1.rate }
        return sum / Double(rates.count)
    }

    // Total tasks (completed + pending)
    var totalTasks: Int {
        allLists.flatMap { $0.items }.count
    }

    // Today's completion rate
    var todayCompletionRate: Double {
        guard let todaysList = todaysList else { return 0 }
        let total = todaysList.items.count
        guard total > 0 else { return 0 }
        let completed = todaysList.items.filter { $0.isCompleted }.count
        return (Double(completed) / Double(total)) * 100
    }

    // MARK: - CSV Export

    /// Escapes CSV field to prevent formula injection attacks
    /// Adds single quote prefix if field starts with potentially dangerous characters
    private func escapeCsvField(_ field: String) -> String {
        var escaped = field.replacingOccurrences(of: "\"", with: "\"\"")

        // Prevent formula injection (=, +, -, @ can trigger formulas in Excel)
        let dangerousStarters = ["=", "+", "-", "@", "\t", "\r"]
        if dangerousStarters.contains(where: { escaped.hasPrefix($0) }) {
            escaped = "'" + escaped
        }

        return escaped
    }

    func exportToCSV() -> URL? {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"

        var csvText = "Date,Level,Title,Description,Status,Created,Completed,Deadline,Overdue\n"

        for list in allLists {
            // Only export top-level items, children will be exported recursively
            let topLevelItems = list.items.filter { $0.parent == nil }
            for item in topLevelItems {
                exportItemToCSV(item, list: list, formatter: formatter, csvText: &csvText, level: 0)
            }
        }

        let fileName = "TodoEveryday_Export_\(Date().timeIntervalSince1970).csv"
        let fileURL = FileManager.default.temporaryDirectory.appendingPathComponent(fileName)

        do {
            try csvText.write(to: fileURL, atomically: true, encoding: .utf8)
            return fileURL
        } catch {
            print("Failed to export CSV: \(error)")
            return nil
        }
    }

    private func exportItemToCSV(_ item: TodoItem, list: DailyTodoList, formatter: DateFormatter, csvText: inout String, level: Int) {
        let date = list.dateString
        let indent = String(repeating: "  ", count: level)
        let title = escapeCsvField(indent + item.title)
        let description = escapeCsvField(item.itemDescription)
        let status = item.isCompleted ? "Completed" : "Pending"
        let created = formatter.string(from: item.createdDate)
        let completed = item.completedDate != nil ? formatter.string(from: item.completedDate!) : ""
        let deadline = item.deadline != nil ? formatter.string(from: item.deadline!) : ""
        let overdue = item.isOverdue ? "Yes" : "No"

        csvText += "\"\(date)\",\"\(level)\",\"\(title)\",\"\(description)\",\"\(status)\",\"\(created)\",\"\(completed)\",\"\(deadline)\",\"\(overdue)\"\n"

        // Recursively export children
        for child in item.children {
            exportItemToCSV(child, list: list, formatter: formatter, csvText: &csvText, level: level + 1)
        }
    }

    /// Recalculate cached statistics when data changes
    private func recalculateStatistics() {
        // Recalculate average completion time
        var totalMinutes: Double = 0
        var daysWithCompletedTasks = 0

        for list in allLists {
            let completedItems = list.items.filter { $0.isCompleted && $0.completedDate != nil }
            if !completedItems.isEmpty {
                var dayTotalMinutes: Double = 0
                for item in completedItems {
                    let timeInterval = item.completedDate!.timeIntervalSince(item.createdDate)
                    dayTotalMinutes += timeInterval / 60
                }
                totalMinutes += dayTotalMinutes / Double(completedItems.count)
                daysWithCompletedTasks += 1
            }
        }

        cachedAverageCompletionTime = daysWithCompletedTasks > 0 ? totalMinutes / Double(daysWithCompletedTasks) : 0

        // Recalculate daily completion rates
        cachedDailyCompletionRates = allLists.map { list in
            let total = list.items.count
            let completed = list.items.filter { $0.isCompleted }.count
            let rate = total > 0 ? (Double(completed) / Double(total)) * 100 : 0
            return (date: list.date, rate: rate)
        }
    }

    private func saveContext() {
        do {
            try modelContext.save()
            recalculateStatistics()  // Update cached statistics after save
        } catch {
            print("Failed to save context: \(error)")
        }
    }
}
