1. Video Creation Flow
The creation flow needs to accommodate both a regular short-form video (if the user doesn't have a PGN) **and** a chess game video with PGN integration.

1.1 Step 1: Record or Upload Video
**Screen:** `VideoCaptureScreen` (if recording directly)
* **Top Bar/Action**: Close icon (back).
* **Main Area**: Camera preview.
* **Bottom Bar**: Record button, flip camera, or pick from gallery.

**Screen:** `VideoReviewScreen` (after capturing/uploading)
* Shows a preview of the recorded/uploaded video.
* "Next" button to move forward.

1.2 Step 2: Add (Optional) PGN File
**Screen:** `AddPGNScreen`
* **Header**: "Attach your chess game PGN?"
* **Description**: "Upload a PGN file to show chess moves, highlight openings, and add timestamps for middle/endgame phases."
* **Widget**:
   * Button to "Upload PGN File" (from device or from cloud).
   * Alternatively, let the user skip if they don't have one.
* If a PGN is uploaded successfully:
   * Parse the PGN to extract moves, detect the opening (ECO code), and display a short summary (e.g., "Sicilian Defense, Najdorf Variation").
   * Show a **Chess Move List** in a scrollable list (like a timeline).

1.3 Step 3: Opening Tag & Game Phase Timestamps
**Screen:** `GameDetailsScreen` (if PGN attached)
* **Opening Tag**
   * If an opening is automatically detected, show it.
   * If not, allow searching or selecting from a drop-down of ECO codes or typical openings.
* **Video + Move Timeline**
   * A combined timeline view that allows the user to:
      1. **Set Middle Game Timestamp**
         * A slider or input field to specify at which second the middle game starts.
      2. **Set End Game Timestamp**
         * Similarly, specify the time for the end game.
      3. Optionally, show a small video scrubber + move list so the user can align critical moves or phases with the video times.
   * **Design Idea**: A horizontally scrollable timeline below the video thumbnail or a "video scrub + PGN moves" sync.
      * E.g., each move in PGN is listed. The user can tap a move -> the video timeline jumps to a recommended time or the user manually sets it.

1.4 Step 4: Mark Special Moves (Brilliant, Good, Inaccuracy, Blunder, etc.)
**Screen:** `MoveAnnotationsScreen`
* **Chess Moves List**: List each move in the game.
* **Tagging UI**: For each move, show a dropdown or small buttons to mark if it's "Brilliant," "Good," "Inaccuracy," "Mistake," "Blunder," etc.
   * Alternatively, you can integrate a lightweight chess engine in the backend or a cloud function to annotate automatically, then let the user approve or override.
* **Preview Animation**:
   * For each special move, you can assign an animation type or icon (sparkles for brilliant, caution sign for inaccuracy, etc.).

1.5 Step 5: Post Metadata and Preview
**Screen:** `PostDetailsScreen`
* **Caption Input**: For the short video text (like TikTok).
* **Hashtags/Tags**: Could be #chess, #openingName, #ECOCode, etc.
* **Privacy Settings**: Public or private.
* **Preview**: Show a short preview of the final video with optional overlays:
   * If the user wants to see how the move annotations will appear in the final content, show a short demonstration (like a small sparkle on the timeline when a "Brilliant" move occurs). Alternatively, the move annotations might appear in a dedicated "detail" screen after posting.
* **Post**: Upload to Firebase Storage, store metadata (PGN, timestamps, etc.) in Firestore/Realtime DB, and call a Cloud Function if needed for further processing (like generating a chess overlay on the server side).