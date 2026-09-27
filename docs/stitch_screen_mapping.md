# Stitch Screen Mapping

## Mobile Screens (Flutter)
| Stitch Screen Title | Flutter Screen | Route | Feature | Firebase Dependencies | Status |
|---|---|---|---|---|---|
| StoryVerse Splash Screen | SplashScreen | /splash | Core | None | Not Started |
| StoryVerse Onboarding Screen | OnboardingScreen | /onboarding | Auth | None | Not Started |
| StoryVerse Login Screen | LoginScreen | /login | Auth | Auth | Not Started |
| StoryVerse Sign Up Screen | SignupScreen | /signup | Auth | Auth, Firestore (users) | Not Started |
| StoryVerse Forgot Password Screen | ForgotPasswordScreen | /forgot-password | Auth | Auth | Not Started |
| StoryVerse Home Screen | HomeScreen | /home | Home | Firestore (stories, episodes) | Not Started |
| StoryVerse Discover Screen | DiscoverScreen | /discover | Discover | Firestore (stories, genres, categories) | Not Started |
| StoryVerse Search Screen | SearchScreen | /search | Search | Firestore (stories) | Not Started |
| StoryVerse Story Details Screen | StoryDetailsScreen | /story/:id | Story | Firestore (stories) | Not Started |
| StoryVerse Episodes Screen | EpisodesScreen | /story/:id/episodes | Story | Firestore (episodes) | Not Started |
| StoryVerse Video Player Screen | VideoPlayerScreen | /player/:episodeId | Video | Storage (video), Firestore (watchHistory) | Not Started |
| StoryVerse Library Screen | LibraryScreen | /library | Library | Firestore (library, watchHistory, favorites) | Not Started |
| StoryVerse Notifications Screen | NotificationsScreen | /notifications | Notifications | Firestore (notifications), FCM | Not Started |
| StoryVerse Profile Screen | ProfileScreen | /profile | Profile | Firestore (users), Auth | Not Started |
| StoryVerse AI Hub Screen | AiHubScreen | /ai | AI | None | Not Started |
| StoryVerse AI Assistant Screen | AiAssistantScreen | /ai/assistant | AI | AI Service, Firestore (stories) | Not Started |
| StoryVerse AI Story Generator Screen | AiGeneratorScreen | /ai/generator | AI | AI Service | Not Started |
| StoryVerse AI Generated Story Result Screen | AiResultScreen | /ai/result | AI | AI Service, Firestore (aiGenerations) | Not Started |

## Admin Screens (React Web)
| Stitch Screen Title | React Component | Route | Feature | Firebase Dependencies | Status |
|---|---|---|---|---|---|
| StoryVerse Admin Login Web Screen | AdminLogin | /login | Auth | Auth | Not Started |
| StoryVerse Admin Dashboard Screen | AdminDashboard | / | Admin | Firestore (all) | Not Started |
| StoryVerse Admin Stories Management Screen | StoriesManagement | /stories | Admin | Firestore (stories) | Not Started |
| StoryVerse Admin Add/Edit Story Screen | EditStory | /stories/edit/:id | Admin | Firestore (stories) | Not Started |
| StoryVerse Admin Episode Management Screen | EpisodesManagement | /episodes | Admin | Firestore (episodes) | Not Started |
| StoryVerse Admin Users Management Screen | UsersManagement | /users | Admin | Firestore (users) | Not Started |
| StoryVerse Admin Moderation Screen | Moderation | /moderation | Admin | Firestore (comments, reports) | Not Started |
| StoryVerse Admin AI Content Review Screen | AiReview | /ai-review | Admin | Firestore (aiGenerations) | Not Started |
| StoryVerse Admin Analytics Screen | Analytics | /analytics | Admin | Firestore (analytics) | Not Started |
