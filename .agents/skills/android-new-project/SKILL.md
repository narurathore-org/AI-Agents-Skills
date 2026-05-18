# android-new-project

Sets up a new Android project from scratch with clean layered architecture,
MVVM, Jetpack Compose, Kotlin Multiplatform (KMP) for shared logic, and a
full testing strategy. Also scaffolds a companion `ui-toolkit` library as a
separate repository publishable as a Gradle dependency.

---

## What this skill produces

### 1. Main Android app repository

```
<project-name>/
├── build-logic/                        # Convention plugins (Gradle)
│   └── src/main/kotlin/
│       ├── AndroidAppConventionPlugin.kt
│       ├── AndroidLibraryConventionPlugin.kt
│       ├── ComposeConventionPlugin.kt
│       ├── KmpConventionPlugin.kt
│       └── TestingConventionPlugin.kt
├── app/                                # Android app shell
│   ├── src/main/kotlin/.../
│   │   ├── MainActivity.kt
│   │   ├── AppNavHost.kt
│   │   └── di/AppModule.kt
│   └── src/test/ & src/androidTest/
├── shared/                             # KMP — business logic lives here
│   ├── src/commonMain/kotlin/.../
│   │   ├── domain/
│   │   │   ├── model/                 # Pure data classes
│   │   │   ├── repository/            # Interfaces only
│   │   │   └── usecase/               # One class per use case
│   │   └── data/
│   │       ├── repository/            # Implementations
│   │       ├── remote/                # Ktor API client
│   │       └── local/                 # SQLDelight / Room expect
│   ├── src/commonTest/kotlin/          # KMP unit tests
│   ├── src/androidMain/kotlin/         # Android actuals
│   └── src/androidTest/kotlin/
├── feature/<name>/                     # One module per feature
│   ├── src/main/kotlin/.../
│   │   ├── <Name>Screen.kt            # Compose screen
│   │   ├── <Name>ViewModel.kt
│   │   └── <Name>UiState.kt           # Sealed class / data class
│   ├── src/test/kotlin/               # ViewModel + UseCase unit tests
│   └── src/androidTest/kotlin/        # Compose UI tests
├── gradle/libs.versions.toml           # Single version catalog
├── settings.gradle.kts
└── build.gradle.kts
```

### 2. UI Toolkit repository (separate)

```
<project-name>-ui-toolkit/
├── toolkit/                            # Library module
│   ├── src/main/kotlin/.../
│   │   ├── tokens/                    # Design tokens
│   │   │   ├── Color.kt
│   │   │   ├── Typography.kt
│   │   │   └── Spacing.kt
│   │   ├── theme/
│   │   │   └── AppTheme.kt
│   │   └── components/                # One file per component
│   │       ├── Button.kt
│   │       ├── TextField.kt
│   │       └── ...
│   └── src/androidTest/kotlin/        # Compose UI tests for every component
├── catalog/                            # Optional: Compose component catalog app
├── gradle/libs.versions.toml
└── settings.gradle.kts
```

---

## Inputs to resolve before starting

Ask if not provided:

- **Project name** — used for package name, repo name, module names.
- **Package name** — e.g. `com.example.myapp`.
- **Root directory** — where to create the project folders.
- **UI Toolkit** — create the ui-toolkit repo now, or scaffold placeholder only?
- **Publish target** — GitHub Packages (default) or Maven Local only?
- **iOS target** — include KMP iOS source sets? (default: no, add later)

---

## Steps

### Step 1 — Scaffold build-logic and version catalog

1. Create `settings.gradle.kts` with `includeBuild("build-logic")` and module
   includes (`app`, `shared`, `feature/*`).

2. Create `gradle/libs.versions.toml` with:

```toml
[versions]
kotlin = "2.1.0"
agp = "8.9.0"
compose-bom = "2025.04.01"
hilt = "2.56"
ktor = "3.1.3"
coroutines = "1.10.2"
turbine = "1.2.0"
mockk = "1.14.0"
junit5 = "5.11.4"
kotest = "5.9.1"

[libraries]
# Compose BOM — import in each module, no version needed after this
compose-bom = { group = "androidx.compose", name = "compose-bom", version.ref = "compose-bom" }
compose-ui = { group = "androidx.compose.ui", name = "ui" }
compose-ui-tooling = { group = "androidx.compose.ui", name = "ui-tooling" }
compose-ui-test-junit4 = { group = "androidx.compose.ui", name = "ui-test-junit4" }
compose-ui-test-manifest = { group = "androidx.compose.ui", name = "ui-test-manifest" }
compose-material3 = { group = "androidx.compose.material3", name = "material3" }
compose-navigation = { group = "androidx.navigation", name = "navigation-compose", version = "2.9.0" }

hilt-android = { group = "com.google.dagger", name = "hilt-android", version.ref = "hilt" }
hilt-compiler = { group = "com.google.dagger", name = "hilt-android-compiler", version.ref = "hilt" }
hilt-navigation-compose = { group = "androidx.hilt", name = "hilt-navigation-compose", version = "1.2.0" }

ktor-client-core = { group = "io.ktor", name = "ktor-client-core", version.ref = "ktor" }
ktor-client-android = { group = "io.ktor", name = "ktor-client-android", version.ref = "ktor" }
ktor-client-content-negotiation = { group = "io.ktor", name = "ktor-client-content-negotiation", version.ref = "ktor" }
ktor-serialization-json = { group = "io.ktor", name = "ktor-serialization-kotlinx-json", version.ref = "ktor" }

coroutines-core = { group = "org.jetbrains.kotlinx", name = "kotlinx-coroutines-core", version.ref = "coroutines" }
coroutines-android = { group = "org.jetbrains.kotlinx", name = "kotlinx-coroutines-android", version.ref = "coroutines" }
coroutines-test = { group = "org.jetbrains.kotlinx", name = "kotlinx-coroutines-test", version.ref = "coroutines" }

turbine = { group = "app.cash.turbine", name = "turbine", version.ref = "turbine" }
mockk = { group = "io.mockk", name = "mockk", version.ref = "mockk" }
junit5-api = { group = "org.junit.jupiter", name = "junit-jupiter-api", version.ref = "junit5" }
junit5-engine = { group = "org.junit.jupiter", name = "junit-jupiter-engine", version.ref = "junit5" }

[plugins]
android-application = { id = "com.android.application", version.ref = "agp" }
android-library = { id = "com.android.library", version.ref = "agp" }
kotlin-android = { id = "org.jetbrains.kotlin.android", version.ref = "kotlin" }
kotlin-multiplatform = { id = "org.jetbrains.kotlin.multiplatform", version.ref = "kotlin" }
kotlin-serialization = { id = "org.jetbrains.kotlin.plugin.serialization", version.ref = "kotlin" }
hilt = { id = "com.google.dagger.hilt.android", version.ref = "hilt" }
ksp = { id = "com.google.devtools.ksp", version = "2.1.0-1.0.29" }
compose-compiler = { id = "org.jetbrains.kotlin.plugin.compose", version.ref = "kotlin" }
```

3. Create convention plugins in `build-logic/` so every module stays DRY:
   - `AndroidLibraryConventionPlugin` — applies `android-library` + `kotlin-android`, sets `compileSdk = 36`, `minSdk = 26`
   - `ComposeConventionPlugin` — applies `compose-compiler` plugin, adds Compose BOM + `compose-ui`, `compose-material3`, `compose-ui-tooling`
   - `KmpConventionPlugin` — applies `kotlin-multiplatform`, configures `androidTarget`, `jvmTarget`
   - `TestingConventionPlugin` — adds `coroutines-test`, `turbine`, `mockk`, JUnit 5 to any module

---

### Step 2 — Scaffold the `shared` KMP module

**`shared/build.gradle.kts`:**
```kotlin
plugins {
    alias(libs.plugins.kotlin.multiplatform)
    alias(libs.plugins.android.library)
    alias(libs.plugins.kotlin.serialization)
}

kotlin {
    androidTarget {
        compilations.all { kotlinOptions { jvmTarget = "17" } }
    }
    // jvm() — add when desktop/server target needed

    sourceSets {
        commonMain.dependencies {
            implementation(libs.coroutines.core)
            implementation(libs.ktor.client.core)
            implementation(libs.ktor.client.content.negotiation)
            implementation(libs.ktor.serialization.json)
        }
        commonTest.dependencies {
            implementation(kotlin("test"))
            implementation(libs.coroutines.test)
            implementation(libs.turbine)
        }
        androidMain.dependencies {
            implementation(libs.ktor.client.android)
            implementation(libs.coroutines.android)
        }
    }
}
```

**Layer structure rules (enforce strictly):**
- `domain/` — pure Kotlin, zero Android imports, zero framework deps. Only stdlib + coroutines.
- `domain/repository/` — interfaces only. No implementations.
- `domain/usecase/` — one public `operator fun invoke()` per class. Calls repository interfaces.
- `data/` — implements domain interfaces. Knows about Ktor, SQLDelight, etc.
- `data/` must NOT be imported by `app/` directly — only through DI bindings.

**Testing rules for `shared`:**
- Every `UseCase` has a `commonTest` unit test.
- Every `Repository` implementation has an `androidTest` integration test (or `commonTest` with fakes).
- Test dispatchers: inject `CoroutineDispatcher` into every class that launches coroutines; use `StandardTestDispatcher` + `TestScope` in tests.
- Use `Turbine` to test `Flow` emissions.

---

### Step 3 — Scaffold a feature module

For each feature (repeat this pattern):

```
feature/<name>/
├── src/main/kotlin/<package>/feature/<name>/
│   ├── <Name>Screen.kt
│   ├── <Name>ViewModel.kt
│   └── <Name>UiState.kt
├── src/test/kotlin/                        # ViewModel unit tests
└── src/androidTest/kotlin/                 # Compose UI tests
```

**`<Name>UiState.kt`:**
```kotlin
sealed interface <Name>UiState {
    data object Loading : <Name>UiState
    data class Content(val items: List<Item>) : <Name>UiState
    data class Error(val message: String) : <Name>UiState
}
```

**`<Name>ViewModel.kt`:**
```kotlin
@HiltViewModel
class <Name>ViewModel @Inject constructor(
    private val get<Name>UseCase: Get<Name>UseCase,
    private val ioDispatcher: CoroutineDispatcher = Dispatchers.IO
) : ViewModel() {

    private val _uiState = MutableStateFlow<<Name>UiState>(<Name>UiState.Loading)
    val uiState: StateFlow<<Name>UiState> = _uiState.asStateFlow()

    init { load() }

    fun load() {
        viewModelScope.launch(ioDispatcher) {
            get<Name>UseCase()
                .onSuccess { _uiState.value = <Name>UiState.Content(it) }
                .onFailure { _uiState.value = <Name>UiState.Error(it.message ?: "") }
        }
    }
}
```

**`<Name>Screen.kt`:**
```kotlin
@Composable
fun <Name>Screen(
    viewModel: <Name>ViewModel = hiltViewModel(),
    modifier: Modifier = Modifier
) {
    val uiState by viewModel.uiState.collectAsStateWithLifecycle()
    <Name>Content(uiState = uiState, modifier = modifier)
}

// Stateless overload — used in Compose UI tests directly (no ViewModel dependency)
@Composable
internal fun <Name>Content(
    uiState: <Name>UiState,
    modifier: Modifier = Modifier
) {
    when (uiState) {
        is <Name>UiState.Loading -> CircularProgressIndicator(
            modifier = Modifier.testTag("<name>_loading")
        )
        is <Name>UiState.Content -> <Name>List(
            items = uiState.items,
            modifier = modifier.testTag("<name>_content")
        )
        is <Name>UiState.Error -> ErrorMessage(
            message = uiState.message,
            modifier = Modifier.testTag("<name>_error")
        )
    }
}
```

**Compose test tag rules:**
- Every top-level screen composable has a root `testTag("<screen>_root")`.
- Every UiState branch has a unique `testTag("<screen>_loading"`, `"_content"`, `"_error"`)`.
- Interactive elements: `testTag("<screen>_<element>_button")`, `"_input"`, `"_item_<id>"`.
- Use `semantics { contentDescription = ... }` for non-interactive elements accessed by tests.
- Never use hardcoded strings in tests — define all tags in a companion object or constants file:

```kotlin
object <Name>TestTags {
    const val Root = "<name>_root"
    const val Loading = "<name>_loading"
    const val Content = "<name>_content"
    const val Error = "<name>_error"
    const val RetryButton = "<name>_retry_button"
}
```

---

### Step 4 — Testing strategy (enforce on every feature)

#### 4.1 — ViewModel unit tests (`src/test/`)

Every ViewModel gets tests covering every UiState transition:

```kotlin
@ExtendWith(CoroutineTestExtension::class)
class <Name>ViewModelTest {

    private val get<Name>UseCase: Get<Name>UseCase = mockk()
    private lateinit var viewModel: <Name>ViewModel

    @Test
    fun `initial state is Loading`() = runTest {
        coEvery { get<Name>UseCase() } coAnswers { delay(100); Result.success(emptyList()) }
        viewModel = <Name>ViewModel(get<Name>UseCase, UnconfinedTestDispatcher())
        viewModel.uiState.test {
            assertThat(awaitItem()).isInstanceOf(<Name>UiState.Loading::class.java)
            cancelAndIgnoreRemainingEvents()
        }
    }

    @Test
    fun `emits Content when use case succeeds`() = runTest {
        val items = listOf(Item("1"))
        coEvery { get<Name>UseCase() } returns Result.success(items)
        viewModel = <Name>ViewModel(get<Name>UseCase, UnconfinedTestDispatcher())
        viewModel.uiState.test {
            skipItems(1) // Loading
            assertThat(awaitItem()).isEqualTo(<Name>UiState.Content(items))
        }
    }

    @Test
    fun `emits Error when use case fails`() = runTest {
        coEvery { get<Name>UseCase() } returns Result.failure(Exception("network error"))
        viewModel = <Name>ViewModel(get<Name>UseCase, UnconfinedTestDispatcher())
        viewModel.uiState.test {
            skipItems(1)
            assertThat(awaitItem()).isInstanceOf(<Name>UiState.Error::class.java)
        }
    }
}
```

#### 4.2 — Compose UI tests (`src/androidTest/`)

Every screen gets tests for every UiState and every user interaction:

```kotlin
@HiltAndroidTest
class <Name>ScreenTest {

    @get:Rule(order = 0) val hiltRule = HiltAndroidRule(this)
    @get:Rule(order = 1) val composeRule = createAndroidComposeRule<ComponentActivity>()

    @Test
    fun showsLoadingIndicator_whenStateIsLoading() {
        composeRule.setContent {
            AppTheme { <Name>Content(uiState = <Name>UiState.Loading) }
        }
        composeRule.onNodeWithTag(<Name>TestTags.Loading).assertIsDisplayed()
        composeRule.onNodeWithTag(<Name>TestTags.Content).assertDoesNotExist()
    }

    @Test
    fun showsItems_whenStateIsContent() {
        val items = listOf(Item("1", "Test Item"))
        composeRule.setContent {
            AppTheme { <Name>Content(uiState = <Name>UiState.Content(items)) }
        }
        composeRule.onNodeWithTag(<Name>TestTags.Content).assertIsDisplayed()
        composeRule.onNodeWithText("Test Item").assertIsDisplayed()
    }

    @Test
    fun showsError_whenStateIsError() {
        composeRule.setContent {
            AppTheme { <Name>Content(uiState = <Name>UiState.Error("Something went wrong")) }
        }
        composeRule.onNodeWithTag(<Name>TestTags.Error).assertIsDisplayed()
        composeRule.onNodeWithText("Something went wrong").assertIsDisplayed()
    }

    @Test
    fun retryButton_triggersReload() {
        var retryClicked = false
        composeRule.setContent {
            AppTheme {
                <Name>Content(
                    uiState = <Name>UiState.Error("error"),
                    onRetry = { retryClicked = true }
                )
            }
        }
        composeRule.onNodeWithTag(<Name>TestTags.RetryButton).performClick()
        assertThat(retryClicked).isTrue()
    }
}
```

**Corner cases to cover in every feature:**
- Empty state (list with no items)
- Single item vs multiple items
- Long text / overflow
- Error state + retry action
- Loading → Content transition
- Loading → Error transition
- Back navigation / screen dismissal
- Accessibility: `contentDescription` on icon-only buttons

---

### Step 5 — Scaffold the UI Toolkit repository

Create as a **separate git repository**: `<project-name>-ui-toolkit`.

```kotlin
// toolkit/build.gradle.kts
plugins {
    alias(libs.plugins.android.library)
    alias(libs.plugins.kotlin.android)
    alias(libs.plugins.compose.compiler)
    `maven-publish`
}

publishing {
    publications {
        create<MavenPublication>("release") {
            groupId = "com.<yourname>"
            artifactId = "<project-name>-ui-toolkit"
            version = "1.0.0"
            afterEvaluate { from(components["release"]) }
        }
    }
    repositories {
        maven {
            name = "GitHubPackages"
            url = uri("https://maven.pkg.github.com/<github-username>/<project-name>-ui-toolkit")
            credentials {
                username = System.getenv("GITHUB_ACTOR")
                password = System.getenv("GITHUB_TOKEN")
            }
        }
    }
}
```

**Component rules:**
- One file per component under `toolkit/src/main/kotlin/.../components/`.
- Every component is stateless — takes lambdas for callbacks, no ViewModel dependency.
- Every component has a preview (`@Preview`) AND a Compose UI test.
- Components expose a `modifier: Modifier = Modifier` parameter as the last parameter.
- Use design tokens (`AppTheme.colors`, `AppTheme.typography`, `AppTheme.spacing`) — never hardcode colors or dimensions.

**Design tokens:**
```kotlin
object AppSpacing {
    val xs = 4.dp
    val sm = 8.dp
    val md = 16.dp
    val lg = 24.dp
    val xl = 32.dp
}
```

**UI Toolkit Compose test pattern:**
```kotlin
class AppButtonTest {

    @get:Rule val composeRule = createComposeRule()

    @Test
    fun rendersLabel() {
        composeRule.setContent {
            AppTheme { AppButton(label = "Submit", onClick = {}) }
        }
        composeRule.onNodeWithText("Submit").assertIsDisplayed()
    }

    @Test
    fun isDisabled_whenEnabledFalse() {
        composeRule.setContent {
            AppTheme { AppButton(label = "Submit", enabled = false, onClick = {}) }
        }
        composeRule.onNodeWithText("Submit").assertIsNotEnabled()
    }

    @Test
    fun firesOnClick_whenClicked() {
        var clicked = false
        composeRule.setContent {
            AppTheme { AppButton(label = "Submit", onClick = { clicked = true }) }
        }
        composeRule.onNodeWithText("Submit").performClick()
        assertThat(clicked).isTrue()
    }
}
```

**Publishing workflow (GitHub Actions):**
```yaml
# .github/workflows/publish.yml
name: Publish
on:
  push:
    tags: [ 'v*' ]
jobs:
  publish:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-java@v4
        with: { java-version: '17', distribution: 'temurin' }
      - run: ./gradlew :toolkit:publishReleasePublicationToGitHubPackagesRepository
        env:
          GITHUB_ACTOR: ${{ github.actor }}
          GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}
```

**Consuming the toolkit in the main project:**

```kotlin
// settings.gradle.kts
dependencyResolutionManagement {
    repositories {
        maven {
            url = uri("https://maven.pkg.github.com/<github-username>/<project-name>-ui-toolkit")
            credentials {
                username = providers.gradleProperty("github.actor").orNull ?: System.getenv("GITHUB_ACTOR")
                password = providers.gradleProperty("github.token").orNull ?: System.getenv("GITHUB_TOKEN")
            }
        }
    }
}
```

```toml
# gradle/libs.versions.toml
[libraries]
ui-toolkit = { group = "com.<yourname>", name = "<project-name>-ui-toolkit", version = "1.0.0" }
```

---

### Step 6 — DI wiring (Hilt)

- `shared` module does NOT use Hilt — it's KMP. Use constructor injection with interfaces.
- `app` module provides bindings: `@Provides` for repository implementations, dispatchers, Ktor client.
- Feature modules use `@HiltViewModel` — no manual ViewModel factories.
- Provide `CoroutineDispatcher` as `@IoDispatcher` / `@MainDispatcher` named qualifiers for testability.

```kotlin
@Module @InstallIn(SingletonComponent::class)
object DispatcherModule {
    @Provides @IoDispatcher fun provideIoDispatcher(): CoroutineDispatcher = Dispatchers.IO
    @Provides @MainDispatcher fun provideMainDispatcher(): CoroutineDispatcher = Dispatchers.Main
}
```

---

### Step 7 — Non-negotiables (apply to every PR in this project)

- No business logic in `@Composable` functions — only in ViewModels or UseCases.
- No `GlobalScope`. Always `viewModelScope` or `lifecycleScope` or injected `CoroutineScope`.
- No `!!` operators.
- No hardcoded strings in UI — use string resources.
- No hardcoded colors or dimensions — use design tokens from ui-toolkit.
- Every new screen must have Compose UI tests covering all UiState branches + corner cases.
- Every new UseCase must have a unit test in `commonTest`.
- Every new ViewModel must have unit tests for every state transition.
- Every new ui-toolkit component must have Compose UI tests.
- Test tags defined in a constants object — never inline strings in test assertions.
- `shared/domain/` must have zero Android imports.
