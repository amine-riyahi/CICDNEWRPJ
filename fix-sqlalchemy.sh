#!/bin/bash
# Script to fix SQLAlchemy compatibility issue

# Navigate to the project directory
cd taskify-pro

# Update requirements.txt to pin compatible Flask, Werkzeug, and SQLAlchemy versions
cat > requirements.txt << 'EOF'
Flask==2.0.2
Werkzeug==2.0.3
SQLAlchemy==1.4.46
Flask-SQLAlchemy==2.5.1
psycopg2-binary==2.9.3
gunicorn==20.1.0
pytest==7.0.0
flake8==4.0.1
black==22.1.0
coverage==6.3.2
python-dotenv==0.19.2
EOF

echo "Requirements file updated with compatible Flask, Werkzeug, and SQLAlchemy versions."
echo "Now run 'docker-compose down && docker-compose up --build' to rebuild with the fixed dependencies."
