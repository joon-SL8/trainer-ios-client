# Session Recording and Strava Upload Architecture

This document provides an overview of how the application records session data and orchestrates the upload of that data to the Strava service.

## Architectural Overview

The application follows a clean architectural approach, separating the presentation of data (View/ViewModel), the business logic/coordination (Service Layer), and the underlying data management/fitness logic (SDK Layer).

## Key Components

### 1. Presentation Layer
- **`SessionViewModel`**: Manages live session state, triggers metrics recording, and handles the user's intent to upload a session in real-time.
- **`CalendarDetailViewModel`**: Allows users to view past sessions and triggers the upload process for completed sessions.

### 2. Service Layer
- **`SessionUploadService`**: The centralized coordinator for the upload process. It orchestrates fetching session data, packing it into a format suitable for fit-file creation, and initiating the publication to Strava.
- **`SessionUseCases`**: A wrapper layer that simplifies interactions with the `libfitness` SDK by exposing clean, async-ready methods for fetching entries, packing data, and publishing activities.

### 3. SDK Layer (`libfitness`)
- **`libfitness`**: The core fitness SDK that handles database management, raw fit-file generation/parsing, and communication with external fitness services like Strava.

## Operational Relationships

The interaction between these components is described in the Mermaid diagram located in `docs/session_strava_upload_architecture.mmd`. 

### Flows

1.  **Recording Flow**: As a user pedals, `SessionViewModel` periodically triggers `recordMetrics()`, which uses `UpdateSessionEntryUseCase` to persist raw data to the local database via `libfitness`.
2.  **Upload Flow**:
    - The ViewModel calls `SessionUploadService.uploadSession(...)`.
    - The Service fetches entries, packs them, and publishes the activity using the `SessionUseCases`.
    - `libfitness` handles the conversion to fit file format and the final submission to the Strava API.
