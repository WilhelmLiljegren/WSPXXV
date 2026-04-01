require 'sqlite3'

db = SQLite3::Database.new("databas.db")
db.results_as_hash = true
db.execute("PRAGMA foreign_keys = ON")

def seed!(db)
  puts "Using db file: db/wspxxv.db"
  puts "🧹 Dropping old tables..."
  drop_tables(db)
  puts "🧱 Creating tables..."
  create_tables(db)
  puts "🍎 Populating tables..."
  populate_tables(db)
  puts "✅ Done seeding the database!"
end

def drop_tables(db)
  db.execute('DROP TABLE IF EXISTS comments')
  db.execute('DROP TABLE IF EXISTS votes')
  db.execute('DROP TABLE IF EXISTS story')
  db.execute('DROP TABLE IF EXISTS users')
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
  story_id INTEGER PRIMARY KEY AUTOINCREMENT,
  headline TEXT NOT NULL,
  content TEXT NOT NULL, 
  user_id INTEGER NOT NULL,
  FOREIGN KEY (user_id) REFERENCES users(user_id) ON DELETE CASCADE
  );
SQL

  db.execute <<~SQL
  CREATE TABLE votes(
  user_id INTEGER NOT NULL,
  story_id INTEGER NOT NULL,
  value INTEGER NOT NULL,
  PRIMARY KEY (user_id, story_id)
  CHECK (value IN (1, -1)),
  FOREIGN KEY (user_id) REFERENCES users(user_id) ON DELETE CASCADE,
  FOREIGN KEY (story_id) REFERENCES stories(story_id) ON DELETE CASCADE
  );
SQL
  db.execute <<~SQL
  CREATE TABLE comments(
  user_id INTEGER NOT NULL,
  story_id INTEGER NOT NULL,
  PRIMARY KEY (user_id, story_id),
  FOREIGN KEY (user_id) REFERENCES users(user_id) ON DELETE CASCADE,
  FOREIGN KEY (story_id) REFERENCES story(story_id) ON DELETE CASCADE,
  comment TEXT
  );
SQL
create_indexes(db) # Fixa index för att optimera sökningar på user_id och story_id i votes och comments-tabellerna.
end

def create_indexes(db)
  db.execute("CREATE INDEX idx_stories_user_id ON stories(user_id)")
  db.execute("CREATE INDEX idx_votes_story_id ON votes(story_id)")
  db.execute("CREATE INDEX idx_comments_story_id ON comments(story_id)")
  db.execute("CREATE INDEX idx_comments_user_id ON comments(user_id)")
end

def populate_tables(db)
  db.execute('INSERT INTO users (username, pwd) VALUES ("User_X", "pwd X")')
  db.execute('INSERT INTO users (username, pwd) VALUES ("User_Y", "pwd Y")')
  db.execute('INSERT INTO users (username, pwd) VALUES ("User_Z", "pwd Z")')
end

db.execute(
  "INSERT OR REPLACE INTO votes (user_id, story_id, value) VALUES (?, ?, 1)",
  [user_id, story_id]
)
seed!(db)





