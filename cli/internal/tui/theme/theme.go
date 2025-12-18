package theme

import "github.com/charmbracelet/lipgloss"

// CharmTone-inspired color palette
// Based on Charmbracelet's design system

// Background tones (dark to light)
var (
	Pepper   = lipgloss.Color("#1a1a1a") // Darkest bg
	Charcoal = lipgloss.Color("#242424") // Base bg
	Iron     = lipgloss.Color("#2e2e2e") // Elevated bg
	Smoke    = lipgloss.Color("#383838") // Selection bg
	Oyster   = lipgloss.Color("#424242") // Hover bg
)

// Text tones (light to dark)
var (
	Salt  = lipgloss.Color("#e8e8e8") // Primary text
	Ash   = lipgloss.Color("#a0a0a0") // Secondary text
	Squid = lipgloss.Color("#666666") // Muted text
	BBQ   = lipgloss.Color("#444444") // Disabled text
)

// Accent colors (vibrant but not harsh)
var (
	Malibu = lipgloss.Color("#7aa2f7") // Blue - selection, links
	Guac   = lipgloss.Color("#9ece6a") // Green - success
	Coral  = lipgloss.Color("#f7768e") // Red - danger, errors
	Citron = lipgloss.Color("#e0af68") // Yellow/Orange - warning, favorites
	Lilac  = lipgloss.Color("#bb9af7") // Purple - other/misc
	Cyan   = lipgloss.Color("#7dcfff") // Cyan - info, watched
)

// Theme holds the current color scheme
type Theme struct {
	// Text colors
	Primary   lipgloss.Color
	Secondary lipgloss.Color
	Muted     lipgloss.Color
	Disabled  lipgloss.Color

	// Background colors
	BgBase      lipgloss.Color
	BgElevated  lipgloss.Color
	BgSelection lipgloss.Color
	BgHover     lipgloss.Color

	// Semantic colors
	Accent  lipgloss.Color
	Success lipgloss.Color
	Warning lipgloss.Color
	Danger  lipgloss.Color
	Info    lipgloss.Color

	// Process type colors
	WebServer   lipgloss.Color
	Database    lipgloss.Color
	Development lipgloss.Color
	System      lipgloss.Color
	Other       lipgloss.Color
}

// current holds the active theme
var current = Dark()

// Dark returns the dark theme (default)
func Dark() Theme {
	return Theme{
		// Text
		Primary:   Salt,
		Secondary: Ash,
		Muted:     Squid,
		Disabled:  BBQ,

		// Backgrounds
		BgBase:      Charcoal,
		BgElevated:  Iron,
		BgSelection: Smoke,
		BgHover:     Oyster,

		// Semantic
		Accent:  Malibu,
		Success: Guac,
		Warning: Citron,
		Danger:  Coral,
		Info:    Cyan,

		// Process types
		WebServer:   Malibu,
		Database:    Guac,
		Development: Citron,
		System:      Squid,
		Other:       Lilac,
	}
}

// Current returns the current theme
func Current() Theme {
	return current
}

// SetTheme sets the current theme
func SetTheme(t Theme) {
	current = t
}

// Styles - pre-configured lipgloss styles using the theme

// Text styles
func (t Theme) TextPrimary() lipgloss.Style {
	return lipgloss.NewStyle().Foreground(t.Primary)
}

func (t Theme) TextSecondary() lipgloss.Style {
	return lipgloss.NewStyle().Foreground(t.Secondary)
}

func (t Theme) TextMuted() lipgloss.Style {
	return lipgloss.NewStyle().Foreground(t.Muted)
}

// Logo/Brand style
func (t Theme) Logo() lipgloss.Style {
	return lipgloss.NewStyle().Foreground(t.Accent).Bold(true)
}

func (t Theme) LogoText() lipgloss.Style {
	return lipgloss.NewStyle().Foreground(t.Primary).Bold(true)
}

// Selection style
func (t Theme) Selected() lipgloss.Style {
	return lipgloss.NewStyle().
		Foreground(t.Primary).
		Background(t.BgSelection).
		Bold(true)
}

// Cursor indicator
func (t Theme) Cursor() lipgloss.Style {
	return lipgloss.NewStyle().Foreground(t.Accent)
}

// AccentStyle style for highlighted items
func (t Theme) AccentStyle() lipgloss.Style {
	return lipgloss.NewStyle().Foreground(t.Accent)
}

// InfoStyle style for informational messages
func (t Theme) InfoStyle() lipgloss.Style {
	return lipgloss.NewStyle().Foreground(t.Info)
}

// Status indicators
func (t Theme) Favorite() lipgloss.Style {
	return lipgloss.NewStyle().Foreground(t.Warning)
}

func (t Theme) Watched() lipgloss.Style {
	return lipgloss.NewStyle().Foreground(t.Info)
}

// Message styles
func (t Theme) SuccessMsg() lipgloss.Style {
	return lipgloss.NewStyle().Foreground(t.Success)
}

func (t Theme) ErrorMsg() lipgloss.Style {
	return lipgloss.NewStyle().Foreground(t.Danger)
}

func (t Theme) WarningMsg() lipgloss.Style {
	return lipgloss.NewStyle().Foreground(t.Warning)
}

// Process type style
func (t Theme) ProcessType(ptype string) lipgloss.Style {
	var color lipgloss.Color
	switch ptype {
	case "WebServer":
		color = t.WebServer
	case "Database":
		color = t.Database
	case "Development":
		color = t.Development
	case "System":
		color = t.System
	default:
		color = t.Other
	}
	return lipgloss.NewStyle().Foreground(color)
}

// Help key style
func (t Theme) HelpKey() lipgloss.Style {
	return lipgloss.NewStyle().Foreground(t.Secondary)
}

func (t Theme) HelpDesc() lipgloss.Style {
	return lipgloss.NewStyle().Foreground(t.Muted)
}

// Dialog styles
func (t Theme) DialogBorder() lipgloss.Style {
	return lipgloss.NewStyle().
		Border(lipgloss.RoundedBorder()).
		BorderForeground(t.Muted).
		Padding(1, 2)
}

func (t Theme) DialogDanger() lipgloss.Style {
	return lipgloss.NewStyle().
		Border(lipgloss.RoundedBorder()).
		BorderForeground(t.Danger).
		Padding(1, 2)
}
