-- ============================================================
-- 竞品监控工具 · 建库建表脚本
-- 目标：MySQL 8.x，字符集 utf8mb4
-- 用法：mysql -u root -p < sql/init.sql
-- 特性：可重复执行（CREATE ... IF NOT EXISTS），不会破坏已有数据
-- ============================================================

CREATE DATABASE IF NOT EXISTS `competitor_monitor`
  DEFAULT CHARACTER SET utf8mb4
  COLLATE utf8mb4_0900_ai_ci;

USE `competitor_monitor`;

SET NAMES utf8mb4;


-- ------------------------------------------------------------
-- competitor_snapshot｜事实表：每日竞品快照
--   唯一键 (task_date, sku_id, platform, url) 保证同日同商品不重复入库；
--   price/price_raw、sales/sales_raw 双列并存，清洗值与原始凭证对照留痕。
-- ------------------------------------------------------------
CREATE TABLE IF NOT EXISTS `competitor_snapshot` (
  `id`          bigint        NOT NULL AUTO_INCREMENT,
  `task_date`   date                   DEFAULT NULL,
  `sku_id`      varchar(32)            DEFAULT NULL,
  `platform`    varchar(16)            DEFAULT NULL,
  `rank`        int                    DEFAULT NULL,
  `title`       varchar(512)           DEFAULT NULL,
  `shop`        varchar(255)           DEFAULT NULL,
  `price`       decimal(10,2)          DEFAULT NULL,
  `price_raw`   varchar(64)            DEFAULT NULL,
  `sales`       int                    DEFAULT NULL,
  `sales_raw`   varchar(64)            DEFAULT NULL,
  `url`         varchar(1024)          DEFAULT NULL,
  `captured_at` datetime               DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_snapshot` (`task_date`,`sku_id`,`platform`,`url`(255)),
  KEY `idx_date_sku` (`task_date`,`sku_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;


-- ------------------------------------------------------------
-- alert_log｜告警事实表：P0 破价 / P1 环比降价 / P2 店铺异动
--   detail 唯一键防重复记录；notified 标记防重复推送；
--   price / our_price / gap_pct 结构化字段支撑「破价最狠 TOP3」排序。
-- ------------------------------------------------------------
CREATE TABLE IF NOT EXISTS `alert_log` (
  `id`          bigint        NOT NULL AUTO_INCREMENT,
  `task_date`   date                   DEFAULT NULL,
  `sku_id`      varchar(32)            DEFAULT NULL,
  `alert_type`  varchar(16)            DEFAULT NULL COMMENT 'P0_BREACH破价 / P1_DROP环比降价 / P2_CHANGE店铺异动',
  `level`       varchar(8)             DEFAULT NULL,
  `detail`      varchar(1024)          DEFAULT NULL COMMENT '告警详情',
  `notified`    tinyint                DEFAULT '0' COMMENT '是否已推送：0=未推，1=已推',
  `title_short` varchar(64)            DEFAULT NULL,
  `price`       decimal(10,2)          DEFAULT NULL,
  `our_price`   decimal(10,2)          DEFAULT NULL,
  `gap_pct`     int                    DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_alert` (`task_date`,`sku_id`,`alert_type`,`detail`(255))
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;


-- ------------------------------------------------------------
-- run_log｜运行流水：每天一行
--   状态机 running / done / partial；卡在 running 即「跑过但没跑完」的告警信号。
-- ------------------------------------------------------------
CREATE TABLE IF NOT EXISTS `run_log` (
  `task_date`  date        NOT NULL,
  `start_time` datetime             DEFAULT NULL,
  `end_time`   datetime             DEFAULT NULL,
  `total`      int                  DEFAULT NULL,
  `success`    int                  DEFAULT NULL,
  `failed`     int                  DEFAULT NULL,
  `status`     varchar(16)          DEFAULT NULL,
  PRIMARY KEY (`task_date`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;


-- ------------------------------------------------------------
-- sku_baseline｜维度表：SKU 基准价与阈值（二期启用）
--   预留表：基准价入库后，compare_alerts 与采集环节可彻底解耦。
--   目前基准价由 config/监控清单.xlsx 提供。
-- ------------------------------------------------------------
CREATE TABLE IF NOT EXISTS `sku_baseline` (
  `sku_id`              varchar(32)    NOT NULL,
  `product_name`        varchar(255)            DEFAULT NULL,
  `our_price`           decimal(10,2)           DEFAULT NULL,
  `keyword`             varchar(255)            DEFAULT NULL,
  `platforms`           varchar(32)             DEFAULT NULL,
  `breach_threshold_pct` decimal(5,2)           DEFAULT NULL,
  `drop_threshold_pct`  decimal(5,2)            DEFAULT NULL,
  `active`              tinyint                 DEFAULT '1',
  PRIMARY KEY (`sku_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
