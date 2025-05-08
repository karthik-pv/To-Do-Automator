import os
from dotenv import load_dotenv
from msal import ConfidentialClientApplication

load_dotenv()


def get_access_token():
    client_id = os.getenv("MICROSOFT_CLIENT_ID")
    client_secret = os.getenv("MICROSOFT_CLIENT_SECRET")
    authority = os.getenv("MICROSOFT_AUTHORITY")
    authorization_code = os.getenv("MICROSOFT_AUTHORIZATION_CODE")

    app = ConfidentialClientApplication(
        client_id, client_credential=client_secret, authority=authority
    )

    result = app.acquire_token_by_authorization_code(
        code=authorization_code, scopes=["Tasks.ReadWrite"]
    )

    return result.get("access_token")


def main():
    token = get_access_token()
    print(token)


if __name__ == "__main__":
    main()
