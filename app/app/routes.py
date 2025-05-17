from flask import Blueprint, jsonify, request, render_template
from app.models import Task
from app import db

main_bp = Blueprint("main", __name__)


@main_bp.route("/", methods=["GET"])
def index():
    return render_template("index.html")


@main_bp.route("/health", methods=["GET"])
def health_check():
    return jsonify(status="ok")


@main_bp.route("/about", methods=["GET"])
def about():
    return render_template("about.html")


@main_bp.route("/contact", methods=["GET"])
def contact():
    return render_template("contact.html")


@main_bp.route("/dashboard", methods=["GET"])
def dashboard():
    return render_template("dashboard.html")


@main_bp.route("/profile", methods=["GET"])
def profile():
    return render_template("profile.html", join_date="2025-05-17")


@main_bp.route("/tasks", methods=["GET"])
def tasks_page():
    tasks = Task.query.order_by(Task.id.desc()).all()
    return render_template("index.html", tasks=tasks)
