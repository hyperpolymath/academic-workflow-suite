//! Time and date utilities for the Academic Workflow Suite.
//!
//! This module provides utilities for:
//! - Timezone conversions (UTC, UK time)
//! - Academic year calculations
//! - Assignment deadline helpers
//! - ISO 8601 formatting

use crate::errors::{Result, SharedError};
use chrono::{DateTime, Datelike, Duration, NaiveDate, NaiveDateTime, TimeZone, Utc};
use chrono_tz::Europe::London;
use chrono_tz::Tz;

/// UK timezone (Europe/London)
pub const UK_TIMEZONE: Tz = London;

/// Academic year start month (October)
pub const ACADEMIC_YEAR_START_MONTH: u32 = 10;

/// Academic year start day
pub const ACADEMIC_YEAR_START_DAY: u32 = 1;

/// Get current UTC datetime.
///
/// # Examples
///
/// ```
/// use academic_shared::time::now_utc;
///
/// let now = now_utc();
/// assert!(now.timestamp() > 0);
/// ```
pub fn now_utc() -> DateTime<Utc> {
    Utc::now()
}

/// Get current UK local time.
///
/// # Examples
///
/// ```
/// use academic_shared::time::now_uk;
///
/// let now = now_uk();
/// // Time is in UK timezone
/// ```
pub fn now_uk() -> DateTime<Tz> {
    Utc::now().with_timezone(&UK_TIMEZONE)
}

/// Convert UTC datetime to UK timezone.
///
/// # Examples
///
/// ```
/// use academic_shared::time::{now_utc, utc_to_uk};
///
/// let utc_time = now_utc();
/// let uk_time = utc_to_uk(&utc_time);
/// ```
pub fn utc_to_uk(utc_time: &DateTime<Utc>) -> DateTime<Tz> {
    utc_time.with_timezone(&UK_TIMEZONE)
}

/// Convert UK timezone datetime to UTC.
///
/// # Examples
///
/// ```
/// use academic_shared::time::{now_uk, uk_to_utc};
///
/// let uk_time = now_uk();
/// let utc_time = uk_to_utc(&uk_time);
/// ```
pub fn uk_to_utc(uk_time: &DateTime<Tz>) -> DateTime<Utc> {
    uk_time.with_timezone(&Utc)
}

/// Parse an ISO 8601 datetime string.
///
/// # Examples
///
/// ```
/// use academic_shared::time::parse_iso8601;
/// use chrono::Datelike;
///
/// let dt = parse_iso8601("2024-01-15T10:30:00Z").unwrap();
/// assert_eq!(dt.year(), 2024);
/// assert_eq!(dt.month(), 1);
/// ```
pub fn parse_iso8601(datetime_str: &str) -> Result<DateTime<Utc>> {
    DateTime::parse_from_rfc3339(datetime_str)
        .map(|dt| dt.with_timezone(&Utc))
        .map_err(|e| SharedError::Time(format!("Failed to parse datetime: {}", e)))
}

/// Format datetime as ISO 8601 string.
///
/// # Examples
///
/// ```
/// use academic_shared::time::{now_utc, format_iso8601};
///
/// let now = now_utc();
/// let formatted = format_iso8601(&now);
/// // RFC3339 format contains T separator and timezone
/// assert!(formatted.contains('T'));
/// assert!(formatted.contains('Z') || formatted.contains("+00:00"));
/// ```
pub fn format_iso8601(datetime: &DateTime<Utc>) -> String {
    datetime.to_rfc3339()
}

/// Parse a date string in YYYY-MM-DD format.
///
/// # Examples
///
/// ```
/// use academic_shared::time::parse_date;
/// use chrono::Datelike;
///
/// let date = parse_date("2024-01-15").unwrap();
/// assert_eq!(date.year(), 2024);
/// ```
pub fn parse_date(date_str: &str) -> Result<NaiveDate> {
    NaiveDate::parse_from_str(date_str, "%Y-%m-%d")
        .map_err(|e| SharedError::Time(format!("Failed to parse date: {}", e)))
}

/// Format date as YYYY-MM-DD string.
///
/// # Examples
///
/// ```
/// use academic_shared::time::format_date;
/// use chrono::NaiveDate;
///
/// let date = NaiveDate::from_ymd_opt(2024, 1, 15).unwrap();
/// assert_eq!(format_date(&date), "2024-01-15");
/// ```
pub fn format_date(date: &NaiveDate) -> String {
    date.format("%Y-%m-%d").to_string()
}

/// Calculate the academic year for a given date.
///
/// Academic year runs from October 1st to September 30th.
/// For example, October 1, 2024 to September 30, 2025 is academic year 2024/2025.
///
/// # Examples
///
/// ```
/// use academic_shared::time::get_academic_year;
/// use chrono::NaiveDate;
///
/// let date = NaiveDate::from_ymd_opt(2024, 10, 1).unwrap();
/// assert_eq!(get_academic_year(&date), 2024);
///
/// let date = NaiveDate::from_ymd_opt(2025, 9, 30).unwrap();
/// assert_eq!(get_academic_year(&date), 2024);
/// ```
pub fn get_academic_year(date: &NaiveDate) -> i32 {
    let year = date.year();
    let month = date.month();

    if month >= ACADEMIC_YEAR_START_MONTH {
        year
    } else {
        year - 1
    }
}

/// Get the start date of an academic year.
///
/// # Examples
///
/// ```
/// use academic_shared::time::academic_year_start;
/// use chrono::NaiveDate;
///
/// let start = academic_year_start(2024);
/// assert_eq!(start, NaiveDate::from_ymd_opt(2024, 10, 1).unwrap());
/// ```
pub fn academic_year_start(year: i32) -> NaiveDate {
    NaiveDate::from_ymd_opt(year, ACADEMIC_YEAR_START_MONTH, ACADEMIC_YEAR_START_DAY)
        .expect("Invalid academic year start date")
}

/// Get the end date of an academic year.
///
/// # Examples
///
/// ```
/// use academic_shared::time::academic_year_end;
/// use chrono::NaiveDate;
///
/// let end = academic_year_end(2024);
/// assert_eq!(end, NaiveDate::from_ymd_opt(2025, 9, 30).unwrap());
/// ```
pub fn academic_year_end(year: i32) -> NaiveDate {
    NaiveDate::from_ymd_opt(year + 1, 9, 30).expect("Invalid academic year end date")
}

/// Format academic year as string (e.g., "2024/2025").
///
/// # Examples
///
/// ```
/// use academic_shared::time::format_academic_year;
///
/// assert_eq!(format_academic_year(2024), "2024/2025");
/// ```
pub fn format_academic_year(year: i32) -> String {
    format!("{}/{}", year, year + 1)
}

/// Calculate days until a deadline.
///
/// Returns negative number if deadline has passed.
///
/// # Examples
///
/// ```
/// use academic_shared::time::days_until;
/// use chrono::{Utc, Duration};
///
/// let future = Utc::now() + Duration::days(5);
/// let days = days_until(&future);
/// assert!(days >= 4 && days <= 5);
/// ```
pub fn days_until(deadline: &DateTime<Utc>) -> i64 {
    let now = Utc::now();
    (*deadline - now).num_days()
}

/// Calculate hours until a deadline.
///
/// # Examples
///
/// ```
/// use academic_shared::time::hours_until;
/// use chrono::{Utc, Duration};
///
/// let future = Utc::now() + Duration::hours(10);
/// let hours = hours_until(&future);
/// assert!(hours >= 9 && hours <= 10);
/// ```
pub fn hours_until(deadline: &DateTime<Utc>) -> i64 {
    let now = Utc::now();
    (*deadline - now).num_hours()
}

/// Check if a deadline has passed.
///
/// # Examples
///
/// ```
/// use academic_shared::time::is_overdue;
/// use chrono::{Utc, Duration};
///
/// let past = Utc::now() - Duration::hours(1);
/// assert!(is_overdue(&past));
///
/// let future = Utc::now() + Duration::hours(1);
/// assert!(!is_overdue(&future));
/// ```
pub fn is_overdue(deadline: &DateTime<Utc>) -> bool {
    Utc::now() > *deadline
}

/// Check if a deadline is within the specified number of days.
///
/// # Examples
///
/// ```
/// use academic_shared::time::is_deadline_soon;
/// use chrono::{Utc, Duration};
///
/// let soon = Utc::now() + Duration::days(2);
/// assert!(is_deadline_soon(&soon, 7));
///
/// let far = Utc::now() + Duration::days(10);
/// assert!(!is_deadline_soon(&far, 7));
/// ```
pub fn is_deadline_soon(deadline: &DateTime<Utc>, days: i64) -> bool {
    if is_overdue(deadline) {
        return false;
    }
    days_until(deadline) <= days
}

/// Add working days to a date (excludes weekends).
///
/// # Examples
///
/// ```
/// use academic_shared::time::add_working_days;
/// use chrono::NaiveDate;
///
/// let start = NaiveDate::from_ymd_opt(2024, 1, 15).unwrap(); // Monday
/// let end = add_working_days(&start, 5);
/// // 5 working days later
/// ```
pub fn add_working_days(start_date: &NaiveDate, working_days: i64) -> NaiveDate {
    let mut current = *start_date;
    let mut days_added = 0;

    while days_added < working_days {
        current = current.succ_opt().expect("Date overflow");

        // Skip weekends (Saturday = 6, Sunday = 7)
        let weekday = current.weekday().num_days_from_monday();
        if weekday < 5 {
            days_added += 1;
        }
    }

    current
}

/// Calculate working days between two dates (excludes weekends).
///
/// # Examples
///
/// ```
/// use academic_shared::time::working_days_between;
/// use chrono::NaiveDate;
///
/// let start = NaiveDate::from_ymd_opt(2024, 1, 15).unwrap(); // Monday
/// let end = NaiveDate::from_ymd_opt(2024, 1, 19).unwrap();   // Friday
/// assert_eq!(working_days_between(&start, &end), 4);
/// ```
pub fn working_days_between(start_date: &NaiveDate, end_date: &NaiveDate) -> i64 {
    if start_date >= end_date {
        return 0;
    }

    let mut count = 0;
    let mut current = *start_date;

    while current < *end_date {
        current = current.succ_opt().expect("Date overflow");

        // Count weekdays only
        let weekday = current.weekday().num_days_from_monday();
        if weekday < 5 {
            count += 1;
        }
    }

    count
}

/// Parse a datetime in UK timezone.
///
/// # Examples
///
/// ```
/// use academic_shared::time::parse_uk_datetime;
///
/// let dt = parse_uk_datetime("2024-01-15 14:30:00").unwrap();
/// ```
pub fn parse_uk_datetime(datetime_str: &str) -> Result<DateTime<Tz>> {
    NaiveDateTime::parse_from_str(datetime_str, "%Y-%m-%d %H:%M:%S")
        .map_err(|e| SharedError::Time(format!("Failed to parse datetime: {}", e)))
        .and_then(|naive_dt| {
            UK_TIMEZONE
                .from_local_datetime(&naive_dt)
                .single()
                .ok_or_else(|| {
                    SharedError::Time("Ambiguous or invalid local time".to_string())
                })
        })
}

/// Format a UK timezone datetime in a human-readable format.
///
/// # Examples
///
/// ```
/// use academic_shared::time::{now_uk, format_uk_datetime};
///
/// let now = now_uk();
/// let formatted = format_uk_datetime(&now);
/// // e.g., "2024-01-15 14:30:00 GMT" or "2024-07-15 14:30:00 BST"
/// ```
pub fn format_uk_datetime(datetime: &DateTime<Tz>) -> String {
    datetime.format("%Y-%m-%d %H:%M:%S %Z").to_string()
}

/// Get the current semester based on the date.
///
/// Returns "Autumn", "Spring", or "Summer".
///
/// # Examples
///
/// ```
/// use academic_shared::time::get_current_semester;
/// use chrono::NaiveDate;
///
/// let autumn = NaiveDate::from_ymd_opt(2024, 10, 15).unwrap();
/// assert_eq!(get_current_semester(&autumn), "Autumn");
///
/// let spring = NaiveDate::from_ymd_opt(2024, 2, 15).unwrap();
/// assert_eq!(get_current_semester(&spring), "Spring");
/// ```
pub fn get_current_semester(date: &NaiveDate) -> &'static str {
    match date.month() {
        10 | 11 | 12 | 1 => "Autumn",
        2 | 3 | 4 | 5 => "Spring",
        6 | 7 | 8 | 9 => "Summer",
        _ => unreachable!(),
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use chrono::Timelike;

    #[test]
    fn test_now_utc() {
        let now = now_utc();
        assert!(now.timestamp() > 0);
    }

    #[test]
    fn test_now_uk() {
        let now = now_uk();
        assert_eq!(now.timezone(), UK_TIMEZONE);
    }

    #[test]
    fn test_timezone_conversion() {
        let utc_time = now_utc();
        let uk_time = utc_to_uk(&utc_time);
        let back_to_utc = uk_to_utc(&uk_time);

        assert_eq!(utc_time.timestamp(), back_to_utc.timestamp());
    }

    #[test]
    fn test_parse_iso8601() {
        let dt = parse_iso8601("2024-01-15T10:30:00Z").unwrap();
        assert_eq!(dt.year(), 2024);
        assert_eq!(dt.month(), 1);
        assert_eq!(dt.day(), 15);
        assert_eq!(dt.hour(), 10);
        assert_eq!(dt.minute(), 30);
    }

    #[test]
    fn test_format_iso8601() {
        let dt = Utc.with_ymd_and_hms(2024, 1, 15, 10, 30, 0).unwrap();
        let formatted = format_iso8601(&dt);
        assert!(formatted.contains("2024-01-15"));
        assert!(formatted.contains("10:30:00"));
    }

    #[test]
    fn test_parse_date() {
        let date = parse_date("2024-01-15").unwrap();
        assert_eq!(date.year(), 2024);
        assert_eq!(date.month(), 1);
        assert_eq!(date.day(), 15);
    }

    #[test]
    fn test_format_date() {
        let date = NaiveDate::from_ymd_opt(2024, 1, 15).unwrap();
        assert_eq!(format_date(&date), "2024-01-15");
    }

    #[test]
    fn test_get_academic_year() {
        // October - start of academic year
        let date = NaiveDate::from_ymd_opt(2024, 10, 1).unwrap();
        assert_eq!(get_academic_year(&date), 2024);

        // September - end of academic year
        let date = NaiveDate::from_ymd_opt(2025, 9, 30).unwrap();
        assert_eq!(get_academic_year(&date), 2024);

        // January - middle of academic year
        let date = NaiveDate::from_ymd_opt(2025, 1, 15).unwrap();
        assert_eq!(get_academic_year(&date), 2024);
    }

    #[test]
    fn test_academic_year_bounds() {
        let start = academic_year_start(2024);
        assert_eq!(start, NaiveDate::from_ymd_opt(2024, 10, 1).unwrap());

        let end = academic_year_end(2024);
        assert_eq!(end, NaiveDate::from_ymd_opt(2025, 9, 30).unwrap());
    }

    #[test]
    fn test_format_academic_year() {
        assert_eq!(format_academic_year(2024), "2024/2025");
        assert_eq!(format_academic_year(2023), "2023/2024");
    }

    #[test]
    fn test_days_until() {
        let future = Utc::now() + Duration::days(5);
        let days = days_until(&future);
        assert!(days >= 4 && days <= 5);

        let past = Utc::now() - Duration::days(5);
        let days = days_until(&past);
        assert!(days <= -4 && days >= -5);
    }

    #[test]
    fn test_hours_until() {
        let future = Utc::now() + Duration::hours(10);
        let hours = hours_until(&future);
        assert!(hours >= 9 && hours <= 10);
    }

    #[test]
    fn test_is_overdue() {
        let past = Utc::now() - Duration::hours(1);
        assert!(is_overdue(&past));

        let future = Utc::now() + Duration::hours(1);
        assert!(!is_overdue(&future));
    }

    #[test]
    fn test_is_deadline_soon() {
        let soon = Utc::now() + Duration::days(2);
        assert!(is_deadline_soon(&soon, 7));

        let far = Utc::now() + Duration::days(10);
        assert!(!is_deadline_soon(&far, 7));

        let past = Utc::now() - Duration::days(1);
        assert!(!is_deadline_soon(&past, 7));
    }

    #[test]
    fn test_add_working_days() {
        // Start on Monday (2024-01-15)
        let start = NaiveDate::from_ymd_opt(2024, 1, 15).unwrap();

        // Add 1 working day -> Tuesday
        let next = add_working_days(&start, 1);
        assert_eq!(next, NaiveDate::from_ymd_opt(2024, 1, 16).unwrap());

        // Add 5 working days -> Next Monday (skips weekend)
        let next_week = add_working_days(&start, 5);
        assert_eq!(next_week, NaiveDate::from_ymd_opt(2024, 1, 22).unwrap());
    }

    #[test]
    fn test_working_days_between() {
        let start = NaiveDate::from_ymd_opt(2024, 1, 15).unwrap(); // Monday
        let end = NaiveDate::from_ymd_opt(2024, 1, 19).unwrap();   // Friday

        assert_eq!(working_days_between(&start, &end), 4);

        // Same date
        assert_eq!(working_days_between(&start, &start), 0);

        // Reversed
        assert_eq!(working_days_between(&end, &start), 0);
    }

    #[test]
    fn test_get_current_semester() {
        let autumn = NaiveDate::from_ymd_opt(2024, 10, 15).unwrap();
        assert_eq!(get_current_semester(&autumn), "Autumn");

        let spring = NaiveDate::from_ymd_opt(2024, 2, 15).unwrap();
        assert_eq!(get_current_semester(&spring), "Spring");

        let summer = NaiveDate::from_ymd_opt(2024, 7, 15).unwrap();
        assert_eq!(get_current_semester(&summer), "Summer");
    }

    #[test]
    fn test_parse_uk_datetime() {
        let dt = parse_uk_datetime("2024-01-15 14:30:00").unwrap();
        assert_eq!(dt.year(), 2024);
        assert_eq!(dt.month(), 1);
        assert_eq!(dt.day(), 15);
    }

    #[test]
    fn test_format_uk_datetime() {
        let naive = NaiveDateTime::parse_from_str("2024-01-15 14:30:00", "%Y-%m-%d %H:%M:%S")
            .unwrap();
        let dt = UK_TIMEZONE.from_local_datetime(&naive).unwrap();
        let formatted = format_uk_datetime(&dt);
        assert!(formatted.contains("2024-01-15"));
        assert!(formatted.contains("14:30:00"));
    }
}
