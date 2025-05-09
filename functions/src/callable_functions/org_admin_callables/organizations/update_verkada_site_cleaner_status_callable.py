from firebase_functions import https_fn
from firebase_admin import firestore
from src.shared import db, POSTcorsrules # Assuming POSTcorsrules is defined in shared.py
from src.helper_functions.auth.auth_functions import (
    check_user_is_authed,
    check_user_is_email_verified,
    check_user_token_current,
    check_user_is_org_admin,
)
from src.helper_functions.verkada_integration.clean_verkada_user_list import clean_verkada_user_list
from src.helper_functions.verkada_integration.clean_verkada_user_groups import clean_verkada_user_groups
from src.helper_functions.verkada_integration.clean_verkada_device_sites import clean_verkada_device_sites
from src.helper_functions.verkada_integration.login_to_verkada import login_to_verkada
from src.helper_functions.verkada_integration.clean_verkada_device_names import clean_verkada_device_names
from src.helper_functions.verkada_integration.sync_verkada_site_ids import sync_verkada_site_ids

@https_fn.on_call(cors=POSTcorsrules, timeout_sec=540)
def update_verkada_site_cleaner_status_callable(req: https_fn.CallableRequest,) -> any:
    """
    Updates the Verkada Site Cleaner status for a given organization.
    """
    try:
        org_id = req.data.get("orgId")
        enabled = req.data.get("enabled")

        check_user_is_authed(req)
        check_user_is_email_verified(req)
        check_user_token_current(req)
        check_user_is_org_admin(req, org_id)

    
        if not org_id:
            raise https_fn.HttpsError(
                code=https_fn.FunctionsErrorCode.INVALID_ARGUMENT,
                message='The function must be called with an "orgId" argument.'
            )
        if enabled is None or not isinstance(enabled, bool):
            raise https_fn.HttpsError(
                code=https_fn.FunctionsErrorCode.INVALID_ARGUMENT,
                message='The function must be called with an "enabled" (boolean) argument.'
            )
        
        
        org_verkada_settings_ref = db.collection('organizations').document(org_id).collection('sensitiveConfigs').document('verkadaIntegrationSettings')
        org_verkada_settings_ref.set({
            'orgVerkadaSiteCleanerEnabled': enabled
        }, merge=True)
        if enabled:
            #login to Verkada and run the cleaner
            current_verkada_settings = org_verkada_settings_ref.get().to_dict()
            verkada_org_shortname = current_verkada_settings.get('orgVerkadaOrgShortName')
            verkada_org_bot_email = current_verkada_settings.get('orgVerkadaBotEmail')
            verkada_org_bot_password = current_verkada_settings.get('orgVerkadaBotPassword')
            verkada_bot_user_info = login_to_verkada(verkada_org_shortname, verkada_org_bot_email, verkada_org_bot_password)
            
            clean_verkada_user_list(verkada_bot_user_info)
            clean_verkada_user_groups(org_id, verkada_bot_user_info)
            clean_verkada_device_names(org_id, verkada_bot_user_info)
            clean_verkada_device_sites(org_id, verkada_bot_user_info)
            sync_verkada_site_ids(org_id, verkada_bot_user_info)

        return {"status": "success", "message": f"Verkada Site Cleaner status for organization {org_id} updated to {enabled}."}

    except https_fn.HttpsError as e:
        # Re-raise HttpsError exceptions directly
        raise e
    except Exception as e:
       
        print(f"An error occurred: {e}") 
        raise https_fn.HttpsError(
            code=https_fn.FunctionsErrorCode.INTERNAL,
            message=f"An internal error occurred: {str(e)}"
        )