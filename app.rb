require 'sinatra'
require 'slim'
require 'sqlite3'
require 'sinatra/reloader'
require 'bcrypt'
require 'json'

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
        if login(username, password)
            puts "User #{username} logged in successfully after sign up"
            redirect('/')
        else
            @error = "Failed to log in after sign up"
            redirect('/login')
        end
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
        if !logged_in? # Ensure the user is logged in before allowing story creation
          redirect('/login')
        end
        slim(:new_story)
    end

    post('/new_story') do
        if !logged_in? # Ensure the user is logged in before allowing story creation
        redirect('/login')
        end
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
        logged_in_check # Ensure the user is logged in before allowing access to stories
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
        logged_in_check # Ensure the user is logged in before allowing story creation
        headline = params[:headline]
        content = params[:content]
        user_id = currentuser[1]
        puts "Received new story submission with headline: #{headline}, content: #{content}, user_id: #{user_id}"
        db = SQLite3::Database.new('db/database.db')
        db.results_as_hash = true
        begin
            db.execute("INSERT INTO story (headline, content, user_id) VALUES (?, ?, ?)", [headline, content, user_id])
            puts "New story created successfully with headline: #{headline}"
            id = db.execute("SELECT story_id FROM story WHERE headline LIKE ?", [st[0]]).first['story_id']
            db.execute("INSERT INTO votes (story_id, user_id, value) VALUES (?,?,?)", [id, 0, 0])
            redirect('/stories')
        rescue SQLite3::Exception => e
            puts "Error creating new story: #{e.message}"
            @error = "Failed to create story. Please try again."
            slim(:new_story)
        end
    end

    get('/vote') do
        logged_in_check
        # story_id = params[:story_id]
        # vote_value = params[:vote_value].to_i
        user_id = $current_user[1]
        p "user_id- #{$current_user[1]}"
        # puts "Received vote with story_id: #{story_id}, vote_value: #{vote_value}, user_id: #{user_id}"
        db = SQLite3::Database.new('db/database.db')
        db.results_as_hash = true
        @stories = db.execute('SELECT * FROM story')
        @votes = db.execute('SELECT * FROM votes')

        puts "Current votes in database: #{@votes.inspect}"
        slim(:vote)
    end
        # begin
        #     db.execute("INSERT INTO votes (user_id, story_id, value) VALUES (?, ?, ?) ON CONFLICT(user_id, story_id) DO UPDATE SET value = excluded.value", [user_id, story_id, vote_value])
        #     puts "Vote recorded successfully for story_id: #{story_id} with value: #{vote_value}"
        #     redirect('/stories')
        # rescue SQLite3::Exception => e
        #     puts "Error recording vote: #{e.message}"
        #     @error = "Failed to record vote. Please try again."
        #     redirect('/stories')
        # end
    # end

    def logged_in_check
        if !logged_in?
            puts "No user logged in, redirecting to login page"
            redirect('/login')
        end
        
    end

    post('/vote/:story_id/upvote') do
        p "Received upvote for story_id: #{params[:story_id]}"
        db = SQLite3::Database.new('db/database.db')
        db.results_as_hash = true
        begin
          row = db.get_first_row("SELECT user_id FROM votes WHERE story_id = ?", [params[:story_id]])
          if(!(row.values[0].count($current_user[1].to_s) > 0))
            usr_ids = row.values ? row.values : [] # Convert the string of user_ids to an array, or initialize an empty array if it's nil
            usr_ids.delete('0') # Remove the default '0' value if it exists
            usr_ids << $current_user[1] # Add the current user's ID to the array
            db.execute("UPDATE votes SET user_id = ? WHERE story_id = ?", [usr_ids.join(","), params[:story_id]])
            db.execute("UPDATE votes SET value = value + 1 WHERE story_id = ?", [params[:story_id]])
          else
            p "User has already voted on this story, skipping vote update"
          end
        rescue SQLite3::Exception => e
          puts "Error updating vote: #{e.message}"
        end
        
        redirect "/vote"
    end

    post('/my_vote/:story_id/downvote') do
        p "Received downvote for story_id: #{params[:story_id]}"
        db = SQLite3::Database.new('db/database.db')
        db.results_as_hash = true
        begin
          row = db.get_first_row("SELECT user_id FROM votes WHERE story_id = ?", [params[:story_id]])
          if(!(row.values[0].count($current_user[1].to_s) > 0))
            usr_ids = row.values ? row.values : [] # Convert the string of user_ids to an array, or initialize an empty array if it's nil
            usr_ids.delete('0') # Remove the default '0' value if it exists
            usr_ids << $current_user[1] # Add the current user's ID to the array
            db.execute("UPDATE votes SET user_id = ? WHERE story_id = ?", [usr_ids.join(","), params[:story_id]])
            db.execute("UPDATE votes SET value = value - 1 WHERE story_id = ?", [params[:story_id]])
          else
            p "User has already voted on this story, skipping vote update"
          end
        rescue SQLite3::Exception => e
          puts "Error updating vote: #{e.message}"
        end
        redirect "/vote"
    end