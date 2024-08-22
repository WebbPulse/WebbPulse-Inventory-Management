from src.shared import db

def update_user_display_names_in_orgs(org_id, uid, org_member_display_name):
    try:
        db.collection('organizations').document(org_id).collection('members').document(uid).update({
            'orgMemberDisplayName': org_member_display_name,
        })
    except Exception as e:
        pass