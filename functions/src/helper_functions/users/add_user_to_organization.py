from src.shared import db, firestore, https_fn, auth
from src.helper_functions.users import update_user_roles
def add_user_to_organization(uid, org_id, org_member_display_name, org_member_email):
    try:
        org_member_ref = db.collection('organizations').document(org_id).collection('members').document(uid)
        org_member_ref.set({
            'orgMemberId': uid,
            'createdAt': firestore.SERVER_TIMESTAMP,
            'orgMemberDisplayName': org_member_display_name,
            'orgMemberEmail': org_member_email,
            'orgMemberPhotoURL': "",
            'orgMemberRole': "member"
        })
        update_user_roles(uid, "member", org_id, False)
    except Exception as e:
        raise https_fn.HttpsError(code=https_fn.FunctionsErrorCode.UNKNOWN, message=f"Unknown Error adding user to organization: {str(e)}")