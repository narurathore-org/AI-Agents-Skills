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
├── core-network/                       # Retrofit + OkHttp + Hilt wiring
│   └── src/main/kotlin/.../core/network/
│       ├── ApiService.kt              # Retrofit service interface
│       ├── NetworkResponse.kt         # Sealed result wrapper
│       ├── AuthInterceptor.kt         # OkHttp request interceptor
│       └── di/NetworkModule.kt        # Hilt: OkHttp, Retrofit, ApiService
├── core-analytics/                     # Firebase Analytics wrapper
│   └── src/main/kotlin/.../core/analytics/
│       ├── AnalyticsEvent.kt          # Sealed class of all trackable events
│       ├── AnalyticsTracker.kt        # Interface (injected into ViewModels)
│       ├── FirebaseAnalyticsTracker.kt
│       └── di/AnalyticsModule.kt
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

### 2. `:ui-toolkit` module (local, inside this project)

```
ui-toolkit/
├── build.gradle.kts
└── src/
    ├── main/kotlin/.../ui/toolkit/
    │   ├── tokens/                    # Design tokens
    │   │   ├── Color.kt
    │   │   ├── Typography.kt
    │   │   └── Spacing.kt
    │   ├── theme/
    │   │   └── AppTheme.kt
    │   └── components/                # One file per component
    │       ├── Button.kt
    │       ├── TextField.kt
    │       └── ...
    └── androidTest/kotlin/            # Compose UI tests for every component
```

---

## Inputs to resolve before starting

Ask if not provided:

- **Project name** — used for package name, repo name, module names.
- **Package name** — e.g. `com.example.myapp`.
- **Root directory** — where to create the project folders.
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
firebase-bom = "33.7.0"
google-services = "4.4.2"
retrofit = "2.11.0"
okhttp = "4.12.0"
moshi = "1.15.1"

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

firebase-bom = { group = "com.google.firebase", name = "firebase-bom", version.ref = "firebase-bom" }
firebase-analytics = { group = "com.google.firebase", name = "firebase-analytics" }

retrofit-core = { group = "com.squareup.retrofit2", name = "retrofit", version.ref = "retrofit" }
retrofit-moshi = { group = "com.squareup.retrofit2", name = "converter-moshi", version.ref = "retrofit" }
okhttp-bom = { group = "com.squareup.okhttp3", name = "okhttp-bom", version.ref = "okhttp" }
okhttp-core = { group = "com.squareup.okhttp3", name = "okhttp" }
okhttp-logging = { group = "com.squareup.okhttp3", name = "logging-interceptor" }
moshi-core = { group = "com.squareup.moshi", name = "moshi", version.ref = "moshi" }
moshi-kotlin = { group = "com.squareup.moshi", name = "moshi-kotlin", version.ref = "moshi" }
moshi-codegen = { group = "com.squareup.moshi", name = "moshi-kotlin-codegen", version.ref = "moshi" }

[plugins]
android-application = { id = "com.android.application", version.ref = "agp" }
android-library = { id = "com.android.library", version.ref = "agp" }
kotlin-android = { id = "org.jetbrains.kotlin.android", version.ref = "kotlin" }
kotlin-multiplatform = { id = "org.jetbrains.kotlin.multiplatform", version.ref = "kotlin" }
kotlin-serialization = { id = "org.jetbrains.kotlin.plugin.serialization", version.ref = "kotlin" }
hilt = { id = "com.google.dagger.hilt.android", version.ref = "hilt" }
ksp = { id = "com.google.devtools.ksp", version = "2.1.0-1.0.29" }
compose-compiler = { id = "org.jetbrains.kotlin.plugin.compose", version.ref = "kotlin" }
google-services = { id = "com.google.gms.google-services", version.ref = "google-services" }
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

### Step 5 — Scaffold the `:ui-toolkit` local module

Create `ui-toolkit/` as a local Android library module **inside the project**. Add it to
`settings.gradle.kts` — no separate repo, no publishing, no GitHub Packages.

```kotlin
// settings.gradle.kts  (add to the include list)
include(":ui-toolkit")
```

```kotlin
// ui-toolkit/build.gradle.kts
plugins {
    alias(libs.plugins.android.library)
    alias(libs.plugins.kotlin.android)
    alias(libs.plugins.compose.compiler)
}

android {
    namespace = "<package>.ui.toolkit"
    compileSdk = libs.versions.compileSdk.get().toInt()
    defaultConfig { minSdk = libs.versions.minSdk.get().toInt() }
}

dependencies {
    implementation(platform(libs.compose.bom))
    implementation(libs.compose.ui)
    implementation(libs.compose.ui.tooling.preview)
    implementation(libs.compose.material3)
    debugImplementation(libs.compose.ui.tooling)
    androidTestImplementation(platform(libs.compose.bom))
    androidTestImplementation(libs.compose.ui.test.junit4)
    debugImplementation(libs.compose.ui.test.manifest)
}
```

Feature modules consume it as a local project dependency:

```kotlin
// feature/<name>/build.gradle.kts
dependencies {
    implementation(project(":ui-toolkit"))
}
```

**Component rules:**
- One file per component under `ui-toolkit/src/main/kotlin/.../components/`.
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

### Step 7 — Network layer (Retrofit + OkHttp + Hilt)

#### 7.1 — Scaffold `:core-network`

Add to `settings.gradle.kts`:

```kotlin
include(":core-network")
```

**`core-network/build.gradle.kts`:**

```kotlin
plugins {
    alias(libs.plugins.android.library)
    alias(libs.plugins.kotlin.android)
    alias(libs.plugins.hilt)
    alias(libs.plugins.ksp)
}

android {
    namespace = "<package>.core.network"
    compileSdk = libs.versions.compileSdk.get().toInt()
    defaultConfig { minSdk = libs.versions.minSdk.get().toInt() }
    buildTypes {
        release { isMinifyEnabled = false }
    }
}

dependencies {
    implementation(libs.hilt.android)
    ksp(libs.hilt.compiler)
    implementation(platform(libs.okhttp.bom))
    implementation(libs.okhttp.core)
    implementation(libs.okhttp.logging)
    implementation(libs.retrofit.core)
    implementation(libs.retrofit.moshi)
    implementation(libs.moshi.kotlin)
    ksp(libs.moshi.codegen)
    testImplementation(libs.junit5.api)
    testImplementation(libs.mockk)
}
```

Feature modules consume it as:

```kotlin
// feature/<name>/build.gradle.kts
dependencies {
    implementation(project(":core-network"))
}
```

#### 7.2 — Network response wrapper

**`NetworkResponse.kt`** — sealed class that wraps every API result:

```kotlin
sealed class NetworkResponse<out T> {
    data class Success<T>(val data: T) : NetworkResponse<T>()
    data class Error(
        val code: Int,
        val message: String,
    ) : NetworkResponse<Nothing>()
    data class Exception(val throwable: Throwable) : NetworkResponse<Nothing>()
}

suspend fun <T> safeApiCall(call: suspend () -> T): NetworkResponse<T> = try {
    NetworkResponse.Success(call())
} catch (e: HttpException) {
    NetworkResponse.Error(e.code(), e.message())
} catch (e: Throwable) {
    NetworkResponse.Exception(e)
}
```

#### 7.3 — Auth interceptor

**`AuthInterceptor.kt`** — adds `Authorization` header to every request:

```kotlin
class AuthInterceptor @Inject constructor(
    private val tokenProvider: TokenProvider,   // injected via Hilt
) : Interceptor {

    override fun intercept(chain: Interceptor.Chain): Response {
        val request = chain.request().newBuilder()
            .addHeader("Authorization", "Bearer ${tokenProvider.getToken()}")
            .build()
        return chain.proceed(request)
    }
}

interface TokenProvider {
    fun getToken(): String
}
```

#### 7.4 — Retrofit API service

**`ApiService.kt`** — every endpoint is a `suspend` function:

```kotlin
interface ApiService {

    @GET("v1/items")
    suspend fun getItems(): List<ItemDto>

    @GET("v1/items/{id}")
    suspend fun getItem(@Path("id") id: String): ItemDto

    @POST("v1/items")
    suspend fun createItem(@Body request: CreateItemRequest): ItemDto

    @PUT("v1/items/{id}")
    suspend fun updateItem(
        @Path("id") id: String,
        @Body request: UpdateItemRequest,
    ): ItemDto

    @DELETE("v1/items/{id}")
    suspend fun deleteItem(@Path("id") id: String): Response<Unit>
}
```

Use `@JsonClass(generateAdapter = true)` on every DTO:

```kotlin
@JsonClass(generateAdapter = true)
data class ItemDto(
    @Json(name = "id") val id: String,
    @Json(name = "name") val name: String,
    @Json(name = "created_at") val createdAt: String,
)
```

#### 7.5 — Hilt NetworkModule

**`di/NetworkModule.kt`:**

```kotlin
@Module
@InstallIn(SingletonComponent::class)
object NetworkModule {

    @Provides
    @Singleton
    fun provideOkHttpClient(
        authInterceptor: AuthInterceptor,
    ): OkHttpClient = OkHttpClient.Builder()
        .addInterceptor(authInterceptor)
        .addInterceptor(
            HttpLoggingInterceptor().apply {
                level = if (BuildConfig.DEBUG)
                    HttpLoggingInterceptor.Level.BODY
                else
                    HttpLoggingInterceptor.Level.NONE
            }
        )
        .connectTimeout(30, TimeUnit.SECONDS)
        .readTimeout(30, TimeUnit.SECONDS)
        .writeTimeout(30, TimeUnit.SECONDS)
        .build()

    @Provides
    @Singleton
    fun provideMoshi(): Moshi = Moshi.Builder()
        .addLast(KotlinJsonAdapterFactory())
        .build()

    @Provides
    @Singleton
    fun provideRetrofit(
        okHttpClient: OkHttpClient,
        moshi: Moshi,
    ): Retrofit = Retrofit.Builder()
        .baseUrl(BuildConfig.BASE_URL)
        .client(okHttpClient)
        .addConverterFactory(MoshiConverterFactory.create(moshi))
        .build()

    @Provides
    @Singleton
    fun provideApiService(retrofit: Retrofit): ApiService =
        retrofit.create(ApiService::class.java)
}
```

Add `BASE_URL` to `app/build.gradle.kts`:

```kotlin
android {
    defaultConfig {
        buildConfigField("String", "BASE_URL", "\"https://api.example.com/\"")
    }
    buildFeatures { buildConfig = true }
}
```

#### 7.6 — Repository implementation

Repository implementations in `shared/data/` call `safeApiCall` and map DTOs to domain models:

```kotlin
class ItemRepositoryImpl @Inject constructor(
    private val apiService: ApiService,
    @IoDispatcher private val ioDispatcher: CoroutineDispatcher,
) : ItemRepository {

    override suspend fun getItems(): Result<List<Item>> =
        withContext(ioDispatcher) {
            when (val response = safeApiCall { apiService.getItems() }) {
                is NetworkResponse.Success  -> Result.success(response.data.map { it.toDomain() })
                is NetworkResponse.Error    -> Result.failure(ApiException(response.code, response.message))
                is NetworkResponse.Exception -> Result.failure(response.throwable)
            }
        }
}

// Bind in AppModule:
@Binds @Singleton
abstract fun bindItemRepository(impl: ItemRepositoryImpl): ItemRepository
```

#### 7.7 — Testing pattern

Mock `ApiService` directly — no HTTP server needed:

```kotlin
class ItemRepositoryTest {

    private val apiService: ApiService = mockk()
    private val repository = ItemRepositoryImpl(apiService, UnconfinedTestDispatcher())

    @Test
    fun `getItems returns Success when api call succeeds`() = runTest {
        val dtos = listOf(ItemDto("1", "Test", "2025-01-01"))
        coEvery { apiService.getItems() } returns dtos

        val result = repository.getItems()

        assertThat(result.isSuccess).isTrue()
        assertThat(result.getOrNull()).hasSize(1)
    }

    @Test
    fun `getItems returns Failure when api throws`() = runTest {
        coEvery { apiService.getItems() } throws IOException("no network")

        val result = repository.getItems()

        assertThat(result.isFailure).isTrue()
    }
}
```

---

### Step 8 — Analytics integration (Google Firebase Analytics)

#### 8.1 — Prerequisites

1. Create a Firebase project at [console.firebase.google.com](https://console.firebase.google.com).
2. Register the Android app using the `applicationId` from `app/build.gradle.kts`.
3. Download `google-services.json` and place it at `app/google-services.json`.
   > `google-services.json` contains no secrets — it is safe to commit.

#### 8.2 — Apply the Google Services plugin

`app/build.gradle.kts`:

```kotlin
plugins {
    alias(libs.plugins.android.application)
    alias(libs.plugins.kotlin.android)
    alias(libs.plugins.hilt)
    alias(libs.plugins.ksp)
    alias(libs.plugins.compose.compiler)
    alias(libs.plugins.google.services)    // ← add
}
```

#### 8.3 — Scaffold `:core-analytics`

Add to `settings.gradle.kts`:

```kotlin
include(":core-analytics")
```

**`core-analytics/build.gradle.kts`:**

```kotlin
plugins {
    alias(libs.plugins.android.library)
    alias(libs.plugins.kotlin.android)
    alias(libs.plugins.hilt)
    alias(libs.plugins.ksp)
}

android {
    namespace = "<package>.core.analytics"
    compileSdk = libs.versions.compileSdk.get().toInt()
    defaultConfig { minSdk = libs.versions.minSdk.get().toInt() }
}

dependencies {
    implementation(libs.hilt.android)
    ksp(libs.hilt.compiler)
    implementation(platform(libs.firebase.bom))
    implementation(libs.firebase.analytics)
}
```

#### 8.4 — Analytics domain model

**`AnalyticsEvent.kt`** — sealed class; every trackable event is a subtype:

```kotlin
sealed class AnalyticsEvent {
    abstract val name: String
    abstract val params: Map<String, Any>

    data class ScreenView(
        val screenName: String,
        val screenClass: String,
    ) : AnalyticsEvent() {
        override val name = "screen_view"
        override val params = mapOf(
            "screen_name" to screenName,
            "screen_class" to screenClass,
        )
    }

    data class ButtonClick(
        val buttonName: String,
        val screenName: String,
    ) : AnalyticsEvent() {
        override val name = "button_click"
        override val params = mapOf(
            "button_name" to buttonName,
            "screen_name" to screenName,
        )
    }

    data class ErrorShown(
        val errorType: String,
        val screenName: String,
        val message: String = "",
    ) : AnalyticsEvent() {
        override val name = "error_shown"
        override val params = mapOf(
            "error_type" to errorType,
            "screen_name" to screenName,
            "message" to message,
        )
    }
}
```

**`AnalyticsTracker.kt`** — interface injected into ViewModels for testability:

```kotlin
interface AnalyticsTracker {
    fun track(event: AnalyticsEvent)
    fun setUserId(userId: String?)
    fun setUserProperty(key: String, value: String?)
}
```

#### 8.5 — Firebase implementation

**`FirebaseAnalyticsTracker.kt`:**

```kotlin
class FirebaseAnalyticsTracker @Inject constructor(
    private val firebaseAnalytics: FirebaseAnalytics,
) : AnalyticsTracker {

    override fun track(event: AnalyticsEvent) {
        val bundle = Bundle().apply {
            event.params.forEach { (key, value) ->
                when (value) {
                    is String  -> putString(key, value)
                    is Long    -> putLong(key, value)
                    is Double  -> putDouble(key, value)
                    is Int     -> putInt(key, value)
                    is Boolean -> putBoolean(key, value)
                }
            }
        }
        firebaseAnalytics.logEvent(event.name, bundle)
    }

    override fun setUserId(userId: String?) {
        firebaseAnalytics.setUserId(userId)
    }

    override fun setUserProperty(key: String, value: String?) {
        firebaseAnalytics.setUserProperty(key, value)
    }
}
```

#### 8.6 — Hilt module

**`di/AnalyticsModule.kt`:**

```kotlin
@Module
@InstallIn(SingletonComponent::class)
object AnalyticsModule {

    @Provides
    @Singleton
    fun provideFirebaseAnalytics(
        @ApplicationContext context: Context,
    ): FirebaseAnalytics = FirebaseAnalytics.getInstance(context)

    @Provides
    @Singleton
    fun provideAnalyticsTracker(
        impl: FirebaseAnalyticsTracker,
    ): AnalyticsTracker = impl
}
```

#### 8.7 — Usage in a ViewModel

Add `:core-analytics` as a dependency in any feature module, then inject:

```kotlin
// feature/<name>/build.gradle.kts
dependencies {
    implementation(project(":core-analytics"))
}
```

```kotlin
@HiltViewModel
class <Name>ViewModel @Inject constructor(
    private val get<Name>UseCase: Get<Name>UseCase,
    private val analytics: AnalyticsTracker,
    private val ioDispatcher: CoroutineDispatcher = Dispatchers.IO,
) : ViewModel() {

    init {
        analytics.track(
            AnalyticsEvent.ScreenView(
                screenName = "<FeatureName>",
                screenClass = "<Name>ViewModel",
            )
        )
        load()
    }

    fun onRetryClicked() {
        analytics.track(
            AnalyticsEvent.ButtonClick(
                buttonName = "retry",
                screenName = "<FeatureName>",
            )
        )
        load()
    }
}
```

#### 8.8 — Testing pattern

Use `mockk(relaxed = true)` — no Firebase SDK needed in unit tests:

```kotlin
@ExtendWith(CoroutineTestExtension::class)
class <Name>ViewModelTest {

    private val get<Name>UseCase: Get<Name>UseCase = mockk()
    private val analytics: AnalyticsTracker = mockk(relaxed = true)

    @Test
    fun `tracks screen_view on init`() = runTest {
        coEvery { get<Name>UseCase() } returns Result.success(emptyList())
        <Name>ViewModel(get<Name>UseCase, analytics, UnconfinedTestDispatcher())

        verify {
            analytics.track(match {
                it is AnalyticsEvent.ScreenView && it.screenName == "<FeatureName>"
            })
        }
    }

    @Test
    fun `tracks button_click when retry pressed`() = runTest {
        coEvery { get<Name>UseCase() } returns Result.failure(Exception("error"))
        val viewModel = <Name>ViewModel(get<Name>UseCase, analytics, UnconfinedTestDispatcher())

        viewModel.onRetryClicked()

        verify {
            analytics.track(match {
                it is AnalyticsEvent.ButtonClick && it.buttonName == "retry"
            })
        }
    }
}
```

---

### Step 9 — Non-negotiables (apply to every PR in this project)

- No business logic in `@Composable` functions — only in ViewModels or UseCases.
- No `GlobalScope`. Always `viewModelScope` or `lifecycleScope` or injected `CoroutineScope`.
- No `!!` operators.
- No hardcoded strings in UI — use string resources.
- No hardcoded colors or dimensions — use design tokens from `:ui-toolkit`.
- Every new screen must have Compose UI tests covering all UiState branches + corner cases.
- Every new UseCase must have a unit test in `commonTest`.
- Every new ViewModel must have unit tests for every state transition.
- Every new `:ui-toolkit` component must have Compose UI tests.
- Test tags defined in a constants object — never inline strings in test assertions.
- `shared/domain/` must have zero Android imports.
- All API calls must go through `ApiService` — never use `OkHttpClient` directly in business code.
- Always wrap API calls with `safeApiCall { }` — never let exceptions propagate uncaught.
- Every DTO must be annotated with `@JsonClass(generateAdapter = true)`.
- Never put `BASE_URL` in source code — always use `BuildConfig.BASE_URL`.
- Logging interceptor must be `Level.NONE` in release builds.
- Every screen view must fire `AnalyticsEvent.ScreenView` on ViewModel init.
- Every user action (button tap, form submit, retry) must fire an `AnalyticsEvent`.
- Never call `FirebaseAnalytics` directly from ViewModels or Composables — always inject `AnalyticsTracker`.
- Never hardcode event names as raw strings — always add a new subtype to `AnalyticsEvent`.
- Every ViewModel test must verify analytics calls using `mockk(relaxed = true)`.

---

### Step 10 — Write CLAUDE.md at the project root

Create `CLAUDE.md` at the project root. This file is auto-loaded by Claude Code
in every session, ensuring all agents follow the same architecture without being
told explicitly.

```markdown
# CLAUDE.md

## Architecture
Clean layered architecture with MVVM, Jetpack Compose, Kotlin Multiplatform.

### Modules
- `shared/` — KMP. All business logic. Zero Android imports in `domain/`.
- `feature/<name>/` — One module per feature. Compose UI + ViewModel only.
- `app/` — DI wiring, navigation host, entry point only.
- `:ui-toolkit` — local design system module. Never a separate dependency.
- `:core-network` — Retrofit + OkHttp client, `ApiService`, `NetworkResponse` wrapper, Hilt bindings.
- `:core-analytics` — Google Firebase Analytics wrapper. All event tracking goes through `AnalyticsTracker`.

### Layer rules
- `domain/` — Pure Kotlin. Repository interfaces only. No implementations.
- `data/` — Implements domain interfaces. Ktor, SQLDelight, etc.
- `ui/` — Compose + ViewModel. No business logic in @Composable functions.
- `data/` must NOT be imported by `app/` directly — only through DI bindings.

## Non-negotiables
- No business logic in `@Composable` functions.
- No `GlobalScope` — use `viewModelScope`, `lifecycleScope`, or injected scope.
- No `!!` operators.
- No hardcoded strings — use string resources.
- No hardcoded colors or dimensions — use design tokens from `:ui-toolkit`.
- `shared/domain/` must have zero Android imports.
- Never call `FirebaseAnalytics` directly — always inject `AnalyticsTracker`.
- Never hardcode analytics event names — always use `AnalyticsEvent` subtypes.

## Network
- All API calls go through `ApiService` (Retrofit interface injected via Hilt).
- Wrap every call with `safeApiCall { }` — never let exceptions escape unchecked.
- DTOs use `@JsonClass(generateAdapter = true)` + `@Json(name = ...)` for field mapping.
- `BASE_URL` comes from `BuildConfig` — never hardcoded.
- `HttpLoggingInterceptor` is `Level.NONE` in release builds.

## Analytics
- Every screen view fires `AnalyticsEvent.ScreenView` in ViewModel init.
- Every user action fires the appropriate `AnalyticsEvent` subtype.
- New events = new subtype in `core-analytics/AnalyticsEvent.kt`.
- Unit tests mock `AnalyticsTracker` with `mockk(relaxed = true)`.

## Testing requirements
- Every screen: Compose UI tests for all UiState branches + corner cases.
- Every ViewModel: unit tests for every state transition.
- Every UseCase: unit test in `commonTest`.
- Every `:ui-toolkit` component: Compose UI test.
- Test tags in constants objects — never inline strings in tests.
- Use Turbine for Flow testing, MockK for mocking, coroutines-test for dispatchers.

## Progress & planning
- See `Progress.md` for current work status.
- See `plan/index.md` for all feature and bug plans.
- See `specs/` for feature specs (SDD).

## Spec-Driven Development
Before implementing any feature, write a spec in `specs/features/<slug>/spec.md`.
Use `specs/template.md` as the base. Get spec approved before writing code.
```

---

### Step 11 — Create Progress.md

Create `Progress.md` at the project root:

```markdown
# Progress

## Current session
- **Date:**
- **Focus:**
- **Branch:**

## In progress
<!-- What is actively being worked on -->
-

## Completed
<!-- Finished tasks — add date -->
-

## Blocked
<!-- What is blocked and why -->
-

## Up next
<!-- Next tasks to pick up in the next session -->
-
```

---

### Step 12 — Create plan/ structure

```
plan/
  index.md
  generic.md
  features/
    .gitkeep
  bugs/
    .gitkeep
```

**`plan/index.md`:**
```markdown
# Plan Index

| Type | Name | Status | Plan file |
|------|------|--------|-----------|
| — | — | — | — |

## Status legend
- `draft` — plan written, not started
- `in-progress` — actively being implemented
- `blocked` — waiting on something
- `done` — shipped
```

**`plan/generic.md`** (reusable template for any task):
```markdown
# Plan: <title>

## Goal
One sentence describing what this achieves.

## Context
Why we are doing this. Links to spec, Jira ticket, or design.

## Phases overview
1. Phase 1 — <outcome>
2. Phase 2 — <outcome>

## Phase 1 — <title>
**Goal:** <one sentence>
**Files:**
- add: `path/to/file.kt` — purpose
- edit: `path/to/file.kt` — what changes

**Tests:**
- `path/to/Test.kt` — what it asserts [unit | compose-ui]

**Commits:**
1. `test(scope): add failing tests for X`
2. `feat(scope): implement X`

**Definition of done:** <observable outcome>

---
_Copy Phase 1 block for each additional phase._
```

---

### Step 13 — Create specs/ structure

```
specs/
  README.md
  template.md
  features/
    .gitkeep
  bugs/
    .gitkeep
```

**`specs/README.md`:**
```markdown
# Specs

Spec-Driven Development (SDD) for this project.

## Workflow
1. Create a spec before writing any code.
2. Use `template.md` as the base.
3. Place feature specs in `features/<slug>/spec.md`.
4. Place bug specs (when the fix is complex) in `bugs/<ticket-id>/spec.md`.
5. Get spec reviewed/approved before implementation starts.
6. Keep the spec updated if scope changes mid-implementation.

## Spec → Plan → Code
Every spec links to a plan in `plan/`. Every plan phase traces back to
acceptance criteria in the spec. Tests must cover every acceptance criterion.
```

**`specs/template.md`:**
```markdown
# Spec: <Feature name>

**Date:** YYYY-MM-DD
**Status:** draft | approved | in-progress | done
**Plan:** [plan/features/<slug>.md](../plan/features/<slug>.md)

---

## Overview
One paragraph: what problem this solves and what the outcome looks like.

## User stories
- As a <user>, I want <action> so that <value>.

## Acceptance criteria
- AC-1: Given <context>, when <action>, then <outcome>.
- AC-2:
- AC-3:

## Non-goals
What this spec explicitly does NOT cover.

## UX notes
Screen list, key states, copy decisions. Link to Figma if available.

## Data model & API contract
Key data classes, API endpoints, request/response shape, error codes.

## Edge cases & error states
| Scenario | Expected behaviour |
|----------|--------------------|
| Network error | Show error state with retry |
| Empty response | Show empty state |

## Open questions
- [ ] Question — owner
```
