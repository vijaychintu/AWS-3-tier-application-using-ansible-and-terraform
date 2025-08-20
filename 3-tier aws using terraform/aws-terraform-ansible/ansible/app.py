from flask import Flask
import os
app = Flask(__name__)

@app.get("/")
def hello():
    db = os.getenv("APP_DB_URI", "not-configured")
    return f"Hello from Ansible! DB: {db}"

if __name__ == "__main__":
    app.run(host="0.0.0.0", port=8000)
