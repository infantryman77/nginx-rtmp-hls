FROM ubuntu:focal

LABEL maintainer="infantryman77 <fred_d26@hotmail.com>"

# Install dependencies
RUN apt-get update && \
	apt-get install -y \
		wget build-essential ca-certificates && \
    rm -rf /var/lib/apt/lists/*

# Download nginx source
RUN mkdir -p /tmp/build && \
	cd /tmp/build && \
	wget https://nginx.org/download/nginx-1.18.0.tar.gz && \
	tar -zxf nginx-1.18.0.tar.gz && \
	rm nginx-1.18.0.tar.gz

# Download and Decompress RTMP module

RUN cd /tmp/build/ && \
    git clone https://github.com/sergey-dryabzhinsky/nginx-rtmp-module.git

# Build and Install Nginx

# Build nginx with nginx-rtmp module
RUN cd /tmp/build/nginx-1.18.0 && \
    ./configure \
        --sbin-path=/usr/local/sbin/nginx \
        --conf-path=/etc/nginx/nginx.conf \
        --error-log-path=/var/log/nginx/error.log \
        --http-log-path=/var/log/nginx/access.log \		
        --pid-path=/var/run/nginx/nginx.pid \
        --lock-path=/var/lock/nginx.lock \
        --http-client-body-temp-path=/tmp/nginx-client-body \
        --with-http_ssl_module \
        --with-threads \
        --add-module=/tmp/build/nginx-rtmp-module && \
    make -j $(getconf _NPROCESSORS_ONLN) && \
    make install && \
    mkdir /var/lock/nginx

# Forward Logs to Docker

RUN ln -sf /dev/stdout /var/log/nginx/access.log && \
    ln -sf /dev/stderr /var/log/nginx/error.log

# Set up NGINX config file

COPY nginx.conf /etc/nginx/nginx.conf

# RTMP & HLS Ports

EXPOSE 1935 8080

CMD ["nginx", "-g", "daemon off;"]
