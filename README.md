# TodoEveryday

A macOS application for managing daily todo lists with automatic task carryover and comprehensive tracking features.

## Features

### 📋 Daily Todo Management

- **Create Todo Items**: Add new tasks with a simple text input and press Enter or click the plus button
- **Mark as Complete**: Click the circle icon next to any task to mark it done (turns green with checkmark)
  - 🔊 **Completion Sound**: Plays a satisfying sound effect when you complete a task
  - **Carryover Completion Dialog**: When completing a carried-over task, you can choose to mark all related instances done or just the current one
- **Edit Tasks**: Double-click any task or right-click and select "Edit Title" to modify the text
- **Task Descriptions**: Add detailed notes to any task
  - Click the document icon to add/edit descriptions
  - Hover over the filled orange icon to preview the description via tooltip
  - Descriptions are preserved during carryover and included in CSV exports
- **Delete Tasks**: Click the trash icon on the right side of any item, or right-click for more options
- **Clickable Links**: URLs in task titles are automatically detected and clickable with hand cursor
- **Automatic Daily Lists**: A new list is automatically created each day when you open the app
- **Task Carryover**: Incomplete tasks from yesterday automatically appear in today's list
  - **Carryover Indicators**: Orange "↻" badge marks tasks that were carried over from previous days
  - Tasks are linked across days with a unique group ID for tracking

### ⏰ Deadline Management

- **Set Deadlines**: Add optional deadlines with hour-level precision when creating tasks
- **Edit Deadlines**: Right-click any item to set, edit, or remove deadlines
- **Visual Indicators**:
  - Overdue tasks appear in red text with red circle icons
  - Clock icon shows the deadline date and time
  - Overdue count displayed in statistics
- **Smart Sorting**: Tasks are sorted with incomplete items first, prioritized by deadline

### 🔄 Hierarchical Sub-Items (Task Breakdown)

- **Break Down Tasks**: Click the plus button on any task to add sub-items
- **Unlimited Nesting**: Sub-items can have their own sub-items for detailed breakdown
- **Visual Hierarchy**: Sub-items appear indented (32 pixels per level) for clear structure
- **Expand/Collapse**: Click the chevron (▶/▼) to show/hide sub-items
- **Smart Ordering**:
  - Newer sub-items appear at the top automatically
  - Drag and drop any sub-item to reorder within its parent
  - Custom order is preserved during daily carryover
- **Full Feature Support**: Sub-items support all features (completion, deadlines, editing, deletion)
- **Recursive Carryover**: Incomplete sub-items automatically carry over with their parent tasks

### ⚙️ Settings

Click the **Settings** button in the sidebar (above Statistics) to customize your experience:

1. **Auto-Carryover** (Default: ON)
   - Automatically carry over unfinished tasks to the next day
   - When disabled, each day starts with a blank list

2. **Carryover Popup** (Default: ON)
   - Show confirmation dialog when completing carried-over tasks
   - Lets you choose to mark all related task instances done or just the current one
   - Automatically disabled when Auto-Carryover is OFF

3. **Weekend Days** (Default: ON)
   - Create new lists for Saturday and Sunday
   - When disabled, weekend days are skipped (Friday carries to Monday)

All settings are saved automatically and persist across app launches.

### 📅 History & Organization

- **Last 7 Days View**: Left sidebar shows each of the last 7 days as individual sections
  - Shows day name (or "Today" for current day)
  - **Dual Count Display**: Shows both completed (green checkmark) and pending (orange circle) task counts
  - Better clickable areas - entire row is clickable for easy navigation
- **Pagination**: Sidebar initially shows 7 recent days
  - Click **"Show 7 More Days"** to expand and see older days
  - Click **"Show Less"** to collapse back to the most recent 7 days
  - Counter shows how many more days are available to view
- **History Section**: Access all todo lists older than visible days
- **Day Navigation**: Click any day in the sidebar to view that day's list

### 📝 Daily Summaries

- **Editable Summaries**: Each day has a summary section at the bottom where you can write notes
- **Auto-Save**: Summaries are automatically saved as you type
- **History Display**: Past summaries are visible when viewing history

### 📊 Statistics Dashboard

Located at the top of the left sidebar with a simple button interface (no distracting numbers). Click to view detailed statistics:

**Today's Stats:**
- ✅ Completed tasks count
- ⭕ Pending tasks count
- ⚠️ Overdue tasks count (shown only if applicable)

**All Time Stats:**
- Total completed tasks across all days
- Total pending tasks across all days

**User Experience Improvements:**
- Clean sidebar appearance - statistics don't clutter the navigation
- Full-screen detail view for comprehensive data analysis
- Better clickable areas throughout the interface

### 💾 Data Export

- **Export to CSV**: Click the "Export to CSV" button at the bottom of the sidebar
- **Comprehensive Data**: Exports all tasks with:
  - Date
  - Hierarchy Level (0 for top-level, 1+ for sub-items)
  - Title (with indentation showing hierarchy)
  - Description (detailed notes for each task)
  - Status (Completed/Pending)
  - Created timestamp
  - Completed timestamp
  - Deadline
  - Overdue status
- **Hierarchical Structure**: Sub-items are indented in the CSV to show their relationship
- **Save Anywhere**: Choose where to save the CSV file on your Mac
- **Compatible**: Opens in Excel, Google Sheets, Numbers, or any spreadsheet application

### 🎨 User Interface

- **Two-Panel Layout**: Sidebar navigation and main content area
- **Visual Feedback**:
  - Hover effects on interactive elements (plus and trash icons fade in)
  - Color-coded status indicators (green for complete, red for overdue)
  - Strikethrough text for completed tasks
  - Hand cursor appears when hovering over clickable URLs
  - Chevron indicators (▶/▼) for expandable items
- **Completion Time**: Shows when each task was completed
- **Context Menus**: Right-click anywhere on item text for quick actions:
  - Edit Title
  - Edit Description
  - Set/Edit/Remove Deadline
  - Delete
- **Drag and Drop**: Click and drag sub-items to reorder them within their parent
- **Inline Editing**: Double-click any task to edit its title directly

### 💾 Data Persistence

- **Automatic Saving**: All changes are saved immediately using SwiftData
- **Local Storage**: All data is stored locally on your Mac
- **No Cloud Sync**: Your data stays private on your device

## Installation

### Building from Source

1. Open the project in Xcode
2. Select **Product** > **Build** (or press `Cmd + B`)
3. Select **Product** > **Run** (or press `Cmd + R`)

### Installing the App

1. In Xcode, select **Product** > **Archive**
2. When archiving completes, click **Distribute App**
3. Choose **Copy App** and select a save location
4. Copy the `todoeveryday.app` to your `/Applications` folder
5. Launch from Spotlight, Launchpad, or Applications folder

**Note**: On first launch, you may need to:
- Go to **System Settings** > **Privacy & Security**
- Click **Open Anyway** next to the security warning

## Requirements

- macOS 14.0 or later
- No Apple Developer membership required for personal use

## Technical Details

### Built With

- **SwiftUI**: Modern declarative UI framework
- **SwiftData**: Data persistence and management
- **AppKit**: Native macOS file dialogs and NSTextView for rich text
- **AVFoundation**: Audio playback for completion sound
- **UniformTypeIdentifiers**: CSV file type handling and drag-and-drop

### Architecture

- **MVVM Pattern**: Clear separation between UI and business logic
- **Model Classes**:
  - `TodoItem`: Individual task with title, completion status, deadline, and hierarchical relationships
  - `DailyTodoList`: Container for tasks on a specific day with summary
- **ViewModel**: `TodoViewModel` manages data operations, computed properties, and sub-item logic
- **Views**: SwiftUI views for each section (sidebar, day detail, history)
- **Custom Components**:
  - `ClickableTextView`: NSTextView wrapper for URL detection and context menus
  - `SubItemDropDelegate`: Handles drag-and-drop reordering of sub-items
  - `SoundManager`: Singleton for audio playback

### Data Model

```
DailyTodoList
├── id: UUID
├── date: Date
├── summary: String
├── isDebugCreated: Bool       # Mark days created in debug mode
└── items: [TodoItem]

TodoItem
├── id: UUID
├── title: String
├── itemDescription: String    # Optional detailed notes
├── isCompleted: Bool
├── createdDate: Date
├── completedDate: Date?
├── deadline: Date?
├── isExpanded: Bool           # For expand/collapse state
├── sortOrder: Int             # For custom ordering
├── taskGroupId: UUID          # Links related tasks across days
├── dailyList: DailyTodoList?  # Parent list relationship
├── parent: TodoItem?          # Parent item for sub-items
└── children: [TodoItem]       # Child sub-items
```

## Project Structure

```
todoeveryday/
├── todoeverydayApp.swift          # App entry point
├── ContentView.swift              # Main UI with navigation and all views
├── TodoItem.swift                 # Todo item data model with hierarchy
├── DailyTodoList.swift           # Daily list data model
├── TodoViewModel.swift           # Business logic and sub-item operations
├── URLHelper.swift               # URL detection and clickable text view
├── SoundManager.swift            # Audio playback manager
├── task-complete.mp3             # Completion sound effect
└── todoeveryday.entitlements     # App permissions
```

## Features Summary

✅ Daily todo lists with automatic creation
✅ Task completion tracking with sound effects
✅ Automatic carryover of incomplete tasks and sub-items
✅ Carryover task indicators (orange "↻" badge)
✅ Carryover completion dialog (mark all or just one)
✅ Task descriptions with hover preview tooltips
✅ Hierarchical sub-items with unlimited nesting
✅ Expand/collapse items with children
✅ Drag-and-drop reordering of sub-items
✅ Editable tasks (double-click or right-click)
✅ Clickable URLs with proper cursor behavior
✅ Optional deadlines with hour precision
✅ Overdue task detection and highlighting
✅ Settings panel with three customizable toggles
✅ Dual count display (completed + pending)
✅ Sidebar pagination (show more/less functionality)
✅ Last 7 days quick access
✅ Full history of all past lists
✅ Daily summary notes
✅ Statistics dashboard (today + all time)
✅ Hierarchical CSV export with descriptions
✅ Delete individual tasks
✅ Right-click context menus on item text
✅ Smart task sorting by deadline
✅ Visual status indicators
✅ Local data persistence with @AppStorage settings
✅ No internet connection required

## License

This project is for personal use.

## Version

**2.2** - User Customization & Enhanced Task Management (January 2026)
- **Carryover Task Tracking**: Orange "↻" badge on carried-over tasks
- **Smart Completion**: Confirmation dialog for completing carried-over tasks (mark all or just one)
- **Task Descriptions**: Add detailed notes with hover tooltip preview
- **Settings Panel**: Three customizable toggles
  - Auto-carryover unfinished tasks (default: ON)
  - Show carryover completion popup (default: ON)
  - Create weekend days (default: ON)
- **Improved Sidebar**: Dual count display showing completed (green) and pending (orange) tasks
- **Pagination**: Show More/Show Less buttons to manage sidebar length
- **Better UX**: Entire sidebar rows clickable, cleaner statistics button
- **Debug Mode Enhancements**: Respects all settings, can delete any day including today

**2.1** - Statistics Dashboard & Item Descriptions (January 2026)
- Comprehensive statistics panel with visual charts
- Item descriptions with hover tooltip preview
- Performance metrics and completion tracking
- Enhanced UI/UX with better clickable areas

**2.0** - Hierarchical Sub-Items & Enhanced Features (January 2026)
- Hierarchical sub-items with unlimited nesting
- Expand/collapse functionality
- Drag-and-drop reordering
- Editable tasks (double-click or context menu)
- Clickable URLs with hand cursor
- Completion sound effect
- Enhanced context menus

**1.0** - Initial Release (January 2026)
- Daily todo lists with automatic creation
- Task completion tracking
- Deadline management
- CSV export functionality

---

Built with ❤️ using SwiftUI and SwiftData
