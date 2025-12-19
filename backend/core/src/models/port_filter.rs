//! Port filtering and search functionality.

use std::collections::HashSet;

use serde::{Deserialize, Serialize};

use super::{PortInfo, ProcessType, WatchedPort};

/// Filter criteria for port listings.
///
/// PortFilter provides comprehensive filtering options for port listings,
/// including text search, port range, process type, and special lists
/// (favorites and watched).
#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize)]
pub struct PortFilter {
    /// Text to search across port info fields.
    #[serde(default)]
    pub search_text: String,

    /// Minimum port number (inclusive).
    #[serde(default)]
    pub min_port: Option<u16>,

    /// Maximum port number (inclusive).
    #[serde(default)]
    pub max_port: Option<u16>,

    /// Process types to include. If empty, includes all types.
    #[serde(default = "all_process_types")]
    pub process_types: HashSet<ProcessType>,

    /// Only show favorite ports.
    #[serde(default)]
    pub show_only_favorites: bool,

    /// Only show watched ports.
    #[serde(default)]
    pub show_only_watched: bool,
}

fn all_process_types() -> HashSet<ProcessType> {
    ProcessType::ALL.into_iter().collect()
}

impl Default for PortFilter {
    fn default() -> Self {
        Self {
            search_text: String::new(),
            min_port: None,
            max_port: None,
            process_types: all_process_types(),
            show_only_favorites: false,
            show_only_watched: false,
        }
    }
}

impl PortFilter {
    /// Create a new filter with default settings (no filtering).
    pub fn new() -> Self {
        Self::default()
    }

    /// Check if the filter has any active conditions.
    pub fn is_active(&self) -> bool {
        !self.search_text.is_empty()
            || self.min_port.is_some()
            || self.max_port.is_some()
            || self.process_types.len() < ProcessType::ALL.len()
            || self.show_only_favorites
            || self.show_only_watched
    }

    /// Check if a port matches all filter criteria.
    ///
    /// # Arguments
    /// * `port` - The port info to check
    /// * `favorites` - Set of favorite port numbers
    /// * `watched` - List of watched ports
    pub fn matches(
        &self,
        port: &PortInfo,
        favorites: &HashSet<u16>,
        watched: &[WatchedPort],
    ) -> bool {
        // Search text filter
        if !self.search_text.is_empty() && !port.matches_search(&self.search_text) {
            return false;
        }

        // Port range filter
        if let Some(min) = self.min_port {
            if port.port < min {
                return false;
            }
        }
        if let Some(max) = self.max_port {
            if port.port > max {
                return false;
            }
        }

        // Process type filter
        if !self.process_types.is_empty() && !self.process_types.contains(&port.process_type()) {
            return false;
        }

        // Favorites filter
        if self.show_only_favorites && !favorites.contains(&port.port) {
            return false;
        }

        // Watched filter
        if self.show_only_watched && !watched.iter().any(|w| w.port == port.port) {
            return false;
        }

        true
    }

    /// Reset all filter criteria to defaults.
    pub fn reset(&mut self) {
        *self = Self::default();
    }

    /// Set the search text.
    pub fn with_search(mut self, text: impl Into<String>) -> Self {
        self.search_text = text.into();
        self
    }

    /// Set the port range.
    pub fn with_port_range(mut self, min: Option<u16>, max: Option<u16>) -> Self {
        self.min_port = min;
        self.max_port = max;
        self
    }

    /// Set the allowed process types.
    pub fn with_process_types(mut self, types: impl IntoIterator<Item = ProcessType>) -> Self {
        self.process_types = types.into_iter().collect();
        self
    }

    /// Enable/disable favorites-only mode.
    pub fn with_favorites_only(mut self, enabled: bool) -> Self {
        self.show_only_favorites = enabled;
        self
    }

    /// Enable/disable watched-only mode.
    pub fn with_watched_only(mut self, enabled: bool) -> Self {
        self.show_only_watched = enabled;
        self
    }
}

/// Apply a filter to a list of ports.
pub fn filter_ports(
    ports: &[PortInfo],
    filter: &PortFilter,
    favorites: &HashSet<u16>,
    watched: &[WatchedPort],
) -> Vec<PortInfo> {
    ports
        .iter()
        .filter(|p| filter.matches(p, favorites, watched))
        .cloned()
        .collect()
}

#[cfg(test)]
mod tests {
    use super::*;

    fn sample_ports() -> Vec<PortInfo> {
        vec![
            PortInfo::active(3000, 1234, "node", "*", "user", "node server.js", "19u"),
            PortInfo::active(5432, 5678, "postgres", "*", "postgres", "postgres", "6u"),
            PortInfo::active(80, 1, "nginx", "*", "root", "nginx", "6u"),
            PortInfo::active(8080, 9999, "java", "*", "user", "java -jar app.jar", "10u"),
        ]
    }

    #[test]
    fn test_default_filter_matches_all() {
        let filter = PortFilter::new();
        let ports = sample_ports();
        let favorites = HashSet::new();
        let watched = vec![];

        for port in &ports {
            assert!(filter.matches(port, &favorites, &watched));
        }
    }

    #[test]
    fn test_search_filter() {
        let filter = PortFilter::new().with_search("node");
        let ports = sample_ports();
        let favorites = HashSet::new();
        let watched = vec![];

        let filtered = filter_ports(&ports, &filter, &favorites, &watched);
        assert_eq!(filtered.len(), 1);
        assert_eq!(filtered[0].process_name, "node");
    }

    #[test]
    fn test_port_range_filter() {
        let filter = PortFilter::new().with_port_range(Some(1000), Some(6000));
        let ports = sample_ports();
        let favorites = HashSet::new();
        let watched = vec![];

        let filtered = filter_ports(&ports, &filter, &favorites, &watched);
        assert_eq!(filtered.len(), 2); // 3000 and 5432
    }

    #[test]
    fn test_process_type_filter() {
        let filter = PortFilter::new().with_process_types([ProcessType::WebServer]);
        let ports = sample_ports();
        let favorites = HashSet::new();
        let watched = vec![];

        let filtered = filter_ports(&ports, &filter, &favorites, &watched);
        assert_eq!(filtered.len(), 1);
        assert_eq!(filtered[0].process_name, "nginx");
    }

    #[test]
    fn test_favorites_filter() {
        let filter = PortFilter::new().with_favorites_only(true);
        let ports = sample_ports();
        let mut favorites = HashSet::new();
        favorites.insert(3000);
        favorites.insert(80);
        let watched = vec![];

        let filtered = filter_ports(&ports, &filter, &favorites, &watched);
        assert_eq!(filtered.len(), 2);
    }

    #[test]
    fn test_watched_filter() {
        let filter = PortFilter::new().with_watched_only(true);
        let ports = sample_ports();
        let favorites = HashSet::new();
        let watched = vec![WatchedPort::new(5432)];

        let filtered = filter_ports(&ports, &filter, &favorites, &watched);
        assert_eq!(filtered.len(), 1);
        assert_eq!(filtered[0].port, 5432);
    }

    #[test]
    fn test_is_active() {
        let default_filter = PortFilter::new();
        assert!(!default_filter.is_active());

        let search_filter = PortFilter::new().with_search("test");
        assert!(search_filter.is_active());

        let favorites_filter = PortFilter::new().with_favorites_only(true);
        assert!(favorites_filter.is_active());
    }

    #[test]
    fn test_reset() {
        let mut filter = PortFilter::new()
            .with_search("test")
            .with_favorites_only(true);
        assert!(filter.is_active());

        filter.reset();
        assert!(!filter.is_active());
    }
}
