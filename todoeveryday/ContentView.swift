//
//  ContentView.swift
//  todoeveryday
//
//  Created by Gang Zhang on 1/6/26.
//

import SwiftUI
import SwiftData
import AppKit
import UniformTypeIdentifiers

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var viewModel: TodoViewModel?
    @State private var newItemTitle: String = ""
    @State private var selectedList: DailyTodoList?
    @State private var showingHistory: Bool = false
    @State private var showingStatistics: Bool = false
    @State private var showingExportAlert: Bool = false
    @State private var showingExportError: Bool = false
    @State private var exportErrorMessage: String = ""
    @State private var exportedFileURL: URL?
    @State private var visibleRecentDaysCount: Int = 7
    @State private var showingSettings: Bool = false
    @AppStorage("debugMode") private var debugMode: Bool = false
    @AppStorage("autoCarryover") private var autoCarryover: Bool = true
    @AppStorage("showCarryoverPopup") private var showCarryoverPopup: Bool = true
    @AppStorage("createWeekendDays") private var createWeekendDays: Bool = true

    // MARK: - Navigation Helper

    private func navigateTo(
        list: DailyTodoList? = nil,
        showHistory: Bool = false,
        showStats: Bool = false,
        showSettings: Bool = false
    ) {
        withAnimation {
            selectedList = list
            showingHistory = showHistory
            showingStatistics = showStats
            showingSettings = showSettings
        }
    }

    var body: some View {
        NavigationSplitView {
            VStack(spacing: 0) {
                List {
                    if let viewModel = viewModel {
                        ForEach(Array(viewModel.recentLists.prefix(visibleRecentDaysCount)), id: \.id) { list in
                            Button(action: { navigateTo(list: list) }) {
                                HStack {
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(list.isToday ? "Today" : list.weekdayString)
                                            .font(.headline)
                                        Text(list.shortDateString)
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                    Spacer()

                                    StatusBadge(
                                        icon: "checkmark.circle.fill",
                                        count: list.items.filter { $0.isCompleted }.count,
                                        color: .green
                                    )

                                    StatusBadge(
                                        icon: "circle",
                                        count: list.items.filter { !$0.isCompleted }.count,
                                        color: .orange
                                    )

                                    if !showingStatistics && !showingHistory && selectedList?.id == list.id {
                                        Image(systemName: "checkmark")
                                            .foregroundColor(.blue)
                                    }

                                    // Delete button in debug mode
                                    if debugMode {
                                        Button(action: {
                                            viewModel.deleteList(list)
                                            if selectedList?.id == list.id {
                                                selectedList = nil
                                            }
                                        }) {
                                            Image(systemName: "trash")
                                                .foregroundColor(.red)
                                                .font(.caption)
                                        }
                                        .buttonStyle(.plain)
                                    }
                                }
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .contentShape(Rectangle())
                            }
                            .buttonStyle(.plain)
                            .listRowBackground(
                                !showingStatistics && !showingHistory && selectedList?.id == list.id ?
                                Color.blue.opacity(0.1) : Color.clear
                            )
                        }

                        // Show More/Less buttons
                        if viewModel.recentLists.count > 7 {
                            if visibleRecentDaysCount < viewModel.recentLists.count {
                                // Show More button
                                Button(action: {
                                    withAnimation {
                                        visibleRecentDaysCount += 7
                                    }
                                }) {
                                    HStack {
                                        Image(systemName: "chevron.down")
                                        Text("Show 7 More Days")
                                        Spacer()
                                        Text("\(viewModel.recentLists.count - visibleRecentDaysCount)")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .contentShape(Rectangle())
                                }
                                .buttonStyle(.plain)
                                .foregroundColor(.blue)
                            } else if visibleRecentDaysCount > 7 {
                                // Show Less button
                                Button(action: {
                                    withAnimation {
                                        visibleRecentDaysCount = 7
                                    }
                                }) {
                                    HStack {
                                        Image(systemName: "chevron.up")
                                        Text("Show Less")
                                        Spacer()
                                    }
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .contentShape(Rectangle())
                                }
                                .buttonStyle(.plain)
                                .foregroundColor(.blue)
                            }
                        }

                        if !viewModel.olderLists.isEmpty {
                            Button(action: { navigateTo(showHistory: true) }) {
                                HStack {
                                    Image(systemName: "clock")
                                    Text("History")
                                    Spacer()
                                    if showingHistory {
                                        Image(systemName: "checkmark")
                                            .foregroundColor(.blue)
                                    }
                                }
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .contentShape(Rectangle())
                            }
                            .buttonStyle(.plain)
                            .listRowBackground(showingHistory ? Color.blue.opacity(0.1) : Color.clear)
                        }
                    }
                }
                .listStyle(.sidebar)

                // Settings & Stats Section
                Divider()

                if let viewModel = viewModel {
                    // Settings Button
                    Button(action: { navigateTo(showSettings: true) }) {
                        HStack {
                            Image(systemName: "gearshape.fill")
                            Text("Settings")
                            Spacer()
                            if showingSettings {
                                Image(systemName: "checkmark")
                                    .foregroundColor(.blue)
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .contentShape(Rectangle())
                        .padding()
                        .background(showingSettings ? Color.blue.opacity(0.1) : Color.clear)
                    }
                    .buttonStyle(.plain)

                    // Statistics Button
                    Button(action: { navigateTo(showStats: true) }) {
                        HStack {
                            Image(systemName: "chart.bar.fill")
                            Text("Statistics")
                            Spacer()
                            if showingStatistics {
                                Image(systemName: "checkmark")
                                    .foregroundColor(.blue)
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .contentShape(Rectangle())
                        .padding()
                        .background(showingStatistics ? Color.blue.opacity(0.1) : Color.clear)
                    }
                    .buttonStyle(.plain)
                }


                // DEBUG Section
                if let viewModel = viewModel {
                    Divider()
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Toggle("Debug Mode", isOn: $debugMode)
                            .toggleStyle(.switch)
                            .padding(.horizontal)
                            .padding(.top, 8)
                        
                        if debugMode {
                            VStack(spacing: 6) {
                                Button(action: {
                                    // Create the next sequential day with current settings
                                    viewModel.createNextDebugDay(autoCarryover: autoCarryover, createWeekendDays: createWeekendDays)
                                }) {
                                    HStack {
                                        Image(systemName: "plus.circle.fill")
                                        Text("Create Next Day")
                                            .font(.caption)
                                    }
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 6)
                                }
                                .buttonStyle(.bordered)
                                .controlSize(.small)
                                .tint(.orange)

                                Button(action: {
                                    // Create a previous day (going backwards) with current settings
                                    viewModel.createPreviousDebugDay(createWeekendDays: createWeekendDays)
                                }) {
                                    HStack {
                                        Image(systemName: "minus.circle.fill")
                                        Text("Create Previous Day")
                                            .font(.caption)
                                    }
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 6)
                                }
                                .buttonStyle(.bordered)
                                .controlSize(.small)
                                .tint(.blue)
                            }
                            .padding(.horizontal)
                            .padding(.bottom, 8)
                        }
                    }
                }
                // Export Button at Bottom
                VStack(spacing: 0) {
                    Divider()
                    Button(action: {
                        if let fileURL = viewModel?.exportToCSV() {
                            exportedFileURL = fileURL

                            // Open save panel
                            let savePanel = NSSavePanel()
                            savePanel.allowedContentTypes = [.commaSeparatedText]
                            savePanel.nameFieldStringValue = "TodoEveryday_Export_\(Date().formatted(date: .numeric, time: .omitted).replacingOccurrences(of: "/", with: "-")).csv"
                            savePanel.message = "Choose where to save your todo data"
                            savePanel.begin { response in
                                if response == .OK, let destinationURL = savePanel.url {
                                    do {
                                        // Remove existing file if present to avoid conflicts
                                        if FileManager.default.fileExists(atPath: destinationURL.path) {
                                            try FileManager.default.removeItem(at: destinationURL)
                                        }
                                        try FileManager.default.copyItem(at: fileURL, to: destinationURL)
                                        showingExportAlert = true
                                    } catch {
                                        // Show error to user instead of silent failure
                                        exportErrorMessage = error.localizedDescription
                                        showingExportError = true
                                    }
                                }
                            }
                        } else {
                            // Show error if export creation failed
                            exportErrorMessage = "Failed to create export file"
                            showingExportError = true
                        }
                    }) {
                        HStack(spacing: 4) {
                            Image(systemName: "square.and.arrow.up")
                                .font(.caption)
                            Text("Export to CSV")
                                .font(.caption)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.small)
                    .padding(.horizontal)
                    .padding(.vertical, 8)
                }
            }
            .navigationSplitViewColumnWidth(min: 200, ideal: 240)
        } detail: {
            if showingSettings {
                SettingsView(
                    autoCarryover: $autoCarryover,
                    showCarryoverPopup: $showCarryoverPopup,
                    createWeekendDays: $createWeekendDays
                )
            } else if showingStatistics {
                StatisticsDetailView(viewModel: viewModel)
            } else if showingHistory {
                HistoryView(viewModel: viewModel, debugMode: debugMode)
            } else if let selectedList = selectedList {
                DayDetailView(list: selectedList, viewModel: viewModel, newItemTitle: $newItemTitle, showCarryoverPopup: showCarryoverPopup)
            } else if let todaysList = viewModel?.todaysList {
                DayDetailView(list: todaysList, viewModel: viewModel, newItemTitle: $newItemTitle, showCarryoverPopup: showCarryoverPopup)
            } else {
                ProgressView()
            }
        }
        .onAppear {
            if viewModel == nil {
                viewModel = TodoViewModel(modelContext: modelContext)
                selectedList = viewModel?.todaysList
            }
        }
        .alert("Export Successful", isPresented: $showingExportAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text("Your todo data has been exported successfully!")
        }
        .alert("Export Failed", isPresented: $showingExportError) {
            Button("OK", role: .cancel) { }
        } message: {
            Text("Failed to save the export file: \(exportErrorMessage)")
        }
    }
}

struct DayDetailView: View {
    let list: DailyTodoList
    let viewModel: TodoViewModel?
    @Binding var newItemTitle: String
    let showCarryoverPopup: Bool
    @State private var newItemDeadline: Date?
    @State private var showDeadlinePicker: Bool = false
    @FocusState private var isInputFocused: Bool
    @FocusState private var isSummaryFocused: Bool

    private var summaryBinding: Binding<String> {
        Binding(
            get: { list.summary },
            set: { newValue in
                viewModel?.updateSummary(for: list, summary: newValue)
            }
        )
    }

    // Check if this list is the active "today" list (handles debug days)
    private var isActiveTodayList: Bool {
        viewModel?.todaysList?.id == list.id
    }

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text(isActiveTodayList ? "Today's Todo List" : list.weekdayString)
                    .font(.title)
                    .bold()
                Spacer()
                Text(list.dateString)
                    .foregroundColor(.secondary)
            }
            .padding()

            Divider()

            if isActiveTodayList {
                VStack(spacing: 8) {
                    HStack {
                        TextField("Add a new todo...", text: $newItemTitle)
                            .textFieldStyle(.plain)
                            .focused($isInputFocused)
                            .onSubmit {
                                addItem()
                            }

                        Button(action: {
                            showDeadlinePicker.toggle()
                        }) {
                            Image(systemName: showDeadlinePicker ? "calendar.badge.minus" : "calendar.badge.plus")
                                .font(.title2)
                                .foregroundColor(newItemDeadline != nil ? .blue : .secondary)
                        }
                        .buttonStyle(.plain)

                        Button(action: addItem) {
                            Image(systemName: "plus.circle.fill")
                                .font(.title2)
                        }
                        .buttonStyle(.plain)
                        .disabled(newItemTitle.isEmpty)
                    }

                    if showDeadlinePicker {
                        HStack {
                            DatePicker("Deadline:", selection: Binding(
                                get: { newItemDeadline ?? Date() },
                                set: { newItemDeadline = $0 }
                            ), displayedComponents: [.date, .hourAndMinute])
                            .datePickerStyle(.compact)

                            if newItemDeadline != nil {
                                Button(action: {
                                    newItemDeadline = nil
                                }) {
                                    Image(systemName: "xmark.circle.fill")
                                        .foregroundColor(.secondary)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(.top, 4)
                    }
                }
                .padding()

                Divider()
            }

            if list.items.isEmpty {
                VStack(spacing: 16) {
                    Image(systemName: "checkmark.circle")
                        .font(.system(size: 60))
                        .foregroundColor(.secondary)
                    Text("No todos yet")
                        .font(.title2)
                        .foregroundColor(.secondary)
                    Text("Add your first todo above")
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ScrollView {
                    VStack(spacing: 0) {
                        ForEach(list.topLevelItems.sortedForDisplay(), id: \.id) { item in
                            TodoItemRow(item: item, viewModel: viewModel, indentLevel: 0, showCarryoverPopup: showCarryoverPopup)
                            Divider()
                        }
                    }
                    .padding(.horizontal)
                }
            }

            Divider()

            VStack(alignment: .leading, spacing: 8) {
                Text("Day Summary")
                    .font(.headline)
                    .foregroundColor(.secondary)

                TextEditor(text: summaryBinding)
                    .font(.body)
                    .focused($isSummaryFocused)
                    .frame(minHeight: 80, maxHeight: 120)
                    .padding(8)
                    .background(Color.secondary.opacity(0.1))
                    .cornerRadius(8)
            }
            .padding()
        }
        .frame(minWidth: 400, minHeight: 300)
    }

    private func addItem() {
        guard !newItemTitle.isEmpty else { return }
        viewModel?.addTodoItem(title: newItemTitle, deadline: newItemDeadline)
        newItemTitle = ""
        newItemDeadline = nil
        showDeadlinePicker = false
        isInputFocused = true
    }
}

struct TodoItemRow: View {
    let item: TodoItem
    let viewModel: TodoViewModel?
    let indentLevel: Int
    let showCarryoverPopup: Bool
    @State private var isHovering: Bool = false
    @State private var showDeadlineEditor: Bool = false
    @State private var editingDeadline: Date = Date()
    @State private var isEditingTitle: Bool = false
    @State private var editingTitle: String = ""
    @State private var isAddingSubItem: Bool = false
    @State private var newSubItemTitle: String = ""
    @State private var showDescription: Bool = false
    @State private var editingDescription: String = ""
    @State private var isHoveringDescription: Bool = false
    @State private var showCarryoverAlert: Bool = false
    @FocusState private var isTitleFocused: Bool
    @FocusState private var isSubItemFocused: Bool
    @FocusState private var isDescriptionFocused: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    // Expand/collapse button for items with children
                    if !item.children.isEmpty {
                        Button(action: {
                            viewModel?.toggleItemExpansion(item)
                        }) {
                            Image(systemName: item.isExpanded ? "chevron.down" : "chevron.right")
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .frame(width: 12)
                        }
                        .buttonStyle(.plain)
                    } else {
                        // Spacer for alignment when no children
                        Color.clear.frame(width: 12)
                    }

                    Button(action: {
                        // Check if it's a carryover item and not completed, and if popup is enabled
                        if showCarryoverPopup && !item.isCompleted, let vm = viewModel, vm.isCarryoverItem(item) {
                            showCarryoverAlert = true
                        } else {
                            viewModel?.toggleItemCompletion(item)
                        }
                    }) {
                        Image(systemName: item.isCompleted ? "checkmark.circle.fill" : "circle")
                            .font(.title2)
                            .foregroundColor(item.isCompleted ? .green : (item.isOverdue ? .red : .secondary))
                    }
                    .buttonStyle(.plain)

                    // Carryover indicator badge with gradient color based on age
                    if let vm = viewModel, vm.isCarryoverItem(item) && !item.isCompleted {
                        let carryoverDays = vm.carryoverDaysCount(for: item)
                        Text("↻")
                            .font(.caption2)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                            .padding(2)
                            .background(vm.carryoverBadgeColor(for: item))
                            .clipShape(Circle())
                            .help(carryoverDays == 1
                                ? "This task was carried over from yesterday"
                                : "This task has been pending for \(carryoverDays) days")
                    }

                    VStack(alignment: .leading, spacing: 2) {
                        if isEditingTitle {
                            TextField("Task title", text: $editingTitle)
                                .textFieldStyle(.plain)
                                .focused($isTitleFocused)
                                .onSubmit {
                                    saveTitle()
                                }
                                .onAppear {
                                    isTitleFocused = true
                                }
                        } else {
                            ClickableTextView(
                                text: item.title,
                                isCompleted: item.isCompleted,
                                isOverdue: item.isOverdue,
                                isStrikethrough: item.isCompleted,
                                onEditTitle: {
                                    startEditing()
                                },
                                onSetDeadline: {
                                    editingDeadline = item.deadline ?? Date()
                                    showDeadlineEditor = true
                                },
                                onRemoveDeadline: item.deadline != nil ? {
                                    viewModel?.updateItemDeadline(item, deadline: nil)
                                } : nil,
                                onEditDescription: {
                                    editingDescription = item.itemDescription
                                    showDescription = true
                                },
                                onDelete: {
                                    viewModel?.deleteItem(item)
                                },
                                hasDeadline: item.deadline != nil
                            )
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .onTapGesture(count: 2) {
                                startEditing()
                            }
                        }

                        if let deadlineStr = item.deadlineString {
                            HStack(spacing: 4) {
                                Image(systemName: "clock")
                                    .font(.caption2)
                                Text(deadlineStr)
                                    .font(.caption)
                            }
                            .foregroundColor(item.isOverdue ? .red : .secondary)
                        }
                    }

                    Spacer()

                    if item.isCompleted, let completedDate = item.completedDate {
                        Text(completedDate.formatted(date: .omitted, time: .shortened))
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .padding(.trailing, 8)
                    }

                    // Description button with hover preview
                    Button(action: {
                        if !showDescription {
                            editingDescription = item.itemDescription
                        }
                        showDescription.toggle()
                    }) {
                        Image(systemName: !item.itemDescription.isEmpty ? "doc.text.fill" : "doc.text")
                            .foregroundColor(!item.itemDescription.isEmpty ? .orange : .secondary)
                    }
                    .buttonStyle(.plain)
                    .opacity(isHovering || !item.itemDescription.isEmpty ? 1.0 : 0.3)
                    .help(!item.itemDescription.isEmpty ? item.itemDescription : "")
                    .onHover { hovering in
                        if !item.itemDescription.isEmpty {
                            isHoveringDescription = hovering
                        }
                    }

                    // Plus button to add sub-item
                    Button(action: {
                        isAddingSubItem.toggle()
                    }) {
                        Image(systemName: "plus.circle")
                            .foregroundColor(.blue)
                    }
                    .buttonStyle(.plain)
                    .opacity(isHovering ? 1.0 : 0.3)

                    Button(action: {
                        viewModel?.deleteItem(item)
                    }) {
                        Image(systemName: "trash")
                            .foregroundColor(.red)
                    }
                    .buttonStyle(.plain)
                    .opacity(isHovering ? 1.0 : 0.3)
                }

                if showDeadlineEditor {
                    DeadlineEditor(
                        deadline: $editingDeadline,
                        onSave: {
                            viewModel?.updateItemDeadline(item, deadline: editingDeadline)
                            showDeadlineEditor = false
                        },
                        onClear: {
                            viewModel?.updateItemDeadline(item, deadline: nil)
                            showDeadlineEditor = false
                        },
                        onCancel: { showDeadlineEditor = false }
                    )
                    .padding(.leading, 44)
                    .padding(.vertical, 4)
                }

                // Add sub-item input field
                if isAddingSubItem {
                    HStack {
                        TextField("Add sub-item...", text: $newSubItemTitle)
                            .textFieldStyle(.plain)
                            .focused($isSubItemFocused)
                            .onSubmit {
                                addSubItem()
                            }

                        Button(action: addSubItem) {
                            Image(systemName: "plus.circle.fill")
                                .foregroundColor(.blue)
                        }
                        .buttonStyle(.plain)
                        .disabled(newSubItemTitle.isEmpty)

                        Button(action: {
                            isAddingSubItem = false
                            newSubItemTitle = ""
                        }) {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.secondary)
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(.leading, 44)
                    .padding(.vertical, 4)
                    .onAppear {
                        isSubItemFocused = true
                    }
                }

                // Description editor
                if showDescription {
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text("Description")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Spacer()
                            EditorActions(
                                onSave: {
                                    viewModel?.updateItemDescription(item, description: editingDescription)
                                    showDescription = false
                                },
                                onCancel: { showDescription = false }
                            )
                        }

                        TextEditor(text: $editingDescription)
                            .font(.body)
                            .focused($isDescriptionFocused)
                            .frame(minHeight: 60)
                            .padding(4)
                            .background(Color.secondary.opacity(0.1))
                            .cornerRadius(4)
                    }
                    .padding(.leading, 44)
                    .padding(.vertical, 4)
                    .onAppear {
                        isDescriptionFocused = true
                    }
                }
            }
            .padding(.vertical, 4)
            .onHover { hovering in
                isHovering = hovering
            }

            // Recursively display children with indentation
            if item.isExpanded && !item.children.isEmpty {
                ForEach(item.children.sorted { $0.sortOrder < $1.sortOrder }, id: \.id) { childItem in
                    TodoItemRow(item: childItem, viewModel: viewModel, indentLevel: indentLevel + 1, showCarryoverPopup: showCarryoverPopup)
                        .padding(.leading, 32)
                        .onDrag {
                            return NSItemProvider(object: childItem.id.uuidString as NSString)
                        }
                        .onDrop(of: [.text], delegate: SubItemDropDelegate(
                            item: childItem,
                            allChildren: item.children,
                            viewModel: viewModel
                        ))
                }
            }
        }
        .alert("Mark All Linked Tasks Complete?", isPresented: $showCarryoverAlert) {
            Button("Yes, Mark All") {
                viewModel?.toggleItemCompletion(item, markAllLinked: true)
            }
            Button("No, Just This One") {
                viewModel?.toggleItemCompletion(item, markAllLinked: false)
            }
            Button("Cancel", role: .cancel) {
                // Do nothing
            }
        } message: {
            if let vm = viewModel {
                let count = vm.linkedItemsCount(for: item)
                Text("This task appears in \(count) day(s). Do you want to mark it complete in all days, or just today?")
            }
        }
    }

    private func startEditing() {
        editingTitle = item.title
        isEditingTitle = true
    }

    private func saveTitle() {
        guard !editingTitle.isEmpty else {
            isEditingTitle = false
            return
        }
        viewModel?.updateItemTitle(item, title: editingTitle)
        isEditingTitle = false
    }

    private func addSubItem() {
        guard !newSubItemTitle.isEmpty else { return }
        viewModel?.addSubItem(to: item, title: newSubItemTitle)
        newSubItemTitle = ""
        isAddingSubItem = false
    }
}

struct SettingsView: View {
    @Binding var autoCarryover: Bool
    @Binding var showCarryoverPopup: Bool
    @Binding var createWeekendDays: Bool

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text("Settings")
                    .font(.title)
                    .bold()
                Spacer()
            }
            .padding()

            Divider()

            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // Carryover Settings
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Task Carryover")
                            .font(.title2)
                            .bold()

                        VStack(alignment: .leading, spacing: 12) {
                            Toggle(isOn: $autoCarryover) {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Auto-carryover unfinished tasks")
                                        .font(.body)
                                    Text("Automatically carry over incomplete tasks to the next day")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            }
                            .toggleStyle(.switch)

                            Toggle(isOn: $showCarryoverPopup) {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Show carryover completion dialog")
                                        .font(.body)
                                    Text("Ask whether to mark all linked tasks complete when completing a carried-over task")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            }
                            .toggleStyle(.switch)
                            .disabled(!autoCarryover)
                        }
                    }
                    .padding()
                    .background(Color.secondary.opacity(0.05))
                    .cornerRadius(12)

                    // Weekend Settings
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Schedule")
                            .font(.title2)
                            .bold()

                        VStack(alignment: .leading, spacing: 12) {
                            Toggle(isOn: $createWeekendDays) {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Create weekend days")
                                        .font(.body)
                                    Text("Automatically create new days on Saturdays and Sundays")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            }
                            .toggleStyle(.switch)
                        }
                    }
                    .padding()
                    .background(Color.secondary.opacity(0.05))
                    .cornerRadius(12)
                }
                .padding()
            }
        }
        .frame(minWidth: 400, minHeight: 300)
    }
}

struct StatisticsDetailView: View {
    let viewModel: TodoViewModel?

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text("Statistics")
                    .font(.title)
                    .bold()
                Spacer()
            }
            .padding()

            Divider()

            if let viewModel = viewModel {
                ScrollView {
                    VStack(alignment: .leading, spacing: 24) {
                        // Today's Stats Section
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Today's Stats")
                                .font(.title2)
                                .bold()

                            HStack(spacing: 20) {
                                StatCard(
                                    icon: "checkmark.circle.fill",
                                    color: .green,
                                    title: "Completed",
                                    value: "\(viewModel.todayCompletedTasks)"
                                )

                                StatCard(
                                    icon: "circle",
                                    color: .secondary,
                                    title: "Pending",
                                    value: "\(viewModel.todayPendingTasks)"
                                )

                                if viewModel.todayOverdueTasks > 0 {
                                    StatCard(
                                        icon: "exclamationmark.circle.fill",
                                        color: .red,
                                        title: "Overdue",
                                        value: "\(viewModel.todayOverdueTasks)"
                                    )
                                }
                            }

                            // Today's Progress
                            VStack(alignment: .leading, spacing: 8) {
                                HStack {
                                    Text("Progress")
                                        .font(.headline)
                                    Spacer()
                                    Text(String(format: "%.1f%%", viewModel.todayCompletionRate))
                                        .font(.title3)
                                        .bold()
                                }

                                ProgressView(value: viewModel.todayCompletionRate, total: 100)
                                    .progressViewStyle(.linear)
                                    .tint(.blue)
                            }
                            .padding()
                            .background(Color.secondary.opacity(0.1))
                            .cornerRadius(8)
                        }

                        Divider()

                        // All Time Stats Section
                        VStack(alignment: .leading, spacing: 12) {
                            Text("All Time Stats")
                                .font(.title2)
                                .bold()

                            HStack(spacing: 20) {
                                StatCard(
                                    icon: "checkmark.circle.fill",
                                    color: .green,
                                    title: "Completed",
                                    value: "\(viewModel.totalCompletedTasks)"
                                )

                                StatCard(
                                    icon: "circle",
                                    color: .secondary,
                                    title: "Pending",
                                    value: "\(viewModel.totalPendingTasks)"
                                )

                                StatCard(
                                    icon: "list.bullet",
                                    color: .blue,
                                    title: "Total",
                                    value: "\(viewModel.totalTasks)"
                                )
                            }
                        }

                        Divider()

                        // Performance Metrics
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Performance Metrics")
                                .font(.title2)
                                .bold()

                            VStack(spacing: 16) {
                                // Average completion time
                                HStack {
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text("Average Time to Complete")
                                            .font(.headline)
                                        Text("Per task across all days")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                    Spacer()
                                    Text(formatCompletionTime(viewModel.averageCompletionTimePerDay))
                                        .font(.title2)
                                        .bold()
                                        .foregroundColor(.blue)
                                }
                                .padding()
                                .background(Color.blue.opacity(0.1))
                                .cornerRadius(8)

                                // Average daily completion rate
                                HStack {
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text("Average Daily Completion Rate")
                                            .font(.headline)
                                        Text("Across all days")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                    Spacer()
                                    Text(String(format: "%.1f%%", viewModel.averageDailyCompletionRate))
                                        .font(.title2)
                                        .bold()
                                        .foregroundColor(.green)
                                }
                                .padding()
                                .background(Color.green.opacity(0.1))
                                .cornerRadius(8)
                            }
                        }

                        Divider()

                        // Recent Days Performance
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Recent Days Performance")
                                .font(.title2)
                                .bold()

                            VStack(spacing: 8) {
                                ForEach(viewModel.dailyCompletionRates.prefix(7), id: \.date) { item in
                                    HStack {
                                        VStack(alignment: .leading, spacing: 2) {
                                            Text(item.date.formatted(date: .abbreviated, time: .omitted))
                                                .font(.body)
                                            Text(getWeekday(for: item.date))
                                                .font(.caption)
                                                .foregroundColor(.secondary)
                                        }
                                        Spacer()

                                        HStack(spacing: 8) {
                                            ProgressView(value: item.rate, total: 100)
                                                .progressViewStyle(.linear)
                                                .frame(width: 100)
                                                .tint(getProgressColor(for: item.rate))

                                            Text(String(format: "%.0f%%", item.rate))
                                                .font(.body)
                                                .bold()
                                                .frame(width: 50, alignment: .trailing)
                                        }
                                    }
                                    .padding(.vertical, 4)
                                }
                            }
                            .padding()
                            .background(Color.secondary.opacity(0.05))
                            .cornerRadius(8)
                        }
                    }
                    .padding()
                }
            } else {
                ProgressView()
            }
        }
        .frame(minWidth: 400, minHeight: 300)
    }

    private func formatCompletionTime(_ minutes: Double) -> String {
        if minutes < 1 {
            return "< 1 min"
        } else if minutes < 60 {
            return String(format: "%.0f min", minutes)
        } else if minutes < 1440 {
            let hours = minutes / 60
            return String(format: "%.1f hrs", hours)
        } else {
            let days = minutes / 1440
            return String(format: "%.1f days", days)
        }
    }

    private func getWeekday(for date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE"
        return formatter.string(from: date)
    }

    private func getProgressColor(for rate: Double) -> Color {
        if rate >= 80 {
            return .green
        } else if rate >= 50 {
            return .orange
        } else {
            return .red
        }
    }
}

struct StatCard: View {
    let icon: String
    let color: Color
    let title: String
    let value: String

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title)
                .foregroundColor(color)
            Text(value)
                .font(.title)
                .bold()
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color.secondary.opacity(0.1))
        .cornerRadius(8)
    }
}

// MARK: - Reusable Components

/// Reusable badge component for displaying counts with an icon
struct StatusBadge: View {
    let icon: String
    let count: Int
    let color: Color

    var body: some View {
        HStack(spacing: 3) {
            Image(systemName: icon)
                .font(.caption2)
                .foregroundColor(color)
            Text("\(count)")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(.horizontal, 6)
        .padding(.vertical, 2)
        .background(color.opacity(0.1))
        .cornerRadius(10)
    }
}

/// Reusable deadline editor with save/clear/cancel buttons
struct DeadlineEditor: View {
    @Binding var deadline: Date
    let onSave: () -> Void
    let onClear: () -> Void
    let onCancel: () -> Void

    var body: some View {
        HStack {
            DatePicker("Deadline:", selection: $deadline, displayedComponents: [.date, .hourAndMinute])
                .datePickerStyle(.compact)
                .labelsHidden()

            Button("Save", action: onSave)
                .buttonStyle(.borderedProminent)
                .controlSize(.small)

            Button("Clear", action: onClear)
                .buttonStyle(.bordered)
                .controlSize(.small)

            Button("Cancel", action: onCancel)
                .buttonStyle(.bordered)
                .controlSize(.small)
        }
    }
}

/// Reusable save/cancel button pair for editors
struct EditorActions: View {
    let onSave: () -> Void
    let onCancel: () -> Void

    var body: some View {
        HStack {
            Button("Save", action: onSave)
                .buttonStyle(.borderedProminent)
                .controlSize(.small)

            Button("Cancel", action: onCancel)
                .buttonStyle(.bordered)
                .controlSize(.small)
        }
    }
}

struct HistoryView: View {
    let viewModel: TodoViewModel?
    let debugMode: Bool

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text("History")
                    .font(.title)
                    .bold()
                Spacer()
                Text("Older than 7 days")
                    .foregroundColor(.secondary)
            }
            .padding()

            Divider()

            if let lists = viewModel?.olderLists, !lists.isEmpty {
                List {
                    ForEach(lists, id: \.id) { list in
                        Section(header: HStack {
                            Text(list.dateString).font(.headline)
                            Spacer()
                            if debugMode {
                                Button(action: {
                                    viewModel?.deleteList(list)
                                }) {
                                    Image(systemName: "trash")
                                        .foregroundColor(.red)
                                        .font(.caption)
                                }
                                .buttonStyle(.plain)
                            }
                        }) {
                            if list.items.isEmpty {
                                Text("No items")
                                    .foregroundColor(.secondary)
                                    .italic()
                            } else {
                                ForEach(list.items, id: \.id) { item in
                                    VStack(alignment: .leading, spacing: 2) {
                                        HStack(alignment: .top) {
                                            Image(systemName: item.isCompleted ? "checkmark.circle.fill" : "circle")
                                                .foregroundColor(item.isCompleted ? .green : .secondary)
                                            ClickableTextView(
                                                text: item.title,
                                                isCompleted: item.isCompleted,
                                                isOverdue: false,
                                                isStrikethrough: item.isCompleted,
                                                onEditTitle: {},
                                                onSetDeadline: {},
                                                onRemoveDeadline: nil,
                                                onEditDescription: {},
                                                onDelete: {},
                                                hasDeadline: false
                                            )
                                            .frame(maxWidth: .infinity, alignment: .leading)
                                        }
                                        if let deadlineStr = item.deadlineString {
                                            HStack(spacing: 4) {
                                                Image(systemName: "clock")
                                                    .font(.caption2)
                                                Text(deadlineStr)
                                                    .font(.caption)
                                            }
                                            .foregroundColor(.secondary)
                                            .padding(.leading, 24)
                                        }
                                    }
                                }
                            }

                            if !list.summary.isEmpty {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Summary:")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                    Text(list.summary)
                                        .font(.body)
                                        .padding(8)
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                        .background(Color.secondary.opacity(0.1))
                                        .cornerRadius(8)
                                }
                                .padding(.top, 4)
                            }
                        }
                    }
                }
                .listStyle(.inset)
            } else {
                VStack(spacing: 16) {
                    Image(systemName: "clock")
                        .font(.system(size: 60))
                        .foregroundColor(.secondary)
                    Text("No history yet")
                        .font(.title2)
                        .foregroundColor(.secondary)
                    Text("History shows items older than 7 days")
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .frame(minWidth: 400, minHeight: 300)
    }
}

struct SubItemDropDelegate: DropDelegate {
    let item: TodoItem
    let allChildren: [TodoItem]
    let viewModel: TodoViewModel?

    func performDrop(info: DropInfo) -> Bool {
        return true
    }

    func dropEntered(info: DropInfo) {
        guard let draggedItemID = info.itemProviders(for: [.text]).first else { return }

        draggedItemID.loadItem(forTypeIdentifier: "public.text", options: nil) { (data, error) in
            guard let data = data as? Data,
                  let uuidString = String(data: data, encoding: .utf8),
                  let draggedUUID = UUID(uuidString: uuidString),
                  let draggedItem = allChildren.first(where: { $0.id == draggedUUID }),
                  draggedItem.id != item.id else { return }

            DispatchQueue.main.async {
                let sortedChildren = allChildren.sorted { $0.sortOrder < $1.sortOrder }
                guard let fromIndex = sortedChildren.firstIndex(where: { $0.id == draggedItem.id }),
                      let toIndex = sortedChildren.firstIndex(where: { $0.id == item.id }) else { return }

                viewModel?.moveSubItem(draggedItem, from: fromIndex, to: toIndex)
            }
        }
    }
}

#Preview {
    ContentView()
        .modelContainer(for: [DailyTodoList.self, TodoItem.self], inMemory: true)
}
