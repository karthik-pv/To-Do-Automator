from datetime import datetime
from typing import Optional
from bson import ObjectId
import bcrypt
from pymongo import MongoClient


class User:
    def __init__(self, db):
        self.collection = db.users
        # Create unique index on email
        self.collection.create_index("email", unique=True)

    def create_user(self, email, password, name=None):
        """Create a new user with hashed password"""
        try:
            # Hash the password
            hashed_password = bcrypt.hashpw(password.encode("utf-8"), bcrypt.gensalt())

            user_data = {
                "email": email.lower().strip(),
                "password": hashed_password,
                "name": name or email.split("@")[0],
                "created_at": datetime.utcnow(),
                "updated_at": datetime.utcnow(),
            }

            result = self.collection.insert_one(user_data)
            return str(result.inserted_id)
        except Exception as e:
            print(f"Error creating user: {e}")
            return None

    def authenticate_user(self, email, password):
        """Authenticate user with email and password"""
        try:
            user = self.collection.find_one({"email": email.lower().strip()})
            if user and bcrypt.checkpw(password.encode("utf-8"), user["password"]):
                return str(user["_id"])
            return None
        except Exception as e:
            print(f"Error authenticating user: {e}")
            return None

    def get_user_by_id(self, user_id):
        """Get user by ID"""
        try:
            user = self.collection.find_one({"_id": ObjectId(user_id)})
            if user:
                user["_id"] = str(user["_id"])
                # Remove password from response
                user.pop("password", None)
                return user
            return None
        except Exception as e:
            print(f"Error getting user: {e}")
            return None

    def get_user_by_email(self, email):
        """Get user by email (without password)"""
        try:
            user = self.collection.find_one({"email": email.lower().strip()})
            if user:
                user["_id"] = str(user["_id"])
                user.pop("password", None)
                return user
            return None
        except Exception as e:
            print(f"Error getting user by email: {e}")
            return None


class Task:
    def __init__(self, db):
        self.collection = db.tasks
        # Create indexes for better performance
        self.collection.create_index("user_id")
        self.collection.create_index("list_id")

    def create_task(self, task_data):
        """Create a new task with user_id"""
        try:
            task_data["created_at"] = datetime.utcnow()
            task_data["updated_at"] = datetime.utcnow()

            # Ensure required fields
            if "isCompleted" not in task_data:
                task_data["isCompleted"] = False
            if "isImportant" not in task_data:
                task_data["isImportant"] = False

            # Handle list_ids as array - ensure it's always an array
            if "list_id" in task_data:
                # Convert single list_id to array for backward compatibility
                task_data["list_ids"] = [task_data["list_id"]]
                del task_data["list_id"]
            elif "list_ids" not in task_data:
                # Default to 'my-tasks' if no list specified
                task_data["list_ids"] = ["my-tasks"]
            elif not isinstance(task_data["list_ids"], list):
                # Ensure list_ids is always an array
                task_data["list_ids"] = [task_data["list_ids"]]

            result = self.collection.insert_one(task_data)
            return str(result.inserted_id)
        except Exception as e:
            print(f"Error creating task: {e}")
            return None

    def get_tasks(self, user_id, list_id=None):
        """Get tasks for a user, optionally filtered by list_id"""
        try:
            query = {"user_id": user_id}
            if list_id:
                # Check if list_id is in the list_ids array
                query["list_ids"] = {"$in": [list_id]}

            tasks = list(self.collection.find(query))
            for task in tasks:
                task["_id"] = str(task["_id"])
                # Ensure backward compatibility - add list_id field from first list_ids entry
                if "list_ids" in task and task["list_ids"]:
                    task["list_id"] = task["list_ids"][0]
                elif "list_id" not in task:
                    task["list_id"] = "my-tasks"
                    task["list_ids"] = ["my-tasks"]
            return tasks
        except Exception as e:
            print(f"Error getting tasks: {e}")
            return []

    def get_task_by_id(self, task_id, user_id):
        """Get a specific task by ID and user_id"""
        try:
            task = self.collection.find_one(
                {"_id": ObjectId(task_id), "user_id": user_id}
            )
            if task:
                task["_id"] = str(task["_id"])
                # Ensure backward compatibility
                if "list_ids" in task and task["list_ids"]:
                    task["list_id"] = task["list_ids"][0]
                elif "list_id" not in task:
                    task["list_id"] = "my-tasks"
                    task["list_ids"] = ["my-tasks"]
                return task
            return None
        except Exception as e:
            print(f"Error getting task: {e}")
            return None

    def update_task(self, task_id, user_id, update_data):
        """Update a task"""
        try:
            update_data["updated_at"] = datetime.utcnow()

            # Handle list_ids updates
            if "list_id" in update_data:
                # Convert single list_id to array for backward compatibility
                if "list_ids" not in update_data:
                    update_data["list_ids"] = [update_data["list_id"]]
                del update_data["list_id"]
            elif "list_ids" in update_data and not isinstance(
                update_data["list_ids"], list
            ):
                # Ensure list_ids is always an array
                update_data["list_ids"] = [update_data["list_ids"]]

            result = self.collection.update_one(
                {"_id": ObjectId(task_id), "user_id": user_id}, {"$set": update_data}
            )
            return result.modified_count > 0
        except Exception as e:
            print(f"Error updating task: {e}")
            return False

    def delete_task(self, task_id, user_id):
        """Delete a task"""
        try:
            result = self.collection.delete_one(
                {"_id": ObjectId(task_id), "user_id": user_id}
            )
            return result.deleted_count > 0
        except Exception as e:
            print(f"Error deleting task: {e}")
            return False

    def delete_multiple_tasks(self, task_ids, user_id):
        """Delete multiple tasks"""
        try:
            object_ids = [ObjectId(task_id) for task_id in task_ids]
            result = self.collection.delete_many(
                {"_id": {"$in": object_ids}, "user_id": user_id}
            )
            return result.deleted_count
        except Exception as e:
            print(f"Error deleting multiple tasks: {e}")
            return 0

    def add_task_to_list(self, task_id, user_id, list_id):
        """Add a task to an additional list"""
        try:
            result = self.collection.update_one(
                {"_id": ObjectId(task_id), "user_id": user_id},
                {"$addToSet": {"list_ids": list_id}},
            )
            return result.modified_count > 0
        except Exception as e:
            print(f"Error adding task to list: {e}")
            return False

    def remove_task_from_list(self, task_id, user_id, list_id):
        """Remove a task from a specific list (but keep in other lists)"""
        try:
            # Get the task first to check current list_ids
            task = self.get_task_by_id(task_id, user_id)
            if not task:
                return False

            current_list_ids = task.get("list_ids", [])
            if len(current_list_ids) <= 1:
                # Don't remove if it's the only list - would orphan the task
                return False

            result = self.collection.update_one(
                {"_id": ObjectId(task_id), "user_id": user_id},
                {"$pull": {"list_ids": list_id}},
            )
            return result.modified_count > 0
        except Exception as e:
            print(f"Error removing task from list: {e}")
            return False

    def get_important_tasks(self, user_id):
        """Get all important tasks for a user"""
        try:
            tasks = list(
                self.collection.find({"user_id": user_id, "isImportant": True})
            )
            for task in tasks:
                task["_id"] = str(task["_id"])
            return tasks
        except Exception as e:
            print(f"Error getting important tasks: {e}")
            return []

    def get_completed_tasks(self, user_id):
        """Get all completed tasks for a user"""
        try:
            tasks = list(
                self.collection.find({"user_id": user_id, "isCompleted": True})
            )
            for task in tasks:
                task["_id"] = str(task["_id"])
            return tasks
        except Exception as e:
            print(f"Error getting completed tasks: {e}")
            return []

    def search_tasks(self, user_id, search_term):
        """Search tasks by title for a user"""
        try:
            tasks = list(
                self.collection.find(
                    {
                        "user_id": user_id,
                        "title": {"$regex": search_term, "$options": "i"},
                    }
                )
            )
            for task in tasks:
                task["_id"] = str(task["_id"])
            return tasks
        except Exception as e:
            print(f"Error searching tasks: {e}")
            return []

    def delete_tasks_by_list(self, list_id, user_id):
        """Delete all tasks in a specific list for a user"""
        try:
            result = self.collection.delete_many(
                {"list_id": list_id, "user_id": user_id}
            )
            return result.deleted_count
        except Exception as e:
            print(f"Error deleting tasks by list: {e}")
            return 0


class TaskList:
    def __init__(self, db):
        self.collection = db.task_lists
        # Create index for better performance
        self.collection.create_index("user_id")

    def create_task_list(self, list_data):
        """Create a new task list with user_id"""
        try:
            list_data["created_at"] = datetime.utcnow()
            list_data["updated_at"] = datetime.utcnow()

            # Ensure isDefault is set
            if "isDefault" not in list_data:
                list_data["isDefault"] = False

            result = self.collection.insert_one(list_data)
            return str(result.inserted_id)
        except Exception as e:
            print(f"Error creating task list: {e}")
            return None

    def get_task_lists(self, user_id, default_only=False):
        """Get task lists for a user"""
        try:
            query = {"user_id": user_id}
            if default_only:
                query["isDefault"] = True

            lists = list(self.collection.find(query))
            for task_list in lists:
                task_list["_id"] = str(task_list["_id"])
            return lists
        except Exception as e:
            print(f"Error getting task lists: {e}")
            return []

    def get_task_list_by_id(self, list_id, user_id):
        """Get a specific task list by ID and user_id"""
        try:
            task_list = self.collection.find_one(
                {"_id": ObjectId(list_id), "user_id": user_id}
            )
            if task_list:
                task_list["_id"] = str(task_list["_id"])
                return task_list
            return None
        except Exception as e:
            print(f"Error getting task list: {e}")
            return None

    def update_task_list(self, list_id, user_id, update_data):
        """Update a task list"""
        try:
            update_data["updated_at"] = datetime.utcnow()
            result = self.collection.update_one(
                {"_id": ObjectId(list_id), "user_id": user_id}, {"$set": update_data}
            )
            return result.modified_count > 0
        except Exception as e:
            print(f"Error updating task list: {e}")
            return False

    def delete_task_list(self, list_id, user_id):
        """Delete a task list (only if not default)"""
        try:
            # First check if it's a default list
            task_list = self.get_task_list_by_id(list_id, user_id)
            if task_list and task_list.get("isDefault", False):
                return False  # Cannot delete default lists

            result = self.collection.delete_one(
                {
                    "_id": ObjectId(list_id),
                    "user_id": user_id,
                    "isDefault": {"$ne": True},  # Extra safety check
                }
            )
            return result.deleted_count > 0
        except Exception as e:
            print(f"Error deleting task list: {e}")
            return False

    def create_default_lists(self, user_id):
        """Create default lists for a new user"""
        try:
            default_lists = [
                {
                    "name": "My Day",
                    "icon": "wb_sunny_outlined",
                    "iconColor": 0xFFFFB900,
                    "isDefault": True,
                    "user_id": user_id,
                },
                {
                    "name": "Important",
                    "icon": "star_border",
                    "iconColor": 0xFFD13438,
                    "isDefault": True,
                    "user_id": user_id,
                },
                {
                    "name": "Tasks",
                    "icon": "home_outlined",
                    "iconColor": 0xFF0078D4,
                    "isDefault": True,
                    "user_id": user_id,
                },
            ]

            created_ids = []
            for list_data in default_lists:
                list_id = self.create_task_list(list_data)
                if list_id:
                    created_ids.append(list_id)

            return created_ids
        except Exception as e:
            print(f"Error creating default lists: {e}")
            return []
