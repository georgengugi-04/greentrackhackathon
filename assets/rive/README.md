# Rive animation assets

Drop `.riv` files here (e.g. `chef.riv`, `farmer.riv`, `loading.riv`) and
reference them by filename in `RiveCharacter` — see
lib/features/shared/widgets/rive_character.dart.

Where to get .riv files:
- Design your own at https://rive.app (free tier available) — this is
  where you'd build the interactive chef/farmer characters described in
  the motion concept doc (idle/loading/success states as named animations
  or a state machine).
- Browse Rive's community for free starter characters/animations:
  https://rive.app/community

Nothing in this folder is required for the app to build — RiveCharacter
falls back to a plain placeholder if a file isn't found here yet.
