# Run from the project root (the folder that contains lib/) AFTER copying this overlay in.
# Removes the old prototype files that conflict with the rebuilt app.
# Kept on purpose: lib/core/app_theme.dart (the old admin pages still import it).
Remove-Item -Force  lib\app.dart               -ErrorAction SilentlyContinue
Remove-Item -Recurse -Force lib\pages          -ErrorAction SilentlyContinue
Remove-Item -Force  lib\widgets\common_widgets.dart -ErrorAction SilentlyContinue
Write-Host "Old prototype files removed."
