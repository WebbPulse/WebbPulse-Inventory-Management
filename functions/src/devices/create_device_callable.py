from src.shared.shared import POSTcorsrules, db, firestore, https_fn, Any, check_user_is_org_member, check_user_is_authed, check_user_token_current

@https_fn.on_call(cors=POSTcorsrules)
def create_device_callable(req: https_fn.CallableRequest) -> Any:
    try:
        # Extract parameters
        serial = req.data["deviceSerialNumber"]
        org_id = req.data["orgId"]
        
        check_user_is_authed(req)
        check_user_token_current(req)
        check_user_is_org_member(req, org_id)

        # Check if the serial and org_id are provided and valid
        if not serial or not org_id:
            raise https_fn.HttpsError(
                code=https_fn.FunctionsErrorCode.INVALID_ARGUMENT,
                message='The function must be called with  valid "serial" and "org_id" arguments.'
            )

        # Create the device in Firestore
        device_ref = db.collection('organizations').document(org_id).collection('devices').document()
        device_ref.set({
            'deviceId': device_ref.id,
            'deviceSerialNumber': serial,
            'createdAt': firestore.SERVER_TIMESTAMP,
            'isDeviceCheckedOut': False,
            'deviceCheckedOutBy': '',
            'deviceCheckedOutAt': None,
        })

        return {"response": f"Device {serial} created"}
    except https_fn.HttpsError as e:
        # Re-raise known HttpsErrors
        raise e
    except Exception as e:
        # Handle any other exceptions
        raise https_fn.HttpsError(
            code=https_fn.FunctionsErrorCode.UNKNOWN,
            message=f"Error creating organization: {str(e)}"
        )