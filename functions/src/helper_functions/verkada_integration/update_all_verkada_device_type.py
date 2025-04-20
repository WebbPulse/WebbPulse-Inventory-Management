from src.helper_functions.verkada_integration.check_verkada_device_type import check_verkada_device_type
from src.shared import db

def update_all_devices_verkada_device_type(org_id: str) -> None:
    org_ref = db.collection('organizations').document(org_id)
    devices_ref = org_ref.collection('devices')
    docs = devices_ref.stream()
    for doc in docs:
        device_serial_number = doc.get('deviceSerialNumber')
        if device_serial_number:
            device_verkada_device_type = check_verkada_device_type(device_serial_number)
            devices_ref.document(doc.id).update({
                'deviceVerkadaDeviceType': device_verkada_device_type
            })