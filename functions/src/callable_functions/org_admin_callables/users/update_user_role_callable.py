from src.shared import POSTcorsrules, check_user_is_org_admin, check_user_is_authed, check_user_token_current, check_user_is_email_verified
from src.helper_functions.users.update_user_roles import update_user_roles

from firebase_functions import https_fn
from typing import Any

@https_fn.on_call(cors=POSTcorsrules)
def update_user_role_callable(req: https_fn.CallableRequest) -> Any:
    """
    Firebase Function to update a member's role in an organization.
    The function ensures the user making the request is authenticated, their email is verified,
    their token is current, and they are an admin of the specified organization.
    It updates the member's role and revokes their existing refresh token.
    """
    try:
        # Step 1: Extract the organization ID, member ID, and new role from the request data.
        org_id = req.data["orgId"]  # Organization ID to which the user belongs.
        org_member_id = req.data["orgMemberId"]  # User ID of the member whose role is being updated.
        org_member_role = req.data["orgMemberRole"]  # The new role to assign to the member.

        # Step 2: Perform authentication, email verification, and token validation checks.
        check_user_is_authed(req)  # Ensure the user is authenticated.
        check_user_is_email_verified(req)  # Ensure the user's email is verified.
        check_user_token_current(req)  # Ensure the user's token is valid and current.
        check_user_is_org_admin(req, org_id)  # Check if the user is an admin of the specified organization.

        # Step 3: Validate that organization ID, member ID, and the new role are provided.
        if not org_id or not org_member_id or not org_member_role:
            # If any of the required parameters are missing, raise an INVALID_ARGUMENT error.
            raise https_fn.HttpsError(
                code=https_fn.FunctionsErrorCode.INVALID_ARGUMENT,
                message='The function must be called with the following arguments: orgId, orgMemberId, orgMemberRole'
            )

        # Step 4: Update the user's role in the organization, and revoke their existing refresh token.
        update_user_roles(org_member_id, org_member_role, org_id, True)  # True indicates that the refresh token should be revoked.

        # Step 5: Return a success message indicating the user's new role.
        return {"response": f"User role updated to: {org_member_role}, token: {req.auth.token}"}

    # Catch and re-raise any known Firebase HttpsErrors.
    except https_fn.HttpsError as e:
        raise e

    # Catch any unexpected errors and return a generic error message.
    except Exception as e:
        raise https_fn.HttpsError(
            code=https_fn.FunctionsErrorCode.UNKNOWN,
            message=f"An error occurred: {str(e)}"
        )
