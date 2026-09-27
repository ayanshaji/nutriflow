# ============================================================
# BACKEND
# ============================================================

FROM node:22-alpine AS backend

WORKDIR /app

COPY backend/package*.json ./

RUN npm ci --omit=dev

COPY backend/ .

EXPOSE 8000

CMD ["npm", "start"]


# ============================================================
# FRONTEND BUILD
# ============================================================

FROM node:22-alpine AS frontend-build

WORKDIR /app

COPY frontend/package*.json ./

RUN npm ci

COPY frontend/ .

RUN npm run build


# ============================================================
# FRONTEND RUNTIME
# ============================================================

FROM nginx:alpine AS frontend

COPY --from=frontend-build /app/dist /usr/share/nginx/html

# SPA routing + backend reverse proxy
RUN printf '%s\n' \
'server {' \
'    listen 80;' \
'    server_name _;' \
'' \
'    root /usr/share/nginx/html;' \
'    index index.html;' \
'' \
'    location / {' \
'        try_files $uri $uri/ /index.html;' \
'    }' \
'' \
'    location /nutriflow/ {' \
'        proxy_pass http://nutriflow-backend:8000;' \
'        proxy_http_version 1.1;' \
'        proxy_set_header Host $host;' \
'        proxy_set_header X-Real-IP $remote_addr;' \
'        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;' \
'        proxy_set_header X-Forwarded-Proto $scheme;' \
'    }' \
'}' \
> /etc/nginx/conf.d/default.conf

EXPOSE 80

CMD ["nginx", "-g", "daemon off;"]
