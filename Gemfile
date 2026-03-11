source 'https://rubygems.org'

git_source(:github) do |repo_name|
  repo_name = "#{repo_name}/#{repo_name}" unless repo_name.include?("/")
  "https://github.com/#{repo_name}.git"
end


# Bundle edge Rails instead: gem 'rails', github: 'rails/rails'
gem 'rails', '~> 5.0.7', '>= 5.0.7.2'
# Use mysql as the database for Active Record
gem 'mysql2', '>= 0.3.18', '< 0.6.0'
# Use Puma as the app server
gem 'puma', '~> 3.0'
# Use SCSS for stylesheets
gem 'sass-rails', '~> 5.0'
# Use Uglifier as compressor for JavaScript assets
gem 'uglifier', '>= 1.3.0'
# Use CoffeeScript for .coffee assets and views
gem 'coffee-rails', '~> 4.2'
# See https://github.com/rails/execjs#readme for more supported runtimes
# gem 'therubyracer', platforms: :ruby

# Use jquery as the JavaScript library
gem 'jquery-rails'
# Turbolinks makes navigating your web application faster. Read more: https://github.com/turbolinks/turbolinks
gem 'turbolinks', '~> 5'
# Build JSON APIs with ease. Read more: https://github.com/rails/jbuilder
gem 'jbuilder', '~> 2.5'
# Use Redis adapter to run Action Cable in production
# gem 'redis', '~> 3.0'
# Use ActiveModel has_secure_password
# gem 'bcrypt', '~> 3.1.7'

# Use Capistrano for deployment
# gem 'capistrano-rails', group: :development

gem 'rack-cors', :require => 'rack/cors'

gem 'grape'

gem 'grape-swagger'

gem 'bootstrap-sass', '~> 3.3.1'
# gem 'sass-rails', github: 'rails/sass-rails'
# gem 'autoprefixer-rails'

gem "font-awesome-rails"

gem 'bootstrap_form'

gem 'seed_dump'

gem 'bcrypt', '~> 3.1.7'

gem 'data-confirm-modal'

gem 'has_secure_token'
# Datetime picker
gem 'momentjs-rails', '>= 2.9.0'
gem 'bootstrap3-datetimepicker-rails', '~> 4.17.47'
gem 'autoprefixer-rails', '~> 7.1.6'

gem 'tzinfo'
gem "chartkick"
gem 'groupdate'
gem 'rest-client'
gem 'gon'

# PDF Export lib. VU: 06/01/2023
gem 'wicked_pdf'
gem 'wkhtmltopdf-binary', '0.12.3.1'

# export excel. 13/2/2023
gem "roo"
gem "roo-xls"

gem 'rubyzip', '~> 1.1.0'
gem 'axlsx', '2.1.0.pre'
gem 'axlsx_rails'

gem 'apnotic'

gem "sprockets-rails"
gem 'ffi'
gem 'httparty'
gem 'fcm'

gem 'prawn'
gem 'combine_pdf'

gem 'lazy_high_charts'

group :development, :test do
  # Call 'byebug' anywhere in the code to stop execution and get a debugger console
  gem 'byebug', platform: :mri
end

group :development do
  # Access an IRB console on exception pages or by using <%= console %> anywhere in the code.
  gem 'web-console', '>= 3.3.0'
  gem 'listen', '~> 3.0.5'
  # Spring speeds up development by keeping your application running in the background. Read more: https://github.com/rails/spring
  gem 'spring'
  gem 'spring-watcher-listen', '~> 2.0.0'
end

# Windows does not include zoneinfo files, so bundle the tzinfo-data gem
gem 'tzinfo-data', platforms: [:mingw, :mswin, :x64_mingw, :jruby]
gem 'simple_captcha2', require: 'simple_captcha'
