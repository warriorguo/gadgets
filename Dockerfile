FROM nginx:1.27-alpine

COPY index.html .nojekyll /usr/share/nginx/html/
COPY assets/   /usr/share/nginx/html/assets/
COPY markdown/ /usr/share/nginx/html/markdown/
COPY json/     /usr/share/nginx/html/json/
COPY code/     /usr/share/nginx/html/code/
COPY log/      /usr/share/nginx/html/log/

EXPOSE 80
