-- Bảng lưu các danh mục
CREATE TABLE Categories (
    category_id INT PRIMARY KEY AUTO_INCREMENT,
    name VARCHAR(100) NOT NULL UNIQUE,
    slug VARCHAR(100) NOT NULL UNIQUE -- Dùng cho URL thân thiện, ví dụ: /the-thao
);

-- Bảng lưu thông tin người đăng tin (phóng viên)
CREATE TABLE Reporters (
    reporter_id INT PRIMARY KEY AUTO_INCREMENT,
    full_name VARCHAR(150) NOT NULL,
    email VARCHAR(100) NOT NULL UNIQUE
    -- ... các trường thông tin khác
);

-- Bảng tin tức chính
CREATE TABLE NewsArticles (
    article_id BIGINT PRIMARY KEY AUTO_INCREMENT,
    title VARCHAR(255) NOT NULL,
    short_description TEXT,
    content TEXT NOT NULL,
    published_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    category_id INT,
    reporter_id INT,
    FOREIGN KEY (category_id) REFERENCES Categories(category_id),
    FOREIGN KEY (reporter_id) REFERENCES Reporters(reporter_id)
);

-- Đánh index để tăng tốc truy vấn theo ngày và danh mục
CREATE INDEX idx_published_date ON NewsArticles (published_date DESC);
CREATE INDEX idx_category_id ON NewsArticles (category_id);