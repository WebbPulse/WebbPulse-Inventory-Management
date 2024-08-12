from src.shared.shared import https_fn, POSTcorsrules, Any, db



@https_fn.on_call(cors=POSTcorsrules)
def update_user_role_callable(req: https_fn.CallableRequest) -> Any:
    #create the user in firebase auth
    try:
        # Checking that the user is authenticated.
        if req.auth is None:
        # Throwing an HttpsError so that the client gets the error details.
            raise https_fn.HttpsError(code=https_fn.FunctionsErrorCode.FAILED_PRECONDITION,
                                message="The function must be called while authenticated.")
        
        # Extract parameters
        org_id = req.data["orgId"]
        org_member_id = req.data["orgMemberId"]
        org_member_role = req.data["orgMemberRole"]
        # Checking attribute.
        if not org_id or not org_member_id or not org_member_role:
            # Throwing an HttpsError so that the client gets the error details.
            raise https_fn.HttpsError(code=https_fn.FunctionsErrorCode.INVALID_ARGUMENT,
                                message='The function must be called with the following arguments: orgId, orgMemberId, orgMemberRole')

        try:
            db.collection('organizations').document(org_id).collection('members').document(org_member_id).update({
                'orgMemberRole': org_member_role 
            })
        except:
            raise https_fn.HttpsError(code=https_fn.FunctionsErrorCode.UNKNOWN, message=f"Error updating user photo url: {str(e)}")
        return {"response": f"User role updated to: {org_member_role}"}
    
    except https_fn.HttpsError as e:
        # Re-raise known HttpsErrors
        raise e
    except Exception as e:
        # Handle any other exceptions
        raise https_fn.HttpsError(
            code=https_fn.FunctionsErrorCode.UNKNOWN,
            message=f"Error editing user role: {str(e)}"
        )