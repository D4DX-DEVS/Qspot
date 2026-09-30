#!/usr/bin/env python3
import os
import re

# Define the import mappings (without lib/ prefix for relative imports)
IMPORT_MAPPINGS = {
    # Video module
    "models/video_model.dart": "screens/video/model/video_model.dart",
    "providers/video_provider.dart": "screens/video/provider/video_provider.dart",
    "screens/video_list_screen.dart": "screens/video/screens/video_list_screen.dart",
    "screens/video_player_screen.dart": "screens/video/screens/video_player_screen.dart",
    "widgets/video_card.dart": "screens/video/widgets/video_card.dart",
    "widgets/latest_video_card.dart": "screens/video/widgets/latest_video_card.dart",
    
    # Speaker module
    "models/speaker_model.dart": "screens/speaker/model/speaker_model.dart",
    "providers/speaker_provider.dart": "screens/speaker/provider/speaker_provider.dart",
    "screens/speaker_detail_screen.dart": "screens/speaker/screens/speaker_detail_screen.dart",
    "screens/speaker_list_screen.dart": "screens/speaker/screens/speaker_list_screen.dart",
    "widgets/speaker_card.dart": "screens/speaker/widgets/speaker_card.dart",
    
    # Subject module
    "models/subject_model.dart": "screens/subject/model/subject_model.dart",
    "providers/subject_provider.dart": "screens/subject/provider/subject_provider.dart",
    "screens/subject_list_screen.dart": "screens/subject/screens/subject_list_screen.dart",
    "screens/subject_videos_screen.dart": "screens/subject/screens/subject_videos_screen.dart",
    "widgets/subject_card.dart": "screens/subject/widgets/subject_card.dart",
    
    # Bookmark module
    "models/bookmark_model.dart": "screens/bookmark/model/bookmark_model.dart",
    "providers/bookmark_provider.dart": "screens/bookmark/provider/bookmark_provider.dart",
    "screens/bookmarks_screen.dart": "screens/bookmark/screens/bookmarks_screen.dart",
    "services/bookmark_service.dart": "screens/bookmark/service/bookmark_service.dart",
    
    # Banner module
    "models/banner_model.dart": "screens/banner/model/banner_model.dart",
    "providers/banner_provider.dart": "screens/banner/provider/banner_provider.dart",
    "widgets/banner_carousel.dart": "screens/banner/widgets/banner_carousel.dart",
    
    # Schedule module
    "models/schedule_model.dart": "screens/schedule/model/schedule_model.dart",
    "providers/schedule_provider.dart": "screens/schedule/provider/schedule_provider.dart",
    "screens/schedule_screen.dart": "screens/schedule/screens/schedule_screen.dart",
    "services/alarm_service.dart": "screens/schedule/service/alarm_service.dart",
    
    # Notification module
    "models/notification_model.dart": "screens/notification/model/notification_model.dart",
    "providers/notification_provider.dart": "screens/notification/provider/notification_provider.dart",
    "screens/notifications_screen.dart": "screens/notification/screens/notifications_screen.dart",
    "services/notification_service.dart": "screens/notification/service/notification_service.dart",
    
    # Auth module
    "models/user_model.dart": "screens/auth/model/user_model.dart",
    "providers/auth_provider.dart": "screens/auth/provider/auth_provider.dart",
    "screens/login_screen.dart": "screens/auth/screens/login_screen.dart",
    "screens/registration_screen.dart": "screens/auth/screens/registration_screen.dart",
    "services/auth_service.dart": "screens/auth/service/auth_service.dart",
    
    # Question module
    "models/question_model.dart": "screens/question/model/question_model.dart",
    "screens/ask_question_screen.dart": "screens/question/screens/ask_question_screen.dart",
    "screens/my_questions_screen.dart": "screens/question/screens/my_questions_screen.dart",
    
    # Quiz module (some already moved)
    "models/quiz_model.dart": "screens/quiz/model/quiz_model.dart",
    "models/student_model.dart": "screens/quiz/model/student_model.dart",
    "providers/quiz_provider.dart": "screens/quiz/provider/quiz_provider.dart",
    "screens/quiz_screen.dart": "screens/quiz/screens/quiz_screen.dart",
    "screens/quiz_question_screen.dart": "screens/quiz/screens/quiz_question_screen.dart",
    "screens/quiz_results_screen.dart": "screens/quiz/screens/quiz_results_screen.dart",
    "screens/quiz/student_form_screen.dart": "screens/quiz/screens/student_form_screen.dart",
    "services/database_helper.dart": "screens/quiz/service/database_helper.dart",
    "widgets/gender_card.dart": "screens/quiz/widgets/gender_card.dart",
    
    # Home and Settings
    "screens/home_screen.dart": "screens/home/screens/home_screen.dart",
    "screens/settings_screen.dart": "screens/settings/screens/settings_screen.dart",
    
    # Common screens
    "screens/splash_screen.dart": "screens/common/screens/splash_screen.dart",
    "screens/main_navigation_screen.dart": "screens/common/screens/main_navigation_screen.dart",
    "screens/contact_us_screen.dart": "screens/common/screens/contact_us_screen.dart",
    "screens/image_viewer_screen.dart": "screens/common/screens/image_viewer_screen.dart",
    
    # Common widgets
    "widgets/loading_skeleton.dart": "widgets/common/loading_skeleton.dart",
    "widgets/see_all_button.dart": "widgets/common/see_all_button.dart",
    
    # Common services
    "services/directus_service.dart": "services/common/directus_service.dart",
    "services/storage_service.dart": "services/common/storage_service.dart",
}

# Also handle package:qspot/ imports
PACKAGE_IMPORT_MAPPINGS = {
    f"package:qspot/{old}": f"package:qspot/{new}" 
    for old, new in IMPORT_MAPPINGS.items()
}

def update_imports_in_file(file_path):
    """Update imports in a single Dart file."""
    try:
        with open(file_path, 'r', encoding='utf-8') as f:
            content = f.read()
        
        original_content = content
        changes = []
        
        # Update relative imports
        for old_path, new_path in IMPORT_MAPPINGS.items():
            patterns = [
                (f"import '{old_path}'", f"import '{new_path}'"),
                (f'import "{old_path}"', f'import "{new_path}"'),
                (f"export '{old_path}'", f"export '{new_path}'"),
                (f'export "{old_path}"', f'export "{new_path}"'),
                (f"from '{old_path}'", f"from '{new_path}'"),
                (f'from "{old_path}"', f'from "{new_path}"'),
            ]
            
            for old, new in patterns:
                if old in content:
                    content = content.replace(old, new)
                    changes.append(f"{old} -> {new}")
        
        # Update package imports
        for old_path, new_path in PACKAGE_IMPORT_MAPPINGS.items():
            patterns = [
                (f"import '{old_path}'", f"import '{new_path}'"),
                (f'import "{old_path}"', f'import "{new_path}"'),
                (f"export '{old_path}'", f"export '{new_path}'"),
                (f'export "{old_path}"', f'export "{new_path}"'),
            ]
            
            for old, new in patterns:
                if old in content:
                    content = content.replace(old, new)
                    changes.append(f"{old} -> {new}")
        
        # Only write if content changed
        if content != original_content:
            with open(file_path, 'w', encoding='utf-8') as f:
                f.write(content)
            return True, changes
        return False, []
    except Exception as e:
        debugPrint(f"Error processing {file_path}: {e}")
        return False, []

def main():
    """Walk through all Dart files and update imports."""
    lib_dir = os.path.join(os.getcwd(), 'lib')
    updated_files = []
    
    for root, dirs, files in os.walk(lib_dir):
        for file in files:
            if file.endswith('.dart'):
                file_path = os.path.join(root, file)
                updated, changes = update_imports_in_file(file_path)
                if updated:
                    updated_files.append((file_path, len(changes)))
    
    debugPrint(f"\n✅ Updated imports in {len(updated_files)} files:")
    for file_path, change_count in updated_files:
        rel_path = os.path.relpath(file_path, lib_dir)
        debugPrint(f"  - {rel_path} ({change_count} changes)")
    
    debugPrint(f"\n🎉 Import update complete!")

if __name__ == "__main__":
    main()
