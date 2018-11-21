#!/usr/bin/env bash

mkdir /etc/nginx/ssl 2>/dev/null

PATH_SSL="/etc/nginx/ssl"
PATH_KEY="${PATH_SSL}/${1}.key"
PATH_CSR="${PATH_SSL}/${1}.csr"
PATH_CRT="${PATH_SSL}/${1}.crt"

export DEBIAN_FRONTEND=noninteractive
sudo apt-get update
sudo apt- get install php5.6-mcrypt php5.6-curl php5.6-intl php5.6-xsl php5.6-mbstring php5.6-zip php5.6-bcmath php5.6-iconv php5.6-soap

if [ ! -f $PATH_KEY ] || [ ! -f $PATH_CSR ] || [ ! -f $PATH_CRT ]
then
  openssl genrsa -out "$PATH_KEY" 2048 2>/dev/null
  openssl req -new -key "$PATH_KEY" -out "$PATH_CSR" -subj "/CN=$1/O=Vagrant/C=UK" 2>/dev/null
  openssl x509 -req -days 365 -in "$PATH_CSR" -signkey "$PATH_KEY" -out "$PATH_CRT" 2>/dev/null
fi

block="server {
    listen ${3:-80};
    listen ${4:-443} ssl http2;
    server_name $1;
    root \$MAGE_ROOT;
    index index.php;
    autoindex off;
    charset UTF-8;
    error_page 404 403 = /errors/404.php;
    #add_header "X-UA-Compatible" "IE=Edge";

# Denied locations require a "^~" to prevent regexes (such as the PHP handler below) from matching
        # http://nginx.org/en/docs/http/ngx_http_core_module.html#location
        location ^~ /app/                       { return 403; }
        location ^~ /includes/                  { return 403; }
        location ^~ /media/downloadable/        { return 403; }
        location ^~ /pkginfo/                   { return 403; }
        location ^~ /report/config.xml          { return 403; }
        location ^~ /var/                       { return 403; }
        location ^~ /lib/                       { return 403; }
        location ^~ /dev/                       { return 403; }
        location ^~ /RELEASE_NOTES.txt          { return 403; }
        location ^~ /downloader/pearlib         { return 403; }
        location ^~ /downloader/template        { return 403; }
        location ^~ /downloader/Maged           { return 403; }
        location ~* ^/errors/.+\.xml            { return 403; }






location /media/ {
    try_files \$uri \$uri/ /get.php\$is_args\$args;
    location ~ ^/media/theme_customization/.*\.xml {
        deny all;
    }
    location ~* \.(ico|jpg|jpeg|png|gif|svg|js|css|swf|eot|ttf|otf|woff|woff2)$ {
        add_header Cache-Control 'public';
        add_header X-Frame-Options 'SAMEORIGIN';
        expires +1y;
        try_files \$uri \$uri/ /get.php\$is_args\$args;
    }
    location ~* \.(zip|gz|gzip|bz2|csv|xml)$ {
        add_header Cache-Control 'no-store';
        add_header X-Frame-Options 'SAMEORIGIN';
        expires    off;
        try_files \$uri \$uri/ /get.php\$is_args\$args;
    }
    add_header X-Frame-Options 'SAMEORIGIN';
}
location /media/customer/ {
    deny all;
}
location /media/downloadable/ {
    deny all;
}
location /media/import/ {
    deny all;
}
# PHP entry point for main application
location ~ (index|get|static|report|404|503|health_check)\.php$ {
    try_files \$uri =404;
    fastcgi_pass unix:/var/run/php/php5.6-fpm.sock;
    fastcgi_buffers 1024 4k;
    fastcgi_param  PHP_FLAG  'session.auto_start=off \n suhosin.session.cryptua=off';
    fastcgi_param  PHP_VALUE 'memory_limit=756M \n max_execution_time=18000';
    fastcgi_read_timeout 600s;
    fastcgi_connect_timeout 600s;
    fastcgi_index  index.php;
    fastcgi_param  SCRIPT_FILENAME  \$document_root\$fastcgi_script_name;
    include        fastcgi_params;
}
gzip on;
gzip_disable 'msie6';
gzip_comp_level 6;
gzip_min_length 1100;
gzip_buffers 16 8k;
gzip_proxied any;
gzip_types
    text/plain
    text/css
    text/js
    text/xml
    text/javascript
    application/javascript
    application/x-javascript
    application/json
    application/xml
    application/xml+rss
    image/svg+xml;
gzip_vary on;
# Banned locations (only reached if the earlier PHP entry point regexes don't match)
location ~* (\.php$|\.htaccess$|\.git) {
    deny all;
}
}"

echo "$block" > "/etc/nginx/sites-available/$1"
ln -fs "/etc/nginx/sites-available/$1" "/etc/nginx/sites-enabled/$1"
