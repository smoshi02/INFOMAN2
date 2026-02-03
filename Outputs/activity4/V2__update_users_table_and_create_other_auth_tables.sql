alter table users
add column password VARCHAR(60) NOT NULL,
add column date_created timestamp default now();

create table roles (
    id SERIAL PRIMARY KEY,
    name VARCHAR(50) unique NOT NULL,
    date_created timestamp default now()
);

create table user_roles (
    id serial primary key,
    user_id int not NULL,
    role_id int not NULL,
    foreign key (user_id) references users(id) on update cascade on delete cascade,
    foreign key (role_id) references roles(id) on update cascade on delete cascade
);