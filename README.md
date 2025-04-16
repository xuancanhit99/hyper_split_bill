# Hyper Split Bill

Hyper Split Bill is a Flutter application designed to simplify the process of splitting shared bills. Users can upload an image of a bill, have the app automatically extract items and prices using OCR and AI, edit the details, assign items to participants, and calculate individual shares.

## Features

*   **User Authentication:** Secure login and registration (likely using Supabase Auth).
*   **Bill Upload:** Upload bill images from the device gallery or camera.
*   **Image Cropping:** Crop the uploaded image to focus on the relevant bill area.
*   **OCR Processing:** Extract text data from the bill image using an Optical Character Recognition service.
*   **AI-Powered Structuring:** Automatically structure the extracted text into bill items, prices, and potentially identify participants using an AI/LLM service.
*   **Bill Editing:** Manually add, edit, or delete bill items, participants, and general bill information (e.g., title, date, currency).
*   **Participant Assignment:** Assign specific items to different participants involved in the bill.
*   **Splitting Calculation:** Automatically calculate the amount each participant owes.
*   **Bill History:** (Assumed) View and manage previously processed bills.
*   **Chatbot Interaction:** (Potential) Interact with a chatbot for assistance or refining structured data.

## Tech Stack

*   **Framework:** Flutter
*   **Architecture:** Clean Architecture (Data, Domain, Presentation)
*   **State Management:** Bloc / flutter_bloc
*   **Dependency Injection:** get_it / injectable
*   **Routing:** go_router
*   **Backend:** Supabase (Auth, Database)
*   **External Services:**
    *   OCR Service API (Specific service not identified)
    *   AI/LLM Service API (Specific service not identified, potentially for structuring data via chat interface)
*   **Image Handling:** image_picker, image_cropper (or similar)

## Architecture Overview

The application follows the principles of Clean Architecture, separating concerns into three main layers:

1.  **Presentation:** Contains UI (Widgets, Pages) and State Management (Blocs). Handles user interaction and displays data.
2.  **Domain:** Contains business logic (Use Cases) and core entities. Defines the application's core functionality independent of UI or data sources.
3.  **Data:** Contains Repositories implementations and Data Sources (Remote - APIs, Supabase; Local - potentially cache). Handles data retrieval and storage.

Dependency Injection is managed using `get_it` and `injectable` for decoupling and easier testing. Navigation is handled by `go_router`.

## Getting Started

**Prerequisites:**

*   Flutter SDK installed (check `pubspec.yaml` for version constraints)
*   Dart SDK installed
*   An editor like VS Code or Android Studio
*   Supabase account and project setup
*   API keys for the OCR and AI/LLM services used

**Installation & Setup:**

1.  **Clone the repository:**
    ```bash
    git clone <repository-url>
    cd hyper_split_bill
    ```
2.  **Set up environment variables:**
    *   Copy the `.env.example` file to `.env`:
        ```bash
        cp .env.example .env
        ```
    *   Fill in the required values in the `.env` file, including:
        *   Supabase URL and Anon Key
        *   API Keys for OCR and AI services

3.  **Install dependencies:**
    ```bash
    flutter pub get
    ```
4.  **Generate dependency injection code:**
    ```bash
    dart run build_runner build --delete-conflicting-outputs
    ```

**Running the App:**

*   **Web:**
    ```bash
    flutter run -d chrome
    ```
*   **Mobile (Android/iOS):**
    *   Ensure you have a connected device or running emulator/simulator.
    *   ```bash
        flutter run
        ```

## Project Structure (`lib` folder)

```
lib/
├── app.dart                  # Main application widget setup (MaterialApp, Router)
├── injection_container.dart  # Dependency injection setup (GetIt)
├── injection_module.dart     # Modules for injectable
├── main.dart                 # Application entry point
├── common/                   # Widgets/Utilities shared across features
├── core/                     # Core functionalities (config, constants, error handling, routing, theme)
│   ├── config/
│   ├── constants/
│   ├── error/
│   ├── router/
│   └── theme/
└── features/                 # Feature modules (following Clean Architecture)
    ├── auth/                 # Authentication feature
    │   ├── data/
    │   ├── domain/
    │   └── presentation/
    └── bill_splitting/       # Bill splitting feature
        ├── data/             # Data sources, models, repository impl
        ├── domain/           # Entities, use cases, repository interface
        └── presentation/     # Blocs, pages, widgets
