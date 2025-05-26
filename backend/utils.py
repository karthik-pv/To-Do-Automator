def validate_object(obj):
    if not isinstance(obj, dict):
        return False

    if set(obj.keys()) != {"update_id", "message"}:
        return False

    if not isinstance(obj["update_id"], int):
        return False

    message = obj["message"]

    if set(message.keys()) != {"message_id", "from", "chat", "date", "text"}:
        return False

    if not isinstance(message["message_id"], int):
        return False

    from_obj = message["from"]
    if set(from_obj.keys()) != {
        "id",
        "is_bot",
        "first_name",
        "last_name",
        "language_code",
    }:
        return False

    if (
        not isinstance(from_obj["id"], int)
        or not isinstance(from_obj["is_bot"], bool)
        or not isinstance(from_obj["first_name"], str)
        or not isinstance(from_obj["last_name"], str)
        or not isinstance(from_obj["language_code"], str)
    ):
        return False

    chat_obj = message["chat"]
    if set(chat_obj.keys()) != {"id", "first_name", "last_name", "type"}:
        return False

    if (
        not isinstance(chat_obj["id"], int)
        or not isinstance(chat_obj["first_name"], str)
        or not isinstance(chat_obj["last_name"], str)
        or not isinstance(chat_obj["type"], str)
    ):
        return False

    if not isinstance(message["date"], int):
        return False

    if not isinstance(message["text"], str):
        return False

    return True


def extract_text_from_object(data):
    return data["message"]["text"]
