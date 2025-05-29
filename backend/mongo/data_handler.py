import os
from pymongo import MongoClient
from typing import List, Optional, Dict, Any
from .models import Task, TaskList, User
from dotenv import load_dotenv
from datetime import datetime
from bson import ObjectId

load_dotenv()


class DataHandler:
    def __init__(
        self,
        connection_string: str = os.getenv("MONGO_URL"),
        database_name: str = os.getenv("DATABASE_NAME"),
    ):
        print(connection_string)
        self.client = MongoClient(connection_string)
        print(self.client)
        self.db = self.client[database_name]

        # Initialize model classes
        self.user_model = User(self.db)
        self.task_model = Task(self.db)
        self.task_list_model = TaskList(self.db)

    def close_connection(self):
        self.client.close()

    # ==================== USER OPERATIONS ====================

    def create_user(self, email: str, password: str) -> Optional[str]:
        """Create a new user and return user ID"""
        try:
            user_id = self.user_model.create_user(email, password)
            if user_id:
                # Create default lists for the user
                self.task_list_model.create_default_lists(user_id)
                return user_id
            return None
        except Exception as e:
            print(f"Error creating user: {e}")
            return None

    def authenticate_user(self, email: str, password: str) -> Optional[str]:
        """Authenticate user and return user ID if successful"""
        try:
            return self.user_model.authenticate_user(email, password)
        except Exception as e:
            print(f"Error authenticating user: {e}")
            return None

    def get_user_by_id(self, user_id: str) -> Optional[Dict]:
        """Get user by ID"""
        try:
            return self.user_model.get_user_by_id(user_id)
        except Exception as e:
            print(f"Error getting user: {e}")
            return None

    # ==================== TASK OPERATIONS ====================

    def create_task(self, task_data: Dict[str, Any]) -> Optional[str]:
        """Create a new task and return its ID"""
        try:
            return self.task_model.create_task(task_data)
        except Exception as e:
            print(f"Error creating task: {e}")
            return None

    def get_tasks(self, user_id: str, list_id: Optional[str] = None) -> List[Dict]:
        """Get all tasks for a user, optionally filtered by list_id"""
        try:
            return self.task_model.get_tasks(user_id, list_id)
        except Exception as e:
            print(f"Error getting tasks: {e}")
            return []

    def get_task_by_id(self, task_id: str, user_id: str) -> Optional[Dict]:
        """Get a specific task by ID, ensuring it belongs to the user"""
        try:
            return self.task_model.get_task_by_id(task_id, user_id)
        except Exception as e:
            print(f"Error getting task: {e}")
            return None

    def update_task(self, task_id: str, user_id: str, updates: Dict[str, Any]) -> bool:
        """Update a task, ensuring it belongs to the user"""
        try:
            # Convert datetime fields if needed
            if "dueDate" in updates and updates["dueDate"]:
                updates["dueDate"] = datetime.fromisoformat(
                    updates["dueDate"].replace("Z", "+00:00")
                )
            return self.task_model.update_task(task_id, user_id, updates)
        except Exception as e:
            print(f"Error updating task: {e}")
            return False

    def delete_task(self, task_id: str, user_id: str) -> bool:
        """Delete a task, ensuring it belongs to the user"""
        try:
            return self.task_model.delete_task(task_id, user_id)
        except Exception as e:
            print(f"Error deleting task: {e}")
            return False

    def mark_task_completed(
        self, task_id: str, user_id: str, is_completed: bool = True
    ) -> bool:
        """Mark a task as completed or uncompleted"""
        return self.task_model.update_task(
            task_id, user_id, {"isCompleted": is_completed}
        )

    def mark_task_important(
        self, task_id: str, user_id: str, is_important: bool = True
    ) -> bool:
        """Mark a task as important or not important"""
        return self.task_model.update_task(
            task_id, user_id, {"isImportant": is_important}
        )

    # ==================== TASK LIST OPERATIONS ====================

    def create_task_list(self, task_list_data: Dict[str, Any]) -> Optional[str]:
        """Create a new task list and return its ID"""
        try:
            return self.task_list_model.create_task_list(task_list_data)
        except Exception as e:
            print(f"Error creating task list: {e}")
            return None

    def get_task_lists(self, user_id: str, default_only: bool = False) -> List[Dict]:
        """Get all task lists for a user"""
        try:
            return self.task_list_model.get_task_lists(user_id, default_only)
        except Exception as e:
            print(f"Error getting task lists: {e}")
            return []

    def get_task_list_by_id(self, list_id: str, user_id: str) -> Optional[Dict]:
        """Get a specific task list by ID, ensuring it belongs to the user"""
        try:
            return self.task_list_model.get_task_list_by_id(list_id, user_id)
        except Exception as e:
            print(f"Error getting task list: {e}")
            return None

    def update_task_list(
        self, list_id: str, user_id: str, updates: Dict[str, Any]
    ) -> bool:
        """Update a task list, ensuring it belongs to the user"""
        try:
            return self.task_list_model.update_task_list(list_id, user_id, updates)
        except Exception as e:
            print(f"Error updating task list: {e}")
            return False

    def delete_task_list(self, list_id: str, user_id: str) -> bool:
        """Delete a task list and all its tasks, ensuring it belongs to the user"""
        try:
            # Check if it's a default list (cannot be deleted)
            task_list = self.get_task_list_by_id(list_id, user_id)
            if task_list and task_list.get("isDefault", False):
                return False

            # Delete the task list
            success = self.task_list_model.delete_task_list(list_id, user_id)
            if success:
                # Delete all tasks in this list
                self.task_model.delete_tasks_by_list(list_id, user_id)
            return success
        except Exception as e:
            print(f"Error deleting task list: {e}")
            return False

    # ==================== UTILITY OPERATIONS ====================

    def get_important_tasks(self, user_id: str) -> List[Dict]:
        """Get all important tasks for a user"""
        try:
            return self.task_model.get_important_tasks(user_id)
        except Exception as e:
            print(f"Error getting important tasks: {e}")
            return []

    def get_completed_tasks(self, user_id: str) -> List[Dict]:
        """Get all completed tasks for a user"""
        try:
            return self.task_model.get_completed_tasks(user_id)
        except Exception as e:
            print(f"Error getting completed tasks: {e}")
            return []

    def search_tasks(self, user_id: str, search_term: str) -> List[Dict]:
        """Search tasks by title for a user"""
        try:
            return self.task_model.search_tasks(user_id, search_term)
        except Exception as e:
            print(f"Error searching tasks: {e}")
            return []

    def get_list_stats(self, list_id: str, user_id: str) -> Optional[Dict[str, int]]:
        """Get statistics for a specific list"""
        try:
            tasks = self.get_tasks(user_id, list_id)
            total_tasks = len(tasks)
            completed_tasks = len(
                [task for task in tasks if task.get("isCompleted", False)]
            )
            pending_tasks = total_tasks - completed_tasks

            return {
                "totalTasks": total_tasks,
                "completedTasks": completed_tasks,
                "pendingTasks": pending_tasks,
            }
        except Exception as e:
            print(f"Error getting list stats: {e}")
            return None
