from src.shared import https_fn, POSTcorsrules, Any, db, check_user_is_org_admin, check_user_is_authed, check_user_token_current, check_user_is_email_verified, firestore
from src.helper_functions.users.update_user_roles import update_user_roles

@https_fn.on_call(cors=POSTcorsrules)
def delete_org_member_callable(req: https_fn.CallableRequest) -> Any:
    try:
        # Extract parameters
        org_id = req.data["orgId"]
        org_member_id = req.data["orgMemberId"]
        
        check_user_is_authed(req)
        check_user_is_email_verified(req)
        check_user_token_current(req)
        check_user_is_org_admin(req, org_id)
        
        # Checking attribute.
        if not org_id or not org_member_id:
            raise https_fn.HttpsError(
                code=https_fn.FunctionsErrorCode.INVALID_ARGUMENT,
                message='The function must be called with the following arguments: orgId, orgMemberId'
            )
        

        #revoke user roles for organization
        update_user_roles(org_member_id, 'none', org_id, True)    
                
        #delete user from organization
        org_member_ref = db.collection('organizations').document(org_id).collection('members').document(org_member_id)
        org_member_ref.set({
            'orgMemberDeleted': True
        }, merge=True)

        return {"response": f"Organization member removed: {org_id}"}
    
    except https_fn.HttpsError as e:
        # Re-raise known HttpsErrors
        raise e
    except Exception as e:
        raise https_fn.HttpsError(
            code=https_fn.FunctionsErrorCode.UNKNOWN,
            message=f"An error occurred: {str(e)}"
        )
