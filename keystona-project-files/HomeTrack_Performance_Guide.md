# HomeTrack Performance & Optimization Guide
## Every Interaction Under 1 Second

**Version 1.0 | February 2026**
**Status:** Active — Every agent follows these patterns from day one

---

## Table of Contents

1. [Performance Budget](#1-performance-budget)
2. [Database & Query Optimization](#2-database--query-optimization)
3. [Image & File Optimization](#3-image--file-optimization)
4. [Widget Build Optimization](#4-widget-build-optimization)
5. [State Management Performance](#5-state-management-performance)
6. [Caching Strategy](#6-caching-strategy)
7. [Search Performance](#7-search-performance)
8. [Network Optimization](#8-network-optimization)
9. [App Startup Optimization](#9-app-startup-optimization)
10. [List & Scroll Performance](#10-list--scroll-performance)
11. [Animation Performance](#11-animation-performance)
12. [Perceived Performance Tricks](#12-perceived-performance-tricks)
13. [Monitoring & Profiling](#13-monitoring--profiling)
14. [Performance Checklist Per Feature](#14-performance-checklist-per-feature)

---

## 1. Performance Budget

**Target: Every user interaction completes in under 1 second.**

This is aggressive. Here's how we break it down:

### 1.1 Time Budgets by Action Type

| Action | Budget | Measurement |
|--------|--------|-------------|
| Screen navigation | < 200ms | Time from tap to first frame of new screen |
| List load (initial) | < 800ms | Time from screen visible to content rendered |
| List refresh (pull-to-refresh) | < 600ms | Time from release to data updated |
| Search query | < 500ms | Time from keystroke to results displayed |
| Form save | < 500ms | Time from tap Save to confirmation shown |
| File upload start | < 300ms | Time from tap to progress indicator visible |
| Tab switch | < 100ms | Time from tap to tab content visible |
| Dialog/sheet open | < 150ms | Time from tap to dialog fully visible |
| Image load (thumbnail) | < 400ms | Time from scroll-into-view to image rendered |
| Image load (full size) | < 1000ms | Time from tap to full image rendered |

### 1.2 Frame Rate Targets

| Scenario | Target | Notes |
|----------|--------|-------|
| Scrolling lists | 60 fps | No dropped frames during normal scroll |
| Page transitions | 60 fps | Smooth slide/fade animations |
| Skeleton animations | 60 fps | Pulse animation shouldn't jank |
| Before/after slider | 60 fps | Drag must be perfectly smooth |
| Idle | 0 fps | No unnecessary repaints when nothing is happening |

### 1.3 Size Budgets

| Metric | Budget |
|--------|--------|
| App binary (iOS) | < 50MB |
| App binary (Android) | < 40MB |
| Memory usage (idle) | < 100MB |
| Memory usage (active) | < 200MB |
| SQLite cache (Emergency Hub) | < 20MB |
| Image cache (disk) | < 100MB |

---

## 2. Database & Query Optimization

### 2.1 Index Strategy

The database schema already includes indexes. Here's why each matters and what to watch for:

**Existing indexes and their query patterns:**

| Index | Query It Serves | Expected Speed |
|-------|----------------|----------------|
| `idx_documents_property` | Document list for a property | < 5ms for 100 docs |
| `idx_documents_category` | Filter documents by category | < 5ms |
| `idx_documents_expiration` | Expiration dashboard sort | < 10ms |
| `idx_documents_search` (GIN trgm) | Fuzzy name search | < 20ms |
| `idx_documents_ocr_search` (GIN tsvector) | Full-text OCR search | < 50ms for 500 docs |
| `idx_systems_property` | Systems list for property | < 3ms |
| `idx_tasks_property_status` | Task list filtered by status | < 5ms |
| `idx_tasks_due_date` | Tasks sorted by due date | < 5ms |
| `idx_contacts_property` | Contact list for property | < 3ms |
| `idx_projects_property` | Projects list for property | < 3ms |
| `idx_budget_items_project` | Budget items for a project | < 5ms |
| `idx_project_photos_project` | Photos for a project | < 5ms |
| `idx_project_photos_pair` | Before/after photo pairs | < 3ms |

### 2.2 Query Patterns That Stay Fast

**Always filter by `property_id` first.** Every user-data query should start with the property filter — this hits the primary index and limits the scan to that user's data only.

```dart
// ✅ FAST — hits idx_documents_property directly
final docs = await supabase
  .from('documents')
  .select('*')
  .eq('property_id', propertyId)     // Index hit
  .is_('deleted_at', null)
  .order('created_at', ascending: false)
  .limit(50);

// ❌ SLOW — scans entire table
final docs = await supabase
  .from('documents')
  .select('*')
  .order('created_at', ascending: false)
  .limit(50);
```

### 2.3 Select Only What You Need

Never use `select('*')` on list screens. Only fetch the columns needed for the card display.

```dart
// ✅ FAST — only fetches card fields
final docs = await supabase
  .from('documents')
  .select('id, name, category_id, thumbnail_path, created_at, expiration_date')
  .eq('property_id', propertyId)
  .is_('deleted_at', null)
  .order('created_at', ascending: false);

// ❌ SLOW — fetches OCR text, notes, and every column for card display
final docs = await supabase
  .from('documents')
  .select('*')
  .eq('property_id', propertyId);
```

**Column selection per screen:**

| Screen | Columns Needed |
|--------|---------------|
| Document list card | id, name, category_id, thumbnail_path, created_at, expiration_date, mime_type |
| Task list card | id, name, category, status, due_date, priority, linked_system_id |
| System list card | id, name, category, status, brand, installation_date, expected_lifespan_years |
| Project list card | id, name, status, estimated_budget, actual_spent, planned_start_date, planned_end_date, project_type |
| Contact list item | id, name, company_name, category, phone_primary, is_favorite |

### 2.4 Pagination Strategy

**Never load all data at once.** Use cursor-based or offset pagination.

```dart
// ✅ Offset pagination for lists
const pageSize = 25;
int currentPage = 0;

final docs = await supabase
  .from('documents')
  .select('id, name, thumbnail_path, created_at')
  .eq('property_id', propertyId)
  .is_('deleted_at', null)
  .order('created_at', ascending: false)
  .range(currentPage * pageSize, (currentPage + 1) * pageSize - 1);
```

**Page sizes by screen:**

| Screen | Page Size | Reason |
|--------|-----------|--------|
| Document list | 25 | Typical user has < 50 docs |
| Task list | 30 | Show full month's tasks |
| System/appliance list | 20 | Rarely > 20 items |
| Project list | 15 | Few active projects |
| Budget items | 25 | Can grow large on big projects |
| Contact list | 25 | Rarely > 30 contacts |
| Completion history | 20 | Scrollable history |
| Photo grid | 20 | Load more on scroll |

### 2.5 Avoid N+1 Queries

Use PostgREST nested selects instead of querying each related item separately.

```dart
// ✅ FAST — single query with nested join
final project = await supabase
  .from('projects')
  .select('''
    *,
    phases:project_phases(id, name, status, sort_order),
    contractors:project_contractors(
      id, role, contract_amount,
      contact:emergency_contacts(id, name, phone_primary)
    )
  ''')
  .eq('id', projectId)
  .single();

// ❌ SLOW — three separate queries (N+1 problem)
final project = await supabase.from('projects').select().eq('id', projectId).single();
final phases = await supabase.from('project_phases').select().eq('project_id', projectId);
final contractors = await supabase.from('project_contractors').select().eq('project_id', projectId);
// Then for each contractor, fetch the contact... even worse
```

### 2.6 RPC for Complex Calculations

Don't calculate things client-side that the database can do faster.

```dart
// ✅ FAST — calculation happens in PostgreSQL
final score = await supabase.rpc('get_home_health_score', params: { 'p_property_id': propertyId });

// ❌ SLOW — fetch all tasks, calculate in Dart
final tasks = await supabase.from('maintenance_tasks').select().eq('property_id', propertyId);
final score = calculateScoreInDart(tasks); // Wasteful — moved all data to client
```

---

## 3. Image & File Optimization

### 3.1 Thumbnail Strategy

Never load full-resolution images in list views. Use thumbnails everywhere.

| Context | Max Dimension | Quality | Format |
|---------|--------------|---------|--------|
| Document list card | 120px wide | 70% JPEG | Generate on upload or via transform |
| System/appliance card | 80px | 70% JPEG | Generate on upload |
| Project card cover | 200px wide | 75% JPEG | First project photo or placeholder |
| Contact avatar | 48px | 60% JPEG | Not used (icon instead) |
| Photo grid thumbnail | 150px | 70% JPEG | Generate on upload |
| Before/after comparison | Full width | 85% JPEG | Load on demand |

### 3.2 Supabase Image Transformations

Supabase Storage supports on-the-fly image transforms. Use them.

```dart
// ✅ FAST — request thumbnail-sized image
final url = supabase.storage
  .from('documents')
  .getPublicUrl(
    filePath,
    transform: TransformOptions(
      width: 120,
      height: 120,
      resize: ResizeMode.cover,
      quality: 70,
    ),
  );

// ❌ SLOW — load full 5MB image for a 120px card thumbnail
final url = supabase.storage.from('documents').getPublicUrl(filePath);
```

### 3.3 CachedNetworkImage (Always)

Every image in the app must use `CachedNetworkImage`. No exceptions.

```dart
// ✅ ALWAYS use CachedNetworkImage
CachedNetworkImage(
  imageUrl: thumbnailUrl,
  width: 120,
  height: 120,
  fit: BoxFit.cover,
  placeholder: (context, url) => Container(
    color: AppColors.skeletonGray,  // Matches skeleton loader color
    width: 120,
    height: 120,
  ),
  errorWidget: (context, url, error) => Icon(Icons.document_scanner, size: 48),
  memoryCache​MaxWidth: 240,  // 2x for retina
  memoryCache​MaxHeight: 240,
)

// ❌ NEVER use Image.network directly
Image.network(fullSizeUrl)  // No caching, no placeholder, blocks on load
```

### 3.4 Upload Optimization

Before uploading any image:

```dart
// 1. Compress
final compressed = await FlutterImageCompress.compressWithFile(
  file.path,
  quality: 80,
  minWidth: 1920,   // Max dimension
  minHeight: 1920,
);

// 2. Convert HEIC to JPEG (iOS cameras default to HEIC)
// flutter_image_compress handles this automatically

// 3. Check size
if (compressed.length > maxSize) {
  // Offer to compress further or reject
}
```

**Compression targets by context:**

| Upload Type | Max Dimension | Quality | Max File Size |
|------------|--------------|---------|---------------|
| Document (photo scan) | 2400px | 85% | 10MB |
| Document (PDF) | N/A | N/A | 25MB |
| System/appliance photo | 1920px | 80% | 5MB |
| Shutoff photo | 1200px | 70% | 500KB (offline) |
| Completion photo | 1920px | 80% | 5MB |
| Project photo | 1920px | 85% | 10MB |

### 3.5 Lazy Image Loading

In lists and grids, only load images that are visible on screen.

```dart
// ✅ ListView.builder already lazy-loads by default
ListView.builder(
  itemCount: documents.length,
  itemBuilder: (context, index) {
    // This widget only builds when scrolled into view
    return DocumentCard(doc: documents[index]);
  },
)

// ✅ For grids, same principle
GridView.builder(
  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 3),
  itemCount: photos.length,
  itemBuilder: (context, index) => PhotoThumbnail(photo: photos[index]),
)
```

---

## 4. Widget Build Optimization

### 4.1 The Golden Rule: Minimize Rebuilds

Every `setState`, `ref.watch`, or provider change triggers a widget rebuild. Minimize the scope of what rebuilds.

```dart
// ✅ FAST — only the counter text rebuilds
class TaskCount extends ConsumerWidget {
  Widget build(BuildContext context, WidgetRef ref) {
    final count = ref.watch(taskCountProvider);
    return Text('$count tasks');
  }
}

// ❌ SLOW — entire screen rebuilds when count changes
class MaintenanceScreen extends ConsumerWidget {
  Widget build(BuildContext context, WidgetRef ref) {
    final count = ref.watch(taskCountProvider);
    return Scaffold(
      appBar: AppBar(title: Text('Maintenance')),
      body: Column(
        children: [
          Text('$count tasks'),
          // 200 more widgets that don't need count...
          TaskList(),
          HealthScoreGauge(),
          // All rebuild unnecessarily
        ],
      ),
    );
  }
}
```

### 4.2 Use `const` Constructors Everywhere

`const` widgets are created once and reused. Flutter skips rebuilding them entirely.

```dart
// ✅ FAST — StatusBadge never rebuilds if props haven't changed
const StatusBadge(label: 'Active', color: Colors.green)

// ✅ Make widgets const-capable
class StatusBadge extends StatelessWidget {
  const StatusBadge({super.key, required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
    decoration: BoxDecoration(
      color: color.withOpacity(0.1),
      borderRadius: const BorderRadius.all(Radius.circular(4)),
    ),
    child: Text(label, style: const TextStyle(fontSize: 12)),
  );
}
```

**Rules:**
- Every `StatelessWidget` should have a `const` constructor if possible
- Use `const` for all literal `EdgeInsets`, `BorderRadius`, `TextStyle`, `SizedBox`
- Use `const SizedBox(height: 8)` not `SizedBox(height: 8)` — the `const` version is cached

### 4.3 Extract Widgets, Don't Use Methods

```dart
// ✅ FAST — separate widget, can be const, has its own build lifecycle
class _DocumentCard extends StatelessWidget {
  const _DocumentCard({required this.doc});
  final Document doc;

  @override
  Widget build(BuildContext context) => Card(/* ... */);
}

// ❌ SLOW — method rebuilds every time parent rebuilds, can't be const
Widget _buildDocumentCard(Document doc) {
  return Card(/* ... */);
}
```

### 4.4 Use `RepaintBoundary` for Expensive Paints

Wrap complex paint operations (charts, gauges, photo comparisons) in `RepaintBoundary` to prevent unnecessary repaints.

```dart
// ✅ Health score gauge won't repaint when the list scrolls
RepaintBoundary(
  child: HealthScoreGauge(score: healthScore),
)
```

### 4.5 Avoid Layout Thrashing

Don't cause layout shifts that force re-layout of the entire tree.

```dart
// ✅ GOOD — fixed size, no layout shift when image loads
SizedBox(
  width: 120,
  height: 120,
  child: CachedNetworkImage(imageUrl: url, fit: BoxFit.cover),
)

// ❌ BAD — size unknown until image loads, causes layout shift
CachedNetworkImage(imageUrl: url)  // What size? Layout jumps when it loads
```

**Cross-reference:** See **Platform UI Guide, Section 8** for custom component patterns that avoid layout shifts.

---

## 5. State Management Performance

### 5.1 Riverpod Best Practices

**Use `.select()` to watch specific fields:**

```dart
// ✅ FAST — only rebuilds when task count changes
final count = ref.watch(tasksProvider.select((tasks) => tasks.length));

// ❌ SLOW — rebuilds when ANY task property changes
final tasks = ref.watch(tasksProvider);
final count = tasks.length;
```

**Use `ref.read` for one-time reads (event handlers):**

```dart
// ✅ CORRECT — read once on tap, don't watch
onTap: () {
  ref.read(tasksProvider.notifier).completeTask(taskId);
}

// ❌ WRONG — watching in an event handler
onTap: () {
  ref.watch(tasksProvider.notifier).completeTask(taskId);  // BAD
}
```

**Use `autoDispose` to clean up unused providers:**

```dart
// ✅ Provider disposes when no widget watches it
@riverpod
Future<List<Document>> documents(DocumentsRef ref) async {
  // Auto-disposed when document list screen is popped
  return fetchDocuments();
}
```

### 5.2 Avoid Provider Chains

Don't create long chains of providers that all trigger rebuilds.

```dart
// ✅ GOOD — single provider does the work
@riverpod
Future<MaintenanceDashboard> maintenanceDashboard(MaintenanceDashboardRef ref) async {
  final tasks = await fetchTasks();
  final score = calculateScore(tasks);
  return MaintenanceDashboard(tasks: tasks, score: score);
}

// ❌ BAD — chain of providers that cascade rebuilds
@riverpod
Future<List<Task>> tasks(TasksRef ref) => fetchTasks();

@riverpod
int taskCount(TaskCountRef ref) => ref.watch(tasksProvider).value?.length ?? 0;

@riverpod
double healthScore(HealthScoreRef ref) {
  final tasks = ref.watch(tasksProvider).value ?? [];
  return calculateScore(tasks);  // Rebuilds when tasks rebuild
}
```

---

## 6. Caching Strategy

### 6.1 Three Cache Layers

```
Layer 1: Riverpod Provider Cache (in-memory, per session)
  ↓ miss
Layer 2: SharedPreferences / Hive (on-device, persists across sessions)
  ↓ miss
Layer 3: Supabase (server, source of truth)
```

### 6.2 What to Cache Where

| Data | Layer 1 (Memory) | Layer 2 (Disk) | Layer 3 (Server) | TTL |
|------|-----------------|---------------|-----------------|-----|
| Document list | ✅ | ✅ (last page) | ✅ | Refresh on pull |
| Task list | ✅ | ✅ (last page) | ✅ | Refresh on pull |
| System/appliance list | ✅ | ✅ | ✅ | Refresh on pull |
| Emergency Hub data | ✅ | ✅ (SQLite) | ✅ | Sync on every open |
| Category lookups | ✅ | ✅ | ✅ | Cache 24 hours |
| Document type lookups | ✅ | ✅ | ✅ | Cache 24 hours |
| Task templates | ✅ | ✅ | ✅ | Cache 24 hours |
| Phase templates | ✅ | ✅ | ✅ | Cache 24 hours |
| User profile | ✅ | ✅ | ✅ | Cache until changed |
| Property info | ✅ | ✅ | ✅ | Cache until changed |
| Image thumbnails | ✅ | ✅ (CachedNetworkImage) | ✅ | Cache 7 days |
| Full-size images | ❌ (too large) | ✅ (CachedNetworkImage) | ✅ | Cache 7 days |
| Signed URLs | ✅ | ❌ | N/A | Cache 1 hour (Supabase default) |

### 6.3 Cache-First Pattern

For screens that load frequently, use cache-first:

```dart
// Show cached data immediately, then refresh from server
@riverpod
class DocumentList extends _$DocumentList {
  @override
  Future<List<Document>> build() async {
    // Step 1: Return cached data immediately (if available)
    final cached = await _loadFromCache();
    if (cached != null) {
      // Show cached, then fetch fresh in background
      _refreshFromServer();
      return cached;
    }

    // Step 2: No cache — fetch from server
    final fresh = await _fetchFromServer();
    await _saveToCache(fresh);
    return fresh;
  }

  Future<void> _refreshFromServer() async {
    final fresh = await _fetchFromServer();
    await _saveToCache(fresh);
    state = AsyncValue.data(fresh);  // Update UI with fresh data
  }
}
```

### 6.4 Lookup Table Pre-Loading

Pre-load lookup tables at app startup so they're instant when needed:

```dart
// In app initialization (after auth)
Future<void> preloadLookups() async {
  await Future.wait([
    ref.read(categoriesProvider.future),    // Document categories
    ref.read(documentTypesProvider.future), // Document types
    ref.read(taskTemplatesProvider.future), // Maintenance templates
    ref.read(phaseTemplatesProvider.future), // Project phase templates
  ]);
}
```

These are small datasets (< 100 rows total) that every screen references. Loading them once at startup means pickers and filters are instant.

---

## 7. Search Performance

### 7.1 Debouncing

Never fire a search query on every keystroke. Debounce.

```dart
// ✅ FAST — debounce 300ms, cancels previous query
Timer? _debounceTimer;

void onSearchChanged(String query) {
  _debounceTimer?.cancel();
  _debounceTimer = Timer(const Duration(milliseconds: 300), () {
    performSearch(query);
  });
}
```

### 7.2 Free Tier Search (Name + Category)

Fast by default — uses trigram index.

```dart
// ✅ Trigram search with pg_trgm — fast fuzzy matching
final results = await supabase
  .from('documents')
  .select('id, name, category_id, thumbnail_path, created_at')
  .eq('property_id', propertyId)
  .is_('deleted_at', null)
  .ilike('name', '%$query%')         // Hits idx_documents_search (GIN trgm)
  .order('created_at', ascending: false)
  .limit(20);
```

### 7.3 Premium OCR Search (Full-Text)

Full-text search using PostgreSQL tsvector.

```dart
// ✅ Full-text search — hits idx_documents_ocr_search
final results = await supabase
  .from('documents')
  .select('id, name, category_id, thumbnail_path, created_at')
  .eq('property_id', propertyId)
  .is_('deleted_at', null)
  .textSearch('ocr_text', query, type: TextSearchType.websearch)
  .order('created_at', ascending: false)
  .limit(20);
```

### 7.4 Search Result Ranking

For OCR search, PostgreSQL `ts_rank` provides relevance ranking:

```sql
-- RPC for ranked search results
CREATE OR REPLACE FUNCTION search_documents(
  p_property_id UUID,
  p_query TEXT,
  p_limit INT DEFAULT 20
) RETURNS TABLE (
  id UUID,
  name TEXT,
  category_id UUID,
  thumbnail_path TEXT,
  created_at TIMESTAMPTZ,
  rank REAL,
  snippet TEXT
) AS $$
BEGIN
  RETURN QUERY
  SELECT
    d.id, d.name, d.category_id, d.thumbnail_path, d.created_at,
    ts_rank(d.ocr_search_vector, websearch_to_tsquery('english', p_query)) AS rank,
    ts_headline('english', d.ocr_text, websearch_to_tsquery('english', p_query),
      'MaxWords=30, MinWords=15, StartSel=**, StopSel=**') AS snippet
  FROM documents d
  WHERE d.property_id = p_property_id
    AND d.deleted_at IS NULL
    AND d.ocr_search_vector @@ websearch_to_tsquery('english', p_query)
  ORDER BY rank DESC
  LIMIT p_limit;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
```

### 7.5 Search UX Optimization

- Show results as user types (after debounce) — don't wait for "Enter"
- Show recent searches (stored locally) as autocomplete suggestions
- Show "Searching..." skeleton state during query
- If query takes > 500ms, show subtle progress indicator
- Cache last 10 search results in memory (going back to a previous search is instant)

---

## 8. Network Optimization

### 8.1 Request Batching

When a screen needs data from multiple tables, use nested selects (not separate calls):

```dart
// ✅ ONE request — nested select
final project = await supabase.from('projects').select('''
  *, phases:project_phases(*), budget:project_budget_items(*)
''').eq('id', projectId).single();

// ❌ THREE requests
final project = await supabase.from('projects').select().eq('id', projectId).single();
final phases = await supabase.from('project_phases').select().eq('project_id', projectId);
final budget = await supabase.from('project_budget_items').select().eq('project_id', projectId);
```

### 8.2 Parallel Requests

When you must make multiple independent requests, use `Future.wait`:

```dart
// ✅ FAST — parallel execution
final results = await Future.wait([
  supabase.from('documents').select('*').eq('property_id', propertyId),
  supabase.from('maintenance_tasks').select('*').eq('property_id', propertyId),
  supabase.from('projects').select('*').eq('property_id', propertyId),
]);

// ❌ SLOW — sequential execution (3x slower)
final docs = await supabase.from('documents').select('*').eq('property_id', propertyId);
final tasks = await supabase.from('maintenance_tasks').select('*').eq('property_id', propertyId);
final projects = await supabase.from('projects').select('*').eq('property_id', propertyId);
```

### 8.3 Connection Pooling

Supabase client reuses connections automatically. Don't create new clients per request:

```dart
// ✅ Singleton — created once
final supabase = Supabase.instance.client;

// ❌ Never do this
final client = SupabaseClient(url, anonKey);  // New connection each time
```

### 8.4 Payload Size Optimization

Minimize data over the wire:

```dart
// ✅ Only request needed columns
.select('id, name, status, created_at')

// ✅ Limit results
.limit(25)

// ✅ Use count query when you only need the count
.select('*', { count: 'exact', head: true })  // Returns count, no data
```

---

## 9. App Startup Optimization

### 9.1 Startup Time Budget: < 3 Seconds Cold Start

```
0ms     → App process starts
200ms   → Flutter engine initialized
500ms   → First frame painted (splash screen)
1000ms  → Auth state checked
1500ms  → Main screen skeleton visible
2500ms  → Data loaded, content rendered
3000ms  → App fully interactive (DEADLINE)
```

### 9.2 Startup Sequence

```dart
void main() async {
  // PHASE 1: Critical (blocks first frame)
  WidgetsFlutterBinding.ensureInitialized();
  await Supabase.initialize(url: config.supabaseUrl, anonKey: config.supabaseAnonKey);

  // PHASE 2: Launch app (shows splash or main screen immediately)
  runApp(const ProviderScope(child: HomeTrackApp()));

  // PHASE 3: Deferred (happens after first frame, doesn't block UI)
  // These run in the background after the app is visible:
  // - Sentry initialization
  // - PostHog initialization
  // - Push notification token registration
  // - Lookup table pre-loading
  // - Emergency Hub sync check
}
```

### 9.3 Deferred Initialization

Don't block startup with non-critical services:

```dart
class HomeTrackApp extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Schedule deferred init after first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _deferredInit(ref);
    });

    return MaterialApp.router(/* ... */);
  }

  Future<void> _deferredInit(WidgetRef ref) async {
    // These don't block the UI
    await Future.wait([
      SentryFlutter.init(/* ... */),
      Posthog.init(/* ... */),
      ref.read(lookupTablesProvider.future),
    ]);
  }
}
```

---

## 10. List & Scroll Performance

### 10.1 Always Use `.builder()` Constructors

```dart
// ✅ FAST — only builds visible items
ListView.builder(
  itemCount: 500,
  itemBuilder: (context, index) => DocumentCard(doc: docs[index]),
)

// ❌ SLOW — builds all 500 items at once
ListView(
  children: docs.map((doc) => DocumentCard(doc: doc)).toList(),
)
```

### 10.2 Use `itemExtent` When Possible

If all list items have the same height, tell Flutter:

```dart
// ✅ FAST — Flutter can calculate scroll position without measuring items
ListView.builder(
  itemExtent: 80,  // Fixed height per item
  itemBuilder: (context, index) => TaskCard(task: tasks[index]),
)
```

### 10.3 Use `SliverList` for Complex Layouts

Screens with multiple sections (header, filters, list) should use `CustomScrollView` with slivers:

```dart
CustomScrollView(
  slivers: [
    // Navigation bar
    adaptiveNavigationBar(title: 'Maintenance'),

    // Pull-to-refresh
    CupertinoSliverRefreshControl(onRefresh: refresh),

    // Health score (non-scrollable header)
    SliverToBoxAdapter(child: HealthScoreWidget()),

    // Filter chips
    SliverToBoxAdapter(child: FilterChipRow()),

    // Task list (efficient scrolling)
    SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, index) => TaskCard(task: tasks[index]),
        childCount: tasks.length,
      ),
    ),
  ],
)
```

### 10.4 Infinite Scroll / Load More

```dart
// ✅ Detect scroll near bottom, load next page
NotificationListener<ScrollNotification>(
  onNotification: (notification) {
    if (notification.metrics.pixels >= notification.metrics.maxScrollExtent - 200) {
      ref.read(documentsProvider.notifier).loadNextPage();
    }
    return false;
  },
  child: ListView.builder(/* ... */),
)
```

---

## 11. Animation Performance

### 11.1 Rules

- **Use `AnimatedContainer`, `AnimatedOpacity`, `AnimatedSwitcher`** for simple transitions — Flutter optimizes these internally.
- **Never animate in `build()`** — use `AnimationController` in `StatefulWidget` or `AnimatedBuilder`.
- **Keep animations at 200-300ms** — fast enough to feel snappy, slow enough to be perceived.
- **Use `Curves.easeOutCubic`** as default — feels responsive and natural.

### 11.2 Skeleton Shimmer

The shimmer animation should be GPU-accelerated:

```dart
// ✅ Uses Shimmer package — GPU-optimized
Shimmer.fromColors(
  baseColor: Colors.grey[300]!,
  highlightColor: Colors.grey[100]!,
  period: const Duration(milliseconds: 1500),
  child: Container(
    width: double.infinity,
    height: 80,
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
    ),
  ),
)
```

### 11.3 Page Transitions

```dart
// ✅ Platform-appropriate, smooth transitions
// iOS: Cupertino slide (right-to-left, with back gesture)
// Android: Material fade-through or shared axis

// GoRouter handles this when you use CupertinoPage vs MaterialPage
// See Platform UI Guide, Section 4.2
```

---

## 12. Perceived Performance Tricks

When you can't make it actually faster, make it feel faster.

### 12.1 Optimistic Updates

Show the result immediately, sync with server in background.

```dart
// ✅ Task appears complete IMMEDIATELY, server syncs after
void completeTask(String taskId) {
  // 1. Update local state instantly
  state = state.map((task) =>
    task.id == taskId ? task.copyWith(status: 'completed') : task
  ).toList();

  // 2. Sync to server in background
  supabase.from('maintenance_tasks')
    .update({'status': 'completed', 'completed_at': DateTime.now().toIso8601String()})
    .eq('id', taskId)
    .then((_) => null)
    .catchError((e) {
      // 3. Revert on failure
      state = state.map((task) =>
        task.id == taskId ? task.copyWith(status: 'scheduled') : task
      ).toList();
      showSnackbar('Couldn\'t complete task. Please try again.');
    });
}
```

**Use optimistic updates for:**
- Task completion / skip
- Favorite toggle (contacts)
- Document metadata edits
- Project status changes
- Note edits
- Phase reordering

**Don't use optimistic updates for:**
- File uploads (need real progress)
- Account deletion (irreversible)
- Payment actions (must confirm server-side)

### 12.2 Prefetching

Predict what the user will do next and load it before they tap.

```dart
// ✅ When document list is visible, prefetch the first document's detail
if (documents.isNotEmpty) {
  ref.read(documentDetailProvider(documents.first.id));  // Warm cache
}

// ✅ When user is on Task List, prefetch the first overdue task detail
if (overdueTasks.isNotEmpty) {
  ref.read(taskDetailProvider(overdueTasks.first.id));
}
```

### 12.3 Skeleton Timing

Show skeleton immediately — don't wait to decide if you need it.

```dart
// ✅ Show skeleton on frame 1, replace when data arrives
Widget build(BuildContext context, WidgetRef ref) {
  final asyncDocs = ref.watch(documentsProvider);

  return asyncDocs.when(
    loading: () => const DocumentListSkeleton(),  // Instant
    error: (e, s) => ErrorView(onRetry: () => ref.invalidate(documentsProvider)),
    data: (docs) => docs.isEmpty
      ? const DocumentsEmptyState()
      : DocumentListView(documents: docs),
  );
}

// ❌ Don't show a blank screen, then a spinner, then content
```

### 12.4 Progressive Loading

For detail screens with multiple sections, load sections independently:

```dart
// Project detail: header loads fast, budget/photos/notes load progressively
Column(
  children: [
    // These load from the parent's cached data (instant)
    ProjectHeader(project: project),
    ProjectStatusBar(project: project),

    // These load independently (show skeleton per section)
    AsyncPhaseList(projectId: project.id),
    AsyncBudgetSummary(projectId: project.id),
    AsyncPhotoGrid(projectId: project.id),
  ],
)
```

---

## 13. Monitoring & Profiling

### 13.1 Flutter DevTools Checks

Before merging any feature, run these checks:

```bash
# 1. Performance overlay — verify 60fps scrolling
flutter run --profile  # Run in profile mode (release-like performance)

# 2. In DevTools:
# - Timeline view: check for jank (frames > 16ms)
# - Memory view: check for leaks (memory growing without shrinking)
# - Network view: check for excessive requests
```

### 13.2 Performance Metrics to Track (PostHog)

```dart
// Track screen load times
final stopwatch = Stopwatch()..start();
await loadDocuments();
stopwatch.stop();

posthog.capture('screen_loaded', properties: {
  'screen': 'document_list',
  'load_time_ms': stopwatch.elapsedMilliseconds,
  'item_count': documents.length,
});
```

**Alert thresholds:**
- Screen load > 1000ms → Warning
- Screen load > 2000ms → Error (investigate)
- Search query > 500ms → Warning
- Upload start > 300ms → Warning

### 13.3 Sentry Performance Monitoring

```dart
// Automatic transaction tracking
final transaction = Sentry.startTransaction('load_documents', 'ui.load');
try {
  final docs = await fetchDocuments();
  transaction.status = SpanStatus.ok();
} catch (e) {
  transaction.status = SpanStatus.internalError();
  Sentry.captureException(e);
} finally {
  await transaction.finish();
}
```

---

## 14. Performance Checklist Per Feature

Every agent must verify these before marking a feature complete.

### Build-Time Checks

- [ ] All `StatelessWidget` constructors are `const` where possible
- [ ] No `Image.network` — all images use `CachedNetworkImage`
- [ ] All lists use `.builder()` constructors
- [ ] All images have explicit dimensions (no layout shift)
- [ ] All database queries select only needed columns
- [ ] All database queries filter by `property_id` first
- [ ] No N+1 query patterns (use nested selects)
- [ ] Pagination implemented for lists > 20 items
- [ ] Search debounced (300ms minimum)
- [ ] `RepaintBoundary` on complex paint widgets (charts, gauges)

### Runtime Checks

- [ ] Screen loads in under 1 second (test on physical device)
- [ ] Scrolling is 60fps (no jank in profile mode)
- [ ] Tab switching is under 100ms
- [ ] Search returns results in under 500ms
- [ ] No memory leaks (check DevTools memory tab after navigating away and back 5 times)
- [ ] Skeleton loading visible immediately (no blank flash)
- [ ] Pull-to-refresh completes in under 600ms

### Size Checks

- [ ] No uncompressed images in assets
- [ ] Feature doesn't add > 2MB to app binary
- [ ] Cached images have reasonable TTL (not unbounded)

---

**Cross-reference:** For adaptive widget patterns that maintain performance across platforms, see **HomeTrack Platform UI Compliance Guide, Sections 3 and 9**.

---

*End of Performance & Optimization Guide*
*HomeTrack — Version 1.0 — February 2026*
