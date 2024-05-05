from flask import Flask, render_template, url_for, redirect, send_from_directory, request, escape, jsonify, render_template_string
from flask_sqlalchemy import SQLAlchemy
from flask_login import UserMixin, login_user, LoginManager, login_required, logout_user, current_user
from flask_wtf import FlaskForm
from wtforms import StringField, PasswordField, SubmitField
from wtforms.validators import InputRequired, Length, ValidationError
from flask_bcrypt import Bcrypt
import json
import uuid

app = Flask(__name__)
app.config['SQLALCHEMY_DATABASE_URI'] = 'sqlite:///database.db'
app.config['SECRET_KEY'] = 'c20c7363-a410-4072-b45e-247599fb4c52'
db = SQLAlchemy(app)
bcrypt = Bcrypt(app)


login_manager = LoginManager()
login_manager.init_app(app)
login_manager.login_view = "login"

users_queue = []


@login_manager.user_loader
def load_user(user_id):
    return User.query.get(int(user_id))

class User(db.Model, UserMixin):
    id = db.Column(db.Integer, primary_key=True)
    username = db.Column(db.String(20), nullable=False, unique=True)
    password = db.Column(db.String(80), nullable=False)
    expenses = db.Column(db.String(10000), nullable=True, default="[{\"expense\":\"dinner\", \"cost\":\"50\", \"currency\": \"USD\"}]")
    status = db.Column(db.String(100), nullable=True, default="Not yet submitted")
    admin = db.Column(db.Boolean(), nullable=False, default=False)


class RegisterForm(FlaskForm):
    username = StringField(validators=[InputRequired(), Length(
        min=4, max=20)], render_kw={"placeholder": "Username"})

    password = PasswordField(validators=[InputRequired(), Length(
        min=4, max=20)], render_kw={"placeholder": "Password"})

    submit = SubmitField("Register")

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

    admin_user.session_token = ".eJwtjktqAzEQRO-itRfqltQfX2aQ-kOCIYEZe2V892iR5asqivcuR55xfZX783zFrRzfXu4FmmfF8DGl6wAb3KxT8mKtMIU3r7oiTQamV20xWBKEnL2S4-41MnMRJINwYkxH7kxLZwCozAZozdGqGhNmTwvvge5728sWeV1x_ttstOvM4_n7iJ8drJ6txjaZDSehTdjfnRggVZVtkchiGeXzB_diPz4.Zi2z4w.43JW_JRYjdx_uGhT9MAL7F2qMMY"


@app.route('/')
def home():
    return render_template('index.html')


@app.route('/dashboard', methods=['GET', 'POST'])
@login_required
def dashboard():
    return render_template('dashboard.html', table_data=json.loads(current_user.expenses), status=current_user.status)

@app.route('/admin', methods=['GET', 'POST'])
@login_required
def admin():
    if current_user.admin:
        if len(users_queue) > 0: 
            return render_template('admin.html', table_data=json.loads(load_user(users_queue[0][0]).expenses), popID=users_queue[0][1])
        else:
            return render_template('adminEmpty.html')
    else:
        return "Must be an admin to access this page", 403

@app.route('/login', methods=['GET', 'POST'])
def login():
    form = LoginForm()
    if form.validate_on_submit():
        user = User.query.filter_by(username=form.username.data).first()
        if user:
            if bcrypt.check_password_hash(user.password, form.password.data):
                login_user(user)
                if current_user.admin:
                    return redirect(url_for('admin'))
                return redirect(url_for('dashboard'))

    return render_template('login.html', form=form)

@app.route('/register', methods=['GET', 'POST'])
def register():
    form = RegisterForm()
    
    if form.validate_on_submit():
        hashed_password = bcrypt.generate_password_hash(password=form.password.data)
        new_user = User(username=form.username.data, password=hashed_password)
        db.session.add(new_user)
        db.session.commit()
        return redirect(url_for('login'))

    return render_template('register.html', form=form, error="" if request.method=="GET" else "The data submitted was invalid")

@app.route('/logout', methods=['GET', 'POST'])
@login_required
def logout():
    logout_user()
    return redirect(url_for('login'))

@app.route('/admin/<path:path>')
@login_required
def send_file(path):
    if not current_user.admin:
        return "Must be an admin to access that file", 403
    return send_from_directory('admin', path)

@app.route('/api/getExpenses', methods=['GET'])
@login_required
def get_expenses():
    return jsonify(current_user.expenses), 200

@app.route('/api/getStatus', methods=['GET'])
@login_required
def get_status():
    out = ""
    if current_user.status == "Accepted":
        out = "<div style=\"color:green;\">"+current_user.status+"</div>"
    elif current_user.status == "Denied":
        out = "<div style=\"color:red;\">"+current_user.status+"</div>"
    else:
        out = "<div>"+current_user.status+"</div>"

    return render_template_string(out)

@app.route('/api/updateExpenseStatus', methods=['POST'])
@login_required
def update_expense_status():
    if current_user.admin:
        if len(users_queue) > 0:
            if users_queue[0][1] == request.json["popID"]:
                user = load_user(users_queue.pop(0)[0])
                user.status = request.json["status"]

                db.session.commit()
                return "Looks good", 200
            else:
                return "Invalid popID", 400
        else:
            return "No pending requests", 400
    else: 
        return "Must be an admin to access this page", 403

@app.route('/api/addToQueue', methods=['POST'])
@login_required
def add_to_queue():
    
    for user in users_queue:
        if user[0] == current_user.id:
            return "Current user already in list", 200

    users_queue.append((current_user.id, str(uuid.uuid4())))
    current_user.status = "Pending"

    db.session.commit()
    return "Looks good", 200

@app.route('/api/saveExpenses', methods=['POST'])
@login_required
def save_expenses():
    for expense in request.json:
        if len(expense["expense"]) > 50:
            return "Expense names must be less than 50 characters long", 400
        expense["expense"] = escape(expense["expense"])

        if not expense["cost"].replace('.', '', 1).isdigit():
            return "Expense costs must be a number", 400

        if len(expense["currency"]) > 10:
            return "Expense currency must be less than or equal to 10 characters", 400

    
    current_user.expenses = json.dumps(request.json)
    current_user.status = "Updated"
    db.session.commit()

    return "Looks good", 200


if __name__ == '__main__':
    app.run(host='0.0.0.0', debug=True)
