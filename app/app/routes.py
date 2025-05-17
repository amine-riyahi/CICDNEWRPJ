
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
