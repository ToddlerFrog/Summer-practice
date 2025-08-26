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

# Главная страница
get '/' do
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
