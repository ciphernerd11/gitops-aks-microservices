import os
import random
import time
import requests
import logging

# Configure logging
logging.basicConfig(level=logging.INFO, format='%(asctime)s - %(levelname)s - %(message)s')

# Configuration
API_URL = os.getenv("API_URL", "http://alert-api-service:8000/alerts")

DISASTER_TEMPLATES = [
    {
        "category": "Weather",
        "severity": "high",
        "title_tpl": "FLASH FLOOD EMERGENCY",
        "desc_tpl": "IMMEDIATE ACTION REQUIRED: Life-threatening flash flooding is occurring in {location}. Seek higher ground immediately. Do not attempt to travel unless fleeing an area subject to flooding."
    },
    {
        "category": "Geological",
        "severity": "critical",
        "title_tpl": "MAJOR EARTHQUAKE DETECTED",
        "desc_tpl": "A magnitude {mag} earthquake has been detected near {location}. Expect strong shaking. Drop, Cover, and Hold On. Initial reports indicate potential infrastructure damage."
    },
    {
        "category": "Weather",
        "severity": "critical",
        "title_tpl": "EXTREME WIND WARNING",
        "desc_tpl": "Dangerous winds exceeding 120km/h are impacting {location}. Stay indoors and away from windows. Power outages and structural damage are highly likely."
    },
    {
        "category": "Public Health",
        "severity": "medium",
        "title_tpl": "PUBLIC HEALTH ADVISORY",
        "desc_tpl": "Health officials have detected a localized outbreak in {location}. Residents are advised to follow standard sanitation protocols and monitor for symptoms. Resource teams are on-site."
    },
    {
        "category": "Fire",
        "severity": "critical",
        "title_tpl": "EVACUATION ORDER: WILDFIRE",
        "desc_tpl": "A fast-moving vegetation fire is threatening structures in {location}. AN EVACUATION ORDER IS IN EFFECT. Leave the area immediately via designated routes."
    }
]

LOCATIONS = [
    {"name": "Panjim City Center", "lat": 15.4909, "lon": 73.8278},
    {"name": "Margao Railway Hub", "lat": 15.2736, "lon": 73.9581},
    {"name": "Vasco Industrial Zone", "lat": 15.3959, "lon": 73.8117},
    {"name": "Mapusa Market District", "lat": 15.5937, "lon": 73.8142},
    {"name": "Ponda Foothills", "lat": 15.4026, "lon": 74.0089},
    {"name": "Calangute Coastal Strip", "lat": 15.5494, "lon": 73.7535}
]

def generate_alert():
    tpl = random.choice(DISASTER_TEMPLATES)
    loc = random.choice(LOCATIONS)
    
    # Fill dynamic fields
    mag = round(random.uniform(5.5, 7.8), 1)
    title = tpl["title_tpl"]
    description = tpl["desc_tpl"].format(location=loc["name"], mag=mag)
    
    payload = {
        "title": title,
        "category": tpl["category"],
        "severity": tpl["severity"],
        "location": loc["name"],
        "description": description,
        "latitude": loc["lat"],
        "longitude": loc["lon"],
        "active": True
    }
    
    try:
        logging.info(f"Broadcasting Emergency Alert: {title} - {loc['name']}")
        response = requests.post(API_URL, json=payload, timeout=5)
        response.raise_for_status()
        logging.info(f"Broadcast successful. Response: {response.status_code}")
    except Exception as e:
        logging.error(f"Critical Error: Failed to broadcast emergency alert: {e}")

if __name__ == "__main__":
    generate_alert()
