from src.helper_functions.verkada_integration.sync_verkada_user_groups import sync_verkada_user_groups
from firebase_functions import scheduler_fn
from src.shared import db
from src.helper_functions.verkada_integration.login_to_verkada import login_to_verkada
import logging

# Configure logging
logging.basicConfig(level=logging.INFO)

@scheduler_fn.on_schedule(schedule="every 24 hours", timeout_sec=540)
def sync_verkada_user_groups_scheduled(event: scheduler_fn.ScheduledEvent) -> None:
    """
    Scheduled function to sync Verkada user groups for all enabled organizations every 24 hours.
    """
    logging.info("Starting scheduled Verkada user group sync.")

    try:
        # Query organizations where Verkada integration is enabled
        orgs_ref = db.collection('organizations').where('orgVerkadaIntegrationEnabled', '==', True).stream()

        for org_doc in orgs_ref:
            
            org_id = org_doc.id
            logging.info(f"Processing organization: {org_id}")
            verkada_org_bot_email = None
            verkada_org_bot_password = None

            # --- Fetch sensitive data from the subcollection ---
            try:
                creds_doc_ref = db.collection('organizations').document(org_id).collection('sensitiveConfigs').document('verkadaIntegrationSettings')
                creds_doc = creds_doc_ref.get()
                if creds_doc.exists:
                    creds_data = creds_doc.to_dict()
                    verkada_org_short_name = creds_data.get('orgVerkadaOrgShortName')
                    verkada_org_bot_email = creds_data.get('orgVerkadaBotEmail')
                    verkada_org_bot_password = creds_data.get('orgVerkadaBotPassword')
                else:
                    logging.warning(f"Verkada integration enabled for {org_id}, but credentials document not found at {creds_doc_ref.path}")
            except Exception as e:
                logging.error(f"Error fetching credentials for organization {org_id}: {str(e)}")
                continue
            

            # Check if necessary credentials are present
            if not verkada_org_short_name or not verkada_org_bot_email or not verkada_org_bot_password:
                logging.warning(f"Skipping organization {org_id}: Missing Verkada credentials.")
                continue

            try:
                # Log in to Verkada
                verkada_bot_user_info = login_to_verkada(verkada_org_short_name, verkada_org_bot_email, verkada_org_bot_password)

                verkada_org_id = verkada_bot_user_info.get('org_id')
                verkada_bot_user_id = verkada_bot_user_info.get('user_id')

                if not verkada_org_id or not verkada_bot_user_id:
                     logging.error(f"Failed to log in to Verkada for organization {org_id}. Check credentials.")
                     continue # Skip to the next organization

                # Grant permissions
                sync_verkada_user_groups(org_id, verkada_bot_user_info)
                logging.info(f"Successfully synced Verkada groups for organization {org_id}.")

            except Exception as e:
                logging.error(f"Error processing organization {org_id}: {str(e)}")
                # Continue to the next organization even if one fails

        logging.info("Finished scheduled Verkada groups sync.")

    except Exception as e:
        logging.error(f"An unexpected error occurred during the scheduled sync: {str(e)}")