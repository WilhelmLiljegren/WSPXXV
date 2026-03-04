require 'sinatra'
require 'slim'
require 'sqlite3'
require 'sinatra/reloader'
require 'bcrypt'

enable :session

get('/login') do
    username = params ["username"]
    password = params ["password"]
    password_confirmation = params ["password_confirmation"]
    result = db.execute('SELECT * FROM user WHERE username = ?', [username])
    
    if result.empty?
        if password == password_confirmation
            password_digest = BCrypt::Password.create(password)
            p password_digest
            db.execute("INSERT INTO  user(username, pwd) VALUES (?,?)", [username, password_digest])
        else 
            set_error ... -->
    slim(:login)
    end
