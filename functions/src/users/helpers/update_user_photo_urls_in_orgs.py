from src.shared.shared import db

def update_user_photo_urls_in_orgs(org_id, uid, org_member_photo_url):
    try:
        db.collection('organizations').document(org_id).collection('members').document(uid).update({
            'orgMemberPhotoURL': org_member_photo_url,
        })
    except Exception as e:
        pass