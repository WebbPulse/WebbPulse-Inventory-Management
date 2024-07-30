from src.shared.shared import https_fn, POSTcorsrules, Any, db



@https_fn.on_call(cors=POSTcorsrules)
def update_global_user_display_name_callable(req: https_fn.CallableRequest) -> Any:
    #create the user in firebase auth
    try:
        # Checking that the user is authenticated.
        if req.auth is None:
        # Throwing an HttpsError so that the client gets the error details.
            raise https_fn.HttpsError(code=https_fn.FunctionsErrorCode.FAILED_PRECONDITION,
                                message="The function must be called while authenticated.")
        
        # Extract parameters 
        display_name = req.data["displayName"]
        uid = req.auth.uid
        # Checking attribute.
        if not display_name:
            # Throwing an HttpsError so that the client gets the error details.
            raise https_fn.HttpsError(code=https_fn.FunctionsErrorCode.INVALID_ARGUMENT,
                                message='The function must be called with one argument: "DisplayName".')

        try:
            db.collection('users').document(uid).update({
                'displayName': display_name 
            })
        except:
            raise https_fn.HttpsError(code=https_fn.FunctionsErrorCode.UNKNOWN, message=f"Error updating user display name: {str(e)}")
        return {"response": f"User display name updated to {display_name}"}
    
    except https_fn.HttpsError as e:
        # Re-raise known HttpsErrors
        raise e
    except Exception as e:
        # Handle any other exceptions
        raise https_fn.HttpsError(
            code=https_fn.FunctionsErrorCode.UNKNOWN,
            message=f"Error creating user: {str(e)}"
        )