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
