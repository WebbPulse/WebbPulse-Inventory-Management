import concurrent.futures
from firebase_admin import firestore
from requests.exceptions import RequestException, JSONDecodeError
from .http_utils import requests_with_retry
from src.shared import db
from functools import partial

# --- Helper function to process a single camera ---
def _process_camera(camera_data: dict, org_id: str):
    """Processes a single camera: finds/creates Firestore doc and updates Verkada ID."""
    verkada_device_id = camera_data.get("cameraId")
    serial_number = camera_data.get("serialNumber")
    if not (verkada_device_id and serial_number):
        print(f"Skipping camera due to missing ID or Serial: {camera_data}")
        return

    try:
        existing_device_query = db.collection('organizations').document(org_id).collection('devices').where('deviceSerialNumber', '==', serial_number).limit(1).get()
        if existing_device_query:
            device_ref = existing_device_query[0].reference
            device_ref.set({
                'deviceVerkadaDeviceId': verkada_device_id,
                'deviceVerkadaDeviceType': "Camera",
            }, merge=True)
        else:
            device_ref = db.collection('organizations').document(org_id).collection('devices').document()
            device_ref.set({
                'deviceId': device_ref.id,
                'deviceSerialNumber': serial_number,
                'deviceVerkadaDeviceId': verkada_device_id,
                'createdAt': firestore.SERVER_TIMESTAMP,
                'isDeviceCheckedOut': False,
                'deviceCheckedOutBy': '',
                'deviceCheckedOutAt': None,
                'deviceDeleted': False,
                'deviceVerkadaDeviceType': "Camera",
            })
    except Exception as e:
        print(f"Error processing camera SN {serial_number}: {e}")
# --- End Helper Function ---


def sync_verkada_device_ids(org_id, verkada_bot_user_info: dict) -> None:
    verkada_org_shortname = verkada_bot_user_info.get("org_name")
    auth_headers = verkada_bot_user_info.get("auth_headers")

    def sync_camera_ids():
        url = f"https://vappinit.command.verkada.com/__v/{verkada_org_shortname}/app/v2/init"
        payload = {"fieldsToSkip": ["permissions"]}
        cameras = []
        try:
            response = requests_with_retry('post', url, headers=auth_headers, json=payload)
            response.raise_for_status()
            cameras = response.json().get("cameras", [])
        except RequestException as e:
            print(f"Error fetching camera info after retries: {e}")
            return
        except JSONDecodeError as e:
            print(f"Error decoding JSON response for cameras: {e}")
            return
        except Exception as e:
            print(f"An unexpected error occurred during camera fetch: {e}")
            return

        if not cameras:
            print("No cameras found to process.")
            return

        process_camera_with_org = partial(_process_camera, org_id=org_id)

        with concurrent.futures.ThreadPoolExecutor(max_workers=10) as executor:
            list(executor.map(process_camera_with_org, cameras))

        print(f"Finished processing {len(cameras)} cameras.")

    def sync_access_controller_ids():
        print("Syncing access controller IDs (Not Implemented Yet)")
        pass

    with concurrent.futures.ThreadPoolExecutor(max_workers=2) as executor:
        futures = [
            executor.submit(sync_camera_ids),
            executor.submit(sync_access_controller_ids),
        ]
        for future in concurrent.futures.as_completed(futures):
            try:
                future.result()
            except Exception as exc:
                print(f'A sync function generated an exception: {exc}')

    print(f"Completed all Verkada device sync for org: {org_id}")