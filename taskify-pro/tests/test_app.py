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
