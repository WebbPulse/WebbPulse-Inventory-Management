from src.shared import POSTcorsrules, db, firestore, https_fn, Any, check_user_is_org_member, check_user_is_authed, check_user_token_current, check_user_is_email_verified

@https_fn.on_call(cors=POSTcorsrules)
def update_device_checkout_status_callable(req: https_fn.CallableRequest) -> Any:
    try:
        #extract parameters from request
        org_id = req.data["orgId"]
        device_serial_number = req.data["deviceSerialNumber"]
        is_device_checked_out = req.data["isDeviceCheckedOut"]
        device_checked_out_by = req.data["deviceCheckedOutBy"]
        
        check_user_is_authed(req)
        check_user_is_email_verified(req)
        check_user_token_current(req)
        check_user_is_org_member(req, org_id)

        # Check if the serial, org_id, and isCheckedOut are provided and valid
        if device_serial_number or org_id or is_device_checked_out or device_checked_out_by is None:
            raise https_fn.HttpsError(
                code=https_fn.FunctionsErrorCode.INVALID_ARGUMENT,
                message='The function must be called with valid "serial", "org_id", and "isCheckedOut" arguments.'
            )

        if device_checked_out_by != req.auth.uid:
            if not req.auth.token.get(f"org_admin_{org_id}") and not req.auth.token.get(f"org_deskstation_{org_id}"):
                raise https_fn.HttpsError(
                    code=https_fn.FunctionsErrorCode.PERMISSION_DENIED,
                    message='You are not authorized to check out devices for other users in the organization.'
                )

        # Update the device in Firestore
        querySnapshot = db.collection('organizations').document(org_id).collection('devices').where('deviceSerialNumber', '==', device_serial_number).get()
        if len(querySnapshot) > 0:
            docId = querySnapshot[0].id
            
            if is_device_checked_out:
                db.collection('organizations').document(org_id).collection('devices').document(docId).update({
                'isDeviceCheckedOut': True,
                'deviceCheckedOutBy': device_checked_out_by,
                'deviceCheckedOutAt': firestore.SERVER_TIMESTAMP,
            })    
                
            else:
                db.collection('organizations').document(org_id).collection('devices').document(docId).update({
                'isDeviceCheckedOut': False,
                'deviceCheckedOutBy': '',
                'deviceCheckedOutAt': None,
            })
        else:
            raise https_fn.HttpsError(
                code=https_fn.FunctionsErrorCode.NOT_FOUND,
                message='Device not found'
            )

        return {"response": f"Device {device_serial_number} created"}
    except https_fn.HttpsError as e:
        # Re-raise known HttpsErrors
        raise e
    except Exception as e:
        # Handle any other exceptions
        raise https_fn.HttpsError(
            code=https_fn.FunctionsErrorCode.UNKNOWN,
            message=f"Error updating device checkout status: {str(e)}"
        )