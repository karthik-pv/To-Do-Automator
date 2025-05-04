import requests

BOT_TOKEN = ""
WEBHOOK_URL = ""

resp = requests.get(
    f"https://api.telegram.org/bot{BOT_TOKEN}/setWebhook", params={"url": WEBHOOK_URL}
)
print(resp.json())
