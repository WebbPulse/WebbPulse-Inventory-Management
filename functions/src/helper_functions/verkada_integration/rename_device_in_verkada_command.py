from src.shared import db
from src.helper_functions.verkada_integration.login_to_verkada import login_to_verkada
def rename_device_in_verkada_command(device_id, org_id, device_being_checked_out):
    """
    """
    org_doc = db.collection('organizations').document(org_id).get
    verkada_org_short_name = org_doc.get('orgVerkadaOrgShortName')
    verkada_org_bot_email = org_doc.get('orgVerkadaBotEmail')
    verkada_org_bot_password = org_doc.get('orgVerkadaBotPassword')

    verkada_bot_user_info = login_to_verkada(verkada_org_short_name, verkada_org_bot_email, verkada_org_bot_password)
    verkada_org_id = verkada_bot_user_info.get('org_id')
    verkada_bot_user_id = verkada_bot_user_info.get('user_id')
    
    deviceDoc = db.collection('organizations').document(org_id).collection('devices').document(device_id).get()
    device_serial_number = deviceDoc.get('deviceSerialNumber')
    device_verkada_device_id = deviceDoc.get('deviceVerkadaDeviceId')
    device_verkada_device_type = deviceDoc.get('deviceVerkadaDeviceType')
    
    if device_being_checked_out:
        device_name = f"{device_serial_number} - Checked Out"
    else:
        device_name = f"{device_serial_number} - Available"

    if device_verkada_device_type == "Camera":
        pass