use colored::*;
use serde::Serialize;
use std::fmt::Display;

pub enum OutputFormat {
    Text,
    Json,
}

impl OutputFormat {
    pub fn from_str(s: &str) -> Self {
        match s.to_lowercase().as_str() {
            "json" => OutputFormat::Json,
            _ => OutputFormat::Text,
        }
    }
}

pub fn print_table(headers: &[&str], rows: &[Vec<String>]) {
    if rows.is_empty() {
        println!("{}", "No data to display".yellow());
        return;
    }

    // Calculate column widths
    let mut widths = headers.iter().map(|h| h.len()).collect::<Vec<_>>();

    for row in rows {
        for (i, cell) in row.iter().enumerate() {
            if i < widths.len() {
                widths[i] = widths[i].max(cell.len());
            }
        }
    }

    // Print header
    print!("┌");
    for (i, width) in widths.iter().enumerate() {
        print!("{}", "─".repeat(width + 2));
        if i < widths.len() - 1 {
            print!("┬");
        }
    }
    println!("┐");

    print!("│");
    for (i, (header, width)) in headers.iter().zip(&widths).enumerate() {
        print!(" {:<width$} ", header.bold(), width = width);
        print!("│");
    }
    println!();

    print!("├");
    for (i, width) in widths.iter().enumerate() {
        print!("{}", "─".repeat(width + 2));
        if i < widths.len() - 1 {
            print!("┼");
        }
    }
    println!("┤");

    // Print rows
    for row in rows {
        print!("│");
        for (i, (cell, width)) in row.iter().zip(&widths).enumerate() {
            print!(" {:<width$} ", cell, width = width);
            print!("│");
        }
        println!();
    }

    // Print footer
    print!("└");
    for (i, width) in widths.iter().enumerate() {
        print!("{}", "─".repeat(width + 2));
        if i < widths.len() - 1 {
            print!("┴");
        }
    }
    println!("┘");
}

pub fn print_json<T: Serialize>(data: &T) -> anyhow::Result<()> {
    let json = serde_json::to_string_pretty(data)?;
    println!("{}", json);
    Ok(())
}

pub fn print_success(message: &str) {
    println!("{} {}", "✓".green().bold(), message);
}

pub fn print_error(message: &str) {
    eprintln!("{} {}", "✗".red().bold(), message);
}

pub fn print_warning(message: &str) {
    println!("{} {}", "⚠".yellow().bold(), message);
}

pub fn print_info(message: &str) {
    println!("{} {}", "ℹ".blue().bold(), message);
}

pub fn print_section(title: &str) {
    println!();
    println!("{}", title.cyan().bold());
    println!("{}", "─".repeat(title.len()));
}

pub fn print_key_value(key: &str, value: &str) {
    println!("  {}: {}", key.bold(), value);
}

pub fn print_list_item(item: &str) {
    println!("  • {}", item);
}

pub fn format_bytes(bytes: u64) -> String {
    const KB: u64 = 1024;
    const MB: u64 = KB * 1024;
    const GB: u64 = MB * 1024;

    if bytes >= GB {
        format!("{:.2} GB", bytes as f64 / GB as f64)
    } else if bytes >= MB {
        format!("{:.2} MB", bytes as f64 / MB as f64)
    } else if bytes >= KB {
        format!("{:.2} KB", bytes as f64 / KB as f64)
    } else {
        format!("{} bytes", bytes)
    }
}

pub fn format_duration(seconds: u64) -> String {
    let hours = seconds / 3600;
    let minutes = (seconds % 3600) / 60;
    let secs = seconds % 60;

    if hours > 0 {
        format!("{}h {}m {}s", hours, minutes, secs)
    } else if minutes > 0 {
        format!("{}m {}s", minutes, secs)
    } else {
        format!("{}s", secs)
    }
}

pub fn truncate(s: &str, max_len: usize) -> String {
    if s.len() <= max_len {
        s.to_string()
    } else {
        format!("{}...", &s[..max_len - 3])
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_format_bytes() {
        assert_eq!(format_bytes(100), "100 bytes");
        assert_eq!(format_bytes(1024), "1.00 KB");
        assert_eq!(format_bytes(1024 * 1024), "1.00 MB");
        assert_eq!(format_bytes(1024 * 1024 * 1024), "1.00 GB");
    }

    #[test]
    fn test_format_duration() {
        assert_eq!(format_duration(30), "30s");
        assert_eq!(format_duration(90), "1m 30s");
        assert_eq!(format_duration(3661), "1h 1m 1s");
    }

    #[test]
    fn test_truncate() {
        assert_eq!(truncate("Hello", 10), "Hello");
        assert_eq!(truncate("Hello World!", 8), "Hello...");
    }
}
