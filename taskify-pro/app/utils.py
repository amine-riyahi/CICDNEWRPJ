# Utility functions can be added here as needed
def validate_task_data(data):
    """Validate incoming task data"""
    errors = []
    if not data.get('title'):
        errors.append('Title is required')
        
    if 'status' in data and data['status'] not in ['pending', 'in_progress', 'completed']:
        errors.append('Status must be one of: pending, in_progress, completed')
    
    return errors
