FROM nginx:alpine

# Xóa file c?u hình m?c d?nh c?a nginx
RUN rm /etc/nginx/conf.d/default.conf

# Sao chép file c?u hình nginx tùy ch?nh
COPY docker/nginx.conf /etc/nginx/conf.d/

# Sao chép build web vào thu m?c web c?a nginx
COPY build/web /usr/share/nginx/html

# C?ng mà nginx s? ph?c v?
EXPOSE 80

# L?nh kh?i d?ng khi container ch?y
CMD ["nginx", "-g", "daemon off;"]
