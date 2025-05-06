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
            org_id = org_doc.id
            
            # Initialize credentials and settings to None/False
            verkada_org_short_name = None
            verkada_org_bot_email = None
            verkada_org_bot_password = None
            site_cleaner_enabled = False

            # --- Fetch sensitive data from the subcollection ---
            try:
                settings_doc_ref = db.collection('organizations').document(org_id).collection('sensitiveConfigs').document('verkadaIntegrationSettings')
                settings_doc = settings_doc_ref.get()
                if settings_doc.exists:
                    settings_data = settings_doc.to_dict()
                    verkada_org_short_name = settings_data.get('orgVerkadaOrgShortName')
                    verkada_org_bot_email = settings_data.get('orgVerkadaBotEmail')
                    verkada_org_bot_password = settings_data.get('orgVerkadaBotPassword')
                    site_cleaner_enabled = settings_data.get('orgVerkadaSiteCleanerEnabled') == True
                else:
                    logging.warning(f"Verkada integration settings document not found for {org_id} at {settings_doc_ref.path}")
                    continue # Skip to the next organization
            except Exception as e:
                logging.error(f"Error fetching settings for organization {org_id}: {str(e)}")
                continue # Skip to the next organization

            # Check if site cleaner is enabled for this org
            if not site_cleaner_enabled:
                logging.info(f"Skipping organization {org_id}: Verkada site cleaner is not enabled.")
                continue # Skip to the next organization

            logging.info(f"Processing organization: {org_id} (Site cleaner enabled)")

            if not verkada_org_short_name or not verkada_org_bot_email or not verkada_org_bot_password:
                logging.warning(f"Skipping organization {org_id}: Missing Verkada credentials.")
                continue

            try:
                verkada_bot_user_info = login_to_verkada(verkada_org_short_name, verkada_org_bot_email, verkada_org_bot_password)

                verkada_org_id_from_login = verkada_bot_user_info.get('org_id') # Corrected variable name
                verkada_bot_user_id = verkada_bot_user_info.get('user_id')

                if not verkada_org_id_from_login or not verkada_bot_user_id: # Corrected variable name
                     logging.error(f"Failed to log in to Verkada for organization {org_id}. Check credentials.")
                     continue

                clean_verkada_user_list(verkada_bot_user_info)
                logging.info(f"Successfully cleaned verkada user list for organization {org_id}.")

            except Exception as e:
                logging.error(f"Error processing organization {org_id}: {str(e)}")

        logging.info("Finished scheduled Verkada user list cleaning.") # Corrected log message

    except Exception as e:
        logging.error(f"An unexpected error occurred during the scheduled sync: {str(e)}")