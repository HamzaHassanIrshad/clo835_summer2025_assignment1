from flask import Flask, render_template, request
from pymysql import connections
import os
import random
import argparse

app = Flask(__name__)

# Get DB config from environment or set defaults
DBHOST = os.environ.get("DBHOST", "localhost")
DBUSER = os.environ.get("DBUSER", "root")
DBPWD = os.environ.get("DBPWD", "password")
DATABASE = os.environ.get("DATABASE", "employees")
DBPORT = int(os.environ.get("DBPORT", "3306"))
COLOR_FROM_ENV = os.environ.get("APP_COLOR", "lime")

# Define supported color codes
color_codes = {
    "red": "#e74c3c",
    "green": "#16a085",
    "blue": "#89CFF0",
    "blue2": "#30336b",
    "pink": "#f4c2c2",
    "darkblue": "#130f40",
    "lime": "#C1FF9C",
}
SUPPORTED_COLORS = ",".join(color_codes.keys())
COLOR = random.choice(list(color_codes.keys()))

# Connect to MySQL
try:
    db_conn = connections.Connection(
        host=DBHOST,
        port=DBPORT,
        user=DBUSER,
        password=DBPWD,
        db=DATABASE
    )
except Exception as e:
    print(f"❌ Failed to connect to MySQL: {e}")
    db_conn = None

@app.route("/", methods=['GET', 'POST'])
def home():
    return render_template('addemp.html', color=color_codes[COLOR])

@app.route("/about", methods=['GET','POST'])
def about():
    return render_template('about.html', color=color_codes[COLOR])

@app.route("/addemp", methods=['POST'])
def AddEmp():
    if not db_conn:
        return "Database connection failed.", 500

    emp_id = request.form['emp_id']
    first_name = request.form['first_name']
    last_name = request.form['last_name']
    primary_skill = request.form['primary_skill']
    location = request.form['location']

    insert_sql = "INSERT INTO employee VALUES (%s, %s, %s, %s, %s)"
    cursor = db_conn.cursor()

    try:
        cursor.execute(insert_sql, (emp_id, first_name, last_name, primary_skill, location))
        db_conn.commit()
        emp_name = f"{first_name} {last_name}"
    finally:
        cursor.close()

    return render_template('addempoutput.html', name=emp_name, color=color_codes[COLOR])

@app.route("/getemp", methods=['GET', 'POST'])
def GetEmp():
    return render_template("getemp.html", color=color_codes[COLOR])

@app.route("/fetchdata", methods=['GET','POST'])
def FetchData():
    if not db_conn:
        return "Database connection failed.", 500

    emp_id = request.form['emp_id']
    select_sql = "SELECT emp_id, first_name, last_name, primary_skill, location FROM employee WHERE emp_id=%s"
    cursor = db_conn.cursor()

    output = {}
    try:
        cursor.execute(select_sql, (emp_id,))
        result = cursor.fetchone()
        if result:
            output["emp_id"], output["first_name"], output["last_name"], output["primary_skills"], output["location"] = result
        else:
            return "Employee not found.", 404
    finally:
        cursor.close()

    return render_template("getempoutput.html", id=output["emp_id"], fname=output["first_name"],
                           lname=output["last_name"], interest=output["primary_skills"],
                           location=output["location"], color=color_codes[COLOR])

if __name__ == '__main__':
    parser = argparse.ArgumentParser()
    parser.add_argument('--color', required=False)
    args = parser.parse_args()

    if args.color:
        COLOR = args.color
        if COLOR_FROM_ENV:
            print(f"A color was set through environment variable ({COLOR_FROM_ENV}). Argument takes precedence.")
    elif COLOR_FROM_ENV:
        COLOR = COLOR_FROM_ENV

    if COLOR not in color_codes:
        print(f"Color '{COLOR}' not supported. Must be one of {SUPPORTED_COLORS}")
        exit(1)

    app.run(host='0.0.0.0', port=8080, debug=True)
