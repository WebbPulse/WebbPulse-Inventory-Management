from src.shared import POSTcorsrules, db, check_user_is_org_admin, check_user_is_authed, check_user_token_current, check_user_is_email_verified

from firebase_functions import https_fn
from typing import Any

@https_fn.on_call(cors=POSTcorsrules)
def delete_device_callable(req: https_fn.CallableRequest) -> Any:
    """
    Firebase Function to mark a device as deleted in an organization's device collection.
    The function ensures the user is authenticated, their email is verified, their token is current,
    and they are an admin of the specified organization.
    """
    try:
        # Step 1: Extract the organization ID and device ID from the request data.
        org_id = req.data["orgId"]  # The organization ID from which the device will be deleted.
        device_id = req.data["deviceId"]  # The ID of the device to be deleted.

        # Step 2: Perform authentication, email verification, and token validation checks.
        check_user_is_authed(req)  # Ensure the user is authenticated.
        check_user_is_email_verified(req)  # Ensure the user's email is verified.
        check_user_token_current(req)  # Ensure the user's token is valid and current.
        check_user_is_org_admin(req, org_id)  # Check if the user is an admin of the specified organization.

        # Step 3: Validate that both organization ID and device ID are provided.
        if not org_id or not device_id:
            # If either the organization ID or device ID is missing, raise an INVALID_ARGUMENT error.
            raise https_fn.HttpsError(
                code=https_fn.FunctionsErrorCode.INVALID_ARGUMENT,
                message='The function must be called with the following arguments: orgId, deviceId'
            )

        # Step 4: Mark the device as deleted in the organization's Firestore document.
        device_ref = db.collection('organizations').document(org_id).collection('devices').document(device_id)
        device_ref.set({
            'deviceDeleted': True  # Set the 'deviceDeleted' field to True to mark the device as deleted.
        }, merge=True)  # Use merge=True to avoid overwriting other fields in the document.

        # Step 5: Return a success message indicating the device has been removed.
        return {"response": f"Organization device removed: {device_id}"}

    # Catch and re-raise any known Firebase HttpsErrors.
    except https_fn.HttpsError as e:
        raise e

    # Catch any unexpected errors and return a generic error message.
    except Exception as e:
        raise https_fn.HttpsError(
            code=https_fn.FunctionsErrorCode.UNKNOWN,
            message=f"An error occurred: {str(e)}"
        )
