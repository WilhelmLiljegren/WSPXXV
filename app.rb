require 'sinatra'
require 'slim'
require 'sqlite3'
require 'sinatra/reloader'
require 'bcrypt'

enable :sessions
$current_user = [nil, nil]

get('/') do
    puts "Received request for root path '/'"
    if !logged_in?
        puts "No user logged in, redirecting to login page"
        redirect('/login')
    end
     query=params[:q]

      db=SQLite3::Database.new("./db/database.db")
      db.results_as_hash = true
      @stories=db.execute("SELECT * FROM story WHERE headline LIKE ?",
      ["%#{query}%"])
       
    slim(:main)
end

get('/about') do
    slim(:about)
end

get('/debug') do
  db = SQLite3::Database.new("./db/database .db")
  db.results_as_hash = true
  db.execute("SELECT name FROM sqlite_master WHERE type='table'").inspect
end


def logged_in?
  !!session[:username]
end

get ('/login') do
  slim (:login)
end

post('/login') do
    username = params[:username]
    password = params[:password]
    puts "Received login_user attempt with username: #{username} and password: #{password}"
    if login(username, password)
      session[:username] = username
      puts "User #{username} logged in successfully"
      redirect('/')
    else
      @error = "Invalid username or password"
      puts "User #{ username} failed to log in"  
      slim(:login)
    end
end

post('/logout') do
    session.clear
    redirect('/login')
end

get ('/sign_up') do 
    slim :sign_up
end

post('/sign_up') do
    username = params[:username]
    password = params[:password]
    puts "Received create_user attempt with username: #{username} and password: #{password}"
    if create_user(username, password)
        @success = "User created successfully! Please log in."
        puts "User #{username} created successfully"
        slim(:sign_up)
    else
        @error = "Username already exists or user is already logged in"
        puts "Failed to create user #{username}"
        slim(:sign_up)
    end
end

# post('/store') do
#     session[:username] = params[:username]
#     # redirect('/')
# end

    get('/new_story') do
    slim(:new_story)
    end

    post('/new_story') do
        headline = params[:headline]
        content = params[:content]
        user_id = $current_user[1]
        puts "Received new story submission with headline: #{headline}, content: #{content}, user_id: #{user_id}"
            db = SQLite3::Database.new('db/database.db')
            db.execute("INSERT INTO story (headline, content, user_id) VALUES (?,?,?)", [headline, content, user_id])
            redirect(:story)
    end

    def login(username, password)
        puts "username = #{username}, password = #{password}"
        db = SQLite3::Database.new('db/database.db')
        db.results_as_hash = true
        result = db.execute('SELECT * FROM users WHERE username = ?', [username])
        puts "Database query result: #{result.inspect} for username: #{username}"
        if result.empty?
            session.clear
            return false
        else
            password_digest = result.first['pwd']
            userid = result.first['user_id'].to_i
            $current_user = [username, userid]
            puts "Set $current_user to: #{$current_user.inspect} $current_user[0] = #{ $current_user[0]}, $current_user[1] = #{ $current_user[1]}"
            puts "Retrieved password digest from database: #{password_digest} for username: #{username}"
            return BCrypt::Password.new(password_digest) == password
        end
    end

    def create_user(username, password)
        if logged_in?
            puts "User #{username} is already logged in, cannot create a new user"
            return false
        end
        password_digest = BCrypt::Password.create(password)
        db = SQLite3::Database.new('db/database.db')
        db.results_as_hash = true
        begin
            db.execute('INSERT INTO users (username, pwd) VALUES (?, ?)', [username, password_digest])
            puts "User #{username} created successfully with password digest: #{password_digest}"
            return true
        rescue SQLite3::ConstraintException => e
            puts "Error creating user #{username}: #{e.message}"
            return false
        end
    end

    get('/story') do
        query = params[:q]
        puts "Received request to print stories with query: #{query}"
        db = SQLite3::Database.new('db/database.db')
        db.results_as_hash = true
        stories = db.execute('SELECT * FROM story')
        puts "Current stories in database: #{stories.inspect}"

        if query && !query.empty?
            @stories = db.execute("SELECT * FROM story WHERE headline LIKE ?", ["%#{query}%"])
            puts "Stories matching query '#{query}': #{@stories.inspect}"
        else
            @stories = db.execute("SELECT * FROM story")
            puts "No query provided, returning all stories: #{@stories.inspect}"
        end
        slim(:story)
    end
    
    post ('/new_story') do
        headline = params[:headline]
        content = params[:content]
        user_id = currentuser[1]
        puts "Received new story submission with headline: #{headline}, content: #{content}, user_id: #{user_id}"
        db = SQLite3::Database.new('db/database.db')
        db.results_as_hash = true
        begin
            db.execute("INSERT INTO story (headline, content, user_id) VALUES (?, ?, ?)", [headline, content, user_id])
            puts "New story created successfully with headline: #{headline}"
            redirect('/stories')
        rescue SQLite3::Exception => e
            puts "Error creating new story: #{e.message}"
            @error = "Failed to create story. Please try again."
            slim(:new_story)
        end
    end

    get('/vote') do
        story_id = params[:story_id]
        vote_value = params[:vote_value].to_i
        # if $current_user[0] == nil
        #     puts "No user logged in, cannot record vote"
        #     @error = "You must be logged in to vote"
        #     redirect('/stories')
        # end
        user_id = $current_user[1]
        p "#{$current_user[1]}"
        puts "Received vote with story_id: #{story_id}, vote_value: #{vote_value}, user_id: #{user_id}"
        db = SQLite3::Database.new('db/database.db')
        db.results_as_hash = true
        begin
            db.execute("INSERT INTO votes (user_id, story_id, value) VALUES (?, ?, ?) ON CONFLICT(user_id, story_id) DO UPDATE SET value = excluded.value", [user_id, story_id, vote_value])
            puts "Vote recorded successfully for story_id: #{story_id} with value: #{vote_value}"
            redirect('/stories')
        rescue SQLite3::Exception => e
            puts "Error recording vote: #{e.message}"
            @error = "Failed to record vote. Please try again."
            redirect('/stories')
        end
    end