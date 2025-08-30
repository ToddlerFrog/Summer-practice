require 'sinatra'
require 'sinatra/reloader' if development? # автоматическая перезагрузка кода
require 'sqlite3' # бд
require 'bcrypt' # хэш
require 'date'
require_relative './models/exposition'

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

# поиск по фильтру(м)

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
    results += search_authors(db, query)
    
  when 'exposition'
    results = search_expositions(db, query)
    
  when 'exhibit'
    results = search_exhibits(db, query)
  
  when 'author'
    results = search_authors(db, query)

  end
  
  results.uniq #избегание повторов
end

def search_expositions(db, query)
  db.execute <<-SQL, [query]
    SELECT e.id_exposition, e.name_exposition as title, 'exposition' as type, e.descreption, h.number_hall as hall, f.number_floor as floor
    FROM exposition e
    LEFT JOIN hall h ON e.id_hall = h.id_hall
    LEFT JOIN floor_museum f ON h.number_floor = f.number_floor
    WHERE LOWER(e.name_exposition) LIKE ?
  SQL
end

def search_exhibits(db, query)
  db.execute <<-SQL, [query, query]
    SELECT e.id_exhibit, e.name_exhibit as title, 'exhibit' as type, e.description, h.number_hall as hall, f.number_floor as floor, CONCAT(second_name , ' ' , first_name , ' ' , surname) as author_title
    FROM exhibit e
    LEFT JOIN hall h ON e.id_hall = h.id_hall
    LEFT JOIN floor_museum f ON h.number_floor = f.number_floor
    LEFT JOIN author a ON a.id_author = e.id_author
    WHERE LOWER(e.name_exhibit) LIKE ? OR LOWER(e.description) LIKE ?
  SQL
end

def search_authors(db, query)
  db.execute <<-SQL, [query, query]
    SELECT a.id_author, e.name_exhibit as title, 'author' as type, a.second_name, CONCAT(a.second_name , ' ' , a.first_name , ' ' , a.surname) as author_title, e.description, h.number_hall as hall, f.number_floor as floor
    FROM author a
    LEFT JOIN exhibit e ON e.id_author = a.id_author
    LEFT JOIN hall h ON e.id_hall = h.id_hall
    LEFT JOIN floor_museum f ON h.number_floor = f.number_floor
    WHERE LOWER(second_name) LIKE ? OR LOWER(title) LIKE ?
  SQL
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

# добавление экспозиции в бд

get '/exposition/new' do
  db = get_db
  @hall = db.execute("SELECT * FROM hall ORDER BY number_hall")
  @floor = db.execute("SELECT * FROM floor_museum ORDER BY number_floor")
  @exhibit = db.execute("SELECT * FROM exhibit ORDER BY name_exhibit")
  
  erb :new_exposition
end

# Обработка создания экспозиции
post '/exposition' do
  # # Преобразуем даты
  # begin
  #   start_date = Date.parse(params[:start_date]) if params[:start_date]
  #   end_date = Date.parse(params[:end_date]) if params[:end_date]
  # rescue ArgumentError
  #   # Обработка неверного формата даты
  # end

  start_date_ymd = params[:start_date].split("-").reverse.join("-")
  end_date_ymd = params[:end_date].split("-").reverse.join("-")

  exposition = Exposition.new(
    name_exposition: params[:name_exposition],
    descreption: params[:descreption],
    id_hall: params[:id_hall],
    number_floor: params[:number_floor],
    start_date: start_date_ymd,
    end_date:  end_date_ymd,
    photos: params[:photo] || [],
    id_exhibit: params[:exhibit] || []
  )

  db = get_db
  db.execute(
    "INSERT INTO exposition (name_exposition, descreption, id_hall) VALUES (?, ?, ?)",
    [exposition.name_exposition, exposition.descreption, exposition.id_hall]
    )
  new_id = db.last_insert_row_id

  if exposition.valid? && exposition.save
    redirect "/exposition/#{new_id}?success=1"
  else
    @errors = exposition.errors
    @params = params
    
    # Загружаем данные для формы
    db = get_db
    @hall = db.execute("SELECT * FROM hall ORDER BY number_hall")
    @floor = db.execute("SELECT * FROM floor_museum ORDER BY number_florr")
    @exhibit = db.execute("SELECT * FROM exhibit ORDER BY name_exhibit")
    
    erb :new_exposition
  end
end

# Страница просмотра экспозиции
get '/exposition/:id_exposition' do

  db = get_db
  @exposition = db.execute(<<-SQL, [params[:id_exposition]]).first
    SELECT e.*, es.start_date, es.end_date, es.id_status,
           h.number_hall as number_hall, f.number_floor as number_floor
    FROM exposition e
    LEFT JOIN status_exposition es ON e.id_exposition = es.id_exposition
    LEFT JOIN hall h ON e.id_hall = h.id_hall
    LEFT JOIN floor_museum f ON h.number_floor = f.number_floor
    WHERE e.id_exposition = ?
  SQL

  @photo = db.execute("SELECT * FROM photo_exposition WHERE id_exposition = ?", [params[:id_exposition]])
  @exhibit = db.execute(<<-SQL, [params[:id_exposition]])
    SELECT e.* 
    FROM exhibit e
    JOIN exhibit_in_exposition ee ON e.id_exhibit = ee.id_exhibit
    WHERE ee.id_exposition = ?
  SQL

  @success = params[:success]
  erb :exposition_detail
end



# Страница формы удаления
get '/delete_exposition' do
  erb :delete_exposition
end

# Обработка удаления
post '/delete_exposition' do
  db = get_db
  
  # Ищем экспозицию по ID и названию (для безопасности)
  exposition = db.execute(
    "SELECT * FROM exposition WHERE id_exposition = ? AND name_exposition = ?", 
    [params[:id_exposition], params[:name_exposition]]
  ).first

  if exposition
    begin
      # Удаляем связанные данные
      db.execute("DELETE FROM status_exposition WHERE id_exposition = ?", [params[:id_exposition]])
      db.execute("DELETE FROM exhibit_in_exposition WHERE id_exposition = ?", [params[:id_exposition]])
      db.execute("DELETE FROM photo_exposition WHERE id_exposition = ?", [params[:id_exposition]])
      
      # Удаляем саму экспозицию
      db.execute("DELETE FROM exposition WHERE id_exposition = ?", [params[:id_exposition]])
      
      @message = "✅ Exposition '#{params[:name_exposition]}' successfully deleted!"
      @success = true
      
    rescue SQLite3::Exception => e
      @error = "❌ Error: #{e.message}"
      @success = false
    end
  else
    @error = "❌ Exposition not founded. Check ID or name again."
    @success = false
  end

  erb :delete_exposition
end