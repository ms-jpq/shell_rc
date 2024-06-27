# macOS

## Disable language switcher popup

```bash
defaults write kCFPreferencesAnyApplication TSMLanguageIndicatorEnabled 0
```

## Enable Key Repeat

```bash
defaults write -g ApplePressAndHoldEnabled -bool false
```

## Enable window dragging via `ctrl` + `cmd`

```bash
defaults write -g NSWindowShouldDragOnGesture YES
```
