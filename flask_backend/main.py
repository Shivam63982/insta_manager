# main.py
import os
from flask import Flask, request, jsonify
import json
from flask_cors import CORS

app = Flask(__name__)
CORS(app, resources={r"/*": {"origins": "*"}}, methods=["GET", "POST", "OPTIONS"])


credentials_path = os.path.join(os.path.dirname(__file__), "credentials.json")

@app.route("/")
def home():
    return "Instagram App Manager Backend is Running!"

@app.route("/login", methods=["POST"])
def login():
    data = request.get_json()
    username = data.get("username")
    password = data.get("password")

    try:
        with open(credentials_path, "r") as f:
            credentials = json.load(f)

        if username in credentials:
            user_data = credentials[username]
            if user_data["password"] == password:
                return jsonify({
                    "access_token": user_data["access_token"],
                    "ig_user_id": user_data["ig_user_id"]
                }), 200
            else:
                return jsonify({"error": "Invalid password"}), 401
        else:
            return jsonify({"error": "User not found"}), 404

    except Exception as e:
        return jsonify({"error": str(e)}), 500

if __name__ == "__main__":
    app.run(host="0.0.0.0", port=5000, debug=True)
