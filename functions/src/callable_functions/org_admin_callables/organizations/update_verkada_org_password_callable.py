from src.shared import POSTcorsrules, db, check_user_is_org_admin, check_user_is_authed, check_user_token_current, check_user_is_email_verified

from firebase_functions import https_fn
from typing import Any

@https_fn.on_call(cors=POSTcorsrules)
def update_verkada_org_password_callable(req: https_fn.CallableRequest) -> Any:
    try:
        org_id = req.data["orgId"]
        org_verkada_org_password = req.data["orgVerkadaOrgPassword"]

        check_user_is_authed(req)
        check_user_is_email_verified(req)
        check_user_token_current(req)
        check_user_is_org_admin(req, org_id)

        if not org_id:
            raise https_fn.HttpsError(
                code=https_fn.FunctionsErrorCode.INVALID_ARGUMENT,
                message='The function must be called with the following arguments: orgId, orgVerkadaOrgPassword'
            )

        org_ref = db.collection('organizations').document(org_id)
        org_ref.update({
            'orgVerkadaOrgPassword': org_verkada_org_password,
        })

        return {"response": f"Verkada org password updated to: {org_verkada_org_password}"}

    except https_fn.HttpsError as e:
        raise e

    except Exception as e:
        raise https_fn.HttpsError(
            code=https_fn.FunctionsErrorCode.UNKNOWN,
            message=f"An error occurred: {str(e)}"
        )
