import requests
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

def _process_classic_alarm_keypad(classic_alarm_keypad_data: dict, org_id: str):
    """Processes a single classic alarm keypad: finds/creates Firestore doc and updates Verkada ID."""
    verkada_device_id = classic_alarm_keypad_data.get("deviceId")
    serial_number = classic_alarm_keypad_data.get("claimedSerialNumber")

    if not (verkada_device_id and serial_number):
        print(f"Skipping classic alarm keypad due to missing ID or Serial: {classic_alarm_keypad_data}")
        return

    try:
        existing_device_query = db.collection('organizations').document(org_id).collection('devices').where('deviceSerialNumber', '==', serial_number).limit(1).get()
        if existing_device_query:
            device_ref = existing_device_query[0].reference
            device_ref.set({
                'deviceVerkadaDeviceId': verkada_device_id,
                'deviceVerkadaDeviceType': "Classic Alarm Keypad",
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
                'deviceVerkadaDeviceType': "Classic Alarm Keypad",
            })
    except Exception as e:
        print(f"Error processing classic alarm keypad SN {serial_number}: {e}")


def _process_classic_alarm_hub_device(classic_alarm_hub_device_data: dict, org_id: str):
    """Processes a single classic alarm hub device: finds/creates Firestore doc and updates Verkada ID."""
    verkada_device_id = classic_alarm_hub_device_data.get("deviceId")
    serial_number = classic_alarm_hub_device_data.get("claimedSerialNumber")

    if not (verkada_device_id and serial_number):
        print(f"Skipping classic alarm hub device due to missing ID or Serial: {classic_alarm_hub_device_data}")
        return

    try:
        existing_device_query = db.collection('organizations').document(org_id).collection('devices').where('deviceSerialNumber', '==', serial_number).limit(1).get()
        if existing_device_query:
            device_ref = existing_device_query[0].reference
            device_ref.set({
                'deviceVerkadaDeviceId': verkada_device_id,
                'deviceVerkadaDeviceType': "Classic Alarm Hub Device",
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
                'deviceVerkadaDeviceType': "Classic Alarm Hub Device",
            })
    except Exception as e:
        print(f"Error processing classic alarm hub device SN {serial_number}: {e}")
def _process_classic_alarms_door_contact_sensor(classic_alarm_door_contact_sensor_data: dict, org_id: str):
    """Processes a single classic alarm door contact sensor: finds/creates Firestore doc and updates Verkada ID."""
    verkada_device_id = classic_alarm_door_contact_sensor_data.get("deviceId")
    serial_number = classic_alarm_door_contact_sensor_data.get("serialNumber")

    if not (verkada_device_id and serial_number):
        print(f"Skipping classic alarm door contact sensor due to missing ID or Serial: {classic_alarm_door_contact_sensor_data}")
        return

    try:
        existing_device_query = db.collection('organizations').document(org_id).collection('devices').where('deviceSerialNumber', '==', serial_number).limit(1).get()
        if existing_device_query:
            device_ref = existing_device_query[0].reference
            device_ref.set({
                'deviceVerkadaDeviceId': verkada_device_id,
                'deviceVerkadaDeviceType': "Classic Alarm Door Contact Sensor",
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
                'deviceVerkadaDeviceType': "Classic Alarm Door Contact Sensor",
            })
    except Exception as e:
        print(f"Error processing classic alarm door contact sensor SN {serial_number}: {e}")
def _process_classic_alarms_glass_break_sensor(classic_alarm_glass_break_sensor_data: dict, org_id: str):
    """Processes a single classic alarm glass break sensor: finds/creates Firestore doc and updates Verkada ID."""
    verkada_device_id = classic_alarm_glass_break_sensor_data.get("deviceId")
    serial_number = classic_alarm_glass_break_sensor_data.get("serialNumber")

    if not (verkada_device_id and serial_number):
        print(f"Skipping classic alarm glass break sensor due to missing ID or Serial: {classic_alarm_glass_break_sensor_data}")
        return

    try:
        existing_device_query = db.collection('organizations').document(org_id).collection('devices').where('deviceSerialNumber', '==', serial_number).limit(1).get()
        if existing_device_query:
            device_ref = existing_device_query[0].reference
            device_ref.set({
                'deviceVerkadaDeviceId': verkada_device_id,
                'deviceVerkadaDeviceType': "Classic Alarm Glass Break Sensor",
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
                'deviceVerkadaDeviceType': "Classic Alarm Glass Break Sensor",
            })
    except Exception as e:
        print(f"Error processing classic alarm glass break sensor SN {serial_number}: {e}")
def _process_classic_alarms_motion_sensor(classic_alarm_motion_sensor_data: dict, org_id: str):
    """Processes a single classic alarm motion sensor: finds/creates Firestore doc and updates Verkada ID."""
    verkada_device_id = classic_alarm_motion_sensor_data.get("deviceId")
    serial_number = classic_alarm_motion_sensor_data.get("serialNumber")

    if not (verkada_device_id and serial_number):
        print(f"Skipping classic alarm motion sensor due to missing ID or Serial: {classic_alarm_motion_sensor_data}")
        return

    try:
        existing_device_query = db.collection('organizations').document(org_id).collection('devices').where('deviceSerialNumber', '==', serial_number).limit(1).get()
        if existing_device_query:
            device_ref = existing_device_query[0].reference
            device_ref.set({
                'deviceVerkadaDeviceId': verkada_device_id,
                'deviceVerkadaDeviceType': "Classic Alarm Motion Sensor",
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
                'deviceVerkadaDeviceType': "Classic Alarm Motion Sensor",
            })
    except Exception as e:
        print(f"Error processing classic alarm motion sensor SN {serial_number}: {e}")

def _process_classic_alarms_panic_button(classic_alarm_panic_button_data: dict, org_id: str):
    """Processes a single classic alarm panic button: finds/creates Firestore doc and updates Verkada ID."""
    verkada_device_id = classic_alarm_panic_button_data.get("deviceId")
    serial_number = classic_alarm_panic_button_data.get("serialNumber")

    if not (verkada_device_id and serial_number):
        print(f"Skipping classic alarm panic button due to missing ID or Serial: {classic_alarm_panic_button_data}")
        return

    try:
        existing_device_query = db.collection('organizations').document(org_id).collection('devices').where('deviceSerialNumber', '==', serial_number).limit(1).get()
        if existing_device_query:
            device_ref = existing_device_query[0].reference
            device_ref.set({
                'deviceVerkadaDeviceId': verkada_device_id,
                'deviceVerkadaDeviceType': "Classic Alarm Panic Button",
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
                'deviceVerkadaDeviceType': "Classic Alarm Panic Button",
            })
    except Exception as e:
        print(f"Error processing classic alarm panic button SN {serial_number}: {e}")
def _process_classic_alarms_water_sensor(classic_alarm_water_sesnsor_data: dict, org_id: str):
    """Processes a single classic alarm water sensor: finds/creates Firestore doc and updates Verkada ID."""
    verkada_device_id = classic_alarm_water_sesnsor_data.get("deviceId")
    serial_number = classic_alarm_water_sesnsor_data.get("serialNumber")

    if not (verkada_device_id and serial_number):
        print(f"Skipping classic alarm water sensor due to missing ID or Serial: {classic_alarm_water_sesnsor_data}")
        return

    try:
        existing_device_query = db.collection('organizations').document(org_id).collection('devices').where('deviceSerialNumber', '==', serial_number).limit(1).get()
        if existing_device_query:
            device_ref = existing_device_query[0].reference
            device_ref.set({
                'deviceVerkadaDeviceId': verkada_device_id,
                'deviceVerkadaDeviceType': "Classic Alarm Water Sensor",
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
                'deviceVerkadaDeviceType': "Classic Alarm Water Sensor",
            })
    except Exception as e:
        print(f"Error processing classic alarm water sensor SN {serial_number}: {e}")
def _process_classic_alarms_wireless_relay(classic_alarm_wireless_relay_data: dict, org_id: str):
    """Processes a single classic alarm wireless relay: finds/creates Firestore doc and updates Verkada ID."""
    verkada_device_id = classic_alarm_wireless_relay_data.get("deviceId")
    serial_number = classic_alarm_wireless_relay_data.get("serialNumber")

    if not (verkada_device_id and serial_number):
        print(f"Skipping classic alarm wireless relay due to missing ID or Serial: {classic_alarm_wireless_relay_data}")
        return

    try:
        existing_device_query = db.collection('organizations').document(org_id).collection('devices').where('deviceSerialNumber', '==', serial_number).limit(1).get()
        if existing_device_query:
            device_ref = existing_device_query[0].reference
            device_ref.set({
                'deviceVerkadaDeviceId': verkada_device_id,
                'deviceVerkadaDeviceType': "Classic Alarm Wireless Relay",
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
                'deviceVerkadaDeviceType': "Classic Alarm Wireless Relay",
            })
    except Exception as e:
        print(f"Error processing classic alarm wireless relay SN {serial_number}: {e}")

def _process_new_alarms_device(new_alarms_device_data: dict, org_id: str):
    """Processes a single new alarms device: finds/creates Firestore doc and updates Verkada ID."""
    verkada_device_id = new_alarms_device_data.get("id")
    serial_number = new_alarms_device_data.get("verkadaDeviceConfig").get("serialNumber")
    verkada_new_alarms_system_id = new_alarms_device_data.get("alarmSystemId")

    if not (verkada_device_id and serial_number):
        print(f"Skipping new alarms device due to missing ID or Serial: {new_alarms_device_data}")
        return

    try:
        existing_device_query = db.collection('organizations').document(org_id).collection('devices').where('deviceSerialNumber', '==', serial_number).limit(1).get()
        if existing_device_query:
            device_ref = existing_device_query[0].reference
            device_ref.set({
                'deviceVerkadaDeviceId': verkada_device_id,
                'deviceVerkadaDeviceType': "New Alarms Device",
                'deviceVerkadaNewAlarmsSystemId': verkada_new_alarms_system_id,
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
                'deviceVerkadaDeviceType': "New Alarms Device",
                'deviceVerkadaNewAlarmsSystemId': verkada_new_alarms_system_id,
            })
    except Exception as e:
        print(f"Error processing new alarms device SN {serial_number}: {e}")

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
        payload = {'organizationId': verkada_org_id}
        command_connectors = []
        try:
            response = requests_with_retry('post', url, headers=auth_headers, json=payload)
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
    
    def sync_classic_alarms_keypad_ids():
        url = f"https://alarms.command.verkada.com/__v/{verkada_org_shortname}/device/keypad/get_all"
        payload = {
            "organizationId": verkada_org_id,
        }
        classic_alarms_keypads = []
        try:
            response = requests_with_retry('post', url, headers=auth_headers, json=payload)
            response.raise_for_status()
            classic_alarms_keypads = response.json().get("keypad", [])
            

        except RequestException as e:
            print(f"Error fetching classic alarm keypad info after retries: {e}")
            return
        except JSONDecodeError as e:
            print(f"Error decoding JSON response for classic alarm keypad: {e}")
            return
        except Exception as e:
            print(f"An unexpected error occurred during classic alarm keypad fetch: {e}")
            return

        if not classic_alarms_keypads:
            print("No classic alarms keypads found to process.")
            return
        

        process_classic_alarm_keypad_with_org = partial(_process_classic_alarm_keypad, org_id=org_id)
        with concurrent.futures.ThreadPoolExecutor(max_workers=10) as executor:
            list(executor.map(process_classic_alarm_keypad_with_org, classic_alarms_keypads))
        print(f"Finished processing {len(classic_alarms_keypads)} classic alarm keypads.")
    
    def sync_classic_alarms_hub_and_sensor_ids():
        url = f"https://alarms.command.verkada.com/__v/{verkada_org_shortname}/device/get_all"
        payload = {
            "organizationId": verkada_org_id,
        }
        classic_alarms_hub_devices = []
        classic_alarms_door_contact_sensors = []
        classic_alarms_glass_break_sensors = []
        classic_alarms_motion_sensors = []
        classic_alarms_panic_buttons = []
        classic_alarms_water_sensors = []
        classic_alarms_wireless_relays = []
        try:
            response = requests_with_retry('post', url, headers=auth_headers, json=payload)
            response.raise_for_status()
            classic_alarms_hub_devices = response.json().get("hubDevice", [])
            classic_alarms_door_contact_sensors = response.json().get("doorContactSensor", [])
            classic_alarms_glass_break_sensors = response.json().get("glassBreakSensor", [])
            classic_alarms_motion_sensors = response.json().get("motionSensor", [])
            classic_alarms_panic_buttons = response.json().get("panicButton", [])
            classic_alarms_water_sensors = response.json().get("waterSensor", [])
            classic_alarms_wireless_relays = response.json().get("wirelessRelay", [])
            

        except RequestException as e:
            print(f"Error fetching classic alarm device info after retries: {e}")
            return
        except JSONDecodeError as e:
            print(f"Error decoding JSON response for classic alarm device: {e}")
            return
        except Exception as e:
            print(f"An unexpected error occurred during classic alarm device fetch: {e}")
            return

        if not classic_alarms_hub_devices and not classic_alarms_door_contact_sensors and not classic_alarms_glass_break_sensors and not classic_alarms_motion_sensors and not classic_alarms_panic_buttons and not classic_alarms_water_sensors and not classic_alarms_wireless_relays:
            print("No classic alarms devices found to process.")
            return
        

        process_classic_alarm_hub_device_with_org = partial(_process_classic_alarm_hub_device, org_id=org_id)
        with concurrent.futures.ThreadPoolExecutor(max_workers=10) as executor:
            list(executor.map(process_classic_alarm_hub_device_with_org, classic_alarms_hub_devices))
        print(f"Finished processing {len(classic_alarms_hub_devices)} classic alarm hub devices.")

        process_classic_alarms_door_contact_sensor_with_org = partial(_process_classic_alarms_door_contact_sensor, org_id=org_id)
        with concurrent.futures.ThreadPoolExecutor(max_workers=10) as executor:
            list(executor.map(process_classic_alarms_door_contact_sensor_with_org, classic_alarms_door_contact_sensors))
        print(f"Finished processing {len(classic_alarms_door_contact_sensors)} classic alarm door contact sensors.")

        process_classic_alarms_glass_break_sensor_with_org = partial(_process_classic_alarms_glass_break_sensor, org_id=org_id)
        with concurrent.futures.ThreadPoolExecutor(max_workers=10) as executor:
            list(executor.map(process_classic_alarms_glass_break_sensor_with_org, classic_alarms_glass_break_sensors))
        print(f"Finished processing {len(classic_alarms_glass_break_sensors)} classic alarm glass break sensors.")

        process_classic_alarms_motion_sensor_with_org = partial(_process_classic_alarms_motion_sensor, org_id=org_id)
        with concurrent.futures.ThreadPoolExecutor(max_workers=10) as executor:
            list(executor.map(process_classic_alarms_motion_sensor_with_org, classic_alarms_motion_sensors))
        print(f"Finished processing {len(classic_alarms_motion_sensors)} classic alarm motion sensors.")
        
        process_classic_alarms_panic_button_with_org = partial(_process_classic_alarms_panic_button, org_id=org_id)
        with concurrent.futures.ThreadPoolExecutor(max_workers=10) as executor:
            list(executor.map(process_classic_alarms_panic_button_with_org, classic_alarms_panic_buttons))
        print(f"Finished processing {len(classic_alarms_panic_buttons)} classic alarm panic buttons.")

        process_classic_alarms_water_sensor_with_org = partial(_process_classic_alarms_water_sensor, org_id=org_id)
        with concurrent.futures.ThreadPoolExecutor(max_workers=10) as executor:
            list(executor.map(process_classic_alarms_water_sensor_with_org, classic_alarms_water_sensors))
        print(f"Finished processing {len(classic_alarms_water_sensors)} classic alarm water sensors.")

        process_classic_alarms_wireless_relay_with_org = partial(_process_classic_alarms_wireless_relay, org_id=org_id)
        with concurrent.futures.ThreadPoolExecutor(max_workers=10) as executor:
            list(executor.map(process_classic_alarms_wireless_relay_with_org, classic_alarms_wireless_relays))
        print(f"Finished processing {len(classic_alarms_wireless_relays)} classic alarm wireless relays.")

    def sync_new_alarms_device_ids():
        url = f"https://vproconfig.command.verkada.com/__v/{verkada_org_shortname}/org/get_devices_and_alarm_systems"
        payload = {}
        new_alarms_devices = []
        try:
            response = requests_with_retry('post', url, headers=auth_headers, json=payload)
            response.raise_for_status()
            new_alarms_devices = response.json().get("devices", [])
            
        except RequestException as e:
            print(f"Error fetching new alarms device info after retries: {e}")
            return
        except JSONDecodeError as e:
            print(f"Error decoding JSON response for new alarms device: {e}")
            return
        except Exception as e:
            print(f"An unexpected error occurred during new alarms device fetch: {e}")
            return

        if not new_alarms_devices:
            print("No new alarms devices found to process.")
            return
        

        process_new_alarms_device_with_org = partial(_process_new_alarms_device, org_id=org_id)
        with concurrent.futures.ThreadPoolExecutor(max_workers=10) as executor:
            list(executor.map(process_new_alarms_device_with_org, new_alarms_devices))
        print(f"Finished processing {len(new_alarms_devices)} new alarms devices.")


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
            executor.submit(sync_classic_alarms_keypad_ids),
            executor.submit(sync_classic_alarms_hub_and_sensor_ids),
            executor.submit(sync_new_alarms_device_ids),
        ]
        for future in concurrent.futures.as_completed(futures):
            try:
                future.result()
            except Exception as exc:
                print(f'A sync function generated an exception: {exc}')

    print(f"Completed all Verkada device sync for org: {org_id}")