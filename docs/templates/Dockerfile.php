# PHP Dockerfile Template with Nginx
# Optimized for PHP 8.3 with Nginx web server
#
# Usage:
#   1. Copy this file to your service directory as "Dockerfile"
#   2. Adjust PHP version, extensions, and file paths as needed
#   3. Create nginx.conf in config/ directory
#   4. Build: docker build -t my-service .
#   5. Run: docker run -p 8100:80 my-service

FROM php:8.3-fpm-alpine

# Install system dependencies
RUN apk add --no-cache \
    nginx \
    curl \
    postgresql-dev \
    libzip-dev \
    libpng-dev \
    libjpeg-turbo-dev \
    freetype-dev \
    supervisor

# Install PHP extensions
# Uncomment extensions you need
RUN docker-php-ext-install \
    pdo \
    pdo_pgsql \
    opcache
    # pdo_mysql \
    # mysqli \
    # zip \
    # exif \
    # pcntl \
    # bcmath

# Install additional PHP extensions
# RUN docker-php-ext-configure gd --with-freetype --with-jpeg && \
#     docker-php-ext-install -j$(nproc) gd

# Install Composer
COPY --from=composer:latest /usr/bin/composer /usr/bin/composer

# Set working directory
WORKDIR /var/www/html

# Copy composer files first for better layer caching
# COPY composer.json composer.lock* ./

# Install PHP dependencies (if using Composer)
# RUN composer install --no-dev --optimize-autoloader --no-interaction

# Copy application files
COPY src/ /var/www/html/

# Copy Nginx configuration
# Make sure you have an nginx.conf file in config/
COPY config/nginx.conf /etc/nginx/http.d/default.conf

# Copy Supervisor configuration
COPY config/supervisord.conf /etc/supervisord.conf

# Copy PHP configuration (optional)
# COPY config/php.ini /usr/local/etc/php/conf.d/custom.ini

# Set proper permissions
RUN chown -R www-data:www-data /var/www/html && \
    chmod -R 755 /var/www/html && \
    mkdir -p /var/log/nginx /var/log/php && \
    chown -R www-data:www-data /var/log/nginx /var/log/php

# Create nginx PID directory
RUN mkdir -p /run/nginx && \
    chown -R www-data:www-data /run/nginx

# Expose port 80 (Nginx)
EXPOSE 80

# Health check
HEALTHCHECK --interval=30s --timeout=10s --retries=3 --start-period=10s \
  CMD curl -f http://localhost/health || exit 1

# Use Supervisor to run both PHP-FPM and Nginx
CMD ["/usr/bin/supervisord", "-c", "/etc/supervisord.conf"]

# ============================================
# Example nginx.conf
# ============================================
# Place this in config/nginx.conf:
#
# server {
#     listen 80;
#     server_name _;
#     root /var/www/html;
#     index index.php;
#
#     location / {
#         try_files $uri $uri/ /index.php?$query_string;
#     }
#
#     location ~ \.php$ {
#         fastcgi_pass 127.0.0.1:9000;
#         fastcgi_index index.php;
#         fastcgi_param SCRIPT_FILENAME $document_root$fastcgi_script_name;
#         include fastcgi_params;
#     }
#
#     location ~ /\. {
#         deny all;
#     }
# }

# ============================================
# Example supervisord.conf
# ============================================
# Place this in config/supervisord.conf:
#
# [supervisord]
# nodaemon=true
# user=root
# logfile=/dev/null
# logfile_maxbytes=0
# pidfile=/run/supervisord.pid
#
# [program:php-fpm]
# command=php-fpm -F
# stdout_logfile=/dev/stdout
# stdout_logfile_maxbytes=0
# stderr_logfile=/dev/stderr
# stderr_logfile_maxbytes=0
# autorestart=true
#
# [program:nginx]
# command=nginx -g 'daemon off;'
# stdout_logfile=/dev/stdout
# stdout_logfile_maxbytes=0
# stderr_logfile=/dev/stderr
# stderr_logfile_maxbytes=0
# autorestart=true
