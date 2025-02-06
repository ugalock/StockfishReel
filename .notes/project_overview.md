## Project Overview
### Mission statement
We are building a mobile application that is a simplified TikTok clone called StockfishReel and our content creators are all chess streamers that would like to upload videos of their games.

### Tech stack
- Flutter
- Firebase Auth
- Firebase Storage
- Firestore Database
- Firebase Functions
- Firebase Analytics

NEVER CHANGE EXISTING PACKAGES WITHOUT ASKING FIRST.

### File structure
Full file structure can be found in the `file_structure.md` file, and any time we are creating something new we should refer to the file structure to see if a named file has already been sketched out. Any changes to the file structure should be reflected in the `file_structure.md` file with similar formatting and level of detail in terms of comments.

### Database design
Full schema can be found in the `schema.md` file, and any time we need to interact with the database, we should refer to the schema. Any changes to the schema should be reflected in the `schema.md` file.

### Features
Basic TikTok functionalities of like, comment, follow, and search, along with these specific user stories for creators:
1. Categorize and tag videos of games by chess opening
2. Add game metadata to videos like ELO, opponent ELO, site, date, result, etc.
3. Add time stamps to videos for opening, middle game, and end game.
4. Add animations to the videos to indicate move classifications
5. Add a side panel that shows all moves and annotations
6. Make an exportable PGN of the game