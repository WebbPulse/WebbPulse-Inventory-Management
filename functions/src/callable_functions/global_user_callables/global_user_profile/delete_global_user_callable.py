from src.helper_functions.auth.auth_functions import check_user_is_authed, check_user_token_current, check_user_is_email_verified
from src.shared import db, POSTcorsrules
from firebase_admin import auth
from firebase_functions import https_fn
from typing import Any


@https_fn.on_call(cors=POSTcorsrules)
def delete_global_user_callable(req: https_fn.CallableRequest) -> Any:
    """
    Firebase Function to handle the removal of a global user.
    It checks if the user is authenticated, their email is verified, and their token is current.
    Then, it removes the user from all associated organizations by updating their status in Firestore.
    """
    try:
        # Step 1: Extract the authenticated user's UID from the request.
        uid = req.auth.uid
        
        # Step 2: Check if the user is authenticated, has a verified email, and if their token is still valid.
        check_user_is_authed(req)
        check_user_is_email_verified(req)
        check_user_token_current(req)

        # Step 3: Get the user's details from Firebase Authentication.
        user = auth.get_user(uid)
        
        # Step 4: Retrieve any custom claims associated with the user (e.g., organization memberships).
        custom_claims = user.custom_claims or {}
        
        # Step 5: Extract the organization IDs from the user's custom claims by filtering claims
        # that start with "org_member_" or "org_admin_".
        user_org_ids = [
            claim.split("_")[-1]  # Extract the org ID by splitting the claim string.
            for claim in custom_claims.keys()
            if claim.startswith("org_member_") or claim.startswith("org_admin_")
        ]

        # Step 6: Loop through the list of organization IDs associated with the user.
        for user_org_id in user_org_ids:          
            # Step 7: For each organization, set the 'orgMemberDeleted' flag to True for the user in that organization.
            org_member_ref = db.collection('organizations').document(user_org_id).collection('members').document(uid)
            org_member_ref.set({
                'orgMemberDeleted': True
            }, merge=True)  # Use merge=True to update the document without overwriting other fields.

        # Step 8: Return a success message indicating that the user has been removed globally.
        return {"response": f"Global user removed: {uid}"}
    
    # Catch and re-raise any known Firebase HttpsErrors to preserve their specific error message and code.
    except https_fn.HttpsError as e:
        raise e

    # Catch any unknown exceptions and return a generic UNKNOWN error with the exception's message.
    except Exception as e:
        raise https_fn.HttpsError(
            code=https_fn.FunctionsErrorCode.UNKNOWN,
            message=f"An error occurred: {str(e)}"
        )
