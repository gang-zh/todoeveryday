# TodoEveryday

A macOS app for managing daily todo lists with automatic task carryover.

## Features

### Task Management
- **Add/Edit/Delete** tasks with Enter key or click
- **Sub-items** with unlimited nesting (click + on any task)
- **Descriptions** with hover tooltip preview
- **Clickable URLs** auto-detected in task titles
- **Completion sound** when marking tasks done
- **Drag & drop** to reorder sub-items

### Deadlines
- Set deadlines with hour-level precision
- Overdue tasks highlighted in red
- Smart sorting by deadline

### Carryover
- Incomplete tasks automatically carry to the next day
- Color-coded "↻" badge (orange→red based on pending days)
- Tooltip shows how long task has been pending
- Option to mark all linked instances complete at once

### History & Stats
- Last 7 days in sidebar (expandable)
- Full history view for older lists
- Daily summaries
- Statistics dashboard with accurate unique task counting
- Average completion time tracks from original creation to completion

### Settings
| Setting | Default | Description |
|---------|---------|-------------|
| Auto-Carryover | ON | Carry incomplete tasks to next day |
| Carryover Popup | ON | Confirm when completing linked tasks |
| Weekend Days | ON | Create lists for Sat/Sun |

### Export
Export all data to CSV including hierarchy, descriptions, and deadlines.

## Installation

### From Source
```bash
# Open in Xcode and run (Cmd+R)
open todoeveryday.xcodeproj
```

### Release Build
1. Xcode → Product → Archive
2. Distribute App → Copy App
3. Move to `/Applications`

> **Note**: On first launch, go to System Settings → Privacy & Security → Open Anyway

## Requirements

- macOS 14.0+

## Tech Stack

- **SwiftUI** + **SwiftData** for UI and persistence
- **AppKit** for native dialogs
- **AVFoundation** for audio
- **MVVM** architecture

See [CLAUDE.md](CLAUDE.md) for detailed technical documentation.

## Version History

| Version | Highlights |
|---------|------------|
| **2.3** | Fixed statistics accuracy, carryover badge color gradient, code refinements |
| **2.2** | Settings panel, carryover tracking with badges, sidebar pagination |
| **2.1** | Statistics dashboard, item descriptions |
| **2.0** | Hierarchical sub-items, drag-drop, editable tasks, clickable URLs |
| **1.0** | Initial release |

---

Built with SwiftUI and SwiftData
