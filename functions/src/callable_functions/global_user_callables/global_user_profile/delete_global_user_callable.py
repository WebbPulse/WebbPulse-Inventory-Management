from src.shared import https_fn, POSTcorsrules, Any, db, check_user_is_authed, check_user_token_current, check_user_is_email_verified, auth

@https_fn.on_call(cors=POSTcorsrules)
def delete_global_user_callable(req: https_fn.CallableRequest) -> Any:
    try:
        # Extract parameters
        uid = req.auth.uid
        
        check_user_is_authed(req)
        check_user_is_email_verified(req)
        check_user_token_current(req)

        user = auth.get_user(uid)
        custom_claims = user.custom_claims or {}
        
        # Filter out the organization IDs from the custom claims
        user_org_ids = [
        claim.split("_")[-1]
        for claim in custom_claims.keys()
        if claim.startswith("org_member_") or claim.startswith("org_admin_")
        ]

        for user_org_id in user_org_ids:          
           #delete user from organization
            org_member_ref = db.collection('organizations').document(user_org_id).collection('members').document(uid)
            org_member_ref.set({
                'orgMemberDeleted': True
            }, merge=True)

        return {"response": f"Global user removed: {uid}"}
    
    except https_fn.HttpsError as e:
        # Re-raise known HttpsErrors
        raise e
    except Exception as e:
        raise https_fn.HttpsError(
            code=https_fn.FunctionsErrorCode.UNKNOWN,
            message=f"An error occurred: {str(e)}"
        )
