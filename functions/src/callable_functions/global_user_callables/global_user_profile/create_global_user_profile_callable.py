from src.shared import auth, https_fn, db, POSTcorsrules, allowed_domains, Any, UserNotFoundError, check_user_is_org_admin, check_user_is_authed, check_user_token_current, check_user_is_email_verified
from src.helper_functions.users.create_global_user_profile import create_global_user_profile


@https_fn.on_call(cors=POSTcorsrules)
def create_global_user_profile_callable(req: https_fn.CallableRequest) -> Any:
    # Create the user in Firebase Auth
    try: 
        check_user_is_authed(req)
        check_user_token_current(req)
        
        
        # Check if the user document already exists in Firestore

        uid = req.auth.token.uid
        user_ref = db.collection("users").document(uid)
        user_doc = user_ref.get()

        if user_doc.exists:
            raise https_fn.HttpsError(code=https_fn.FunctionsErrorCode.ALREADY_EXISTS,
                                      message=f'User already exists in the database.')

        user = auth.get_user(uid)
        create_global_user_profile(user)
        response_message = f"User {user.email} created in database."

        return {"response": response_message}
    
    except https_fn.HttpsError as e:
        # Re-raise known HttpsErrors
        raise e
    except Exception as e:
        # Handle any other exceptions
        raise https_fn.HttpsError(
            code=https_fn.FunctionsErrorCode.UNKNOWN,
            message=f"Error creating user: {str(e)}"
        )
