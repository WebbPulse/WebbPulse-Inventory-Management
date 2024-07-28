from firebase_functions import https_fn, identity_fn

# The Firebase Admin SDK to access Cloud Firestore.
from firebase_admin import firestore, auth
import google.cloud.firestore as gcf
from typing import Any

from main import allowed_domains, db, POSTcorsrules

def create_user_profile(user):
    try:
        user_data = {
            'created_at': firestore.SERVER_TIMESTAMP,
            'email': user.email,
            'organizationUids': [],
            'uid': user.uid,
            'username': user.display_name,
        }
        db.collection('users').document(user.uid).set(user_data)
    except Exception as e:
        raise https_fn.HttpsError(code=https_fn.FunctionsErrorCode.UNKNOWN, message=f"Unknown Error creating user profile: {str(e)}")
@identity_fn.before_user_created()
def create_user_ui(event: identity_fn.AuthBlockingEvent) -> identity_fn.BeforeCreateResponse | None:
    user = event.data
    try:
        if not user.email or user.email.split("@")[1] not in allowed_domains:
            return https_fn.HttpsError(
                code=https_fn.FunctionsErrorCode.INVALID_ARGUMENT,
                message="Unauthorized email"
            )
        create_user_profile(user)
    except https_fn.HttpsError as e:
        return identity_fn.BeforeCreateResponse(
            error=identity_fn.Error(
                message=e.message,
                code=e.code
            )
        )


@https_fn.on_call(cors=POSTcorsrules)
def create_user_callable(req: https_fn.CallableRequest) -> Any:
    #create the user in firebase auth
    try:
        # Checking that the user is authenticated.
        if req.auth is None:
        # Throwing an HttpsError so that the client gets the error details.
            raise https_fn.HttpsError(code=https_fn.FunctionsErrorCode.FAILED_PRECONDITION,
                                message="The function must be called while authenticated.")
        
        # Extract parameters 
        new_user_dispay_name = req.data["newUserDisplayName"]
        new_user_email = req.data["newUserEmail"]

        # Checking attribute.
        if not new_user_dispay_name or not new_user_email:
            # Throwing an HttpsError so that the client gets the error details.
            raise https_fn.HttpsError(code=https_fn.FunctionsErrorCode.INVALID_ARGUMENT,
                                message='The function must be called with two arguments, "new_user_dispay_name" and "new_user_email"')

        if new_user_dispay_name.split("@")[1] not in allowed_domains:
            raise https_fn.HttpsError(code=https_fn.FunctionsErrorCode.INVALID_ARGUMENT,
                                message='Unauthorized email for new user')

        #create the user in firebase auth
        user = auth.create_user(
            email=new_user_email,
            email_verified=False,
            display_name=new_user_dispay_name,
            disabled=False
        )
        #create the user profile in firestore
        create_user_profile(user)

        return {"response": f"User {new_user_email} created"}
    except https_fn.HttpsError as e:
        # Re-raise known HttpsErrors
        raise e
    except Exception as e:
        # Handle any other exceptions
        raise https_fn.HttpsError(
            code=https_fn.FunctionsErrorCode.UNKNOWN,
            message=f"Error creating user: {str(e)}"
        )