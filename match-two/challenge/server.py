import random
import enum
from werkzeug.middleware import proxy_fix
from flask import Flask, render_template, request, redirect, flash
from flask_csp.csp import csp_header

# Form related
from flask_wtf import FlaskForm, CSRFProtect
from wtforms import StringField, PasswordField, SubmitField, TextAreaField
from wtforms.validators import DataRequired, EqualTo, ValidationError, Regexp, Length
from flask_wtf.csrf import CSRFError


# Login/Registration related
from flask_login import UserMixin, logout_user, login_user, LoginManager, login_required, current_user
from werkzeug.security import generate_password_hash, check_password_hash

# Backend
from flask_sqlalchemy import SQLAlchemy
from sqlalchemy import delete
from sqlalchemy.orm import relationship
from sqlalchemy.exc import InterfaceError

# Card related
from random import shuffle
import numpy
import base64

# Flask App initialization
app = Flask(__name__)
app.wsgi_app = proxy_fix.ProxyFix(app.wsgi_app)

# Flask_login initialization
login_manager = LoginManager()
login_manager.init_app(app)


# Secret key, also used for CSRF token
app.secret_key = b'98234a09fjd8184fef6!'
csrf = CSRFProtect(app)

# Database setup
app.config["SQLALCHEMY_DATABASE_URI"] = "sqlite:///database.sqlite"
db = SQLAlchemy(app)

# Game state 
class StateType(enum.Enum):
    VALID = 0
    INVALID = 1

# User model 
class User(db.Model, UserMixin):
    __tablename__ = 'user'
    id = db.Column(db.Integer, primary_key=True, index=True)
    username = db.Column(db.String(50), nullable=False, unique=True)
    password_hash = db.Column(db.String(255), nullable=False)
    game_state =  db.Column(db.Enum(StateType), nullable=False,
                      default=StateType.VALID)

    def change_state(self, state):
        self.game_state = state

    def set_password(self, password):
        self.password_hash = generate_password_hash(password)

    def check_password(self, password):
        return check_password_hash(self.password_hash, password)

    def __repr__(self):
        return self.username

# Card model
class Card(db.Model):
    __tablename__ = 'cards'
    id = db.Column(db.Integer, primary_key=True)
    value = db.Column(db.Integer)
    first = db.Column(db.Integer)
    second = db.Column(db.Integer)
    match = db.Column(db.Boolean)
    user_id = (db.Column(db.Integer, db.ForeignKey('user.id'), nullable=False))

with app.app_context():
    db.create_all()

# Forms used by the application


class LoginForm(FlaskForm):
    class Meta:
        csrf = False
    username = StringField('Username', validators=[DataRequired(), Regexp(
        '^\w+$', message="Username must be AlphaNumeric")])
    password = PasswordField('Password', validators=[DataRequired()])
    submit = SubmitField('Login')


class RegistrationForm(FlaskForm):
    class Meta:
        csrf = False
    username = StringField('Username', validators=[DataRequired(), Regexp(
        '^\w+$', message="Username must be AlphaNumeric")])
    # email = StringField('Email Address', validators=[DataRequired(), Email()])
    password = PasswordField('New Password',
                             validators=[DataRequired()])
    confirm = PasswordField('Repeat Password', validators=[
                            DataRequired(), EqualTo('password', message='Passwords must match')])
    submit = SubmitField('Register')

    def validate_username(self, username):
        user = User.query.filter_by(username=username.data).first()
        if user is not None:
            raise ValidationError('Please use a different username.')

# Application routes

# Login


@app.route('/')
@app.route('/login', methods=['GET', 'POST'])
@csrf.exempt
@csp_header({'default-src': "'self'", 'style-src-elem': "'self' https://fonts.googleapis.com", 'font-src': "https://fonts.gstatic.com"})
def login():
    form = LoginForm()
    if request.method == 'POST':
        if form.validate_on_submit():
            user = User.query.filter_by(username=form.username.data).first()
            if user is None or not user.check_password(form.password.data):
                flash('Invalid username or password', 'error')
                return redirect('/login')
            login_user(user)
            return redirect('/home')
    return render_template('login.html', form=form)

# Registration


@app.route('/register', methods=['GET', 'POST'])
@csp_header({'default-src': "'self'", 'style-src-elem': "'self' https://fonts.googleapis.com", 'font-src': "https://fonts.gstatic.com"})
@csrf.exempt
def register():
    form = RegistrationForm()
    if form.validate_on_submit():
        user = User(username=form.username.data)
        user.set_password(form.password.data)
        db.session.add(user)
        db.session.commit()
        flash('Thanks for registering')
        return redirect('/login')
    return render_template('register.html', form=form)


# Home page
@login_required
@app.route('/home', methods=['GET'])
@csp_header({'default-src': "'self'", 'style-src-elem': "'self' https://fonts.googleapis.com", 'font-src': "https://fonts.gstatic.com", 'img-src': "'self' data:"})
def home():
    msg = ""
    if 'msg' in request.args:
        msg = request.args.get('msg')
    resetCards()
    shuffleCards()
    return render_template('home.html', user=current_user, msg=msg, n=17)


@login_required
@app.route('/match', methods=['GET'])
@csp_header({'default-src': "'self'", 'style-src-elem': "'self' https://fonts.googleapis.com", 'font-src': "https://fonts.gstatic.com"})
def home_match():
   userCards = []
   data = {}
   firstPos = request.args.get('first_pos')
   secondPos = request.args.get('second_pos')
   try:
        userCards.append(int(firstPos))
        userCards.append(int(secondPos))
        data = matchCheck(sorted(userCards))
   except ValueError:
        notMatch()
        return "Only Integers allowed", 403
   if data["state"] == 0:
        notMatch()
        return data, 200
   elif firstPos == secondPos:
        return data, 200
   return data, 200

# Flag
@login_required
@app.route('/flag', methods=['GET'])
def flag():
    flagStr = 'CTF{svg-0n-th3-f1y}'
    user = User.query.filter_by(id=current_user.id).one_or_none()
    cards = Card.query.filter_by(user_id=current_user.id)
    error = "You got some pairs wrong, reset the game and try again!"
    if user.game_state == StateType.VALID:
        solve = 0
        for card in cards:
            if card.match:
                solve = solve + 1
        if solve == 8:
            return render_template('flag.html', flag=flagStr)
    return render_template('error.html', error=error)

# Logout
@app.route('/logout', methods=['GET'])
def logout():
    logout_user()
    return redirect('/login')


# Shuffle Cards
def shuffleCards():
    cards = [1, 2 ,3, 4, 5, 6, 7, 8]
    cardPairs = cards * 2 
    shuffle(cardPairs)
    cardArray = numpy.array(cardPairs)
    for card in cards:
        positions = numpy.where(cardArray == card)
        # Return match as array([X, Y])
        newCard = Card(user_id=current_user.id, value=card, first=int(positions[0][0]), second=int(positions[0][1]), match=False)
        db.session.add(newCard)
    db.session.commit()
    return cardPairs

# Reset Cards 
def resetCards():
    user = User.query.filter_by(id=current_user.id).one_or_none()
    user.change_state(StateType.VALID)
    # If a card exists for the user, delete it
    card = Card.query.filter_by(user_id=current_user.id).first()
    if card is not None:
        sql = delete(Card).where(Card.user_id == current_user.id)
        db.session.execute(sql)
        db.session.commit()

# Match related helpers 
# When a user has an incorrect match, set game state to invalid
def notMatch():
    user = User.query.filter_by(id=current_user.id).one_or_none()
    user.change_state(StateType.INVALID)
    db.session.commit()

# Fetch the SVG for the two cards and determine if their values match 
def matchCheck(userCards):
    data = {"state":0, "first_svgdata":"","second_svgdata":""}
    if userCards[0] == userCards[1]:
        data["state"] = -1
    card = Card.query.filter((Card.user_id == current_user.id) & (Card.first == userCards[0]) & (Card.second == userCards[1])).one_or_none()
    if card:
        card.match = True
        db.session.commit()
        data["state"] = 1
        data["first_svgdata"] = data["second_svgdata"] = getImg(card.value)
    else:
        first_card = Card.query.filter((Card.user_id == current_user.id) & ((Card.first == userCards[0]) | (Card.second == userCards[0]))).one_or_none()
        if first_card:
            data["first_svgdata"] = getImg(first_card.value)
        second_card = Card.query.filter((Card.user_id == current_user.id) & ((Card.first == userCards[1]) | (Card.second == userCards[1]))).one_or_none()
        if second_card:
            data["second_svgdata"] = getImg(second_card.value) 
    return data

# Read the image and base64 encode it 
def getImg(value):
    encoded_img = ""
    try:
        filepath = str(value) + ".svg"
        with open(filepath, "rb") as file:
            img = file.read()
    except FileNotFoundError:
        raise FileNotFoundError(f"File not found: {filepath}")
    encoded_img = base64.b64encode(img).decode("utf-8")
    print(encoded_img)
    return encoded_img

# Helper functions
@login_manager.user_loader
def load_user(id):
    return db.session.get(User, id)


@app.errorhandler(CSRFError)
def handle_csrf_error(e):
    return render_template('error.html', error=e.description), 400


app.run(host='0.0.0.0', port=8000)
app._static_folder = ''
