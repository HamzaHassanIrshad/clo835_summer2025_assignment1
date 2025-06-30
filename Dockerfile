FROM ubuntu:20.04

ENV DEBIAN_FRONTEND=noninteractive
ENV TZ=Etc/UTC

# Install required packages
RUN apt-get update --fix-missing && \
    apt-get install -y tzdata python3-pip default-mysql-client iputils-ping && \
    apt-get clean && rm -rf /var/lib/apt/lists/*

# Set workdir and copy app code
WORKDIR /app
COPY . .

# Install Python dependencies
RUN pip3 install --upgrade pip && pip3 install -r requirements.txt

EXPOSE 8080

CMD ["python3", "app.py"]
