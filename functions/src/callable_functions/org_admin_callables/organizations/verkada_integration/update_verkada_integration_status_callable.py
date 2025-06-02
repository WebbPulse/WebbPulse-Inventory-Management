from src.helper_functions.auth.auth_functions import check_user_is_org_admin, check_user_is_authed, check_user_token_current, check_user_is_email_verified
from src.shared import db, POSTcorsrules
from src.helper_functions.verkada_integration.utils.update_all_verkada_device_type import update_all_devices_verkada_device_type

from firebase_functions import https_fn
from typing import Any

@https_fn.on_call(cors=POSTcorsrules)
def update_verkada_integration_status_callable(req: https_fn.CallableRequest) -> Any:
    """
    Firebase Function to update the name of an organization.
    The function ensures the user is authenticated, their email is verified, their token is current, 
    and they are an admin of the organization.
    """

    try:
        org_id = req.data["orgId"]
        enabled = req.data["enabled"]

        check_user_is_authed(req)
        check_user_is_email_verified(req)
        check_user_token_current(req)
        check_user_is_org_admin(req, org_id)

        if not org_id:
            raise https_fn.HttpsError(
                code=https_fn.FunctionsErrorCode.INVALID_ARGUMENT,
                message='The function must be called with the following arguments: orgId, enabled'
            )

        org_ref = db.collection('organizations').document(org_id)
        org_ref.update({
            'orgVerkadaIntegrationEnabled': enabled,
        })
        if enabled:
            if not org_ref.collection('sensitiveConfigs').document('verkadaIntegrationSettings').get().exists:
                org_ref.collection('sensitiveConfigs').document('verkadaIntegrationSettings').set({
                    'orgVerkadaBotUserInfo': {},
                    'orgVerkadaProductSiteDesignations': {  
                        'Access Control Building': '',
                        'Access Control Floor': '',
                        'Access Control Site': '',
                        'Access Level': '',
                        'Camera Site': '',
                        'Classic Alarm Site': '',
                        'Classic Alarm Zone': '',
                        'Command Connector Site': '',
                        'Desk Station Site': '',
                        'Environmental Sensor Site': '',
                        'Gateway Site': '',
                        'Guest Site': '',
                        'Intercom Site': '',
                        'Mailroom Site': '',
                        'New Alarm Site': '',
                        'Speaker Site': '',
                        'Viewing Station Site': '',
                    },
                    'orgVerkadaUserGroups': [],
                })
            update_all_devices_verkada_device_type(org_id)
        
        return {"response": f"Organization Verkada integration status updated to: {enabled}"}

    except https_fn.HttpsError as e:
        raise e

    except Exception as e:
        raise https_fn.HttpsError(
            code=https_fn.FunctionsErrorCode.UNKNOWN,
            message=f"An error occurred: {str(e)}"
        )
