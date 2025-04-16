from src.shared import POSTcorsrules, db, check_user_is_authed, check_user_token_current, check_user_is_email_verified
from firebase_functions import https_fn
from typing import Any

@https_fn.on_call(cors=POSTcorsrules)
def update_global_user_display_name_callable(req: https_fn.CallableRequest) -> Any:
    """
    Firebase Function to update the display name of a global user.
    It ensures that the user is authenticated, their email is verified, and their token is current.
    If the provided display name is valid, it updates the 'userDisplayName' field in Firestore.
    """
    try:
        # Step 1: Extract the display name and user UID from the request.
        user_display_name = req.data["userDisplayName"]
        uid = req.auth.uid

        # Step 2: Perform authentication, email verification, and token validation checks.
        check_user_is_authed(req)
        check_user_is_email_verified(req)
        check_user_token_current(req)

        # Step 3: Validate that the display name is not empty.
        if not user_display_name:
            # If the display name is not provided, raise an INVALID_ARGUMENT error.
            raise https_fn.HttpsError(
                code=https_fn.FunctionsErrorCode.INVALID_ARGUMENT,
                message='The function must be called with one argument: "DisplayName".'
            )

        try:
            # Step 4: Update the user's display name in Firestore under the 'users' collection.
            db.collection('users').document(uid).update({
                'userDisplayName': user_display_name
            })
        except Exception as e:
            # If an error occurs during the Firestore update, raise an UNKNOWN error with details.
            raise https_fn.HttpsError(
                code=https_fn.FunctionsErrorCode.UNKNOWN, 
                message=f"Error updating user display name: {str(e)}"
            )

        # Step 5: Return a success response with the updated display name.
        return {"response": f"User display name updated to {user_display_name}"}
    
    except https_fn.HttpsError as e:
        # Catch and re-raise any known Firebase HttpsErrors to preserve their specific error message and code.
        raise e

    except Exception as e:
        # Catch any unknown exceptions and return a generic UNKNOWN error with the exception's message.
        raise https_fn.HttpsError(
            code=https_fn.FunctionsErrorCode.UNKNOWN,
            message=f"Error updating user display name: {str(e)}"
        )
