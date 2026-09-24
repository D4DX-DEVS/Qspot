#!/usr/bin/env python3
import os
import re
from pathlib import Path

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
        return to_file

def get_file_depth(file_path, base_dir):
    """Get the depth of a file relative to base directory."""
    rel_path = os.path.relpath(file_path, base_dir)
    return len(Path(rel_path).parts) - 1

def fix_shared_imports(file_path, lib_dir):
    """Fix imports for shared resources like themes, utils, services."""
    try:
        with open(file_path, 'r', encoding='utf-8') as f:
            content = f.read()
        
        original_content = content
        rel_file_path = os.path.relpath(file_path, lib_dir)
        
        # Shared resources that need fixing
        shared_resources = {
            'app_theme.dart': 'themes/app_theme.dart',
            'api_urls.dart': 'utils/api_urls.dart',
        }
        
        for filename, correct_path in shared_resources.items():
            # Find all imports of this file
            patterns = [
                r"(import|export)\s+['\"](\.\./)*(.*/)?{}['\"];?".format(re.escape(filename)),
            ]
            
            for pattern in patterns:
                matches = list(re.finditer(pattern, content))
                for match in matches:
                    statement_type = match.group(1)
                    old_import = match.group(0)
                    
                    # Calculate correct relative path
                    new_rel_path = calculate_relative_path(rel_file_path, correct_path)
                    
                    # Determine quote character
                    quote_char = "'" if "'" in old_import else '"'
                    
                    # Create new import statement
                    new_import = f"{statement_type} {quote_char}{new_rel_path}{quote_char};"
                    
                    content = content.replace(old_import, new_import)
        
        if content != original_content:
            with open(file_path, 'w', encoding='utf-8') as f:
                f.write(content)
            return True
        return False
        
    except Exception as e:
        debugPrint(f"Error processing {file_path}: {e}")
        return False

def main():
    """Fix all shared resource imports."""
    lib_dir = os.path.join(os.getcwd(), 'lib')
    updated_files = []
    
    for root, dirs, files in os.walk(lib_dir):
        for file in files:
            if file.endswith('.dart'):
                file_path = os.path.join(root, file)
                if fix_shared_imports(file_path, lib_dir):
                    updated_files.append(file_path)
    
    debugPrint(f"\n✅ Fixed shared imports in {len(updated_files)} files:")
    for file_path in updated_files:
        rel_path = os.path.relpath(file_path, lib_dir)
        debugPrint(f"  - {rel_path}")
    
    debugPrint(f"\n🎉 Shared imports fix complete!")

if __name__ == "__main__":
    main()

