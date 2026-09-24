#!/usr/bin/env python3
import os
import re
from pathlib import Path

# Map old file locations to new locations
FILE_LOCATIONS = {
    # Video module
    "video_model.dart": "screens/video/model/video_model.dart",
    "video_provider.dart": "screens/video/provider/video_provider.dart",
    "video_list_screen.dart": "screens/video/screens/video_list_screen.dart",
    "video_player_screen.dart": "screens/video/screens/video_player_screen.dart",
    "video_card.dart": "screens/video/widgets/video_card.dart",
    "latest_video_card.dart": "screens/video/widgets/latest_video_card.dart",
    
    # Speaker module
    "speaker_model.dart": "screens/speaker/model/speaker_model.dart",
    "speaker_provider.dart": "screens/speaker/provider/speaker_provider.dart",
    "speaker_detail_screen.dart": "screens/speaker/screens/speaker_detail_screen.dart",
    "speaker_list_screen.dart": "screens/speaker/screens/speaker_list_screen.dart",
    "speaker_card.dart": "screens/speaker/widgets/speaker_card.dart",
    
    # Subject module
    "subject_model.dart": "screens/subject/model/subject_model.dart",
    "subject_provider.dart": "screens/subject/provider/subject_provider.dart",
    "subject_list_screen.dart": "screens/subject/screens/subject_list_screen.dart",
    "subject_videos_screen.dart": "screens/subject/screens/subject_videos_screen.dart",
    "subject_card.dart": "screens/subject/widgets/subject_card.dart",
    
    # Bookmark module
    "bookmark_model.dart": "screens/bookmark/model/bookmark_model.dart",
    "bookmark_provider.dart": "screens/bookmark/provider/bookmark_provider.dart",
    "bookmarks_screen.dart": "screens/bookmark/screens/bookmarks_screen.dart",
    "bookmark_service.dart": "screens/bookmark/service/bookmark_service.dart",
    
    # Banner module
    "banner_model.dart": "screens/banner/model/banner_model.dart",
    "banner_provider.dart": "screens/banner/provider/banner_provider.dart",
    "banner_carousel.dart": "screens/banner/widgets/banner_carousel.dart",
    
    # Schedule module
    "schedule_model.dart": "screens/schedule/model/schedule_model.dart",
    "schedule_provider.dart": "screens/schedule/provider/schedule_provider.dart",
    "schedule_screen.dart": "screens/schedule/screens/schedule_screen.dart",
    "alarm_service.dart": "screens/schedule/service/alarm_service.dart",
    
    # Notification module
    "notification_model.dart": "screens/notification/model/notification_model.dart",
    "notification_provider.dart": "screens/notification/provider/notification_provider.dart",
    "notifications_screen.dart": "screens/notification/screens/notifications_screen.dart",
    "notification_service.dart": "screens/notification/service/notification_service.dart",
    
    # Auth module
    "user_model.dart": "screens/auth/model/user_model.dart",
    "auth_provider.dart": "screens/auth/provider/auth_provider.dart",
    "login_screen.dart": "screens/auth/screens/login_screen.dart",
    "registration_screen.dart": "screens/auth/screens/registration_screen.dart",
    "auth_service.dart": "screens/auth/service/auth_service.dart",
    
    # Question module
    "question_model.dart": "screens/question/model/question_model.dart",
    "ask_question_screen.dart": "screens/question/screens/ask_question_screen.dart",
    "my_questions_screen.dart": "screens/question/screens/my_questions_screen.dart",
    
    # Quiz module
    "quiz_model.dart": "screens/quiz/model/quiz_model.dart",
    "student_model.dart": "screens/quiz/model/student_model.dart",
    "quiz_provider.dart": "screens/quiz/provider/quiz_provider.dart",
    "quiz_screen.dart": "screens/quiz/screens/quiz_screen.dart",
    "quiz_question_screen.dart": "screens/quiz/screens/quiz_question_screen.dart",
    "quiz_results_screen.dart": "screens/quiz/screens/quiz_results_screen.dart",
    "student_form_screen.dart": "screens/quiz/screens/student_form_screen.dart",
    "database_helper.dart": "screens/quiz/service/database_helper.dart",
    "gender_card.dart": "screens/quiz/widgets/gender_card.dart",
    
    # Home and Settings
    "home_screen.dart": "screens/home/screens/home_screen.dart",
    "settings_screen.dart": "screens/settings/screens/settings_screen.dart",
    
    # Common screens
    "splash_screen.dart": "screens/common/screens/splash_screen.dart",
    "main_navigation_screen.dart": "screens/common/screens/main_navigation_screen.dart",
    "contact_us_screen.dart": "screens/common/screens/contact_us_screen.dart",
    "image_viewer_screen.dart": "screens/common/screens/image_viewer_screen.dart",
    
    # Common widgets
    "loading_skeleton.dart": "widgets/common/loading_skeleton.dart",
    "see_all_button.dart": "widgets/common/see_all_button.dart",
    
    # Common services
    "directus_service.dart": "services/common/directus_service.dart",
    "storage_service.dart": "services/common/storage_service.dart",
}

def calculate_relative_path(from_file, to_file):
    """Calculate relative path from one file to another."""
    from_path = Path(from_file).parent
    to_path = Path(to_file)
    
    try:
        rel_path = os.path.relpath(to_path, from_path)
        # Ensure forward slashes
        rel_path = rel_path.replace('\\', '/')
        return rel_path
    except ValueError:
        # If paths are on different drives (Windows), return absolute import
        return to_file

def update_imports_in_file(file_path, lib_dir):
    """Update imports in a single Dart file."""
    try:
        with open(file_path, 'r', encoding='utf-8') as f:
            lines = f.readlines()
        
        changed = False
        new_lines = []
        rel_file_path = os.path.relpath(file_path, lib_dir)
        
        for line in lines:
            new_line = line
            
            # Match import/export statements
            import_match = re.match(r"(import|export)\s+['\"](.+?)['\"];?", line)
            if import_match:
                statement_type = import_match.group(1)
                import_path = import_match.group(2)
                
                # Skip package imports
                if import_path.startswith('package:') or import_path.startswith('dart:'):
                    new_lines.append(line)
                    continue
                
                # Extract the filename from the import path
                imported_file = os.path.basename(import_path)
                
                # Check if this file has been moved
                if imported_file in FILE_LOCATIONS:
                    new_location = FILE_LOCATIONS[imported_file]
                    
                    # Calculate the new relative path
                    new_rel_path = calculate_relative_path(rel_file_path, new_location)
                    
                    # Replace the import
                    quote_char = "'" if "'" in line else '"'
                    new_line = f"{statement_type} {quote_char}{new_rel_path}{quote_char};\n"
                    changed = True
                    
            new_lines.append(new_line)
        
        if changed:
            with open(file_path, 'w', encoding='utf-8') as f:
                f.writelines(new_lines)
            return True
        return False
        
    except Exception as e:
        debugPrint(f"Error processing {file_path}: {e}")
        return False

def main():
    """Walk through all Dart files and update imports."""
    lib_dir = os.path.join(os.getcwd(), 'lib')
    updated_files = []
    
    for root, dirs, files in os.walk(lib_dir):
        for file in files:
            if file.endswith('.dart'):
                file_path = os.path.join(root, file)
                if update_imports_in_file(file_path, lib_dir):
                    updated_files.append(file_path)
    
    debugPrint(f"\n✅ Updated imports in {len(updated_files)} files:")
    for file_path in updated_files:
        rel_path = os.path.relpath(file_path, lib_dir)
        debugPrint(f"  - {rel_path}")
    
    debugPrint(f"\n🎉 Import update complete!")
    debugPrint(f"\nRun 'flutter pub get' and then 'flutter analyze' to check for any remaining issues.")

if __name__ == "__main__":
    main()

