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
    if  req.auth.token.get('auth_time') < mostRecentTokenRevokeTime:
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

def check_user_is_email_verified(req: https_fn.CallableRequest):
    # Check if the user's email is verified
    if not req.auth.token.get('email_verified'):
        raise https_fn.HttpsError(
            code=https_fn.FunctionsErrorCode.PERMISSION_DENIED,
            message="The function must be called with a verified email."
        )
    
def check_user_is_org_member(req: https_fn.CallableRequest, org_id: str):
    # Check if the user has either the member or admin role for the specified organization
    is_member = req.auth.token.get(f"org_member_{org_id}")
    is_admin = req.auth.token.get(f"org_admin_{org_id}")
    is_deskstation = req.auth.token.get(f"org_deskstation_{org_id}")

    if is_member is None and is_admin is None and is_deskstation is None:
        raise https_fn.HttpsError(
            code=https_fn.FunctionsErrorCode.PERMISSION_DENIED,
            message="Unauthorized access. User is not a member or admin of the organization."
        )
    
def check_user_is_org_admin(req: https_fn.CallableRequest, org_id: str):
        # Check for the admin role
        if req.auth.token.get(f"org_admin_{org_id}") is None:
            raise https_fn.HttpsError(code=https_fn.FunctionsErrorCode.PERMISSION_DENIED,
                                      message=f"Unauthorized access. User is not an admin of the organization.")
        
def check_user_is_org_deskstation_or_higher(req: https_fn.CallableRequest, org_id: str):
    # Check for the deskstation role
    is_deskstation = req.auth.token.get(f"org_deskstation_{org_id}")
    is_admin = req.auth.token.get(f"org_admin_{org_id}")

    if is_deskstation is None and is_admin is None:
        raise https_fn.HttpsError(
            code=https_fn.FunctionsErrorCode.PERMISSION_DENIED,
            message="Unauthorized access. User is not a deskstation of the organization."
        )
        
def check_user_is_at_global_org_limit(uid:str):
    # Check if the user is at the global organization limit
    user = auth.get_user(uid)
    custom_claims = user.custom_claims or {}
    org_admin_claims = [claim for claim in custom_claims.keys() if claim.startswith("org_admin_")]
    org_member_claims = [claim for claim in custom_claims.keys() if claim.startswith("org_member_")]
    org_deskstation_claims = [claim for claim in custom_claims.keys() if claim.startswith("org_deskstation_")]
    org_count = len(org_admin_claims) + len(org_member_claims) + len(org_deskstation_claims)
    
    if org_count >= 10:
        raise https_fn.HttpsError(
            code=https_fn.FunctionsErrorCode.FAILED_PRECONDITION,
            message="The user is at the global organization limit."
        )

def check_user_already_belongs_to_org(uid: str, org_id: str):
    # Check if the user already belongs to the organization
    user = auth.get_user(uid)
    custom_claims = user.custom_claims or {}
    org_admin_claims = [claim for claim in custom_claims.keys() if claim.startswith("org_admin_")]
    org_member_claims = [claim for claim in custom_claims.keys() if claim.startswith("org_member_")]
    org_deskstation_claims = [claim for claim in custom_claims.keys() if claim.startswith("org_deskstation_")]
    
    if f"org_admin_{org_id}" in org_admin_claims or f"org_member_{org_id}" in org_member_claims or f"org_deskstation_{org_id}" in org_deskstation_claims:
        raise https_fn.HttpsError(
            code=https_fn.FunctionsErrorCode.ALREADY_EXISTS,
            message="User already belongs to the organization."
        )