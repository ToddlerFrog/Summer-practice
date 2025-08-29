create table if not exists visitor
(
 id_visitor integer,
 email text not null,
 password_account text not null,
 first_name text not null,
 second_name text not null,
 surname text,
 date_of_birth date not null,
 primary key (id_visitor),
 check(date_of_birth <= current_date)
);

create table if not exists ticket
(
 number_ticket integer,
 id_visitor text not null,
 cost_ticket money not null,
 date_visit date not null,
 id_benefits integer,
 primary key (number_ticket),
 check(date_visit >= current_date)
);

create table if not exists benefits
(
 id_benefits integer,
 name_benefits text not null,
 primary key (id_benefits) 
);

create table if not exists exhibit 
(
 id_exhibit integer,
 name_exhibit text not null, 
 description text not null,
 id_author integer,
 id_hall integer not null,
 primary key (id_exhibit)
);

create table if not exists photo_exhibit
( 
 id_exhibit integer,
 id_photo integer,
 photo text not null,
 primary key (id_exhibit, id_photo)
);

create table if not exists author
( 
 id_author integer,
 first_name text not null,
 second_name text not null,
 surname text,
 primary key (id_author)
);

create table if not exists author_exhibit
( 
 id_exhibit integer,
 id_author integer,
 primary key (id_exhibit, id_author)
);

create table if not exists exposition
( 
 id_exposition integer,
 name_exposition text not null,
 descreption text not null,
 id_hall integer not null,
 primary key (id_exposition)
);

create table if not exists photo_exposition
( 
 id_exposition integer,
 id_photo integer,
 photo text not null,
 primary key (id_exposition, id_photo)
);

create table if not exists exhibit_in_exposition
( 
 id_exposition integer,
 id_exhibit integer,
 primary key (id_exposition, id_exhibit)
);

create table if not exists hall
( 
 id_hall integer,
 number_hall integer not null,
 name_hall text,
 number_floor integer not null,
 primary key (id_hall)
);

create table if not exists floor_museum
( 
 number_floor integer, 
 name_floor text,
 primary key (number_floor)
);

create table if not exists change_log
( 
 id_change integer,
 id_exposition integer not null,
 before_change text not null,
 next_change text not null,
 date_change date not null,
 id_admin integer not null,
 reason text not null,
 primary key (id_change)
);

create table if not exists administrator 
( 
 id_admin integer,
 first_name text not null,
 second_name text not null,
 surname text,
 id_category integer not null,
 confirmation_code integer not null,
 primary key (id_admin)
);

create table if not exists category 
( 
 id_category integer,
 name_category text not null,
 primary key (id_category)
);

create table if not exists status_exposition 
( 
 id_exposition integer,
 id_status integer,
 start_date date, 
 end_date date,
 primary key (id_exposition, id_status)
);

create table if not exists status
( 
 id_status integer,
 name_status text not null,
 primary key (id_status)
);

-- INSERT INTO author (first_name, second_name, surname) VALUES ("Leonardo", "Da Vinchi", NULL), ("Ivan", "Shishkin", "Ivanovich"), ("Vasiliy", "Condinskiy", "Vasilievich"), ("William", "Van Gogh", NULL);
-- INSERT INTO floor_museum (number_floor, name_floor) VALUES (1, "CLassical Art"), (2, "Modern Art"), (3, "Art of 19-20 centuries");
-- INSERT INTO hall (number_hall, name_hall, number_floor) VALUES (1, "European painters", 1), (2, "Soviet painters", 1), (3, "Big paintings", 2), (4, "miniatures", 3);
-- INSERT INTO exposition (name_exposition, descreption, id_hall) VALUES ("Condinskiy", "Our museum's artwork page has a curated selection of our most notable pieces and collections. Featuring detailed descriptions and high-quality images, it offers insights into the artistry and history behind each work. Enjoy a virtual tour of our collection from the comfort of your home.", 1), 
-- ("van Gogh", "Experience the passion and brilliance of Vincent van Gogh at this unforgettable exhibition! Marvel at his iconic swirls of Starry Night, glowing Sunflowers, and vivid landscapes that pulse with emotion. Discover the turbulent genius behind the brushstrokes—his dreams, struggles, and unparalleled vision that transformed art forever.", 1), 
-- ("Malevich", "Dive into the bold, revolutionary art of Kazimir Malevich, the pioneer of abstract geometric forms. This exhibition showcases his iconic Black Square—a symbol of artistic rebellion—alongside striking Suprematist works that shattered 
-- traditional boundaries. Explore how Malevich reduced painting to pure feeling, using stark shapes and vibrant colors to create a new visual language.", "3"),
-- ("Future collections", "Journey through centuries of creativity in this breathtaking exhibition of European masterpieces! From the luminous Renaissance portraits to the dramatic Baroque scenes, the dreamy Impressionist landscapes to the bold strokes of Modernism—discover the evolution of art across time and cultures.", 2);
-- INSERT INTO exhibit (name_exhibit, description, id_author, id_hall) VALUES ("Composition №224", "For Kandinsky, the essence of phenomena is their spiritual substance, which is expressed through the harmony of color, form, and line. Each element in Kandinsky's abstract paintings is expressive and necessary, like a perfectly tuned note in a chord.", 1, 1),
-- ("Morning in the pine forest", "This painting by Ivan Ivanovich Shishkin was created in 1889. It is one of the most popular works by the artist and one of the most famous landscapes in the history of Russian art.", 2, 2);
-- INSERT INTO photo_exhibit (id_exhibit, id_photo, photo) VALUES (1, 1, "images/car7.jpg"), (2, 2, "images/p3.jpg");
-- INSERT INTO photo_exposition (id_exposition, id_photo, photo) VALUES (1, 1, "images/Cand.jpg"), (2, 2, "images/expos.jpg");
