DROP TABLE IF EXISTS sales;
DROP TABLE IF EXISTS books;

CREATE TABLE books (
    book_id INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    title TEXT NOT NULL,
    author TEXT NOT NULL,
    price NUMERIC(10, 2) NOT NULL,
    stock_quantity INT NOT NULL DEFAULT 0
);

CREATE TABLE sales (
    sale_id INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    book_id INT NOT NULL REFERENCES books(book_id),
    quantity_sold INT NOT NULL,
    sale_date TIMESTAMPTZ DEFAULT NOW()
);

INSERT INTO books (title, author, price, stock_quantity) VALUES
('The Hitchhiker''s Guide to the Galaxy', 'Douglas Adams', 12.50, 5),
('Pride and Prejudice', 'Jane Austen', 9.75, 10),
('Dune', 'Frank Herbert', 15.00, 2);