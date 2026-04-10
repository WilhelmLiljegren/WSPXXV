require 'sqlite3'
require 'bcrypt'

db = SQLite3::Database.new("database.db")
db.results_as_hash = true
db.execute("PRAGMA foreign_keys = ON")

def seed!(db)
  puts "Using db file: database.db"
  puts "🧹 Dropping old tables..."
  drop_tables(db)
  puts "🧱 Creating tables..."
  create_tables(db)
  puts "🍎 Populating tables..."
  populate_tables(db)
  populate_stories(db)
  puts "✅ Done seeding the database!"
end

def drop_tables(db)
  db.execute('DROP TABLE IF EXISTS users')
  db.execute('DROP TABLE IF EXISTS story')
  db.execute('DROP TABLE IF EXISTS votes')
  # db.execute('DROP TABLE IF EXISTS comments')
end

def create_tables(db)
  db.execute <<~SQL
  CREATE TABLE users (
              user_id INTEGER PRIMARY KEY AUTOINCREMENT,
              username TEXT NOT NULL UNIQUE, 
              pwd TEXT NOT NULL
              );
  SQL

  db.execute <<~SQL
  CREATE TABLE story (
  story_id INTEGER PRIMARY KEY,
  headline TEXT NOT NULL,
  content TEXT NOT NULL, 
  user_id INTEGER NOT NULL,
  FOREIGN KEY (user_id) REFERENCES users(user_id) ON DELETE CASCADE
  );
  SQL

  db.execute <<~SQL
  CREATE TABLE votes (
  user_id INTEGER NOT NULL,
  story_id INTEGER NOT NULL,
  value INTEGER NOT NULL,
  PRIMARY KEY (user_id, story_id),
  CHECK (value IN (1, -1)),
  FOREIGN KEY (user_id) REFERENCES users(user_id) ON DELETE CASCADE,
  FOREIGN KEY (story_id) REFERENCES story(story_id) ON DELETE CASCADE
  );
  SQL
  
  
  # db.execute <<~SQL
  # CREATE TABLE comments(
    # user_id INTEGER NOT NULL,
    # story_id INTEGER NOT NULL,
    # PRIMARY KEY (user_id, story_id),
    # FOREIGN KEY (user_id) REFERENCES users(user_id) ON DELETE CASCADE,
    # FOREIGN KEY (story_id) REFERENCES story(story_id) ON DELETE CASCADE,
    # comment TEXT
    # );
    # SQL
  end
  
# db.execute <<~SQL
#   INSERT INTO votes
#   user_id INTEGER NOT NULL,
#   story_id INTEGER NOT NULL,
#   value INTEGER NOT NULL,
#   " (user_id, story_id, value) VALUES (?, ?, ?)",
#     [user_id, story_id, 1]) # Example of an upvote

#     # create_indexes(db) # Fixa index för att optimera sökningar på user_id och 
# # story_id i votes och comments-tabellerna.

# db.execute("INSERT INTO votes (user_id, story_id, value) VALUES (?, ?, ?)", [1, 1, 1]) # User 1 upvotes Story 1
# db.execute("INSERT INTO votes (user_id, story_id, value) VALUES (?, ?, ?  )", [2, 1, -1]) # User 2 downvotes Story 1
# db.execute("INSERT INTO votes (user_id, story_id, value) VALUES (?, ?, ?)", [user_id, story_id, value]) # User 1 upvotes Story 2


def create_indexes(db)
  db.execute("CREATE INDEX idx_story_user_id ON story(user_id)")
  db.execute("CREATE INDEX idx_votes_story_id ON votes(story_id)")
  db.execute("CREATE INDEX idx_comments_story_id ON comments(story_id)")
  db.execute("CREATE INDEX idx_comments_user_id ON comments(user_id)")
end

def populate_tables(db)
  pwd_x_digest = BCrypt::Password.create("pwd_X")
  pwd_y_digest = BCrypt::Password.create("pwd_Y")
  pwd_z_digest = BCrypt::Password.create("pwd_Z")

  db.execute('INSERT INTO users (username, pwd) VALUES ("User_X", ?)', [pwd_x_digest])
  db.execute('INSERT INTO users (username, pwd) VALUES ("User_Y", ?)', [pwd_y_digest])
  db.execute('INSERT INTO users (username, pwd) VALUES ("User_Z", ?)', [pwd_z_digest])
end


def populate_stories(db)
  stories = [
  ["What is this","det var en gång och den var grusad", 1], 
  ["Banan", "Frukta frukten banan", 2], 
  ["Apelsin","Frukta frukten apelsen",3], 
  ["Päron","Frukta frukten päron",1]]

  stories.each do |st|
    db.execute("INSERT INTO story (headline, content, user_id) VALUES (?,?,?)", st)
  end
end

seed!(db)
