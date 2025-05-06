from src.helper_functions.verkada_integration.http_utils import requests_with_retry
from requests.exceptions import RequestException

def login_to_verkada(verkada_org_shortname, verkada_org_bot_email, verkada_org_bot_password) -> dict:
    """
    Logs in to Verkada and retrieves the user token and organization ID.
    Args:
        verkada_org_shortname (str): The short name of the Verkada organization.
        verkada_org_bot_email (str): The email of the Verkada bot user.
        verkada_org_bot_password (str): The password of the Verkada bot user.
    Returns:
        dict: A dictionary containing the user token, organization ID, and other relevant information.
    """

    url = f"https://vprovision.command.verkada.com/__v/{verkada_org_shortname}/user/login"
    payload = {
        "email": verkada_org_bot_email,
        "orgShortName": verkada_org_shortname,
        "termsAcked": True,
        "password": verkada_org_bot_password,
        "shard": "prod1", #Only prod1 supported for now due to the significant amount of work to ensure that janitor functions work correctly on other shards
        "subdomain": True,
    }
    headers = {}
    try:
        response = requests_with_retry('post', url, json=payload, headers=headers)
        response_data = response.json()
        verkada_bot_v2 = response_data["userToken"]
        verkada_bot_user_id = response_data["userId"]
        verkada_org_id = response_data["organizationId"]
        
        auth_headers = {
            "X-Verkada-Auth": verkada_bot_v2,
            "X-Verkada-User-id": verkada_bot_user_id,
            "X-Verkada-Organization-Id": verkada_org_id
        }

        user_info = {
            "auth_headers": auth_headers,
            "org_id": verkada_org_id,
            "org_name": verkada_org_shortname,
            "user_id": verkada_bot_user_id,
            "v2": verkada_bot_v2,
            "email": verkada_org_bot_email,
        }

        return user_info
    except RequestException as e:
        # This block executes if the request fails after all retries
        print(f"Login failed after multiple retries: {e}")
        return {}
    except KeyError as e:
        # Handle cases where the successful response JSON is missing expected keys
        print(f"Login succeeded but response format was unexpected. Missing key: {e}")
        # Avoid printing potentially sensitive response data in production logs
        # print(f"Response content: {response.text if 'response' in locals() else 'Response object not available'}")
        return {}
    except Exception as e:
        # Catch any other unexpected errors during processing
        print(f"An unexpected error occurred during login processing: {e}")
        return {}