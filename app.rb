require 'sinatra'
require 'sinatra/reloader' if development? # автоматическая перезагрузка кода
require 'sqlite3' # бд
require 'bcrypt' # хэш
require 'date'

# Подключение к бд
DB = SQLite3::Database.new('museum.db')
DB.results_as_hash = true

# Включение сессий для отслеживания входа пользователей
enable :sessions

# Главная страница с поиском 
get '/' do
  @search_query = params[:query] || ''
  @search_category = params[:category] || 'all'
  if @search_query.empty?
    @results = []
  else
    @results = search_museum(@search_query, @search_category)
  end
  erb :index
end

# Страница регистрации
get '/register' do
  erb :register
end

# Обработка формы регистрации
post '/register' do
  email = params[:email].to_s.strip
  password = params[:password].to_s
  first_name = params[:first_name].to_s.strip
  second_name = params[:second_name].to_s.strip
  surname = params[:surname].to_s.strip
  birth_date = params[:birth_date].to_s

  # Валидация данных
  errors = []

  errors << "Email не может быть пустым" if email.empty?
  errors << "Пароль должен содержать не менее 6 символов" if password.length < 6
  errors << "Имя не может быть пустым" if first_name.empty?
  errors << "Фамилия не может быть пустой" if second_name.empty?
  errors << "Дата рождения не может быть пустой" if birth_date.empty?

  # Проверка формата почты
  unless email.empty?
    email_regex = /\A[\w+\-.]+@[a-z\d\-]+(\.[a-z]+)*\.[a-z]+\z/i
    errors << "Неверный формат email" unless email.match?(email_regex)
  end

  # Проверка отсутствия данного пользователя в бд
  unless email.empty?
    existing_user = DB.execute("SELECT id_visitor FROM visitor WHERE email = ?", [email]).first
    errors << "Пользователь с таким email уже существует" if existing_user
  end

  # Вывод ошибок
  if errors.any?
    session[:errors] = errors
    redirect '/register'
  end

  # Хеш пароля
  password_hash = BCrypt::Password.create(password)

  # Сохранение в бд
  begin
    DB.execute(
      "INSERT INTO visitor (email, password_account, first_name, second_name, surname, date_of_birth) 
       VALUES (?, ?, ?, ?, ?, ?)",
      [email, password_hash, first_name, second_name, surname, birth_date]
    )

    session[:success] = "Регистрация прошла успешно! Теперь вы можете войти."
    redirect '/'
  rescue SQLite3::Exception => e
    session[:errors] = ["Ошибка при сохранении данных: #{e.message}"]
    redirect '/register'
  end
end

# Страница входа 
get '/login' do
  erb :login
end

# Обработка входа
post '/login' do
  email = params[:email].to_s.strip
  password = params[:password].to_s

  user = DB.execute("SELECT * FROM visitor WHERE email = ?", [email]).first

  if user && BCrypt::Password.new(user['password_account']) == password
    session[:user_id] = user['id']
    session[:success] = "Добро пожаловать, #{user['first_name']}!"
    redirect '/'
  else
    session[:errors] = ["Неверный email или пароль"]
    redirect '/login'
  end
end

# Выход
get '/logout' do
  session.clear
  redirect '/'
end







def get_db
  SQLite3::Database.new 'museum.db'
end



# Поиск по музею
def search_museum(query, category)
  db = get_db
  query = "%#{query.downcase}%"
  
  results = []
  
  case category
  when 'all'
    results += search_expositions(db, query)
    results += search_exhibits(db, query)
    results += search_halls(db, query)
    results += search_authors(db, query)
    
  when 'expositions'
    results = search_expositions(db, query)
    
  when 'exhibits'
    results = search_exhibits(db, query)
  
  when 'authors'
    results = search_authors(db, query)
    
  when 'halls'
    results = search_halls(db, query)
  end
  
  results.uniq #избегание повторов
end

def search_expositions(db, query)
  db.execute <<-SQL, [query]
    SELECT e.id_exposition, e.name_exposition as title, 'exposition' as type, h.number_hall as hall, f.number_floor as floor
    FROM exposition e
    LEFT JOIN hall h ON e.id_hall = h.id_hall
    LEFT JOIN floor_museum f ON h.number_floor = f.number_floor
    WHERE LOWER(e.name_exposition) LIKE ?
  SQL
end

def search_exhibits(db, query)
  db.execute <<-SQL, [query, query]
    SELECT e.id_exhibit, e.name_exhibit as title, 'exhibit' as type, e.description, h.number_hall as hall, f.number_floor as floor
    FROM exhibit e
    LEFT JOIN hall h ON e.id_hall = h.id_hall
    LEFT JOIN floor_museum f ON h.number_floor = f.number_floor
    WHERE LOWER(e.name_exhibit) LIKE ? OR LOWER(e.description) LIKE ?
  SQL
end

def search_authors(db, query)
  db.execute <<-SQL, [query]
    SELECT id_author, second_name + ' ' + first_name + ' ' + surname as title, 'author' as type, '' as hall, '' as floor
    FROM author 
    WHERE LOWER(title) LIKE ?
  SQL
end

def search_halls(db, query)
  db.execute <<-SQL, [query, query]
    SELECT h.id_hall, h.name_hall as title, 'hall' as type, f.name_floor as floor, '' as author
    FROM hall h
    LEFT JOIN floor_museum f ON h.number_floor = f.number_floor
    WHERE LOWER(h.name_hall) LIKE ? OR LOWER(f.name_floor) LIKE ?
  SQL
end

#Страница деталей экспозиции
get '/exposition/:id' do
  db = get_db
  @exposition = db.execute <<-SQL, [params[:id]]
    SELECT e.*, h.name as hall_name, f.name as floor_name
    FROM exposition e
    LEFT JOIN hall h ON e.id_hall = h.id_hall
    LEFT JOIN floor_museum f ON h.number_floor = f.number_floor
    WHERE e.id_exposition = ?
  SQL
  
  @photos = db.execute("SELECT photo FROM photo_exposition WHERE id_exposition = ?", [params[:id]])
  
  erb :exposition_detail
end

# Страница деталей экспоната
get '/exhibit/:id' do
  db = get_db
  @exhibit = db.execute <<-SQL, [params[:id]]
    SELECT e.*, h.name_hall as hall_name, f.name_floor as floor_name
    FROM exhibit e
    LEFT JOIN hall h ON e.id_hall = h.id_hall
    LEFT JOIN floor f ON h.number_floor = f.number_floor
    WHERE e.id_exhibit = ?
  SQL
  
  @photos = db.execute("SELECT photo FROM photo_exhibit WHERE id_exhibit = ?", [params[:id]])
  
  erb :exhibit_detail
end

# API для быстрого поиска (AJAX)
get '/api/search' do
  content_type :json
  query = params[:q] || ''
  category = params[:category] || 'all'
  
  if query.empty?
    { results: [] }.to_json
  else
    results = search_museum(query, category)
    { results: results }.to_json
  end
end