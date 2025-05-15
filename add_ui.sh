#!/bin/bash

echo "📁 Creating UI folders..."
mkdir -p app/templates app/static/css app/static/js

echo "📄 Adding layout.html..."
cat > app/templates/layout.html <<'EOF'
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <title>Taskify</title>
    <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0/dist/css/bootstrap.min.css" rel="stylesheet">
    <link href="{{ url_for('static', filename='css/style.css') }}" rel="stylesheet">
</head>
<body class="bg-light">
    <div class="container mt-4">
        <h1 class="text-center mb-4">📝 Taskify - Task Manager</h1>
        {% block content %}{% endblock %}
    </div>
    <script src="{{ url_for('static', filename='js/main.js') }}"></script>
</body>
</html>
EOF

echo "📄 Adding index.html..."
cat > app/templates/index.html <<'EOF'
{% extends "layout.html" %}

{% block content %}
<div class="card p-3 mb-3">
    <form id="taskForm">
        <div class="row g-2">
            <div class="col-md-4">
                <input type="text" class="form-control" placeholder="Title" name="title" required>
            </div>
            <div class="col-md-5">
                <input type="text" class="form-control" placeholder="Description" name="description">
            </div>
            <div class="col-md-3">
                <button class="btn btn-primary w-100">Add Task</button>
            </div>
        </div>
    </form>
</div>

<ul class="list-group" id="taskList"></ul>
{% endblock %}
EOF

echo "📄 Adding main.js..."
cat > app/static/js/main.js <<'EOF'
document.addEventListener('DOMContentLoaded', loadTasks);

function loadTasks() {
    fetch('/tasks')
        .then(res => res.json())
        .then(data => {
            const list = document.getElementById('taskList');
            list.innerHTML = '';
            data.tasks.forEach(task => {
                const li = document.createElement('li');
                li.className = 'list-group-item d-flex justify-content-between align-items-center';
                li.innerHTML = \`
                    <span>\${task.title} - <em>\${task.status}</em></span>
                    <button class="btn btn-sm btn-danger" onclick="deleteTask(\${task.id})">Delete</button>
                \`;
                list.appendChild(li);
            });
        });
}

document.getElementById('taskForm').addEventListener('submit', function (e) {
    e.preventDefault();
    const formData = new FormData(this);
    const data = {
        title: formData.get('title'),
        description: formData.get('description'),
    };

    fetch('/tasks', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(data)
    })
    .then(res => res.json())
    .then(() => {
        this.reset();
        loadTasks();
    });
});

function deleteTask(id) {
    fetch(\`/tasks/\${id}\`, {
        method: 'DELETE'
    }).then(() => loadTasks());
}
EOF

echo "📄 Adding style.css..."
cat > app/static/css/style.css <<'EOF'
body {
    font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;
}
EOF

echo "🔧 Patching main_bp to render index..."
# Inject home route if not exists
ROUTE_LINE="from flask import Blueprint, jsonify, request, render_template"
if ! grep -q "render_template" app/routes/main.py; then
    sed -i "s/from flask import .*/$ROUTE_LINE/" app/routes/main.py
fi

# Add new route if not already present
if ! grep -q "@main_bp.route('/')\ndef home():" app/routes/main.py; then
cat >> app/routes/main.py <<EOF

@main_bp.route('/')
def home():
    return render_template('index.html')
EOF
fi

echo "✅ UI files created and Flask route updated!"
echo "👉 Commit and push your changes to trigger CI/CD"
