from src.helper_functions.auth.auth_functions import check_user_is_org_admin, check_user_is_authed, check_user_token_current, check_user_is_email_verified
from src.shared import db, POSTcorsrules
from src.helper_functions.verkada_integration.grant_all_verkada_permissions import grant_all_verkada_permissions
from src.helper_functions.verkada_integration.login_to_verkada import login_to_verkada
from src.helper_functions.verkada_integration.sync_verkada_device_ids import sync_verkada_device_ids
from src.helper_functions.verkada_integration.clean_verkada_user_list import clean_verkada_user_list


from firebase_functions import https_fn
from typing import Any


@https_fn.on_call(cors=POSTcorsrules, timeout_sec=540)
def sync_verkada_permissions_callable(req: https_fn.CallableRequest) -> Any:
    """
    Firebase Function to update the name of an organization.
    The function ensures the user is authenticated, their email is verified, their token is current, 
    and they are an admin of the organization.
    """

    try:
        org_id = req.data["orgId"]
        verkada_org_short_name = req.data["orgVerkadaOrgShortName"]
        verkada_org_bot_email = req.data["orgVerkadaBotEmail"]
        verkada_org_bot_password = req.data["orgVerkadaBotPassword"]

        check_user_is_authed(req)
        check_user_is_email_verified(req)
        check_user_token_current(req)
        check_user_is_org_admin(req, org_id)

        if not org_id or not verkada_org_short_name or not verkada_org_bot_email or not verkada_org_bot_password:
            raise https_fn.HttpsError(
                code=https_fn.FunctionsErrorCode.INVALID_ARGUMENT,
                message='The function must be called with the following arguments: orgId, orgVerkadaOrgShortName, orgVerkadaBotEmail, orgVerkadaBotPassword'
            )
        
        
        verkada_bot_user_info = login_to_verkada(verkada_org_short_name, verkada_org_bot_email, verkada_org_bot_password)
        
        verkada_org_id = verkada_bot_user_info.get('org_id')
        verkada_bot_user_id = verkada_bot_user_info.get('user_id')
        
        if not verkada_org_id or not verkada_bot_user_id:
            raise https_fn.HttpsError(
                code=https_fn.FunctionsErrorCode.PERMISSION_DENIED,
                message='Failed to log in to Verkada. Please check your credentials.'
            )
        
        org_ref = db.collection('organizations').document(org_id).collection('sensitiveConfigs').document('verkadaIntegrationSettings')
        org_ref.update({
            'orgVerkadaOrgId': verkada_org_id,
            'orgVerkadaBotUserId': verkada_bot_user_id,
            'orgVerkadaBotEmail': verkada_org_bot_email,
            'orgVerkadaBotPassword': verkada_org_bot_password,
            'orgVerkadaOrgShortName': verkada_org_short_name,
        })
        grant_all_verkada_permissions(verkada_bot_user_info)
        sync_verkada_device_ids(org_id, verkada_bot_user_info)
        clean_verkada_user_list(verkada_bot_user_info)

        return {"response": f"Organization Verkada permissions synced successfully."}

    except https_fn.HttpsError as e:
        raise e

    except Exception as e:
        raise https_fn.HttpsError(
            code=https_fn.FunctionsErrorCode.UNKNOWN,
            message=f"An error occurred: {str(e)}"
        )
