from src.shared import auth, https_fn, POSTcorsrules, allowed_domains, Any, UserNotFoundError, check_user_is_org_admin, check_user_is_authed, check_user_token_current, check_user_is_email_verified
from src.helper_functions.users.create_global_user_profile import create_global_user_profile
from src.helper_functions.users.add_user_to_organization import add_user_to_organization


@https_fn.on_call(cors=POSTcorsrules)
def create_user_callable(req: https_fn.CallableRequest) -> Any:
    # Create the user in Firebase Auth
    try: 
        user_email = req.data["userEmail"]
        org_id = req.data["orgId"]
        
        check_user_is_authed(req)
        check_user_is_email_verified(req)
        check_user_token_current(req)
        check_user_is_org_admin(req, org_id)

        # Checking attribute.
        if not user_email or not org_id:
            # Throwing an HttpsError so that the client gets the error details.
            raise https_fn.HttpsError(code=https_fn.FunctionsErrorCode.INVALID_ARGUMENT,
                                      message='The function must be called with two arguments: "userEmail" and "orgId".')

        if user_email.split("@")[1] not in allowed_domains:
            raise https_fn.HttpsError(code=https_fn.FunctionsErrorCode.INVALID_ARGUMENT,
                                      message='Unauthorized email for new user')

        user = None
        response_message = ""

        def user_exists_in_auth():
            nonlocal user
            try:
                # User exists
                user = auth.get_user_by_email(user_email)
                return True
                    
            except auth.UserNotFoundError:
                # Create the user in Firebase Auth
                user = auth.create_user(
                    email=user_email,
                    email_verified=False,
                    disabled=False
                )
                return False

        if user_exists_in_auth():   
            add_user_to_organization(user.uid, org_id, user.display_name, user_email)
            response_message = f"User {user_email} added to organization."
        else:
            create_global_user_profile(user)
            add_user_to_organization(user.uid, org_id, user.display_name, user_email)
            response_message = f"User {user_email} created and added to organization."

        return {"response": response_message,
                "token": req.auth.token}
    
    except https_fn.HttpsError as e:
        # Re-raise known HttpsErrors
        raise e
    except Exception as e:
        # Handle any other exceptions
        raise https_fn.HttpsError(
            code=https_fn.FunctionsErrorCode.UNKNOWN,
            message=f"Error creating user: {str(e)}"
        )
