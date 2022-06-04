#   cs-cart-4.14.x.tpl
#   HestiaCP & CS-Cart 4.14.x Nginx config, by karen.marketing
#   Place this file /usr/local/hestia/data/templates/web/nginx/php-fpm
#### Testing was successfully carried out on HestiaCP 1.5.15.

server {
    listen      %ip%:%web_port%;
    server_name %domain_idn% %alias_idn%;
    root        %docroot%;
    index       index.php index.html index.htm;
    access_log  /var/log/nginx/domains/%domain%.log combined;
    access_log  /var/log/nginx/domains/%domain%.bytes bytes;
    error_log   /var/log/nginx/domains/%domain%.error.log error;
        
    include %home%/%user%/conf/web/%domain%/nginx.forcessl.conf*;

    ####    CS-Cart config     ####
    ############################################################################

    #   Кодировка по умолчанию
    charset utf-8;

    ############################################################################

    #   Сжатие
    gzip on;
    gzip_disable "msie6";
    gzip_comp_level 2;
    gzip_min_length  1100;
    gzip_buffers 16 8k;
    gzip_proxied any;
    gzip_types text/plain application/xml
    application/javascript
    text/css
    text/js
    text/xml
    application/x-javascript
    text/javascript
    application/json
    application/xml+rss;

    ############################################################################

    #   Прочие настройки
    client_max_body_size            100m;
    client_body_buffer_size         128k;
    client_header_timeout           3m;
    client_body_timeout             3m;
    send_timeout                    3m;
    client_header_buffer_size       1k;
    large_client_header_buffers     4 16k;

    ############################################################################
    
    error_page 598 = @backend;

    ############################################################################


    location @backend {
        try_files $uri $uri/ /$2$3 /$3 /index.php  =404;
        #   Путь к сокету PHP-FPM
        #fastcgi_pass unix:/var/run/php5-fpm.sock;
        fastcgi_pass    %backend_lsnr%;
        #
        fastcgi_index index.php;
        fastcgi_read_timeout 360;
        #   Добавляем содержимое fastcgi_params.conf
        ################################################################################
        fastcgi_param  QUERY_STRING       $query_string;
        fastcgi_param  REQUEST_METHOD     $request_method;
        fastcgi_param  CONTENT_TYPE       $content_type;
        fastcgi_param  CONTENT_LENGTH     $content_length;
        fastcgi_param  SCRIPT_NAME        $fastcgi_script_name;
        fastcgi_param  REQUEST_URI        $request_uri;
        fastcgi_param  DOCUMENT_URI       $document_uri;
        fastcgi_param  DOCUMENT_ROOT      $document_root;
        fastcgi_param  SERVER_PROTOCOL    $server_protocol;
        fastcgi_param  HTTPS              $https if_not_empty;
        fastcgi_param  GATEWAY_INTERFACE  CGI/1.1;
        fastcgi_param  SERVER_SOFTWARE    nginx/$nginx_version;
        fastcgi_param  REMOTE_ADDR        $remote_addr;
        fastcgi_param  REMOTE_PORT        $remote_port;
        fastcgi_param  SERVER_ADDR        $server_addr;
        fastcgi_param  SERVER_PORT        $server_port;
        fastcgi_param  SERVER_NAME        $server_name;
        fastcgi_param  SCRIPT_FILENAME    $document_root$fastcgi_script_name;
        fastcgi_param  REDIRECT_STATUS    200;
        ################################################################################
    }

    ############################################################################

    location  / {
        index  index.php index.html index.htm;
        try_files $uri $uri/ /index.php?$args;


        ####    HestiaCP conf /  ####

        location ~* ^.+\.(jpeg|jpg|png|webp|gif|bmp|ico|svg|css|js)$ {
            expires     max;
            fastcgi_hide_header "Set-Cookie";
        }

        location ~ [^/]\.php(/|$) {
            fastcgi_param SCRIPT_FILENAME $document_root$fastcgi_script_name;
            if (!-f $document_root$fastcgi_script_name) {
                return  404;
            }

            fastcgi_pass    %backend_lsnr%;
            fastcgi_index   index.php;
            include         /etc/nginx/fastcgi_params;
            include     %home%/%user%/conf/web/%domain%/nginx.fastcgi_cache.conf*;
        }

        ####    END HestiaCP conf /  ####    
    }

    ############################################################################

    location ~ ^/(\w+/)?(\w+/)?api/ {
        rewrite ^/(\w+/)?(\w+/)?api/(.*)$ /api.php?_d=$3&ajax_custom=1&$args last;
        rewrite_log off;
    }

    ############################################################################

    location ~ ^/(\w+/)?(\w+/)?var/database/ {
        return 404;
    }

    location ~ ^/(\w+/)?(\w+/)?var/backups/ {
        return 404;
    }

    location ~ ^/(\w+/)?(\w+/)?var/restore/ {
        return 404;
    }

    location ~ ^/(\w+/)?(\w+/)?var/themes_repository/ {
        allow all;
        location ~* \.(tpl|php.?)$ {
            return 404;
        }
    }

    location ~ ^/(\w+/)?(\w+/)?var/ {
        return 404;
        location ~* /(\w+/)?(\w+/)?(.+\.(js|css|png|jpe?g|gz|yml|xml))$ {
            try_files $uri $uri/ /$2$3 /$3 /index.php?$args;
            allow all;
            access_log off;
            expires 1M;
            add_header Cache-Control public;
            add_header Access-Control-Allow-Origin *;
        }
    }

    ############################################################################

    location ~ ^/(\w+/)?(\w+/)?app/payments/ {
        return 404;
        location ~ \.php$ {
            return 598;
        }
    }

    location ~ ^/(\w+/)?(\w+/)?app/addons/rus_exim_1c/ {
        return 404;
        location ~ \.php$ {
            return 598;
        }
    }

    location ~ ^/(\w+/)?(\w+/)?app/ {
        return 404;
    }

    ############################################################################

    location ~ ^/(favicon|apple-touch-icon|homescreen-|firefox-icon-|coast-icon-|mstile-).*\.(png|ico)$  {
        access_log off;
        try_files $uri =404;
        expires max;
        add_header Access-Control-Allow-Origin *;
        add_header Cache-Control public;
    }

    location ~* /(\w+/)?(\w+/)?(.+\.(jpe?g|jpg|ico|gif|png|css|js|pdf|txt|tar|woff|svg|ttf|eot|csv|zip|xml|yml))$ {
        access_log off;
        try_files $uri $uri/ /$2$3 /$3 /index.php?$args;
        expires max;
        add_header Access-Control-Allow-Origin *;
        add_header Cache-Control public;
    }

    ############################################################################

    location ~ ^/(\w+/)?(\w+/)?design/ {
        allow all;
        location ~* \.(tpl|php.?)$ {
            return 404;
        }
    }

    ############################################################################

    location ~ ^/(\w+/)?(\w+/)?images/ {
        allow all;
        location ~* \.(php.?)$ {
            return 404;
        }
    }

    ############################################################################

    location ~ ^/(\w+/)?(\w+/)?js/ {
        allow all;
        location ~* \.(php.?)$ {
            return 404;
        }
    }

    ############################################################################

    location ~ ^/(\w+/)?(\w+/)?init.php {
        return 404;
    }

    location ~* \.(tpl.?)$ {
        return 404;
    }

    location ~ /\.(ht|git) {
        return 404;
    }

    location ~* \.php$ {
        return 598 ;
    }

    ################################################################################
    ####    END CS-Cart config     ####

    ########    HestiaCP conf       ########

/*  location / {

        location ~* ^.+\.(jpeg|jpg|png|webp|gif|bmp|ico|svg|css|js)$ {
            expires     max;
            fastcgi_hide_header "Set-Cookie";
        }

        location ~ [^/]\.php(/|$) {
            fastcgi_param SCRIPT_FILENAME $document_root$fastcgi_script_name;
            if (!-f $document_root$fastcgi_script_name) {
                return  404;
            }

            fastcgi_pass    %backend_lsnr%;
            fastcgi_index   index.php;
            include         /etc/nginx/fastcgi_params;
            include     %home%/%user%/conf/web/%domain%/nginx.fastcgi_cache.conf*;     
        }
    }*/
    
    location /error/ {
        alias   %home%/%user%/web/%domain%/document_errors/;
    }

    location ~ /\.(?!well-known\/) { 
       deny all; 
       return 404;
    }

    location /vstats/ {
        alias   %home%/%user%/web/%domain%/stats/;
        include %home%/%user%/web/%domain%/stats/auth.conf*;
    }

    include     /etc/nginx/conf.d/phpmyadmin.inc*;
    include     /etc/nginx/conf.d/phppgadmin.inc*;
    include     %home%/%user%/conf/web/%domain%/nginx.conf_*;

    ########    END HestiaCP conf   ########
}
