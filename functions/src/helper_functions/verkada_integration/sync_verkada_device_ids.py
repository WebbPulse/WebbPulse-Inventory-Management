import concurrent.futures
from firebase_admin import firestore
from requests.exceptions import RequestException, JSONDecodeError
from .http_utils import requests_with_retry
from src.shared import db
from functools import partial
from src.helper_functions.verkada_integration.check_verkada_device_type import check_verkada_device_type

# --- Helper function to process a single camera ---
def _process_camera(camera_data: dict, org_id: str):
    """Processes a single camera: finds/creates Firestore doc and updates Verkada ID."""
    verkada_device_id = camera_data.get("cameraId")
    serial_number = camera_data.get("serialNumber")
    device_type = check_verkada_device_type(serial_number)
    if device_type != "Camera":
        print(f"Skipping camera due to device type mismatch: {device_type} for {serial_number}")
        return
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

# --- Helper function to process a single access controller ---
def _process_access_controller(access_controller_data: dict, org_id: str):
    """Processes a single access controller: finds/creates Firestore doc and updates Verkada ID."""
    verkada_device_id = access_controller_data.get("accessControllerId")
    serial_number = access_controller_data.get("serialNumber")
    device_type = check_verkada_device_type(serial_number)
    if device_type != "Access Controller":
        print(f"Skipping access controller due to device type mismatch: {device_type} for {serial_number}")
        return
    if not (verkada_device_id and serial_number):
        print(f"Skipping access controller due to missing ID or Serial: {access_controller_data}")
        return

    try:
        existing_device_query = db.collection('organizations').document(org_id).collection('devices').where('deviceSerialNumber', '==', serial_number).limit(1).get()
        if existing_device_query:
            device_ref = existing_device_query[0].reference
            device_ref.set({
                'deviceVerkadaDeviceId': verkada_device_id,
                'deviceVerkadaDeviceType': "Access Controller", 
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
                'deviceVerkadaDeviceType': "Access Controller",
            })
    except Exception as e:
        print(f"Error processing access controller SN {serial_number}: {e}")

# --- Helper function to process a single env sensor ---
def _process_env_sensor(env_sensor_data: dict, org_id: str):
    """Processes a single env sensor: finds/creates Firestore doc and updates Verkada ID."""
    verkada_device_id = env_sensor_data.get("deviceId")
    serial_number = env_sensor_data.get("claimedSerialNumber")
    device_type = check_verkada_device_type(serial_number)
    if device_type != "Environmental Sensor":
        print(f"Skipping env sensor due to device type mismatch: {device_type} for {serial_number}")
        return
    if not (verkada_device_id and serial_number):
        print(f"Skipping env sensor due to missing ID or Serial: {env_sensor_data}")
        return

    try:
        existing_device_query = db.collection('organizations').document(org_id).collection('devices').where('deviceSerialNumber', '==', serial_number).limit(1).get()
        if existing_device_query:
            device_ref = existing_device_query[0].reference
            device_ref.set({
                'deviceVerkadaDeviceId': verkada_device_id,
                'deviceVerkadaDeviceType': "Environmental Sensor", 
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
                'deviceVerkadaDeviceType': "Environmental Sensor", 
            })
    except Exception as e:
        print(f"Error processing env sensor SN {serial_number}: {e}")

    # --- Helper function to process a single env sensor ---
def _process_desk_station(desk_station_data: dict, org_id: str):
    """Processes a single desk station: finds/creates Firestore doc and updates Verkada ID."""
    verkada_device_id = desk_station_data.get("deviceId")
    serial_number = desk_station_data.get("serialNumber")
    device_type = check_verkada_device_type(serial_number)
    if device_type != "Desk Station":
        print(f"Skipping desk station due to device type mismatch: {device_type} for {serial_number}")
        return
    if not (verkada_device_id and serial_number):
        print(f"Skipping desk station due to missing ID or Serial: {desk_station_data}")
        return

    try:
        existing_device_query = db.collection('organizations').document(org_id).collection('devices').where('deviceSerialNumber', '==', serial_number).limit(1).get()
        if existing_device_query:
            device_ref = existing_device_query[0].reference
            device_ref.set({
                'deviceVerkadaDeviceId': verkada_device_id,
                'deviceVerkadaDeviceType': "Desk Station", 
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
                'deviceVerkadaDeviceType': "Desk Station", 
            })
    except Exception as e:
        print(f"Error processing desk station SN {serial_number}: {e}")

    # --- Helper function to process a single env sensor ---
def _process_intercom(intercom_data: dict, org_id: str):
    """Processes a single intercom: finds/creates Firestore doc and updates Verkada ID."""
    verkada_device_id = intercom_data.get("deviceId")
    serial_number = intercom_data.get("serialNumber")
    device_type = check_verkada_device_type(serial_number)
    if device_type != "Intercom":
        print(f"Skipping intercom due to device type mismatch: {device_type} for {serial_number}")
        return
    if not (verkada_device_id and serial_number):
        print(f"Skipping intercom due to missing ID or Serial: {intercom_data}")
        return

    try:
        existing_device_query = db.collection('organizations').document(org_id).collection('devices').where('deviceSerialNumber', '==', serial_number).limit(1).get()
        if existing_device_query:
            device_ref = existing_device_query[0].reference
            device_ref.set({
                'deviceVerkadaDeviceId': verkada_device_id,
                'deviceVerkadaDeviceType': "Intercom",
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
                'deviceVerkadaDeviceType': "Intercom",
            })
    except Exception as e:
        print(f"Error processing intercom SN {serial_number}: {e}")


def _process_gateway(gateway_data: dict, org_id: str):
    """Processes a single gateway: finds/creates Firestore doc and updates Verkada ID."""
    verkada_device_id = gateway_data.get("device_id")
    serial_number = gateway_data.get("claimed_serial_number")
    device_type = check_verkada_device_type(serial_number)
    if device_type != "Gateway":
        print(f"Skipping gateway due to device type mismatch: {device_type} for {serial_number}")
        return
    if not (verkada_device_id and serial_number):
        print(f"Skipping gateway due to missing ID or Serial: {gateway_data}")
        return

    try:
        existing_device_query = db.collection('organizations').document(org_id).collection('devices').where('deviceSerialNumber', '==', serial_number).limit(1).get()
        if existing_device_query:
            device_ref = existing_device_query[0].reference
            device_ref.set({
                'deviceVerkadaDeviceId': verkada_device_id,
                'deviceVerkadaDeviceType': "Gateway",
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
                'deviceVerkadaDeviceType': "Gateway",
            })
    except Exception as e:
        print(f"Error processing gateway SN {serial_number}: {e}")

def _process_command_connector(command_connector_data: dict, org_id: str):
    """Processes a single command connector: finds/creates Firestore doc and updates Verkada ID."""
    verkada_device_id = command_connector_data.get("deviceId")
    serial_number = command_connector_data.get("claimedSerialNumber")
    device_type = check_verkada_device_type(serial_number)
    if device_type != "Command Connector":
        print(f"Skipping command connector due to device type mismatch: {device_type} for {serial_number}")
        return
    if not (verkada_device_id and serial_number):
        print(f"Skipping command connector due to missing ID or Serial: {command_connector_data}")
        return

    try:
        existing_device_query = db.collection('organizations').document(org_id).collection('devices').where('deviceSerialNumber', '==', serial_number).limit(1).get()
        if existing_device_query:
            device_ref = existing_device_query[0].reference
            device_ref.set({
                'deviceVerkadaDeviceId': verkada_device_id,
                'deviceVerkadaDeviceType': "Command Connector",
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
                'deviceVerkadaDeviceType': "Command Connector",
            })
    except Exception as e:
        print(f"Error processing command connector SN {serial_number}: {e}")

def _process_viewing_station(viewing_station_data: dict, org_id: str):
    """Processes a single viewing station: finds/creates Firestore doc and updates Verkada ID."""
    verkada_device_id = viewing_station_data.get("viewingStationId")
    serial_number = viewing_station_data.get("claimedSerialNumber")
    device_type = check_verkada_device_type(serial_number)
    if device_type != "Viewing Station":
        print(f"Skipping viewing station due to device type mismatch: {device_type} for {serial_number}")
        return
    if not (verkada_device_id and serial_number):
        print(f"Skipping viewing station due to missing ID or Serial: {viewing_station_data}")
        return

    try:
        existing_device_query = db.collection('organizations').document(org_id).collection('devices').where('deviceSerialNumber', '==', serial_number).limit(1).get()
        if existing_device_query:
            device_ref = existing_device_query[0].reference
            device_ref.set({
                'deviceVerkadaDeviceId': verkada_device_id,
                'deviceVerkadaDeviceType': "Viewing Station",
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
                'deviceVerkadaDeviceType': "Viewing Station",
            })
    except Exception as e:
        print(f"Error processing viewing station SN {serial_number}: {e}")
def _process_speaker(speaker_data: dict, org_id: str):
    """Processes a single speaker: finds/creates Firestore doc and updates Verkada ID."""
    verkada_device_id = speaker_data.get("deviceId")
    serial_number = speaker_data.get("serialNumber")
    device_type = check_verkada_device_type(serial_number)
    if device_type != "Speaker":
        print(f"Skipping speaker due to device type mismatch: {device_type} for {serial_number}")
        return
    if not (verkada_device_id and serial_number):
        print(f"Skipping speaker due to missing ID or Serial: {speaker_data}")
        return

    try:
        existing_device_query = db.collection('organizations').document(org_id).collection('devices').where('deviceSerialNumber', '==', serial_number).limit(1).get()
        if existing_device_query:
            device_ref = existing_device_query[0].reference
            device_ref.set({
                'deviceVerkadaDeviceId': verkada_device_id,
                'deviceVerkadaDeviceType': "Speaker",
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
                'deviceVerkadaDeviceType': "Speaker",
            })
    except Exception as e:
        print(f"Error processing speaker SN {serial_number}: {e}")

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

    def sync_intercom_and_desk_station_ids():
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

    def sync_gateway_ids():
        url = f"https://vnet.command.verkada.com/__v/{verkada_org_shortname}/devices/list"
        payload = {"organizationId": verkada_org_id}
        gateways = []
        
        try:
            response = requests_with_retry('post', url, headers=auth_headers, json=payload)
            response.raise_for_status()
            gateways = response.json()

        except RequestException as e:
            print(f"Error fetching gateway info after retries: {e}")
            return
        except JSONDecodeError as e:
            print(f"Error decoding JSON response for gateway: {e}")
            return
        except Exception as e:
            print(f"An unexpected error occurred during gateway fetch: {e}")
            return

        if not gateways:
            print("No gateways found to process.")
            return
        

        process_gateway_with_org = partial(_process_gateway, org_id=org_id)
        with concurrent.futures.ThreadPoolExecutor(max_workers=10) as executor:
            list(executor.map(process_gateway_with_org, gateways))
        print(f"Finished processing {len(gateways)} gateways.")
        
    
    def sync_command_connector_ids():
        url = f"https://vprovision.command.verkada.com/__v/{verkada_org_shortname}/vfortress/list_boxes"
        payload = {}
        command_connectors = []
        try:
            response = requests_with_retry('get', url, headers=auth_headers, json=payload)
            response.raise_for_status()
            command_connectors = response.json()
        except RequestException as e:
            print(f"Error fetching command connector info after retries: {e}")
            return
        except JSONDecodeError as e:
            print(f"Error decoding JSON response for command connector: {e}")
            return
        except Exception as e:
            print(f"An unexpected error occurred during command connector fetch: {e}")
            return

        if not command_connectors:
            print("No command connectors found to process.")
            return

        process_command_connector_with_org = partial(_process_command_connector, org_id=org_id)

        with concurrent.futures.ThreadPoolExecutor(max_workers=10) as executor:
            list(executor.map(process_command_connector_with_org, command_connectors))

        print(f"Finished processing {len(command_connectors)} command connectors.")
    

    def sync_viewing_station_ids():
        url = f"https://vvx.command.verkada.com/__v/{verkada_org_shortname}/device/list"
        payload = {"organizationId": verkada_org_id}
        viewing_stations = []
        print(f"Fetching viewing stations for org: {verkada_org_shortname} with ID: {verkada_org_id}")
        try:
            response = requests_with_retry('post', url, headers=auth_headers, json=payload)
            response.raise_for_status()
            viewing_stations = response.json().get("viewingStations", [])
        except RequestException as e:
            print(f"Error fetching viewing station info after retries: {e}")
            return
        except JSONDecodeError as e:
            print(f"Error decoding JSON response for viewing station: {e}")
            return
        except Exception as e:
            print(f"An unexpected error occurred during viewing station fetch: {e}")
            return

        if not viewing_stations:
            print("No viewing stations found to process.")
            return
        process_viewing_station_with_org = partial(_process_viewing_station, org_id=org_id)

        with concurrent.futures.ThreadPoolExecutor(max_workers=10) as executor:
            list(executor.map(process_viewing_station_with_org, viewing_stations))

        print(f"Finished processing {len(viewing_stations)} viewing stations.")

    def sync_speaker_ids():
        url = f"https://vbroadcast.command.verkada.com/__v/{verkada_org_shortname}/management/speaker/list"
        payload = {"organizationId": verkada_org_id}
        speakers = []
        try:
            response = requests_with_retry('post', url, headers=auth_headers, json=payload)
            response.raise_for_status()
            speakers = response.json().get("garfunkel", [])
        except RequestException as e:
            print(f"Error fetching speaker info after retries: {e}")
            return
        except JSONDecodeError as e:
            print(f"Error decoding JSON response for speaker: {e}")
            return
        except Exception as e:
            print(f"An unexpected error occurred during speaker fetch: {e}")
            return

        if not speakers:
            print("No speakers found to process.")
            return

        process_speaker_with_org = partial(_process_speaker, org_id=org_id)

        with concurrent.futures.ThreadPoolExecutor(max_workers=10) as executor:
            list(executor.map(process_speaker_with_org, speakers))

        print(f"Finished processing {len(speakers)} speakers.")


    with concurrent.futures.ThreadPoolExecutor(max_workers=10) as executor:
        futures = [
            executor.submit(sync_camera_ids),
            executor.submit(sync_access_controller_ids),
            executor.submit(sync_env_sensor_ids),
            executor.submit(sync_intercom_and_desk_station_ids),
            executor.submit(sync_gateway_ids),
            executor.submit(sync_command_connector_ids),
            executor.submit(sync_viewing_station_ids),
            executor.submit(sync_speaker_ids),
        ]
        for future in concurrent.futures.as_completed(futures):
            try:
                future.result()
            except Exception as exc:
                print(f'A sync function generated an exception: {exc}')

    print(f"Completed all Verkada device sync for org: {org_id}")