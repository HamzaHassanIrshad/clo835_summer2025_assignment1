CREATE DATABASE IF NOT EXISTS employees;
USE employees;

CREATE TABLE IF NOT EXISTS employee(
emp_id VARCHAR(20),
first_name VARCHAR(20),
last_name VARCHAR(20),
primary_skill VARCHAR(20),
location VARCHAR(20));

INSERT INTO employee VALUES ('1','Amanda','Williams','Smile','local');
INSERT INTO employee VALUES ('2','Alan','Williams','Empathy','alien');
INSERT INTO employee VALUES ('3','John','Doe','Python','remote');
INSERT INTO employee VALUES ('4','Jane','Smith','Java','office');
SELECT * FROM employee;