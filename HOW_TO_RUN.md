# 🚀 Hướng Dẫn Chạy Dự Án CAPP ERP

## 📋 Yêu Cầu Hệ Thống

### Bắc Buộc
- **Ruby**: 2.7+ hoặc 3.0+
- **Rails**: 6.0+
- **MySQL**: 5.7+ hoặc MariaDB
- **Node.js**: 12.x+ (cho asset compilation)
- **Git**: Quản lý version

### Bộ Cài Đặt
```
Ruby >= 2.7.0
Rails >= 6.0.0
MySQL/MariaDB >= 5.7
Bundler >= 1.17.3
```

---

## 1️⃣ Cài Đặt Và Cấu Hình Ban Đầu

### Bước 1: Clone/Chuẩn Bị Dự Án

```bash
cd c:\Users\Admin\Desktop\ruby\capp_erp
```

### Bước 2: Cài Đặt Ruby Gems

```bash
# Cài đặt tất cả dependencies từ Gemfile
bundle install

# Nếu gặp lỗi với mysql2 gem, cài đặt development tools:
# Windows: Cần Visual Studio Build Tools hoặc DevKit
```

### Bước 3: Cấu Hình Database

<details>
<summary><b>✅ Tệp database.yml đã được tìm thấy</b></summary>

Thông tin kết nối PostgreSQL hiện tại:
- **Host**: 10.10.2.220
- **Port**: 3306
- **Username**: btmums
- **Password**: HelpPe0ple
- **Development DB**: sg_bmtu_platform_development
- **Test DB**: sg_bmtu_platform_test
- **Production DB**: sg_bmtu_platform_prod

**Cấu hình tại**: `config/database.yml`

```yaml
default: &default
  adapter: mysql2
  encoding: utf8
  pool: 5
  username: btmums
  password: HelpPe0ple
  host: 10.10.2.220
  port: 3306

development:
  <<: *default
  database: sg_bmtu_platform_development

test:
  <<: *default
  database: sg_bmtu_platform_test

production:
  <<: *default
  database: sg_bmtu_platform_prod
```

</details>

#### 📝 Nếu Cần Thay Đổi Database:

Đối với development cục bộ, sửa `config/database.yml`:

```yaml
default: &default
  adapter: mysql2
  encoding: utf8
  pool: 5
  username: root
  password: ''  # hoặc password của bạn
  host: localhost
  port: 3306

development:
  <<: *default
  database: capp_erp_development

test:
  <<: *default
  database: capp_erp_test
```

### Bước 4: Tạo Và Khởi Tạo Database

```bash
# Tạo databases
bundle exec rake db:create

# Chạy migrations
bundle exec rake db:migrate

# (Optional) Tạo sample data
bundle exec rake db:seed
```

---

## 2️⃣ Chạy Development Server

### Cách 1: Chạy Rails Server

```bash
# Khởi động Rails development server (mặc định port 3000)
bundle exec rails server
# hoặc viết tắt
bundle exec rails s

# Hoặc chỉ định port khác
bundle exec rails server -p 4000
```

Truy cập ứng dụng tại: **http://localhost:3000**

### Cách 2: Chạy Với Procfile (Full Stack)

Nếu dự án có Procfile:

```bash
bundle exec foreman start
```

### Cách 3: Chạy Assets & Server Riêng

```bash
# Terminal 1 - Rails Server
bundle exec rails server

# Terminal 2 - Watch & Compile Assets
bundle exec rails assets:precompile --trace
```

---

## 3️⃣ Công Việc Rails Phổ Biến

### Database Management

```bash
# Tạo database
bundle exec rake db:create

# Khởi tạo schema
bundle exec rake db:setup

# Chạy migrations
bundle exec rake db:migrate

# Rollback migration cuối cùng
bundle exec rake db:rollback

# Xem status migrations
bundle exec rake db:migrate:status

# Reset database (xóa & tạo mới)
bundle exec rake db:drop
bundle exec rake db:create
bundle exec rake db:migrate
```

### Asset Compilation

```bash
# Precompile assets cho production
bundle exec rails assets:precompile

# Clear assets cache
bundle exec rails assets:clobber
```

### Server & Console

```bash
# Rails Console (debug & test code)
bundle exec rails console

# Debugger (nếu có)
bundle exec rails server --debug

# Check routes
bundle exec rails routes
```

### Testing

```bash
# Chạy tất cả tests
bundle exec rails test

# Chạy một test file cụ thể
bundle exec rails test test/models/user_test.rb

# Run tests với coverage
bundle exec rspec
```

---

## 4️⃣ Chạy Background Jobs

Dự án sử dụng ActiveJob với Sidekiq/Delayed Job.

### Khởi Động Job Worker

```bash
# Nếu dùng Sidekiq
bundle exec sidekiq

# Nếu dùng Delayed Job
bundle exec rake jobs:work

# Nếu dùng async (chỉ development)
# Không cần chạy riêng, tự động trong rails server
```

### Job Queue được sử dụng:
- `NotificationJob` - Gửi notifications
- `SendNotificationJob` - Gửi notification async
- `SendMandocuhandleNotificationJob` - Document notifications
- `CheckAppointsurveyStatusJob` - Monitor surveys
- `UpdateCheckoutJob` - Update check-out times

---

## 5️⃣ Cấu Hình Firebase Cloud Messaging (FCM)

Dự án sử dụng FCM cho push notifications.

### Bước 1: Cấu Hình FCM

Tạo file `config/initializers/fcm.rb`:

```ruby
FCM_API_KEY = ENV['FCM_API_KEY'] || 'your_fcm_api_key_here'

# Hoặc tải từ Google Service Account JSON
require 'googleauth'

FCM_PROJECT_ID = ENV['FCM_PROJECT_ID'] || 'your_project_id'
FCM_CREDENTIALS_PATH = ENV['FCM_CREDENTIALS_PATH'] || 'path/to/service-account-key.json'
```

### Bước 2: Thiết Lập Environment Variables

Tạo `.env` file trong thư mục gốc:

```bash
FCM_API_KEY=your_api_key_here
FCM_PROJECT_ID=your_project_id
RAILS_ENV=development
DATABASE_HOST=localhost
DATABASE_USER=root
DATABASE_PASSWORD=your_password
```

Hoặc trên Windows (PowerShell):

```powershell
$env:FCM_API_KEY = "your_api_key_here"
$env:RAILS_ENV = "development"
```

---

## 6️⃣ Cấu Hình Email (Mailer)

Dự án có 5 mailers:
- `UserMailer` - Email liên quan user
- `AttendMailer` - Email attendance
- `HolidayMailer` - Email holiday notifications
- `SystemMailer` - Email hệ thống
- `ApplicationMailer` - Base mailer

### Cấu Hình SMTP:

Sửa `config/environments/development.rb`:

```ruby
config.action_mailer.delivery_method = :smtp
config.action_mailer.smtp_settings = {
  address: 'smtp.gmail.com',
  port: 587,
  domain: 'gmail.com',
  user_name: 'your_email@gmail.com',
  password: 'your_app_password',
  authentication: 'plain',
  enable_starttls_auto: true
}
config.action_mailer.default_url_options = { host: 'localhost:3000' }
```

Hoặc dùng Mailgun, SendGrid, v.v.

---

## 7️⃣ Khởi Động Hoàn Chỉnh (Multi-Process)

Tạo `Procfile` để chạy mọi service cùng lúc:

```procfile
web: bundle exec rails server -p 3000
worker: bundle exec sidekiq
scheduled: bundle exec whenever --run-now
```

Chạy:

```bash
bundle exec foreman start
```

Hoặc trên Windows PowerShell:

```powershell
# Terminal 1 - Rails Server
bundle exec rails server

# Terminal 2 - Sidekiq Worker (nếu có)
bundle exec sidekiq

# Terminal 3 - Scheduled Jobs (nếu dùng whenever)
bundle exec whenever --run-now
```

---

## 8️⃣ Cấu Hình SSL (Production)

Nếu cần HTTPS:

```bash
# Tạo self-signed certificate (dev only)
sudo openssl req -x509 -newkey rsa:4096 -keyout key.pem -out cert.pem -days 365 -nodes

# Hoặc dùng Let's Encrypt trong production
```

---

## 9️⃣ Troubleshooting (Giải Quyết Vấn Đề)

### Lỗi: `Gem mysql2 not installed`

```bash
# Cài gem mysql2 cụ thể
bundle install --no-cache

# Nếu vẫn lỗi, cài development tools cho MySQL
gem install mysql2 -- --with-mysql-config=/usr/local/mysql/bin/mysql_config
```

### Lỗi: `Could not find database for development`

```bash
bundle exec rake db:create
bundle exec rake db:migrate
```

### Lỗi: `Rails Port Already In Use`

```bash
# Tìm process dùng port 3000
lsof -i :3000    # macOS/Linux
Get-NetTCPConnection -LocalPort 3000  # Windows

# Chạy trên port khác
bundle exec rails server -p 4000
```

### Lỗi: `SimpleCaptcha Errors`

```bash
# Generate captcha images
bundle exec rails generate simple_captcha
```

### Lỗi: Asset Pipeline (CSS/JS không load)

```bash
# Precompile assets
bundle exec rails assets:precompile

# Hoặc clear cache
bundle exec rails assets:clobber
bundle exec rails assets:precompile
```

### Lỗi: Session/Cookie Issues

Xóa session cache:
```bash
# Clear temporary files
rm -rf tmp/
mkdir tmp/

# Hoặc
Remove-Item -Path ./tmp -Recurse -Force
New-Item -ItemType Directory -Path ./tmp
```

---

## 🔟 Kiểm Tra Health Status

```bash
# Kiểm tra dependencies
bundle check

# Kiểm tra database connection
bundle exec rails dbconsole

# Liệt kê tất cả routes
bundle exec rails routes

# Check Rails version
bundle exec rails --version

# Check Ruby version
ruby --version
```

---

## 1️⃣1️⃣ Dữ Liệu Mẫu (Seeding)

Nếu có seed data:

```bash
# Tạo dữ liệu mẫu
bundle exec rake db:seed

# Kết hợp create + migrate + seed
bundle exec rake db:setup
```

File seed thường nằm tại: `db/seeds.rb`

---

## 1️⃣2️⃣ Logs & Debugging

### Xem Logs Development

```bash
# Logs chính
tail -f log/development.log

# Windows PowerShell
Get-Content log/development.log -Tail 50 -Wait
```

### Kích hoạt Debug Mode

```bash
# Trong console.log hoặc code
binding.pry  # Nếu có gem 'pry'
debugger     # Nếu có gem 'debug'
```

---

## 1️⃣3️⃣ Production Deployment

### Chuẩn Bị Production

```bash
# Compile assets
RAILS_ENV=production bundle exec rails assets:precompile

# Set secret key
export SECRET_KEY_BASE=$(bundle exec rails secret)

# Database setup
RAILS_ENV=production bundle exec rake db:create
RAILS_ENV=production bundle exec rake db:migrate
```

### Chạy Production Server

```bash
# Với Puma (production server)
RAILS_ENV=production bundle exec puma -t 5:5 -p 3000

# Hoặc với Unicorn
RAILS_ENV=production bundle exec unicorn -p 3000
```

### Sử Dụng Nginx (Reverse Proxy)

Cấu hình Nginx pointing sang Rails port:

```nginx
upstream rails_app {
  server 127.0.0.1:3000;
}

server {
  listen 80;
  server_name example.com;

  location / {
    proxy_pass http://rails_app;
  }
}
```

---

## 1️⃣4️⃣ Quickstart Command Cheatsheet

```bash
# Setup ban đầu
bundle install
bundle exec rake db:create
bundle exec rake db:migrate

# Chạy development
bundle exec rails server

# Chạy tests
bundle exec rails test

# Background jobs
bundle exec sidekiq

# Rails console
bundle exec rails console

# Generate migrations
bundle exec rails generate migration AddNameToUsers name:string

# Create model
bundle exec rails generate model User email:string password_digest:string

# Database utilities
bundle exec rake db:reset     # Reset database
bundle exec rake db:rollback  # Undo last migration
bundle exec rake db:seed      # Seed data
```

---

## 1️⃣5️⃣ File Cấu Hình Quan Trọng

| File | Mục Đích |
|------|----------|
| `Gemfile` | Quản lý dependencies |
| `config/database.yml` | Cấu hình database |
| `config/routes.rb` | Định nghĩa routes |
| `config/environments/` | Development/Production settings |
| `config/initializers/` | Khởi tạo gems & services |
| `db/schema.rb` | Database schema (auto-generated) |
| `db/seeds.rb` | Dữ liệu mẫu |
| `.env` | Environment variables |
| `Procfile` | Multi-process startup |

---

## 📞 Kiểm Tra Kết Nối

Khi server chạy, kiểm tra:

1. **Web UI**: http://localhost:3000
2. **Rails Console**: `bundle exec rails console`
3. **Database**: `bundle exec rails dbconsole`
4. **Routes**: `bundle exec rails routes -c Users`

---

## 🎯 Tóm Tắt Các Bước

```bash
# 1. Cài đặt
cd c:\Users\Admin\Desktop\ruby\capp_erp
bundle install

# 2. Cấu hình Database (nếu cần)
# Sửa config/database.yml

# 3. Tạo & setup database
bundle exec rake db:create
bundle exec rake db:migrate

# 4. Chạy server
bundle exec rails server

# 5. Mở trình duyệt
# http://localhost:3000
```

**Xong! Dự án đã sẵn sàng.**

---

**Ghi chú**: Tất cả commands phía trên sử dụng `bundle exec` để đảm bảo gem versions chính xác. Bạn có thể bỏ `bundle exec` nếu đã `bundle install` thành công.
