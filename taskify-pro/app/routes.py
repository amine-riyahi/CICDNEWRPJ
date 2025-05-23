from flask import Blueprint, jsonify, request
from app.models import Task
from app import db
from datetime import datetime

main_bp = Blueprint("main", __name__)


@main_bp.route("/health", methods=["GET"])
def health_check():
    return jsonify(
        {
            "status": "ok",
            "timestamp": datetime.utcnow().isoformat(),
            "service": "taskify-pro",
            "database": (
                "connected"
                if db.engine.execute("SELECT 1").scalar()
                else "disconnected"
            ),
        }
    )


@main_bp.route("/tasks", methods=["GET"])
def get_tasks():
    tasks = Task.query.all()
    return jsonify({"tasks": [task.to_dict() for task in tasks], "count": len(tasks)})


@main_bp.route("/tasks", methods=["POST"])
def create_task():
    data = request.get_json()

    if not data or "title" not in data:
        return jsonify({"error": "Title is required"}), 400

    task = Task(
        title=data["title"],
        description=data.get("description", ""),
        status=data.get("status", "pending"),
    )

    if "due_date" in data and data["due_date"]:
        task.due_date = datetime.fromisoformat(data["due_date"])

    db.session.add(task)
    db.session.commit()

    return jsonify(task.to_dict()), 201


@main_bp.route("/tasks/<int:task_id>", methods=["GET"])
def get_task(task_id):
    task = Task.query.get_or_404(task_id)
    return jsonify(task.to_dict())


@main_bp.route("/tasks/<int:task_id>", methods=["PUT"])
def update_task(task_id):
    task = Task.query.get_or_404(task_id)
    data = request.get_json()

    if "title" in data:
        task.title = data["title"]
    if "description" in data:
        task.description = data["description"]
    if "status" in data:
        task.status = data["status"]
    if "due_date" in data:
        task.due_date = (
            datetime.fromisoformat(data["due_date"]) if data["due_date"] else None
        )

    db.session.commit()
    return jsonify(task.to_dict())


@main_bp.route("/tasks/<int:task_id>", methods=["DELETE"])
def delete_task(task_id):
    task = Task.query.get_or_404(task_id)
    db.session.delete(task)
    db.session.commit()
    return "", 204
