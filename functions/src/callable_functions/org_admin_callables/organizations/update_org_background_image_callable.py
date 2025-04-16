from src.shared import POSTcorsrules, db, check_user_is_org_admin, check_user_is_authed, check_user_token_current, check_user_is_email_verified

from firebase_functions import https_fn
from typing import Any

@https_fn.on_call(cors=POSTcorsrules)
def update_org_background_image_callable(req: https_fn.CallableRequest) -> Any:
    """
    Firebase Function to update the background image URL for an organization.
    The function ensures that the user is authenticated, their email is verified, 
    their token is current, and they are an admin of the organization.
    """

    try:
        # Step 1: Extract the organization ID and background image URL from the request.
        org_id = req.data["orgId"]
        org_background_image_url = req.data["orgBackgroundImageURL"]

        # Step 2: Perform authentication, email verification, and token validation checks.
        check_user_is_authed(req)  # Ensure the user is authenticated.
        check_user_is_email_verified(req)  # Ensure the user's email is verified.
        check_user_token_current(req)  # Ensure the user's token is valid and current.
        check_user_is_org_admin(req, org_id)  # Check if the user is an admin of the specified organization.

        # Step 3: Validate that the organization ID is provided.
        if not org_id:
            # If the organization ID is not provided, raise an INVALID_ARGUMENT error.
            raise https_fn.HttpsError(
                code=https_fn.FunctionsErrorCode.INVALID_ARGUMENT,
                message='The function must be called with the following argument: orgId'
            )

        # Step 4: Update the organization's background image URL in Firestore.
        org_ref = db.collection('organizations').document(org_id)  # Reference to the organization document.
        org_ref.update({
            'orgBackgroundImageURL': org_background_image_url,  # Update the background image URL.
        })

        # Step 5: Return a success response with the updated background image URL.
        return {"response": f"Organization background image updated to: {org_background_image_url}"}

    # Catch and re-raise any known Firebase HttpsErrors to preserve their error messages and codes.
    except https_fn.HttpsError as e:
        raise e

    # Catch any unknown exceptions and return a generic UNKNOWN error with the exception's message.
    except Exception as e:
        raise https_fn.HttpsError(
            code=https_fn.FunctionsErrorCode.UNKNOWN,
            message=f"An error occurred: {str(e)}"
        )
