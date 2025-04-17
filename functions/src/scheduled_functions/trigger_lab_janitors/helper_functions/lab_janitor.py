from firebase_functions import scheduler_fn
import requests
import json

@scheduler_fn.on_schedule(schedule="every day 00:00")
def lab_janitor_scheduled():
    with open('config.json') as f:
        config = json.load(f)
    org_name = config["org_name"]

    def login():
        url = f"https://vprovision.command.verkada.com/__v/{org_name}/user/login"
        payload = {
            "email": config["bot_email"],
            "orgShortName": org_name,
            "termsAcked": True,
            "password": config["bot_password"],
            "shard": "prod1",
            "subdomain": True,
        }
        headers = {}
        response = requests.post(url, json=payload, headers=headers)
        if response.status_code == 200:
            print("Login successful")
            response_data = response.json()

            v2 = response_data["userToken"]
            user_id = response_data["userId"]
            org_id = response_data["organizationId"]
            auth_headers = {
                "x-verkada-auth": v2,
                "x-verkada-user": user_id,
                "x-verkada-organization": org_id
            }

            user_info = {
                "auth_headers": auth_headers,
                "org_id": org_id,
                "org_name": org_name,
                "user_id": user_id,
                "v2": v2,
            }

            return user_info
        else:
            print("Login failed")
            return None
    user_info = login()