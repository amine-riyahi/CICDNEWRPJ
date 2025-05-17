#!/usr/bin/env bash
# One‑stop scaffold: adds multiple pages, updates UI/UX, and wires routes/templates in Taskify‑Pro
# Usage: run from project root: chmod +x scaffold.sh && ./scaffold.sh

# Exit on error
set -e

APP_DIR="app"
TEMPLATES="$APP_DIR/templates"
STATIC_CSS="$APP_DIR/static/css"
STATIC_JS="$APP_DIR/static/js"
ROUTES_FILE="$APP_DIR/routes.py"
LAYOUT_FILE="$TEMPLATES/layout.html"
INDEX_FILE="$TEMPLATES/index.html"
CONFIG_FILE="$APP_DIR/__init__.py"

# 1. Ensure directories exist
mkdir -p "$TEMPLATES" "$STATIC_CSS" "$STATIC_JS"

echo "[*] Creating additional pages in templates..."
# 2. Create About page
cat > "$TEMPLATES/about.html" << 'EOF'
{% extends "layout.html" %}
{% block content %}
<h1>About Taskify</h1>
<p>Taskify is a modern task manager app built with Flask.</p>
{% endblock %}
EOF

# Contact page
cat > "$TEMPLATES/contact.html" << 'EOF'
{% extends "layout.html" %}
{% block content %}
<h1>Contact Us</h1>
<form>
  <div class="mb-3"><input class="form-control" placeholder="Your name"></div>
  <div class="mb-3"><input class="form-control" placeholder="Your email"></div>
  <div class="mb-3"><textarea class="form-control" placeholder="Message"></textarea></div>
  <button class="btn btn-primary">Send</button>
</form>
{% endblock %}
EOF

# Dashboard page
cat > "$TEMPLATES/dashboard.html" << 'EOF'
{% extends "layout.html" %}
{% block content %}
<h1>Dashboard</h1>
<p>Welcome back, user!</p>
{% endblock %}
EOF

# Profile page
cat > "$TEMPLATES/profile.html" << 'EOF'
{% extends "layout.html" %}
{% block content %}
<h1>Your Profile</h1>
<ul class="list-group">
  <li class="list-group-item">Username: demo</li>
  <li class="list-group-item">Joined: {{ join_date }}</li>
</ul>
{% endblock %}
EOF

echo "[*] Updating layout.html with navbar and TailwindCSS CDN..."
# 3. Prepend navbar and Tailwind to layout.html
cat > "$LAYOUT_FILE" << 'EOF'
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <title>Taskify</title>
  <!-- TailwindCSS via CDN -->
  <script src="https://cdn.tailwindcss.com"></script>
  <link href="{{ url_for('static', filename='css/style.css') }}" rel="stylesheet">
</head>
<body class="bg-gray-100">
  <nav class="bg-white p-4 shadow mb-6">
    <div class="container mx-auto flex space-x-4">
      <a href="/" class="font-bold">Home</a>
      <a href="/dashboard">Dashboard</a>
      <a href="/tasks">Tasks</a>
      <a href="/about">About</a>
      <a href="/contact">Contact</a>
      <a href="/profile">Profile</a>
    </div>
  </nav>
  <div class="container mx-auto p-4">
    {% block content %}{% endblock %}
  </div>
</body>
</html>
EOF

echo "[*] Appending new routes to routes.py..."
# 4. Append blueprint routes
cat >> "$ROUTES_FILE" << 'EOF'

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
    # demo data
    return render_template('profile.html', join_date='2025-05-17')

@main_bp.route('/tasks', methods=['GET'])
def tasks_page():
    # fetch all tasks via API or direct query
    tasks = Task.query.order_by(Task.id.desc()).all()
    return render_template('index.html', tasks=tasks)
EOF

# 5. Ensure routes.py imports and context
if ! grep -q "render_template" "$ROUTES_FILE"; then
  sed -i "1 s/from flask import Blueprint, jsonify, request/from flask import Blueprint, jsonify, request, render_template/" "$ROUTES_FILE"
fi
if ! grep -q "Task" "$ROUTES_FILE"; then
  sed -i "2 a from app.models import Task" "$ROUTES_FILE"
fi

echo "[*] Scaffold complete! Restart your Flask server to see changes."
