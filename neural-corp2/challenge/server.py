from flask import Flask, render_template, url_for, redirect, send_from_directory, request, escape, jsonify, render_template_string
from flask_sqlalchemy import SQLAlchemy
from flask_login import UserMixin, login_user, LoginManager, login_required, logout_user, current_user
from flask_wtf import FlaskForm
from wtforms import StringField, PasswordField, SubmitField
from wtforms.validators import InputRequired, Length, ValidationError
from flask_bcrypt import Bcrypt
import json
import uuid
import random, time


app = Flask(__name__)
app.config['SQLALCHEMY_DATABASE_URI'] = 'sqlite:///database.db'
app.config['SECRET_KEY'] = '1997a33a-46e3-49e6-841b-d41a9176e4e4'
app.config['SESSION_COOKIE_SAMESITE'] = "None"
app.config['SESSION_COOKIE_SECURE'] = True
db = SQLAlchemy(app)
bcrypt = Bcrypt(app)

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
class LoginForm(FlaskForm):
	username = StringField(validators=[InputRequired(), Length(
		min=4, max=20)], render_kw={"placeholder": "Username"})

	password = PasswordField(validators=[InputRequired(), Length(
		min=4, max=20)], render_kw={"placeholder": "Password"})

	submit = SubmitField("Login")


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
		rd = random.Random()
		rd.seed(int(time.time()/300))
		fiveMinToken = rd.getrandbits(128)
		rd.seed(int(time.time()/600))
		tenMinToken = rd.getrandbits(128)
		if request.method == "GET":
			return render_template('registration.html', token = fiveMinToken)
		if int(request.values.get("token")) != fiveMinToken and int(request.values.get("token")) != tenMinToken:
			return "Invalid token", 400
	
		if User.query.filter_by(username=request.values.get("username")).first():
			return render_template('registration.html')	
	
		hashed_password = bcrypt.generate_password_hash(password=request.values.get("password"))
		new_user = User(username=request.values.get("username"), password=hashed_password)
		db.session.add(new_user)
		db.session.commit()
		return redirect(url_for('admin_panel'))
	else:
		return redirect(url_for('login'))

@app.route('/landing-page')
@login_required
def landing_page():
	return render_template('landing_page.html')	

if __name__ == '__main__':
		app.run(host='0.0.0.0', debug=True)
