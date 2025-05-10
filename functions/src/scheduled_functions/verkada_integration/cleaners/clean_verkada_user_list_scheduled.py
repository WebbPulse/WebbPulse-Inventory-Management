from firebase_functions import scheduler_fn
from src.helper_functions.verkada_integration.cleaners.clean_verkada_user_list import clean_verkada_user_list
from src.helper_functions.verkada_integration.utils.scheduled_function_org_helpers import get_site_cleaner_enabled_orgs_data

import logging

logging.basicConfig(level=logging.INFO)

@scheduler_fn.on_schedule(schedule="every 24 hours", timeout_sec=540)
def clean_verkada_user_list_scheduled(event: scheduler_fn.ScheduledEvent) -> None:
    logging.info("Starting scheduled Verkada user list cleaning.")
    try:
        orgs_with_verkada_integration = get_site_cleaner_enabled_orgs_data()
        if not orgs_with_verkada_integration:
            logging.info("No organizations found with Verkada user list cleaning enabled.")
            return
        for org_id, verkada_bot_user_info in orgs_with_verkada_integration:
            try:
                clean_verkada_user_list(verkada_bot_user_info)
                logging.info(f"Successfully cleaned verkada user list for organization {org_id}.")

            except Exception as e:
                logging.error(f"Error processing organization {org_id}: {str(e)}")

        logging.info("Finished scheduled Verkada user list cleaning.") # Corrected log message

    except Exception as e:
        logging.error(f"An unexpected error occurred during the scheduled sync: {str(e)}")