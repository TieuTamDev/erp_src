#!/usr/bin/env pwsh
# CAPP ERP - Automatic Setup Script for Windows
# Run as: .\setup.ps1

Write-Host "🚀 CAPP ERP - Windows Setup Script" -ForegroundColor Green
Write-Host "=================================" -ForegroundColor Green
Write-Host ""

# Check Ruby Installation
Write-Host "📝 Checking Ruby installation..." -ForegroundColor Yellow
try {
    $rubyVersion = ruby --version
    Write-Host "✅ Ruby found: $rubyVersion" -ForegroundColor Green
} catch {
    Write-Host "❌ Ruby not found! Please install Ruby first." -ForegroundColor Red
    Write-Host "   Download from: https://rubyinstaller.org/" -ForegroundColor Yellow
    exit 1
}

# Check Rails Installation
Write-Host ""
Write-Host "📝 Checking Rails installation..." -ForegroundColor Yellow
try {
    $railsVersion = rails --version
    Write-Host "✅ Rails found: $railsVersion" -ForegroundColor Green
} catch {
    Write-Host "⚠️  Rails gem not found, will install with bundle install" -ForegroundColor Yellow
}

# Check Bundler
Write-Host ""
Write-Host "📝 Checking Bundler..." -ForegroundColor Yellow
try {
    $bundlerVersion = bundle --version
    Write-Host "✅ Bundler found: $bundlerVersion" -ForegroundColor Green
} catch {
    Write-Host "❌ Bundler not found! Installing..." -ForegroundColor Yellow
    gem install bundler
}

# Check MySQL
Write-Host ""
Write-Host "📝 Checking MySQL/MariaDB installation..." -ForegroundColor Yellow
try {
    $mysqlVersion = mysql --version
    Write-Host "✅ MySQL found: $mysqlVersion" -ForegroundColor Green
} catch {
    Write-Host "⚠️  MySQL not found. Please install MySQL/MariaDB first." -ForegroundColor Yellow
    Write-Host "   Download from: https://www.mysql.com/downloads/" -ForegroundColor Yellow
}

# Get project directory
Write-Host ""
$projectDir = Get-Location
Write-Host "📂 Project directory: $projectDir" -ForegroundColor Cyan

# Step 1: Install Gems
Write-Host ""
Write-Host "Step 1️⃣ : Installing Ruby Gems..." -ForegroundColor Yellow
bundle install
if ($LASTEXITCODE -ne 0) {
    Write-Host "❌ Bundle install failed!" -ForegroundColor Red
    exit 1
}
Write-Host "✅ Gems installed successfully!" -ForegroundColor Green

# Step 2: Database Configuration
Write-Host ""
Write-Host "Step 2️⃣ : Database Configuration..." -ForegroundColor Yellow
$dbConfigPath = "config/database.yml"

if (Test-Path $dbConfigPath) {
    Write-Host "📄 database.yml found" -ForegroundColor Green
    Write-Host ""
    Write-Host "Current database configuration:" -ForegroundColor Cyan
    Get-Content $dbConfigPath | Select-String -Pattern "host:|database:|username:" | ForEach-Object {
        Write-Host "  $_" -ForegroundColor Cyan
    }
    
    $useCurrent = Read-Host "Use current configuration? (Y/n)"
    if ($useCurrent -ne "N" -and $useCurrent -ne "n") {
        Write-Host "✅ Using current configuration" -ForegroundColor Green
    } else {
        Write-Host "⚠️  Please edit config/database.yml manually" -ForegroundColor Yellow
        Start-Process notepad $dbConfigPath
        Read-Host "Press Enter after editing..."
    }
} else {
    Write-Host "⚠️  database.yml not found! Creating template..." -ForegroundColor Yellow
}

# Step 3: Create Database
Write-Host ""
Write-Host "Step 3️⃣ : Creating Database..." -ForegroundColor Yellow
bundle exec rake db:create 2>$null
if ($LASTEXITCODE -eq 0) {
    Write-Host "✅ Database created successfully!" -ForegroundColor Green
} else {
    Write-Host "⚠️  Database creation had issues. Check your database configuration." -ForegroundColor Yellow
    Write-Host "   This might be okay if database already exists." -ForegroundColor Gray
}

# Step 4: Run Migrations
Write-Host ""
Write-Host "Step 4️⃣ : Running Database Migrations..." -ForegroundColor Yellow
bundle exec rake db:migrate
if ($LASTEXITCODE -eq 0) {
    Write-Host "✅ Migrations completed successfully!" -ForegroundColor Green
} else {
    Write-Host "⚠️  Migration had issues. Check the logs above." -ForegroundColor Yellow
}

# Step 5: Precompile Assets
Write-Host ""
Write-Host "Step 5️⃣ : Precompiling Assets..." -ForegroundColor Yellow
bundle exec rails assets:precompile 2>&1 | Out-Null
if ($LASTEXITCODE -eq 0) {
    Write-Host "✅ Assets precompiled successfully!" -ForegroundColor Green
} else {
    Write-Host "⚠️  Asset precompilation had issues (non-critical)" -ForegroundColor Yellow
}

# Summary
Write-Host ""
Write-Host "=================================" -ForegroundColor Green
Write-Host "✅ SETUP COMPLETED!" -ForegroundColor Green
Write-Host "=================================" -ForegroundColor Green
Write-Host ""
Write-Host "Next steps:" -ForegroundColor Yellow
Write-Host "1. Run the development server:" -ForegroundColor Yellow
Write-Host "   bundle exec rails server" -ForegroundColor Cyan
Write-Host ""
Write-Host "2. Open your browser:" -ForegroundColor Yellow
Write-Host "   http://localhost:3000" -ForegroundColor Cyan
Write-Host ""
Write-Host "3. View all available routes:" -ForegroundColor Yellow
Write-Host "   bundle exec rails routes" -ForegroundColor Cyan
Write-Host ""
Write-Host "For more information, see: HOW_TO_RUN.md" -ForegroundColor Yellow
Write-Host ""

# Ask to run server
Write-Host "Would you like to start the development server now?" -ForegroundColor Yellow
$runServer = Read-Host "(Y/n)"
if ($runServer -ne "N" -and $runServer -ne "n") {
    Write-Host ""
    Write-Host "🚀 Starting Rails Server..." -ForegroundColor Green
    Write-Host "Press Ctrl+C to stop the server" -ForegroundColor Yellow
    Write-Host ""
    bundle exec rails server
} else {
    Write-Host "You can start the server later with: bundle exec rails server" -ForegroundColor Cyan
}
