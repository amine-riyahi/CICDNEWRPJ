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
