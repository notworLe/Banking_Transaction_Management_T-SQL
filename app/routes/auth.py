from flask import Blueprint, flash, redirect, render_template, request, session, url_for

from app.services import auth_service

auth_bp = Blueprint("auth", __name__)


@auth_bp.route("/login", methods=["GET", "POST"])
def login():
    form_data = {"username": "", "role": "admin"}

    if request.method == "POST":
        username = request.form.get("username", "").strip()
        password = request.form.get("password", "")
        role = request.form.get("role", "").strip()

        form_data = {"username": username, "role": role}

        if not username or not password:
            flash("Vui lòng nhập tên đăng nhập và mật khẩu.", "warning")
            return render_template("auth/login.html", form_data=form_data)

        if role not in auth_service.VALID_ROLES:
            flash("Vui lòng chọn vai trò hợp lệ.", "warning")
            return render_template("auth/login.html", form_data=form_data)

        user = auth_service.mock_login(username, password, role)
        session["user"] = user
        dashboard_route = auth_service.get_dashboard_url_for_role(user["role"])
        flash(f"Đăng nhập thành công. Xin chào, {user['display_name']}!", "success")
        return redirect(url_for(dashboard_route))

    return render_template("auth/login.html", form_data=form_data)


@auth_bp.route("/logout")
def logout():
    session.clear()
    flash("Bạn đã đăng xuất.", "info")
    return redirect(url_for("auth.login"))
