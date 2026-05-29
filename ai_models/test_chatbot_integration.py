import urllib.request
import json
import random

def post_json(url, payload, headers=None):
    if headers is None:
        headers = {}
    headers["Content-Type"] = "application/json"
    headers["Accept"] = "application/json"
    data = json.dumps(payload).encode("utf-8")
    req = urllib.request.Request(url, data=data, headers=headers, method="POST")
    try:
        with urllib.request.urlopen(req, timeout=15) as response:
            return response.status, json.loads(response.read().decode("utf-8"))
    except urllib.error.HTTPError as e:
        try:
            return e.code, json.loads(e.read().decode("utf-8"))
        except Exception:
            return e.code, {"error": e.reason}
    except Exception as e:
        return 500, {"error": str(e)}

def get_json(url, headers=None):
    if headers is None:
        headers = {}
    headers["Accept"] = "application/json"
    req = urllib.request.Request(url, headers=headers, method="GET")
    try:
        with urllib.request.urlopen(req, timeout=15) as response:
            return response.status, json.loads(response.read().decode("utf-8"))
    except urllib.error.HTTPError as e:
        try:
            return e.code, json.loads(e.read().decode("utf-8"))
        except Exception:
            return e.code, {"error": e.reason}
    except Exception as e:
        return 500, {"error": str(e)}

def main():
    print("Testing Laravel Chatbot Integration...")
    base_url = "http://127.0.0.1:8001/api"
    
    # 1. Register a test user
    rand = random.randint(1000, 9999)
    register_payload = {
        "full_name": f"Test Farmer {rand}",
        "phone_number": f"+9477000{rand}",
        "email": f"farmer{rand}@aswenna.com",
        "password": "Password123",
        "province": "Central",
        "district": "Matale",
        "role": "farmer"
    }
    
    print("\n--- 1. Registering test farmer ---")
    status, res = post_json(f"{base_url}/register", register_payload)
    print(f"Status: {status}")
    token = res.get("token")
    if not token:
        print("Registration failed or didn't return a token:", res)
        # Try to log in if already registered
        print("Attempting to login...")
        login_payload = {
            "email": f"farmer{rand}@aswenna.com",
            "password": "Password123"
        }
        status, res = post_json(f"{base_url}/login", login_payload)
        token = res.get("token")
        if not token:
            print("Login failed:", res)
            return
            
    print("Logged in successfully! Token received.")
    headers = {"Authorization": f"Bearer {token}"}
    
    # 2. Create Chat Session
    print("\n--- 2. Creating a new chat session ---")
    status, session_res = post_json(f"{base_url}/chat/session", {}, headers=headers)
    print(f"Status: {status}, Response:", json.dumps(session_res, indent=2))
    session_id = session_res.get("session_id")
    if not session_id:
        print("Failed to create session.")
        return
        
    # 3. Send User Message (Rice cultivation)
    print("\n--- 3. Sending rice cultivation question ---")
    chat_payload = {
        "session_id": session_id,
        "message": "How to grow Bg 352 rice?"
    }
    status, chat_res = post_json(f"{base_url}/chat/send", chat_payload, headers=headers)
    print(f"Status: {status}, Response:", json.dumps(chat_res, indent=2))
    
    # 4. Send User Message (Pest control)
    print("\n--- 4. Sending pest control question ---")
    chat_payload2 = {
        "session_id": session_id,
        "message": "What organic options work against paddy bugs?"
    }
    status, chat_res2 = post_json(f"{base_url}/chat/send", chat_payload2, headers=headers)
    print(f"Status: {status}, Response:", json.dumps(chat_res2, indent=2))
    
    # 5. Fetch Session History
    print("\n--- 5. Loading conversation history using session_id ---")
    status, history_res = get_json(f"{base_url}/chat/session/{session_id}", headers=headers)
    print(f"Status: {status}, Response:", json.dumps(history_res, indent=2))
    
    print("\nEnd-to-end integration test completed successfully!")

if __name__ == '__main__':
    main()
