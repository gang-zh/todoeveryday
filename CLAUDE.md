# CLAUDE.MD - Development Guide for AI Assistants

This document provides context and guidelines for AI assistants working on the TodoEveryday macOS application.

## Project Context

TodoEveryday is a personal daily task management application for macOS built with SwiftUI and SwiftData. The user manages their tasks day-by-day, with automatic carryover of incomplete items.

### Key User Preferences
- The user is **new to macOS development** - provide clear explanations
- **Always proceed with implementation** - user has set "always approve" mode
- Focus on **simplicity** - avoid over-engineering
- **Local-only** - no cloud sync, all data stored locally

## Architecture Overview

### Technology Stack
- **SwiftUI**: Declarative UI framework
- **SwiftData**: Data persistence (similar to Core Data but simpler)
- **AppKit**: Used for native macOS features (NSSavePanel, NSTextView)
- **AVFoundation**: Audio playback for completion sounds
- **MVVM Pattern**: Model-View-ViewModel architecture

### File Structure
```
todoeveryday/
├── todoeverydayApp.swift          # App entry point, ModelContainer setup
├── ContentView.swift              # Main UI, navigation, sidebar, all views
├── TodoItem.swift                 # Task model (@Model class) with hierarchy
├── DailyTodoList.swift           # Daily list model (@Model class)
├── TodoViewModel.swift           # Business logic (@Observable class)
├── URLHelper.swift               # URL detection and ClickableTextView
├── SoundManager.swift            # Audio playback manager
├── task-complete.mp3             # Completion sound effect
└── todoeveryday.entitlements     # App sandbox permissions
```

### Data Models

**TodoItem.swift**
```swift
@Model final class TodoItem {
    var id: UUID
    var title: String
    var itemDescription: String    // Optional description for detailed notes
    var isCompleted: Bool
    var createdDate: Date
    var completedDate: Date?
    var deadline: Date?
    var isExpanded: Bool           // For expand/collapse state
    var sortOrder: Int             // For custom ordering
    var taskGroupId: UUID          // Links all instances of the same task across days

    @Relationship(deleteRule: .nullify, inverse: \DailyTodoList.items)
    var dailyList: DailyTodoList?

    @Relationship(deleteRule: .nullify, inverse: \TodoItem.children)
    var parent: TodoItem?          // Parent item for sub-items

    @Relationship(deleteRule: .cascade)
    var children: [TodoItem]       // Child sub-items
}
```

**DailyTodoList.swift**
```swift
@Model final class DailyTodoList {
    var id: UUID
    var date: Date  // Always normalized to startOfDay
    var summary: String
    var isDebugCreated: Bool  // Mark days created by debug mode
    @Relationship(deleteRule: .cascade)
    var items: [TodoItem]
}
```

**Key Relationships:**
- One DailyTodoList has many TodoItems (one-to-many)
- Deleting a DailyTodoList cascades to delete all its items
- TodoItems can exist without a parent list (nullify delete rule)
- **Hierarchical Structure**: TodoItems can have parent-child relationships
  - Parent relationship is nullify (orphan items remain)
  - Children relationship is cascade (deleting parent deletes children)
- **Unlimited Nesting**: Sub-items can have their own sub-items recursively

### ViewModel Pattern

**TodoViewModel.swift** is @Observable and manages:
- Loading and storing data via ModelContext
- Separating recent (last 7 days) vs older lists
- Creating today's list with carryover logic (including sub-items and descriptions)
- CRUD operations on items and sub-items
- Hierarchical operations (add/delete/reorder sub-items)
- Computed statistics (completion rates, average completion time, progress tracking)
- CSV export with hierarchy and descriptions

**Important**: ViewModel is initialized once in ContentView.onAppear and passed to child views.

### Custom Components

**SoundManager.swift**
- Singleton pattern for audio playback
- Plays completion sound using AVAudioPlayer
- Sound file: `task-complete.mp3`

**URLHelper.swift**
- Extension on String for URL detection using NSDataDetector
- `ClickableTextView`: NSViewRepresentable wrapping NSTextView
- Handles clickable URLs with proper cursor behavior
- Custom context menu implementation via AppKit
- Context menu includes: Edit Title, Edit Description, Set/Edit/Remove Deadline, Delete
- Properly sets `.cursor` attribute for hand cursor on links

**SubItemDropDelegate (in ContentView.swift)**
- Implements DropDelegate protocol for drag-and-drop
- Handles reordering of sub-items within a parent
- Uses UUID string transfer for identifying dragged items

**StatisticsDetailView (in ContentView.swift)**
- Comprehensive statistics dashboard view
- Displays today's stats, all-time stats, performance metrics
- Shows recent days performance with color-coded progress bars
- Time formatting helpers for displaying completion times
- Color-coded progress indicators based on completion rates

**StatCard (in ContentView.swift)**
- Reusable card component for displaying individual statistics
- Shows icon, value, and title in a styled card layout
- Used for today's stats and all-time stats display

**SettingsView (in ContentView.swift)**
- Comprehensive settings interface with toggles for user preferences
- Three main settings using @AppStorage for persistence:
  - `autoCarryover`: Controls automatic task carryover to next day (default: true)
  - `showCarryoverPopup`: Shows confirmation dialog for completing linked tasks (default: true)
  - `createWeekendDays`: Enables/disables weekend day creation (default: true)
- Professional card-based layout with sections
- Settings automatically disable dependent options (popup disabled when carryover is off)
- All settings apply to both regular day creation and debug mode

## Key Design Decisions

### 1. Date Normalization
All DailyTodoList dates are normalized to `startOfDay` to ensure consistent date comparisons. This prevents duplicate lists for the same day.

```swift
Calendar.current.startOfDay(for: date)
```

### 2. Automatic List Creation
When the app launches:
- Check if today's list exists
- If not, create it and carry over incomplete items from yesterday
- **Hierarchical Carryover**: Incomplete sub-items are recursively copied with their parent
- Deadlines and sortOrder are preserved during carryover
- Only top-level incomplete items (parent == nil) are carried over initially
- Helper function `copyItemWithChildren()` handles recursive copying

### 3. Hierarchical Sub-Items
- **Unlimited Nesting**: Items can have children, which can have their own children
- **Visual Hierarchy**: 32-pixel indentation per level
- **sortOrder Field**: Maintains custom ordering within siblings
  - Newer sub-items get sortOrder 0 (appear at top)
  - Existing siblings increment their sortOrder
- **Expand/Collapse**: isExpanded boolean controls visibility
- **Drag-and-Drop**: Sub-items can be reordered via drag-and-drop
- **Filtering**: Top-level items filtered by `parent == nil`
- **Sorting**: Children sorted by `sortOrder` ascending

### 4. Item Descriptions
- **Optional Field**: Each TodoItem has an `itemDescription` string field (defaults to empty)
- **Visual Indicator**: Document icon button shows filled orange when description exists
- **Hover Preview**: Native macOS tooltip (`.help()` modifier) shows description on hover
- **Edit Interface**: Click icon or use context menu to open TextEditor for editing
- **Preserved on Carryover**: Descriptions are copied when incomplete items move to next day
- **Export**: Included in CSV export as separate column

### 5. Statistics & Progress Tracking (enhanced in v2.3)
- **Hidden in Sidebar**: Statistics button shows no numbers, click to view full detail panel
- **Unique Task Counting**: Carried-over tasks counted once using `taskGroupId` deduplication
  - `totalCompletedTasks`, `totalPendingTasks`, `totalTasks` use unique task groups
  - Prevents double-counting tasks that span multiple days
- **Comprehensive Metrics**:
  - Today's completion rate with visual progress bar
  - Average completion time (from original creation to completion, tracks across carryovers)
  - Daily completion rates for last 7 days
  - Color-coded progress indicators (green/orange/red)
- **Computed Properties**: All statistics are computed on-demand via @Observable
- **No Manual Refresh**: Statistics update automatically when data changes

### 6. 7-Day Cutoff
Lists from the last 7 days appear individually in the sidebar. Older lists are grouped in "History" view.

### 7. SwiftData Persistence
- ModelContainer is created in `todoeverydayApp.swift`
- Schema includes both TodoItem and DailyTodoList
- No complex migration plan currently (fresh start on schema changes)
- Database location: `~/Library/Containers/skywhat.todoeveryday/Data/Library/Application Support/`

### 8. Entitlements
The app requires specific entitlements for file operations:
- `com.apple.security.app-sandbox` - Enable sandbox
- `com.apple.security.files.user-selected.read-write` - For NSSavePanel (CSV export)

### 9. Task Group Linking (v2.2, enhanced in v2.3)
- **taskGroupId Field**: Each TodoItem has a UUID that links all instances of the same task across days
- **Preserved on Carryover**: When a task carries over, the new instance gets the same `taskGroupId`
- **Visual Indicator**: "↻" badge with color gradient (orange→red based on pending days)
- **Badge Color Logic**: `carryoverBadgeColor(for:)` interpolates from orange (1 day) to red (7+ days)
- **Days Tracking**: `carryoverDaysCount(for:)` calculates days since task first appeared
- **Linked Completion**: When completing a carried-over task, user can mark all linked instances complete
- **Detection Logic**: `isCarryoverItem()` checks if taskGroupId exists in earlier days

### 10. User Settings (v2.2)
- **Auto-Carryover Setting**: Controls whether incomplete tasks carry over automatically (default: true)
  - When disabled, new days start empty
  - Applies to both regular and debug day creation
- **Carryover Popup Setting**: Shows confirmation dialog when completing linked tasks (default: true)
  - Three options: "Yes, Mark All", "No, Just This One", "Cancel"
  - Automatically disabled when auto-carryover is off
  - Respects setting in all completion actions
- **Weekend Days Setting**: Controls weekend day creation (default: true)
  - When disabled, Saturday and Sunday are skipped
  - Applies to both regular day creation and debug mode
  - Uses weekday component (1=Sunday, 7=Saturday)

### 11. Sidebar Pagination (v2.2)
- **Initial Display**: Shows first 7 recent days
- **Show More**: Button appears if more than 7 days exist, loads 7 more at a time
- **Show Less**: Collapses back to 7 days when expanded
- **Counter Badge**: Shows how many hidden days remain
- **State Management**: `visibleRecentDaysCount` tracks current display limit

### 12. Debug Mode Enhancements (v2.2)
- **Settings Respect**: Debug day creation now respects all user settings
- **Create Previous Day**: New button to create days going backwards in time
- **Delete Any Day**: Can delete any day including today when debug mode is enabled
- **Act as Today**: Debug-created days become the active "today" for testing
- **Cleanup on Startup**: All debug-created days (`isDebugCreated = true`) are deleted on app launch

## Common Development Tasks

### Adding a New Field to Models

**IMPORTANT**: SwiftData schema changes can break existing databases.

**Steps:**
1. Add the field to the @Model class
2. Provide a default value in the initializer
3. Test with a fresh database (delete old one first)
4. If users have existing data, consider migration (currently not implemented)

**Quick database reset:**
```bash
rm -rf ~/Library/Containers/skywhat.todoeveryday/Data/Library/Application\ Support/*.store*
```

### Adding a New View

1. Create the view struct in `ContentView.swift` (all views are in one file currently)
2. Pass `viewModel` as a parameter if data access is needed
3. Use `@State` for local UI state, not for data that needs persistence
4. Follow the existing pattern: separate views for major sections (DayDetailView, HistoryView, etc.)

### Adding Statistics

1. Add computed property to `TodoViewModel`
2. Use `allLists`, `todaysList`, `recentLists`, or `olderLists` as data source
3. Update automatically via @Observable - no manual refresh needed

### Modifying Data

Always use ViewModel methods:
- `addTodoItem(title:deadline:)` - Add top-level item with sortOrder
- `addSubItem(to:title:)` - Add sub-item at top (sortOrder 0)
- `toggleItemCompletion(_:)` - Toggle completion and play sound
- `deleteItem(_:)` - Delete item (cascades to children)
- `updateItemDeadline(_:deadline:)` - Update deadline
- `updateItemTitle(_:title:)` - Update item title
- `updateItemDescription(_:description:)` - Update item description
- `updateSummary(for:summary:)` - Update daily summary
- `toggleItemExpansion(_:)` - Expand/collapse item
- `moveSubItem(_:from:to:)` - Reorder sub-items

Each method calls `saveContext()` automatically.

### Export/Import Features

**CSV Export** is already implemented with hierarchical structure:
- `exportToCSV()` returns URL to temporary file
- Uses recursive helper `exportItemToCSV()` for hierarchy
- Includes columns: Date, Level, Title, Description, Status, Created, Completed, Deadline, Overdue
- Titles are indented with spaces to show hierarchy
- Descriptions are included in full text
- Filters to only export top-level items initially (children handled recursively)

For other formats:
1. Add export logic to TodoViewModel (similar to `exportToCSV()`)
2. Create file in temporary directory
3. Use NSSavePanel to let user choose save location
4. Remember to add required UTType imports

### Working with Sub-Items

**Adding Sub-Items:**
```swift
viewModel.addSubItem(to: parentItem, title: "Sub-task title")
```
- New sub-items get sortOrder 0 (appear at top)
- Existing siblings increment sortOrder by 1
- Automatically inserted into ModelContext

**Reordering Sub-Items:**
```swift
viewModel.moveSubItem(draggedItem, from: oldIndex, to: newIndex)
```
- Adjusts sortOrder of affected items
- Works only within the same parent

**Rendering Hierarchy:**
```swift
ForEach(item.children.sorted { $0.sortOrder < $1.sortOrder }, id: \.id) { child in
    TodoItemRow(item: child, viewModel: viewModel, indentLevel: indentLevel + 1)
        .padding(.leading, 32)  // 32px per level
}
```

**Context Menu on NSTextView:**
- SwiftUI `.contextMenu` doesn't work on NSViewRepresentable
- Implement `menu(for:)` in CustomTextView subclass
- Return NSMenu with NSMenuItems
- Set actions as `@objc` methods

## UI Patterns

### Sidebar Structure
```
VStack {
    Statistics Section
    Divider
    List (Recent 7 days + History)
    Export Button
}
```

### Detail View Structure
```
VStack {
    Header (Title + Date)
    Divider
    Add Item Section (only for today)
    Task List (ScrollView)
    Divider
    Summary Section (TextEditor)
}
```

### Common SwiftUI Patterns Used
- `@State` for local UI state
- `@Environment(\.modelContext)` for data operations
- `@FocusState` for keyboard focus management
- `.onAppear` for initialization
- `NavigationSplitView` for sidebar layout

## Important Conventions

### Code Style
- SwiftUI views use computed `body` property
- Private helper methods at bottom of structs
- Clear naming: `todaysList`, `recentLists`, not abbreviations
- DateFormatter setup inline where needed

### Dates and Times
- Store dates in Date objects, not strings
- Format for display, not for storage
- Use `Calendar.current` for date arithmetic
- Deadline precision: date + hour (components: [.date, .hourAndMinute])

### Error Handling
- Currently uses simple print() for errors
- SwiftData errors are caught and logged but not surfaced to user
- File operations (CSV export) fail silently with console log

## Testing Approach

No formal unit tests currently. Manual testing checklist:

1. **Fresh Install**: Delete database, launch app, verify empty state
2. **Daily Creation**: Verify new list appears when date changes
3. **Carryover**: Create incomplete tasks, verify they appear next day
4. **Statistics**: Add/complete tasks, verify counts update
5. **Export**: Test CSV export, verify all data is present
6. **Deadlines**: Test overdue detection, sorting, visual indicators

## Known Limitations & Gotchas

### 1. Schema Migration
No automatic migration. Schema changes require database deletion. Future improvement: implement VersionedSchema and MigrationPlan.

### 2. Date Change Detection
App doesn't detect date changes while running. User must restart app to see new day's list. Could be improved with Timer or NotificationCenter.

### 3. File Permissions
NSSavePanel requires entitlements to be properly configured. If export fails with permission error, check:
- entitlements file exists
- `ENABLE_USER_SELECTED_FILES = readwrite` in project settings
- `CODE_SIGN_ENTITLEMENTS` points to correct file

### 4. Performance
No pagination on history. With years of data, the history view could become slow. Current assumption: personal use, reasonable data size.

### 5. Single Window
App opens single window. If closed, app terminates. Standard macOS app behavior but no multi-window support.

## Future Enhancement Ideas

### Potential Features
- [ ] Recurring tasks (daily, weekly patterns)
- [ ] Task categories/tags
- [ ] Search functionality
- [ ] Keyboard shortcuts
- [ ] Dark mode optimization
- [ ] iCloud sync (would require CloudKit)
- [ ] Widgets for menu bar or Today view
- [ ] Notifications for upcoming deadlines
- [ ] Import from CSV
- [ ] Weekly/monthly summary reports
- [ ] Task templates
- [x] **Subtasks or checklist items** (✅ v2.0 - Hierarchical sub-items)
- [x] **Notes/descriptions for tasks** (✅ v2.1 - Item descriptions with hover preview)
- [ ] Attachments (files, images)
- [ ] Color coding or priorities
- [ ] Time tracking per task
- [x] **Completion sound** (✅ v2.0)
- [x] **Clickable URLs** (✅ v2.0)
- [x] **Editable tasks** (✅ v2.0)

### Technical Improvements
- [ ] Implement proper schema migration
- [ ] Add unit tests
- [ ] Detect date change while app is running
- [ ] Pagination for history view
- [ ] Localization support
- [ ] Accessibility improvements
- [ ] Performance profiling with large datasets
- [ ] Better error handling and user feedback
- [ ] Undo/redo support
- [x] **Drag and drop task reordering** (✅ v2.0 - For sub-items)

## Debugging Tips

### View Database Contents
SwiftData stores data in binary format. To inspect:
1. Find database: `~/Library/Containers/skywhat.todoeveryday/Data/Library/Application Support/`
2. Use Xcode's preview to see data in running app
3. Add temporary print statements in ViewModel methods

### Common Issues

**"Could not create ModelContainer" error:**
- Schema changed without migration
- Solution: Delete database files

**Export button doesn't work:**
- Check entitlements are linked in project settings
- Verify `ENABLE_USER_SELECTED_FILES = readwrite`

**Items not appearing:**
- Check date normalization (should be startOfDay)
- Verify ModelContext is being passed correctly
- Ensure saveContext() is called after changes

**Stats not updating:**
- ViewModel should be @Observable
- Views should reference viewModel directly (not through @State)
- If using @State, manually trigger view refresh

## Build & Distribution

### Development Build
```bash
# Open in Xcode
open todoeveryday.xcodeproj

# Or build from command line
xcodebuild -scheme todoeveryday -configuration Debug build
```

### Release Build
1. Product > Archive in Xcode
2. Distribute App > Copy App
3. Copy to /Applications

### Entitlements Requirements
Must include in `todoeveryday.entitlements`:
- User Selected File Read/Write (for save panel)
- App Sandbox enabled
- Downloads folder access (optional, for default save location)

## Contact & Maintenance

- **Bundle ID**: `skywhat.todoeveryday`
- **Minimum macOS**: 14.0 (SwiftData requirement)
- **Development Environment**: Xcode 15.0+
- **Language**: Swift 5.9+

## Version History

**v2.3** - Statistics Accuracy & Carryover Improvements (January 2026)
- **Statistics Accuracy Fixes**:
  - Fixed double-counting of carried-over tasks in statistics
  - `totalCompletedTasks`, `totalPendingTasks`, `totalTasks` now count unique tasks by `taskGroupId`
  - Carried-over tasks counted as single task across all days
  - Average completion time now tracks from original task creation to completion
- **Carryover Badge Enhancements**:
  - Color gradient from orange (1 day) to red (7+ days) based on pending duration
  - `carryoverDaysCount(for:)` calculates days since task was first created
  - `carryoverBadgeColor(for:)` interpolates badge color based on age
  - Dynamic tooltip shows exact number of pending days
- **Code Quality Improvements**:
  - Refactored statistics calculation logic for clarity
  - Improved code organization across ContentView, TodoViewModel, and URLHelper
  - Better separation of concerns in statistics computation

**v2.2** - Settings, Carryover Tracking & UI Enhancements (January 2026)
- **Carryover Task Tracking**:
  - Added `taskGroupId` field to link task instances across days
  - Orange "↻" badge indicator for carried-over tasks
  - Confirmation dialog when completing linked tasks (3 options: mark all, just this one, cancel)
  - Shows count of days task appears in
  - `isCarryoverItem()` and `linkedItemsCount()` helper methods
- **Settings View**: New comprehensive settings panel
  - Settings button in sidebar (gear icon) above Statistics
  - **Auto-carryover toggle**: Enable/disable automatic task carryover (default: ON)
  - **Carryover popup toggle**: Show/hide completion confirmation dialog (default: ON)
  - **Weekend days toggle**: Create/skip Saturday and Sunday (default: ON)
  - All settings persist via @AppStorage
  - Settings apply to both regular and debug mode
  - Professional card-based UI layout with help text
- **Sidebar Enhancements**:
  - Dual count display: Completed (green badge) + Pending (orange badge)
  - Pagination: Shows 7 days initially, "Show 7 More Days" button
  - "Show Less" button to collapse back to 7 days
  - Counter shows remaining hidden days
- **Debug Mode Improvements**:
  - "Create Previous Day" button (blue) for historical testing
  - Can delete any day including today when debug mode enabled
  - Delete buttons appear in sidebar and history view
  - Debug-created days now respect all settings (weekend skip, auto-carryover)
  - Debug days act as real "today" (can add items)
  - Auto-cleanup on startup (removes all debug days)
- **Error Handling**:
  - Better ModelContainer error handling with in-memory fallback
  - Helpful console messages guide users to delete corrupted database
  - App can still launch with database schema errors
- **Bug Fixes**:
  - Fixed weekend day creation in debug mode
  - Settings now properly passed to all day creation methods
  - Improved active "today" detection for debug days

**v2.1** - Statistics Dashboard & Item Descriptions (January 2026)
- **Statistics Detail View**: Comprehensive statistics panel with charts and metrics
  - Hidden statistics numbers in sidebar (click to view full detail panel)
  - Today's progress with visual progress bar and completion percentage
  - All-time statistics (total completed, pending, and total tasks)
  - Performance metrics: average time to complete tasks, average daily completion rate
  - Recent days performance with color-coded progress bars (last 7 days)
  - Better clickable areas in sidebar (entire row is clickable)
- **Item Descriptions**: Optional detailed notes for each task
  - `itemDescription` field added to TodoItem model
  - Description button with hover tooltip preview (native macOS tooltip)
  - Click description icon to edit in expandable text editor
  - Visual indicator: filled orange icon when description exists, gray outline when empty
  - "Edit Description" option in right-click context menu
  - Descriptions preserved during task carryover
  - Descriptions included in CSV export
- **Enhanced Statistics Computing**:
  - `averageCompletionTimePerDay`: Average time from task creation to completion
  - `dailyCompletionRates`: Completion percentage for each day
  - `averageDailyCompletionRate`: Overall average completion rate
  - `todayCompletionRate`: Today's progress percentage
  - Time formatting helper (minutes, hours, days)
- **UI/UX Improvements**:
  - Smooth navigation between Today, History, and Statistics views
  - Fixed layout shifting issues with consistent `.fixedSize()` and `.contentShape(Rectangle())`
  - Professional card-based statistics layout
  - Color-coded progress indicators (green ≥80%, orange ≥50%, red <50%)

**v2.0** - Hierarchical Sub-Items & Enhanced Features (January 2026)
- Hierarchical sub-items with unlimited nesting
- Expand/collapse functionality for items with children
- Drag-and-drop reordering of sub-items
- Smart ordering (newer sub-items appear at top)
- Editable tasks (double-click or right-click context menu)
- Clickable URLs with hand cursor on hover
- Completion sound effect using AVFoundation
- Enhanced context menus on item text (not just icons)
- Recursive carryover of incomplete sub-items
- Hierarchical CSV export with level and indentation
- New data model fields: `isExpanded`, `sortOrder`, `parent`, `children`
- Custom components: `SoundManager`, `ClickableTextView`, `SubItemDropDelegate`

**v1.0** - Initial release (January 2026)
- Daily todo lists
- Task completion tracking
- Deadline management
- Statistics dashboard
- CSV export
- History view (last 7 days + older)
- Daily summaries

---

## Quick Reference for Common Modifications

### Add a new todo item property
1. Add to `TodoItem.swift` model
2. Update initializer with default value
3. Update CSV export in `TodoViewModel.exportToCSV()`
4. Update UI in `TodoItemRow` if needed
5. Delete database for testing

### Add a new statistic
1. Add computed property to `TodoViewModel`
2. Use in ContentView stats section
3. No manual refresh needed (@Observable)

### Change UI layout
1. Modify `ContentView.swift` directly
2. All views are in single file
3. Use SwiftUI preview for quick iteration

### Modify carryover logic
1. Edit `createTodaysList()` and `copyItemWithChildren()` in `TodoViewModel`
2. Current logic:
   - Filter top-level incomplete items (parent == nil)
   - Recursively copy items with their incomplete children
   - Preserve deadlines and sortOrder
3. Test by creating items with sub-items yesterday, restarting app
4. Verify sub-items maintain hierarchy and order

---

*Last Updated: January 10, 2026 - v2.3 Release*
*This document should be updated when significant architectural changes are made.*
