from src.shared import POSTcorsrules, db, firestore, https_fn, Any, check_user_is_org_member, check_user_is_authed, check_user_token_current, check_user_is_email_verified

@https_fn.on_call(cors=POSTcorsrules)
def create_devices_callable(req: https_fn.CallableRequest) -> Any:
    try:
        # Extract parameters
        device_serial_numbers = req.data["deviceSerialNumbers"]  # This should now be a list
        org_id = req.data["orgId"]

        check_user_is_authed(req)
        check_user_is_email_verified(req)
        check_user_token_current(req)
        check_user_is_org_member(req, org_id)

        # Check if the serial numbers and org_id are provided and valid
        if not device_serial_numbers or not isinstance(device_serial_numbers, list) or not org_id:
            raise https_fn.HttpsError(
                code=https_fn.FunctionsErrorCode.INVALID_ARGUMENT,
                message='The function must be called with a valid list of "deviceSerialNumbers" and a valid "org_id".'
            )

        response_list = []  # To store responses for each device

        # Process each device serial number in the list
        for device_serial_number in device_serial_numbers:
            if not device_serial_number:
                continue  # Skip empty serial numbers

            # Check if a device with the same serial number already exists
            existing_device_query = db.collection('organizations').document(org_id).collection('devices').where('deviceSerialNumber', '==', device_serial_number).limit(1).get()
            if existing_device_query:
                device_ref = existing_device_query[0].reference
                device_ref.set({
                    'deviceId': device_ref.id,
                    'deviceSerialNumber': device_serial_number,
                    'createdAt': firestore.SERVER_TIMESTAMP,
                    'isDeviceCheckedOut': False,
                    'deviceCheckedOutBy': '',
                    'deviceCheckedOutAt': None,
                    'deviceDeleted': False,
                }, merge=True)
            else:
                # Create the device in Firestore
                device_ref = db.collection('organizations').document(org_id).collection('devices').document()
                device_ref.set({
                    'deviceId': device_ref.id,
                    'deviceSerialNumber': device_serial_number,
                    'createdAt': firestore.SERVER_TIMESTAMP,
                    'isDeviceCheckedOut': False,
                    'deviceCheckedOutBy': '',
                    'deviceCheckedOutAt': None,
                    'deviceDeleted': False,
                })

            response_list.append(f"Device {device_serial_number} created")

        return {"response": response_list}

    except https_fn.HttpsError as e:
        # Re-raise known HttpsErrors
        raise e
    except Exception as e:
        # Handle any other exceptions
        raise https_fn.HttpsError(
            code=https_fn.FunctionsErrorCode.UNKNOWN,
            message=f"Error creating devices: {str(e)}"
        )
