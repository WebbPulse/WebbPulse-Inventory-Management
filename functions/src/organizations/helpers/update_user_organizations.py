from src.shared.shared import db, gcf, https_fn

def update_user_organizations(uid, organization_uid):
    try:
        user_ref = db.collection('users').document(uid)
        user_ref.update({
            'organizationUids': gcf.ArrayUnion([organization_uid])
        })
    except Exception as e:
        raise https_fn.HttpsError(code=https_fn.FunctionsErrorCode.UNKNOWN, message=f"Unknown Error updating user organizations: {str(e)}")