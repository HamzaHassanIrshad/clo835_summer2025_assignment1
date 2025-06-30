from flask import Flask, render_template, request, g
from pymysql import connections
import os
import random
import argparse

app = Flask(__name__)

# Get DB config from environment or set defaults
def get_db_config():
    return {
        'host': os.environ.get("DBHOST", "localhost"),
        'user': os.environ.get("DBUSER", "root"),
        'password': os.environ.get("DBPWD", "password"),
        'db': os.environ.get("DATABASE", "employees"),
        'port': int(os.environ.get("DBPORT", "3306")),
    }

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
SUPPORTED_COLORS = list(color_codes.keys())

def get_color():
    # Priority: app config > ENV > random
    color = app.config.get("COLOR_OVERRIDE")
    if color:
        return color
    color_env = os.environ.get("APP_COLOR")
    if color_env and color_env in color_codes:
        return color_env
    return random.choice(SUPPORTED_COLORS)

@app.before_request
def before_request():
    g.db_conn = None
    try:
        g.db_conn = connections.Connection(**get_db_config())
    except Exception as e:
        g.db_conn = None
        g.db_error = str(e)

@app.teardown_request
def teardown_request(exception):
    db_conn = getattr(g, 'db_conn', None)
    if db_conn:
        db_conn.close()

@app.route("/", methods=['GET', 'POST'])
def home():
    return render_template('addemp.html', color=color_codes[get_color()])

@app.route("/about", methods=['GET','POST'])
def about():
    return render_template('about.html', color=color_codes[get_color()])

@app.route("/addemp", methods=['POST'])
def AddEmp():
    if not getattr(g, 'db_conn', None):
        return render_template('error.html', message=f"Database connection failed: {getattr(g, 'db_error', 'Unknown error')}")

    emp_id = request.form['emp_id']
    first_name = request.form['first_name']
    last_name = request.form['last_name']
    primary_skill = request.form['primary_skill']
    location = request.form['location']

    insert_sql = "INSERT INTO employee VALUES (%s, %s, %s, %s, %s)"
    cursor = g.db_conn.cursor()

    try:
        cursor.execute(insert_sql, (emp_id, first_name, last_name, primary_skill, location))
        g.db_conn.commit()
        emp_name = f"{first_name} {last_name}"
    finally:
        cursor.close()

    return render_template('addempoutput.html', name=emp_name, color=color_codes[get_color()])

@app.route("/getemp", methods=['GET', 'POST'])
def GetEmp():
    return render_template("getemp.html", color=color_codes[get_color()])

@app.route("/fetchdata", methods=['GET','POST'])
def FetchData():
    if not getattr(g, 'db_conn', None):
        return render_template('error.html', message=f"Database connection failed: {getattr(g, 'db_error', 'Unknown error')}")

    emp_id = request.form['emp_id']
    select_sql = "SELECT emp_id, first_name, last_name, primary_skill, location FROM employee WHERE emp_id=%s"
    cursor = g.db_conn.cursor()

    output = {}
    try:
        cursor.execute(select_sql, (emp_id,))
        result = cursor.fetchone()
        if result:
            output["emp_id"], output["first_name"], output["last_name"], output["primary_skills"], output["location"] = result
        else:
            return render_template('error.html', message="Employee not found.")
    finally:
        cursor.close()

    return render_template("getempoutput.html", id=output["emp_id"], fname=output["first_name"],
                           lname=output["last_name"], interest=output["primary_skills"],
                           location=output["location"], color=color_codes[get_color()])

if __name__ == '__main__':
    parser = argparse.ArgumentParser()
    parser.add_argument('--color', required=False)
    args = parser.parse_args()

    if args.color and args.color in color_codes:
        app.config["COLOR_OVERRIDE"] = args.color
    elif args.color:
        print(f"Color '{args.color}' not supported. Must be one of {', '.join(SUPPORTED_COLORS)}")
        exit(1)

    app.run(host='0.0.0.0', port=8080, debug=True)
