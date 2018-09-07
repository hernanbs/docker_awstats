FROM nginx:1.13.12
LABEL maintainer="Hernan Santos"
LABEL version="1.0"
#Usando debian stretch


#Mudando data e hora
RUN apt -y update && apt install -y tzdata
ENV TZ=America/Sao_Paulo
RUN ln -snf /usr/share/zoneinfo/${TZ} /etc/localtime && echo $TZ > /etc/timezone && dpkg-reconfigure -f noninteractive tzdata  && date
#

# Instalando
RUN rm /etc/nginx/conf.d/default.conf
RUN  ln -sv /srv/nginx.conf /etc/nginx/conf.d/base.conf
RUN apt -y update && apt install -y awstats php7.0-fpm
#

# Criando arquivo de configuração awstats
RUN echo '\
    LogFile="/srv/log/nginx_access.log"\n\
    LogFormat=1\n\
    AllowToUpdateStatsFromBrowser=1\n\
    DNSLookup=1\n\
    DirData="/var/lib/awstats/example.br"\n\
    SiteDomain="example.br"\n\
    HostAliases=localhost\
    example.br\
    www.example.br \
    127.0.0.1\n\
    #Só é necessario se usar dayBYday\n\
    HTMLHeadSection="<script language=javascript src="/js/day-by-day-head.js"></script>"\n\
    HTMLEndSection="<script language=javascript src="/js/day-by-day-end.js"></script>"' > /etc/awstats/awstats.example.br.conf
#

# Modificando arquivos de configuração awstats
RUN cp  /etc/awstats/awstats.conf  /etc/awstats/awstats.conf.backup
WORKDIR /var/lib/awstats/example.br
# awstats.conf.local
RUN sed -i "s/Include \"\/etc\/awstats\/awstats.conf.local\"/#Include \"\/etc\/awstats\/awstats.conf.local\"/" /etc/awstats/awstats.conf.backup
#RUN tail -n3 /etc/awstats/awstats.conf.backup
# awstats.conf
RUN sed -i "s/Include \"\/etc\/awstats\/awstats.conf.local\"/Include \"\/etc\/awstats\/awstats.example.br.conf\"/" /etc/awstats/awstats.conf
#RUN tail -n3 /etc/awstats/awstats.conf
#

#Adicionando servidor e  CGI
RUN  ln -sv /srv/utils-awstats/awstats_server_8081.conf /etc/nginx/conf.d/awstats_server_8081.conf
COPY ./files/cgi-bin.php /etc/nginx/cgi-bin.php
COPY ./files/cgi-bin.php /usr/lib/cgi-bin/cgi-bin.php
#

#Criando pasta DayByDay
WORKDIR /usr/share/awstats/js/
RUN ln -sv /srv/utils-awstats/dayByday/day-by-day-end.js /usr/share/awstats/js/day-by-day-end.js
RUN ln -sv /srv/utils-awstats/dayByday/day-by-day-head.js /usr/share/awstats/js/day-by-day-head.js
#

WORKDIR /home/
#configuração php-fpm
RUN sed -i "s/listen.owner = www-data/listen.owner = nginx/" /etc/php/7.0/fpm/pool.d/www.conf
RUN sed -i "s/listen.group = www-data/listen.group = nginx/" /etc/php/7.0/fpm/pool.d/www.conf
RUN sed -i "s/;listen.mode = 0660/listen.mode = 0666/" /etc/php/7.0/fpm/pool.d/www.conf
RUN sed -i "s/listen = \/run\/php\/php7.0-fpm.sock/listen =\/var\/run\/php\/php7.0-fpm.sock/" /etc/php/7.0/fpm/pool.d/www.conf
RUN /etc/init.d/php7.0-fpm start && /etc/init.d/php7.0-fpm status
#

RUN chown -R www-data.www-data  /var/lib/awstats
CMD service php7.0-fpm start && nginx -g "daemon off;"
#TODO
#necessario fazer fora do docker
#/srv/
#/srv/awstats/
#/srv/db-awstats/example.br
#/srv/log/
#/srv/utils-awstats/dayByday/
#/srv/utils-awstats/awstats_server_8081.conf
#/srv/nginx.conf
#/srv/utils-awstats/index.html
#chown -R www-data.www-data  /srv/db-awstats/
