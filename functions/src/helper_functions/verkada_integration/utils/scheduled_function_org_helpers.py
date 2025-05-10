import logging
from typing import List, Tuple, Dict, Any
from src.shared import db
from src.helper_functions.verkada_integration.utils.login_to_verkada import login_to_verkada

# Configure logging if not already configured at a higher level
# logging.basicConfig(level=logging.INFO)

def get_verkada_integrated_orgs_data() -> List[Tuple[str, Dict[str, Any]]]:
    """
    Retrieves organization IDs and Verkada bot user info for organizations
    with Verkada integration enabled.

    Returns:
        List[Tuple[str, Dict[str, Any]]]: A list of tuples, where each tuple
        contains the organization ID (str) and the Verkada bot user info (dict).
        Returns an empty list if no such organizations are found or in case of errors.
    """
    integrated_orgs = []
    try:
        orgs_ref = db.collection('organizations').where('orgVerkadaIntegrationEnabled', '==', True).stream()
        for org_doc in orgs_ref:
            org_id = org_doc.id
            logging.info(f"Processing org_id for Verkada integration: {org_id}")
            
            verkada_org_short_name = None
            verkada_org_bot_email = None
            verkada_org_bot_password = None

            try:
                settings_doc_ref = db.collection('organizations').document(org_id).collection('sensitiveConfigs').document('verkadaIntegrationSettings')
                settings_doc = settings_doc_ref.get()
                if settings_doc.exists:
                    settings_data = settings_doc.to_dict()
                    verkada_org_short_name = settings_data.get('orgVerkadaOrgShortName')
                    verkada_org_bot_email = settings_data.get('orgVerkadaBotEmail')
                    verkada_org_bot_password = settings_data.get('orgVerkadaBotPassword')
                else:
                    logging.warning(f"Verkada integration settings document not found for {org_id} at {settings_doc_ref.path}")
                    continue
            except Exception as e:
                logging.error(f"Error fetching settings for organization {org_id}: {str(e)}")
                continue

            if not verkada_org_short_name or not verkada_org_bot_email or not verkada_org_bot_password:
                logging.warning(f"Skipping organization {org_id}: Missing Verkada credentials for integration.")
                continue

            try:
                verkada_bot_user_info = login_to_verkada(verkada_org_short_name, verkada_org_bot_email, verkada_org_bot_password)
                if verkada_bot_user_info and verkada_bot_user_info.get('org_id') and verkada_bot_user_info.get('user_id'):
                    integrated_orgs.append((org_id, verkada_bot_user_info))
                else:
                    logging.error(f"Failed to log in to Verkada for organization {org_id} or missing critical login info.")
            except Exception as e:
                logging.error(f"Error logging into Verkada for organization {org_id}: {str(e)}")
                continue
                
    except Exception as e:
        logging.error(f"An unexpected error occurred while fetching verkada integrated organizations: {str(e)}")
    
    return integrated_orgs

def get_site_cleaner_enabled_orgs_data() -> List[Tuple[str, Dict[str, Any]]]:
    """
    Retrieves organization IDs and Verkada bot user info for organizations
    where Verkada integration and site cleaner are enabled.

    Returns:
        List[Tuple[str, Dict[str, Any]]]: A list of tuples, where each tuple
        contains the organization ID (str) and the Verkada bot user info (dict).
        Returns an empty list if no such organizations are found or in case of errors.
    """
    site_cleaner_orgs = []
    try:
        # First, get orgs with Verkada integration enabled, as site cleaner depends on it.
        orgs_ref = db.collection('organizations').where('orgVerkadaIntegrationEnabled', '==', True).stream()
        
        for org_doc in orgs_ref:
            org_id = org_doc.id
            logging.info(f"Processing org_id for site cleaner: {org_id}")

            verkada_org_short_name = None
            verkada_org_bot_email = None
            verkada_org_bot_password = None
            
            try:
                settings_doc_ref = db.collection('organizations').document(org_id).collection('sensitiveConfigs').document('verkadaIntegrationSettings')
                settings_doc = settings_doc_ref.get()
                if settings_doc.exists:
                    settings_data = settings_doc.to_dict()
                    if settings_data.get('orgVerkadaSiteCleanerEnabled') == True:
                        verkada_org_short_name = settings_data.get('orgVerkadaOrgShortName')
                        verkada_org_bot_email = settings_data.get('orgVerkadaBotEmail')
                        verkada_org_bot_password = settings_data.get('orgVerkadaBotPassword')
                    else:
                        # Site cleaner is not enabled for this org, skip it.
                        logging.debug(f"Site cleaner not enabled for {org_id}. Skipping.")
                        continue 
                else:
                    logging.warning(f"Verkada integration settings document not found for {org_id} at {settings_doc_ref.path}. Skipping.")
                    continue
            except Exception as e:
                logging.error(f"Error fetching settings for organization {org_id}: {str(e)}. Skipping.")
                continue

            if not verkada_org_short_name or not verkada_org_bot_email or not verkada_org_bot_password:
                logging.warning(f"Skipping organization {org_id}: Missing Verkada credentials though site cleaner is marked enabled.")
                continue

            try:
                verkada_bot_user_info = login_to_verkada(verkada_org_short_name, verkada_org_bot_email, verkada_org_bot_password)
                if verkada_bot_user_info and verkada_bot_user_info.get('org_id') and verkada_bot_user_info.get('user_id'):
                    site_cleaner_orgs.append((org_id, verkada_bot_user_info))
                else:
                    logging.error(f"Failed to log in to Verkada for organization {org_id} or missing critical login info (site cleaner check).")
            except Exception as e:
                logging.error(f"Error logging into Verkada for organization {org_id} (site cleaner check): {str(e)}")
                continue
                
    except Exception as e:
        logging.error(f"An unexpected error occurred while fetching site cleaner enabled organizations: {str(e)}")
        
    return site_cleaner_orgs
