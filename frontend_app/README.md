# Microsoft To-Do Clone - Flutter App

A beautiful Flutter application that closely mimics Microsoft To-Do's design and functionality.

## Features

### Authentication

- User registration and login
- Secure local storage of user credentials
- Automatic login persistence

### Task Lists

- Create, edit, and delete custom task lists
- Default lists ("Tasks" and "My Day") that cannot be deleted
- Colorful icons and customizable themes
- Grid-based layout similar to Microsoft To-Do

### Tasks

- Create, edit, and delete tasks within any list
- Mark tasks as completed/incomplete
- Mark tasks as important with star indicator
- Add notes to tasks
- Set due dates with intelligent date formatting
- Quick task creation with inline text input

### User Interface

- Microsoft To-Do inspired color palette
- Clean, modern Material Design
- Responsive layout for different screen sizes
- Smooth animations and transitions
- Intuitive touch interactions

## Setup Instructions

### Prerequisites

- Flutter SDK installed
- Android Studio or VS Code with Flutter extension
- A running backend server (see backend requirements)

### Backend Configuration

1. Make sure your backend server is running on `http://localhost:5000`
2. If your server is on a different URL, update the `baseUrl` in `lib/services/api_service.dart`

### Installation

1. Navigate to the frontend_app directory:

   ```bash
   cd frontend_app
   ```

2. Install dependencies:

   ```bash
   flutter pub get
   ```

3. Run the app:
   ```bash
   flutter run
   ```

## Usage

### First Time Setup

1. Launch the app
2. Create a new account or sign in with existing credentials
3. After login, you'll see the home screen with default lists

### Managing Lists

- Tap the "+" button to create a new list
- Choose an icon and color for your list
- Tap on any list tile to view its tasks
- Long press or use the menu to delete non-default lists

### Managing Tasks

- In any list, use the text input at the top to quickly add tasks
- Tap on a task to view/edit its details
- Use the checkbox to mark tasks as complete
- Tap the star icon to mark tasks as important
- Use the menu (⋮) for additional options

### Task Details

- Edit task title and notes
- Set or modify due dates
- Toggle importance status
- Mark as complete/incomplete
- Delete the task

## Default Lists

The app comes with two default lists that cannot be deleted:

1. **Tasks** - General purpose task list (listId: "my-tasks")
2. **My Day** - Daily planning list (listId: "my-day")

Additional lists can be created as needed.

## Backend Integration

This app integrates with a Python Flask backend that provides:

- User authentication (register/login)
- Task list management (CRUD operations)
- Task management (CRUD operations)
- Data persistence with MongoDB

Ensure your backend is running and accessible before using the app.

## Color Scheme

The app uses Microsoft To-Do's signature color palette:

- Primary Blue: #0078D4
- Background Gray: #F3F2F1
- Text Dark: #323130
- Text Light: #605E5C
- Important Red: #D83B01
- Completed Green: #107C10

## Architecture

```
lib/
├── models/          # Data models (Task, TaskList, User)
├── services/        # API service for backend communication
├── screens/         # Main app screens
├── widgets/         # Reusable UI components
├── theme/           # App theme and styling
└── main.dart        # App entry point
```

## Contributing

Feel free to submit issues and enhancement requests!
