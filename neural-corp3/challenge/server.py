from flask import Flask, render_template, url_for, redirect, send_from_directory, request, escape, jsonify, render_template_string
from flask_sqlalchemy import SQLAlchemy
from flask_login import UserMixin, login_user, LoginManager, login_required, logout_user, current_user
from flask_wtf import FlaskForm
from flask_cors import CORS
from wtforms import StringField, PasswordField, SubmitField
from wtforms.validators import InputRequired, Length, ValidationError
from flask_bcrypt import Bcrypt
import json
import uuid
import random, time


app = Flask(__name__)
app.config['SQLALCHEMY_DATABASE_URI'] = 'sqlite:///database.db'
app.config['SECRET_KEY'] = 'd797c000-bccf-4e06-84e6-3245f6772648'
app.config['SESSION_COOKIE_SAMESITE'] = "None"
app.config['SESSION_COOKIE_SECURE'] = True
db = SQLAlchemy(app)
bcrypt = Bcrypt(app)
cors = CORS(app, resources={"/register": {"origins": "*", "supports_credentials": True}})

login_manager = LoginManager()
login_manager.init_app(app)
login_manager.login_view = "login"

links = []

@login_manager.user_loader
def load_user(user_id):
    return User.query.get(int(user_id))

class User(db.Model, UserMixin):
    id = db.Column(db.Integer, primary_key=True)
    username = db.Column(db.String(20), nullable=False, unique=True)
    password = db.Column(db.String(80), nullable=False)
    admin = db.Column(db.Boolean(), nullable=False, default=False)

class RegisterForm(FlaskForm):
    username = StringField(validators=[InputRequired(), Length(
        min=4, max=20)], render_kw={"placeholder": "Username"})

    password = PasswordField(validators=[InputRequired(), Length(
        min=4, max=20)], render_kw={"placeholder": "Password"})

    submit = SubmitField("Create")

    def validate_username(self, username):
        existing_user_username = User.query.filter_by(
                username=username.data).first()
        if existing_user_username:
            raise ValidationError(
                    "That username already exists. Please choose a different one.")

class LoginForm(FlaskForm):
    username = StringField(validators=[InputRequired(), Length(
        min=4, max=20)], render_kw={"placeholder": "Username"})

    password = PasswordField(validators=[InputRequired(), Length(
        min=4, max=20)], render_kw={"placeholder": "Password"})

    submit = SubmitField("Login")

@app.before_first_request
def initialize():
    admin_user = load_user('1')
    login_user(admin_user)

    admin_user.session_token = ".eJwtjs1qAzEMhF_F-ByK_2XnKXovYZEtKRuaZst6cwp59-rQ0_DNDNK87CJ3nCtPe_56WXOo2B-eE69sT_bzzjjZ3LeruT3MsRkcQ0NzrLdpfrXzYS_vy0mP7DxXez72JyvdyJ6tjyQuMGWsqWU_MsSRikCH5jxWUO6us4yag5BrkTNU8bUQkCsUNG8sIr14AV9BAiMFSFB6Q_a-VYw-jEhhuDagBEkymBIHIu0mnb88J-__axTH3GU5tm9-qEEYqmDRX4S9h1wkZecTgs8pluFLS0CtRPv-A0QyVng.Zi2gfg.du1c4_ZpDgr1gdko51FYhNIytnA" 

@app.route('/')
def home():
    return render_template("index.html")

@app.route('/link-submission', methods=["GET", "POST"])
def link_submission():
    if request.method == 'POST':
        links.insert(0, request.values.get("link"))
        print(links)

    return render_template("link-submission.html")

@app.route('/admin-panel')
@login_required
def admin_panel():
	if current_user.admin:
	    return render_template("admin_panel.html", urls=links[:5])
	else:
		return redirect(url_for("home"))

@app.route('/login', methods=['GET', 'POST'])
def login():
    form = LoginForm()
    if form.validate_on_submit():
        user = User.query.filter_by(username=form.username.data).first()
        if user:
            if bcrypt.check_password_hash(user.password, form.password.data):
                login_user(user)
                if current_user.admin:
                    return redirect(url_for('admin_panel'))
                return redirect(url_for('landing_page'))

    return render_template('login.html', form=form)

@app.route('/register', methods=["GET", "POST"])
@login_required
def register():
	if current_user.admin:
		form = RegisterForm()
		
		if form.validate_on_submit():
			hashed_password = bcrypt.generate_password_hash(password=form.password.data)
			new_user = User(username=form.username.data, password=hashed_password)
			db.session.add(new_user)
			db.session.commit()
			return redirect(url_for('login'))

		return render_template('registration.html', form=form, error="" if request.method=="GET" else "The data submitted was invalid")
	else:
		return redirect(url_for('admin_panel'))

@app.route('/landing-page')
@login_required
def landing_page():
	return render_template('landing_page.html')	

if __name__ == '__main__':
        app.run(host='0.0.0.0', debug=True)
