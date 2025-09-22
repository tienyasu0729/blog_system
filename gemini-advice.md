## 🏛️ **Kiến trúc Tổng thể**

Để đáp ứng các yêu cầu, chúng ta sẽ không dùng một máy chủ đơn lẻ mà thay vào đó là một hệ thống gồm nhiều dịch vụ chuyên biệt (Microservices), phối hợp với nhau.

1.  **CDN (Content Delivery Network):** Là lớp ngoài cùng, tiếp xúc với người dùng toàn cầu. Giúp tăng tốc độ tải trang bằng cách lưu trữ bản sao (cache) của tin tức, hình ảnh ở các máy chủ gần người dùng nhất.
2.  **Load Balancer (Bộ cân bằng tải):** Phân phối lưu lượng truy cập của người dùng đến nhiều máy chủ ứng dụng, tránh tình trạng quá tải cho bất kỳ máy chủ nào và đảm bảo hệ thống luôn hoạt động ngay cả khi một máy chủ gặp sự cố.
3.  **API Gateway:** Điểm vào duy nhất cho mọi yêu cầu. Nó sẽ điều hướng yêu cầu đến các Microservice tương ứng (ví dụ: yêu cầu tìm kiếm sẽ đến dịch vụ tìm kiếm, yêu cầu xem tin sẽ đến dịch vụ tin tức).
4.  **Microservices:** Các dịch vụ độc lập, mỗi dịch vụ thực hiện một chức năng kinh doanh cụ thể:
      * **News Service:** Xử lý mọi thứ liên quan đến nghiệp vụ tin tức (đăng, sửa, xóa, lấy tin tức).
      * **Search Service:** Cung cấp khả năng tìm kiếm tin tức hiệu quả.
      * **User Service:** Quản lý thông tin người đăng tin (phóng viên).
5.  **Message Queue (Hàng đợi tin nhắn):** Dùng để giao tiếp bất đồng bộ giữa các service. Khi một tin mới được đăng, News Service chỉ cần đẩy một tin nhắn vào hàng đợi, các dịch vụ khác (như Search Service) sẽ lắng nghe và tự động cập nhật.
6.  **Database & Caching:** Hệ thống lưu trữ dữ liệu, được tối ưu cho cả việc đọc và ghi ở quy mô lớn.

-----

## 🚀 **Lựa chọn Công nghệ Chi tiết**

### 1\. Cơ sở dữ liệu (Database) - Trái tim của hệ thống

Với hàng trăm triệu dòng dữ liệu và lượng truy cập đọc cực lớn, một cơ sở dữ liệu SQL truyền thống sẽ khó đáp ứng. Chúng ta cần một giải pháp có khả năng mở rộng theo chiều ngang (horizontal scaling).

  * **Lựa chọn hàng đầu: NoSQL Database**

      * **Gợi ý:** **Apache Cassandra** hoặc **Amazon DynamoDB**.
      * **Tại sao?** Các hệ quản trị CSDL này được thiết kế để chạy trên nhiều máy chủ, cho phép ghi và đọc dữ liệu với tốc độ cực nhanh ở quy mô lớn. Chúng đặc biệt mạnh cho dữ liệu dạng chuỗi thời gian (time-series) như tin tức (luôn sắp xếp theo thời gian mới nhất).

  * **Phương án thay thế: SQL với kiến trúc phức tạp hơn**

      * **Gợi ý:** **PostgreSQL** hoặc **MySQL**.
      * **Yêu cầu:** Phải thiết kế theo mô hình **Primary-Replica**.
          * **Primary Database:** Chỉ dùng cho việc ghi dữ liệu (đăng/sửa/xóa tin).
          * **Read Replicas:** Nhiều bản sao của Primary, chỉ dùng cho việc đọc dữ liệu. Người dùng sẽ truy vấn vào các máy chủ này. Khi lượng đọc tăng, ta chỉ cần thêm Read Replica.
          * **Sharding:** Khi dữ liệu quá lớn, ta phải phân mảnh dữ liệu (sharding) ra nhiều cụm database khác nhau.

### 2\. Hệ thống Tìm kiếm (Search System) 🔍

Tuyệt đối **không** dùng lệnh `LIKE` của SQL để tìm kiếm trên bảng dữ liệu lớn, vì nó cực kỳ chậm.

  * **Lựa chọn:** **Elasticsearch** hoặc **OpenSearch**.
  * **Cách hoạt động:** Khi một tin tức được đăng hoặc cập nhật, hệ thống sẽ đẩy dữ liệu của tin đó (tiêu đề, mô tả) vào Elasticsearch để "đánh chỉ mục" (indexing). Việc tìm kiếm sẽ được thực hiện trên Elasticsearch, cho kết quả gần như ngay lập tức.

### 3\. Caching để Tăng tốc ⚡

  * **CDN (Cloudflare, AWS CloudFront):** Cache lại nội dung các bài viết đã được xem bởi người dùng. Người dùng ở các quốc gia khác nhau sẽ tải tin tức từ máy chủ gần họ nhất.
  * **In-memory Cache (Redis, Memcached):** Cache lại những dữ liệu hay được truy cập, ví dụ: danh sách 50 tin tức mới nhất trên trang chủ, danh sách các danh mục. Điều này giúp giảm tải đáng kể cho database.

### 4\. Message Queue (RabbitMQ, Apache Kafka, AWS SQS)

Đây là chất keo kết dính hệ thống.

  * **Ví dụ luồng đăng tin:**
    1.  Phóng viên bấm nút "Đăng tin".
    2.  Yêu cầu được gửi đến **News Service**.
    3.  **News Service** lưu tin tức vào Database chính và ngay lập tức trả về thông báo "Thành công" cho phóng viên.
    4.  Đồng thời, **News Service** đẩy một tin nhắn chứa ID của bài viết mới vào **Message Queue**.
    5.  **Search Service** nhận được tin nhắn, tự động lấy dữ liệu bài viết từ database và cập nhật vào Elasticsearch.
    6.  Một dịch vụ khác có thể nhận tin nhắn này để gửi thông báo đến người dùng...
  * **Lợi ích:** Phóng viên không phải chờ đợi lâu. Hệ thống phản hồi nhanh và các tác vụ phụ trợ được xử lý ngầm một cách đáng tin cậy.

-----

## 💾 **Thiết kế Sơ đồ Cơ sở dữ liệu (Schema)**

Dưới đây là ví dụ đơn giản cho cả hai phương án SQL và NoSQL (Cassandra).

#### 1\. Sơ đồ SQL (PostgreSQL/MySQL)

```sql
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
```

#### 2\. Sơ đồ NoSQL (Apache Cassandra)

Trong Cassandra, chúng ta thiết kế bảng dựa trên câu truy vấn sẽ thực hiện.

**Truy vấn chính:** *Lấy các tin tức mới nhất trong một danh mục.*

```cql
-- Thiết kế bảng để tối ưu cho việc lấy tin theo danh mục và ngày đăng
CREATE TABLE articles_by_category (
    category_slug text,          -- Khóa phân vùng (Partition Key): Dữ liệu sẽ được gom nhóm theo danh mục
    published_date timestamp,     -- Khóa gom cụm (Clustering Key): Dữ liệu trong mỗi danh mục sẽ được sắp xếp theo ngày
    article_id timeuuid,          -- ID duy nhất
    title text,
    short_description text,
    content text,
    reporter_id int,
    reporter_name text,
    PRIMARY KEY ((category_slug), published_date)
) WITH CLUSTERING ORDER BY (published_date DESC); -- Sắp xếp sẵn theo ngày mới nhất

-- Khi muốn lấy 10 tin mới nhất của danh mục 'the-thao':
-- SELECT * FROM articles_by_category WHERE category_slug = 'the-thao' LIMIT 10;
-- Câu lệnh này cực kỳ nhanh vì dữ liệu đã được tổ chức sẵn.
```

Chúc bạn thành công với dự án của mình\!