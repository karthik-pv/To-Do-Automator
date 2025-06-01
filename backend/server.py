import json
from flask import Flask, request, jsonify
from flask_cors import CORS
from datetime import datetime
import os
from dotenv import load_dotenv
from bson import ObjectId

from core import inboundTelegramHandler
from mongo.data_handler import DataHandler
from mongo.models import Task, TaskList

# Load environment variables
load_dotenv()

app = Flask(__name__)

CORS(app)

# Initialize data handler
CONNECTION_STRING = os.getenv("MONGO_URL")
DATABASE_NAME = os.getenv("DATABASE_NAME", "todo_app")
data_handler = DataHandler(CONNECTION_STRING, DATABASE_NAME)


# Helper function to validate user_id
def get_user_id_from_headers():
    """Extract user_id from request headers"""
    user_id = request.headers.get("X-User-ID")
    if not user_id:
        return None
    try:
        # Validate ObjectId format
        ObjectId(user_id)
        return user_id
    except:
        return None


# Authentication endpoints
@app.route("/auth/register", methods=["POST"])
def register():
    """Register a new user"""
    try:
        data = request.get_json()

        if not data or "email" not in data or "password" not in data:
            return (
                jsonify(
                    {"success": False, "message": "Email and password are required"}
                ),
                400,
            )

        email = data["email"].strip()
        password = data["password"].strip()

        if not email or not password:
            return (
                jsonify(
                    {"success": False, "message": "Email and password cannot be empty"}
                ),
                400,
            )

        if len(password) < 6:
            return (
                jsonify(
                    {
                        "success": False,
                        "message": "Password must be at least 6 characters long",
                    }
                ),
                400,
            )

        user_id = data_handler.create_user(email, password)

        if user_id:
            return (
                jsonify(
                    {
                        "success": True,
                        "message": "User registered successfully",
                        "userId": user_id,
                    }
                ),
                201,
            )
        else:
            return (
                jsonify(
                    {
                        "success": False,
                        "message": "User already exists or registration failed",
                    }
                ),
                409,
            )

    except Exception as e:
        print(f"Registration error: {e}")
        return jsonify({"success": False, "message": "Internal server error"}), 500


@app.route("/auth/login", methods=["POST"])
def login():
    """Authenticate user login"""
    try:
        data = request.get_json()

        if not data or "email" not in data or "password" not in data:
            return (
                jsonify(
                    {"success": False, "message": "Email and password are required"}
                ),
                400,
            )

        email = data["email"].strip()
        password = data["password"].strip()

        user_id = data_handler.authenticate_user(email, password)

        if user_id:
            user = data_handler.get_user_by_id(user_id)
            return (
                jsonify(
                    {
                        "success": True,
                        "message": "Login successful",
                        "userId": user_id,
                        "email": user["email"],
                    }
                ),
                200,
            )
        else:
            return (
                jsonify({"success": False, "message": "Invalid email or password"}),
                401,
            )

    except Exception as e:
        print(f"Login error: {e}")
        return jsonify({"success": False, "message": "Internal server error"}), 500


@app.route("/")
def home():
    return "Hello automator !"


@app.route("/inboundTelegram", methods=["POST"])
def inbound_telegram():
    data = request.json
    if isinstance(data, str):
        data = json.loads(data)
    return inboundTelegramHandler(data)


# ==================== TASK ROUTES ====================


@app.route("/tasks", methods=["POST"])
def create_task():
    """Create a new task"""
    try:
        user_id = get_user_id_from_headers()
        if not user_id:
            return (
                jsonify({"success": False, "message": "User authentication required"}),
                401,
            )

        data = request.get_json()

        if not data or "title" not in data:
            return jsonify({"success": False, "message": "Task title is required"}), 400

        # Handle list_ids - ensure task appears in both the specific list and "Tasks" list
        list_ids = []
        if "listId" in data and data["listId"]:
            list_ids.append(data["listId"])
        elif "list_ids" in data and data["list_ids"]:
            list_ids = (
                data["list_ids"]
                if isinstance(data["list_ids"], list)
                else [data["list_ids"]]
            )

        # Always add to the main "Tasks" list (find the actual ID for the Tasks list)
        tasks_lists = data_handler.get_task_lists(user_id)
        tasks_list_id = None
        for task_list in tasks_lists:
            if task_list.get("name") == "Tasks" or task_list.get("id") == "my-tasks":
                tasks_list_id = task_list.get("_id") or task_list.get("id")
                break

        if tasks_list_id and tasks_list_id not in list_ids:
            list_ids.append(tasks_list_id)

        # If no list specified, default to Tasks list
        if not list_ids:
            list_ids = ["my-tasks"]

        # Create task data with user_id and list_ids
        task_data = {
            "title": data["title"],
            "user_id": user_id,
            "list_ids": list_ids,
            "isCompleted": data.get("isCompleted", False),
            "isImportant": data.get("isImportant", False),
            "note": data.get("note"),
            "dueDate": (
                datetime.fromisoformat(data["dueDate"].replace("Z", "+00:00"))
                if data.get("dueDate")
                else None
            ),
        }

        task_id = data_handler.create_task(task_data)

        if task_id:
            return (
                jsonify(
                    {
                        "success": True,
                        "message": "Task created successfully",
                        "taskId": task_id,
                    }
                ),
                201,
            )
        else:
            return (
                jsonify({"success": False, "message": "Failed to create task"}),
                500,
            )

    except Exception as e:
        print(f"Create task error: {e}")
        return jsonify({"success": False, "message": "Internal server error"}), 500


@app.route("/tasks/<task_id>", methods=["GET"])
def get_task(task_id):
    """Get a specific task"""
    try:
        user_id = get_user_id_from_headers()
        if not user_id:
            return (
                jsonify({"success": False, "message": "User authentication required"}),
                401,
            )

        task = data_handler.get_task_by_id(task_id, user_id)

        if task:
            return (
                jsonify({"success": True, "task": task}),
                200,
            )
        else:
            return (
                jsonify({"success": False, "message": "Task not found"}),
                404,
            )

    except Exception as e:
        print(f"Get task error: {e}")
        return jsonify({"success": False, "message": "Internal server error"}), 500


@app.route("/tasks", methods=["GET"])
def get_tasks():
    """Get all tasks for the user, optionally filtered by list_id"""
    try:
        user_id = get_user_id_from_headers()
        if not user_id:
            return (
                jsonify({"success": False, "message": "User authentication required"}),
                401,
            )

        list_id = request.args.get("listId")

        tasks = data_handler.get_tasks(user_id, list_id)

        return (
            jsonify({"success": True, "tasks": tasks}),
            200,
        )

    except Exception as e:
        print(f"Get tasks error: {e}")
        return jsonify({"success": False, "message": "Internal server error"}), 500


@app.route("/tasks/<task_id>", methods=["PUT"])
def update_task(task_id):
    """Update a task"""
    try:
        user_id = get_user_id_from_headers()
        if not user_id:
            return (
                jsonify({"success": False, "message": "User authentication required"}),
                401,
            )

        data = request.get_json()

        if not data:
            return jsonify({"success": False, "message": "No data provided"}), 400

        # Convert dueDate if provided
        if "dueDate" in data and data["dueDate"]:
            data["dueDate"] = datetime.fromisoformat(
                data["dueDate"].replace("Z", "+00:00")
            )

        success = data_handler.update_task(task_id, user_id, data)

        if success:
            return (
                jsonify({"success": True, "message": "Task updated successfully"}),
                200,
            )
        else:
            return (
                jsonify(
                    {
                        "success": False,
                        "message": "Failed to update task or task not found",
                    }
                ),
                404,
            )

    except Exception as e:
        print(f"Update task error: {e}")
        return jsonify({"success": False, "message": "Internal server error"}), 500


@app.route("/tasks/<task_id>", methods=["DELETE"])
def delete_task(task_id):
    """Delete a task"""
    try:
        user_id = get_user_id_from_headers()
        if not user_id:
            return (
                jsonify({"success": False, "message": "User authentication required"}),
                401,
            )

        success = data_handler.delete_task(task_id, user_id)

        if success:
            return (
                jsonify({"success": True, "message": "Task deleted successfully"}),
                200,
            )
        else:
            return (
                jsonify(
                    {
                        "success": False,
                        "message": "Failed to delete task or task not found",
                    }
                ),
                404,
            )

    except Exception as e:
        print(f"Delete task error: {e}")
        return jsonify({"success": False, "message": "Internal server error"}), 500


@app.route("/tasks/bulk-delete", methods=["DELETE"])
def delete_multiple_tasks():
    """Delete multiple tasks"""
    try:
        user_id = get_user_id_from_headers()
        if not user_id:
            return (
                jsonify({"success": False, "message": "User authentication required"}),
                401,
            )

        data = request.get_json()
        if not data or "taskIds" not in data or not data["taskIds"]:
            return jsonify({"success": False, "message": "Task IDs are required"}), 400

        task_ids = data["taskIds"]
        if not isinstance(task_ids, list):
            return (
                jsonify({"success": False, "message": "Task IDs must be an array"}),
                400,
            )

        deleted_count = data_handler.delete_multiple_tasks(task_ids, user_id)

        return (
            jsonify(
                {
                    "success": True,
                    "message": f"{deleted_count} tasks deleted successfully",
                    "deletedCount": deleted_count,
                }
            ),
            200,
        )

    except Exception as e:
        print(f"Delete multiple tasks error: {e}")
        return jsonify({"success": False, "message": "Internal server error"}), 500


@app.route("/tasks/<task_id>/complete", methods=["PUT"])
def toggle_task_completion(task_id):
    """Toggle task completion status"""
    try:
        user_id = get_user_id_from_headers()
        if not user_id:
            return (
                jsonify({"success": False, "message": "User authentication required"}),
                401,
            )

        data = request.get_json()

        if not data or "isCompleted" not in data:
            return (
                jsonify({"success": False, "message": "isCompleted field is required"}),
                400,
            )

        is_completed = data["isCompleted"]

        success = data_handler.mark_task_completed(task_id, user_id, is_completed)

        if success:
            return (
                jsonify(
                    {
                        "success": True,
                        "message": f"Task marked as {'completed' if is_completed else 'incomplete'}",
                    }
                ),
                200,
            )
        else:
            return (
                jsonify(
                    {
                        "success": False,
                        "message": "Failed to update task or task not found",
                    }
                ),
                404,
            )

    except Exception as e:
        print(f"Toggle task completion error: {e}")
        return jsonify({"success": False, "message": "Internal server error"}), 500


@app.route("/tasks/<task_id>/important", methods=["PUT"])
def toggle_task_importance(task_id):
    """Toggle task importance status"""
    try:
        user_id = get_user_id_from_headers()
        if not user_id:
            return (
                jsonify({"success": False, "message": "User authentication required"}),
                401,
            )

        data = request.get_json()

        if not data or "isImportant" not in data:
            return (
                jsonify({"success": False, "message": "isImportant field is required"}),
                400,
            )

        is_important = data["isImportant"]

        # Update the task's importance status
        success = data_handler.mark_task_important(task_id, user_id, is_important)

        if success:
            # Find the Important list ID
            task_lists = data_handler.get_task_lists(user_id)
            important_list_id = None
            for task_list in task_lists:
                if task_list.get("name") == "Important" and task_list.get("isDefault"):
                    important_list_id = task_list.get("_id")
                    break

            if important_list_id:
                if is_important:
                    # Add task to Important list
                    data_handler.add_task_to_list(task_id, user_id, important_list_id)
                else:
                    # Remove task from Important list (but keep in other lists)
                    data_handler.remove_task_from_list(
                        task_id, user_id, important_list_id
                    )

            return (
                jsonify(
                    {
                        "success": True,
                        "message": f"Task marked as {'important' if is_important else 'not important'}",
                    }
                ),
                200,
            )
        else:
            return (
                jsonify(
                    {
                        "success": False,
                        "message": "Failed to update task or task not found",
                    }
                ),
                404,
            )

    except Exception as e:
        print(f"Toggle task importance error: {e}")
        return jsonify({"success": False, "message": "Internal server error"}), 500


@app.route("/tasks/add-to-lists", methods=["POST"])
def add_tasks_to_lists():
    """Add multiple tasks to one or more lists"""
    try:
        user_id = get_user_id_from_headers()
        if not user_id:
            return (
                jsonify({"success": False, "message": "User authentication required"}),
                401,
            )

        data = request.get_json()
        if not data or "taskIds" not in data or "listIds" not in data:
            return (
                jsonify(
                    {"success": False, "message": "Task IDs and List IDs are required"}
                ),
                400,
            )

        task_ids = data["taskIds"]
        list_ids = data["listIds"]

        if not isinstance(task_ids, list) or not isinstance(list_ids, list):
            return (
                jsonify(
                    {
                        "success": False,
                        "message": "Task IDs and List IDs must be arrays",
                    }
                ),
                400,
            )

        success_count = 0
        for task_id in task_ids:
            for list_id in list_ids:
                if data_handler.add_task_to_list(task_id, user_id, list_id):
                    success_count += 1

        return (
            jsonify(
                {
                    "success": True,
                    "message": f"Successfully added tasks to lists",
                    "addedCount": success_count,
                }
            ),
            200,
        )

    except Exception as e:
        print(f"Add tasks to lists error: {e}")
        return jsonify({"success": False, "message": "Internal server error"}), 500


# ==================== TASK LIST ROUTES ====================


@app.route("/task-lists", methods=["POST"])
def create_task_list():
    """Create a new task list"""
    try:
        user_id = get_user_id_from_headers()
        if not user_id:
            return (
                jsonify({"success": False, "message": "User authentication required"}),
                401,
            )

        data = request.get_json()

        if not data or "name" not in data:
            return (
                jsonify({"success": False, "message": "Task list name is required"}),
                400,
            )

        # Create task list data with user_id
        list_data = {
            "name": data["name"],
            "user_id": user_id,
            "icon": data.get("icon", "list"),
            "iconColor": data.get("iconColor", 0xFF0078D4),
            "isDefault": data.get("isDefault", False),
        }

        list_id = data_handler.create_task_list(list_data)

        if list_id:
            return (
                jsonify(
                    {
                        "success": True,
                        "message": "Task list created successfully",
                        "listId": list_id,
                    }
                ),
                201,
            )
        else:
            return (
                jsonify({"success": False, "message": "Failed to create task list"}),
                500,
            )

    except Exception as e:
        print(f"Create task list error: {e}")
        return jsonify({"success": False, "message": "Internal server error"}), 500


@app.route("/task-lists/<list_id>", methods=["GET"])
def get_task_list(list_id):
    """Get a specific task list"""
    try:
        user_id = get_user_id_from_headers()
        if not user_id:
            return (
                jsonify({"success": False, "message": "User authentication required"}),
                401,
            )

        task_list = data_handler.get_task_list_by_id(list_id, user_id)

        if task_list:
            return (
                jsonify({"success": True, "taskList": task_list}),
                200,
            )
        else:
            return (
                jsonify({"success": False, "message": "Task list not found"}),
                404,
            )

    except Exception as e:
        print(f"Get task list error: {e}")
        return jsonify({"success": False, "message": "Internal server error"}), 500


@app.route("/task-lists", methods=["GET"])
def get_task_lists():
    """Get all task lists for the user"""
    try:
        user_id = get_user_id_from_headers()
        if not user_id:
            return (
                jsonify({"success": False, "message": "User authentication required"}),
                401,
            )

        default_only = request.args.get("defaultOnly", "false").lower() == "true"

        task_lists = data_handler.get_task_lists(user_id, default_only)

        return (
            jsonify({"success": True, "taskLists": task_lists}),
            200,
        )

    except Exception as e:
        print(f"Get task lists error: {e}")
        return jsonify({"success": False, "message": "Internal server error"}), 500


@app.route("/task-lists/<list_id>", methods=["PUT"])
def update_task_list(list_id):
    """Update a task list"""
    try:
        user_id = get_user_id_from_headers()
        if not user_id:
            return (
                jsonify({"success": False, "message": "User authentication required"}),
                401,
            )

        data = request.get_json()

        if not data:
            return jsonify({"success": False, "message": "No data provided"}), 400

        success = data_handler.update_task_list(list_id, user_id, data)

        if success:
            return (
                jsonify({"success": True, "message": "Task list updated successfully"}),
                200,
            )
        else:
            return (
                jsonify(
                    {
                        "success": False,
                        "message": "Failed to update task list or list not found",
                    }
                ),
                404,
            )

    except Exception as e:
        print(f"Update task list error: {e}")
        return jsonify({"success": False, "message": "Internal server error"}), 500


@app.route("/task-lists/<list_id>", methods=["DELETE"])
def delete_task_list(list_id):
    """Delete a task list and all its tasks"""
    try:
        user_id = get_user_id_from_headers()
        if not user_id:
            return (
                jsonify({"success": False, "message": "User authentication required"}),
                401,
            )

        success = data_handler.delete_task_list(list_id, user_id)

        if success:
            return (
                jsonify(
                    {
                        "success": True,
                        "message": "Task list and all its tasks deleted successfully",
                    }
                ),
                200,
            )
        else:
            return (
                jsonify(
                    {
                        "success": False,
                        "message": "Failed to delete task list, list not found, or cannot delete default list",
                    }
                ),
                400,
            )

    except Exception as e:
        print(f"Delete task list error: {e}")
        return jsonify({"success": False, "message": "Internal server error"}), 500


# ==================== UTILITY ROUTES ====================


@app.route("/tasks/important", methods=["GET"])
def get_important_tasks():
    """Get all important tasks for the user"""
    try:
        user_id = get_user_id_from_headers()
        if not user_id:
            return (
                jsonify({"success": False, "message": "User authentication required"}),
                401,
            )

        tasks = data_handler.get_important_tasks(user_id)

        return (
            jsonify({"success": True, "tasks": tasks}),
            200,
        )

    except Exception as e:
        print(f"Get important tasks error: {e}")
        return jsonify({"success": False, "message": "Internal server error"}), 500


@app.route("/tasks/completed", methods=["GET"])
def get_completed_tasks():
    """Get all completed tasks for the user"""
    try:
        user_id = get_user_id_from_headers()
        if not user_id:
            return (
                jsonify({"success": False, "message": "User authentication required"}),
                401,
            )

        tasks = data_handler.get_completed_tasks(user_id)

        return (
            jsonify({"success": True, "tasks": tasks}),
            200,
        )

    except Exception as e:
        print(f"Get completed tasks error: {e}")
        return jsonify({"success": False, "message": "Internal server error"}), 500


@app.route("/tasks/search", methods=["GET"])
def search_tasks():
    """Search tasks by title for the user"""
    try:
        user_id = get_user_id_from_headers()
        if not user_id:
            return (
                jsonify({"success": False, "message": "User authentication required"}),
                401,
            )

        search_term = request.args.get("q")

        if not search_term:
            return (
                jsonify({"success": False, "message": "Search term is required"}),
                400,
            )

        tasks = data_handler.search_tasks(user_id, search_term)

        return (
            jsonify({"success": True, "tasks": tasks}),
            200,
        )

    except Exception as e:
        print(f"Search tasks error: {e}")
        return jsonify({"success": False, "message": "Internal server error"}), 500


@app.route("/task-lists/<list_id>/stats", methods=["GET"])
def get_list_stats(list_id):
    """Get statistics for a specific task list"""
    try:
        user_id = get_user_id_from_headers()
        if not user_id:
            return (
                jsonify({"success": False, "message": "User authentication required"}),
                401,
            )

        stats = data_handler.get_list_stats(list_id, user_id)

        if stats is not None:
            return (
                jsonify({"success": True, "stats": stats}),
                200,
            )
        else:
            return (
                jsonify({"success": False, "message": "Task list not found"}),
                404,
            )

    except Exception as e:
        print(f"Get list stats error: {e}")
        return jsonify({"success": False, "message": "Internal server error"}), 500


if __name__ == "__main__":
    app.run(debug=True)
