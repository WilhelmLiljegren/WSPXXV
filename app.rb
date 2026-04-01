require 'sinatra'
require 'slim'
require 'sqlite3'
require 'sinatra/reloader'
require 'bcrypt'

enable :session

    get('/') do
      db=SQLite3::Database.new(".db")
     db.results_as_hash = true
  @stories=db.execute("SELECT * FROM story")
  p @stories
    end

    get('/welcome') do


    end


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
                redirect(:layout)
            else 
                @error = "Invalid username or password"
            end
        end
        slim(:login)
    end

    get('/new_story') do
    slim(:new_story)
    end

    post('/story') do
        new_story = params[:new_story]
        headline = params[:headline]
        content = params[:content]
        story_id = params[:story_id].to_i
        user_id = params[:user_id].to_i
            db = SQqlite3::Database.new('db/story.db') #???
            db.execute("INSERT INTO story (headline, content, story_id, user_id) VALUES (?,?,?,?)")
            redirect(:main)
    end

    get('/clear_session') do
        session.clear
        slim(:login)
    end