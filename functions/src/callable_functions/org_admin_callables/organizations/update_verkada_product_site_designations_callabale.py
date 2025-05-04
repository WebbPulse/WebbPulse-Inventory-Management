from src.helper_functions.auth.auth_functions import check_user_is_org_admin, check_user_is_authed, check_user_token_current, check_user_is_email_verified
from src.shared import db, POSTcorsrules
from src.helper_functions.verkada_integration.update_all_verkada_device_type import update_all_devices_verkada_device_type

from firebase_functions import https_fn
from typing import Any

@https_fn.on_call(cors=POSTcorsrules)
def update_verkada_product_site_designations_callable(req: https_fn.CallableRequest) -> Any:
    """
    """

    try:
        org_id = req.data["orgId"]
        updated_designations = req.data["productSiteDesignations"]

        check_user_is_authed(req)
        check_user_is_email_verified(req)
        check_user_token_current(req)
        check_user_is_org_admin(req, org_id)

        if not org_id or updated_designations is None: 
            raise https_fn.HttpsError(
                code=https_fn.FunctionsErrorCode.INVALID_ARGUMENT,
                message='The function must be called with the following arguments: orgId, productSiteDesignations.'
            )

        
        if not isinstance(updated_designations, dict):
             raise https_fn.HttpsError(
                code=https_fn.FunctionsErrorCode.INVALID_ARGUMENT,
                message='The "productSiteDesignations" argument must be a dictionary.'
            )

        org_ref = db.collection('organizations').document(org_id)
        org_ref.collection('sensitiveConfigs').document('verkadaIntegrationSettings').set({
            'orgVerkadaProductSiteDesignations': updated_designations
            
        }, merge=True)

        return {"response": f"Successfully updated the  product site designations for org {org_id}."}

    except https_fn.HttpsError as e:
        raise e

    except Exception as e:
        raise https_fn.HttpsError(
            code=https_fn.FunctionsErrorCode.UNKNOWN,
            message=f"An error occurred: {str(e)}"
        )