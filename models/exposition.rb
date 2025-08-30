class Exposition
  attr_accessor :id_exposition, :name_exposition, :descreption, :id_hall, :number_floor, 
                :start_date, :end_date, :photo, :id_exhibit

  def initialize(attributes = {})
    @name_exposition = attributes[:name_exposition] || ''
    @descreption = attributes[:descreption] || ''
    @id_hall = attributes[:id_hall]
    @number_floor = attributes[:number_floor]
    @start_date = attributes[:start_date]
    @end_date = attributes[:end_date]
    @photo = attributes[:photo] || []
    @id_exhibit = attributes[:id_exhibit] || []
  end

# exposition = Exposition.new(
#     name_exposition: params[:name_exposition],
#     descreption: params[:descreption],
#     id_hall: params[:id_hall],
#     start_date: start_date,
#     end_date: end_date,
#     id_exhibit: params[:exhibit] || []
#   )

  def valid?
    errors.empty?
  end

  def errors
    errors = []
    errors << "Название обязательно" if @name_exposition.to_s.strip.empty?
    errors << "Описание обязательно" if @descreption.to_s.strip.empty?
    errors << "Зал должен быть выбран" if @id_hall.nil?
    errors << "Дата начала должна быть указана" if @start_date.to_s.strip.empty?
    errors << "Дата окончания должна быть указана" if @end_date.to_s.strip.empty?
    errors << "Дата окончания должна быть после даты начала" if valid_dates? && @end_date < @start_date
    errors
  end

  def save
    return false unless valid?
    
    db = SQLite3::Database.new 'museum.db'
    
    db.transaction do
      # Сохраняем основную информацию
      db.execute(
        "INSERT INTO exposition (name_exposition, descreption, id_hall) VALUES (?, ?, ?)",
        [@name_exposition, @descreption, @id_hall]
      )
      
      @id_exposition = db.last_insert_row_id
      
      # Сохраняем даты
      db.execute(
        "INSERT INTO status_exposition (id_exposition, start_date, end_date) VALUES (?, ?, ?)",
        [@id_exposition, @start_date, @end_date]
      )
      
      # Сохраняем экспонаты
      @id_exhibit.each do |id_exhibit|
        db.execute(
          "INSERT INTO exhibit_in_exposition (id_exposition, id_exhibit) VALUES (?, ?)",
          [@id_exposition, id_exhibit]
        )
      end
      
      # Сохраняем фото (упрощенно)
      @photo.each do |photo|
        db.execute(
          "INSERT INTO photo_exposition (id_exposition, photo) VALUES (?, ?)",
          [@id_exposition, photo]
        )
      end
    end
    
    true
  rescue SQLite3::Exception => e
    puts "Ошибка сохранения: #{e.message}"
    false
  end

  private

  def valid_dates?
    @start_date && @end_date && @start_date.is_a?(Date) && @end_date.is_a?(Date)
  end
end