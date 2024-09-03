from src.shared import https_fn, POSTcorsrules, Any, db, check_user_is_org_member, check_user_is_authed, check_user_token_current, check_user_is_email_verified


@https_fn.on_call(cors=POSTcorsrules)
def delete_device_callable(req: https_fn.CallableRequest) -> Any:
    try:
        # Extract parameters
        org_id = req.data["orgId"]
        device_id = req.data["deviceId"]
        
        check_user_is_authed(req)
        check_user_is_email_verified(req)
        check_user_token_current(req)
        check_user_is_org_member(req, org_id)
        
        # Checking attribute.
        if not org_id or not device_id:
            raise https_fn.HttpsError(
                code=https_fn.FunctionsErrorCode.INVALID_ARGUMENT,
                message='The function must be called with the following arguments: orgId, deviceId'
            )
              
        #delete device from organization
        device_ref = db.collection('organizations').document(org_id).collection('devices').document(device_id)
        device_ref.set({
            'deviceDeleted': True
        }, merge=True)

        return {"response": f"Organization device removed: {device_id}"}
    
    except https_fn.HttpsError as e:
        # Re-raise known HttpsErrors
        raise e
    except Exception as e:
        raise https_fn.HttpsError(
            code=https_fn.FunctionsErrorCode.UNKNOWN,
            message=f"An error occurred: {str(e)}"
        )