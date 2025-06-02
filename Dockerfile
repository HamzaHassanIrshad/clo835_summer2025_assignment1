FROM ubuntu:20.04

ENV DEBIAN_FRONTEND=noninteractive
ENV TZ=Etc/UTC

# Clean, update, fix dpkg, and install necessary packages
RUN apt-get clean && \
    apt-get update --fix-missing && \
    apt-get install -y tzdata && \
    apt-get install -y python3-pip default-mysql-client iputils-ping && \
    dpkg --configure -a && \
    apt-get clean

# Copy source code
COPY . /app
WORKDIR /app

# Install Python dependencies
RUN pip3 install --upgrade pip
RUN pip3 install -r requirements.txt

EXPOSE 8080

ENTRYPOINT ["python3"]
CMD ["app.py"]
