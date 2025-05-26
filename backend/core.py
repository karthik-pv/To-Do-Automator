from utils import validate_object, extract_text_from_object
from ai_model import extract_activities


def inboundTelegramHandler(data):
    if validate_object(data):
        activity_desc_string = extract_text_from_object(data)
        activities = extract_activities(activity_desc_string)
        return activities
    else:
        return None
