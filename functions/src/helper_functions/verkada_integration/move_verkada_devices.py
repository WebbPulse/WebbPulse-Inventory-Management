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
            move_url = f"https://vprovision.command.verkada.com/__v/{verkada_org_short_name}/camera/site/batch/set"
            payload = {"cameraIds":[camera_id],
                    "destinationSiteId": verkada_camera_site_id}
            response = requests_with_retry('post', move_url, headers=verkada_auth_headers, json=payload)
            response.raise_for_status()
            print(f"{camera_id} moved successfully to {verkada_camera_site_id}.")
        except RequestException as e:
            print(f"Error moving {camera_id} info after retries: {e}")
        except Exception as e:
            print(f"Error moving {camera_id}: {e}")
    
    def move_controller(device, verkada_access_control_site_id, verkada_access_control_building_id, verkada_access_control_floor_id, verada_access_level_id):
        if not verkada_access_control_site_id:
            print("No site ID provided for access controller.")
            return
        
        try:
            controller_id = device.get('deviceVerkadaDeviceId')
            move_url = f"https://vcerberus.command.verkada.com/__v/{verkada_org_short_name}/access_controller/move_to_site"
            payload = {"accessControllerId":controller_id,"siteId":verkada_access_control_site_id}
            response = requests_with_retry('post', move_url, headers=verkada_auth_headers, json=payload)
            response.raise_for_status()
            print(f"{controller_id} moved successfully to {verkada_access_control_site_id}.")
        except RequestException as e:
            print(f"Error moving {controller_id} info after retries: {e}")
        except Exception as e:
            print(f"Error moving {controller_id}: {e}")
    

    # WILL NOT WORK UNTIL WE PLACE ENV SENSOR SITE INFO IN DB
    def move_env_sensor(device, verkada_env_sensor_site_id):
        if not verkada_env_sensor_site_id:
            print("No site ID provided for environmental sensor.")
            return
        
        try:
            env_sensor_id = device.get('deviceVerkadaDeviceId')
            env_sensor_prev_site = ''
            move_url = f"https://vsensor.command.verkada.com/__v/{verkada_org_short_name}/devices/{env_sensor_id}"
            payload = {'currentSiteId': env_sensor_prev_site, 'siteId': verkada_env_sensor_site_id}
            response = requests_with_retry('patch', move_url, headers=verkada_auth_headers, json=payload)
            response.raise_for_status()
            print(f"{env_sensor_id} moved successfully to {verkada_env_sensor_site_id}.")
        except RequestException as e:
            print(f"Error moving {env_sensor_id} info after retries: {e}")
        except Exception as e:
            print(f"Error moving {env_sensor_id}: {e}")



    def move_intercom(device, verkada_intercom_site_id):
        if not verkada_intercom_site_id:
            print("No site ID provided for intercom.")
            return
        
        try:
            intercom_id = device.get('deviceVerkadaDeviceId')
            move_url = f"https://api.command.verkada.com/__v/{verkada_org_short_name}/vinter/v1/user/organization/{verkada_org_id}/intercom/{intercom_id}"
            payload = {"siteId":verkada_intercom_site_id}
            response = requests_with_retry('patch', move_url, headers=verkada_auth_headers, json=payload)
            response.raise_for_status()
            print(f"{intercom_id} moved successfully to {verkada_intercom_site_id}.")
        except RequestException as e:
            print(f"Error moving {intercom_id} info after retries: {e}")
        except Exception as e:
            print(f"Error moving {intercom_id}: {e}")

    # WILL NOT WORK UNTIL WE PLACE GATEWAY SITE INFO IN DB
    def move_gateway(device, verkada_gateway_site_id):
        if not verkada_gateway_site_id:
            print("No site ID provided for intercom.")
            return
        
        try:
            gateway_prev_site = ''
            gateway_id = device.get('deviceVerkadaDeviceId')
            move_url = f"https://vnet.command.verkada.com/__v/{verkada_org_short_name}/devices/{gateway_id}"
            payload = {'currentSiteId': gateway_prev_site, 'siteId': verkada_gateway_site_id}
            response = requests_with_retry('patch', move_url, headers=verkada_auth_headers, json=payload)
            response.raise_for_status()
            print(f"{gateway_id} moved successfully to {verkada_gateway_site_id}.")
        except RequestException as e:
            print(f"Error moving {gateway_id} info after retries: {e}")
        except Exception as e:
            print(f"Error moving {gateway_id}: {e}")


    def move_command_connector(device, verkada_command_connector_site_id):
        if not verkada_command_connector_site_id:
            print("No site ID provided for Command Connector.")
            return
        
        try:
            cc_id = device.get('deviceVerkadaDeviceId')
            move_url = f"https://vprovision.command.verkada.com/__v/{verkada_org_short_name}/vfortress/update_box"
            payload = {
                'deviceId': cc_id,
                'siteId': config["connector_site"]
            }
            response = requests_with_retry('patch', move_url, headers=verkada_auth_headers, json=payload)
            response.raise_for_status()
            print(f"{gateway_id} moved successfully to {verkada_gateway_site_id}.")
        except RequestException as e:
            print(f"Error moving {gateway_id} info after retries: {e}")
        except Exception as e:
            print(f"Error moving {gateway_id}: {e}")

    
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
    
    

