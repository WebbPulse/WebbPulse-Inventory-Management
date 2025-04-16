from src.shared import POSTcorsrules, db, check_user_is_org_member, check_user_is_authed, check_user_token_current, check_user_is_email_verified

from firebase_functions import https_fn
from typing import Any
from firebase_admin import firestore

@https_fn.on_call(cors=POSTcorsrules, timeout_sec=540)
def create_devices_callable(req: https_fn.CallableRequest) -> Any:
    """
    Firebase Function to create devices for an organization.
    The function ensures the user is authenticated, their email is verified, their token is current, 
    and they are a member of the organization. It accepts a list of device serial numbers and creates 
    corresponding device documents in Firestore.
    """
    try:
        # Step 1: Extract the list of device serial numbers and organization ID from the request.
        device_serial_numbers = req.data["deviceSerialNumbers"]  # Expecting a list of device serial numbers.
        org_id = req.data["orgId"]  # Organization ID to which the devices belong.

        # Step 2: Perform authentication, email verification, and token validation checks.
        check_user_is_authed(req)  # Ensure the user is authenticated.
        check_user_is_email_verified(req)  # Ensure the user's email is verified.
        check_user_token_current(req)  # Ensure the user's token is valid and current.
        check_user_is_org_member(req, org_id)  # Ensure the user is a member of the specified organization.

        # Step 3: Validate that the serial numbers list and organization ID are provided and valid.
        if not device_serial_numbers or not isinstance(device_serial_numbers, list) or not org_id:
            # If the serial numbers list is missing or not a list, or the org ID is missing, raise an error.
            raise https_fn.HttpsError(
                code=https_fn.FunctionsErrorCode.INVALID_ARGUMENT,
                message='The function must be called with a valid list of "deviceSerialNumbers" and a valid "org_id".'
            )

        response_list = []  # Initialize an empty list to store responses for each device.

        # Step 4: Process each device serial number in the list.
        for device_serial_number in device_serial_numbers:
            if not device_serial_number:
                continue  # Skip empty serial numbers.

            # Step 5: Check if a device with the same serial number already exists in Firestore.
            existing_device_query = db.collection('organizations').document(org_id).collection('devices').where('deviceSerialNumber', '==', device_serial_number).limit(1).get()
            if existing_device_query:
                # If the device exists, update the existing device document.
                device_ref = existing_device_query[0].reference
                device_ref.set({
                    'deviceId': device_ref.id,  # Use the existing device ID.
                    'deviceSerialNumber': device_serial_number,
                    'createdAt': firestore.SERVER_TIMESTAMP,  # Update the creation timestamp.
                    'isDeviceCheckedOut': False,  # Ensure the device is marked as not checked out.
                    'deviceCheckedOutBy': '',  # Clear any user associated with checkout.
                    'deviceCheckedOutAt': None,  # Clear any checkout timestamp.
                    'deviceDeleted': False,  # Mark the device as not deleted.
                }, merge=True)  # Merge to avoid overwriting other fields.
            else:
                # Step 6: If the device does not exist, create a new device document in Firestore.
                device_ref = db.collection('organizations').document(org_id).collection('devices').document()
                device_ref.set({
                    'deviceId': device_ref.id,  # Generate a new device ID.
                    'deviceSerialNumber': device_serial_number,
                    'createdAt': firestore.SERVER_TIMESTAMP,  # Record the creation timestamp.
                    'isDeviceCheckedOut': False,  # Mark the device as not checked out.
                    'deviceCheckedOutBy': '',  # No user has checked out the device yet.
                    'deviceCheckedOutAt': None,  # No checkout timestamp.
                    'deviceDeleted': False,  # Mark the device as not deleted.
                })

            # Step 7: Add a response message for this device.
            response_list.append(f"Device {device_serial_number} created")

        # Step 8: Return the response messages for all processed devices.
        return {"response": response_list}

    except https_fn.HttpsError as e:
        # Catch and re-raise any known Firebase HttpsErrors.
        raise e

    except Exception as e:
        # Catch any unexpected errors and return a generic error message.
        raise https_fn.HttpsError(
            code=https_fn.FunctionsErrorCode.UNKNOWN,
            message=f"Error creating devices: {str(e)}"
        )
