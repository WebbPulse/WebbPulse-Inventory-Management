from src.shared import db
from .http_utils import requests_with_retry
from requests.exceptions import RequestException
import logging

def sync_verkada_user_groups(org_id, verkada_bot_user_info):
    """
    Syncs user groups from Verkada to the Firestore database.
    """
    print("Syncing Verkada user groups...")
    verkada_org_id = verkada_bot_user_info.get('org_id')
    verkada_bot_user_id = verkada_bot_user_info.get('user_id')
    verkada_bot_headers = verkada_bot_user_info.get('auth_headers')

    def fetch_verkada_user_groups(verkada_org_id, verkada_bot_user_id):
        """
        Fetches user groups from Verkada.
        """
        url = f"https://vauth.command.verkada.com/__v/webbpulse/security_entity_group/list"
        payload = {
            "organizationId": verkada_org_id,
            "includeMembers": False,
            "includeMemberCount": False,
        }
        response = requests_with_retry(
            "post",
            url=url,
            headers=verkada_bot_headers,
            json=payload
        )
        user_groups = response.json().get("securityEntityGroup", [])
        print(f"Fetched {len(user_groups)} user groups from Verkada.")
        if not user_groups:
            logging.warning("No user groups found in the response.")
            return []
        return [
            {
                "groupId": group.get("entityGroupId"),
                "groupName": group.get("name"),
            }
            for group in user_groups
            if group.get("entityGroupId") and group.get("name") is not None
        ]
    def update_firestore_with_user_groups(org_id, user_groups):
        """
        Updates Firestore with the fetched user groups.
        """
        org_ref = db.collection('organizations').document(org_id).collection('sensitiveConfigs').document('verkadaIntegrationSettings')
        org_ref.set({
            'orgVerkadaUserGroups': user_groups
        }, merge=True)

    # Fetch user groups from Verkada
    user_groups = fetch_verkada_user_groups(verkada_org_id, verkada_bot_user_id)

    # Update Firestore with the fetched user groups
    update_firestore_with_user_groups(org_id, user_groups)
