#!/bin/bash

# Exit if anything fails
set -e

ROUTES_FILE="app/routes.py"
BACKUP_FILE="app/routes.py.bak"

echo "[*] Backing up routes.py..."
cp "$ROUTES_FILE" "$BACKUP_FILE"

echo "[*] Inserting route handlers after main_bp declaration..."

python3 - <<EOF
import re

file_path = "$ROUTES_FILE"

with open(file_path, "r") as f:
    content = f.read()

pattern = r'(main_bp\s*=\s*Blueprint\(.*?\))'
insertion = '''
@main_bp.route('/about')
def about():
    return render_template('about.html')

@main_bp.route('/contact')
def contact():
    return render_template('contact.html')

@main_bp.route('/dashboard')
def dashboard():
    return render_template('dashboard.html')

@main_bp.route('/profile')
def profile():
    return render_template('profile.html', join_date='2025-05-17')

@main_bp.route('/tasks', methods=['GET'])
def tasks_page():
    tasks = Task.query.order_by(Task.id.desc()).all()
    return render_template('index.html', tasks=tasks)
'''

if insertion.strip() in content:
    print("[-] Route handlers already exist. Skipping insertion.")
else:
    new_content = re.sub(pattern, r'\1\n' + insertion, content, count=1)

    with open(file_path, "w") as f:
        f.write(new_content)

    print("[+] Routes inserted successfully.")
EOF
