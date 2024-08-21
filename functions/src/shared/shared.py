from firebase_functions import options, https_fn, identity_fn, firestore_fn
from firebase_admin import firestore, auth
from firebase_admin.auth import UserNotFoundError
import google.cloud.firestore as gcf
from typing import Any
import time

allowed_domains = ["gmail.com","verkada.com"]
POSTcorsrules=options.CorsOptions(cors_origins="*", cors_methods=["get", "post"])
db = firestore.client()

def check_user_token_current(req: https_fn.CallableRequest):
    # Retrieve most recent token revoke time
    user_metadata_ref = db.collection('usersMetadata').document(req.auth.uid)
    user_metadata = user_metadata_ref.get().to_dict()
    
    if not user_metadata or 'mostRecentTokenRevokeTime' not in user_metadata:
        raise https_fn.HttpsError(
            code=https_fn.FunctionsErrorCode.NOT_FOUND,
            message="User metadata or most recent token revoke time not found."
        )
    
    mostRecentTokenRevokeTime = user_metadata['mostRecentTokenRevokeTime']

    # Check if the user token is current
    if  req.auth['auth_time'] < mostRecentTokenRevokeTime:
        raise https_fn.HttpsError(
            code=https_fn.FunctionsErrorCode.FAILED_PRECONDITION,
            message="The function must be called with a valid token."
        )

def check_user_is_authed(req: https_fn.CallableRequest):
    # Check if the user is authenticated
        if req.auth is None:
            raise https_fn.HttpsError(
                code=https_fn.FunctionsErrorCode.FAILED_PRECONDITION,
                message="The function must be called while authenticated."
            )
def check_user_is_org_member(req: https_fn.CallableRequest, org_id: str):
        # Check for the member role
        if req.auth.token.get(f"org_member_{org_id}") is None:
            raise https_fn.HttpsError(code=https_fn.FunctionsErrorCode.PERMISSION_DENIED,
                                      message=f"Unauthorized access.")

def check_user_is_org_admin(req: https_fn.CallableRequest, org_id: str):
        # Check for the admin role
        if req.auth.token.get(f"org_admin_{org_id}") is None:
            raise https_fn.HttpsError(code=https_fn.FunctionsErrorCode.PERMISSION_DENIED,
                                      message=f"Unauthorized access.")