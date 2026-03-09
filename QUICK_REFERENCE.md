# 📚 CAPP ERP - Quick Reference Guide (Hướng Dẫn Nhanh)

## ⚡ Các Lệnh Thường Dùng

### 🔧 Cài Đặt & Khởi Động

| Lệnh | Mục Đích |
|------|----------|
| `bundle install` | Cài đặt tất cả Ruby gems |
| `bundle exec rake db:create` | Tạo database |
| `bundle exec rake db:migrate` | Chạy database migrations |
| `bundle exec rails server` | Khởi động Rails server (port 3000) |
| `bundle exec rails s -p 4000` | Khởi động server trên port 4000 |

### 📊 Database

| Lệnh | Mục Đích |
|------|----------|
| `bundle exec rake db:setup` | Tạo DB, migrate, seed dữ liệu |
| `bundle exec rake db:reset` | Xóa & tạo lại database |
| `bundle exec rake db:migrate:status` | Xem status migrations |
| `bundle exec rake db:rollback` | Undo migration cuối |
| `bundle exec rake db:seed` | Insert dữ liệu mẫu |
| `bundle exec rails dbconsole` | Mở MySQL console |

### 🧪 Testing & Debugging

| Lệnh | Mục Đích |
|------|----------|
| `bundle exec rails test` | Chạy tất cả tests |
| `bundle exec rails console` | Mở Rails console (debug) |
| `bundle exec rails routes` | Liệt kê tất cả routes |
| `bundle exec rails routes -c Users` | Routes của Users controller |
| `bundle exec rails generate migration NAME` | Tạo migration mới |

### 🎨 Assets & Frontend

| Lệnh | Mục Đích |
|------|----------|
| `bundle exec rails assets:precompile` | Compile CSS/JS |
| `bundle exec rails assets:clobber` | Xóa compiled assets |
| `bundle exec rails tailwindcss:build` | Build Tailwind CSS |

### 🔄 Background Jobs

| Lệnh | Mục Đích |
|------|----------|
| `bundle exec sidekiq` | Chạy Sidekiq worker |
| `bundle exec rake jobs:work` | Chạy Delayed Job |
| `bundle exec whenever --run-now` | Chạy scheduled jobs |

### 📦 Gem Management

| Lệnh | Mục Đích |
|------|----------|
| `bundle check` | Kiểm tra gem dependencies |
| `bundle update` | Update tất cả gems |
| `bundle show GEM_NAME` | Xem path của gem |
| `gem list` | Liệt kê installed gems |

### 📋 Logs & Monitoring

| Lệnh | Mục Đích |
|------|----------|
| `tail -f log/development.log` | Xem development logs (live) |
| `Get-Content log/development.log -Tail 50 -Wait` | Xem logs trên Windows |
| `bundle exec rails logs` | Xem tất cả logs |

---

## 🚀 Quick Start (5 Bước)

### Cách 1: Tự động (Khuyên dùng)

**Windows PowerShell:**
```powershell
Set-ExecutionPolicy -ExecutionPolicy Bypass -Scope Process
.\setup.ps1
```

**Windows CMD:**
```bash
setup.bat
```

### Cách 2: Manual

```bash
# 1. Cài gems
bundle install

# 2. Tạo database
bundle exec rake db:create

# 3. Chạy migrations
bundle exec rake db:migrate

# 4. Khởi động server
bundle exec rails server

# 5. Mở browser
# http://localhost:3000
```

---

## 🔍 Kiểm Tra Cấu Hình

```bash
# Kiểm tra version
ruby --version
rails --version
bundle --version

# Kiểm tra database connection
bundle exec rails dbconsole

# Liệt kê tất cả routes
bundle exec rails routes

# Xem environment variables
bundle exec rails runner 'puts ENV.inspect'
```

---

## 🛠️ Troubleshooting Nhanh

### Problem: Port 3000 đã dùng

```bash
# Tìm process dùng port
lsof -i :3000          # macOS/Linux
Get-NetTCPConnection -LocalPort 3000  # Windows

# Chạy port khác
bundle exec rails server -p 4000
```

### Problem: Database connection error

```bash
# Sửa config/database.yml
# Đảm bảo host, username, password đúng

# Kiểm tra kết nối
bundle exec rails dbconsole
```

### Problem: Gems không cài được

```bash
# Update bundler
gem install bundler

# Clear cache & cài lại
rm Gemfile.lock
bundle install
```

### Problem: Assets không load

```bash
# Xóa compiled assets
bundle exec rails assets:clobber

# Precompile lại
bundle exec rails assets:precompile
```

### Problem: Migration errors

```bash
# Xem status
bundle exec rake db:migrate:status

# Rollback một migration
bundle exec rake db:rollback STEP=1

# Rollback tất cả
bundle exec rake db:migrate VERSION=0

# Migrate lại
bundle exec rake db:migrate
```

---

## 📁 Project Structure

```
capp_erp/
├── app/
│   ├── controllers/      (71+ controllers)
│   ├── models/           (130+ models)
│   ├── views/            (Templates)
│   ├── services/         (Business logic)
│   ├── jobs/             (Background jobs)
│   └── mailers/          (Email)
├── config/
│   ├── database.yml      (Database config)
│   ├── routes.rb         (Routes)
│   └── environments/     (Dev/Production)
├── db/
│   ├── schema.rb         (Schema)
│   └── seeds.rb          (Sample data)
├── Gemfile               (Dependencies)
├── Rakefile              (Tasks)
├── setup.bat             (Windows setup)
├── setup.ps1             (PowerShell setup)
├── HOW_TO_RUN.md         (Full guide)
└── README.md             (Project info)
```

---

## 🌐 Truy Cập Ứng Dụng

Khi server chạy:

| URL | Mục Đích |
|-----|----------|
| http://localhost:3000 | Main app |
| http://localhost:3000/login | Login page |
| http://localhost:3000/dashboard | Dashboard |
| http://localhost:3000/api/... | API endpoints |
| http://localhost:3000/rails/info | Rails info |

---

## 🔐 Default Credentials

*Kiểm tra file `db/seeds.rb` hoặc tài liệu khác để lấy thông tin login mẫu*

---

## 📖 Tài Liệu Bổ Sung

- **Full Guide**: Xem `HOW_TO_RUN.md`
- **Project Info**: Xem `README.md`
- **Rails Guides**: https://guides.rubyonrails.org/
- **Ruby Docs**: https://ruby-doc.org/

---

## 💡 Mẹo & Thủ Thuật

### 1. Tạo Model mới
```bash
bundle exec rails generate model ModelName field1:type field2:type
```

### 2. Tạo Controller mới
```bash
bundle exec rails generate controller ControllerName action1 action2
```

### 3. Tạo Migration
```bash
bundle exec rails generate migration AddFieldNameToTableName field_name:type
```

### 4. Xem database schema
```bash
# Tại Rails console
bundle exec rails console
> User.columns_hash
> User.new.attributes
```

### 5. Reset environment
```bash
# Xóa tất cả
bundle exec rake db:drop db:create db:migrate db:seed

# Hoặc
bundle exec rake db:reset
```

### 6. Chạy specific test
```bash
bundle exec rails test test/models/user_test.rb
bundle exec rails test test/models/user_test.rb:LineNumber
```

### 7. Interactive debugging
```bash
# Trong code, thêm:
binding.pry
# hoặc
debugger

# Chạy server & inspect
bundle exec rails server
```

---

## 🎯 Lifecycle Commands

```
Initial Setup:
bundle install
bundle exec rake db:create
bundle exec rake db:migrate
bundle exec rails server

Daily Development:
bundle exec rails server        # Main server
bundle exec sidekiq             # Background jobs
bundle exec rails console       # Debug

Before Deployment:
bundle exec rails test          # Run tests
bundle exec rails assets:precompile
bundle exec rake db:migrate RAILS_ENV=production

Production:
RAILS_ENV=production bundle exec rails server
RAILS_ENV=production bundle exec sidekiq
```

---

## 📞 Cần Giúp?

1. **Kiểm tra logs**: `tail -f log/development.log`
2. **Rails Console**: `bundle exec rails console` → test code
3. **Database Console**: `bundle exec rails dbconsole` → query DB
4. **Routes**: `bundle exec rails routes` → xem endpoints
5. **Gems**: `bundle check` → kiểm tra dependencies

---

**Happy Coding! 🎉**
