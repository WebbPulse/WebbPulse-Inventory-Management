from src.shared import https_fn, POSTcorsrules, Any, db, check_user_is_authed, check_user_token_current



@https_fn.on_call(cors=POSTcorsrules)
def update_global_user_display_name_callable(req: https_fn.CallableRequest) -> Any:
    #create the user in firebase auth
    try:
        # Extract parameters 
        user_display_name = req.data["userDisplayName"]
        uid = req.auth.uid
        # Check if the user is authenticated
        check_user_is_authed(req)
        check_user_token_current(req)
        
        # Checking attribute.
        if not user_display_name:
            # Throwing an HttpsError so that the client gets the error details.
            raise https_fn.HttpsError(code=https_fn.FunctionsErrorCode.INVALID_ARGUMENT,
                                message='The function must be called with one argument: "DisplayName".')

        try:
            db.collection('users').document(uid).update({
                'userDisplayName': user_display_name 
            })
        except:
            raise https_fn.HttpsError(code=https_fn.FunctionsErrorCode.UNKNOWN, message=f"Error updating user display name: {str(e)}")
        return {"response": f"User display name updated to {user_display_name}"}
    
    except https_fn.HttpsError as e:
        # Re-raise known HttpsErrors
        raise e
    except Exception as e:
        # Handle any other exceptions
        raise https_fn.HttpsError(
            code=https_fn.FunctionsErrorCode.UNKNOWN,
            message=f"Error creating user: {str(e)}"
        )