from flask import Blueprint, flash, redirect, render_template, request, session, url_for

from app.services import (
    account_service,
    customer_service,
    dashboard_service,
    transaction_service,
)

banker_bp = Blueprint("banker", __name__)


def _current_user():
    return session.get("user", {})


def _created_by_user_id():
    return _current_user().get("username", "banker")


@banker_bp.route("/dashboard")
def dashboard():
    data = dashboard_service.get_banker_dashboard()
    return render_template("banker/dashboard.html", dashboard=data, user=_current_user())


@banker_bp.route("/customers")
def customers():
    customer_list = customer_service.get_customers()
    return render_template("banker/customers.html", customers=customer_list, user=_current_user())


@banker_bp.route("/customers/new", methods=["GET", "POST"])
def customers_new():
    form_data = {
        "full_name": "",
        "email": "",
        "phone_number": "",
        "address": "",
        "birth_day": "",
        "username": "",
        "password": "",
    }

    if request.method == "POST":
        form_data = {key: request.form.get(key, "").strip() for key in form_data}
        required = ["full_name", "email", "phone_number", "username", "password"]
        if not all(form_data[f] for f in required):
            flash("Vui lòng điền đầy đủ các trường bắt buộc.", "warning")
            return render_template("banker/customers_new.html", form_data=form_data, user=_current_user())

        result = customer_service.create_customer(**form_data)
        flash(result["message"], "success" if result["success"] else "danger")
        if result["success"]:
            return redirect(url_for("banker.customers"))
        return render_template("banker/customers_new.html", form_data=form_data, user=_current_user())

    return render_template("banker/customers_new.html", form_data=form_data, user=_current_user())


@banker_bp.route("/accounts")
def accounts():
    account_list = account_service.get_accounts()
    return render_template("banker/accounts.html", accounts=account_list, user=_current_user())


@banker_bp.route("/accounts/open", methods=["GET", "POST"])
def accounts_open():
    form_data = {"customer_id": "", "account_type": "checking", "initial_balance": ""}
    customers = account_service.get_customers_for_select()
    account_types = account_service.get_account_types()

    if request.method == "POST":
        form_data = {
            "customer_id": request.form.get("customer_id", "").strip(),
            "account_type": request.form.get("account_type", "").strip(),
            "initial_balance": request.form.get("initial_balance", "").strip(),
        }
        if not form_data["customer_id"] or not form_data["account_type"]:
            flash("Vui lòng chọn khách hàng và loại tài khoản.", "warning")
            return render_template(
                "banker/accounts_open.html",
                form_data=form_data,
                customers=customers,
                account_types=account_types,
                user=_current_user(),
            )

        result = account_service.open_account(
            customer_id=form_data["customer_id"],
            account_type=form_data["account_type"],
            initial_balance=form_data["initial_balance"] or "0",
            created_by_user_id=_created_by_user_id(),
        )
        flash(result["message"], "success" if result["success"] else "danger")
        if result["success"]:
            return redirect(url_for("banker.accounts"))
        return render_template(
            "banker/accounts_open.html",
            form_data=form_data,
            customers=customers,
            account_types=account_types,
            user=_current_user(),
        )

    return render_template(
        "banker/accounts_open.html",
        form_data=form_data,
        customers=customers,
        account_types=account_types,
        user=_current_user(),
    )


@banker_bp.route("/transactions")
def transactions():
    tx_list = transaction_service.get_transactions()
    return render_template("banker/transactions.html", transactions=tx_list, user=_current_user())


@banker_bp.route("/transactions/deposit", methods=["GET", "POST"])
def deposit():
    form_data = {"account_number": "", "amount": "", "description": ""}
    if request.method == "POST":
        form_data = {k: request.form.get(k, "").strip() for k in form_data}
        if not form_data["account_number"] or not form_data["amount"]:
            flash("Vui lòng nhập số tài khoản và số tiền.", "warning")
            return render_template("banker/deposit.html", form_data=form_data, user=_current_user())

        result = transaction_service.deposit(
            account_number=form_data["account_number"],
            amount=form_data["amount"],
            description=form_data["description"],
            created_by_user_id=_created_by_user_id(),
        )
        flash(result["message"], "success" if result["success"] else "danger")
        if result["success"]:
            return redirect(url_for("banker.transactions"))
        return render_template("banker/deposit.html", form_data=form_data, user=_current_user())

    return render_template("banker/deposit.html", form_data=form_data, user=_current_user())


@banker_bp.route("/transactions/withdraw", methods=["GET", "POST"])
def withdraw():
    form_data = {"account_number": "", "amount": "", "description": ""}
    if request.method == "POST":
        form_data = {k: request.form.get(k, "").strip() for k in form_data}
        if not form_data["account_number"] or not form_data["amount"]:
            flash("Vui lòng nhập số tài khoản và số tiền.", "warning")
            return render_template("banker/withdraw.html", form_data=form_data, user=_current_user())

        result = transaction_service.withdraw(
            account_number=form_data["account_number"],
            amount=form_data["amount"],
            description=form_data["description"],
            created_by_user_id=_created_by_user_id(),
        )
        flash(result["message"], "success" if result["success"] else "danger")
        if result["success"]:
            return redirect(url_for("banker.transactions"))
        return render_template("banker/withdraw.html", form_data=form_data, user=_current_user())

    return render_template("banker/withdraw.html", form_data=form_data, user=_current_user())


@banker_bp.route("/transactions/transfer", methods=["GET", "POST"])
def transfer():
    form_data = {
        "from_account_number": "",
        "to_account_number": "",
        "amount": "",
        "description": "",
    }
    if request.method == "POST":
        form_data = {k: request.form.get(k, "").strip() for k in form_data}
        if not all([form_data["from_account_number"], form_data["to_account_number"], form_data["amount"]]):
            flash("Vui lòng nhập đầy đủ tài khoản nguồn, đích và số tiền.", "warning")
            return render_template("banker/transfer.html", form_data=form_data, user=_current_user())

        result = transaction_service.transfer(
            from_account_number=form_data["from_account_number"],
            to_account_number=form_data["to_account_number"],
            amount=form_data["amount"],
            description=form_data["description"],
            created_by_user_id=_created_by_user_id(),
        )
        flash(result["message"], "success" if result["success"] else "danger")
        if result["success"]:
            return redirect(url_for("banker.transactions"))
        return render_template("banker/transfer.html", form_data=form_data, user=_current_user())

    return render_template("banker/transfer.html", form_data=form_data, user=_current_user())
