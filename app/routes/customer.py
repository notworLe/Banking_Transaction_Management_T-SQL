from flask import Blueprint, flash, redirect, render_template, request, session, url_for

from app.services import customer_portal_service, transaction_service

customer_bp = Blueprint("customer", __name__)


def _current_user():
    return session.get("user", {})


def _username():
    return _current_user().get("username", "customer")


@customer_bp.route("/dashboard")
def dashboard():
    data = customer_portal_service.get_dashboard(_username())
    return render_template("customer/dashboard.html", dashboard=data, user=_current_user())


@customer_bp.route("/accounts")
def accounts():
    account_list = customer_portal_service.get_accounts(_username())
    profile = customer_portal_service.get_dashboard(_username())
    return render_template(
        "customer/accounts.html",
        accounts=account_list,
        customer_name=profile["customer_name"],
        user=_current_user(),
    )


@customer_bp.route("/transactions")
def transactions():
    tx_list = customer_portal_service.get_transactions(_username())
    return render_template("customer/transactions.html", transactions=tx_list, user=_current_user())


@customer_bp.route("/transfer", methods=["GET", "POST"])
def transfer():
    owned_accounts = customer_portal_service.get_owned_account_numbers(_username())
    form_data = {
        "from_account_number": owned_accounts[0] if owned_accounts else "",
        "to_account_number": "",
        "amount": "",
        "description": "",
    }

    if request.method == "POST":
        form_data = {k: request.form.get(k, "").strip() for k in form_data}
        if not all([form_data["from_account_number"], form_data["to_account_number"], form_data["amount"]]):
            flash("Vui lòng nhập đầy đủ tài khoản nguồn, đích và số tiền.", "warning")
            return render_template(
                "customer/transfer.html",
                form_data=form_data,
                owned_accounts=owned_accounts,
                user=_current_user(),
            )

        result = transaction_service.transfer(
            from_account_number=form_data["from_account_number"],
            to_account_number=form_data["to_account_number"],
            amount=form_data["amount"],
            description=form_data["description"],
            created_by_user_id=_username(),
        )
        flash(result["message"], "success" if result["success"] else "danger")
        if result["success"]:
            return redirect(url_for("customer.transactions"))
        return render_template(
            "customer/transfer.html",
            form_data=form_data,
            owned_accounts=owned_accounts,
            user=_current_user(),
        )

    return render_template(
        "customer/transfer.html",
        form_data=form_data,
        owned_accounts=owned_accounts,
        user=_current_user(),
    )
