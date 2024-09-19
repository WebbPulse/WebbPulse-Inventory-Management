from src.shared import https_fn, POSTcorsrules, Any, db, check_user_is_org_admin, check_user_is_authed, check_user_token_current, check_user_is_email_verified, firestore
from src.helper_functions.users.update_user_roles import update_user_roles

@https_fn.on_call(cors=POSTcorsrules)
def delete_org_member_callable(req: https_fn.CallableRequest) -> Any:
    """
    Firebase Function to remove a member from an organization.
    The function ensures the user making the request is authenticated, their email is verified, 
    their token is current, and they are an admin of the specified organization.
    It revokes the member's roles and marks them as deleted in Firestore.
    """
    try:
        # Step 1: Extract the organization ID and member ID from the request data.
        org_id = req.data["orgId"]
        org_member_id = req.data["orgMemberId"]
        
        # Step 2: Perform authentication, email verification, and token validation checks.
        check_user_is_authed(req)  # Ensure the user is authenticated.
        check_user_is_email_verified(req)  # Ensure the user's email is verified.
        check_user_token_current(req)  # Ensure the user's token is valid and current.
        check_user_is_org_admin(req, org_id)  # Check if the user is an admin of the specified organization.

        # Step 3: Validate that both organization ID and member ID are provided.
        if not org_id or not org_member_id:
            # Raise an error if either orgId or orgMemberId is missing.
            raise https_fn.HttpsError(
                code=https_fn.FunctionsErrorCode.INVALID_ARGUMENT,
                message='The function must be called with the following arguments: orgId, orgMemberId'
            )

        # Step 4: Revoke the user's roles in the organization.
        update_user_roles(org_member_id, 'none', org_id, True)  # Remove the user from the organization roles.

        # Step 5: Mark the user as deleted in the organization's members collection in Firestore.
        org_member_ref = db.collection('organizations').document(org_id).collection('members').document(org_member_id)
        org_member_ref.set({
            'orgMemberDeleted': True  # Flag the member as deleted without removing the document entirely.
        }, merge=True)  # Use merge=True to avoid overwriting other fields in the document.

        # Step 6: Return a success message indicating the member was removed.
        return {"response": f"Organization member removed: {org_id}"}

    # Catch and re-raise any known Firebase HttpsErrors.
    except https_fn.HttpsError as e:
        raise e

    # Catch any unexpected errors and return a generic error message.
    except Exception as e:
        raise https_fn.HttpsError(
            code=https_fn.FunctionsErrorCode.UNKNOWN,
            message=f"An error occurred: {str(e)}"
        )
