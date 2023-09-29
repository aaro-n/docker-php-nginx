# 使用基础镜像
FROM debian:stable-slim

# 设置默认环境变量
ARG TIMEZONE=Asia/Shanghai
ENV TZ=$TIMEZONE
ENV NGINX_ROOT_HTML=/home/www/html
ENV NGINX_PORT=8080
ENV PHP_VERSION=7.0

# 添加SURY PHP PPA存储库并安装PHP
RUN apt-get update && apt-get install -y wget apt-transport-https lsb-release ca-certificates \
    && wget -O /etc/apt/trusted.gpg.d/php.gpg https://packages.sury.org/php/apt.gpg \
    && echo "deb https://packages.sury.org/php/ $(lsb_release -sc) main" > /etc/apt/sources.list.d/php.list \
    && apt-get update && apt-get install -y \
    nginx \
    php${PHP_VERSION} \
    php${PHP_VERSION}-fpm \
    php${PHP_VERSION}-xml \
    php${PHP_VERSION}-mbstring \
    php${PHP_VERSION}-tidy \
    php${PHP_VERSION}-curl \
    php${PHP_VERSION}-intl \
    php${PHP_VERSION}-apcu \
    php${PHP_VERSION}-zip \
    cron \
    s6 \
    logrotate \
    tzdata \
    && ln -snf /usr/share/zoneinfo/$TZ /etc/localtime \
    && echo $TZ > /etc/timezone \
    && mkdir -p /home/www/html \
    && mkdir -p /home/www/nginx \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# 将S6配置文件复制到容器
COPY config/s6 /etc/s6
# 将定时任务复制到容器
COPY config/crontab /etc/cron.d/crontab
# 将Nginx复制到容器
COPY config/nginx.conf /etc/nginx/sites-enabled/default
# 显示访问日志
COPY config/logrotate.conf /etc/logrotate.d/logrotate.conf

COPY config/html /home/www/html

# 创建PHP目录
RUN  mkdir -p /run/php/ \
    # 为PHP目录赋予权限
    && chmod -R 755 /run/php/ \
    # 为S6赋予权限
    && chmod -R 755 /etc/s6 \
    # 为定时任务赋予权限
    && chmod 0644 /etc/cron.d/crontab

WORKDIR /home/www

# 启动s6-svscan作为入口命令
CMD ["s6-svscan", "/etc/s6"]

