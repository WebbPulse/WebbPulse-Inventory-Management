from src.shared import db, firestore, https_fn, identity_fn, allowed_domains
from src.helper_functions.users import create_global_user_profile

@identity_fn.before_user_created()
def create_user_ui(event: identity_fn.AuthBlockingEvent) -> identity_fn.BeforeCreateResponse | None:
    user = event.data
    try:
        if not user.email or user.email.split("@")[1] not in allowed_domains:
            raise https_fn.HttpsError(
                code=https_fn.FunctionsErrorCode.INVALID_ARGUMENT,
                message="Unauthorized email"
            )
        create_global_user_profile(user)
    except https_fn.HttpsError as e:
        # Re-raise the specific HttpsError to be handled by Firebase Functions
        raise e
    except Exception as e:
        # Catch all other exceptions and raise a generic HttpsError
        raise https_fn.HttpsError(
            code=https_fn.FunctionsErrorCode.INTERNAL,
            message="An internal error occurred: " + str(e)
        )
