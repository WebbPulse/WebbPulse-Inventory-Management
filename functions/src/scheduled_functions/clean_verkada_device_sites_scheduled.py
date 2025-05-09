from firebase_functions import scheduler_fn, https_fn
from src.shared import db
from src.helper_functions.verkada_integration.login_to_verkada import login_to_verkada
from src.helper_functions.verkada_integration.clean_verkada_device_sites import clean_verkada_device_sites
from src.helper_functions.verkada_integration.sync_verkada_site_ids import sync_verkada_site_ids
import logging

logging.basicConfig(level=logging.INFO)
@scheduler_fn.on_schedule(schedule="every 24 hours", timeout_sec=540)
def clean_verkada_device_sites_scheduled(event: scheduler_fn.ScheduledEvent) -> None:
    """
    Scheduled function to sync Verkada device sites for all enabled organizations every 24 hours.
    """
    logging.info("Starting scheduled Verkada device sites sync.")

    try:
        # Step 1: Query organizations where Verkada integration is enabled at the top level.
        enabled_orgs_query = db.collection('organizations').where('orgVerkadaIntegrationEnabled', '==', True)
        org_snapshots = enabled_orgs_query.stream()

        for org_doc_snapshot in org_snapshots: # org_doc_snapshot is a DocumentSnapshot for an organization
            org_id = org_doc_snapshot.id
            
            # Step 2: For each enabled organization, check if site cleaner is enabled in its sensitiveConfigs.
            settings_doc_ref = db.collection('organizations').document(org_id).collection('sensitiveConfigs').document('verkadaIntegrationSettings')
            settings_doc = settings_doc_ref.get()

            if settings_doc.exists:
                settings_data = settings_doc.to_dict()
                if settings_data.get('orgVerkadaSiteCleanerEnabled') == True:
                    verkada_org_short_name = settings_data.get('orgVerkadaOrgShortName')
                    verkada_org_bot_email = settings_data.get('orgVerkadaBotEmail')
                    verkada_org_bot_password = settings_data.get('orgVerkadaBotPassword')

                    logging.info(f"Processing organization: {org_id}")

                    # Check if necessary credentials are present
                    if not verkada_org_short_name or not verkada_org_bot_email or not verkada_org_bot_password:
                        logging.warning(f"Skipping organization {org_id}: Missing Verkada credentials.")
                        continue # to the next org_doc_snapshot

                    try:
                        # Log in to Verkada
                        verkada_bot_user_info = login_to_verkada(verkada_org_short_name, verkada_org_bot_email, verkada_org_bot_password)

                        verkada_org_id_from_login = verkada_bot_user_info.get('org_id')
                        verkada_bot_user_id = verkada_bot_user_info.get('user_id')

                        if not verkada_org_id_from_login or not verkada_bot_user_id:
                             logging.error(f"Failed to log in to Verkada for organization {org_id}. Check credentials.")
                             continue # Skip to the next organization

                        # Sync device sites
                        clean_verkada_device_sites(org_id, verkada_bot_user_info)
                        logging.info(f"Successfully synced Verkada device sites for organization {org_id}.")
                        sync_verkada_site_ids(org_id, verkada_bot_user_info)
                        logging.info(f"Successfully synced Verkada device sites for organization {org_id}.")
                    except Exception as e:
                        logging.error(f"Error processing organization {org_id}: {str(e)}")
                        # Continue to the next organization even if one fails
    except Exception as e:
        logging.error(f"Error in scheduled function: {str(e)}")
        # Handle any errors that occur during the scheduled function execution
    logging.info("Finished scheduled Verkada device sites sync.")