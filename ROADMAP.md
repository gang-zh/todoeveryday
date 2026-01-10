# TodoEveryday Web Version - Implementation Roadmap

## Overview

This roadmap outlines the implementation plan for building a web version of TodoEveryday with **bi-directional sync** between the macOS app and web platform. The goal is to achieve seamless data synchronization across platforms while maintaining the same user experience.

**Estimated Timeline**: 12 weeks
**Tech Stack**: React (TypeScript) + Golang + GCP

---

## Project Goals

1. **Cross-Platform Access**: Access your todos from any web browser
2. **Real-Time Sync**: Changes sync automatically between macOS app and web
3. **Offline Support**: Both platforms work offline and sync when reconnected
4. **Conflict Resolution**: Smart handling of concurrent edits on multiple devices
5. **Consistent UX**: Maintain the same features and user experience across platforms

---

## Architecture Overview

```
┌─────────────────────────────────────────────────────────────┐
│                     CLIENT LAYER                             │
├──────────────────────┬──────────────────────────────────────┤
│   macOS App          │         Web App (React)               │
│   (SwiftUI)          │         (TypeScript)                  │
│   ├─ SwiftData       │         ├─ Redux Store                │
│   ├─ Sync Manager    │         ├─ IndexedDB                  │
│   └─ WebSocket       │         └─ Service Worker             │
└──────────┬───────────┴──────────────┬────────────────────────┘
           │                          │
           │      REST / WebSocket    │
           └───────────┬──────────────┘
                       │
          ┌────────────▼────────────┐
          │    API Gateway          │
          │  (Cloud Load Balancer)  │
          └────────────┬────────────┘
                       │
┌──────────────────────▼──────────────────────────────────────┐
│                  BACKEND (GCP)                               │
│  ┌────────────────────────────────────────────────────┐    │
│  │         Golang Service (Cloud Run)                  │    │
│  │  ├─ REST API Handlers                               │    │
│  │  ├─ WebSocket Server                                │    │
│  │  ├─ Sync Engine (Vector Clocks)                     │    │
│  │  └─ Conflict Resolver                               │    │
│  └────────────────────────────────────────────────────┘    │
│                                                              │
│  ┌─────────────────┐  ┌──────────────┐  ┌──────────────┐  │
│  │   Firestore     │  │  Cloud Pub/  │  │   Firebase   │  │
│  │   (Database)    │  │     Sub      │  │     Auth     │  │
│  └─────────────────┘  └──────────────┘  └──────────────┘  │
└──────────────────────────────────────────────────────────────┘
```

---

## Key Technical Decisions

### 1. Sync Strategy: Vector Clocks + Last-Write-Wins

**Why**: Simple yet effective for our use case
- Each device maintains a logical clock (vector clock)
- Conflicts detected by comparing vector clocks across devices
- Last-Write-Wins (LWW) for simple field updates
- Custom resolution logic for complex operations (reordering, deletions)

**Alternatives Considered**:
- CRDT (too complex for low-conflict scenarios)
- Timestamp-only (doesn't handle causality)

### 2. Database: Cloud Firestore

**Why**: Built for real-time sync
- Native real-time synchronization capabilities
- Offline support for web clients out-of-the-box
- Document-based structure matches our hierarchical tasks
- Auto-scaling with predictable pricing

**Alternatives Considered**:
- PostgreSQL + custom sync (more work, no built-in real-time)
- Firebase Realtime Database (less flexible querying)

### 3. Backend: Golang on Cloud Run

**Why**: Performance + Scalability
- Excellent concurrency support (goroutines)
- Fast execution, low memory footprint
- Cloud Run auto-scales from 0 to 100 instances
- Only pay for actual usage

**Alternatives Considered**:
- Node.js (slower for CPU-intensive sync operations)
- Python (slower startup, higher memory)

### 4. Frontend: React + TypeScript

**Why**: Modern, type-safe, component-based
- TypeScript prevents type-related bugs
- Rich ecosystem (Redux, React Query, etc.)
- Great developer experience with Vite
- Easy to add progressive web app (PWA) features

**Alternatives Considered**:
- Vue.js (smaller ecosystem)
- Next.js (overkill for SPA, server-side not needed)

### 5. Real-time: WebSocket + Pub/Sub

**Why**: Bi-directional, low-latency updates
- WebSocket for persistent connections (macOS ↔ Backend)
- Firestore listeners for web app (built-in)
- Cloud Pub/Sub for event distribution
- Fallback to polling if WebSocket unavailable

---

## Implementation Phases

### Phase 1: Backend API + Database Setup (Weeks 1-3)

**Goal**: Create the foundation for sync

**Deliverables**:
- ✅ GCP project setup with required services
- ✅ Firestore database with proper schema
- ✅ Golang REST API with authentication
- ✅ Sync engine with vector clock implementation
- ✅ Basic conflict resolution logic
- ✅ Docker containerization
- ✅ Deploy to Cloud Run

**Key Files to Create**:
```
backend/
├── cmd/server/main.go
├── internal/
│   ├── api/handlers/
│   │   ├── auth.go
│   │   ├── sync.go
│   │   └── tasks.go
│   ├── sync/
│   │   ├── engine.go
│   │   ├── conflict_resolver.go
│   │   └── vector_clock.go
│   └── storage/firestore.go
├── Dockerfile
└── go.mod
```

**GCP Services Used**:
- Cloud Firestore (database)
- Cloud Run (backend hosting)
- Firebase Authentication (user auth)
- Cloud Load Balancer (API gateway)

**Complexity**: Medium
**Critical Path**: Yes

---

### Phase 2: React Frontend with Basic Features (Weeks 4-6)

**Goal**: Build web UI matching macOS app features

**Deliverables**:
- ✅ React app with TypeScript + Vite
- ✅ Authentication UI (login, register)
- ✅ Task list views (Today, History, Statistics)
- ✅ CRUD operations for tasks
- ✅ Hierarchical sub-tasks support
- ✅ Task descriptions with hover preview
- ✅ Settings panel
- ✅ IndexedDB for offline storage
- ✅ Basic sync service integration

**Key Features to Implement**:
1. **Daily Todo Management**
   - Create, edit, delete tasks
   - Mark tasks complete with sound effect
   - Drag-and-drop reordering
   - Clickable URLs

2. **Hierarchical Sub-tasks**
   - Unlimited nesting
   - Expand/collapse
   - Visual indentation

3. **Offline Support**
   - IndexedDB for local storage
   - Queue operations when offline
   - Auto-sync when online

4. **Statistics Dashboard**
   - Today's completion rate
   - All-time stats
   - Recent days performance

**Key Files to Create**:
```
web/
├── src/
│   ├── components/
│   │   ├── tasks/TaskList.tsx
│   │   ├── tasks/TaskItem.tsx
│   │   └── statistics/StatisticsPanel.tsx
│   ├── services/
│   │   ├── SyncService.ts
│   │   ├── IndexedDBService.ts
│   │   └── WebSocketService.ts
│   ├── store/
│   │   ├── slices/tasksSlice.ts
│   │   └── middleware/syncMiddleware.ts
│   └── hooks/
│       ├── useAuth.ts
│       └── useSync.ts
├── package.json
└── vite.config.ts
```

**Complexity**: Medium-High
**Critical Path**: No (can be done in parallel with Phase 3)

---

### Phase 3: macOS App Sync Integration (Weeks 7-9)

**Goal**: Enable macOS app to sync with cloud

**Deliverables**:
- ✅ Extend SwiftData models with sync metadata
- ✅ Implement SyncManager in Swift
- ✅ Network service for API calls
- ✅ WebSocket connection for real-time updates
- ✅ Auth flow (login UI, token management)
- ✅ Sync status indicator in UI
- ✅ Handle offline/online transitions
- ✅ Conflict resolution UI (if needed)

**Changes to Existing Files**:

**TodoItem.swift**: Add sync metadata
```swift
@Model
final class TodoItem {
    // Existing fields...

    // NEW: Sync metadata
    var lastSyncedAt: Date?
    var vectorClock: [String: Int]?  // JSON string
    var lastModifiedBy: String?      // Device ID
    var isDirty: Bool                // Needs sync
    var cloudId: String?             // Firestore ID
}
```

**TodoViewModel.swift**: Integrate sync
```swift
var syncManager: SyncManager?

func initializeSync(authService: AuthService) {
    self.syncManager = SyncManager(
        deviceId: getDeviceId(),
        userId: authService.currentUser.id,
        apiBaseURL: URL(string: "https://api.todoeveryday.com")!
    )
    Task { try await syncManager?.sync() }
}
```

**New Files to Create**:
```
todoeveryday/
├── SyncManager.swift        # Core sync logic
├── NetworkService.swift     # HTTP client
├── AuthService.swift        # Authentication
├── WebSocketClient.swift   # Real-time connection
└── LoginView.swift          # Login UI
```

**Complexity**: High
**Critical Path**: Yes

---

### Phase 4: Real-time Sync + Conflict Resolution (Weeks 10-11)

**Goal**: Achieve seamless real-time synchronization

**Deliverables**:
- ✅ WebSocket server implementation (backend)
- ✅ Cloud Pub/Sub integration for event streaming
- ✅ Real-time push notifications to clients
- ✅ Enhanced conflict resolution UI
- ✅ Manual conflict resolution dialog
- ✅ Conflict logging for debugging
- ✅ Comprehensive sync testing
- ✅ Performance optimization

**Sync Flow**:
```
1. Local Change → Mark as dirty → Queue operation
2. Sync Triggered → Push changes to server
3. Server → Detect conflicts → Resolve
4. Server → Publish event to Pub/Sub
5. Pub/Sub → Notify all connected devices
6. Devices → Pull changes → Apply locally
```

**Conflict Resolution Rules**:

| Scenario | Resolution |
|----------|-----------|
| Same field edited on 2 devices | Last-Write-Wins (newest timestamp) |
| Task completed on both devices | Keep completed (OR logic) |
| Task deleted on one, edited on other | Deletion wins (tombstone) |
| Children reordered differently | Operational transformation |

**Key Features**:
- **Automatic Conflict Resolution**: 95%+ of conflicts resolved automatically
- **Manual Resolution UI**: For rare complex conflicts
- **Conflict Logging**: Track all conflicts for analysis
- **Operation History**: Full audit trail for debugging

**Complexity**: Very High
**Critical Path**: Yes

---

### Phase 5: Deployment + Monitoring (Week 12)

**Goal**: Production-ready deployment

**Deliverables**:
- ✅ Infrastructure as Code (Terraform)
- ✅ CI/CD pipeline (GitHub Actions)
- ✅ Environment configs (dev, staging, prod)
- ✅ Monitoring dashboards
- ✅ Alerting rules
- ✅ Performance testing
- ✅ Security audit
- ✅ Documentation (API docs, deployment guide)

**Infrastructure**:
```hcl
# Terraform Configuration
- Cloud Run (API backend)
- Firestore (database)
- Cloud Pub/Sub (event streaming)
- Cloud Load Balancer (HTTPS/SSL)
- Firebase Hosting (web app)
- Cloud Monitoring (metrics)
```

**Monitoring Metrics**:
- API latency (P50, P95, P99)
- Sync success rate (target: >99%)
- Conflict rate (target: <1%)
- WebSocket connection stability
- Error rates by endpoint
- Database read/write costs

**Alerts**:
- High error rate (>5% in 5 min) → PagerDuty
- Sync failures spike (>10 in 1 min) → Slack
- High latency (P95 >2s) → Email
- Cost anomaly (2x average) → Email

**Complexity**: Medium
**Critical Path**: No

---

## Getting Started

### Prerequisites

1. **GCP Account**: Create a GCP project with billing enabled
2. **GitHub Repository**: Already set up ✅
3. **Development Environment**:
   - Go 1.21+
   - Node.js 18+
   - Xcode 15+ (for macOS app)
   - Docker

### Quick Start Options

#### Option 1: Backend First (Recommended)
Start with the backend to establish the sync foundation:
```bash
# Create backend project structure
mkdir -p backend/{cmd/server,internal/{api/handlers,sync,storage},pkg/{config,logger}}
cd backend
go mod init github.com/gang-zh/todoeveryday-backend
```

#### Option 2: Frontend First
Start with the web UI if you want to see visual progress:
```bash
# Create React app with Vite
npm create vite@latest web -- --template react-ts
cd web
npm install
```

#### Option 3: Infrastructure First
Set up GCP infrastructure before coding:
```bash
# Install Terraform
brew install terraform

# Initialize GCP project
gcloud init
gcloud services enable firestore.googleapis.com
gcloud services enable run.googleapis.com
```

### Recommended Order

1. **Week 1**: Set up GCP project + Firestore schema
2. **Week 2**: Create basic Golang API with auth
3. **Week 3**: Implement sync engine + conflict resolution
4. **Week 4**: Initialize React app + authentication
5. **Week 5**: Build task management UI
6. **Week 6**: Implement offline support (IndexedDB)
7. **Week 7**: Add sync to macOS app
8. **Week 8**: Test sync between platforms
9. **Week 9**: Fix bugs, optimize performance
10. **Week 10**: Add WebSocket real-time updates
11. **Week 11**: Enhanced conflict resolution UI
12. **Week 12**: Deploy to production + monitoring

---

## Risk Assessment

### High-Risk Areas

| Risk | Impact | Mitigation |
|------|--------|------------|
| Data loss from incorrect conflict resolution | Critical | Operation logs, soft deletes, manual resolution UI |
| Poor sync performance with large datasets | High | Pagination, delta sync, batch operations |
| Offline data corruption | High | Durable storage (IndexedDB), full resync option |
| Security vulnerabilities | Critical | JWT tokens, rate limiting, audit logs |

### Testing Strategy

**Backend Tests**:
- Unit tests for sync engine
- Integration tests for API endpoints
- Conflict resolution scenarios
- Load testing (100+ concurrent users)

**Frontend Tests**:
- Component tests (React Testing Library)
- E2E tests (Playwright)
- Offline scenarios
- Cross-browser compatibility

**macOS Tests**:
- SwiftUI view tests
- Sync manager unit tests
- Network failure scenarios
- Multi-device sync scenarios

---

## Success Metrics

### Technical Metrics
- ✅ Sync latency: <500ms average
- ✅ Sync success rate: >99%
- ✅ Conflict rate: <1%
- ✅ API error rate: <0.1%
- ✅ Uptime: 99.9%

### User Metrics
- Daily Active Users (DAU)
- Web vs macOS usage ratio
- Average tasks per user per day
- Feature adoption rates

### Business Metrics
- GCP monthly cost (target: <$50 for first 100 users)
- Time to sync across platforms (should feel instant)
- User-reported sync issues (target: <1%)

---

## Future Enhancements (Post-Launch)

### Phase 6: Mobile Apps
- iOS native app with sync
- Android native app with sync
- React Native for faster development

### Phase 7: Collaboration Features
- Share todo lists with others
- Real-time collaborative editing
- Comments on tasks
- @mentions

### Phase 8: Advanced Features
- Recurring tasks
- Task templates
- Attachments (files, images)
- Time tracking per task
- Calendar integration
- Notifications (push, email)

### Phase 9: AI Features
- Smart task suggestions
- Automatic categorization
- Priority recommendations
- Natural language task creation

---

## Team Recommendations

### Minimum Team (12 weeks)
- 1 Backend Engineer (Golang + GCP)
- 1 Frontend Engineer (React + TypeScript)
- 1 iOS/macOS Engineer (Swift)
- 0.5 DevOps Engineer (part-time)

### Accelerated Team (8 weeks)
- 2 Backend Engineers
- 2 Frontend Engineers
- 1 iOS/macOS Engineer
- 1 DevOps Engineer

### Solo Developer (20-24 weeks)
Focus on one phase at a time, prioritize backend → web → macOS → real-time.

---

## Resources & Documentation

### Official Documentation
- [Cloud Firestore](https://firebase.google.com/docs/firestore)
- [Cloud Run](https://cloud.google.com/run/docs)
- [Firebase Auth](https://firebase.google.com/docs/auth)
- [SwiftData](https://developer.apple.com/documentation/swiftdata)

### Sync Algorithm References
- [Vector Clocks Explained](https://en.wikipedia.org/wiki/Vector_clock)
- [Operational Transformation](https://en.wikipedia.org/wiki/Operational_transformation)
- [CRDT Overview](https://crdt.tech/)

### Example Implementations
- [Firestore Sync Patterns](https://firebase.google.com/docs/firestore/solutions/sync)
- [Building Offline-First Apps](https://web.dev/offline-first/)

---

## Contact & Support

- **GitHub Issues**: [Report bugs or request features](https://github.com/gang-zh/todoeveryday/issues)
- **Project Owner**: Gang Zhang
- **Repository**: https://github.com/gang-zh/todoeveryday

---

## Version History

- **v1.0** (January 2026): Initial roadmap created
- **v2.2** (Current): macOS app with all features, ready for web version

---

**Last Updated**: January 9, 2026

*This roadmap is a living document and will be updated as the project progresses.*
