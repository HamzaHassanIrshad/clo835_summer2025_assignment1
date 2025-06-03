# Install the required MySQL package

sudo apt-get update -y
sudo apt-get install mysql-client -y

# Running application locally
pip3 install -r requirements.txt
sudo python3 app.py
# Building and running 2 tier web application locally
### Building mysql docker image 
```docker build -t my_db -f Dockerfile_mysql . ```

### Building application docker image 
```docker build -t my_app -f Dockerfile . ```

### Running mysql
```docker run -d -e MYSQL_ROOT_PASSWORD=pw  my_db```


### Get the IP of the database and export it as DBHOST variable
```docker inspect <container_id>```


### Example when running DB runs as a docker container and app is running locally
```
export DBHOST=127.0.0.1
export DBPORT=3307
```
### Example when running DB runs as a docker container and app is running locally
```
export DBHOST=172.17.0.2
export DBPORT=3306
```
```
export DBUSER=root
export DATABASE=employees
export DBPWD=pw
export APP_COLOR=blue
```
### Run the application, make sure it is visible in the browser
```docker run -p 8080:8080  -e DBHOST=$DBHOST -e DBPORT=$DBPORT -e  DBUSER=$DBUSER -e DBPWD=$DBPWD  my_app```

## 🔧 Setting Up Terraform and SSH Key (Cloud9 / EC2)

### Install Terraform on Amazon Linux
```bash
sudo yum install -y yum-utils shadow-utils
sudo yum-config-manager --add-repo https://rpm.releases.hashicorp.com/AmazonLinux/hashicorp.repo
sudo yum -y install terraform
```

### Generate SSH Key Pair (for EC2 Access)
```bash
mkdir -p ~/.ssh
cd ~/.ssh
ssh-keygen -t rsa -b 2048 -f clo835-key
chmod 400 clo835-key
```

### Import SSH Key to AWS
```bash
aws ec2 import-key-pair \
  --key-name clo835-key \
  --public-key-material fileb://clo835-key.pub \
  --region us-east-1
```
