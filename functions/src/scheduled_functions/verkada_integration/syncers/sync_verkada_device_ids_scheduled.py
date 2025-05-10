from firebase_functions import scheduler_fn
from src.shared import db
from src.helper_functions.verkada_integration.utils.login_to_verkada import login_to_verkada
from src.helper_functions.verkada_integration.syncers.sync_verkada_device_ids import sync_verkada_device_ids
from src.helper_functions.verkada_integration.utils.scheduled_function_org_helpers import get_verkada_integrated_orgs_data

import logging

# Configure logging
logging.basicConfig(level=logging.INFO)

@scheduler_fn.on_schedule(schedule="every 24 hours", timeout_sec=540)
def sync_verkada_device_ids_scheduled(event: scheduler_fn.ScheduledEvent) -> None:
    """
    Scheduled function to sync Verkada device IDs for all enabled organizations every 24 hours.
    """
    logging.info("Starting scheduled Verkada device IDs sync.")

    try:
        verkada_integrated_orgs = get_verkada_integrated_orgs_data()
        if not verkada_integrated_orgs:
            logging.info("No organizations found with Verkada integration enabled.")
            return
        for org_id, verkada_bot_user_info in verkada_integrated_orgs:
            try:
                sync_verkada_device_ids(org_id, verkada_bot_user_info)
                logging.info(f"Successfully synced Verkada device IDs for organization {org_id}.")

            except Exception as e:
                logging.error(f"Error processing organization {org_id}: {str(e)}")
                # Continue to the next organization even if one fails

        logging.info("Finished scheduled Verkada device IDs sync.")

    except Exception as e:
        logging.error(f"An unexpected error occurred during the scheduled sync: {str(e)}")