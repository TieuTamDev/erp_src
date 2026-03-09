@echo off
REM CAPP ERP - Automatic Setup Script for Windows CMD
REM Run as: setup.bat

color 0A
echo.
echo ========================================
echo   CAPP ERP - Windows Setup Script
echo ========================================
echo.

REM Check Ruby Installation
echo Checking Ruby installation...
ruby --version >nul 2>&1
if errorlevel 1 (
    color 0C
    echo.
    echo ERROR: Ruby not found!
    echo Please install Ruby from: https://rubyinstaller.org/
    echo.
    pause
    exit /b 1
)
color 0A
echo OK - Ruby found

REM Check Bundler
echo Checking Bundler...
bundle --version >nul 2>&1
if errorlevel 1 (
    echo Installing Bundler...
    gem install bundler
)
echo OK - Bundler found

echo.
echo Step 1: Installing Ruby Gems...
echo ========================================
bundle install
if errorlevel 1 (
    color 0C
    echo ERROR: Bundle install failed!
    pause
    exit /b 1
)
color 0A

echo.
echo Step 2: Creating Database...
echo ========================================
bundle exec rake db:create
if errorlevel 1 (
    echo WARNING: Database creation failed (might already exist)
) else (
    echo OK - Database created
)

echo.
echo Step 3: Running Migrations...
echo ========================================
bundle exec rake db:migrate
if errorlevel 1 (
    color 0C
    echo ERROR: Migrations failed!
    pause
    exit /b 1
)
color 0A

echo.
echo Step 4: Precompiling Assets...
echo ========================================
bundle exec rails assets:precompile >nul 2>&1

echo.
echo ========================================
echo   SETUP COMPLETED!
echo ========================================
echo.
echo Next Steps:
echo 1. Start the server: bundle exec rails server
echo 2. Open browser: http://localhost:3000
echo.
echo For more info, see: HOW_TO_RUN.md
echo.

set /p run_server="Would you like to start the development server? (Y/n): "
if /i "%run_server%"=="n" (
    echo.
    echo You can start the server later with: bundle exec rails server
    pause
    exit /b 0
)

echo.
echo Starting Rails Server...
echo Press Ctrl+C to stop
echo.
bundle exec rails server
