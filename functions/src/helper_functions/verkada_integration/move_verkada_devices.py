from src.helper_functions.verkada_integration.http_utils import requests_with_retry
from requests.exceptions import RequestException
import logging
from src.shared import db

def move_verkada_devices(org_id, verkada_bot_user_info):
    print("Moving Verkada devices...")
    verkada_org_id = verkada_bot_user_info.get('org_id')
    verkada_auth_headers = verkada_bot_user_info.get('auth_headers')
    
    
    org_verkada_product_site_designations = {}
    try:
        verkada_integation_settings_ref = db.collection('organizations').document(org_id).collection('sensitiveConfigs').document('verkadaIntegrationSettings').get()
        if not verkada_integation_settings_ref.exists:
            raise Exception("Verkada integration settings not found in Firestore.")
        verkada_integation_settings = verkada_integation_settings_ref.to_dict()
        org_verkada_product_site_designations = verkada_integation_settings.get('orgVerkadaProductSiteDesignations')
    except Exception as e:
        logging.error(f"Error retrieving organization settings: {e}")
        raise

    verkada_org_short_name = verkada_bot_user_info.get('org_name')

    verkada_access_control_building_id = org_verkada_product_site_designations.get('Access Controller Building', '' )
    verkada_access_control_floor_id = org_verkada_product_site_designations.get('Access Controller Floor', '' )
    verkada_access_control_site_id = org_verkada_product_site_designations.get('Access Controller Site', '' )
    verada_access_level_id = org_verkada_product_site_designations.get('Access Level', '' )
    verkada_camera_site_id = org_verkada_product_site_designations.get('Camera Site', '' )
    verkada_classic_alarm_site_id = org_verkada_product_site_designations.get('Classic Alarm Site', '' )
    verkada_classic_alarm_zone_id = org_verkada_product_site_designations.get('Classic Alarm Zone', '' )
    verkada_command_connector_site_id = org_verkada_product_site_designations.get('Command Connector Site', '' )
    verkada_desk_station_site_id = org_verkada_product_site_designations.get('Desk Station Site', '' )
    verkada_env_sensor_site_id = org_verkada_product_site_designations.get('Environmental Sensor Site', '' )
    verkada_gateway_site_id = org_verkada_product_site_designations.get('Gateway Site', '' )
    verkada_guest_site_id = org_verkada_product_site_designations.get('Guest Site', '' )
    verkada_intercom_site_id = org_verkada_product_site_designations.get('Intercom Site', '' )
    verkada_mailroom_site_id = org_verkada_product_site_designations.get('Mailroom Site', '' )
    verkada_new_alarm_site_id = org_verkada_product_site_designations.get('New Alarm Site', '' )
    verkada_speaker_site_id = org_verkada_product_site_designations.get('Speaker Site', '' )
    verkada_viewing_station_site_id = org_verkada_product_site_designations.get('Viewing Station Site', '' )
    
    
    devices = []
    try:
        devices_ref = db.collection('organizations').document(org_id).collection('devices').where('deviceVerkadaDeviceId', '!=', None)
        devices = devices_ref.get()
        print(f"Devices to move: {len(devices)}")
    except Exception as e:
        logging.error(f"Error retrieving devices: {e}")
        raise
    
    def move_camera(device, verkada_camera_site_id):
        if not verkada_camera_site_id:
            print("No site ID provided for camera.")
            return
        
        try:
            camera_id = device.get('deviceVerkadaDeviceId')
            rename_url = f"https://vprovision.command.verkada.com/__v/{verkada_org_short_name}/camera/site/batch/set"
            payload = {"cameraIds":[camera_id],
                    "destinationSiteId": verkada_camera_site_id}
            response = requests_with_retry('post', rename_url, headers=verkada_auth_headers, json=payload)
            response.raise_for_status()
            print(f"{camera_id} moved successfully to {verkada_camera_site_id}.")
        except RequestException as e:
            print(f"Error moving {camera_id} info after retries: {e}")
        except Exception as e:
            print(f"Error moving {camera_id}: {e}")
    
    def move_controller(device, verkada_access_control_site_id, verkada_access_control_building_id, verkada_access_control_floor_id, verada_access_level_id):
        print("controller moving not implemented")
        pass
    def move_env_sensor(device, verkada_env_sensor_site_id):
        print("env sensor moving not implemented")
        pass
    def move_intercom(device, verkada_intercom_site_id):
        print("intercom moving not implemented")
        pass
    def move_gateway(device, verkada_gateway_site_id):
        print("gateway moving not implemented")
        pass
    def move_command_connector(device, verkada_command_connector_site_id):
        print("command connector moving not implemented")
        pass
    def move_viewing_station(device, verkada_viewing_station_site_id):
        print("viewing station moving not implemented")
        pass
    def move_desk_station(device, verkada_desk_station_site_id):
        print("desk station moving not implemented")
        pass
    def move_speaker(device, verkada_speaker_site_id):
        print("speaker moving not implemented")
        pass
    def move_classic_alarm_hub_device(device, verkada_classic_alarm_site_id, verkada_classic_alarm_zone_id):
        print("classic hub moving not implemented")
        pass
    def move_classic_alarm_keypad(device, verkada_classic_alarm_site_id):
        print("keypad moving not implemented")
        pass
    def move_siren_strobe(device, verkada_new_alarm_site_id):
        print("siren strobe moving not implemented")
        pass
    def move_alarm_expander(device, verkada_new_alarm_site_id):
        print("alarm expander moving not implemented")
        pass
    
    
    for device in devices:
        device = device.to_dict()
        
        device_type = device.get('deviceVerkadaDeviceType')
        if device_type == "Camera": 
            move_camera(device, verkada_camera_site_id)
        elif device_type == 'Access Controller' or device_type == 'Input Output Board':
            move_controller(device, verkada_access_control_site_id, verkada_access_control_building_id, verkada_access_control_floor_id, verada_access_level_id)
        elif device_type == 'Environmental Sensor':
            move_env_sensor(device, verkada_env_sensor_site_id)
        elif device_type == 'Intercom':
            move_intercom(device, verkada_intercom_site_id)
        elif device_type == 'Gateway':
            move_gateway(device, verkada_gateway_site_id)
        elif device_type == 'Command Connector':
            move_command_connector(device, verkada_command_connector_site_id)
        elif device_type == 'Viewing Station':
            move_viewing_station(device, verkada_viewing_station_site_id)
        elif device_type == 'Desk Station':
            move_desk_station(device, verkada_desk_station_site_id)
        elif device_type == 'Speaker':
            move_speaker(device, verkada_classic_alarm_site_id)
        elif device_type == 'Classic Alarm Hub Device':
            move_classic_alarm_hub_device(device, verkada_classic_alarm_site_id, verkada_classic_alarm_zone_id)
        elif device_type == 'Classic Alarm Keypad':
            move_classic_alarm_keypad(device, verkada_classic_alarm_site_id)
        elif device_type == 'Classic Alarm Door Contact Sensor':
            pass
        elif device_type == 'Classic Alarm Glass Break Sensor':
            pass
        elif device_type == 'Classic Alarm Motion Sensor':
            pass
        elif device_type == 'Classic Alarm Panic Button':
            pass
        elif device_type == 'Classic Alarm Water Sensor':
            pass
        elif device_type == 'Classic Alarm Wireless Relay':
            pass
        elif device_type == 'Siren Strobe':
            move_siren_strobe(device, verkada_new_alarm_site_id)
        elif device_type == 'BP52 Panel':
            print('Oh fuck, this is a BP52')
            pass
        elif device_type == 'Alarm Expander':
            move_alarm_expander(device, verkada_new_alarm_site_id)
            pass
            
        else:
            print(f"Device type unaccounted for when moving: {device_type}")
    
    

