from src.shared.shared import auth, https_fn, POSTcorsrules, allowed_domains, Any
from src.users.helpers.create_user_profile import create_user_profile


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