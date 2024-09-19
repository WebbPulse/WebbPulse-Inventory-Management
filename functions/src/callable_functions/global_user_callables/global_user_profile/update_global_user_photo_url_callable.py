from src.shared import https_fn, POSTcorsrules, Any, db, check_user_is_authed, check_user_token_current, check_user_is_email_verified

@https_fn.on_call(cors=POSTcorsrules)
def update_global_user_photo_url_callable(req: https_fn.CallableRequest) -> Any:
    """
    Firebase Function to update the photo URL of a global user.
    It ensures that the user is authenticated, their email is verified, and their token is current.
    If valid, it updates the 'userPhotoURL' field in Firestore.
    """
    try:
        # Step 1: Extract the photo URL and user UID from the request.
        user_photo_url = req.data["userPhotoURL"]
        uid = req.auth.uid

        # Step 2: Perform authentication, email verification, and token validation checks.
        check_user_is_authed(req)
        check_user_is_email_verified(req)
        check_user_token_current(req)

        try:
            # Step 3: Update the user's photo URL in Firestore under the 'users' collection.
            db.collection('users').document(uid).update({
                'userPhotoURL': user_photo_url
            })
        except Exception as e:
            # If an error occurs during the Firestore update, raise an UNKNOWN error with details.
            raise https_fn.HttpsError(
                code=https_fn.FunctionsErrorCode.UNKNOWN, 
                message=f"Error updating user photo URL: {str(e)}"
            )

        # Step 4: Return a success response with the updated photo URL.
        return {"response": f"User photo URL updated to {user_photo_url}"}
    
    except https_fn.HttpsError as e:
        # Catch and re-raise any known Firebase HttpsErrors to preserve their specific error message and code.
        raise e

    except Exception as e:
        # Catch any unknown exceptions and return a generic UNKNOWN error with the exception's message.
        raise https_fn.HttpsError(
            code=https_fn.FunctionsErrorCode.UNKNOWN,
            message=f"Error updating user: {str(e)}"
        )
