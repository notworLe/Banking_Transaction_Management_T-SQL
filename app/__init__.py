from flask import Flask

from app.config import Config


def create_app(config_class=Config):
    app = Flask(__name__)
    app.config.from_object(config_class)

    from app.routes.auth import auth_bp
    from app.routes.admin import admin_bp
    from app.routes.banker import banker_bp
    from app.routes.customer import customer_bp

    app.register_blueprint(auth_bp)
    app.register_blueprint(admin_bp, url_prefix="/admin")
    app.register_blueprint(banker_bp, url_prefix="/banker")
    app.register_blueprint(customer_bp, url_prefix="/customer")

    @app.route("/")
    def index():
        from flask import redirect, url_for

        return redirect(url_for("auth.login"))

    return app
