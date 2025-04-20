from src.helper_functions.auth.auth_functions import check_user_is_authed
from src.helper_functions.users.create_global_user_profile import create_global_user_profile
from src.shared import db, POSTcorsrules

from firebase_admin import auth
from firebase_functions import https_fn
from typing import Any

@https_fn.on_call(cors=POSTcorsrules)
def create_global_user_profile_callable(req: https_fn.CallableRequest) -> Any:
    """
    Firebase Function to create a global user profile in Firestore.
    It checks if the user calling the function is authenticated and if their profile already exists in Firestore.
    If the profile exists, it raises an error; otherwise, it creates the profile.
    """

    try: 
        # Step 1: Check if the user is authenticated in the request.
        check_user_is_authed(req)
        
        # Step 2: Extract the user's UID from the authenticated request.
        uid = req.auth.uid

        # Step 3: Get the reference to the user's document in Firestore.
        user_ref = db.collection("users").document(uid)

        # Step 4: Check if the user's document already exists in the Firestore database.
        user_doc = user_ref.get()

        # Step 5: If the document exists, raise an ALREADY_EXISTS error.
        if user_doc.exists:
            raise https_fn.HttpsError(
                code=https_fn.FunctionsErrorCode.ALREADY_EXISTS,
                message=f'User already exists in the database.'
            )

        # Step 6: Retrieve the user's data from Firebase Authentication.
        user = auth.get_user(uid)

        # Step 7: Call the helper function to create a global user profile in Firestore.
        create_global_user_profile(user, inviter_display_name=user.email)

        # Step 8: Return a success response indicating that the user has been created in the database.
        response_message = f"User {user.email} created in database."
        return {"response": response_message}

    # Catch any known Firebase HttpsErrors and re-raise them to preserve their error message and code.
    except https_fn.HttpsError as e:
        raise e

    # Catch all other unknown errors and raise a generic UNKNOWN error with the exception's message.
    except Exception as e:
        raise https_fn.HttpsError(
            code=https_fn.FunctionsErrorCode.UNKNOWN,
            message=f"Error creating user: {str(e)}"
        )
