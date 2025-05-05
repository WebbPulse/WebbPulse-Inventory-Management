from firebase_functions import scheduler_fn, https_fn
from src.shared import db
from src.helper_functions.verkada_integration.login_to_verkada import login_to_verkada
from src.helper_functions.verkada_integration.sync_verkada_device_names import sync_verkada_device_names
import logging

# Configure logging
logging.basicConfig(level=logging.INFO)

@scheduler_fn.on_schedule(schedule="every 24 hours", timeout_sec=540)
def sync_verkada_device_names_scheduled(event: scheduler_fn.ScheduledEvent) -> None:
    """
    Scheduled function to sync Verkada device names for all enabled organizations every 24 hours.
    """
    logging.info("Starting scheduled Verkada permissions sync.")

    try:
        # Query organizations where Verkada integration is enabled
        orgs_ref = db.collection('organizations').where('orgVerkadaIntegrationEnabled', '==', True).stream()

        for org_doc in orgs_ref:
            org_data = org_doc.to_dict()
            org_id = org_doc.id
            verkada_org_short_name = org_data.get('orgVerkadaOrgShortName')
            verkada_org_bot_email = org_data.get('orgVerkadaBotEmail')
            verkada_org_bot_password = org_data.get('orgVerkadaBotPassword')

            logging.info(f"Processing organization: {org_id}")

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

                # Sync device names
                sync_verkada_device_names(verkada_bot_user_info, org_id)
                logging.info(f"Successfully synced Verkada device names for organization {org_id}.")

            except Exception as e:
                logging.error(f"Error processing organization {org_id}: {str(e)}")
                # Continue to the next organization even if one fails

        logging.info("Finished scheduled Verkada device name sync.")

    except Exception as e:
        logging.error(f"An unexpected error occurred during the scheduled sync: {str(e)}")