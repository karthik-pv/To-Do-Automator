import google.generativeai as genai
import os
from datetime import datetime
from dotenv import load_dotenv
from langchain_core.prompts import PromptTemplate
from langchain_google_genai import ChatGoogleGenerativeAI
from langchain_core.runnables import RunnablePassthrough
from langchain_core.output_parsers import JsonOutputParser

load_dotenv()

GOOGLE_API_KEY = os.getenv("GOOGLE_API_KEY")

if not GOOGLE_API_KEY:
    raise ValueError("GOOGLE_API_KEY not found in .env file")

genai.configure(api_key=GOOGLE_API_KEY)

llm = ChatGoogleGenerativeAI(
    model="gemini-1.5-flash", google_api_key=GOOGLE_API_KEY, temperature=0.7
)


def extract_activities(message):
    """
    Extracts activities from a given message using the Gemini API with Langchain and returns a JSON object.

    Args:
        message: The input message containing activities.

    Returns:
        A JSON object containing a list of activities.
    """

    template = """
    Todays date is {date}
    You are a precise assistant designed to extract all activities from a user's message.
    
    STRICT REQUIREMENTS:
    1. Extract EVERY activity mentioned in the message
    2. Return a JSON object with an 'activities' key
    3. Each activity should be a clear, concise string
    4. If no activities are found, return an empty list
    5. Ignore filler words and focus on actionable items
    6. The activities must be a max of 3 words
    7. I want the activity name only, not the associated verb
    8. Capture the date of the activity as well.....if not mentioned by default it is the next day (send back the date in the format dd-mm-yy)

    Input Message: {message}

    JSON Output Format:
    {{
      "activities": [
        {{"activity" :"activity 1" , "date" : "date_of_activity"}},
        {{"activity" :"activity 2" , "date" : "date_of_activity"}},
        ...
      ]
    }}
    """

    prompt = PromptTemplate.from_template(template)

    activity_extractor = RunnablePassthrough() | prompt | llm | JsonOutputParser()

    try:
        result = activity_extractor.invoke(
            {"message": message, "date": datetime.now()},
        )

        return {"activities": result.get("activities", [])}

    except Exception as e:
        print(f"An error occurred: {e}")
        return {"activities": []}
