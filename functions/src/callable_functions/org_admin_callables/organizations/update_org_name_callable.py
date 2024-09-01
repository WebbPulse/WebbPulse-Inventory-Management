from src.shared import https_fn, POSTcorsrules, Any, db, check_user_is_org_admin, check_user_is_authed, check_user_token_current, check_user_is_email_verified




@https_fn.on_call(cors=POSTcorsrules)
def update_org_name_callable(req: https_fn.CallableRequest) -> Any:
    # Create the user in Firebase Auth
    try:
        # Extract parameters
        org_id = req.data["orgId"]
        org_name = req.data["orgName"]
        
        check_user_is_authed(req)
        check_user_is_email_verified(req)
        check_user_token_current(req)
        check_user_is_org_admin(req, org_id)
        
        # Checking attribute.
        if not org_id  or not org_name:
            # Throwing an HttpsError so that the client gets the error details.
            raise https_fn.HttpsError(
                code=https_fn.FunctionsErrorCode.INVALID_ARGUMENT,
                message='The function must be called with the following arguments: orgId, orgName'
            )
        # Update organization background image
        org_ref = db.collection('organizations').document(org_id)
        org_ref.update({
            'orgName': org_name,
        })
        return {"response": f"Organization name updated to: {org_name}"}
    except https_fn.HttpsError as e:
        # Re-raise known HttpsErrors
        raise e
    except Exception as e:
        raise https_fn.HttpsError(
            code=https_fn.FunctionsErrorCode.UNKNOWN,
            message=f"An error occurred: {str(e)}"
        )