# Theme Audit

## Palette Overview
| Token | Light | Dark | Notes |
| --- | --- | --- | --- |
| Seed | `#4C6B88` | `#4C6B88` | Material 3 seed color used to derive scheme. |
| Surface | `#F6F7F9` | `#121417` | Primary scaffold/background surface. |
| Surface Variant | `#E6E9EE` | `#1F242B` | Cards, containers, and subtle backgrounds. |
| On Surface Variant | `#3B4552` | Derived | Secondary text color for readability. |
| Hint Color | `#4B5664` | Derived | Helper text and low-emphasis copy. |

## Contrast & Accessibility Notes
- Text is rendered with Material 3 color roles, ensuring the system-generated `onSurface`/`onPrimary` pairs meet WCAG 2.1 AA contrast ratios.
- Surfaces use muted light/dark tones to prevent glare while keeping cards distinguishable.
- Buttons follow Material 3 defaults, producing accessible contrast for labels on primary backgrounds.

## Extension Guidance
- When introducing new semantic colors (success, warning, info), ensure the `on*` color meets a minimum contrast ratio of 4.5:1 against its background.
- Use `surfaceVariant` or `secondaryContainer` for large panels to maintain hierarchy without sacrificing contrast.
- Avoid pure white (`#FFFFFF`) in dark mode; instead, use tinted white (e.g., `#F5F7FA`) for glow accents.
