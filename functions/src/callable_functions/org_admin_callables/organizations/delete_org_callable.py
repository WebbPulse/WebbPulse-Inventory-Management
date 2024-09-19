from src.shared import https_fn, POSTcorsrules, Any, db, check_user_is_org_admin, check_user_is_authed, check_user_token_current, check_user_is_email_verified, firestore
from src.helper_functions.users.update_user_roles import update_user_roles

@https_fn.on_call(cors=POSTcorsrules)
def delete_org_callable(req: https_fn.CallableRequest) -> Any:
    """
    Firebase Function to delete an organization.
    The function checks if the user is authenticated, their email is verified, and they are an admin of the organization.
    If valid, the organization is marked as deleted and the user's roles in the organization are updated accordingly.
    """
    try:
        # Step 1: Extract the organization ID from the request data.
        org_id = req.data["orgId"]

        # Step 2: Perform authentication, email verification, and token validation checks.
        check_user_is_authed(req)  # Ensure the user is authenticated.
        check_user_is_email_verified(req)  # Ensure the user's email is verified.
        check_user_token_current(req)  # Ensure the user's token is valid and current.
        check_user_is_org_admin(req, org_id)  # Check if the user is an admin of the specified organization.

        # Step 3: Validate that the organization ID is provided and not empty.
        if not org_id:
            raise https_fn.HttpsError(
                code=https_fn.FunctionsErrorCode.INVALID_ARGUMENT,
                message='The function must be called with the following argument: orgId'
            )

        # Step 4: Remove the current user from the organization's user roles.
        uid = req.auth.uid  # Get the current user's UID from the request.
        update_user_roles(uid, 'none', org_id, True)  # Update the user's roles in the organization to 'none' (removal).

        # Step 5: Remove all other users' roles in the organization.
        # Get a reference to the members collection for the specified organization.
        members_ref = db.collection('organizations').document(org_id).collection('members')
        members = members_ref.stream()  # Stream all members in the organization's members collection.

        # Step 6: Loop through each member and update their roles to 'none', removing them from the organization.
        for member in members:
            uid = member.id  # Get each member's UID.
            update_user_roles(uid, 'none', org_id, True)  # Remove the member's role in the organization.

        # Step 7: Mark the organization as deleted in Firestore by setting the 'orgDeleted' field to True.
        org_ref = db.collection('organizations').document(org_id)
        org_ref.set({
            'orgDeleted': True  # Flag the organization as deleted.
        }, merge=True)  # Use merge=True to avoid overwriting other fields.

        # Step 8: Return a success message confirming that the organization was deleted.
        return {"response": f"Organization deleted: {org_id}"}

    # Catch and re-raise any known Firebase HttpsErrors to preserve their error messages and codes.
    except https_fn.HttpsError as e:
        raise e

    # Catch any unknown exceptions and return a generic UNKNOWN error with the exception's message.
    except Exception as e:
        raise https_fn.HttpsError(
            code=https_fn.FunctionsErrorCode.UNKNOWN,
            message=f"An error occurred: {str(e)}"
        )
