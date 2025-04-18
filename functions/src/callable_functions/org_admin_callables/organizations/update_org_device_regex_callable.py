from src.shared import POSTcorsrules, db, check_user_is_org_admin, check_user_is_authed, check_user_token_current, check_user_is_email_verified

from firebase_functions import https_fn
from typing import Any

@https_fn.on_call(cors=POSTcorsrules)
def update_org_device_regex_callable(req: https_fn.CallableRequest) -> Any:
    try:
        org_id = req.data["orgId"]
        org_device_regex_string = req.data["orgDeviceRegexString"]

        check_user_is_authed(req)
        check_user_is_email_verified(req)
        check_user_token_current(req)
        check_user_is_org_admin(req, org_id)

        if not org_id or not org_device_regex_string:
            raise https_fn.HttpsError(
                code=https_fn.FunctionsErrorCode.INVALID_ARGUMENT,
                message='The function must be called with the following arguments: orgId, orgDeviceRegexString'
            )

        org_ref = db.collection('organizations').document(org_id)
        org_ref.update({
            'orgDeviceRegexString': org_device_regex_string,
        })

        return {"response": f"Organization device regex filter changed to: {org_device_regex_string}"}

    except https_fn.HttpsError as e:
        raise e

    except Exception as e:
        raise https_fn.HttpsError(
            code=https_fn.FunctionsErrorCode.UNKNOWN,
            message=f"An error occurred: {str(e)}"
        )
