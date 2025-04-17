from src.shared import POSTcorsrules, db, check_user_is_org_admin, check_user_is_authed, check_user_token_current, check_user_is_email_verified

from firebase_functions import https_fn
from typing import Any

@https_fn.on_call(cors=POSTcorsrules)
def update_verkada_org_short_name_callable(req: https_fn.CallableRequest) -> Any:
    try:
        org_id = req.data["orgId"]
        verkada_org_short_name = req.data["verkadaOrgShortName"]

        check_user_is_authed(req)
        check_user_is_email_verified(req)
        check_user_token_current(req)
        check_user_is_org_admin(req, org_id)

        if not org_id or not verkada_org_short_name:
            raise https_fn.HttpsError(
                code=https_fn.FunctionsErrorCode.INVALID_ARGUMENT,
                message='The function must be called with the following arguments: orgId, verkadaOrgShortName'
            )

        org_ref = db.collection('organizations').document(org_id)
        org_ref.update({
            'verkadaOrgShortName': verkada_org_short_name,
        })

        return {"response": f"Verkada org short name updated to: {verkada_org_short_name}"}

    except https_fn.HttpsError as e:
        raise e

    except Exception as e:
        raise https_fn.HttpsError(
            code=https_fn.FunctionsErrorCode.UNKNOWN,
            message=f"An error occurred: {str(e)}"
        )
