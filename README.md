# Project Setup and Usage Guide

## 0. Setting Up on AWS Cloud9

### 1. Launch a Cloud9 Environment
- Create a new Cloud9 environment in your AWS account (preferably in the us-east-1 region).

### 2. Clone this Repository
```
git clone https://github.com/HamzaHassanIrshad/clo835_summer2025_assignment1.git
cd clo835_summer2025_assignment1
```

### 3. Install Python and MySQL Client
```
sudo yum update -y
sudo yum install python3-pip mysql -y
```

### 4. Install Python Dependencies
```
pip3 install -r requirements.txt
```

### 5. Install Docker
```
sudo yum install -y docker
sudo service docker start
sudo usermod -a -G docker ec2-user
```
*You may need to restart your Cloud9 instance or log out/in for Docker group changes to take effect.*

### 6. (Optional) Install Terraform
```
sudo yum install -y yum-utils shadow-utils
sudo yum-config-manager --add-repo https://rpm.releases.hashicorp.com/AmazonLinux/hashicorp.repo
sudo yum -y install terraform
```

---

## 1. Local Development

### Install Python dependencies
```
pip3 install -r requirements.txt
```

### Set environment variables (example values)
```
export DBHOST=localhost
export DBPORT=3306
export DBUSER=root
export DBPWD=pw
export DATABASE=employees
export APP_COLOR=blue
```

### Run the Flask application
```
python3 app.py
```

---

## 2. Dockerized Setup

### Build MySQL Docker image
```
docker build -t my_db -f Dockerfile_mysql .
```

### Build application Docker image
```
docker build -t my_app -f Dockerfile .
```

### Run MySQL container
```
docker run -d -e MYSQL_ROOT_PASSWORD=pw my_db
```

### Get the IP address of the MySQL container
```
docker inspect <container_id>
```

### Set environment variables for the app container (replace <mysql_container_ip> with actual IP)
```
export DBHOST=<mysql_container_ip>
export DBPORT=3306
export DBUSER=root
export DBPWD=pw
export DATABASE=employees
export APP_COLOR=blue
```

### Run the application container
```
docker run -p 8080:8080 \
  -e DBHOST=$DBHOST \
  -e DBPORT=$DBPORT \
  -e DBUSER=$DBUSER \
  -e DBPWD=$DBPWD \
  -e DATABASE=$DATABASE \
  -e APP_COLOR=$APP_COLOR \
  my_app
```

---

## 3. Terraform (AWS EC2)

### Install Terraform (Amazon Linux)
```
sudo yum install -y yum-utils shadow-utils
sudo yum-config-manager --add-repo https://rpm.releases.hashicorp.com/AmazonLinux/hashicorp.repo
sudo yum -y install terraform
```

### Generate SSH Key Pair (for EC2 Access)
```
mkdir -p ~/.ssh
cd ~/.ssh
ssh-keygen -t rsa -b 2048 -f clo835-key
chmod 400 clo835-key
```

### Import SSH Key to AWS
```
aws ec2 import-key-pair \
  --key-name clo835-key \
  --public-key-material fileb://clo835-key.pub \
  --region us-east-1
```

### Initialize and apply Terraform
```
cd terraform
terraform init
terraform apply
```

---

## 4. Database Schema
- The MySQL schema and initial data are defined in `mysql.sql` and are loaded automatically by the MySQL Docker image.

---

## 5. Application Access
- Once the app is running (locally or in Docker), access it at: [http://localhost:8080](http://localhost:8080)

---

## Notes
- Ensure the MySQL container is running and accessible before starting the app.
- Update environment variables as needed for your setup.
- Repository: https://github.com/HamzaHassanIrshad/clo835_summer2025_assignment1