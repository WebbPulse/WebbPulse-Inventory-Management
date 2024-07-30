from src.shared.shared import db

def update_user_display_names_in_orgs(org_id, uid, display_name):
    try:
        db.collection('organizations').document(org_id).collection('members').document(uid).update({
            'displayName': display_name,
        })
    except Exception as e:
        pass