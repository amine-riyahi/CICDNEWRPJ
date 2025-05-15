#!/bin/bash
# Script to create Taskify Pro project structure

# Create main project directory
mkdir -p taskify-pro

# Change to project directory
cd taskify-pro

# Create GitHub workflow directories
mkdir -p .github/workflows

# Create app directories
mkdir -p app

# Create tests directory
mkdir -p tests

# Create GitHub Actions CI/CD workflow file
cat > .github/workflows/ci-cd.yml << 'EOF'
name: CI/CD Pipeline

on:
  push:
    branches: [ main ]
  pull_request:
    branches: [ main ]

jobs:
  lint:
    runs-on: ubuntu-latest
    strategy:
      matrix:
        python-version: [3.8, 3.9, '3.10']

    steps:
    - uses: actions/checkout@v2
    - name: Set up Python ${{ matrix.python-version }}
      uses: actions/setup-python@v2
      with:
        python-version: ${{ matrix.python-version }}
    - name: Install dependencies
      run: |
        python -m pip install --upgrade pip
        pip install flake8 black
        if [ -f requirements.txt ]; then pip install -r requirements.txt; fi
    - name: Lint with flake8
      run: |
        flake8 . --count --select=E9,F63,F7,F82 --show-source --statistics
    - name: Check formatting with black
      run: |
        black --check .

  test:
    runs-on: ubuntu-latest
    needs: lint
    services:
      postgres:
        image: postgres:14-alpine
        env:
          POSTGRES_USER: postgres
          POSTGRES_PASSWORD: postgres
          POSTGRES_DB: taskify_test
        ports:
          - 5432:5432
        options: >-
          --health-cmd pg_isready
          --health-interval 10s
          --health-timeout 5s
          --health-retries 5
    
    strategy:
      matrix:
        python-version: [3.8, 3.9, '3.10']

    steps:
    - uses: actions/checkout@v2
    - name: Set up Python ${{ matrix.python-version }}
      uses: actions/setup-python@v2
      with:
        python-version: ${{ matrix.python-version }}
    - name: Install dependencies
      run: |
        python -m pip install --upgrade pip
        pip install coverage pytest
        if [ -f requirements.txt ]; then pip install -r requirements.txt; fi
    - name: Test with pytest and coverage
      env:
        FLASK_ENV: testing
        TEST_DATABASE_URL: postgresql://postgres:postgres@localhost:5432/taskify_test
      run: |
        coverage run -m pytest
        coverage report
        coverage xml

  deploy:
    runs-on: ubuntu-latest
    needs: test
    if: github.ref == 'refs/heads/main'
    
    steps:
    - uses: actions/checkout@v2
    
    - name: Deploy to Render
      env:
        RENDER_API_KEY: ${{ secrets.RENDER_API_KEY }}
      run: |
        # Here you would typically use Render's API to trigger a deployment
        # For demonstration, we're using a placeholder
        curl -s "https://api.render.com/deploy/srv-YOUR_SERVICE_ID?key=${RENDER_API_KEY}"
        echo "Deployed to Render successfully!"
EOF

# Create app/__init__.py
cat > app/__init__.py << 'EOF'
from flask import Flask
from flask_sqlalchemy import SQLAlchemy
import os

db = SQLAlchemy()

def create_app(config_name=None):
    app = Flask(__name__)
    
    # Load configuration
    if config_name is None:
        config_name = os.environ.get('FLASK_ENV', 'development')
    
    from app.config import config
    app.config.from_object(config[config_name])
    
    # Initialize extensions
    db.init_app(app)
    
    # Register blueprints
    from app.routes import main_bp
    app.register_blueprint(main_bp)
    
    # Create db tables if they don't exist
    with app.app_context():
        db.create_all()
        
    return app
EOF

# Create app/config.py
cat > app/config.py << 'EOF'
import os

class Config:
    SECRET_KEY = os.environ.get('SECRET_KEY', 'dev-key-for-development')
    SQLALCHEMY_TRACK_MODIFICATIONS = False

class DevelopmentConfig(Config):
    DEBUG = True
    SQLALCHEMY_DATABASE_URI = os.environ.get('DATABASE_URL', 'postgresql://postgres:postgres@db:5432/taskify')

class TestingConfig(Config):
    TESTING = True
    SQLALCHEMY_DATABASE_URI = os.environ.get('TEST_DATABASE_URL', 'postgresql://postgres:postgres@db:5432/taskify_test')

class ProductionConfig(Config):
    DEBUG = False
    SQLALCHEMY_DATABASE_URI = os.environ.get('DATABASE_URL')

config = {
    'development': DevelopmentConfig,
    'testing': TestingConfig,
    'production': ProductionConfig,
    'default': DevelopmentConfig
}
EOF

# Create app/models.py
cat > app/models.py << 'EOF'
from app import db
from datetime import datetime

class Task(db.Model):
    __tablename__ = 'tasks'
    
    id = db.Column(db.Integer, primary_key=True)
    title = db.Column(db.String(100), nullable=False)
    description = db.Column(db.Text)
    status = db.Column(db.String(20), default='pending')
    due_date = db.Column(db.DateTime)
    created_at = db.Column(db.DateTime, default=datetime.utcnow)
    updated_at = db.Column(db.DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)
    
    def to_dict(self):
        return {
            'id': self.id,
            'title': self.title,
            'description': self.description,
            'status': self.status,
            'due_date': self.due_date.isoformat() if self.due_date else None,
            'created_at': self.created_at.isoformat(),
            'updated_at': self.updated_at.isoformat()
        }
EOF

# Create app/routes.py
cat > app/routes.py << 'EOF'
from flask import Blueprint, jsonify, request
from app.models import Task
from app import db
from datetime import datetime

main_bp = Blueprint('main', __name__)

@main_bp.route('/health', methods=['GET'])
def health_check():
    return jsonify({
        'status': 'ok',
        'timestamp': datetime.utcnow().isoformat(),
        'service': 'taskify-pro',
        'database': 'connected' if db.engine.execute('SELECT 1').scalar() else 'disconnected'
    })

@main_bp.route('/tasks', methods=['GET'])
def get_tasks():
    tasks = Task.query.all()
    return jsonify({
        'tasks': [task.to_dict() for task in tasks],
        'count': len(tasks)
    })

@main_bp.route('/tasks', methods=['POST'])
def create_task():
    data = request.get_json()
    
    if not data or 'title' not in data:
        return jsonify({'error': 'Title is required'}), 400
    
    task = Task(
        title=data['title'],
        description=data.get('description', ''),
        status=data.get('status', 'pending')
    )
    
    if 'due_date' in data and data['due_date']:
        task.due_date = datetime.fromisoformat(data['due_date'])
    
    db.session.add(task)
    db.session.commit()
    
    return jsonify(task.to_dict()), 201

@main_bp.route('/tasks/<int:task_id>', methods=['GET'])
def get_task(task_id):
    task = Task.query.get_or_404(task_id)
    return jsonify(task.to_dict())

@main_bp.route('/tasks/<int:task_id>', methods=['PUT'])
def update_task(task_id):
    task = Task.query.get_or_404(task_id)
    data = request.get_json()
    
    if 'title' in data:
        task.title = data['title']
    if 'description' in data:
        task.description = data['description']
    if 'status' in data:
        task.status = data['status']
    if 'due_date' in data:
        task.due_date = datetime.fromisoformat(data['due_date']) if data['due_date'] else None
    
    db.session.commit()
    return jsonify(task.to_dict())

@main_bp.route('/tasks/<int:task_id>', methods=['DELETE'])
def delete_task(task_id):
    task = Task.query.get_or_404(task_id)
    db.session.delete(task)
    db.session.commit()
    return '', 204
EOF

# Create app/utils.py
cat > app/utils.py << 'EOF'
# Utility functions can be added here as needed
def validate_task_data(data):
    """Validate incoming task data"""
    errors = []
    if not data.get('title'):
        errors.append('Title is required')
        
    if 'status' in data and data['status'] not in ['pending', 'in_progress', 'completed']:
        errors.append('Status must be one of: pending, in_progress, completed')
    
    return errors
EOF

# Create tests/__init__.py
cat > tests/__init__.py << 'EOF'
# This file can be empty, it's just to make the tests directory a package
EOF

# Create tests/test_app.py
cat > tests/test_app.py << 'EOF'
import unittest
import json
import os
from app import create_app, db

class TestApp(unittest.TestCase):
    def setUp(self):
        # Set test configuration
        os.environ['FLASK_ENV'] = 'testing'
        self.app = create_app('testing')
        self.client = self.app.test_client()
        self.app_context = self.app.app_context()
        self.app_context.push()
        db.create_all()

    def tearDown(self):
        db.session.remove()
        db.drop_all()
        self.app_context.pop()

    def test_health_endpoint(self):
        response = self.client.get('/health')
        self.assertEqual(response.status_code, 200)
        data = json.loads(response.data)
        self.assertEqual(data['status'], 'ok')
        self.assertEqual(data['service'], 'taskify-pro')

    def test_create_task(self):
        # Test creating a task
        response = self.client.post(
            '/tasks',
            data=json.dumps({
                'title': 'Test Task',
                'description': 'This is a test task',
                'status': 'pending'
            }),
            content_type='application/json'
        )
        self.assertEqual(response.status_code, 201)
        data = json.loads(response.data)
        self.assertEqual(data['title'], 'Test Task')
        self.assertEqual(data['status'], 'pending')

    def test_get_tasks(self):
        # Create a task first
        self.client.post(
            '/tasks',
            data=json.dumps({
                'title': 'Test Task',
                'description': 'This is a test task',
                'status': 'pending'
            }),
            content_type='application/json'
        )
        
        # Test retrieving tasks
        response = self.client.get('/tasks')
        self.assertEqual(response.status_code, 200)
        data = json.loads(response.data)
        self.assertEqual(len(data['tasks']), 1)
        self.assertEqual(data['count'], 1)

if __name__ == '__main__':
    unittest.main()
EOF

# Create .dockerignore
cat > .dockerignore << 'EOF'
__pycache__
*.pyc
*.pyo
*.pyd
.Python
env/
venv/
.venv/
.env
*.so
.git
.gitignore
.pytest_cache/
.coverage
htmlcov/
EOF

# Create .env-example
cat > .env-example << 'EOF'
FLASK_APP=run.py
FLASK_ENV=development
SECRET_KEY=your-secret-key-here
DATABASE_URL=postgresql://postgres:postgres@db:5432/taskify
EOF

# Create .flake8
cat > .flake8 << 'EOF'
[flake8]
max-line-length = 100
exclude = .git,__pycache__,build,dist
EOF

# Create .gitignore
cat > .gitignore << 'EOF'
# Byte-compiled / optimized / DLL files
__pycache__/
*.py[cod]
*$py.class

# Virtual environments
venv/
.venv/
env/
ENV/

# Environment variables
.env

# Flask stuff
instance/
.webassets-cache

# Unit test / coverage reports
htmlcov/
.tox/
.nox/
.coverage
.coverage.*
.cache
nosetests.xml
coverage.xml
*.cover
.hypothesis/
.pytest_cache/

# Docker
.docker/

# IDEs
.idea/
.vscode/
*.sublime-project
*.sublime-workspace

# Database
*.db
*.sqlite
EOF

# Create Dockerfile
cat > Dockerfile << 'EOF'
FROM python:3.10-slim

WORKDIR /app

# Install dependencies
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Copy application code
COPY . .

# Set environment variables
ENV PYTHONDONTWRITEBYTECODE=1
ENV PYTHONUNBUFFERED=1
ENV FLASK_APP=run.py

# Expose the port the app runs on
EXPOSE 5000

# Command to run the application
CMD ["gunicorn", "--bind", "0.0.0.0:5000", "run:app"]
EOF

# Create docker-compose.yml
cat > docker-compose.yml << 'EOF'
version: '3.8'

services:
  web:
    build: .
    ports:
      - "5000:5000"
    environment:
      - FLASK_ENV=development
      - DATABASE_URL=postgresql://postgres:postgres@db:5432/taskify
    depends_on:
      - db
    volumes:
      - .:/app
    restart: always

  db:
    image: postgres:14-alpine
    volumes:
      - postgres_data:/var/lib/postgresql/data
    environment:
      - POSTGRES_USER=postgres
      - POSTGRES_PASSWORD=postgres
      - POSTGRES_DB=taskify
    ports:
      - "5432:5432"

volumes:
  postgres_data:
EOF

# Create requirements.txt
cat > requirements.txt << 'EOF'
Flask==2.0.2
Flask-SQLAlchemy==2.5.1
psycopg2-binary==2.9.3
gunicorn==20.1.0
pytest==7.0.0
flake8==4.0.1
black==22.1.0
coverage==6.3.2
python-dotenv==0.19.2
EOF

# Create run.py
cat > run.py << 'EOF'
from app import create_app, db

app = create_app()

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000)
EOF

echo "Taskify Pro project structure created successfully!"
echo "To start the application with Docker, run: cd taskify-pro && docker-compose up --build"
