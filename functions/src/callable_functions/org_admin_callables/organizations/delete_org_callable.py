from src.shared import https_fn, POSTcorsrules, Any, db, check_user_is_org_admin, check_user_is_authed, check_user_token_current, check_user_is_email_verified, firestore

@https_fn.on_call(cors=POSTcorsrules)
def delete_org_callable(req: https_fn.CallableRequest) -> Any:
    try:
        # Extract parameters
        org_id = req.data["orgId"]
        
        check_user_is_authed(req)
        check_user_is_email_verified(req)
        check_user_token_current(req)
        check_user_is_org_admin(req, org_id)
        
        # Checking attribute.
        if not org_id:
            raise https_fn.HttpsError(
                code=https_fn.FunctionsErrorCode.INVALID_ARGUMENT,
                message='The function must be called with the following arguments: orgId'
            )
        

        #delete organization from global user profiles

        # Reference to the organization's members collection
        members_ref = db.collection('organizations').document(org_id).collection('members')

        # Get all members
        members = members_ref.stream()

        # Perform actions on each user ID in the global users collection
        for member in members:
            user_id = member.id
            # Perform your action here, for example:
            user_ref = db.collection('users').document(user_id)
            user_data = user_ref.get().to_dict()
            if user_data:
                # Example action: Update a field, remove a specific claim, etc.
                user_ref.update({"userOrgIds": firestore.ArrayRemove([org_id])})
                # You can add any other actions here as needed

        # Delete organization after processing all users
        org_ref = db.collection('organizations').document(org_id)
        org_ref.delete()
        
        return {"response": f"Organization deleted: {org_id}"}
    
    except https_fn.HttpsError as e:
        # Re-raise known HttpsErrors
        raise e
    except Exception as e:
        raise https_fn.HttpsError(
            code=https_fn.FunctionsErrorCode.UNKNOWN,
            message=f"An error occurred: {str(e)}"
        )
