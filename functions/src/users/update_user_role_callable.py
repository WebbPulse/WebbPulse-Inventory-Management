from src.shared.shared import https_fn, POSTcorsrules, Any, db, auth, time, firestore, check_user_is_org_admin, check_user_is_authed, check_user_token_current




@https_fn.on_call(cors=POSTcorsrules)
def update_user_role_callable(req: https_fn.CallableRequest) -> Any:
    # Create the user in Firebase Auth
    try:
        # Extract parameters
        org_id = req.data["orgId"]
        org_member_id = req.data["orgMemberId"]
        org_member_role = req.data["orgMemberRole"]
        
        check_user_is_authed(req)
        check_user_token_current(req)
        check_user_is_org_admin(req, org_id)
        
        # Checking attribute.
        if not org_id or not org_member_id or not org_member_role:
            # Throwing an HttpsError so that the client gets the error details.
            raise https_fn.HttpsError(
                code=https_fn.FunctionsErrorCode.INVALID_ARGUMENT,
                message='The function must be called with the following arguments: orgId, orgMemberId, orgMemberRole'
            )

        # Update role in Firestoreß
        db.collection('organizations').document(org_id).collection('members').document(org_member_id).update({
            'orgMemberRole': org_member_role 
        })
        
        # Retrieve existing custom claims
        user = auth.get_user(org_member_id)
        custom_claims = user.custom_claims or {}

        # Update claims based on role
        if org_member_role == "admin":
            custom_claims[f'org_admin_{org_id}'] = True
            custom_claims[f'org_member_{org_id}'] = True
        elif org_member_role == "member":
            custom_claims.pop(f'org_admin_{org_id}', None)  # Remove the admin claim
            custom_claims[f'org_member_{org_id}'] = True
        else:
            raise https_fn.HttpsError(
                code=https_fn.FunctionsErrorCode.INVALID_ARGUMENT,
                message='Invalid role'
            )
        
        
        # Set the updated custom claims
        auth.set_custom_user_claims(org_member_id, custom_claims)
        # Revoke the refresh tokens to ensure new tokens will include the updated claims
        auth.revoke_refresh_tokens(org_member_id)
        # Mark metadata revoke time in firestore
        db.collection('usersMetadata').document(org_member_id).update({
            'mostRecentTokenRevokeTime': time.time()
        })
        
        
        return {"response": f"User role updated to: {org_member_role}"}
    
    except Exception as e:
        raise https_fn.HttpsError(
            code=https_fn.FunctionsErrorCode.UNKNOWN,
            message=f"An error occurred: {str(e)}"
        )
