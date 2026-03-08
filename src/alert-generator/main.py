import os
import random
import time
import requests
import logging

# Configure logging
logging.basicConfig(level=logging.INFO, format='%(asctime)s - %(levelname)s - %(message)s')

# Configuration
API_URL = os.getenv("API_URL", "http://alert-api-service:8000/alerts")

DISASTERS = [
    {"title": "Flooding", "severity": "high", "desc": "Widespread flooding reported due to heavy rains."},
    {"title": "Earthquake", "severity": "critical", "desc": "Magnitude 5.4 tremor detected in the region."},
    {"title": "Wildfire", "severity": "critical", "desc": "Fast-moving brush fire threatens residential areas."},
    {"title": "High Winds", "severity": "medium", "desc": "Strong winds causing power outages and tree damage."},
    {"title": "Heavy Rain", "severity": "low", "desc": "Steady rain expected to continue for 12 hours."},
    {"title": "Medical Emergency", "severity": "medium", "desc": "Localized outbreak requiring resource coordination."},
]

LOCATIONS = [
    "North Goa", "South Goa", "Panjim", "Margao", "Vasco da Gama", 
    "Mapusa", "Ponda", "Calangute", "Baga", "Candolim"
]

def generate_alert():
    disaster = random.choice(DISASTERS)
    location = random.choice(LOCATIONS)
    
    payload = {
        "title": f"SIMULATED: {disaster['title']}",
        "location": location,
        "severity": disaster['severity'],
        "description": f"{disaster['desc']} (Auto-generated for testing at {location})"
    }
    
    try:
        logging.info(f"Sending alert: {payload['title']} at {location}")
        response = requests.post(API_URL, json=payload, timeout=5)
        response.raise_for_status()
        logging.info(f"Successfully posted alert: {response.status_code}")
    except Exception as e:
        logging.error(f"Failed to post alert: {e}")

if __name__ == "__main__":
    generate_alert()
