from flask import Flask, request, jsonify, render_template, session
from flask_cors import CORS
import requests
import json
import os

app = Flask(__name__)
app.secret_key = "supersecretkey"  # Needed for session
CORS(app, resources={r"/*": {"origins": "*"}}, methods=["GET", "POST", "OPTIONS"])

# ---------- Session Helper Functions ----------
def set_active_user(user_data):
    session["ig_user_id"] = user_data["ig_user_id"]
    session["access_token"] = user_data["access_token"]

def get_active_user():
    return {
        "ig_user_id": session.get("ig_user_id"),
        "access_token": session.get("access_token")
    }

# ---------- Routes ----------


@app.route("/")
def home():
    return "Instagram App Manager Backend is running!"

@app.route("/login", methods=["POST"])
def login():
    data = request.get_json()
    username = data.get("username")
    password = data.get("password")

    try:
        credentials_path = os.path.join(os.path.dirname(__file__), "credentials.json")
        with open(credentials_path, "r") as f:
            credentials = json.load(f)

        if username in credentials:
            user_data = credentials[username]
            if user_data["password"] == password:
                set_active_user(user_data)
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

# ---------- Dynamic IG API Call Example ----------
@app.route("/conversations", methods=["GET"])

def fetch_conversations():
    access_token = request.args.get("access_token")
    ig_user_id = request.args.get("ig_user_id")
    url = "https://graph.instagram.com/v23.0/me/conversations"
    payload = {
        "platform": "instagram",
        "access_token": access_token,
        "fields": "id,participants,updated_time"
    }

    try:
        response = requests.get(url, params=payload)
        data = response.json()
        users = {}

        for convo in data.get("data", []):
            participants = convo.get("participants", {}).get("data", [])

            for person in participants:
                user_id = person.get("id")

                if not user_id or user_id in users:
                    continue

                try:

                    profile_url = f"https://graph.instagram.com/v23.0/{user_id}"
                    profile_payload = {
                        "fields": "username,name,profile_pic",
                        "access_token": access_token
                        }

                    profile_res = requests.get(profile_url, params=profile_payload)
                    profile_data = profile_res.json()

                    # print(f"📦 Profile for {user_id}:\n{json.dumps(profile_data, indent=2)}")

                    users[user_id] = {
                        "id": user_id,
                        "username": profile_data.get("username", f"user_{user_id[-4:]}"),
                        "name": profile_data.get("name", profile_data.get("username", "")),
                        "profile_pic": profile_data.get("profile_picture_url") or profile_data.get("profile_pic", "")
                    }

                except Exception as e:
                    print(f"⚠️ Failed to fetch profile for {user_id}:", e)
                    users[user_id] = {
                        "id": user_id,
                        "username": f"user_{user_id[-4:]}",
                        "name": "",
                        "profile_pic": ""
                    }

        # ✅ Save all users locally
        with open("known_users.json", "w") as f:
            json.dump(users, f, indent=4)

        return users

        with open("known_users.json", "r") as f:
            known_users = json.load(f)

        return jsonify(known_users), 200

    except Exception as e:
        print("⚠️ Failed to fetch conversations:", e)
        return {}


def fetch_user_messages_from_graph(user_id):
    access_token = request.args.get("access_token")
    ig_user_id = request.args.get("ig_user_id")
    try:
        print(f"▶️ Fetching messages for user: {user_id}")

        # STEP 1: Get all conversation IDs
        url = "https://graph.instagram.com/v23.0/me/conversations"
        payload = {
            "access_token": access_token,
            "fields": "participants"
        }
        convo_response = requests.get(url=url, params=payload)
        data = convo_response.json()
        # print("🔍 Conversations fetched:", json.dumps(data, indent=2))

        # STEP 2: Find the correct conversation ID for this user
        convo_id = None
        for convo in data.get("data", []):
            participants = convo.get("participants", {}).get("data", [])
            print("🧩 Participants in convo:", [p.get("id") for p in participants])
            for person in participants:
                if person.get("id") == user_id:
                    convo_id = convo.get("id")
                    break
            if convo_id:
                break

        if not convo_id:
            print("❌ No conversation found for user:", user_id)
            return []

        print("✅ Found conversation_id:", convo_id)

        # STEP 3: Fetch messages
        msg_url = f"https://graph.instagram.com/v23.0/{convo_id}"
        msg_params = {
            "fields": "messages{id,created_time,from,to,message,is_unsupported}",
            "access_token": access_token
        }
        msg_response = requests.get(msg_url, params=msg_params)
        messages_data = msg_response.json()
        # print("📦 Messages response:", json.dumps(messages_data, indent=2))

        all_messages = []

        for msg in messages_data.get("messages", {}).get("data", []):
            # print("\n🟡 Processing message:", msg.get("message"))

            from_id = msg.get("from", {}).get("id")
            to_data = msg.get("to", {}).get("data", [])
            to_ids = [t.get("id") for t in to_data]

            # print(f"   🔹 from_id = {from_id}")
            # print(f"   🔹 to_ids = {to_ids}")
            # print(f"   🔹 user_id = {user_id}")

            # ✅ Detect sender: if it's from the user, it's user message. Otherwise bot.
            if from_id == user_id:
                sender_type = "bot"
            else:
                sender_type = "user"

            all_messages.append({
                "timestamp": msg.get("created_time"),
                "sender": sender_type,
                "text": msg.get("message", "").strip()
            })

        # STEP 4: Sort and save
        all_messages.sort(key=lambda x: x["timestamp"])

        file_path = f"messages_{user_id}.json"
        with open(file_path, "w") as f:
            json.dump(all_messages, f, indent=4)

        # print(f"✅ Saved {len(all_messages)} messages to {file_path}")
        return all_messages

    except Exception as e:
        print("❌ Exception while fetching messages:", e)
        return []

@app.route("/fetch_messages/<user_id>", methods=["GET"])
def fetch_and_return_messages(user_id):
    try:
        messages = fetch_user_messages_from_graph(user_id)
        return jsonify(messages), 200
    except Exception as e:
        return jsonify({"error": str(e)}), 500



if __name__ == "__main__":
    app.run(host="0.0.0.0", port=5000, debug=True)
