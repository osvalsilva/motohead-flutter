CREATE TABLE IF NOT EXISTS visitor_tracking (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    visitor_id VARCHAR(64) NOT NULL,
    visit_date DATE NOT NULL,
    ip_address VARCHAR(45) DEFAULT NULL,
    user_agent TEXT DEFAULT NULL,
    page_url VARCHAR(500) DEFAULT NULL,
    user_id BIGINT DEFAULT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE KEY unique_visitor_date (visitor_id, visit_date),
    INDEX idx_visit_date (visit_date),
    INDEX idx_visitor_id (visitor_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
