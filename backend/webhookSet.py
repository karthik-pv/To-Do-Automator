import requests

BOT_TOKEN = "8045767529:AAFYhxsOKzevjoYqdCT-V5M0pWlHeywWzWI"
WEBHOOK_URL = "https://webhook.site/71dc9b06-88f8-48ea-96ed-8ea76512884e"

resp = requests.get(
    f"https://api.telegram.org/bot{BOT_TOKEN}/setWebhook", params={"url": WEBHOOK_URL}
)
print(resp.json())
