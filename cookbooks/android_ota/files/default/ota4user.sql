CREATE TABLE IF NOT EXISTS `pp_admin` (
  `admin_id` smallint(6) unsigned NOT NULL AUTO_INCREMENT,
  `admin_name` varchar(50) NOT NULL,
  `admin_pwd` char(32) NOT NULL,
  `admin_count` smallint(6) NOT NULL,
  `admin_ok` varchar(50) NOT NULL,
  `admin_del` bigint(1) NOT NULL,
  `admin_ip` varchar(40) NOT NULL,
  `admin_email` varchar(40) NOT NULL,
  `admin_logintime` int(11) NOT NULL,
  PRIMARY KEY (`admin_id`)
) ENGINE=MyISAM  DEFAULT CHARSET=utf8;

INSERT INTO `pp_admin` (`admin_id`, `admin_name`, `admin_pwd`, `admin_count`, `admin_ok`, `admin_del`,    `admin_ip`, `admin_email`, `admin_logintime`) VALUES
(1, 'admin', 'e10adc3949ba59abbe56e057f20f883e', 198, '0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0', 0, '192. 168.11.145', '', 1456311434);

CREATE TABLE IF NOT EXISTS `pp_brand_type` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `name` varchar(30) NOT NULL,
  `pinyin` varchar(60) NOT NULL,
  PRIMARY KEY (`id`)
) ENGINE=MyISAM  DEFAULT CHARSET=utf8;

CREATE TABLE IF NOT EXISTS `pp_kbox` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `model` varchar(50) NOT NULL,
  `chip` varchar(50) NOT NULL,
  `remarks` varchar(2048) NOT NULL,
  `time` int(11) NOT NULL,
  `bid` int(11) NOT NULL,
  PRIMARY KEY (`id`)
) ENGINE=MyISAM  DEFAULT CHARSET=utf8;

CREATE TABLE IF NOT EXISTS `pp_ota_info` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `oid` int(11) NOT NULL,
  `lid` int(11) NOT NULL,
  `info` text CHARACTER SET utf8 NOT NULL,
  PRIMARY KEY (`id`)
) ENGINE=MyISAM  DEFAULT CHARSET=utf8;

CREATE TABLE IF NOT EXISTS `pp_ota_lang` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `name` varchar(30) CHARACTER SET utf8 NOT NULL,
  `code` varchar(15) CHARACTER SET utf8 NOT NULL,
  PRIMARY KEY (`id`)
) ENGINE=MyISAM  DEFAULT CHARSET=utf8;

CREATE TABLE IF NOT EXISTS `pp_ota_rom` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `kid` int(11) NOT NULL,
  `cversion` varchar(30) NOT NULL,
  `oversion` varchar(150) NOT NULL,
  `zipurl` varchar(150) NOT NULL,
  `md5` varchar(512) NOT NULL,
  `mac` varchar(60) NOT NULL,
  `status` tinyint(1) NOT NULL DEFAULT '1',
  `time` int(11) NOT NULL,
  `popup` int(2) NOT NULL,
  `count` int(11) NOT NULL,
  PRIMARY KEY (`id`)
) ENGINE=MyISAM  DEFAULT CHARSET=utf8;
