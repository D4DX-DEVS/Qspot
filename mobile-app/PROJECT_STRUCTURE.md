# QSpot Project Structure Documentation

## 📁 New Modular Architecture

The project has been reorganized into a feature-based modular architecture where each feature/module has its own folder containing all related files.

## 🎯 Structure Pattern

Each module follows this structure:
```
module_name/
  ├── model/          # Data models
  ├── provider/       # State management providers
  ├── screens/        # UI screens
  ├── widgets/        # Module-specific widgets (optional)
  └── service/        # Module-specific services (optional)
```

## 📂 Complete Folder Structure

```
lib/
├── main.dart
├── themes/
│   └── app_theme.dart
├── utils/
│   └── api_urls.dart
├── widgets/
│   └── common/
│       ├── loading_skeleton.dart
│       └── see_all_button.dart
├── services/
│   └── common/
│       ├── directus_service.dart
│       └── storage_service.dart
└── screens/
    ├── video/
    │   ├── model/
    │   │   └── video_model.dart
    │   ├── provider/
    │   │   └── video_provider.dart
    │   ├── screens/
    │   │   ├── video_list_screen.dart
    │   │   └── video_player_screen.dart
    │   ├── widgets/
    │   │   ├── latest_video_card.dart
    │   │   └── video_card.dart
    │   └── service/
    │
    ├── speaker/
    │   ├── model/
    │   │   └── speaker_model.dart
    │   ├── provider/
    │   │   └── speaker_provider.dart
    │   ├── screens/
    │   │   ├── speaker_detail_screen.dart
    │   │   └── speaker_list_screen.dart
    │   └── widgets/
    │       └── speaker_card.dart
    │
    ├── subject/
    │   ├── model/
    │   │   └── subject_model.dart
    │   ├── provider/
    │   │   └── subject_provider.dart
    │   ├── screens/
    │   │   ├── subject_list_screen.dart
    │   │   └── subject_videos_screen.dart
    │   └── widgets/
    │       └── subject_card.dart
    │
    ├── bookmark/
    │   ├── model/
    │   │   └── bookmark_model.dart
    │   ├── provider/
    │   │   └── bookmark_provider.dart
    │   ├── screens/
    │   │   └── bookmarks_screen.dart
    │   └── service/
    │       └── bookmark_service.dart
    │
    ├── banner/
    │   ├── model/
    │   │   └── banner_model.dart
    │   ├── provider/
    │   │   └── banner_provider.dart
    │   └── widgets/
    │       └── banner_carousel.dart
    │
    ├── schedule/
    │   ├── model/
    │   │   └── schedule_model.dart
    │   ├── provider/
    │   │   └── schedule_provider.dart
    │   ├── screens/
    │   │   └── schedule_screen.dart
    │   └── service/
    │       └── alarm_service.dart
    │
    ├── notification/
    │   ├── model/
    │   │   └── notification_model.dart
    │   ├── provider/
    │   │   └── notification_provider.dart
    │   ├── screens/
    │   │   └── notifications_screen.dart
    │   └── service/
    │       └── notification_service.dart
    │
    ├── auth/
    │   ├── model/
    │   │   └── user_model.dart
    │   ├── provider/
    │   │   └── auth_provider.dart
    │   ├── screens/
    │   │   ├── login_screen.dart
    │   │   └── registration_screen.dart
    │   └── service/
    │       └── auth_service.dart
    │
    ├── question/
    │   ├── model/
    │   │   └── question_model.dart
    │   └── screens/
    │       ├── ask_question_screen.dart
    │       └── my_questions_screen.dart
    │
    ├── quiz/
    │   ├── model/
    │   │   ├── quiz_model.dart
    │   │   └── student_model.dart
    │   ├── provider/
    │   │   └── quiz_provider.dart
    │   ├── screens/
    │   │   ├── quiz_screen.dart
    │   │   ├── quiz_question_screen.dart
    │   │   ├── quiz_results_screen.dart
    │   │   └── student_form_screen.dart
    │   ├── widgets/
    │   │   └── gender_card.dart
    │   └── service/
    │       └── database_helper.dart
    │
    ├── home/
    │   └── screens/
    │       └── home_screen.dart
    │
    ├── settings/
    │   └── screens/
    │       └── settings_screen.dart
    │
    └── common/
        └── screens/
            ├── splash_screen.dart
            ├── main_navigation_screen.dart
            ├── contact_us_screen.dart
            └── image_viewer_screen.dart
```

## 🎨 Benefits of This Structure

### 1. **Modularity**
- Each feature is self-contained
- Easy to locate all files related to a specific feature
- Clear separation of concerns

### 2. **Scalability**
- Easy to add new modules
- Simple to remove features without affecting others
- Team members can work on different modules independently

### 3. **Maintainability**
- Related files are grouped together
- Easier to understand the codebase structure
- Reduces cognitive load when working on a specific feature

### 4. **Reusability**
- Shared components are in `widgets/common/`
- Shared services are in `services/common/`
- Easy to identify what's module-specific vs. shared

## 📝 Import Guidelines

### Within the same module:
```dart
// Use relative paths
import '../model/video_model.dart';
import '../provider/video_provider.dart';
```

### Across modules:
```dart
// Use relative paths from lib/
import '../../speaker/model/speaker_model.dart';
import '../../bookmark/provider/bookmark_provider.dart';
```

### Shared resources:
```dart
// Themes
import '../../../themes/app_theme.dart';

// Utils
import '../../../utils/api_urls.dart';

// Common widgets
import '../../../widgets/common/loading_skeleton.dart';

// Common services
import '../../../services/common/storage_service.dart';
```

## 🚀 Adding a New Module

To add a new module, follow these steps:

1. **Create the module structure:**
```bash
mkdir -p lib/screens/new_module/{model,provider,screens,widgets,service}
```

2. **Create your files:**
   - `model/new_model.dart` - Data models
   - `provider/new_provider.dart` - State management
   - `screens/new_screen.dart` - UI screens
   - `widgets/new_widget.dart` - Module-specific widgets (optional)
   - `service/new_service.dart` - Business logic (optional)

3. **Register provider in `main.dart`:**
```dart
ChangeNotifierProvider(create: (_) => NewProvider()),
```

4. **Add navigation if needed**

## 🔧 Migration Complete

All files have been successfully migrated to the new structure with:
- ✅ 41 files updated with correct imports
- ✅ 17 shared resource imports fixed
- ✅ 0 errors in flutter analyze
- ✅ All modules properly organized

## 📌 Key Modules

| Module | Purpose |
|--------|---------|
| **video** | Video playback and management |
| **speaker** | Speaker profiles and information |
| **subject** | Subject categorization |
| **bookmark** | Saved videos/content |
| **banner** | Banner/carousel display |
| **schedule** | Schedule and alarm management |
| **notification** | Push notifications |
| **auth** | User authentication |
| **question** | Q&A functionality |
| **quiz** | Quiz/assessment module |
| **home** | Main dashboard |
| **settings** | App settings |
| **common** | Shared screens (splash, navigation, etc.) |

## 🎯 Best Practices

1. **Keep modules independent** - Minimize cross-module dependencies
2. **Use providers for state** - Centralized state management
3. **Shared widgets in common/** - Reusable components
4. **Consistent naming** - Follow the naming pattern for all files
5. **Document changes** - Update this file when adding new modules

---

**Last Updated:** November 15, 2024  
**Structure Version:** 2.0  
**Migration Status:** ✅ Complete

