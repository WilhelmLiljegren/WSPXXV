require 'sqlite3'

db = SQLite3::Database.new("databas.db")


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
  db.execute('DROP TABLE IF EXISTS exempel')
end

def create_tables(db)
  db.execute('CREATE TABLE user (
              user_id INTEGER PRIMARY KEY AUTOINCREMENT,
              username TEXT NOT NULL, 
              pwd TEXT)')

  db.execute('CREATE TABLE story (
  headline TEXT NOT NULL, content TEXT NOT NULL, 
  story_id INTEGER PRIMARY KEY AUTOINCREMENT, 
  user_id INT, FOREIGN KEY (user_id) REFERENCES user(user_id) ON DELETE CASCADE)')

  db.execute ('CREATE TABLE votes(
  user_id INT,
  story_id INT,
  PRIMARY KEY (user_id, story_id)
  FOREIGN KEY (user_id) REFERENCES user(user_id)
  ON DELETE CASCADE,
  FOREIGN KEY (story_id) REFERENCES story(story_id)
  ON DELETE CASCADE
  upvote BOOLEAN,
  downvote BOOLEAN)') #Skapa en knapp

  db.execute ('CREATE TABLE comments(
  user_id INT,
  story_id INT,
  PRIMARY KEY (user_id, story_id)
  FOREIGN KEY (user_id) REFERENCES user(user_id)
  ON DELETE CASCADE,
  FOREIGN KEY (story_id) REFERENCES story(story_id)
  ON DELETE CASCADE
  comment TEXT)')
end

def populate_tables(db)
  db.execute('INSERT INTO user (username, pwd,) VALUES ("User_X", "pwd X")')
  db.execute('INSERT INTO user (username, pwd,) VALUES ("User_Y", "pwd Y")')
  db.execute('INSERT INTO user (username, pwd,) VALUES ("User_Z", "pwd Z")')
end

seed!(db)





