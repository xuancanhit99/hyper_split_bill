FROM nginx:alpine

# X�a file c?u h�nh m?c d?nh c?a nginx
RUN rm /etc/nginx/conf.d/default.conf

# Sao ch�p file c?u h�nh nginx t�y ch?nh
COPY docker/nginx.conf /etc/nginx/conf.d/

# Sao ch�p build web v�o thu m?c web c?a nginx
COPY build/web /usr/share/nginx/html

# C?ng m� nginx s? ph?c v?
EXPOSE 80

# L?nh kh?i d?ng khi container ch?y
CMD ["nginx", "-g", "daemon off;"]
