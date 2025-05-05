import json
from flask import Flask, request

from core import inboundTelegramHandler

app = Flask(__name__)


@app.route("/")
def home():
    return "Hello automator !"


@app.route("/inboundTelegram", methods=["POST"])
def inbound_telegram():
    data = request.json
    if isinstance(data, str):
        data = json.loads(data)
    return inboundTelegramHandler(data)


if __name__ == "__main__":
    app.run(debug=True)
