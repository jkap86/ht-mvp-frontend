"""Replace hardcoded BorderRadius.circular(N) with AppSpacing constants."""
import os
import re

FRONTEND_LIB = os.path.join(os.path.dirname(os.path.abspath(__file__)), 'lib')
APP_SPACING_PATH = os.path.join(FRONTEND_LIB, 'core', 'theme', 'app_spacing.dart')

# Files to skip
SKIP_FILES = {'app_theme.dart', 'app_spacing.dart'}

# Mapping: value -> replacement string
# For values 4, 8, 12, 20: the replacement IS a BorderRadius object (replaces entire expression)
# For values 2, 16, 24: the replacement keeps BorderRadius.circular() wrapper
REPLACEMENTS = {
    '2': 'BorderRadius.circular(AppSpacing.radiusXs)',
    '4': 'AppSpacing.badgeRadius',
    '8': 'AppSpacing.buttonRadius',
    '12': 'AppSpacing.cardRadius',
    '16': 'BorderRadius.circular(AppSpacing.radiusXl)',
    '20': 'AppSpacing.pillRadius',
    '24': 'BorderRadius.circular(AppSpacing.radiusXxl)',
}

def compute_relative_import(file_path):
    """Compute relative import path from file_path to app_spacing.dart."""
    file_dir = os.path.dirname(file_path)
    rel = os.path.relpath(APP_SPACING_PATH, file_dir)
    # Convert backslashes to forward slashes for Dart imports
    rel = rel.replace('\\', '/')
    return f"import '{rel}';"

def find_dart_files(root):
    """Find all .dart files recursively."""
    dart_files = []
    for dirpath, dirnames, filenames in os.walk(root):
        for fname in filenames:
            if fname.endswith('.dart') and fname not in SKIP_FILES:
                dart_files.append(os.path.join(dirpath, fname))
    return dart_files

def add_import_if_needed(content, filepath):
    """Add AppSpacing import after the last import line if not already present."""
    if 'app_spacing.dart' in content:
        return content

    import_line = compute_relative_import(filepath)

    lines = content.split('\n')
    last_import_idx = -1
    for i, line in enumerate(lines):
        stripped = line.strip()
        if stripped.startswith('import '):
            last_import_idx = i

    if last_import_idx >= 0:
        lines.insert(last_import_idx + 1, import_line)
        return '\n'.join(lines)

    return content

def process_file(filepath):
    """Process a single file, making all replacements."""
    with open(filepath, 'r', encoding='utf-8') as f:
        original = f.read()

    content = original
    made_changes = False

    for value, replacement in REPLACEMENTS.items():
        # Build the pattern - match BorderRadius.circular(N) exactly
        # Need to handle possible .0 suffix
        pattern = rf'BorderRadius\.circular\({value}(?:\.0)?\)'

        if re.search(pattern, content):
            content = re.sub(pattern, replacement, content)
            made_changes = True

    if made_changes:
        content = add_import_if_needed(content, filepath)
        with open(filepath, 'w', encoding='utf-8') as f:
            f.write(content)
        return True
    return False

def main():
    files = find_dart_files(FRONTEND_LIB)
    updated = 0
    updated_files = []

    for filepath in sorted(files):
        if process_file(filepath):
            updated += 1
            relpath = os.path.relpath(filepath, FRONTEND_LIB)
            updated_files.append(relpath)
            print(f"Updated: {relpath}")

    print(f"\nTotal files updated: {updated}")

if __name__ == '__main__':
    main()
