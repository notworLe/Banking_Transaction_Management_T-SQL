from flask import Blueprint, flash, redirect, render_template, session, url_for

from app.services import admin_service, dashboard_service

admin_bp = Blueprint("admin", __name__)


def _current_user():
    return session.get("user", {})


@admin_bp.route("/dashboard")
def dashboard():
    data = dashboard_service.get_admin_dashboard()
    return render_template("admin/dashboard.html", dashboard=data, user=_current_user())


@admin_bp.route("/users")
def users():
    user_list = admin_service.get_users()
    return render_template("admin/users.html", users=user_list, user=_current_user())


@admin_bp.route("/users/<int:user_id>/toggle-status", methods=["POST"])
def toggle_user_status(user_id):
    success, message = admin_service.toggle_user_status(user_id)
    flash(message, "success" if success else "danger")
    return redirect(url_for("admin.users"))


@admin_bp.route("/audit-logs")
def audit_logs():
    logs = admin_service.get_audit_logs()
    return render_template("admin/audit_logs.html", audit_logs=logs, user=_current_user())


@admin_bp.route("/login-logs")
def login_logs():
    logs = admin_service.get_login_logs()
    return render_template("admin/login_logs.html", login_logs=logs, user=_current_user())
