from firebase_functions import scheduler_fn, https_fn
from src.shared import db
from src.helper_functions.verkada_integration.login_to_verkada import login_to_verkada
from src.helper_functions.verkada_integration.clean_verkada_user_list import clean_verkada_user_list
import logging

logging.basicConfig(level=logging.INFO)

@scheduler_fn.on_schedule(schedule="every 24 hours", timeout_sec=540)
def clean_verkada_user_list_scheduled(event: scheduler_fn.ScheduledEvent) -> None:
    logging.info("Starting scheduled Verkada user list cleaning.")
    try:
        orgs_ref = db.collection('organizations').where('orgVerkadaIntegrationEnabled', '==', True).stream()
        for org_doc in orgs_ref:
            org_data = org_doc.to_dict()
            org_id = org_doc.id
            verkada_org_short_name = org_data.get('orgVerkadaOrgShortName')
            verkada_org_bot_email = org_data.get('orgVerkadaBotEmail')
            verkada_org_bot_password = org_data.get('orgVerkadaBotPassword')

            logging.info(f"Processing organization: {org_id}")

            if not verkada_org_short_name or not verkada_org_bot_email or not verkada_org_bot_password:
                logging.warning(f"Skipping organization {org_id}: Missing Verkada credentials.")
                continue

            try:
                verkada_bot_user_info = login_to_verkada(verkada_org_short_name, verkada_org_bot_email, verkada_org_bot_password)

                verkada_org_id = verkada_bot_user_info.get('org_id')
                verkada_bot_user_id = verkada_bot_user_info.get('user_id')

                if not verkada_org_id or not verkada_bot_user_id:
                     logging.error(f"Failed to log in to Verkada for organization {org_id}. Check credentials.")
                     continue

                org_ref = db.collection('organizations').document(org_id)
                org_ref.update({
                    'orgVerkadaOrgId': verkada_org_id,
                    'orgVerkadaBotUserId': verkada_bot_user_id,
                })

                clean_verkada_user_list(verkada_bot_user_info)
                logging.info(f"Successfully cleaned verkada user list for organization {org_id}.")

            except Exception as e:
                logging.error(f"Error processing organization {org_id}: {str(e)}")

        logging.info("Finished scheduled Verkada permissions sync.")

    except Exception as e:
        logging.error(f"An unexpected error occurred during the scheduled sync: {str(e)}")