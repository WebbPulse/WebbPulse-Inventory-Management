from src.shared import https_fn, POSTcorsrules, Any, db, auth, check_user_is_org_admin, check_user_is_authed, check_user_token_current, check_user_is_email_verified
from src.helper_functions.users.update_user_roles import update_user_roles




@https_fn.on_call(cors=POSTcorsrules)
def update_user_role_callable(req: https_fn.CallableRequest) -> Any:
    # Create the user in Firebase Auth
    try:
        # Extract parameters
        org_id = req.data["orgId"]
        org_member_id = req.data["orgMemberId"]
        org_member_role = req.data["orgMemberRole"]
        
        check_user_is_authed(req)
        check_user_is_email_verified(req)
        check_user_token_current(req)
        check_user_is_org_admin(req, org_id)
        
        # Checking attribute.
        if not org_id or not org_member_id or not org_member_role:
            # Throwing an HttpsError so that the client gets the error details.
            raise https_fn.HttpsError(
                code=https_fn.FunctionsErrorCode.INVALID_ARGUMENT,
                message='The function must be called with the following arguments: orgId, orgMemberId, orgMemberRole'
            )
        # Update user role, true at the end means we revoke the existing refresh token
        update_user_roles(org_member_id, org_member_role, org_id, True)

        return {"response": f"User role updated to: {org_member_role}, token: {req.auth.token}"}
    except https_fn.HttpsError as e:
        # Re-raise known HttpsErrors
        raise e
    except Exception as e:
        raise https_fn.HttpsError(
            code=https_fn.FunctionsErrorCode.UNKNOWN,
            message=f"An error occurred: {str(e)}"
        )
