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
                'deviceVerkadaDeviceType': "Camera",  #Need to fix later
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
                'deviceVerkadaDeviceType': "Camera", #Need to fix later
            })
    except Exception as e:
        print(f"Error processing camera SN {serial_number}: {e}")

# --- Helper function to process a single access controller ---
def _process_access_controller(access_controller_data: dict, org_id: str):
    """Processes a single access controller: finds/creates Firestore doc and updates Verkada ID."""
    verkada_device_id = access_controller_data.get("accessControllerId")
    serial_number = access_controller_data.get("serialNumber")
    if not (verkada_device_id and serial_number):
        print(f"Skipping access controller due to missing ID or Serial: {access_controller_data}")
        return

    try:
        existing_device_query = db.collection('organizations').document(org_id).collection('devices').where('deviceSerialNumber', '==', serial_number).limit(1).get()
        if existing_device_query:
            device_ref = existing_device_query[0].reference
            device_ref.set({
                'deviceVerkadaDeviceId': verkada_device_id,
                'deviceVerkadaDeviceType': "Access Controller", #Need to fix later
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
                'deviceVerkadaDeviceType': "Access Controller", #Need to fix later
            })
    except Exception as e:
        print(f"Error processing access controller SN {serial_number}: {e}")

# --- Helper function to process a single env sensor ---
def _process_env_sensor(env_sensor_data: dict, org_id: str):
    """Processes a single env sensor: finds/creates Firestore doc and updates Verkada ID."""
    verkada_device_id = env_sensor_data.get("deviceId")
    serial_number = env_sensor_data.get("claimedSerialNumber")
    if not (verkada_device_id and serial_number):
        print(f"Skipping env sensor due to missing ID or Serial: {env_sensor_data}")
        return

    try:
        existing_device_query = db.collection('organizations').document(org_id).collection('devices').where('deviceSerialNumber', '==', serial_number).limit(1).get()
        if existing_device_query:
            device_ref = existing_device_query[0].reference
            device_ref.set({
                'deviceVerkadaDeviceId': verkada_device_id,
                'deviceVerkadaDeviceType': "Environmental Sensor", #Need to fix later
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
                'deviceVerkadaDeviceType': "Environmental Sensor", #Need to fix later
            })
    except Exception as e:
        print(f"Error processing env sensor SN {serial_number}: {e}")

    # --- Helper function to process a single env sensor ---
def _process_desk_station(desk_station_data: dict, org_id: str):
    """Processes a single desk station: finds/creates Firestore doc and updates Verkada ID."""
    verkada_device_id = desk_station_data.get("deviceId")
    serial_number = desk_station_data.get("serialNumber")
    if not (verkada_device_id and serial_number):
        print(f"Skipping desk station due to missing ID or Serial: {desk_station_data}")
        return

    try:
        existing_device_query = db.collection('organizations').document(org_id).collection('devices').where('deviceSerialNumber', '==', serial_number).limit(1).get()
        if existing_device_query:
            device_ref = existing_device_query[0].reference
            device_ref.set({
                'deviceVerkadaDeviceId': verkada_device_id,
                'deviceVerkadaDeviceType': "Desk Station", #Need to fix later
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
                'deviceVerkadaDeviceType': "Desk Station", #Need to fix later
            })
    except Exception as e:
        print(f"Error processing desk station SN {serial_number}: {e}")

    # --- Helper function to process a single env sensor ---
def _process_intercom(intercom_data: dict, org_id: str):
    """Processes a single intercom: finds/creates Firestore doc and updates Verkada ID."""
    verkada_device_id = intercom_data.get("deviceId")
    serial_number = intercom_data.get("serialNumber")
    if not (verkada_device_id and serial_number):
        print(f"Skipping intercom due to missing ID or Serial: {intercom_data}")
        return

    try:
        existing_device_query = db.collection('organizations').document(org_id).collection('devices').where('deviceSerialNumber', '==', serial_number).limit(1).get()
        if existing_device_query:
            device_ref = existing_device_query[0].reference
            device_ref.set({
                'deviceVerkadaDeviceId': verkada_device_id,
                'deviceVerkadaDeviceType': "Intercom", #Need to fix later
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
                'deviceVerkadaDeviceType': "Intercom", #Need to fix later
            })
    except Exception as e:
        print(f"Error processing intercom SN {serial_number}: {e}")


def sync_verkada_device_ids(org_id, verkada_bot_user_info: dict) -> None:
    verkada_org_shortname = verkada_bot_user_info.get("org_name")
    verkada_org_id = verkada_bot_user_info.get("org_id")
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
        url = f"https://vcerberus.command.verkada.com/__v/{verkada_org_shortname}/access/v2/user/access_controllers"
        payload = {}
        access_controllers = []
        try:
            response = requests_with_retry('get', url, headers=auth_headers, json=payload)
            response.raise_for_status()
            access_controllers = response.json().get("accessControllers", [])
        except RequestException as e:
            print(f"Error fetching access controller info after retries: {e}")
            return
        except JSONDecodeError as e:
            print(f"Error decoding JSON response for access controllers: {e}")
            return
        except Exception as e:
            print(f"An unexpected error occurred during access controller fetch: {e}")
            return

        if not access_controllers:
            print("No access controllers found to process.")
            return

        process_access_controller_with_org = partial(_process_access_controller, org_id=org_id)

        with concurrent.futures.ThreadPoolExecutor(max_workers=10) as executor:
            list(executor.map(process_access_controller_with_org, access_controllers))

        print(f"Finished processing {len(access_controllers)} access controllers.")

    def sync_env_sensor_ids():
        url = f"https://vsensor.command.verkada.com/__v/{verkada_org_shortname}/devices/list"
        payload = {"organizationId": verkada_org_id, "favoritesOnly":False}
        env_sensors = []
        try:
            response = requests_with_retry('post', url, headers=auth_headers, json=payload)
            response.raise_for_status()
            env_sensors = response.json().get("sensorDevice", [])
        except RequestException as e:
            print(f"Error fetching env sensor info after retries: {e}")
            return
        except JSONDecodeError as e:
            print(f"Error decoding JSON response for env sensor: {e}")
            return
        except Exception as e:
            print(f"An unexpected error occurred during env sensor fetch: {e}")
            return

        if not env_sensors:
            print("No env sensors found to process.")
            return

        process_env_sensor_with_org = partial(_process_env_sensor, org_id=org_id)

        with concurrent.futures.ThreadPoolExecutor(max_workers=10) as executor:
            list(executor.map(process_env_sensor_with_org, env_sensors))

        print(f"Finished processing {len(env_sensors)} env sensors.")

    def sync_intercom_and_deskstation_ids():
        url = f"https://api.command.verkada.com/__v/{verkada_org_shortname}/vinter/v1/user/organization/{verkada_org_id}/device"
        payload = {}
        desk_stations = []
        intercoms = []
        try:
            response = requests_with_retry('get', url, headers=auth_headers, json=payload)
            response.raise_for_status()
            desk_stations = response.json().get("deskApps", [])
            intercoms = response.json().get("intercoms", [])

        except RequestException as e:
            print(f"Error fetching intercom and desk station info after retries: {e}")
            return
        except JSONDecodeError as e:
            print(f"Error decoding JSON response for intercom or desk station: {e}")
            return
        except Exception as e:
            print(f"An unexpected error occurred during desk station/intercom fetch: {e}")
            return

        if not desk_stations and not intercoms:
            print("No desk stations or intercoms found to process.")
            return
        

        process_desk_station_with_org = partial(_process_desk_station, org_id=org_id)
        with concurrent.futures.ThreadPoolExecutor(max_workers=10) as executor:
            list(executor.map(process_desk_station_with_org, desk_stations))
        print(f"Finished processing {len(desk_stations)} desk stations.")
        
        process_intercom_with_org = partial(_process_intercom, org_id=org_id)
        with concurrent.futures.ThreadPoolExecutor(max_workers=10) as executor:
            list(executor.map(process_intercom_with_org, intercoms))
        print(f"Finished processing {len(intercoms)} intercoms.")


    with concurrent.futures.ThreadPoolExecutor(max_workers=4) as executor:
        futures = [
            executor.submit(sync_camera_ids),
            executor.submit(sync_access_controller_ids),
            executor.submit(sync_env_sensor_ids),
            executor.submit(sync_intercom_and_deskstation_ids),
        ]
        for future in concurrent.futures.as_completed(futures):
            try:
                future.result()
            except Exception as exc:
                print(f'A sync function generated an exception: {exc}')

    print(f"Completed all Verkada device sync for org: {org_id}")