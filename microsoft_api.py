import os
import httpx
from dotenv import load_dotenv

load_dotenv()


def get_todo_lists(access_token):
    graph_url = "https://graph.microsoft.com/v1.0/me/todo/lists"

    headers = {"Authorization": f"Bearer {access_token}"}

    try:
        response = httpx.get(graph_url, headers=headers)
        response.raise_for_status()
        return response.json().get("value", [])
    except httpx.HTTPStatusError as e:
        print(f"Error fetching lists: {e}")
        print(f"Response: {e.response.text}")
        return []


def display_lists(lists):
    if not lists:
        print("No Todo lists found.")
        return

    print("\n📋 Your Todo Lists:")
    for i, todo_list in enumerate(lists, 1):
        print(f"\n{i}. {todo_list.get('displayName', 'Unnamed List')}")
        print(f"   List ID: {todo_list.get('id')}")

        # Additional list details if available
        print(f"   Sharing Status: {todo_list.get('wellknownListName', 'Custom List')}")


def main():
    access_token = os.getenv("MICROSOFT_ACCESS_TOKEN")

    # Fetch all lists
    lists = get_todo_lists(access_token)

    # Display lists
    display_lists(lists)

    # List statistics
    print("\n📊 List Statistics:")
    print(f"Total Lists: {len(lists)}")

    # Optional: Identify well-known lists
    well_known_lists = [
        list_info for list_info in lists if list_info.get("wellknownListName")
    ]

    if well_known_lists:
        print("\nWell-Known Lists:")
        for list_info in well_known_lists:
            print(
                f"- {list_info.get('displayName')}: {list_info.get('wellknownListName')}"
            )


if __name__ == "__main__":
    main()
