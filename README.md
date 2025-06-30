# Project Setup and Usage Guide

## 1. Setting Up on AWS Cloud9

### Step 1: Launch a Cloud9 Environment
- Create a new Cloud9 environment in your AWS account (preferably in the us-east-1 region).

### Step 2: Clone this Repository
```bash
git clone https://github.com/HamzaHassanIrshad/clo835_summer2025_assignment1.git
cd clo835_summer2025_assignment1
```

### Step 3: Install Required Tools
```bash
sudo yum install -y python3-pip mysql || sudo dnf install -y python3-pip mysql
sudo yum install -y docker || sudo dnf install -y docker
```
*If you encounter issues, try searching for available packages with `yum search mysql` or `dnf search mysql`.*

### Step 4: Start Docker and Set Permissions
```bash
sudo service docker start
sudo usermod -a -G docker ec2-user
```
*You may need to restart your Cloud9 instance or log out/in for Docker group changes to take effect.*

### Step 5: Install Python Dependencies
```bash
pip3 install -r requirements.txt
```

---

## 2. Running the Application

### Option A: Local Python (for development/testing)
1. Set environment variables (example values):
    ```bash
    export DBHOST=localhost
    export DBPORT=3306
    export DBUSER=root
    export DBPWD=pw
    export DATABASE=employees
    export APP_COLOR=blue
    ```
2. Run the Flask application:
    ```bash
    python3 app.py
    ```

### Option B: Dockerized (recommended for consistency)
1. Build Docker images:
    ```bash
    docker build -t my_db -f Dockerfile_mysql .
    docker build -t my_app -f Dockerfile .
    ```
2. Run MySQL container:
    ```bash
    docker run -d -e MYSQL_ROOT_PASSWORD=pw my_db
    ```
3. Get the IP address of the MySQL container:
    ```bash
    docker inspect <container_id>
    ```
4. Set environment variables for the app container (replace <mysql_container_ip> with actual IP):
    ```bash
    export DBHOST=<mysql_container_ip>
    export DBPORT=3306
    export DBUSER=root
    export DBPWD=pw
    export DATABASE=employees
    export APP_COLOR=blue
    ```
5. Run the application container:
    ```bash
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

## 3. (Optional) Infrastructure as Code with Terraform (AWS EC2)

### Step 1: Install Terraform
```bash
sudo yum install -y yum-utils shadow-utils
sudo yum-config-manager --add-repo https://rpm.releases.hashicorp.com/AmazonLinux/hashicorp.repo
sudo yum -y install terraform
```

### Step 2: Generate SSH Key Pair (for EC2 Access)
```bash
mkdir -p ~/.ssh
cd ~/.ssh
ssh-keygen -t rsa -b 2048 -f clo835-key
chmod 400 clo835-key
```

### Step 3: Import SSH Key to AWS
```bash
aws ec2 import-key-pair \
  --key-name clo835-key \
  --public-key-material fileb://clo835-key.pub \
  --region us-east-1
```

### Step 4: Initialize and Apply Terraform
```bash
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