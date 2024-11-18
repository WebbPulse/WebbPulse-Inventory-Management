from src.shared import POSTcorsrules, db, firestore, https_fn, Any, check_user_is_org_member, check_user_is_authed, check_user_token_current, check_user_is_email_verified, check_user_is_org_deskstation_or_higher

@https_fn.on_call(cors=POSTcorsrules)
def update_device_checkout_status_callable(req: https_fn.CallableRequest) -> Any:
    """
    Firebase Function to update the checkout status of a device within an organization.
    The function ensures the user is authenticated, their email is verified, their token is current,
    and they are a member of the specified organization. It updates the device's checkout status 
    based on the provided parameters.
    """
    try:
        # Step 1: Extract the necessary parameters from the request data.
        org_id = req.data["orgId"]  # Organization ID to which the device belongs.
        device_serial_number = req.data["deviceSerialNumber"]  # Serial number of the device.
        is_device_being_checked_out = req.data["isDeviceBeingCheckedOut"]  # Boolean indicating if the device is checked out.
        device_being_checked_by = req.data["deviceBeingCheckedBy"]  # The ID of the user who checked out the device.
        device_checked_out_note = req.data["deviceCheckedOutNote"]  # Optional note about the device checkout.

        if not isinstance(is_device_being_checked_out, bool):
            raise https_fn.HttpsError(
                code=https_fn.FunctionsErrorCode.INVALID_ARGUMENT,
                message="'isDeviceCheckedOut' must be a boolean."
            )


        # Step 2: Perform authentication, email verification, and token validation checks.
        check_user_is_authed(req)  # Ensure the user is authenticated.
        check_user_is_email_verified(req)  # Ensure the user's email is verified.
        check_user_token_current(req)  # Ensure the user's token is valid and current.
        check_user_is_org_member(req, org_id)  # Ensure the user is a member of the specified organization.

        # Step 3: Validate that the required parameters are provided and valid.
        if not device_serial_number or not org_id or is_device_being_checked_out is None:
            # If any required parameters are missing or invalid, raise an error.
            raise https_fn.HttpsError(
                code=https_fn.FunctionsErrorCode.INVALID_ARGUMENT,
                message='The function must be called with valid deviceSerialNumber, orgId, and isDeviceCheckedOut parameters.'
            )

        

        # Step 5: Query Firestore to find the device with the specified serial number in the organization.
        querySnapshot = db.collection('organizations').document(org_id).collection('devices').where('deviceSerialNumber', '==', device_serial_number).get()
        
        if len(querySnapshot) > 0:
            if is_device_being_checked_out == False:
                device_currently_checked_out_by = querySnapshot[0].to_dict().get('deviceCheckedOutBy')
                if device_currently_checked_out_by != device_being_checked_by:
                    check_user_is_org_deskstation_or_higher(req, org_id)
            # If the device is found, retrieve its document ID.
            docId = querySnapshot[0].id

            # Step 6: Update the device's checkout status in Firestore based on the request.
            if is_device_being_checked_out:
                # If the device is being checked out, update the relevant fields in Firestore.
                db.collection('organizations').document(org_id).collection('devices').document(docId).update({
                    'isDeviceCheckedOut': True,
                    'deviceCheckedOutBy': device_being_checked_by,  # Set the user who checked out the device.
                    'deviceCheckedOutAt': firestore.SERVER_TIMESTAMP,  # Set the current timestamp for checkout.
                    'deviceCheckedOutNote': device_checked_out_note,  # Set the optional checkout note.
                })
            else:
                # If the device is being checked in, clear the checkout fields.
                db.collection('organizations').document(org_id).collection('devices').document(docId).update({
                    'isDeviceCheckedOut': False,
                    'deviceCheckedOutBy': '',  # Clear the user who checked out the device.
                    'deviceCheckedOutAt': None,  # Clear the checkout timestamp.
                    'deviceCheckedOutNote': '',  # Clear the checkout note.
                })
        else:
            # If the device is not found in the organization's device collection, raise a NOT_FOUND error.
            raise https_fn.HttpsError(
                code=https_fn.FunctionsErrorCode.NOT_FOUND,
                message='Device not found'
            )

        # Step 7: Return a success message indicating the device checkout status was updated.
        return {"response": f"Device {device_serial_number} updated"}

    # Catch and re-raise any known Firebase HttpsErrors.
    except https_fn.HttpsError as e:
        raise e

    # Catch any unexpected errors and return a generic error message.
    except Exception as e:
        raise https_fn.HttpsError(
            code=https_fn.FunctionsErrorCode.UNKNOWN,
            message=f"Error updating device checkout status: {str(e)}"
        )
