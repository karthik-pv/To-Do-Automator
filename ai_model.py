import google.generativeai as genai
import json
import os
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
    You are a precise assistant designed to extract all activities from a user's message.
    
    STRICT REQUIREMENTS:
    1. Extract EVERY activity mentioned in the message
    2. Return a JSON object with an 'activities' key
    3. Each activity should be a clear, concise string
    4. If no activities are found, return an empty list
    5. Ignore filler words and focus on actionable items

    Input Message: {message}

    JSON Output Format:
    {{
      "activities": [
        "activity 1",
        "activity 2",
        ...
      ]
    }}
    """

    prompt = PromptTemplate.from_template(template)

    activity_extractor = RunnablePassthrough() | prompt | llm | JsonOutputParser()

    try:
        result = activity_extractor.invoke({"message": message})

        return {"activities": result.get("activities", [])}

    except Exception as e:
        print(f"An error occurred: {e}")
        return {"activities": []}


def main():
    message = "Uh I want to wake up at five, then solve a leetcode and then uh I'll go for a run. And then I'm gonna go to boxing class. Then uh after college, I want to uh study a little bit of system design. And then I want to record the drums for too sweet and then the guitar for too sweet. And that's it. That's going to be my day."

    activities_json = extract_activities(message)
    print(json.dumps(activities_json, indent=2))


if __name__ == "__main__":
    main()
