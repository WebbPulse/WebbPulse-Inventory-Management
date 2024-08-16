from src.shared.shared import db, firestore, https_fn, auth

def add_user_to_organization(uid, org_id, org_member_display_name, org_member_email):
    try:
        org_member_ref = db.collection('organizations').document(org_id).collection('members').document(uid)
        org_member_ref.set({
            'orgMemberId': uid,
            'createdAt': firestore.SERVER_TIMESTAMP,
            'orgMemberDisplayName': org_member_display_name,
            'orgMemberEmail': org_member_email,
            'orgMemberPhotoURL': "",
            'orgMemberRole': "Org Member"
        })
        auth.set_custom_user_claims(uid, {f'org_member_{org_id}': True})
    except Exception as e:
        raise https_fn.HttpsError(code=https_fn.FunctionsErrorCode.UNKNOWN, message=f"Unknown Error adding user to organization: {str(e)}")