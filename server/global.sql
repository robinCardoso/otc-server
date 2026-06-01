-- phpMyAdmin SQL Dump
-- version 5.0.4
-- https://www.phpmyadmin.net/
--
-- Host: 127.0.0.1
-- Generation Time: Jun 30, 2023 at 01:36 AM
-- Server version: 10.4.17-MariaDB
-- PHP Version: 7.4.13

SET SQL_MODE = "NO_AUTO_VALUE_ON_ZERO";
START TRANSACTION;
SET time_zone = "+00:00";


/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!40101 SET NAMES utf8mb4 */;

--
-- Database: `global`
--

-- --------------------------------------------------------

--
-- Table structure for table `accounts`
--

CREATE TABLE `accounts` (
  `id` int(11) NOT NULL,
  `name` varchar(32) CHARACTER SET utf8 DEFAULT NULL,
  `password` char(40) NOT NULL,
  `secret` char(16) DEFAULT NULL,
  `type` int(11) NOT NULL DEFAULT 1,
  `premdays` int(11) NOT NULL DEFAULT 0,
  `coins` int(12) NOT NULL DEFAULT 0,
  `tournament_coins` int(11) NOT NULL DEFAULT 0,
  `lastday` int(10) UNSIGNED NOT NULL DEFAULT 0,
  `email` varchar(255) NOT NULL DEFAULT '',
  `created` int(11) NOT NULL DEFAULT 0,
  `creation` int(11) NOT NULL DEFAULT 0,
  `vote` int(11) NOT NULL DEFAULT 0,
  `key` varchar(64) NOT NULL DEFAULT '',
  `email_new` varchar(255) NOT NULL DEFAULT '',
  `email_new_time` int(11) NOT NULL DEFAULT 0,
  `rlname` varchar(255) NOT NULL DEFAULT '',
  `location` varchar(255) NOT NULL DEFAULT '',
  `country` varchar(3) NOT NULL DEFAULT '',
  `web_lastlogin` int(11) NOT NULL DEFAULT 0,
  `web_flags` int(11) NOT NULL DEFAULT 0,
  `email_hash` varchar(32) NOT NULL DEFAULT '',
  `email_verified` tinyint(1) NOT NULL DEFAULT 0,
  `page_access` int(11) NOT NULL DEFAULT 0,
  `email_code` varchar(255) NOT NULL DEFAULT '',
  `email_next` int(11) NOT NULL DEFAULT 0,
  `premium_points` int(11) NOT NULL DEFAULT 0,
  `create_date` int(11) NOT NULL DEFAULT 0,
  `create_ip` int(11) NOT NULL DEFAULT 0,
  `last_post` int(11) NOT NULL DEFAULT 0,
  `flag` varchar(80) NOT NULL DEFAULT '',
  `vip_time` int(11) NOT NULL,
  `guild_points` int(11) NOT NULL DEFAULT 0,
  `guild_points_stats` int(11) NOT NULL DEFAULT 0,
  `passed` int(11) NOT NULL DEFAULT 0,
  `block` int(11) NOT NULL DEFAULT 0,
  `refresh` int(11) NOT NULL DEFAULT 0,
  `birth_date` varchar(50) NOT NULL,
  `gender` varchar(20) NOT NULL,
  `loyalty_points` bigint(20) NOT NULL DEFAULT 0,
  `authToken` varchar(100) NOT NULL,
  `backup_points` int(11) NOT NULL DEFAULT 0,
  `secret_status` tinyint(11) NOT NULL DEFAULT 0,
  `player_sell_bank` int(11) NOT NULL,
  `proxy_id` int(11) NOT NULL,
  `tournamentBalance` int(11) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

--
-- Dumping data for table `accounts`
--

INSERT INTO `accounts` (`id`, `name`, `password`, `secret`, `type`, `premdays`, `coins`, `tournament_coins`, `lastday`, `email`, `created`, `creation`, `vote`, `key`, `email_new`, `email_new_time`, `rlname`, `location`, `country`, `web_lastlogin`, `web_flags`, `email_hash`, `email_verified`, `page_access`, `email_code`, `email_next`, `premium_points`, `create_date`, `create_ip`, `last_post`, `flag`, `vip_time`, `guild_points`, `guild_points_stats`, `passed`, `block`, `refresh`, `birth_date`, `gender`, `loyalty_points`, `authToken`, `backup_points`, `secret_status`, `player_sell_bank`, `proxy_id`, `tournamentBalance`) VALUES
(1, 'saljehkjeah', 'sdkjlsdkj22', '', 1, 0, 0, 0, 0, '', 0, 0, 0, '', '', 0, '0', '', '', 0, 0, '', 0, 0, '', 0, 0, 0, 0, 0, 'unknown', 0, 0, 0, 0, 0, 0, '0', 'male', 0, '', 0, 0, 0, 0, 0),
(2, 'god', '21298df8a3277357ee55b01df9530b535cf08ec1', '', 5, 320, 9999, 0, 1688080729, '@god', 0, 0, 0, '', '', 0, 'GOD', '', '', 1688080781, 3, '', 0, 3, '', 0, 12, 0, 0, 0, '', 0, 0, 0, 0, 0, 0, '0', 'male', 0, '', 0, 0, 0, 0, 0);

-- --------------------------------------------------------

--
-- Table structure for table `account_bans`
--

CREATE TABLE `account_bans` (
  `account_id` int(11) NOT NULL,
  `reason` varchar(255) NOT NULL,
  `banned_at` bigint(20) NOT NULL,
  `expires_at` bigint(20) NOT NULL,
  `banned_by` int(11) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

-- --------------------------------------------------------

--
-- Table structure for table `account_ban_history`
--

CREATE TABLE `account_ban_history` (
  `id` int(10) UNSIGNED NOT NULL,
  `account_id` int(11) NOT NULL,
  `reason` varchar(255) NOT NULL,
  `banned_at` bigint(20) NOT NULL,
  `expired_at` bigint(20) NOT NULL,
  `banned_by` int(11) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

-- --------------------------------------------------------

--
-- Table structure for table `account_character_sale`
--

CREATE TABLE `account_character_sale` (
  `id` int(11) NOT NULL,
  `id_account` int(11) NOT NULL,
  `id_player` int(11) NOT NULL,
  `status` tinyint(1) NOT NULL DEFAULT 0,
  `price_type` tinyint(4) NOT NULL,
  `price_coins` int(11) DEFAULT NULL,
  `price_gold` int(11) DEFAULT NULL,
  `dta_insert` datetime NOT NULL,
  `dta_valid` datetime NOT NULL,
  `dta_sale` datetime DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- --------------------------------------------------------

--
-- Table structure for table `account_viplist`
--

CREATE TABLE `account_viplist` (
  `account_id` int(11) NOT NULL COMMENT 'id of account whose viplist entry it is',
  `player_id` int(11) NOT NULL COMMENT 'id of target player of viplist entry',
  `description` varchar(128) NOT NULL DEFAULT '',
  `icon` tinyint(2) UNSIGNED NOT NULL DEFAULT 0,
  `notify` tinyint(1) NOT NULL DEFAULT 0
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

-- --------------------------------------------------------

--
-- Table structure for table `announcements`
--

CREATE TABLE `announcements` (
  `id` int(10) NOT NULL,
  `title` varchar(50) NOT NULL,
  `text` varchar(255) NOT NULL,
  `date` varchar(20) NOT NULL,
  `author` varchar(50) NOT NULL
) ENGINE=MyISAM DEFAULT CHARSET=latin1;

-- --------------------------------------------------------

--
-- Table structure for table `auction_system`
--

CREATE TABLE `auction_system` (
  `id` int(11) NOT NULL,
  `player_id` int(11) NOT NULL,
  `item_name` varchar(255) NOT NULL,
  `item_id` smallint(6) NOT NULL,
  `count` smallint(5) NOT NULL,
  `value` int(7) NOT NULL,
  `date` int(11) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- --------------------------------------------------------

--
-- Table structure for table `blessings_history`
--

CREATE TABLE `blessings_history` (
  `id` int(11) NOT NULL,
  `player_id` int(11) NOT NULL,
  `blessing` tinyint(4) NOT NULL,
  `loss` tinyint(1) NOT NULL,
  `timestamp` int(11) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

-- --------------------------------------------------------

--
-- Table structure for table `boosted_boss`
--

CREATE TABLE `boosted_boss` (
  `looktype` int(11) NOT NULL DEFAULT 136,
  `lookfeet` int(11) NOT NULL DEFAULT 0,
  `looklegs` int(11) NOT NULL DEFAULT 0,
  `lookhead` int(11) NOT NULL DEFAULT 0,
  `lookbody` int(11) NOT NULL DEFAULT 0,
  `lookaddons` int(11) NOT NULL DEFAULT 0,
  `lookmount` int(11) DEFAULT 0,
  `date` varchar(250) NOT NULL DEFAULT '',
  `boostname` text DEFAULT NULL,
  `raceid` varchar(250) NOT NULL DEFAULT ''
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- --------------------------------------------------------

--
-- Table structure for table `boosted_creature`
--

CREATE TABLE `boosted_creature` (
  `looktype` int(11) NOT NULL DEFAULT 136,
  `lookfeet` int(11) NOT NULL DEFAULT 0,
  `looklegs` int(11) NOT NULL DEFAULT 0,
  `lookhead` int(11) NOT NULL DEFAULT 0,
  `lookbody` int(11) NOT NULL DEFAULT 0,
  `lookaddons` int(11) NOT NULL DEFAULT 0,
  `lookmount` int(11) DEFAULT 0,
  `date` varchar(250) NOT NULL DEFAULT '',
  `boostname` text DEFAULT NULL,
  `raceid` varchar(250) NOT NULL DEFAULT ''
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- --------------------------------------------------------

--
-- Table structure for table `bounty_hunter_system`
--

CREATE TABLE `bounty_hunter_system` (
  `id` int(11) NOT NULL,
  `hunter_id` int(11) NOT NULL,
  `target_id` int(11) NOT NULL,
  `killer_id` int(11) NOT NULL,
  `prize` bigint(20) NOT NULL,
  `currencyType` varchar(32) COLLATE utf8_unicode_ci NOT NULL,
  `dateAdded` int(15) NOT NULL,
  `killed` int(11) NOT NULL,
  `dateKilled` int(15) NOT NULL
) ENGINE=MyISAM DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `castle_info`
--

CREATE TABLE `castle_info` (
  `id` int(11) NOT NULL,
  `guild_id` int(11) NOT NULL,
  `timestamp` bigint(20) NOT NULL,
  `active` tinyint(1) NOT NULL DEFAULT 0
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

-- --------------------------------------------------------

--
-- Table structure for table `castle_web`
--

CREATE TABLE `castle_web` (
  `id` int(11) NOT NULL,
  `guild_id` int(11) NOT NULL,
  `guild_name` varchar(255) NOT NULL,
  `player_name` varchar(255) NOT NULL,
  `date` varchar(256) NOT NULL,
  `active` tinyint(1) NOT NULL DEFAULT 0
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

-- --------------------------------------------------------

--
-- Table structure for table `comprovante`
--

CREATE TABLE `comprovante` (
  `id` int(11) NOT NULL,
  `nome` varchar(155) COLLATE utf8_unicode_ci NOT NULL,
  `metodo` varchar(50) COLLATE utf8_unicode_ci NOT NULL,
  `email` varchar(150) COLLATE utf8_unicode_ci NOT NULL,
  `mensagem` text COLLATE utf8_unicode_ci NOT NULL,
  `valor` float(10,2) NOT NULL,
  `anexo` text COLLATE utf8_unicode_ci NOT NULL,
  `motivo` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `pagcode` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `mpcode` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `picpaycode` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `paypalcode` varchar(255) COLLATE utf8_unicode_ci NOT NULL
) ENGINE=MyISAM DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `global_storage`
--

CREATE TABLE `global_storage` (
  `key` varchar(32) NOT NULL,
  `value` text NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

-- --------------------------------------------------------

--
-- Table structure for table `guilds`
--

CREATE TABLE `guilds` (
  `id` int(11) NOT NULL,
  `name` varchar(255) NOT NULL,
  `ownerid` int(11) NOT NULL,
  `creationdata` int(11) NOT NULL,
  `motd` varchar(255) NOT NULL DEFAULT '',
  `description` text NOT NULL,
  `guild_logo` mediumblob DEFAULT NULL,
  `create_ip` int(11) NOT NULL DEFAULT 0,
  `balance` bigint(20) UNSIGNED NOT NULL DEFAULT 0,
  `last_execute_points` int(11) NOT NULL DEFAULT 0,
  `logo_name` varchar(255) NOT NULL DEFAULT 'default.gif',
  `residence` int(11) NOT NULL,
  `level` int(11) NOT NULL,
  `points` int(11) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

--
-- Triggers `guilds`
--
DELIMITER $$
CREATE TRIGGER `oncreate_guilds` AFTER INSERT ON `guilds` FOR EACH ROW BEGIN
    INSERT INTO `guild_ranks` (`name`, `level`, `guild_id`) VALUES ('The Leader', 3, NEW.`id`);
    INSERT INTO `guild_ranks` (`name`, `level`, `guild_id`) VALUES ('Vice-Leader', 2, NEW.`id`);
    INSERT INTO `guild_ranks` (`name`, `level`, `guild_id`) VALUES ('Member', 1, NEW.`id`);
END
$$
DELIMITER ;

-- --------------------------------------------------------

--
-- Table structure for table `guildwar_arenas`
--

CREATE TABLE `guildwar_arenas` (
  `name` varchar(40) NOT NULL DEFAULT 'Default Arena Name',
  `inuse` int(11) NOT NULL DEFAULT 0,
  `type` int(11) NOT NULL DEFAULT 0,
  `guild1` int(11) DEFAULT NULL,
  `guild2` int(11) DEFAULT NULL,
  `start` bigint(15) NOT NULL,
  `end` bigint(15) NOT NULL,
  `team_a_posx` int(11) NOT NULL,
  `team_a_posy` int(11) NOT NULL,
  `team_a_posz` int(11) NOT NULL,
  `team_b_posx` int(11) NOT NULL,
  `team_b_posy` int(11) NOT NULL,
  `team_b_posz` int(11) NOT NULL,
  `maxplayers` int(11) DEFAULT NULL,
  `pending` int(11) NOT NULL,
  `duration` int(11) NOT NULL,
  `challenger` int(11) NOT NULL,
  `arena_team_a_pos` int(1) NOT NULL DEFAULT 0,
  `playersOnTeamA` int(1) DEFAULT 0,
  `playersOnTeamB` int(1) NOT NULL DEFAULT 0,
  `exaust_ssa` int(1) NOT NULL DEFAULT 0,
  `disablepotions` int(1) NOT NULL DEFAULT 0
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

-- --------------------------------------------------------

--
-- Table structure for table `guildwar_kills`
--

CREATE TABLE `guildwar_kills` (
  `id` int(11) NOT NULL,
  `killer` varchar(50) NOT NULL,
  `target` varchar(50) NOT NULL,
  `killerguild` int(11) NOT NULL DEFAULT 0,
  `targetguild` int(11) NOT NULL DEFAULT 0,
  `warid` int(11) NOT NULL DEFAULT 0,
  `time` bigint(15) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

-- --------------------------------------------------------

--
-- Table structure for table `guild_invites`
--

CREATE TABLE `guild_invites` (
  `player_id` int(11) NOT NULL DEFAULT 0,
  `guild_id` int(11) NOT NULL DEFAULT 0,
  `date` int(11) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

-- --------------------------------------------------------

--
-- Table structure for table `guild_kills`
--

CREATE TABLE `guild_kills` (
  `id` int(11) NOT NULL,
  `guild_id` int(11) NOT NULL,
  `war_id` int(11) NOT NULL,
  `death_id` int(11) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

-- --------------------------------------------------------

--
-- Table structure for table `guild_membership`
--

CREATE TABLE `guild_membership` (
  `player_id` int(11) NOT NULL,
  `guild_id` int(11) NOT NULL,
  `rank_id` int(11) NOT NULL,
  `nick` varchar(15) NOT NULL DEFAULT ''
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

-- --------------------------------------------------------

--
-- Table structure for table `guild_ranks`
--

CREATE TABLE `guild_ranks` (
  `id` int(11) NOT NULL,
  `guild_id` int(11) NOT NULL COMMENT 'guild',
  `name` varchar(255) NOT NULL COMMENT 'rank name',
  `level` int(11) NOT NULL COMMENT 'rank level - leader, vice, member, maybe something else'
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

-- --------------------------------------------------------

--
-- Table structure for table `guild_wars`
--

CREATE TABLE `guild_wars` (
  `id` int(11) NOT NULL,
  `guild1` int(11) NOT NULL DEFAULT 0,
  `guild2` int(11) NOT NULL DEFAULT 0,
  `name1` varchar(255) NOT NULL,
  `name2` varchar(255) NOT NULL,
  `status` tinyint(2) NOT NULL DEFAULT 0,
  `started` bigint(15) NOT NULL DEFAULT 0,
  `ended` bigint(15) NOT NULL DEFAULT 0,
  `fraglimit` int(4) NOT NULL DEFAULT 100,
  `frags_limit` int(10) DEFAULT 20
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

-- --------------------------------------------------------

--
-- Table structure for table `houses`
--

CREATE TABLE `houses` (
  `id` int(11) NOT NULL,
  `owner` int(11) NOT NULL,
  `paid` int(10) UNSIGNED NOT NULL DEFAULT 0,
  `warnings` int(11) NOT NULL DEFAULT 0,
  `name` varchar(255) NOT NULL,
  `rent` int(11) NOT NULL DEFAULT 0,
  `town_id` int(11) NOT NULL DEFAULT 0,
  `bid` int(11) NOT NULL DEFAULT 0,
  `bid_end` int(11) NOT NULL DEFAULT 0,
  `last_bid` int(11) NOT NULL DEFAULT 0,
  `highest_bidder` int(11) NOT NULL DEFAULT 0,
  `size` int(11) NOT NULL DEFAULT 0,
  `beds` int(11) NOT NULL DEFAULT 0
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

--
-- Dumping data for table `houses`
--

INSERT INTO `houses` (`id`, `owner`, `paid`, `warnings`, `name`, `rent`, `town_id`, `bid`, `bid_end`, `last_bid`, `highest_bidder`, `size`, `beds`) VALUES
(2, 0, 0, 0, 'Market Street 4 (Shop)', 5105, 1, 0, 0, 0, 0, 182, 3),
(4, 0, 0, 0, 'Market Street 3', 3475, 1, 0, 0, 0, 0, 145, 2),
(5, 0, 0, 0, 'Market Street 2', 4925, 1, 0, 0, 0, 0, 188, 3),
(6, 0, 0, 0, 'Market Street 1', 6680, 1, 0, 0, 0, 0, 234, 3),
(7, 0, 0, 0, 'Old Lighthouse', 3610, 1, 0, 0, 0, 0, 117, 3),
(8, 0, 0, 0, 'Seagull Walk 1', 5095, 1, 0, 0, 0, 0, 186, 2),
(9, 0, 0, 0, 'Seagull Walk 2', 2765, 1, 0, 0, 0, 0, 115, 3),
(10, 0, 0, 0, 'Dream Street 4', 3765, 1, 0, 0, 0, 0, 137, 4),
(11, 0, 0, 0, 'Elm Street 2', 2665, 1, 0, 0, 0, 0, 106, 2),
(12, 0, 0, 0, 'Elm Street 1', 2710, 1, 0, 0, 0, 0, 109, 2),
(13, 0, 0, 0, 'Elm Street 3', 2855, 1, 0, 0, 0, 0, 109, 3),
(14, 0, 0, 0, 'Elm Street 4', 3765, 1, 0, 0, 0, 0, 113, 2),
(15, 0, 0, 0, 'Dream Street 3', 2710, 1, 0, 0, 0, 0, 114, 2),
(16, 0, 0, 0, 'Dream Street 2', 3340, 1, 0, 0, 0, 0, 127, 2),
(18, 0, 0, 0, 'Paupers Palace, Flat 13', 450, 1, 0, 0, 0, 0, 16, 1),
(19, 0, 0, 0, 'Paupers Palace, Flat 12', 685, 1, 0, 0, 0, 0, 27, 2),
(23, 0, 0, 0, 'Paupers Palace, Flat 14', 585, 1, 0, 0, 0, 0, 23, 1),
(24, 0, 0, 0, 'Paupers Palace, Flat 15', 450, 1, 0, 0, 0, 0, 12, 1),
(25, 0, 0, 0, 'Paupers Palace, Flat 16', 585, 1, 0, 0, 0, 0, 19, 1),
(26, 0, 0, 0, 'Paupers Palace, Flat 17', 450, 1, 0, 0, 0, 0, 16, 1),
(27, 0, 0, 0, 'Paupers Palace, Flat 18', 315, 1, 0, 0, 0, 0, 16, 1),
(28, 0, 0, 0, 'Paupers Palace, Flat 01', 405, 1, 0, 0, 0, 0, 15, 1),
(29, 0, 0, 0, 'Paupers Palace, Flat 02', 450, 1, 0, 0, 0, 0, 19, 1),
(30, 0, 0, 0, 'Paupers Palace, Flat 03', 405, 1, 0, 0, 0, 0, 15, 1),
(31, 0, 0, 0, 'Paupers Palace, Flat 04', 450, 1, 0, 0, 0, 0, 16, 1),
(32, 0, 0, 0, 'Paupers Palace, Flat 05', 315, 1, 0, 0, 0, 0, 12, 1),
(33, 0, 0, 0, 'Paupers Palace, Flat 06', 450, 1, 0, 0, 0, 0, 16, 1),
(34, 0, 0, 0, 'Paupers Palace, Flat 07', 685, 1, 0, 0, 0, 0, 23, 2),
(35, 0, 0, 0, 'Paupers Palace, Flat 21', 315, 1, 0, 0, 0, 0, 12, 1),
(36, 0, 0, 0, 'Paupers Palace, Flat 22', 450, 1, 0, 0, 0, 0, 16, 1),
(37, 0, 0, 0, 'Paupers Palace, Flat 23', 585, 1, 0, 0, 0, 0, 23, 1),
(38, 0, 0, 0, 'Paupers Palace, Flat 24', 450, 1, 0, 0, 0, 0, 16, 1),
(39, 0, 0, 0, 'Paupers Palace, Flat 26', 450, 1, 0, 0, 0, 0, 16, 1),
(40, 0, 0, 0, 'Paupers Palace, Flat 28', 315, 1, 0, 0, 0, 0, 15, 1),
(41, 0, 0, 0, 'Paupers Palace, Flat 27', 685, 1, 0, 0, 0, 0, 24, 2),
(42, 0, 0, 0, 'Paupers Palace, Flat 25', 585, 1, 0, 0, 0, 0, 24, 1),
(43, 0, 0, 0, 'Paupers Palace, Flat 31', 855, 1, 0, 0, 0, 0, 28, 1),
(44, 0, 0, 0, 'Paupers Palace, Flat 32', 1135, 1, 0, 0, 0, 0, 32, 2),
(45, 0, 0, 0, 'Paupers Palace, Flat 33', 765, 1, 0, 0, 0, 0, 31, 1),
(46, 0, 0, 0, 'Paupers Palace, Flat 34', 1675, 1, 0, 0, 0, 0, 51, 2),
(47, 0, 0, 0, 'Salvation Street 1 (Shop)', 6240, 1, 0, 0, 0, 0, 200, 4),
(49, 0, 0, 0, 'Dream Street 1 (Shop)', 4330, 1, 0, 0, 0, 0, 147, 2),
(50, 0, 0, 0, 'Blessed Shield Guildhall', 8090, 1, 0, 0, 0, 0, 258, 9),
(51, 0, 0, 0, 'Dagger Alley 1', 2665, 1, 0, 0, 0, 0, 93, 2),
(52, 0, 0, 0, 'Steel Home', 13845, 1, 0, 0, 0, 0, 384, 13),
(53, 0, 0, 0, 'Iron Alley 1', 3450, 1, 0, 0, 0, 0, 111, 4),
(54, 0, 0, 0, 'Iron Alley 2', 3450, 1, 0, 0, 0, 0, 108, 4),
(55, 0, 0, 0, 'Swamp Watch', 11090, 1, 0, 0, 0, 0, 347, 12),
(57, 0, 0, 0, 'Salvation Street 2', 3790, 1, 0, 0, 0, 0, 123, 2),
(60, 0, 0, 0, 'Salvation Street 3', 3790, 1, 0, 0, 0, 0, 129, 2),
(61, 0, 0, 0, 'Silver Street 3', 1980, 1, 0, 0, 0, 0, 61, 1),
(62, 0, 0, 0, 'Golden Axe Guildhall', 10485, 1, 0, 0, 0, 0, 381, 10),
(63, 0, 0, 0, 'Silver Street 1', 2565, 1, 0, 0, 0, 0, 120, 1),
(64, 0, 0, 0, 'Silver Street 2', 1980, 1, 0, 0, 0, 0, 66, 1),
(66, 0, 0, 0, 'Silver Street 4', 3295, 1, 0, 0, 0, 0, 136, 2),
(67, 0, 0, 0, 'Mystic Lane 2', 2980, 1, 0, 0, 0, 0, 99, 2),
(69, 0, 0, 0, 'Mystic Lane 1', 2945, 1, 0, 0, 0, 0, 115, 3),
(70, 0, 0, 0, 'Loot Lane 1 (Shop)', 4565, 1, 0, 0, 0, 0, 194, 3),
(71, 0, 0, 0, 'Market Street 6', 5485, 1, 0, 0, 0, 0, 212, 5),
(72, 0, 0, 0, 'Market Street 7', 2305, 1, 0, 0, 0, 0, 110, 2),
(73, 0, 0, 0, 'Market Street 5 (Shop)', 6375, 1, 0, 0, 0, 0, 214, 4),
(194, 0, 0, 0, 'Lucky Lane 1 (Shop)', 6960, 1, 0, 0, 0, 0, 211, 4),
(208, 0, 0, 0, 'Underwood 1', 1495, 5, 0, 0, 0, 0, 41, 2),
(209, 0, 0, 0, 'Underwood 2', 1495, 5, 0, 0, 0, 0, 41, 2),
(210, 0, 0, 0, 'Underwood 5', 1370, 5, 0, 0, 0, 0, 35, 3),
(211, 0, 0, 0, 'Underwood 3', 1685, 5, 0, 0, 0, 0, 44, 3),
(212, 0, 0, 0, 'Underwood 4', 2235, 5, 0, 0, 0, 0, 56, 4),
(213, 0, 0, 0, 'Underwood 10', 585, 5, 0, 0, 0, 0, 20, 1),
(214, 0, 0, 0, 'Underwood 6', 1595, 5, 0, 0, 0, 0, 42, 3),
(215, 0, 0, 0, 'Great Willow 1a', 500, 5, 0, 0, 0, 0, 16, 1),
(216, 0, 0, 0, 'Great Willow 1b', 650, 5, 0, 0, 0, 0, 22, 1),
(217, 0, 0, 0, 'Great Willow 1c', 650, 5, 0, 0, 0, 0, 22, 1),
(218, 0, 0, 0, 'Great Willow 2d', 450, 5, 0, 0, 0, 0, 10, 1),
(219, 0, 0, 0, 'Great Willow 2c', 650, 5, 0, 0, 0, 0, 21, 1),
(220, 0, 0, 0, 'Great Willow 2b', 450, 5, 0, 0, 0, 0, 16, 1),
(221, 0, 0, 0, 'Great Willow 2a', 650, 5, 0, 0, 0, 0, 17, 1),
(222, 0, 0, 0, 'Great Willow 3d', 450, 5, 0, 0, 0, 0, 17, 1),
(223, 0, 0, 0, 'Great Willow 3c', 650, 5, 0, 0, 0, 0, 21, 1),
(224, 0, 0, 0, 'Great Willow 3b', 450, 5, 0, 0, 0, 0, 16, 1),
(225, 0, 0, 0, 'Great Willow 3a', 650, 5, 0, 0, 0, 0, 20, 1),
(226, 0, 0, 0, 'Great Willow 4b', 950, 5, 0, 0, 0, 0, 25, 2),
(227, 0, 0, 0, 'Great Willow 4c', 950, 5, 0, 0, 0, 0, 25, 2),
(228, 0, 0, 0, 'Great Willow 4d', 750, 5, 0, 0, 0, 0, 26, 1),
(229, 0, 0, 0, 'Great Willow 4a', 950, 5, 0, 0, 0, 0, 25, 2),
(230, 0, 0, 0, 'Underwood 7', 1460, 5, 0, 0, 0, 0, 39, 2),
(231, 0, 0, 0, 'Shadow Caves 3', 300, 5, 0, 0, 0, 0, 16, 1),
(232, 0, 0, 0, 'Shadow Caves 4', 300, 5, 0, 0, 0, 0, 18, 1),
(233, 0, 0, 0, 'Shadow Caves 2', 300, 5, 0, 0, 0, 0, 18, 1),
(234, 0, 0, 0, 'Shadow Caves 1', 300, 5, 0, 0, 0, 0, 16, 1),
(235, 0, 0, 0, 'Shadow Caves 17', 300, 5, 0, 0, 0, 0, 16, 1),
(236, 0, 0, 0, 'Shadow Caves 18', 300, 5, 0, 0, 0, 0, 17, 1),
(237, 0, 0, 0, 'Shadow Caves 15', 300, 5, 0, 0, 0, 0, 16, 1),
(238, 0, 0, 0, 'Shadow Caves 16', 300, 5, 0, 0, 0, 0, 17, 1),
(239, 0, 0, 0, 'Shadow Caves 13', 300, 5, 0, 0, 0, 0, 16, 1),
(240, 0, 0, 0, 'Shadow Caves 14', 300, 5, 0, 0, 0, 0, 19, 1),
(241, 0, 0, 0, 'Shadow Caves 11', 300, 5, 0, 0, 0, 0, 16, 1),
(242, 0, 0, 0, 'Shadow Caves 12', 300, 5, 0, 0, 0, 0, 18, 1),
(243, 0, 0, 0, 'Shadow Caves 27', 300, 5, 0, 0, 0, 0, 14, 1),
(244, 0, 0, 0, 'Shadow Caves 28', 300, 5, 0, 0, 0, 0, 17, 1),
(245, 0, 0, 0, 'Shadow Caves 25', 300, 5, 0, 0, 0, 0, 16, 1),
(246, 0, 0, 0, 'Shadow Caves 26', 300, 5, 0, 0, 0, 0, 17, 1),
(247, 0, 0, 0, 'Shadow Caves 23', 300, 5, 0, 0, 0, 0, 16, 1),
(248, 0, 0, 0, 'Shadow Caves 24', 300, 5, 0, 0, 0, 0, 19, 1),
(249, 0, 0, 0, 'Shadow Caves 21', 300, 5, 0, 0, 0, 0, 16, 1),
(250, 0, 0, 0, 'Shadow Caves 22', 300, 5, 0, 0, 0, 0, 17, 1),
(251, 0, 0, 0, 'Underwood 9', 585, 5, 0, 0, 0, 0, 17, 1),
(252, 0, 0, 0, 'Treetop 13', 1400, 5, 0, 0, 0, 0, 33, 2),
(254, 0, 0, 0, 'Underwood 8', 865, 5, 0, 0, 0, 0, 25, 2),
(255, 0, 0, 0, 'Mangrove 4', 950, 5, 0, 0, 0, 0, 25, 2),
(256, 0, 0, 0, 'Coastwood 10', 1630, 5, 0, 0, 0, 0, 36, 3),
(257, 0, 0, 0, 'Mangrove 1', 1750, 5, 0, 0, 0, 0, 42, 3),
(258, 0, 0, 0, 'Coastwood 1', 980, 5, 0, 0, 0, 0, 24, 2),
(259, 0, 0, 0, 'Coastwood 2', 980, 5, 0, 0, 0, 0, 24, 2),
(260, 0, 0, 0, 'Mangrove 2', 1350, 5, 0, 0, 0, 0, 33, 2),
(262, 0, 0, 0, 'Mangrove 3', 1150, 5, 0, 0, 0, 0, 29, 2),
(263, 0, 0, 0, 'Coastwood 9', 935, 5, 0, 0, 0, 0, 22, 1),
(264, 0, 0, 0, 'Coastwood 8', 1255, 5, 0, 0, 0, 0, 31, 2),
(265, 0, 0, 0, 'Coastwood 6 (Shop)', 1595, 5, 0, 0, 0, 0, 44, 1),
(266, 0, 0, 0, 'Coastwood 7', 660, 5, 0, 0, 0, 0, 19, 1),
(267, 0, 0, 0, 'Coastwood 5', 1530, 5, 0, 0, 0, 0, 35, 2),
(268, 0, 0, 0, 'Coastwood 4', 1145, 5, 0, 0, 0, 0, 30, 2),
(269, 0, 0, 0, 'Coastwood 3', 1310, 5, 0, 0, 0, 0, 34, 2),
(270, 0, 0, 0, 'Treetop 11', 900, 5, 0, 0, 0, 0, 26, 2),
(271, 0, 0, 0, 'Treetop 5 (Shop)', 1350, 5, 0, 0, 0, 0, 40, 1),
(272, 0, 0, 0, 'Treetop 7', 800, 5, 0, 0, 0, 0, 24, 1),
(273, 0, 0, 0, 'Treetop 6', 450, 5, 0, 0, 0, 0, 15, 1),
(274, 0, 0, 0, 'Treetop 8', 800, 5, 0, 0, 0, 0, 23, 1),
(275, 0, 0, 0, 'Treetop 9', 1150, 5, 0, 0, 0, 0, 30, 2),
(276, 0, 0, 0, 'Treetop 10', 1150, 5, 0, 0, 0, 0, 34, 2),
(277, 0, 0, 0, 'Treetop 4 (Shop)', 1250, 5, 0, 0, 0, 0, 40, 1),
(278, 0, 0, 0, 'Treetop 3 (Shop)', 1250, 5, 0, 0, 0, 0, 38, 1),
(279, 0, 0, 0, 'Treetop 2', 650, 5, 0, 0, 0, 0, 21, 1),
(280, 0, 0, 0, 'Treetop 1', 650, 5, 0, 0, 0, 0, 19, 1),
(281, 0, 0, 0, 'Treetop 12 (Shop)', 1350, 5, 0, 0, 0, 0, 40, 1),
(469, 0, 0, 0, 'Darashia 2, Flat 07', 1000, 10, 0, 0, 0, 0, 48, 1),
(470, 0, 0, 0, 'Darashia 2, Flat 01', 1000, 10, 0, 0, 0, 0, 48, 1),
(471, 0, 0, 0, 'Darashia 2, Flat 02', 1000, 10, 0, 0, 0, 0, 42, 1),
(472, 0, 0, 0, 'Darashia 2, Flat 06', 520, 10, 0, 0, 0, 0, 24, 1),
(473, 0, 0, 0, 'Darashia 2, Flat 05', 1260, 10, 0, 0, 0, 0, 48, 2),
(474, 0, 0, 0, 'Darashia 2, Flat 04', 520, 10, 0, 0, 0, 0, 24, 1),
(475, 0, 0, 0, 'Darashia 2, Flat 03', 1160, 10, 0, 0, 0, 0, 42, 1),
(476, 0, 0, 0, 'Darashia 2, Flat 13', 1160, 10, 0, 0, 0, 0, 42, 1),
(477, 0, 0, 0, 'Darashia 2, Flat 12', 520, 10, 0, 0, 0, 0, 24, 1),
(478, 0, 0, 0, 'Darashia 2, Flat 11', 1000, 10, 0, 0, 0, 0, 42, 1),
(479, 0, 0, 0, 'Darashia 2, Flat 14', 520, 10, 0, 0, 0, 0, 24, 1),
(480, 0, 0, 0, 'Darashia 2, Flat 15', 1260, 10, 0, 0, 0, 0, 47, 2),
(481, 0, 0, 0, 'Darashia 2, Flat 16', 680, 10, 0, 0, 0, 0, 30, 1),
(482, 0, 0, 0, 'Darashia 2, Flat 17', 1000, 10, 0, 0, 0, 0, 48, 1),
(483, 0, 0, 0, 'Darashia 2, Flat 18', 680, 10, 0, 0, 0, 0, 30, 1),
(484, 0, 0, 0, 'Darashia 1, Flat 05', 1100, 10, 0, 0, 0, 0, 48, 2),
(485, 0, 0, 0, 'Darashia 1, Flat 01', 1100, 10, 0, 0, 0, 0, 48, 2),
(486, 0, 0, 0, 'Darashia 1, Flat 04', 1000, 10, 0, 0, 0, 0, 42, 1),
(487, 0, 0, 0, 'Darashia 1, Flat 03', 2660, 10, 0, 0, 0, 0, 96, 4),
(488, 0, 0, 0, 'Darashia 1, Flat 02', 1000, 10, 0, 0, 0, 0, 41, 1),
(490, 0, 0, 0, 'Darashia 1, Flat 12', 1780, 10, 0, 0, 0, 0, 66, 2),
(491, 0, 0, 0, 'Darashia 1, Flat 11', 1100, 10, 0, 0, 0, 0, 41, 2),
(492, 0, 0, 0, 'Darashia 1, Flat 13', 1780, 10, 0, 0, 0, 0, 72, 2),
(493, 0, 0, 0, 'Darashia 1, Flat 14', 2760, 10, 0, 0, 0, 0, 108, 5),
(494, 0, 0, 0, 'Darashia 4, Flat 01', 1000, 10, 0, 0, 0, 0, 48, 1),
(495, 0, 0, 0, 'Darashia 4, Flat 05', 1100, 10, 0, 0, 0, 0, 48, 2),
(496, 0, 0, 0, 'Darashia 4, Flat 04', 1780, 10, 0, 0, 0, 0, 72, 2),
(497, 0, 0, 0, 'Darashia 4, Flat 03', 1000, 10, 0, 0, 0, 0, 42, 1),
(498, 0, 0, 0, 'Darashia 4, Flat 02', 1780, 10, 0, 0, 0, 0, 66, 2),
(499, 0, 0, 0, 'Darashia 4, Flat 13', 1780, 10, 0, 0, 0, 0, 78, 2),
(500, 0, 0, 0, 'Darashia 4, Flat 14', 1780, 10, 0, 0, 0, 0, 72, 2),
(501, 0, 0, 0, 'Darashia 4, Flat 11', 1000, 10, 0, 0, 0, 0, 41, 1),
(502, 0, 0, 0, 'Darashia 4, Flat 12', 2560, 10, 0, 0, 0, 0, 96, 3),
(503, 0, 0, 0, 'Darashia 7, Flat 05', 1225, 10, 0, 0, 0, 0, 40, 2),
(504, 0, 0, 0, 'Darashia 7, Flat 01', 1125, 10, 0, 0, 0, 0, 40, 1),
(505, 0, 0, 0, 'Darashia 7, Flat 02', 1125, 10, 0, 0, 0, 0, 41, 1),
(506, 0, 0, 0, 'Darashia 7, Flat 03', 2955, 10, 0, 0, 0, 0, 108, 4),
(507, 0, 0, 0, 'Darashia 7, Flat 04', 1125, 10, 0, 0, 0, 0, 42, 1),
(508, 0, 0, 0, 'Darashia 7, Flat 14', 2955, 10, 0, 0, 0, 0, 108, 4),
(509, 0, 0, 0, 'Darashia 7, Flat 13', 1125, 10, 0, 0, 0, 0, 42, 1),
(510, 0, 0, 0, 'Darashia 7, Flat 11', 1125, 10, 0, 0, 0, 0, 41, 1),
(511, 0, 0, 0, 'Darashia 7, Flat 12', 2955, 10, 0, 0, 0, 0, 95, 4),
(512, 0, 0, 0, 'Darashia 5, Flat 01', 1000, 10, 0, 0, 0, 0, 38, 1),
(513, 0, 0, 0, 'Darashia 5, Flat 05', 1000, 10, 0, 0, 0, 0, 48, 1),
(514, 0, 0, 0, 'Darashia 5, Flat 02', 1620, 10, 0, 0, 0, 0, 57, 2),
(515, 0, 0, 0, 'Darashia 5, Flat 03', 1000, 10, 0, 0, 0, 0, 41, 1),
(516, 0, 0, 0, 'Darashia 5, Flat 04', 1620, 10, 0, 0, 0, 0, 66, 2),
(517, 0, 0, 0, 'Darashia 5, Flat 11', 1780, 10, 0, 0, 0, 0, 66, 2),
(518, 0, 0, 0, 'Darashia 5, Flat 12', 1620, 10, 0, 0, 0, 0, 65, 2),
(519, 0, 0, 0, 'Darashia 5, Flat 13', 1780, 10, 0, 0, 0, 0, 78, 2),
(520, 0, 0, 0, 'Darashia 5, Flat 14', 1620, 10, 0, 0, 0, 0, 66, 2),
(521, 0, 0, 0, 'Darashia 6a', 3115, 10, 0, 0, 0, 0, 117, 2),
(522, 0, 0, 0, 'Darashia 6b', 3430, 10, 0, 0, 0, 0, 139, 2),
(523, 0, 0, 0, 'Darashia, Villa', 5385, 10, 0, 0, 0, 0, 233, 4),
(525, 0, 0, 0, 'Darashia, Western Guildhall', 10435, 10, 0, 0, 0, 0, 376, 14),
(526, 0, 0, 0, 'Darashia 3, Flat 01', 1100, 10, 0, 0, 0, 0, 40, 2),
(527, 0, 0, 0, 'Darashia 3, Flat 05', 1000, 10, 0, 0, 0, 0, 40, 1),
(529, 0, 0, 0, 'Darashia 3, Flat 02', 1620, 10, 0, 0, 0, 0, 65, 2),
(530, 0, 0, 0, 'Darashia 3, Flat 03', 1100, 10, 0, 0, 0, 0, 42, 2),
(531, 0, 0, 0, 'Darashia 3, Flat 04', 1620, 10, 0, 0, 0, 0, 72, 2),
(532, 0, 0, 0, 'Darashia 3, Flat 13', 1100, 10, 0, 0, 0, 0, 42, 2),
(533, 0, 0, 0, 'Darashia 3, Flat 14', 2400, 10, 0, 0, 0, 0, 102, 3),
(534, 0, 0, 0, 'Darashia 3, Flat 11', 1000, 10, 0, 0, 0, 0, 41, 1),
(535, 0, 0, 0, 'Darashia 3, Flat 12', 2600, 10, 0, 0, 0, 0, 90, 5),
(541, 0, 0, 0, 'Darashia 8, Flat 11', 1990, 10, 0, 0, 0, 0, 66, 2),
(542, 0, 0, 0, 'Darashia 8, Flat 12', 1810, 10, 0, 0, 0, 0, 65, 2),
(544, 0, 0, 0, 'Darashia 8, Flat 14', 1810, 10, 0, 0, 0, 0, 66, 2),
(545, 0, 0, 0, 'Darashia 8, Flat 13', 1990, 10, 0, 0, 0, 0, 78, 2),
(574, 0, 0, 0, 'Oskahl I j', 680, 9, 0, 0, 0, 0, 25, 1),
(575, 0, 0, 0, 'Oskahl I f', 840, 9, 0, 0, 0, 0, 34, 1),
(576, 0, 0, 0, 'Oskahl I i', 840, 9, 0, 0, 0, 0, 30, 1),
(577, 0, 0, 0, 'Oskahl I g', 1140, 9, 0, 0, 0, 0, 42, 2),
(578, 0, 0, 0, 'Oskahl I h', 1760, 9, 0, 0, 0, 0, 63, 3),
(579, 0, 0, 0, 'Oskahl I d', 1140, 9, 0, 0, 0, 0, 36, 2),
(580, 0, 0, 0, 'Oskahl I b', 840, 9, 0, 0, 0, 0, 30, 1),
(581, 0, 0, 0, 'Oskahl I c', 680, 9, 0, 0, 0, 0, 29, 1),
(582, 0, 0, 0, 'Oskahl I e', 840, 9, 0, 0, 0, 0, 33, 1),
(583, 0, 0, 0, 'Oskahl I a', 1580, 9, 0, 0, 0, 0, 52, 2),
(584, 0, 0, 0, 'Chameken I', 850, 9, 0, 0, 0, 0, 30, 1),
(585, 0, 0, 0, 'Charsirakh III', 680, 9, 0, 0, 0, 0, 30, 1),
(586, 0, 0, 0, 'Murkhol I d', 440, 9, 0, 0, 0, 0, 21, 1),
(587, 0, 0, 0, 'Murkhol I c', 440, 9, 0, 0, 0, 0, 18, 1),
(588, 0, 0, 0, 'Murkhol I b', 440, 9, 0, 0, 0, 0, 18, 1),
(589, 0, 0, 0, 'Murkhol I a', 440, 9, 0, 0, 0, 0, 20, 1),
(590, 0, 0, 0, 'Charsirakh II', 1140, 9, 0, 0, 0, 0, 39, 2),
(591, 0, 0, 0, 'Thanah II h', 1400, 9, 0, 0, 0, 0, 40, 2),
(592, 0, 0, 0, 'Thanah II g', 1650, 9, 0, 0, 0, 0, 45, 2),
(593, 0, 0, 0, 'Thanah II f', 2850, 9, 0, 0, 0, 0, 80, 3),
(594, 0, 0, 0, 'Thanah II b', 450, 9, 0, 0, 0, 0, 20, 1),
(595, 0, 0, 0, 'Thanah II c', 450, 9, 0, 0, 0, 0, 15, 1),
(596, 0, 0, 0, 'Thanah II d', 350, 9, 0, 0, 0, 0, 16, 1),
(597, 0, 0, 0, 'Thanah II e', 350, 9, 0, 0, 0, 0, 12, 1),
(599, 0, 0, 0, 'Thanah II a', 850, 9, 0, 0, 0, 0, 37, 1),
(600, 0, 0, 0, 'Thrarhor I c (Shop)', 1050, 9, 0, 0, 0, 0, 28, 1),
(601, 0, 0, 0, 'Thrarhor I d (Shop)', 1050, 9, 0, 0, 0, 0, 21, 1),
(602, 0, 0, 0, 'Thrarhor I a (Shop)', 1050, 9, 0, 0, 0, 0, 32, 1),
(603, 0, 0, 0, 'Thrarhor I b (Shop)', 1050, 9, 0, 0, 0, 0, 24, 1),
(604, 0, 0, 0, 'Thanah I c', 3250, 9, 0, 0, 0, 0, 91, 3),
(605, 0, 0, 0, 'Thanah I d', 2900, 9, 0, 0, 0, 0, 80, 4),
(606, 0, 0, 0, 'Thanah I b', 3000, 9, 0, 0, 0, 0, 84, 3),
(607, 0, 0, 0, 'Thanah I a', 850, 9, 0, 0, 0, 0, 27, 1),
(608, 0, 0, 0, 'Harrah I', 5740, 9, 0, 0, 0, 0, 190, 10),
(609, 0, 0, 0, 'Charsirakh I b', 1580, 9, 0, 0, 0, 0, 51, 2),
(610, 0, 0, 0, 'Charsirakh I a', 280, 9, 0, 0, 0, 0, 15, 1),
(611, 0, 0, 0, 'Othehothep I d', 2020, 9, 0, 0, 0, 0, 68, 4),
(612, 0, 0, 0, 'Othehothep I c', 1720, 9, 0, 0, 0, 0, 58, 3),
(613, 0, 0, 0, 'Othehothep I b', 1380, 9, 0, 0, 0, 0, 49, 2),
(614, 0, 0, 0, 'Othehothep I a', 280, 9, 0, 0, 0, 0, 14, 1),
(615, 0, 0, 0, 'Othehothep II e', 1340, 9, 0, 0, 0, 0, 44, 2),
(616, 0, 0, 0, 'Othehothep II f', 1340, 9, 0, 0, 0, 0, 44, 2),
(617, 0, 0, 0, 'Othehothep II d', 840, 9, 0, 0, 0, 0, 32, 1),
(618, 0, 0, 0, 'Othehothep II c', 840, 9, 0, 0, 0, 0, 30, 1),
(619, 0, 0, 0, 'Othehothep II b', 1920, 9, 0, 0, 0, 0, 67, 3),
(620, 0, 0, 0, 'Othehothep II a', 400, 9, 0, 0, 0, 0, 18, 1),
(621, 0, 0, 0, 'Mothrem I', 1140, 9, 0, 0, 0, 0, 38, 2),
(622, 0, 0, 0, 'Arakmehn I', 1320, 9, 0, 0, 0, 0, 41, 3),
(623, 0, 0, 0, 'Othehothep III d', 1040, 9, 0, 0, 0, 0, 36, 1),
(624, 0, 0, 0, 'Othehothep III c', 940, 9, 0, 0, 0, 0, 30, 2),
(625, 0, 0, 0, 'Othehothep III e', 840, 9, 0, 0, 0, 0, 32, 1),
(626, 0, 0, 0, 'Othehothep III f', 680, 9, 0, 0, 0, 0, 27, 1),
(627, 0, 0, 0, 'Othehothep III b', 1340, 9, 0, 0, 0, 0, 49, 2),
(628, 0, 0, 0, 'Othehothep III a', 280, 9, 0, 0, 0, 0, 14, 1),
(629, 0, 0, 0, 'Unklath I d', 1680, 9, 0, 0, 0, 0, 49, 3),
(630, 0, 0, 0, 'Unklath I e', 1580, 9, 0, 0, 0, 0, 51, 2),
(631, 0, 0, 0, 'Unklath I g', 1480, 9, 0, 0, 0, 0, 51, 1),
(632, 0, 0, 0, 'Unklath I f', 1580, 9, 0, 0, 0, 0, 51, 2),
(633, 0, 0, 0, 'Unklath I c', 1460, 9, 0, 0, 0, 0, 50, 2),
(634, 0, 0, 0, 'Unklath I b', 1460, 9, 0, 0, 0, 0, 50, 2),
(635, 0, 0, 0, 'Unklath I a', 1140, 9, 0, 0, 0, 0, 38, 2),
(636, 0, 0, 0, 'Arakmehn II', 1040, 9, 0, 0, 0, 0, 38, 1),
(637, 0, 0, 0, 'Arakmehn III', 1140, 9, 0, 0, 0, 0, 38, 2),
(638, 0, 0, 0, 'Unklath II b', 680, 9, 0, 0, 0, 0, 25, 1),
(639, 0, 0, 0, 'Unklath II c', 680, 9, 0, 0, 0, 0, 27, 1),
(640, 0, 0, 0, 'Unklath II d', 1580, 9, 0, 0, 0, 0, 52, 2),
(641, 0, 0, 0, 'Unklath II a', 1040, 9, 0, 0, 0, 0, 36, 1),
(642, 0, 0, 0, 'Arakmehn IV', 1220, 9, 0, 0, 0, 0, 41, 2),
(643, 0, 0, 0, 'Rathal I b', 680, 9, 0, 0, 0, 0, 25, 1),
(644, 0, 0, 0, 'Rathal I c', 680, 9, 0, 0, 0, 0, 27, 1),
(645, 0, 0, 0, 'Rathal I e', 780, 9, 0, 0, 0, 0, 27, 2),
(646, 0, 0, 0, 'Rathal I d', 780, 9, 0, 0, 0, 0, 27, 2),
(647, 0, 0, 0, 'Rathal I a', 1140, 9, 0, 0, 0, 0, 36, 2),
(648, 0, 0, 0, 'Rathal II b', 680, 9, 0, 0, 0, 0, 25, 1),
(649, 0, 0, 0, 'Rathal II c', 680, 9, 0, 0, 0, 0, 27, 1),
(650, 0, 0, 0, 'Rathal II d', 1460, 9, 0, 0, 0, 0, 52, 2),
(651, 0, 0, 0, 'Rathal II a', 1040, 9, 0, 0, 0, 0, 38, 1),
(653, 0, 0, 0, 'Esuph II a', 280, 9, 0, 0, 0, 0, 14, 1),
(654, 0, 0, 0, 'Uthemath II', 4460, 9, 0, 0, 0, 0, 138, 8),
(655, 0, 0, 0, 'Uthemath I e', 940, 9, 0, 0, 0, 0, 32, 2),
(656, 0, 0, 0, 'Uthemath I d', 840, 9, 0, 0, 0, 0, 30, 1),
(657, 0, 0, 0, 'Uthemath I f', 2440, 9, 0, 0, 0, 0, 86, 3),
(658, 0, 0, 0, 'Uthemath I b', 800, 9, 0, 0, 0, 0, 32, 1),
(659, 0, 0, 0, 'Uthemath I c', 900, 9, 0, 0, 0, 0, 34, 2),
(660, 0, 0, 0, 'Uthemath I a', 400, 9, 0, 0, 0, 0, 18, 1),
(661, 0, 0, 0, 'Botham I c', 1700, 9, 0, 0, 0, 0, 49, 2),
(662, 0, 0, 0, 'Botham I e', 1650, 9, 0, 0, 0, 0, 44, 2),
(663, 0, 0, 0, 'Botham I d', 3050, 9, 0, 0, 0, 0, 80, 3),
(664, 0, 0, 0, 'Botham I b', 3000, 9, 0, 0, 0, 0, 83, 3),
(666, 0, 0, 0, 'Horakhal', 9420, 9, 0, 0, 0, 0, 277, 14),
(667, 0, 0, 0, 'Esuph III b', 1340, 9, 0, 0, 0, 0, 49, 2),
(668, 0, 0, 0, 'Esuph III a', 280, 9, 0, 0, 0, 0, 14, 1),
(669, 0, 0, 0, 'Esuph IV b', 400, 9, 0, 0, 0, 0, 16, 1),
(670, 0, 0, 0, 'Esuph IV c', 400, 9, 0, 0, 0, 0, 18, 1),
(671, 0, 0, 0, 'Esuph IV d', 800, 9, 0, 0, 0, 0, 34, 1),
(672, 0, 0, 0, 'Esuph IV a', 400, 9, 0, 0, 0, 0, 16, 1),
(673, 0, 0, 0, 'Botham II e', 1650, 9, 0, 0, 0, 0, 42, 2),
(674, 0, 0, 0, 'Botham II g', 1400, 9, 0, 0, 0, 0, 38, 2),
(675, 0, 0, 0, 'Botham II f', 1650, 9, 0, 0, 0, 0, 44, 2),
(676, 0, 0, 0, 'Botham II d', 1950, 9, 0, 0, 0, 0, 49, 2),
(677, 0, 0, 0, 'Botham II c', 1250, 9, 0, 0, 0, 0, 38, 2),
(678, 0, 0, 0, 'Botham II b', 1600, 9, 0, 0, 0, 0, 47, 2),
(679, 0, 0, 0, 'Botham II a', 850, 9, 0, 0, 0, 0, 25, 1),
(680, 0, 0, 0, 'Botham III g', 1650, 9, 0, 0, 0, 0, 42, 2),
(681, 0, 0, 0, 'Botham III f', 2350, 9, 0, 0, 0, 0, 56, 3),
(682, 0, 0, 0, 'Botham III h', 3750, 9, 0, 0, 0, 0, 98, 3),
(683, 0, 0, 0, 'Botham III d', 850, 9, 0, 0, 0, 0, 27, 1),
(684, 0, 0, 0, 'Botham III e', 850, 9, 0, 0, 0, 0, 27, 1),
(685, 0, 0, 0, 'Botham III b', 950, 9, 0, 0, 0, 0, 25, 2),
(686, 0, 0, 0, 'Botham III c', 850, 9, 0, 0, 0, 0, 27, 1),
(687, 0, 0, 0, 'Botham III a', 1400, 9, 0, 0, 0, 0, 36, 2),
(688, 0, 0, 0, 'Botham IV i', 1800, 9, 0, 0, 0, 0, 51, 3),
(689, 0, 0, 0, 'Botham IV h', 1850, 9, 0, 0, 0, 0, 49, 1),
(690, 0, 0, 0, 'Botham IV f', 1700, 9, 0, 0, 0, 0, 49, 2),
(691, 0, 0, 0, 'Botham IV g', 1650, 9, 0, 0, 0, 0, 49, 2),
(692, 0, 0, 0, 'Botham IV c', 850, 9, 0, 0, 0, 0, 27, 1),
(693, 0, 0, 0, 'Botham IV e', 850, 9, 0, 0, 0, 0, 27, 1),
(694, 0, 0, 0, 'Botham IV d', 850, 9, 0, 0, 0, 0, 27, 1),
(695, 0, 0, 0, 'Botham IV b', 850, 9, 0, 0, 0, 0, 25, 1),
(696, 0, 0, 0, 'Botham IV a', 1400, 9, 0, 0, 0, 0, 36, 2),
(697, 0, 0, 0, 'Ramen Tah', 7650, 9, 0, 0, 0, 0, 184, 16),
(698, 0, 0, 0, 'Banana Bay 1', 450, 8, 0, 0, 0, 0, 25, 1),
(699, 0, 0, 0, 'Banana Bay 2', 765, 8, 0, 0, 0, 0, 36, 1),
(700, 0, 0, 0, 'Banana Bay 3', 450, 8, 0, 0, 0, 0, 25, 1),
(701, 0, 0, 0, 'Banana Bay 4', 450, 8, 0, 0, 0, 0, 25, 1),
(702, 0, 0, 0, 'Shark Manor', 8780, 8, 0, 0, 0, 0, 286, 15),
(703, 0, 0, 0, 'Coconut Quay 1', 1765, 8, 0, 0, 0, 0, 64, 2),
(704, 0, 0, 0, 'Coconut Quay 2', 1045, 8, 0, 0, 0, 0, 42, 2),
(705, 0, 0, 0, 'Coconut Quay 3', 2145, 8, 0, 0, 0, 0, 70, 4),
(706, 0, 0, 0, 'Coconut Quay 4', 2135, 8, 0, 0, 0, 0, 72, 3),
(707, 0, 0, 0, 'Crocodile Bridge 3', 1270, 8, 0, 0, 0, 0, 49, 2),
(708, 0, 0, 0, 'Crocodile Bridge 2', 865, 8, 0, 0, 0, 0, 36, 2),
(709, 0, 0, 0, 'Crocodile Bridge 1', 1045, 8, 0, 0, 0, 0, 42, 2),
(710, 0, 0, 0, 'Bamboo Garden 1', 1640, 8, 0, 0, 0, 0, 63, 3),
(711, 0, 0, 0, 'Crocodile Bridge 4', 4755, 8, 0, 0, 0, 0, 176, 4),
(712, 0, 0, 0, 'Crocodile Bridge 5', 3970, 8, 0, 0, 0, 0, 157, 2),
(713, 0, 0, 0, 'Woodway 1', 765, 8, 0, 0, 0, 0, 36, 1),
(714, 0, 0, 0, 'Woodway 2', 585, 8, 0, 0, 0, 0, 30, 1),
(715, 0, 0, 0, 'Woodway 3', 1540, 8, 0, 0, 0, 0, 65, 2),
(716, 0, 0, 0, 'Woodway 4', 405, 8, 0, 0, 0, 0, 24, 1),
(717, 0, 0, 0, 'Flamingo Flats 5', 1845, 8, 0, 0, 0, 0, 84, 1),
(718, 0, 0, 0, 'Bamboo Fortress', 21970, 8, 0, 0, 0, 0, 848, 20),
(719, 0, 0, 0, 'Bamboo Garden 3', 1540, 8, 0, 0, 0, 0, 63, 2),
(720, 0, 0, 0, 'Bamboo Garden 2', 1045, 8, 0, 0, 0, 0, 42, 2),
(721, 0, 0, 0, 'Flamingo Flats 4', 865, 8, 0, 0, 0, 0, 36, 2),
(722, 0, 0, 0, 'Flamingo Flats 2', 1045, 8, 0, 0, 0, 0, 42, 2),
(723, 0, 0, 0, 'Flamingo Flats 3', 685, 8, 0, 0, 0, 0, 30, 2),
(724, 0, 0, 0, 'Flamingo Flats 1', 685, 8, 0, 0, 0, 0, 30, 2),
(725, 0, 0, 0, 'Jungle Edge 4', 865, 8, 0, 0, 0, 0, 36, 2),
(726, 0, 0, 0, 'Jungle Edge 5', 865, 8, 0, 0, 0, 0, 36, 2),
(727, 0, 0, 0, 'Jungle Edge 6', 450, 8, 0, 0, 0, 0, 25, 1),
(728, 0, 0, 0, 'Jungle Edge 2', 3170, 8, 0, 0, 0, 0, 128, 3),
(729, 0, 0, 0, 'Jungle Edge 3', 865, 8, 0, 0, 0, 0, 36, 2),
(730, 0, 0, 0, 'Jungle Edge 1', 2495, 8, 0, 0, 0, 0, 98, 3),
(731, 0, 0, 0, 'Haggler\'s Hangout 6', 6450, 8, 0, 0, 0, 0, 208, 4),
(732, 0, 0, 0, 'Haggler\'s Hangout 5 (Shop)', 1550, 8, 0, 0, 0, 0, 56, 1),
(733, 0, 0, 0, 'Haggler\'s Hangout 4a (Shop)', 1850, 8, 0, 0, 0, 0, 56, 1),
(734, 0, 0, 0, 'Haggler\'s Hangout 4b (Shop)', 1550, 8, 0, 0, 0, 0, 56, 1),
(735, 0, 0, 0, 'Haggler\'s Hangout 3', 7550, 8, 0, 0, 0, 0, 256, 4),
(736, 0, 0, 0, 'Haggler\'s Hangout 2', 1300, 8, 0, 0, 0, 0, 49, 1),
(737, 0, 0, 0, 'Haggler\'s Hangout 1', 1400, 8, 0, 0, 0, 0, 49, 2),
(738, 0, 0, 0, 'River Homes 1', 3485, 8, 0, 0, 0, 0, 128, 3),
(739, 0, 0, 0, 'River Homes 2a', 1270, 8, 0, 0, 0, 0, 42, 2),
(740, 0, 0, 0, 'River Homes 2b', 1595, 8, 0, 0, 0, 0, 56, 3),
(741, 0, 0, 0, 'River Homes 3', 5055, 8, 0, 0, 0, 0, 176, 7),
(742, 0, 0, 0, 'The Treehouse', 24120, 8, 0, 0, 0, 0, 897, 23),
(743, 0, 0, 0, 'Corner Shop (Shop)', 2215, 12, 0, 0, 0, 0, 96, 2),
(744, 0, 0, 0, 'Tusk Flats 1', 765, 12, 0, 0, 0, 0, 40, 2),
(745, 0, 0, 0, 'Tusk Flats 2', 835, 12, 0, 0, 0, 0, 42, 2),
(746, 0, 0, 0, 'Tusk Flats 3', 660, 12, 0, 0, 0, 0, 34, 2),
(747, 0, 0, 0, 'Tusk Flats 4', 315, 12, 0, 0, 0, 0, 24, 1),
(748, 0, 0, 0, 'Tusk Flats 6', 660, 12, 0, 0, 0, 0, 35, 2),
(749, 0, 0, 0, 'Tusk Flats 5', 455, 12, 0, 0, 0, 0, 30, 1),
(750, 0, 0, 0, 'Shady Rocks 5', 2890, 12, 0, 0, 0, 0, 110, 2),
(751, 0, 0, 0, 'Shady Rocks 4 (Shop)', 2710, 12, 0, 0, 0, 0, 110, 2),
(752, 0, 0, 0, 'Shady Rocks 3', 4115, 12, 0, 0, 0, 0, 154, 3),
(753, 0, 0, 0, 'Shady Rocks 2', 2010, 12, 0, 0, 0, 0, 77, 4),
(754, 0, 0, 0, 'Shady Rocks 1', 3630, 12, 0, 0, 0, 0, 132, 4),
(755, 0, 0, 0, 'Crystal Glance', 19625, 12, 0, 0, 0, 0, 569, 24),
(756, 0, 0, 0, 'Arena Walk 3', 3550, 12, 0, 0, 0, 0, 126, 3),
(757, 0, 0, 0, 'Arena Walk 2', 1400, 12, 0, 0, 0, 0, 54, 2),
(758, 0, 0, 0, 'Arena Walk 1', 3250, 12, 0, 0, 0, 0, 128, 3),
(759, 0, 0, 0, 'Bears Paw 2', 2305, 12, 0, 0, 0, 0, 100, 2),
(760, 0, 0, 0, 'Bears Paw 1', 1810, 12, 0, 0, 0, 0, 72, 2),
(761, 0, 0, 0, 'Spirit Homes 5', 1450, 12, 0, 0, 0, 0, 56, 2),
(762, 0, 0, 0, 'Glacier Side 3', 1950, 12, 0, 0, 0, 0, 75, 2),
(763, 0, 0, 0, 'Glacier Side 2', 4750, 12, 0, 0, 0, 0, 154, 3),
(764, 0, 0, 0, 'Glacier Side 1', 1600, 12, 0, 0, 0, 0, 65, 2),
(765, 0, 0, 0, 'Spirit Homes 1', 1700, 12, 0, 0, 0, 0, 56, 2),
(766, 0, 0, 0, 'Spirit Homes 2', 1900, 12, 0, 0, 0, 0, 72, 2),
(767, 0, 0, 0, 'Spirit Homes 3', 4250, 12, 0, 0, 0, 0, 128, 3),
(768, 0, 0, 0, 'Spirit Homes 4', 1100, 12, 0, 0, 0, 0, 49, 1),
(770, 0, 0, 0, 'Glacier Side 4', 2050, 12, 0, 0, 0, 0, 75, 1),
(771, 0, 0, 0, 'Shelf Site', 4800, 12, 0, 0, 0, 0, 160, 3),
(772, 0, 0, 0, 'Raven Corner 1', 855, 12, 0, 0, 0, 0, 45, 1),
(773, 0, 0, 0, 'Raven Corner 2', 1685, 12, 0, 0, 0, 0, 60, 3),
(774, 0, 0, 0, 'Raven Corner 3', 855, 12, 0, 0, 0, 0, 45, 1),
(775, 0, 0, 0, 'Bears Paw 3', 2090, 12, 0, 0, 0, 0, 82, 3),
(776, 0, 0, 0, 'Bears Paw 4', 5205, 12, 0, 0, 0, 0, 189, 4),
(778, 0, 0, 0, 'Bears Paw 5', 2045, 12, 0, 0, 0, 0, 81, 3),
(779, 0, 0, 0, 'Trout Plaza 5 (Shop)', 3880, 12, 0, 0, 0, 0, 144, 2),
(780, 0, 0, 0, 'Pilchard Bin 1', 685, 12, 0, 0, 0, 0, 30, 2),
(781, 0, 0, 0, 'Pilchard Bin 2', 685, 12, 0, 0, 0, 0, 24, 2),
(782, 0, 0, 0, 'Pilchard Bin 3', 585, 12, 0, 0, 0, 0, 24, 1),
(783, 0, 0, 0, 'Pilchard Bin 4', 585, 12, 0, 0, 0, 0, 24, 1),
(784, 0, 0, 0, 'Pilchard Bin 5', 685, 12, 0, 0, 0, 0, 24, 2),
(785, 0, 0, 0, 'Pilchard Bin 10', 450, 12, 0, 0, 0, 0, 20, 1),
(786, 0, 0, 0, 'Pilchard Bin 9', 450, 12, 0, 0, 0, 0, 20, 1),
(787, 0, 0, 0, 'Pilchard Bin 8', 450, 12, 0, 0, 0, 0, 20, 2),
(789, 0, 0, 0, 'Pilchard Bin 7', 450, 12, 0, 0, 0, 0, 20, 1),
(790, 0, 0, 0, 'Pilchard Bin 6', 450, 12, 0, 0, 0, 0, 25, 1),
(791, 0, 0, 0, 'Trout Plaza 1', 2395, 12, 0, 0, 0, 0, 112, 2),
(792, 0, 0, 0, 'Trout Plaza 2', 1540, 12, 0, 0, 0, 0, 64, 2),
(793, 0, 0, 0, 'Trout Plaza 3', 900, 12, 0, 0, 0, 0, 36, 1),
(794, 0, 0, 0, 'Trout Plaza 4', 900, 12, 0, 0, 0, 0, 45, 1),
(795, 0, 0, 0, 'Skiffs End 1', 1540, 12, 0, 0, 0, 0, 70, 2),
(796, 0, 0, 0, 'Skiffs End 2', 910, 12, 0, 0, 0, 0, 42, 2),
(797, 0, 0, 0, 'Furrier Quarter 3', 1010, 12, 0, 0, 0, 0, 54, 2),
(798, 0, 0, 0, 'Mammoth Belly', 22810, 12, 0, 0, 0, 0, 634, 30),
(799, 0, 0, 0, 'Furrier Quarter 2', 1045, 12, 0, 0, 0, 0, 56, 2),
(800, 0, 0, 0, 'Furrier Quarter 1', 1635, 12, 0, 0, 0, 0, 84, 3),
(801, 0, 0, 0, 'Fimbul Shelf 3', 1255, 12, 0, 0, 0, 0, 66, 2),
(802, 0, 0, 0, 'Fimbul Shelf 4', 1045, 12, 0, 0, 0, 0, 56, 2),
(803, 0, 0, 0, 'Fimbul Shelf 2', 1045, 12, 0, 0, 0, 0, 56, 2),
(804, 0, 0, 0, 'Fimbul Shelf 1', 975, 12, 0, 0, 0, 0, 48, 2),
(805, 0, 0, 0, 'Frost Manor', 26370, 12, 0, 0, 0, 0, 806, 24),
(806, 0, 0, 0, 'Lower Barracks 11', 300, 3, 0, 0, 0, 0, 20, 1),
(807, 0, 0, 0, 'Lower Barracks 12', 300, 3, 0, 0, 0, 0, 16, 1),
(808, 0, 0, 0, 'Lower Barracks 9', 300, 3, 0, 0, 0, 0, 20, 1),
(809, 0, 0, 0, 'Lower Barracks 10', 300, 3, 0, 0, 0, 0, 19, 1),
(810, 0, 0, 0, 'Lower Barracks 7', 300, 3, 0, 0, 0, 0, 20, 1),
(811, 0, 0, 0, 'Lower Barracks 8', 300, 3, 0, 0, 0, 0, 16, 1),
(812, 0, 0, 0, 'Lower Barracks 5', 300, 3, 0, 0, 0, 0, 20, 1),
(813, 0, 0, 0, 'Lower Barracks 6', 300, 3, 0, 0, 0, 0, 16, 1),
(814, 0, 0, 0, 'Lower Barracks 3', 300, 3, 0, 0, 0, 0, 20, 1),
(815, 0, 0, 0, 'Lower Barracks 4', 300, 3, 0, 0, 0, 0, 19, 1),
(816, 0, 0, 0, 'Lower Barracks 1', 300, 3, 0, 0, 0, 0, 20, 1),
(817, 0, 0, 0, 'Lower Barracks 2', 300, 3, 0, 0, 0, 0, 16, 1),
(818, 0, 0, 0, 'Lower Barracks 24', 300, 3, 0, 0, 0, 0, 20, 1),
(819, 0, 0, 0, 'Lower Barracks 23', 300, 3, 0, 0, 0, 0, 16, 1),
(820, 0, 0, 0, 'Lower Barracks 22', 300, 3, 0, 0, 0, 0, 20, 1),
(821, 0, 0, 0, 'Lower Barracks 21', 300, 3, 0, 0, 0, 0, 16, 1),
(822, 0, 0, 0, 'Lower Barracks 20', 300, 3, 0, 0, 0, 0, 20, 1),
(823, 0, 0, 0, 'Lower Barracks 19', 300, 3, 0, 0, 0, 0, 16, 1),
(824, 0, 0, 0, 'Lower Barracks 18', 300, 3, 0, 0, 0, 0, 20, 1),
(825, 0, 0, 0, 'Lower Barracks 17', 300, 3, 0, 0, 0, 0, 16, 1),
(826, 0, 0, 0, 'Lower Barracks 16', 300, 3, 0, 0, 0, 0, 20, 1),
(828, 0, 0, 0, 'Lower Barracks 15', 300, 3, 0, 0, 0, 0, 16, 1),
(829, 0, 0, 0, 'Lower Barracks 14', 300, 3, 0, 0, 0, 0, 20, 1),
(830, 0, 0, 0, 'Lower Barracks 13', 300, 3, 0, 0, 0, 0, 16, 1),
(831, 0, 0, 0, 'Marble Guildhall', 16810, 3, 0, 0, 0, 0, 530, 17),
(832, 0, 0, 0, 'Iron Guildhall', 15560, 3, 0, 0, 0, 0, 464, 17),
(833, 0, 0, 0, 'The Market 1 (Shop)', 650, 3, 0, 0, 0, 0, 25, 1),
(834, 0, 0, 0, 'The Market 3 (Shop)', 1450, 3, 0, 0, 0, 0, 40, 1),
(835, 0, 0, 0, 'The Market 2 (Shop)', 1100, 3, 0, 0, 0, 0, 40, 1),
(836, 0, 0, 0, 'The Market 4 (Shop)', 1800, 3, 0, 0, 0, 0, 48, 1),
(837, 0, 0, 0, 'Granite Guildhall', 17845, 3, 0, 0, 0, 0, 530, 17),
(838, 0, 0, 0, 'Upper Barracks 01', 210, 3, 0, 0, 0, 0, 14, 1),
(839, 0, 0, 0, 'Upper Barracks 2', 210, 3, 0, 0, 0, 0, 15, 1),
(840, 0, 0, 0, 'Upper Barracks 3', 210, 3, 0, 0, 0, 0, 15, 1),
(841, 0, 0, 0, 'Upper Barracks 4', 210, 3, 0, 0, 0, 0, 15, 1),
(842, 0, 0, 0, 'Upper Barracks 5', 210, 3, 0, 0, 0, 0, 12, 1),
(843, 0, 0, 0, 'Upper Barracks 6', 210, 3, 0, 0, 0, 0, 12, 1),
(844, 0, 0, 0, 'Upper Barracks 7', 210, 3, 0, 0, 0, 0, 16, 1),
(845, 0, 0, 0, 'Upper Barracks 8', 210, 3, 0, 0, 0, 0, 20, 1),
(847, 0, 0, 0, 'Upper Barracks 10', 210, 3, 0, 0, 0, 0, 15, 1),
(848, 0, 0, 0, 'Upper Barracks 11', 210, 3, 0, 0, 0, 0, 15, 1),
(849, 0, 0, 0, 'Upper Barracks 12', 210, 3, 0, 0, 0, 0, 16, 1),
(850, 0, 0, 0, 'Upper Barracks 13', 580, 3, 0, 0, 0, 0, 24, 2),
(851, 0, 0, 0, 'Nobility Quarter 4', 765, 3, 0, 0, 0, 0, 25, 1),
(852, 0, 0, 0, 'Nobility Quarter 5', 765, 3, 0, 0, 0, 0, 25, 1),
(853, 0, 0, 0, 'Nobility Quarter 7', 765, 3, 0, 0, 0, 0, 25, 1),
(854, 0, 0, 0, 'Nobility Quarter 6', 765, 3, 0, 0, 0, 0, 26, 1),
(855, 0, 0, 0, 'Nobility Quarter 8', 765, 3, 0, 0, 0, 0, 26, 1),
(856, 0, 0, 0, 'Nobility Quarter 9', 765, 3, 0, 0, 0, 0, 26, 1),
(857, 0, 0, 0, 'Nobility Quarter 2', 1865, 3, 0, 0, 0, 0, 50, 3),
(858, 0, 0, 0, 'Nobility Quarter 3', 1865, 3, 0, 0, 0, 0, 50, 3),
(859, 0, 0, 0, 'Nobility Quarter 1', 1865, 3, 0, 0, 0, 0, 50, 3),
(863, 0, 0, 0, 'The Farms 6, Fishing Hut', 1255, 3, 0, 0, 0, 0, 32, 2),
(864, 0, 0, 0, 'The Farms 5', 1530, 3, 0, 0, 0, 0, 36, 2),
(865, 0, 0, 0, 'The Farms 4', 1530, 3, 0, 0, 0, 0, 36, 2),
(866, 0, 0, 0, 'The Farms 3', 1530, 3, 0, 0, 0, 0, 36, 2),
(867, 0, 0, 0, 'The Farms 2', 1530, 3, 0, 0, 0, 0, 36, 2),
(868, 0, 0, 0, 'The Farms 1', 2510, 3, 0, 0, 0, 0, 60, 3),
(869, 0, 0, 0, 'Outlaw Camp 12 (Shop)', 280, 3, 0, 0, 0, 0, 12, 0),
(870, 0, 0, 0, 'Outlaw Camp 13 (Shop)', 280, 3, 0, 0, 0, 0, 12, 0),
(871, 0, 0, 0, 'Outlaw Camp 14 (Shop)', 640, 3, 0, 0, 0, 0, 30, 0),
(872, 0, 0, 0, 'Outlaw Camp 7', 780, 3, 0, 0, 0, 0, 38, 2),
(874, 0, 0, 0, 'Outlaw Camp 8', 280, 3, 0, 0, 0, 0, 20, 1),
(877, 0, 0, 0, 'Outlaw Camp 9', 200, 3, 0, 0, 0, 0, 12, 1),
(878, 0, 0, 0, 'Outlaw Camp 10', 200, 3, 0, 0, 0, 0, 12, 1),
(879, 0, 0, 0, 'Outlaw Camp 11', 200, 3, 0, 0, 0, 0, 16, 1),
(880, 0, 0, 0, 'Outlaw Camp 2', 280, 3, 0, 0, 0, 0, 20, 1),
(881, 0, 0, 0, 'Outlaw Camp 3', 740, 3, 0, 0, 0, 0, 35, 2),
(882, 0, 0, 0, 'Outlaw Camp 4', 200, 3, 0, 0, 0, 0, 12, 1),
(883, 0, 0, 0, 'Outlaw Camp 5', 200, 3, 0, 0, 0, 0, 12, 1),
(884, 0, 0, 0, 'Outlaw Camp 6', 200, 3, 0, 0, 0, 0, 16, 1),
(885, 0, 0, 0, 'Outlaw Camp 1', 1660, 3, 0, 0, 0, 0, 91, 2),
(886, 0, 0, 0, 'Outlaw Castle', 8000, 3, 0, 0, 0, 0, 308, 9),
(888, 0, 0, 0, 'Tunnel Gardens 1', 1820, 3, 0, 0, 0, 0, 44, 3),
(889, 0, 0, 0, 'Tunnel Gardens 3', 2000, 3, 0, 0, 0, 0, 45, 3),
(890, 0, 0, 0, 'Tunnel Gardens 4', 2000, 3, 0, 0, 0, 0, 42, 3),
(891, 0, 0, 0, 'Tunnel Gardens 2', 1820, 3, 0, 0, 0, 0, 47, 3),
(892, 0, 0, 0, 'Tunnel Gardens 5', 1360, 3, 0, 0, 0, 0, 35, 2),
(893, 0, 0, 0, 'Tunnel Gardens 6', 1360, 3, 0, 0, 0, 0, 38, 2),
(894, 0, 0, 0, 'Tunnel Gardens 8', 1360, 3, 0, 0, 0, 0, 35, 2),
(895, 0, 0, 0, 'Tunnel Gardens 7', 1360, 3, 0, 0, 0, 0, 35, 2),
(896, 0, 0, 0, 'Tunnel Gardens 12', 1060, 3, 0, 0, 0, 0, 24, 2),
(897, 0, 0, 0, 'Tunnel Gardens 11', 1060, 3, 0, 0, 0, 0, 32, 2),
(898, 0, 0, 0, 'Tunnel Gardens 9', 1000, 3, 0, 0, 0, 0, 29, 2),
(899, 0, 0, 0, 'Tunnel Gardens 10', 1000, 3, 0, 0, 0, 0, 29, 2),
(900, 0, 0, 0, 'Wolftower', 21550, 3, 0, 0, 0, 0, 638, 23),
(901, 0, 0, 0, 'Paupers Palace, Flat 11', 315, 1, 0, 0, 0, 0, 12, 1),
(902, 0, 0, 0, 'Upper Barracks 9', 210, 3, 0, 0, 0, 0, 15, 1),
(905, 0, 0, 0, 'Botham I a', 950, 9, 0, 0, 0, 0, 36, 1),
(906, 0, 0, 0, 'Esuph I', 680, 9, 0, 0, 0, 0, 39, 1),
(907, 0, 0, 0, 'Esuph II b', 1380, 9, 0, 0, 0, 0, 51, 2),
(1883, 0, 0, 0, 'Aureate Court 1', 5240, 13, 0, 0, 0, 0, 276, 3),
(1884, 0, 0, 0, 'Aureate Court 2', 4860, 13, 0, 0, 0, 0, 198, 2),
(1885, 0, 0, 0, 'Aureate Court 3', 4300, 13, 0, 0, 0, 0, 226, 2),
(1886, 0, 0, 0, 'Aureate Court 4', 3980, 13, 0, 0, 0, 0, 208, 4),
(1887, 0, 0, 0, 'Fortune Wing 1', 10180, 13, 0, 0, 0, 0, 420, 4),
(1888, 0, 0, 0, 'Fortune Wing 2', 5580, 13, 0, 0, 0, 0, 260, 2),
(1889, 0, 0, 0, 'Fortune Wing 3', 5740, 13, 0, 0, 0, 0, 258, 2),
(1890, 0, 0, 0, 'Fortune Wing 4', 5740, 13, 0, 0, 0, 0, 305, 4),
(1891, 0, 0, 0, 'Luminous Arc 1', 6460, 13, 0, 0, 0, 0, 344, 2),
(1892, 0, 0, 0, 'Luminous Arc 2', 6460, 13, 0, 0, 0, 0, 301, 4),
(1893, 0, 0, 0, 'Luminous Arc 3', 5400, 13, 0, 0, 0, 0, 249, 3),
(1894, 173, 1605145931, 0, 'Luminous Arc 4', 8000, 13, 0, 0, 0, 0, 343, 5),
(1895, 0, 0, 0, 'Radiant Plaza 1', 5620, 13, 0, 0, 0, 0, 276, 4),
(1896, 0, 0, 0, 'Radiant Plaza 2', 3820, 13, 0, 0, 0, 0, 179, 2),
(1897, 0, 0, 0, 'Radiant Plaza 3', 4900, 13, 0, 0, 0, 0, 256, 2),
(1898, 0, 0, 0, 'Radiant Plaza 4', 7460, 13, 0, 0, 0, 0, 367, 3),
(1899, 0, 0, 0, 'Sun Palace', 23120, 13, 0, 0, 0, 0, 974, 27),
(1900, 0, 0, 0, 'Halls of Serenity', 23360, 13, 0, 0, 0, 0, 1090, 33),
(1901, 0, 0, 0, 'Cascade Towers', 19500, 13, 0, 0, 0, 0, 810, 33),
(1902, 0, 0, 0, 'Sorcerer\'s Avenue 5', 2695, 2, 0, 0, 0, 0, 96, 1),
(1903, 0, 0, 0, 'Sorcerer\'s Avenue 1a', 1255, 2, 0, 0, 0, 0, 42, 2),
(1904, 0, 0, 0, 'Sorcerer\'s Avenue 1b', 1035, 2, 0, 0, 0, 0, 36, 2),
(1905, 0, 0, 0, 'Sorcerer\'s Avenue 1c', 1255, 2, 0, 0, 0, 0, 36, 2),
(1906, 0, 0, 0, 'Beach Home Apartments, Flat 06', 1145, 2, 0, 0, 0, 0, 40, 2),
(1907, 0, 0, 0, 'Beach Home Apartments, Flat 01', 715, 2, 0, 0, 0, 0, 30, 1),
(1908, 0, 0, 0, 'Beach Home Apartments, Flat 02', 715, 2, 0, 0, 0, 0, 25, 1),
(1909, 0, 0, 0, 'Beach Home Apartments, Flat 03', 715, 2, 0, 0, 0, 0, 30, 1),
(1910, 0, 0, 0, 'Beach Home Apartments, Flat 04', 715, 2, 0, 0, 0, 0, 24, 1),
(1911, 0, 0, 0, 'Beach Home Apartments, Flat 05', 715, 2, 0, 0, 0, 0, 24, 1),
(1912, 0, 0, 0, 'Beach Home Apartments, Flat 16', 1145, 2, 0, 0, 0, 0, 40, 2),
(1913, 0, 0, 0, 'Beach Home Apartments, Flat 11', 715, 2, 0, 0, 0, 0, 30, 1),
(1914, 0, 0, 0, 'Beach Home Apartments, Flat 12', 880, 2, 0, 0, 0, 0, 30, 1),
(1915, 0, 0, 0, 'Beach Home Apartments, Flat 13', 880, 2, 0, 0, 0, 0, 29, 1),
(1916, 0, 0, 0, 'Beach Home Apartments, Flat 14', 385, 2, 0, 0, 0, 0, 15, 1),
(1917, 0, 0, 0, 'Beach Home Apartments, Flat 15', 385, 2, 0, 0, 0, 0, 15, 1),
(1918, 0, 0, 0, 'Thais Clanhall', 8420, 2, 0, 0, 0, 0, 366, 10),
(1919, 0, 0, 0, 'Harbour Street 4', 935, 2, 0, 0, 0, 0, 30, 1),
(1920, 0, 0, 0, 'Thais Hostel', 6980, 2, 0, 0, 0, 0, 171, 24),
(1921, 0, 0, 0, 'Lower Swamp Lane 1', 4740, 2, 0, 0, 0, 0, 166, 4),
(1923, 0, 0, 0, 'Lower Swamp Lane 3', 4740, 2, 0, 0, 0, 0, 161, 4),
(1924, 0, 0, 0, 'Sunset Homes, Flat 01', 520, 2, 0, 0, 0, 0, 25, 1),
(1925, 0, 0, 0, 'Sunset Homes, Flat 02', 520, 2, 0, 0, 0, 0, 30, 1),
(1926, 0, 0, 0, 'Sunset Homes, Flat 03', 520, 2, 0, 0, 0, 0, 30, 1),
(1927, 0, 0, 0, 'Sunset Homes, Flat 14', 520, 2, 0, 0, 0, 0, 30, 1),
(1929, 0, 0, 0, 'Sunset Homes, Flat 13', 860, 2, 0, 0, 0, 0, 35, 2),
(1930, 0, 0, 0, 'Sunset Homes, Flat 12', 520, 2, 0, 0, 0, 0, 25, 1),
(1932, 0, 0, 0, 'Sunset Homes, Flat 11', 520, 2, 0, 0, 0, 0, 25, 1),
(1935, 0, 0, 0, 'Sunset Homes, Flat 24', 520, 2, 0, 0, 0, 0, 30, 1),
(1936, 0, 0, 0, 'Sunset Homes, Flat 23', 860, 2, 0, 0, 0, 0, 35, 2),
(1937, 0, 0, 0, 'Sunset Homes, Flat 22', 520, 2, 0, 0, 0, 0, 25, 1),
(1938, 0, 0, 0, 'Sunset Homes, Flat 21', 520, 2, 0, 0, 0, 0, 25, 1),
(1939, 168, 1604950460, 0, 'Harbour Place 1 (Shop)', 1100, 2, 0, 0, 0, 0, 37, 1),
(1940, 0, 1604763320, 0, 'Harbour Place 2 (Shop)', 1300, 2, 0, 0, 0, 0, 48, 1),
(1941, 180, 1605145931, 0, 'Warriors Guildhall', 14725, 2, 0, 0, 0, 0, 522, 11),
(1942, 0, 0, 0, 'Farm Lane, 1st floor (Shop)', 945, 2, 0, 0, 0, 0, 42, 0),
(1943, 0, 0, 0, 'Farm Lane, Basement (Shop)', 945, 2, 0, 0, 0, 0, 36, 0),
(1944, 190, 1604950460, 0, 'Main Street 9, 1st floor (Shop)', 1440, 2, 0, 0, 0, 0, 47, 0),
(1945, 0, 0, 0, 'Main Street 9a, 2nd floor (Shop)', 765, 2, 0, 0, 0, 0, 30, 0),
(1946, 0, 0, 0, 'Main Street 9b, 2nd floor (Shop)', 1260, 2, 0, 0, 0, 0, 48, 0),
(1947, 0, 0, 0, 'Farm Lane, 2nd Floor (Shop)', 945, 2, 0, 0, 0, 0, 42, 0),
(1948, 0, 0, 0, 'The City Wall 5a', 585, 2, 0, 0, 0, 0, 24, 1),
(1949, 0, 0, 0, 'The City Wall 5c', 585, 2, 0, 0, 0, 0, 24, 1),
(1950, 0, 0, 0, 'The City Wall 5e', 585, 2, 0, 0, 0, 0, 30, 1),
(1951, 0, 0, 0, 'The City Wall 5b', 585, 2, 0, 0, 0, 0, 24, 1),
(1952, 0, 0, 0, 'The City Wall 5d', 585, 2, 0, 0, 0, 0, 24, 1),
(1953, 0, 0, 0, 'The City Wall 5f', 585, 2, 0, 0, 0, 0, 30, 1),
(1954, 0, 0, 0, 'The City Wall 3a', 1045, 2, 0, 0, 0, 0, 42, 2),
(1955, 0, 0, 0, 'The City Wall 3b', 1045, 2, 0, 0, 0, 0, 35, 2),
(1956, 0, 0, 0, 'The City Wall 3c', 1045, 2, 0, 0, 0, 0, 35, 2),
(1957, 0, 0, 0, 'The City Wall 3d', 1045, 2, 0, 0, 0, 0, 41, 2),
(1958, 0, 0, 0, 'The City Wall 3e', 1045, 2, 0, 0, 0, 0, 30, 2),
(1959, 0, 0, 0, 'The City Wall 3f', 1045, 2, 0, 0, 0, 0, 31, 2),
(1960, 0, 0, 0, 'The City Wall 1a', 1270, 2, 0, 0, 0, 0, 49, 2),
(1961, 0, 0, 0, 'Mill Avenue 3', 1400, 2, 0, 0, 0, 0, 49, 2),
(1962, 0, 0, 0, 'The City Wall 1b', 1270, 2, 0, 0, 0, 0, 49, 2),
(1963, 0, 0, 0, 'Mill Avenue 4', 1400, 2, 0, 0, 0, 0, 49, 2),
(1964, 0, 0, 0, 'Mill Avenue 5', 3250, 2, 0, 0, 0, 0, 128, 4),
(1965, 0, 0, 0, 'Mill Avenue 1 (Shop)', 1300, 2, 0, 0, 0, 0, 54, 1),
(1966, 0, 0, 0, 'Mill Avenue 2 (Shop)', 2350, 2, 0, 0, 0, 0, 80, 2),
(1967, 0, 0, 0, 'The City Wall 7c', 865, 2, 0, 0, 0, 0, 36, 2),
(1968, 0, 0, 0, 'The City Wall 7a', 585, 2, 0, 0, 0, 0, 30, 1),
(1969, 0, 0, 0, 'The City Wall 7e', 865, 2, 0, 0, 0, 0, 36, 2),
(1970, 0, 0, 0, 'The City Wall 7g', 585, 2, 0, 0, 0, 0, 30, 1),
(1971, 0, 0, 0, 'The City Wall 7d', 865, 2, 0, 0, 0, 0, 36, 2),
(1972, 0, 0, 0, 'The City Wall 7b', 585, 2, 0, 0, 0, 0, 30, 1),
(1973, 0, 0, 0, 'The City Wall 7f', 865, 2, 0, 0, 0, 0, 35, 2),
(1974, 0, 0, 0, 'The City Wall 7h', 585, 2, 0, 0, 0, 0, 30, 1),
(1975, 0, 0, 0, 'The City Wall 9', 955, 2, 0, 0, 0, 0, 50, 2),
(1976, 0, 0, 0, 'Upper Swamp Lane 12', 3800, 2, 0, 0, 0, 0, 116, 3),
(1977, 0, 0, 0, 'Upper Swamp Lane 10', 2060, 2, 0, 0, 0, 0, 70, 3),
(1978, 0, 0, 0, 'Upper Swamp Lane 8', 8120, 2, 0, 0, 0, 0, 216, 3),
(1979, 0, 0, 0, 'Southern Thais Guildhall', 22440, 2, 0, 0, 0, 0, 596, 16),
(1980, 0, 0, 0, 'Alai Flats, Flat 04', 765, 2, 0, 0, 0, 0, 30, 1),
(1981, 0, 0, 0, 'Alai Flats, Flat 05', 1225, 2, 0, 0, 0, 0, 38, 2),
(1982, 0, 0, 0, 'Alai Flats, Flat 06', 1225, 2, 0, 0, 0, 0, 48, 2),
(1983, 0, 0, 0, 'Alai Flats, Flat 07', 765, 2, 0, 0, 0, 0, 30, 1),
(1984, 0, 0, 0, 'Alai Flats, Flat 08', 765, 2, 0, 0, 0, 0, 30, 1),
(1985, 0, 0, 0, 'Alai Flats, Flat 03', 765, 2, 0, 0, 0, 0, 36, 1),
(1986, 0, 0, 0, 'Alai Flats, Flat 01', 765, 2, 0, 0, 0, 0, 26, 1),
(1987, 0, 0, 0, 'Alai Flats, Flat 02', 765, 2, 0, 0, 0, 0, 34, 1),
(1988, 0, 0, 0, 'Alai Flats, Flat 14', 900, 2, 0, 0, 0, 0, 33, 1),
(1989, 0, 0, 0, 'Alai Flats, Flat 15', 1450, 2, 0, 0, 0, 0, 48, 2),
(1990, 0, 0, 0, 'Alai Flats, Flat 16', 1450, 2, 0, 0, 0, 0, 54, 2),
(1991, 0, 0, 0, 'Alai Flats, Flat 17', 900, 2, 0, 0, 0, 0, 38, 1),
(1992, 0, 0, 0, 'Alai Flats, Flat 18', 900, 2, 0, 0, 0, 0, 38, 1),
(1993, 0, 0, 0, 'Alai Flats, Flat 13', 765, 2, 0, 0, 0, 0, 36, 1),
(1994, 0, 0, 0, 'Alai Flats, Flat 12', 765, 2, 0, 0, 0, 0, 25, 1),
(1995, 0, 0, 0, 'Alai Flats, Flat 11', 765, 2, 0, 0, 0, 0, 35, 1),
(1996, 0, 0, 0, 'Alai Flats, Flat 24', 900, 2, 0, 0, 0, 0, 36, 1),
(1997, 0, 0, 0, 'Alai Flats, Flat 25', 1450, 2, 0, 0, 0, 0, 52, 2),
(1998, 0, 0, 0, 'Alai Flats, Flat 26', 1450, 2, 0, 0, 0, 0, 60, 2),
(1999, 0, 0, 0, 'Alai Flats, Flat 27', 900, 2, 0, 0, 0, 0, 38, 1),
(2000, 0, 0, 0, 'Alai Flats, Flat 28', 900, 2, 0, 0, 0, 0, 38, 1),
(2001, 0, 0, 0, 'Alai Flats, Flat 23', 765, 2, 0, 0, 0, 0, 35, 1),
(2002, 0, 0, 0, 'Alai Flats, Flat 22', 765, 2, 0, 0, 0, 0, 25, 1),
(2003, 0, 0, 0, 'Alai Flats, Flat 21', 765, 2, 0, 0, 0, 0, 36, 1),
(2004, 0, 0, 0, 'Upper Swamp Lane 4', 4740, 2, 0, 0, 0, 0, 165, 4),
(2005, 0, 0, 0, 'Upper Swamp Lane 2', 4740, 2, 0, 0, 0, 0, 159, 4),
(2006, 0, 0, 0, 'Sorcerer\'s Avenue Labs 2c', 715, 2, 0, 0, 0, 0, 20, 1),
(2007, 0, 0, 0, 'Sorcerer\'s Avenue Labs 2d', 715, 2, 0, 0, 0, 0, 20, 1),
(2008, 0, 0, 0, 'Sorcerer\'s Avenue Labs 2e', 715, 2, 0, 0, 0, 0, 20, 1),
(2009, 0, 0, 0, 'Sorcerer\'s Avenue Labs 2f', 715, 2, 0, 0, 0, 0, 20, 1),
(2010, 0, 0, 0, 'Sorcerer\'s Avenue Labs 2b', 715, 2, 0, 0, 0, 0, 24, 1),
(2011, 0, 0, 0, 'Sorcerer\'s Avenue Labs 2a', 715, 2, 0, 0, 0, 0, 24, 1),
(2012, 0, 0, 0, 'Ivory Circle 1', 4280, 7, 0, 0, 0, 0, 160, 2),
(2013, 0, 0, 0, 'Admiral\'s Avenue 3', 4115, 7, 0, 0, 0, 0, 142, 2),
(2014, 0, 0, 0, 'Admiral\'s Avenue 2', 5470, 7, 0, 0, 0, 0, 176, 4),
(2015, 0, 0, 0, 'Admiral\'s Avenue 1', 5105, 7, 0, 0, 0, 0, 168, 2),
(2016, 0, 0, 0, 'Sugar Street 5', 1350, 7, 0, 0, 0, 0, 48, 2),
(2017, 0, 0, 0, 'Freedom Street 1', 2450, 7, 0, 0, 0, 0, 84, 2),
(2018, 0, 0, 0, 'Freedom Street 2', 6050, 7, 0, 0, 0, 0, 208, 4),
(2019, 0, 0, 0, 'Trader\'s Point 2 (Shop)', 5350, 7, 0, 0, 0, 0, 198, 2),
(2020, 0, 0, 0, 'Trader\'s Point 3 (Shop)', 5950, 7, 0, 0, 0, 0, 195, 2),
(2021, 0, 0, 0, 'Ivory Circle 2', 7030, 7, 0, 0, 0, 0, 214, 2),
(2022, 0, 0, 0, 'The Tavern 1a', 2750, 7, 0, 0, 0, 0, 72, 4),
(2023, 0, 0, 0, 'The Tavern 1b', 1900, 7, 0, 0, 0, 0, 54, 2),
(2024, 0, 0, 0, 'The Tavern 1c', 4150, 7, 0, 0, 0, 0, 132, 3),
(2025, 0, 0, 0, 'The Tavern 1d', 1550, 7, 0, 0, 0, 0, 48, 2),
(2026, 0, 0, 0, 'The Tavern 2d', 1350, 7, 0, 0, 0, 0, 40, 2),
(2027, 0, 0, 0, 'The Tavern 2c', 950, 7, 0, 0, 0, 0, 32, 1),
(2028, 0, 0, 0, 'The Tavern 2b', 1700, 7, 0, 0, 0, 0, 62, 2),
(2029, 0, 0, 0, 'The Tavern 2a', 5550, 7, 0, 0, 0, 0, 163, 5),
(2030, 0, 0, 0, 'Straycat\'s Corner 4', 210, 7, 0, 0, 0, 0, 20, 1),
(2031, 0, 0, 0, 'Straycat\'s Corner 3', 210, 7, 0, 0, 0, 0, 20, 1),
(2032, 0, 0, 0, 'Straycat\'s Corner 2', 660, 7, 0, 0, 0, 0, 49, 1),
(2033, 0, 0, 0, 'Litter Promenade 5', 580, 7, 0, 0, 0, 0, 35, 2),
(2034, 0, 0, 0, 'Litter Promenade 4', 390, 7, 0, 0, 0, 0, 30, 1),
(2035, 0, 0, 0, 'Litter Promenade 3', 450, 7, 0, 0, 0, 0, 36, 1),
(2036, 0, 0, 0, 'Litter Promenade 2', 300, 7, 0, 0, 0, 0, 25, 1),
(2037, 0, 0, 0, 'Litter Promenade 1', 400, 7, 0, 0, 0, 0, 25, 2),
(2038, 0, 0, 0, 'The Shelter', 13590, 7, 0, 0, 0, 0, 560, 31),
(2039, 0, 0, 0, 'Straycat\'s Corner 6', 300, 7, 0, 0, 0, 0, 25, 1),
(2040, 0, 0, 0, 'Straycat\'s Corner 5', 760, 7, 0, 0, 0, 0, 48, 2),
(2042, 0, 0, 0, 'Rum Alley 3', 330, 7, 0, 0, 0, 0, 28, 1),
(2043, 0, 0, 0, 'Straycat\'s Corner 1', 300, 7, 0, 0, 0, 0, 25, 1),
(2044, 0, 0, 0, 'Rum Alley 2', 300, 7, 0, 0, 0, 0, 25, 1),
(2045, 0, 0, 0, 'Rum Alley 1', 510, 7, 0, 0, 0, 0, 36, 1),
(2046, 0, 0, 0, 'Smuggler Backyard 3', 700, 7, 0, 0, 0, 0, 40, 2),
(2048, 0, 0, 0, 'Shady Trail 3', 300, 7, 0, 0, 0, 0, 25, 1),
(2049, 0, 0, 0, 'Shady Trail 1', 1150, 7, 0, 0, 0, 0, 48, 5),
(2050, 0, 0, 0, 'Shady Trail 2', 490, 7, 0, 0, 0, 0, 30, 2),
(2051, 0, 0, 0, 'Smuggler Backyard 5', 610, 7, 0, 0, 0, 0, 35, 2),
(2052, 0, 0, 0, 'Smuggler Backyard 4', 390, 7, 0, 0, 0, 0, 30, 1),
(2053, 0, 0, 0, 'Smuggler Backyard 2', 670, 7, 0, 0, 0, 0, 40, 2),
(2054, 0, 0, 0, 'Smuggler Backyard 1', 670, 7, 0, 0, 0, 0, 40, 2),
(2055, 0, 0, 0, 'Sugar Street 2', 2550, 7, 0, 0, 0, 0, 84, 3),
(2056, 0, 0, 0, 'Sugar Street 1', 3000, 7, 0, 0, 0, 0, 84, 3),
(2057, 0, 0, 0, 'Sugar Street 3a', 1650, 7, 0, 0, 0, 0, 54, 3),
(2058, 0, 0, 0, 'Sugar Street 3b', 2050, 7, 0, 0, 0, 0, 60, 3),
(2059, 0, 0, 0, 'Harvester\'s Haven, Flat 01', 950, 7, 0, 0, 0, 0, 36, 2),
(2060, 0, 0, 0, 'Harvester\'s Haven, Flat 03', 950, 7, 0, 0, 0, 0, 30, 2),
(2061, 0, 0, 0, 'Harvester\'s Haven, Flat 05', 950, 7, 0, 0, 0, 0, 30, 2),
(2062, 0, 0, 0, 'Harvester\'s Haven, Flat 02', 950, 7, 0, 0, 0, 0, 36, 2),
(2063, 0, 0, 0, 'Harvester\'s Haven, Flat 04', 950, 7, 0, 0, 0, 0, 30, 2),
(2064, 0, 0, 0, 'Harvester\'s Haven, Flat 06', 950, 7, 0, 0, 0, 0, 30, 2),
(2065, 0, 0, 0, 'Harvester\'s Haven, Flat 07', 950, 7, 0, 0, 0, 0, 30, 2),
(2066, 0, 0, 0, 'Harvester\'s Haven, Flat 09', 950, 7, 0, 0, 0, 0, 30, 2),
(2067, 0, 0, 0, 'Harvester\'s Haven, Flat 11', 950, 7, 0, 0, 0, 0, 36, 2),
(2068, 0, 0, 0, 'Harvester\'s Haven, Flat 12', 950, 7, 0, 0, 0, 0, 36, 2),
(2069, 0, 0, 0, 'Harvester\'s Haven, Flat 10', 950, 7, 0, 0, 0, 0, 30, 2),
(2070, 0, 0, 0, 'Harvester\'s Haven, Flat 08', 950, 7, 0, 0, 0, 0, 30, 2),
(2071, 0, 0, 0, 'Marble Lane 4', 6350, 7, 0, 0, 0, 0, 192, 4),
(2072, 0, 0, 0, 'Marble Lane 2', 6415, 7, 0, 0, 0, 0, 200, 3),
(2073, 0, 0, 0, 'Marble Lane 3', 8055, 7, 0, 0, 0, 0, 240, 4),
(2074, 0, 0, 0, 'Marble Lane 1', 11060, 7, 0, 0, 0, 0, 320, 6),
(2075, 0, 0, 0, 'Ivy Cottage', 30650, 7, 0, 0, 0, 0, 858, 26),
(2076, 0, 0, 0, 'Sugar Street 4d', 750, 7, 0, 0, 0, 0, 24, 2),
(2077, 0, 0, 0, 'Sugar Street 4c', 650, 7, 0, 0, 0, 0, 24, 1),
(2078, 0, 0, 0, 'Sugar Street 4b', 950, 7, 0, 0, 0, 0, 36, 2),
(2079, 0, 0, 0, 'Sugar Street 4a', 950, 7, 0, 0, 0, 0, 30, 2),
(2080, 0, 0, 0, 'Trader\'s Point 1', 2200, 7, 0, 0, 0, 0, 77, 2),
(2081, 0, 0, 0, 'Mountain Hideout', 15550, 7, 0, 0, 0, 0, 486, 17),
(2082, 0, 0, 0, 'Dark Mansion', 17845, 2, 0, 0, 0, 0, 573, 17),
(2083, 0, 0, 0, 'Halls of the Adventurers', 15380, 2, 0, 0, 0, 0, 518, 18),
(2084, 0, 0, 0, 'Castle of Greenshore', 18860, 2, 0, 0, 0, 0, 600, 12),
(2085, 0, 0, 0, 'Greenshore Clanhall', 10800, 2, 0, 0, 0, 0, 312, 10),
(2086, 0, 0, 0, 'Greenshore Village 1', 2420, 2, 0, 0, 0, 0, 64, 3),
(2087, 0, 0, 0, 'Greenshore Village, Shop', 1800, 2, 0, 0, 0, 0, 56, 1),
(2088, 0, 0, 0, 'Greenshore Village, Villa', 8700, 2, 0, 0, 0, 0, 263, 4),
(2089, 0, 0, 0, 'Greenshore Village 2', 780, 2, 0, 0, 0, 0, 30, 1),
(2090, 0, 0, 0, 'Greenshore Village 3', 780, 2, 0, 0, 0, 0, 25, 1),
(2091, 0, 0, 0, 'Greenshore Village 5', 780, 2, 0, 0, 0, 0, 30, 1),
(2092, 0, 0, 0, 'Greenshore Village 4', 780, 2, 0, 0, 0, 0, 25, 1),
(2093, 0, 0, 0, 'Greenshore Village 6', 4360, 2, 0, 0, 0, 0, 118, 2),
(2094, 0, 0, 0, 'Greenshore Village 7', 1260, 2, 0, 0, 0, 0, 42, 1),
(2095, 0, 0, 0, 'The Tibianic', 34500, 2, 0, 0, 0, 0, 862, 22),
(2097, 0, 0, 0, 'Fibula Village 5', 1790, 2, 0, 0, 0, 0, 42, 2),
(2098, 0, 0, 0, 'Fibula Village 4', 1790, 2, 0, 0, 0, 0, 42, 2),
(2099, 0, 0, 0, 'Fibula Village, Tower Flat', 5105, 2, 0, 0, 0, 0, 161, 2),
(2100, 0, 0, 0, 'Fibula Village 1', 845, 2, 0, 0, 0, 0, 30, 1),
(2101, 0, 0, 0, 'Fibula Village 2', 845, 2, 0, 0, 0, 0, 30, 1),
(2102, 0, 0, 0, 'Fibula Village 3', 3810, 2, 0, 0, 0, 0, 110, 4),
(2103, 0, 0, 0, 'Mercenary Tower', 41955, 2, 0, 0, 0, 0, 996, 26),
(2104, 0, 0, 0, 'Guildhall of the Red Rose', 27725, 2, 0, 0, 0, 0, 571, 15),
(2105, 0, 0, 0, 'Fibula Village, Bar', 5235, 2, 0, 0, 0, 0, 122, 2),
(2106, 0, 0, 0, 'Fibula Village, Villa', 11490, 2, 0, 0, 0, 0, 402, 5),
(2107, 0, 0, 0, 'Fibula Clanhall', 11430, 2, 0, 0, 0, 0, 290, 10),
(2108, 0, 0, 0, 'Spiritkeep', 19210, 2, 0, 0, 0, 0, 783, 23),
(2109, 165, 1605017925, 0, 'Snake Tower', 29720, 2, 0, 0, 0, 0, 1064, 21),
(2110, 0, 0, 0, 'Bloodhall', 15270, 2, 0, 0, 0, 0, 569, 15),
(2111, 0, 0, 0, 'Senja Clanhall', 10575, 4, 0, 0, 0, 0, 396, 9),
(2112, 0, 0, 0, 'Senja Village 2', 765, 4, 0, 0, 0, 0, 36, 1),
(2113, 0, 0, 0, 'Senja Village 1a', 765, 4, 0, 0, 0, 0, 36, 1),
(2114, 0, 0, 0, 'Senja Village 1b', 1630, 4, 0, 0, 0, 0, 66, 2),
(2115, 0, 0, 0, 'Senja Village 4', 765, 4, 0, 0, 0, 0, 30, 1),
(2116, 0, 0, 0, 'Senja Village 3', 1765, 4, 0, 0, 0, 0, 72, 2),
(2117, 0, 0, 0, 'Senja Village 6b', 765, 4, 0, 0, 0, 0, 30, 1),
(2118, 0, 0, 0, 'Senja Village 6a', 765, 4, 0, 0, 0, 0, 30, 1),
(2119, 0, 0, 0, 'Senja Village 5', 1225, 4, 0, 0, 0, 0, 48, 2),
(2120, 0, 0, 0, 'Senja Village 10', 1485, 4, 0, 0, 0, 0, 72, 1),
(2121, 0, 0, 0, 'Senja Village 11', 2620, 4, 0, 0, 0, 0, 96, 2),
(2122, 0, 0, 0, 'Senja Village 9', 2575, 4, 0, 0, 0, 0, 103, 2),
(2123, 0, 0, 0, 'Senja Village 8', 1675, 4, 0, 0, 0, 0, 57, 2),
(2124, 0, 0, 0, 'Senja Village 7', 865, 4, 0, 0, 0, 0, 37, 2),
(2125, 0, 0, 0, 'Rosebud C', 1340, 4, 0, 0, 0, 0, 70, 0),
(2127, 0, 0, 0, 'Rosebud A', 1000, 4, 0, 0, 0, 0, 60, 1),
(2128, 0, 0, 0, 'Rosebud B', 1000, 4, 0, 0, 0, 0, 60, 1),
(2129, 0, 0, 0, 'Nordic Stronghold', 18400, 4, 0, 0, 0, 0, 718, 21),
(2130, 0, 0, 0, 'Northport Village 2', 1475, 4, 0, 0, 0, 0, 40, 2),
(2131, 0, 0, 0, 'Northport Village 1', 1475, 4, 0, 0, 0, 0, 48, 2),
(2132, 0, 0, 0, 'Northport Village 3', 5435, 4, 0, 0, 0, 0, 178, 2),
(2133, 0, 0, 0, 'Northport Village 4', 2630, 4, 0, 0, 0, 0, 81, 2),
(2134, 0, 0, 0, 'Northport Village 5', 1805, 4, 0, 0, 0, 0, 56, 2),
(2135, 0, 0, 0, 'Northport Village 6', 2135, 4, 0, 0, 0, 0, 64, 2),
(2136, 0, 0, 0, 'Seawatch', 25010, 4, 0, 0, 0, 0, 749, 19),
(2137, 0, 0, 0, 'Northport Clanhall', 9810, 4, 0, 0, 0, 0, 292, 10),
(2138, 0, 0, 0, 'Druids Retreat D', 1180, 4, 0, 0, 0, 0, 54, 2),
(2139, 0, 0, 0, 'Druids Retreat A', 1340, 4, 0, 0, 0, 0, 60, 2),
(2140, 0, 0, 0, 'Druids Retreat C', 980, 4, 0, 0, 0, 0, 45, 2),
(2141, 0, 0, 0, 'Druids Retreat B', 980, 4, 0, 0, 0, 0, 55, 2),
(2142, 0, 0, 0, 'Theater Avenue 14 (Shop)', 2115, 4, 0, 0, 0, 0, 83, 1),
(2143, 0, 0, 0, 'Theater Avenue 12', 955, 4, 0, 0, 0, 0, 28, 2),
(2144, 0, 0, 0, 'Theater Avenue 10', 1090, 4, 0, 0, 0, 0, 45, 2),
(2145, 0, 0, 0, 'Theater Avenue 11c', 585, 4, 0, 0, 0, 0, 24, 1),
(2146, 0, 0, 0, 'Theater Avenue 11b', 585, 4, 0, 0, 0, 0, 24, 1),
(2147, 0, 0, 0, 'Theater Avenue 11a', 1405, 4, 0, 0, 0, 0, 54, 2),
(2148, 0, 0, 0, 'Magician\'s Alley 1', 1050, 4, 0, 0, 0, 0, 35, 2),
(2149, 0, 0, 0, 'Magician\'s Alley 1a', 700, 4, 0, 0, 0, 0, 29, 2),
(2150, 0, 0, 0, 'Magician\'s Alley 1d', 450, 4, 0, 0, 0, 0, 24, 1),
(2151, 0, 0, 0, 'Magician\'s Alley 1b', 750, 4, 0, 0, 0, 0, 24, 2),
(2152, 0, 0, 0, 'Magician\'s Alley 1c', 500, 4, 0, 0, 0, 0, 20, 1),
(2153, 0, 0, 0, 'Magician\'s Alley 5a', 350, 4, 0, 0, 0, 0, 14, 1),
(2154, 0, 0, 0, 'Magician\'s Alley 5b', 500, 4, 0, 0, 0, 0, 25, 1),
(2155, 0, 0, 0, 'Magician\'s Alley 5d', 500, 4, 0, 0, 0, 0, 20, 1),
(2156, 0, 0, 0, 'Magician\'s Alley 5e', 500, 4, 0, 0, 0, 0, 25, 1),
(2157, 0, 0, 0, 'Magician\'s Alley 5c', 1150, 4, 0, 0, 0, 0, 35, 2),
(2158, 0, 0, 0, 'Magician\'s Alley 5f', 1150, 4, 0, 0, 0, 0, 42, 2),
(2159, 0, 0, 0, 'Carlin Clanhall', 10750, 4, 0, 0, 0, 0, 364, 10),
(2160, 0, 0, 0, 'Magician\'s Alley 4', 2750, 4, 0, 0, 0, 0, 96, 4),
(2161, 0, 0, 0, 'Lonely Sea Side Hostel', 10540, 4, 0, 0, 0, 0, 454, 8),
(2162, 0, 0, 0, 'Suntower', 10080, 4, 0, 0, 0, 0, 450, 7),
(2163, 0, 1604950460, 0, 'Harbour Lane 3', 3560, 4, 0, 0, 0, 0, 145, 3),
(2164, 0, 0, 0, 'Harbour Flats, Flat 11', 520, 4, 0, 0, 0, 0, 24, 1),
(2165, 0, 0, 0, 'Harbour Flats, Flat 13', 520, 4, 0, 0, 0, 0, 24, 1),
(2166, 0, 0, 0, 'Harbour Flats, Flat 15', 360, 4, 0, 0, 0, 0, 18, 1),
(2167, 0, 0, 0, 'Harbour Flats, Flat 17', 360, 4, 0, 0, 0, 0, 24, 1),
(2168, 0, 0, 0, 'Harbour Flats, Flat 12', 400, 4, 0, 0, 0, 0, 20, 1);
INSERT INTO `houses` (`id`, `owner`, `paid`, `warnings`, `name`, `rent`, `town_id`, `bid`, `bid_end`, `last_bid`, `highest_bidder`, `size`, `beds`) VALUES
(2169, 0, 0, 0, 'Harbour Flats, Flat 14', 400, 4, 0, 0, 0, 0, 20, 1),
(2170, 0, 0, 0, 'Harbour Flats, Flat 16', 400, 4, 0, 0, 0, 0, 20, 1),
(2171, 0, 0, 0, 'Harbour Flats, Flat 18', 400, 4, 0, 0, 0, 0, 25, 1),
(2172, 0, 0, 0, 'Harbour Flats, Flat 21', 860, 4, 0, 0, 0, 0, 35, 2),
(2173, 0, 0, 0, 'Harbour Flats, Flat 22', 980, 4, 0, 0, 0, 0, 45, 2),
(2174, 0, 0, 0, 'Harbour Flats, Flat 23', 400, 4, 0, 0, 0, 0, 25, 1),
(2175, 0, 0, 0, 'Harbour Lane 2a (Shop)', 680, 4, 0, 0, 0, 0, 32, 0),
(2176, 0, 0, 0, 'Harbour Lane 2b (Shop)', 680, 4, 0, 0, 0, 0, 40, 0),
(2177, 0, 0, 0, 'Harbour Lane 1 (Shop)', 1040, 4, 0, 0, 0, 0, 54, 0),
(2178, 0, 0, 0, 'Theater Avenue 6e', 820, 4, 0, 0, 0, 0, 31, 2),
(2179, 0, 0, 0, 'Theater Avenue 6c', 225, 4, 0, 0, 0, 0, 12, 1),
(2180, 0, 0, 0, 'Theater Avenue 6a', 820, 4, 0, 0, 0, 0, 35, 2),
(2181, 0, 0, 0, 'Theater Avenue 6f', 820, 4, 0, 0, 0, 0, 31, 2),
(2182, 0, 0, 0, 'Theater Avenue 6d', 225, 4, 0, 0, 0, 0, 12, 1),
(2183, 0, 0, 0, 'Theater Avenue 6b', 820, 4, 0, 0, 0, 0, 35, 2),
(2184, 0, 0, 0, 'East Lane 1a', 2260, 4, 0, 0, 0, 0, 95, 2),
(2185, 0, 0, 0, 'East Lane 1b', 1700, 4, 0, 0, 0, 0, 83, 2),
(2186, 0, 0, 0, 'East Lane 2', 3900, 4, 0, 0, 0, 0, 172, 2),
(2191, 0, 0, 0, 'Northern Street 5', 1980, 4, 0, 0, 0, 0, 94, 2),
(2192, 0, 0, 0, 'Northern Street 7', 1700, 4, 0, 0, 0, 0, 83, 2),
(2193, 0, 0, 0, 'Northern Street 3a', 740, 4, 0, 0, 0, 0, 31, 2),
(2194, 0, 0, 0, 'Northern Street 3b', 780, 4, 0, 0, 0, 0, 36, 2),
(2195, 0, 0, 0, 'Northern Street 1c', 740, 4, 0, 0, 0, 0, 31, 2),
(2196, 0, 0, 0, 'Northern Street 1b', 740, 4, 0, 0, 0, 0, 37, 2),
(2197, 0, 0, 0, 'Northern Street 1a', 940, 4, 0, 0, 0, 0, 41, 2),
(2198, 0, 0, 0, 'Theater Avenue 7, Flat 06', 315, 4, 0, 0, 0, 0, 20, 1),
(2199, 0, 0, 0, 'Theater Avenue 7, Flat 01', 315, 4, 0, 0, 0, 0, 15, 1),
(2200, 0, 0, 0, 'Theater Avenue 7, Flat 05', 405, 4, 0, 0, 0, 0, 20, 1),
(2201, 0, 0, 0, 'Theater Avenue 7, Flat 02', 405, 4, 0, 0, 0, 0, 20, 1),
(2202, 0, 0, 0, 'Theater Avenue 7, Flat 04', 495, 4, 0, 0, 0, 0, 20, 1),
(2203, 0, 0, 0, 'Theater Avenue 7, Flat 03', 405, 4, 0, 0, 0, 0, 19, 1),
(2204, 0, 0, 0, 'Theater Avenue 7, Flat 14', 495, 4, 0, 0, 0, 0, 20, 1),
(2205, 0, 0, 0, 'Theater Avenue 7, Flat 13', 405, 4, 0, 0, 0, 0, 17, 1),
(2206, 0, 0, 0, 'Theater Avenue 7, Flat 15', 405, 4, 0, 0, 0, 0, 19, 1),
(2207, 0, 0, 0, 'Theater Avenue 7, Flat 16', 405, 4, 0, 0, 0, 0, 20, 1),
(2208, 0, 0, 0, 'Theater Avenue 7, Flat 11', 495, 4, 0, 0, 0, 0, 23, 1),
(2209, 0, 0, 0, 'Theater Avenue 7, Flat 12', 405, 4, 0, 0, 0, 0, 15, 1),
(2210, 0, 0, 0, 'Theater Avenue 8a', 1270, 4, 0, 0, 0, 0, 50, 2),
(2211, 0, 0, 0, 'Theater Avenue 8b', 1370, 4, 0, 0, 0, 0, 49, 3),
(2212, 0, 0, 0, 'Central Plaza 3', 600, 4, 0, 0, 0, 0, 20, 0),
(2213, 0, 0, 0, 'Central Plaza 2', 600, 4, 0, 0, 0, 0, 20, 0),
(2214, 0, 0, 0, 'Central Plaza 1', 600, 4, 0, 0, 0, 0, 20, 0),
(2215, 0, 0, 0, 'Park Lane 1a', 1220, 4, 0, 0, 0, 0, 53, 2),
(2216, 0, 0, 0, 'Park Lane 3a', 1220, 4, 0, 0, 0, 0, 48, 2),
(2217, 0, 0, 0, 'Park Lane 1b', 1380, 4, 0, 0, 0, 0, 64, 2),
(2218, 0, 0, 0, 'Park Lane 3b', 1100, 4, 0, 0, 0, 0, 48, 2),
(2219, 0, 0, 0, 'Park Lane 4', 980, 4, 0, 0, 0, 0, 42, 2),
(2220, 0, 0, 0, 'Park Lane 2', 980, 4, 0, 0, 0, 0, 42, 2),
(2221, 0, 0, 0, 'Magician\'s Alley 8', 1400, 4, 0, 0, 0, 0, 42, 2),
(2222, 0, 0, 0, 'Moonkeep', 13020, 4, 0, 0, 0, 0, 522, 16),
(2225, 0, 0, 0, 'Castle, Basement, Flat 01', 585, 11, 0, 0, 0, 0, 30, 1),
(2226, 0, 0, 0, 'Castle, Basement, Flat 02', 585, 11, 0, 0, 0, 0, 20, 1),
(2227, 0, 0, 0, 'Castle, Basement, Flat 03', 585, 11, 0, 0, 0, 0, 20, 1),
(2228, 0, 0, 0, 'Castle, Basement, Flat 04', 585, 11, 0, 0, 0, 0, 20, 1),
(2229, 0, 0, 0, 'Castle, Basement, Flat 07', 585, 11, 0, 0, 0, 0, 20, 1),
(2230, 0, 0, 0, 'Castle, Basement, Flat 08', 585, 11, 0, 0, 0, 0, 20, 1),
(2231, 0, 0, 0, 'Castle, Basement, Flat 09', 585, 11, 0, 0, 0, 0, 24, 1),
(2232, 0, 0, 0, 'Castle, Basement, Flat 06', 585, 11, 0, 0, 0, 0, 24, 1),
(2233, 0, 0, 0, 'Castle, Basement, Flat 05', 585, 11, 0, 0, 0, 0, 24, 1),
(2234, 0, 0, 0, 'Castle Shop 1', 1890, 11, 0, 0, 0, 0, 67, 1),
(2235, 0, 0, 0, 'Castle Shop 2', 1890, 11, 0, 0, 0, 0, 70, 1),
(2236, 0, 0, 0, 'Castle Shop 3', 1890, 11, 0, 0, 0, 0, 67, 1),
(2237, 0, 0, 0, 'Castle, 4th Floor, Flat 09', 720, 11, 0, 0, 0, 0, 28, 1),
(2238, 0, 0, 0, 'Castle, 4th Floor, Flat 08', 945, 11, 0, 0, 0, 0, 42, 1),
(2239, 0, 0, 0, 'Castle, 4th Floor, Flat 06', 945, 11, 0, 0, 0, 0, 36, 1),
(2240, 0, 0, 0, 'Castle, 4th Floor, Flat 07', 720, 11, 0, 0, 0, 0, 30, 1),
(2241, 0, 0, 0, 'Castle, 4th Floor, Flat 05', 765, 11, 0, 0, 0, 0, 30, 1),
(2242, 0, 0, 0, 'Castle, 4th Floor, Flat 04', 585, 11, 0, 0, 0, 0, 25, 1),
(2243, 0, 0, 0, 'Castle, 4th Floor, Flat 03', 585, 11, 0, 0, 0, 0, 30, 1),
(2244, 0, 0, 0, 'Castle, 4th Floor, Flat 02', 765, 11, 0, 0, 0, 0, 30, 1),
(2245, 0, 0, 0, 'Castle, 4th Floor, Flat 01', 585, 11, 0, 0, 0, 0, 30, 1),
(2246, 0, 0, 0, 'Castle, 3rd Floor, Flat 01', 585, 11, 0, 0, 0, 0, 30, 1),
(2247, 0, 0, 0, 'Castle, 3rd Floor, Flat 02', 765, 11, 0, 0, 0, 0, 30, 1),
(2248, 0, 0, 0, 'Castle, 3rd Floor, Flat 03', 585, 11, 0, 0, 0, 0, 25, 1),
(2249, 0, 0, 0, 'Castle, 3rd Floor, Flat 05', 765, 11, 0, 0, 0, 0, 30, 1),
(2250, 0, 0, 0, 'Castle, 3rd Floor, Flat 04', 585, 11, 0, 0, 0, 0, 25, 1),
(2251, 0, 0, 0, 'Castle, 3rd Floor, Flat 06', 1045, 11, 0, 0, 0, 0, 35, 2),
(2252, 0, 0, 0, 'Castle, 3rd Floor, Flat 07', 720, 11, 0, 0, 0, 0, 30, 1),
(2253, 0, 0, 0, 'Castle Street 1', 2900, 11, 0, 0, 0, 0, 112, 3),
(2254, 0, 0, 0, 'Castle Street 2', 1495, 11, 0, 0, 0, 0, 56, 2),
(2255, 0, 0, 0, 'Castle Street 3', 1765, 11, 0, 0, 0, 0, 56, 2),
(2256, 0, 0, 0, 'Castle Street 4', 1765, 11, 0, 0, 0, 0, 64, 2),
(2257, 0, 0, 0, 'Castle Street 5', 1765, 11, 0, 0, 0, 0, 61, 2),
(2258, 0, 0, 0, 'Edron Flats, Basement Flat 2', 1540, 11, 0, 0, 0, 0, 48, 2),
(2259, 0, 0, 0, 'Edron Flats, Basement Flat 1', 1540, 11, 0, 0, 0, 0, 48, 2),
(2260, 0, 0, 0, 'Edron Flats, Flat 01', 400, 11, 0, 0, 0, 0, 20, 1),
(2261, 0, 0, 0, 'Edron Flats, Flat 02', 860, 11, 0, 0, 0, 0, 28, 2),
(2262, 0, 0, 0, 'Edron Flats, Flat 03', 400, 11, 0, 0, 0, 0, 20, 1),
(2263, 0, 0, 0, 'Edron Flats, Flat 04', 400, 11, 0, 0, 0, 0, 20, 1),
(2264, 0, 0, 0, 'Edron Flats, Flat 06', 400, 11, 0, 0, 0, 0, 20, 1),
(2265, 0, 0, 0, 'Edron Flats, Flat 05', 400, 11, 0, 0, 0, 0, 20, 1),
(2266, 0, 0, 0, 'Edron Flats, Flat 07', 400, 11, 0, 0, 0, 0, 20, 1),
(2267, 0, 0, 0, 'Edron Flats, Flat 08', 400, 11, 0, 0, 0, 0, 20, 1),
(2268, 0, 0, 0, 'Edron Flats, Flat 11', 400, 11, 0, 0, 0, 0, 25, 1),
(2269, 0, 0, 0, 'Edron Flats, Flat 12', 400, 11, 0, 0, 0, 0, 25, 1),
(2270, 0, 0, 0, 'Edron Flats, Flat 14', 400, 11, 0, 0, 0, 0, 25, 1),
(2271, 0, 0, 0, 'Edron Flats, Flat 13', 400, 11, 0, 0, 0, 0, 25, 1),
(2272, 0, 0, 0, 'Edron Flats, Flat 16', 400, 11, 0, 0, 0, 0, 20, 1),
(2273, 0, 0, 0, 'Edron Flats, Flat 15', 400, 11, 0, 0, 0, 0, 20, 1),
(2274, 0, 0, 0, 'Edron Flats, Flat 18', 400, 11, 0, 0, 0, 0, 20, 1),
(2275, 0, 0, 0, 'Edron Flats, Flat 17', 400, 11, 0, 0, 0, 0, 20, 1),
(2276, 0, 0, 0, 'Edron Flats, Flat 22', 400, 11, 0, 0, 0, 0, 25, 1),
(2277, 0, 0, 0, 'Edron Flats, Flat 21', 860, 11, 0, 0, 0, 0, 40, 2),
(2278, 0, 0, 0, 'Edron Flats, Flat 24', 400, 11, 0, 0, 0, 0, 20, 1),
(2279, 0, 0, 0, 'Edron Flats, Flat 23', 400, 11, 0, 0, 0, 0, 25, 1),
(2280, 0, 0, 0, 'Edron Flats, Flat 26', 400, 11, 0, 0, 0, 0, 20, 1),
(2281, 0, 0, 0, 'Edron Flats, Flat 27', 400, 11, 0, 0, 0, 0, 20, 1),
(2282, 0, 0, 0, 'Edron Flats, Flat 28', 400, 11, 0, 0, 0, 0, 20, 1),
(2283, 0, 0, 0, 'Edron Flats, Flat 25', 400, 11, 0, 0, 0, 0, 20, 1),
(2284, 0, 0, 0, 'Central Circle 1', 3020, 11, 0, 0, 0, 0, 119, 2),
(2285, 0, 0, 0, 'Central Circle 2', 3300, 11, 0, 0, 0, 0, 108, 2),
(2286, 0, 0, 0, 'Central Circle 3', 4160, 11, 0, 0, 0, 0, 147, 5),
(2287, 0, 0, 0, 'Central Circle 4', 4160, 11, 0, 0, 0, 0, 147, 5),
(2288, 0, 0, 0, 'Central Circle 5', 4160, 11, 0, 0, 0, 0, 161, 5),
(2289, 0, 0, 0, 'Central Circle 6 (Shop)', 3980, 11, 0, 0, 0, 0, 182, 2),
(2290, 0, 0, 0, 'Central Circle 7 (Shop)', 3980, 11, 0, 0, 0, 0, 161, 2),
(2291, 0, 0, 0, 'Central Circle 8 (Shop)', 3980, 11, 0, 0, 0, 0, 166, 2),
(2292, 0, 0, 0, 'Central Circle 9a', 940, 11, 0, 0, 0, 0, 42, 2),
(2293, 0, 0, 0, 'Central Circle 9b', 940, 11, 0, 0, 0, 0, 44, 2),
(2294, 0, 0, 0, 'Sky Lane, Guild 1', 21145, 11, 0, 0, 0, 0, 666, 23),
(2295, 0, 0, 0, 'Sky Lane, Guild 2', 19300, 11, 0, 0, 0, 0, 650, 14),
(2296, 0, 0, 0, 'Sky Lane, Guild 3', 17315, 11, 0, 0, 0, 0, 564, 18),
(2297, 0, 0, 0, 'Sky Lane, Sea Tower', 4775, 11, 0, 0, 0, 0, 196, 6),
(2298, 0, 0, 0, 'Wood Avenue 6a', 1450, 11, 0, 0, 0, 0, 56, 2),
(2299, 0, 0, 0, 'Wood Avenue 9a', 1540, 11, 0, 0, 0, 0, 56, 2),
(2300, 0, 0, 0, 'Wood Avenue 10a', 1540, 11, 0, 0, 0, 0, 64, 2),
(2301, 0, 0, 0, 'Wood Avenue 11', 7205, 11, 0, 0, 0, 0, 253, 6),
(2302, 0, 0, 0, 'Wood Avenue 8', 5960, 11, 0, 0, 0, 0, 198, 3),
(2303, 0, 0, 0, 'Wood Avenue 7', 5960, 11, 0, 0, 0, 0, 191, 3),
(2304, 0, 0, 0, 'Wood Avenue 6b', 1450, 11, 0, 0, 0, 0, 56, 2),
(2305, 0, 0, 0, 'Wood Avenue 9b', 1495, 11, 0, 0, 0, 0, 56, 2),
(2306, 0, 0, 0, 'Wood Avenue 10b', 1595, 11, 0, 0, 0, 0, 64, 3),
(2307, 0, 0, 0, 'Wood Avenue 5', 1765, 11, 0, 0, 0, 0, 64, 2),
(2308, 0, 0, 0, 'Wood Avenue 4a', 1495, 11, 0, 0, 0, 0, 56, 2),
(2309, 0, 0, 0, 'Wood Avenue 4b', 1495, 11, 0, 0, 0, 0, 56, 2),
(2310, 0, 0, 0, 'Wood Avenue 4c', 1765, 11, 0, 0, 0, 0, 56, 2),
(2311, 0, 0, 0, 'Wood Avenue 4', 1765, 11, 0, 0, 0, 0, 64, 2),
(2312, 0, 0, 0, 'Wood Avenue 3', 1765, 11, 0, 0, 0, 0, 56, 2),
(2313, 0, 0, 0, 'Wood Avenue 2', 1765, 11, 0, 0, 0, 0, 49, 2),
(2314, 0, 0, 0, 'Wood Avenue 1', 1765, 11, 0, 0, 0, 0, 64, 2),
(2315, 0, 0, 0, 'Magic Academy, Guild', 12025, 11, 0, 0, 0, 0, 414, 14),
(2316, 0, 0, 0, 'Magic Academy, Flat 1', 1465, 11, 0, 0, 0, 0, 57, 3),
(2317, 0, 0, 0, 'Magic Academy, Flat 2', 1530, 11, 0, 0, 0, 0, 55, 2),
(2318, 0, 0, 0, 'Magic Academy, Flat 3', 1430, 11, 0, 0, 0, 0, 55, 1),
(2319, 0, 0, 0, 'Magic Academy, Flat 4', 1530, 11, 0, 0, 0, 0, 55, 2),
(2320, 0, 0, 0, 'Magic Academy, Flat 5', 1430, 11, 0, 0, 0, 0, 55, 1),
(2321, 0, 0, 0, 'Magic Academy, Shop', 1595, 11, 0, 0, 0, 0, 48, 1),
(2322, 0, 0, 0, 'Stonehome Village 1', 1780, 11, 0, 0, 0, 0, 74, 2),
(2323, 0, 0, 0, 'Stonehome Flats, Flat 05', 400, 11, 0, 0, 0, 0, 20, 1),
(2324, 0, 0, 0, 'Stonehome Flats, Flat 04', 400, 11, 0, 0, 0, 0, 25, 1),
(2325, 0, 0, 0, 'Stonehome Flats, Flat 06', 400, 11, 0, 0, 0, 0, 20, 1),
(2326, 0, 0, 0, 'Stonehome Flats, Flat 03', 400, 11, 0, 0, 0, 0, 20, 1),
(2327, 0, 0, 0, 'Stonehome Flats, Flat 01', 400, 11, 0, 0, 0, 0, 20, 1),
(2328, 0, 0, 0, 'Stonehome Flats, Flat 02', 740, 11, 0, 0, 0, 0, 30, 2),
(2329, 0, 0, 0, 'Stonehome Flats, Flat 11', 740, 11, 0, 0, 0, 0, 35, 2),
(2330, 0, 0, 0, 'Stonehome Flats, Flat 12', 740, 11, 0, 0, 0, 0, 35, 2),
(2331, 0, 0, 0, 'Stonehome Flats, Flat 13', 400, 11, 0, 0, 0, 0, 20, 1),
(2332, 0, 0, 0, 'Stonehome Flats, Flat 14', 400, 11, 0, 0, 0, 0, 20, 1),
(2333, 0, 0, 0, 'Stonehome Flats, Flat 16', 400, 11, 0, 0, 0, 0, 20, 1),
(2334, 0, 0, 0, 'Stonehome Flats, Flat 15', 400, 11, 0, 0, 0, 0, 20, 1),
(2335, 0, 0, 0, 'Stonehome Village 2', 640, 11, 0, 0, 0, 0, 35, 1),
(2336, 0, 0, 0, 'Stonehome Village 3', 680, 11, 0, 0, 0, 0, 36, 1),
(2337, 0, 0, 0, 'Stonehome Village 4', 940, 11, 0, 0, 0, 0, 42, 2),
(2338, 0, 0, 0, 'Stonehome Village 6', 1300, 11, 0, 0, 0, 0, 55, 2),
(2339, 0, 0, 0, 'Stonehome Village 5', 1140, 11, 0, 0, 0, 0, 56, 2),
(2340, 0, 0, 0, 'Stonehome Village 7', 1140, 11, 0, 0, 0, 0, 49, 2),
(2341, 0, 0, 0, 'Stonehome Village 8', 680, 11, 0, 0, 0, 0, 36, 1),
(2342, 0, 0, 0, 'Stonehome Village 9', 680, 11, 0, 0, 0, 0, 36, 1),
(2343, 0, 0, 0, 'Stonehome Clanhall', 8580, 11, 0, 0, 0, 0, 345, 9),
(2344, 0, 0, 0, 'Cormaya 1', 1270, 11, 0, 0, 0, 0, 49, 2),
(2345, 0, 0, 0, 'Cormaya 2', 3710, 11, 0, 0, 0, 0, 145, 3),
(2346, 0, 0, 0, 'Cormaya Flats, Flat 01', 450, 11, 0, 0, 0, 0, 20, 1),
(2347, 0, 0, 0, 'Cormaya Flats, Flat 02', 450, 11, 0, 0, 0, 0, 20, 1),
(2348, 0, 0, 0, 'Cormaya Flats, Flat 03', 820, 11, 0, 0, 0, 0, 30, 2),
(2349, 0, 0, 0, 'Cormaya Flats, Flat 06', 450, 11, 0, 0, 0, 0, 20, 1),
(2350, 0, 0, 0, 'Cormaya Flats, Flat 05', 450, 11, 0, 0, 0, 0, 20, 1),
(2351, 0, 0, 0, 'Cormaya Flats, Flat 04', 820, 11, 0, 0, 0, 0, 30, 2),
(2352, 0, 0, 0, 'Cormaya Flats, Flat 13', 820, 11, 0, 0, 0, 0, 30, 2),
(2353, 0, 0, 0, 'Cormaya Flats, Flat 14', 820, 11, 0, 0, 0, 0, 35, 2),
(2354, 0, 0, 0, 'Cormaya Flats, Flat 15', 450, 11, 0, 0, 0, 0, 20, 1),
(2355, 0, 0, 0, 'Cormaya Flats, Flat 16', 450, 11, 0, 0, 0, 0, 20, 1),
(2356, 0, 0, 0, 'Cormaya Flats, Flat 11', 450, 11, 0, 0, 0, 0, 20, 1),
(2357, 0, 0, 0, 'Cormaya Flats, Flat 12', 450, 11, 0, 0, 0, 0, 20, 1),
(2358, 0, 0, 0, 'Cormaya 3', 2035, 11, 0, 0, 0, 0, 72, 2),
(2359, 0, 0, 0, 'Castle of the White Dragon', 25110, 11, 0, 0, 0, 0, 744, 16),
(2360, 0, 0, 0, 'Cormaya 4', 1720, 11, 0, 0, 0, 0, 63, 2),
(2361, 0, 0, 0, 'Cormaya 5', 4250, 11, 0, 0, 0, 0, 167, 3),
(2362, 0, 0, 0, 'Cormaya 6', 2395, 11, 0, 0, 0, 0, 84, 2),
(2363, 0, 0, 0, 'Cormaya 7', 2395, 11, 0, 0, 0, 0, 84, 2),
(2364, 0, 0, 0, 'Cormaya 8', 2710, 11, 0, 0, 0, 0, 113, 2),
(2365, 0, 0, 0, 'Cormaya 9b', 2620, 11, 0, 0, 0, 0, 88, 2),
(2366, 0, 0, 0, 'Cormaya 9a', 1225, 11, 0, 0, 0, 0, 48, 2),
(2367, 0, 0, 0, 'Cormaya 9c', 1225, 11, 0, 0, 0, 0, 48, 2),
(2368, 0, 0, 0, 'Cormaya 9d', 2620, 11, 0, 0, 0, 0, 88, 2),
(2369, 0, 0, 0, 'Cormaya 10', 3800, 11, 0, 0, 0, 0, 140, 3),
(2370, 0, 0, 0, 'Cormaya 11', 2035, 11, 0, 0, 0, 0, 72, 2),
(2371, 0, 0, 0, 'Demon Tower', 3340, 2, 0, 0, 0, 0, 127, 2),
(2372, 0, 0, 0, 'Nautic Observer', 6540, 4, 0, 0, 0, 0, 300, 4),
(2373, 0, 0, 0, 'Riverspring', 19450, 3, 0, 0, 0, 0, 565, 18),
(2374, 0, 0, 0, 'House of Recreation', 22540, 4, 0, 0, 0, 0, 702, 16),
(2375, 0, 0, 0, 'Valorous Venore', 14435, 1, 0, 0, 0, 0, 496, 9),
(2376, 0, 0, 0, 'Ab\'Dendriel Clanhall', 14850, 5, 0, 0, 0, 0, 405, 10),
(2377, 0, 0, 0, 'Castle of the Winds', 23885, 5, 0, 0, 0, 0, 842, 18),
(2378, 0, 0, 0, 'The Hideout', 20800, 5, 0, 0, 0, 0, 597, 20),
(2379, 0, 0, 0, 'Shadow Towers', 21800, 5, 0, 0, 0, 0, 750, 18),
(2380, 0, 0, 0, 'Hill Hideout', 13950, 3, 0, 0, 0, 0, 346, 15),
(2381, 0, 0, 0, 'Meriana Beach', 8230, 7, 0, 0, 0, 0, 184, 3),
(2382, 0, 0, 0, 'Darashia 8, Flat 01', 2485, 10, 0, 0, 0, 0, 80, 2),
(2383, 0, 0, 0, 'Darashia 8, Flat 02', 3385, 10, 0, 0, 0, 0, 114, 2),
(2384, 0, 0, 0, 'Darashia 8, Flat 03', 4700, 10, 0, 0, 0, 0, 171, 3),
(2385, 0, 0, 0, 'Darashia 8, Flat 04', 2845, 10, 0, 0, 0, 0, 90, 2),
(2386, 0, 0, 0, 'Darashia 8, Flat 05', 2665, 10, 0, 0, 0, 0, 85, 2),
(2387, 0, 0, 0, 'Darashia, Eastern Guildhall', 12660, 10, 0, 0, 0, 0, 444, 16),
(2388, 0, 0, 0, 'Theater Avenue 5a', 450, 4, 0, 0, 0, 0, 20, 1),
(2389, 0, 0, 0, 'Theater Avenue 5b', 450, 4, 0, 0, 0, 0, 19, 1),
(2390, 0, 0, 0, 'Theater Avenue 5c', 450, 4, 0, 0, 0, 0, 16, 1),
(2391, 0, 0, 0, 'Theater Avenue 5d', 450, 4, 0, 0, 0, 0, 16, 1),
(2392, 0, 0, 0, 'Outlaw Camp 1', 1660, 3, 0, 0, 0, 0, 52, 2),
(2393, 0, 0, 0, 'Outlaw Camp 2', 280, 3, 0, 0, 0, 0, 12, 1),
(2394, 0, 0, 0, 'Outlaw Camp 3', 740, 3, 0, 0, 0, 0, 27, 2),
(2395, 0, 0, 0, 'Outlaw Camp 4', 200, 3, 0, 0, 0, 0, 9, 1),
(2396, 0, 0, 0, 'Outlaw Camp 5', 200, 3, 0, 0, 0, 0, 9, 1),
(2397, 0, 0, 0, 'Outlaw Camp 6', 200, 3, 0, 0, 0, 0, 9, 1),
(2398, 0, 0, 0, 'Outlaw Camp 7', 780, 3, 0, 0, 0, 0, 27, 2),
(2399, 0, 0, 0, 'Outlaw Camp 8', 280, 3, 0, 0, 0, 0, 12, 1),
(2400, 0, 0, 0, 'Outlaw Camp 9', 200, 3, 0, 0, 0, 0, 9, 1),
(2401, 0, 0, 0, 'Outlaw Camp 10', 200, 3, 0, 0, 0, 0, 9, 1),
(2402, 0, 0, 0, 'Outlaw Camp 11', 200, 3, 0, 0, 0, 0, 9, 1),
(2404, 0, 0, 0, 'Outlaw Camp 12 (Shop)', 280, 3, 0, 0, 0, 0, 7, 0),
(2405, 0, 0, 0, 'Outlaw Camp 13 (Shop)', 280, 3, 0, 0, 0, 0, 7, 0),
(2406, 0, 0, 0, 'Outlaw Camp 14 (Shop)', 640, 3, 0, 0, 0, 0, 16, 0),
(2407, 0, 0, 0, 'Open-Air Theatre', 2700, 2, 0, 0, 0, 0, 60, 1),
(2408, 0, 0, 0, 'The Lair', 7625, 1, 0, 0, 0, 0, 165, 3),
(2409, 0, 0, 0, 'Upper Barracks 2', 210, 3, 0, 0, 0, 0, 13, 1),
(2410, 0, 0, 0, 'Upper Barracks 3', 210, 3, 0, 0, 0, 0, 13, 1),
(2411, 0, 0, 0, 'Upper Barracks 4', 210, 3, 0, 0, 0, 0, 14, 1),
(2412, 0, 0, 0, 'Upper Barracks 5', 210, 3, 0, 0, 0, 0, 12, 1),
(2413, 0, 0, 0, 'Upper Barracks 6', 210, 3, 0, 0, 0, 0, 12, 1),
(2414, 0, 0, 0, 'Upper Barracks 7', 210, 3, 0, 0, 0, 0, 12, 1),
(2415, 0, 0, 0, 'Upper Barracks 8', 210, 3, 0, 0, 0, 0, 13, 1),
(2416, 0, 0, 0, 'Upper Barracks 9', 210, 3, 0, 0, 0, 0, 13, 1),
(2417, 0, 0, 0, 'Upper Barracks 10', 210, 3, 0, 0, 0, 0, 13, 1),
(2418, 0, 0, 0, 'Upper Barracks 11', 210, 3, 0, 0, 0, 0, 14, 1),
(2419, 0, 0, 0, 'Upper Barracks 12', 210, 3, 0, 0, 0, 0, 12, 1),
(2420, 0, 0, 0, 'Low Waters Observatory', 17165, 9, 0, 0, 0, 0, 760, 5),
(2421, 0, 0, 0, 'Eastern House of Tranquility', 11120, 14, 0, 0, 0, 0, 356, 5),
(2422, 0, 0, 0, 'Mammoth House', 9300, 12, 0, 0, 0, 0, 218, 6),
(2427, 0, 0, 0, 'Lower Barracks 1', 300, 3, 0, 0, 0, 0, 17, 1),
(2428, 0, 0, 0, 'Lower Barracks 2', 300, 3, 0, 0, 0, 0, 16, 1),
(2429, 0, 0, 0, 'Lower Barracks 3', 300, 3, 0, 0, 0, 0, 17, 1),
(2430, 0, 0, 0, 'Lower Barracks 4', 300, 3, 0, 0, 0, 0, 16, 1),
(2431, 0, 0, 0, 'Lower Barracks 5', 300, 3, 0, 0, 0, 0, 17, 1),
(2432, 0, 0, 0, 'Lower Barracks 6', 300, 3, 0, 0, 0, 0, 15, 1),
(2433, 0, 0, 0, 'Lower Barracks 7', 300, 3, 0, 0, 0, 0, 17, 1),
(2434, 0, 0, 0, 'Lower Barracks 8', 300, 3, 0, 0, 0, 0, 16, 1),
(2435, 0, 0, 0, 'Lower Barracks 9', 300, 3, 0, 0, 0, 0, 17, 1),
(2436, 0, 0, 0, 'Lower Barracks 10', 300, 3, 0, 0, 0, 0, 16, 1),
(2437, 0, 0, 0, 'Lower Barracks 11', 300, 3, 0, 0, 0, 0, 17, 1),
(2438, 0, 0, 0, 'Lower Barracks 12', 300, 3, 0, 0, 0, 0, 16, 1),
(2439, 0, 0, 0, 'Lower Barracks 13', 300, 3, 0, 0, 0, 0, 17, 1),
(2440, 0, 0, 0, 'Lower Barracks 14', 300, 3, 0, 0, 0, 0, 16, 1),
(2441, 0, 0, 0, 'Lower Barracks 15', 300, 3, 0, 0, 0, 0, 17, 1),
(2442, 0, 0, 0, 'Lower Barracks 16', 300, 3, 0, 0, 0, 0, 16, 1),
(2443, 0, 0, 0, 'Lower Barracks 17', 300, 3, 0, 0, 0, 0, 17, 1),
(2444, 0, 0, 0, 'Lower Barracks 18', 300, 3, 0, 0, 0, 0, 16, 1),
(2445, 0, 0, 0, 'Lower Barracks 19', 300, 3, 0, 0, 0, 0, 17, 1),
(2446, 0, 0, 0, 'Lower Barracks 20', 300, 3, 0, 0, 0, 0, 16, 1),
(2447, 0, 0, 0, 'Lower Barracks 21', 300, 3, 0, 0, 0, 0, 17, 1),
(2448, 0, 0, 0, 'Lower Barracks 22', 300, 3, 0, 0, 0, 0, 16, 1),
(2449, 0, 0, 0, 'Lower Barracks 23', 300, 3, 0, 0, 0, 0, 17, 1),
(2450, 0, 0, 0, 'Lower Barracks 24', 300, 3, 0, 0, 0, 0, 16, 1),
(2451, 0, 0, 0, 'The Farms 4', 1530, 3, 0, 0, 0, 0, 36, 2),
(2452, 0, 0, 0, 'Tunnel Gardens 1', 2000, 3, 0, 0, 0, 0, 40, 3),
(2455, 0, 0, 0, 'Tunnel Gardens 2', 2000, 3, 0, 0, 0, 0, 39, 3),
(2456, 0, 0, 0, 'The Yeah Beach Project', 6525, 7, 0, 0, 0, 0, 183, 3),
(2460, 0, 0, 0, 'Hare\'s Den', 7500, 3, 0, 0, 0, 0, 233, 4),
(2461, 0, 0, 0, 'Lost Cavern', 14730, 3, 0, 0, 0, 0, 621, 7),
(2462, 0, 0, 0, 'Caveman Shelter', 3780, 14, 0, 0, 0, 0, 92, 4),
(2463, 0, 0, 0, 'Old Sanctuary of God King Qjell', 21940, 28, 0, 0, 0, 0, 854, 6),
(2464, 0, 0, 0, 'Wallside Lane 1', 7590, 33, 0, 0, 0, 0, 295, 4),
(2465, 0, 0, 0, 'Wallside Residence', 6680, 33, 0, 0, 0, 0, 223, 4),
(2466, 0, 0, 0, 'Wallside Lane 2', 8445, 33, 0, 0, 0, 0, 294, 4),
(2467, 0, 0, 0, 'Antimony Lane 3', 3665, 33, 0, 0, 0, 0, 126, 3),
(2468, 0, 0, 0, 'Antimony Lane 2', 4745, 33, 0, 0, 0, 0, 159, 3),
(2469, 0, 0, 0, 'Vanward Flats B', 7410, 33, 0, 0, 0, 0, 245, 4),
(2470, 0, 0, 0, 'Vanward Flats A', 7410, 33, 0, 0, 0, 0, 222, 4),
(2471, 0, 0, 0, 'Bronze Brothers Bastion', 35205, 33, 0, 0, 0, 0, 1181, 15),
(2472, 0, 0, 0, 'Antimony Lane 1', 7105, 33, 0, 0, 0, 0, 242, 5),
(2473, 0, 0, 0, 'Rathleton Hills Estate', 20685, 33, 0, 0, 0, 0, 646, 13),
(2474, 0, 0, 0, 'Rathleton Hills Residence', 7085, 33, 0, 0, 0, 0, 228, 3),
(2475, 0, 0, 0, 'Rathleton Plaza 1', 2890, 33, 0, 0, 0, 0, 95, 2),
(2476, 0, 1553707484, 1, 'Rathleton Plaza 2', 2620, 33, 0, 0, 0, 0, 99, 2),
(2478, 0, 0, 0, 'Antimony Lane 4', 5150, 33, 0, 0, 0, 0, 176, 3),
(2480, 0, 0, 0, 'Old Heritage Estate', 12075, 33, 0, 0, 0, 0, 402, 7),
(2481, 0, 0, 0, 'Cistern Ave', 3745, 33, 0, 0, 0, 0, 173, 2),
(2482, 0, 0, 0, 'Rathleton Plaza 4', 5005, 33, 0, 0, 0, 0, 193, 2),
(2483, 0, 0, 0, 'Rathleton Plaza 3', 5735, 33, 0, 0, 0, 0, 193, 3),
(2488, 0, 0, 0, 'Thrarhor V e (Shop)', 3000, 9, 0, 0, 0, 0, 36, 1),
(2491, 0, 0, 0, 'Isle of Solitude House', 3000, 31, 0, 0, 0, 0, 529, 14),
(2496, 0, 0, 0, 'Meriana Beach', 8230, 7, 0, 0, 0, 0, 191, 3),
(2498, 0, 0, 0, 'Darashia 8, Flat 01', 2485, 10, 0, 0, 0, 0, 80, 2),
(2499, 0, 0, 0, 'Darashia 8, Flat 02', 3385, 10, 0, 0, 0, 0, 114, 2),
(2500, 0, 0, 0, 'Darashia 8, Flat 03', 4700, 10, 0, 0, 0, 0, 186, 3),
(2501, 0, 0, 0, 'Darashia 8, Flat 04', 2845, 10, 0, 0, 0, 0, 95, 2),
(2502, 0, 0, 0, 'Darashia 8, Flat 05', 2665, 10, 0, 0, 0, 0, 93, 2),
(2503, 0, 0, 0, 'Darashia, Eastern Guildhall', 12660, 10, 0, 0, 0, 0, 443, 16),
(2504, 0, 0, 0, 'Theater Avenue 5a', 450, 4, 0, 0, 0, 0, 20, 1),
(2505, 0, 0, 0, 'Theater Avenue 5b', 450, 4, 0, 0, 0, 0, 25, 1),
(2506, 0, 0, 0, 'Theater Avenue 5c', 450, 4, 0, 0, 0, 0, 20, 1),
(2507, 0, 0, 0, 'Theater Avenue 5d', 450, 4, 0, 0, 0, 0, 25, 1),
(2508, 0, 0, 0, 'Outlaw Camp 01', 1660, 1, 0, 0, 0, 0, 59, 2),
(2509, 0, 0, 0, 'Outlaw Camp 02', 280, 1, 0, 0, 0, 0, 20, 1),
(2510, 0, 0, 0, 'Outlaw Camp 03', 740, 1, 0, 0, 0, 0, 35, 2),
(2511, 0, 0, 0, 'Outlaw Camp 04', 200, 1, 0, 0, 0, 0, 12, 1),
(2512, 0, 0, 0, 'Outlaw Camp 05', 200, 1, 0, 0, 0, 0, 12, 1),
(2513, 0, 0, 0, 'Outlaw Camp 06', 200, 1, 0, 0, 0, 0, 16, 1),
(2514, 0, 0, 0, 'Outlaw Camp 07', 780, 1, 0, 0, 0, 0, 37, 2),
(2515, 0, 0, 0, 'Outlaw Camp 08', 280, 1, 0, 0, 0, 0, 20, 1),
(2516, 0, 0, 0, 'Outlaw Camp 09', 200, 1, 0, 0, 0, 0, 12, 1),
(2517, 0, 0, 0, 'Outlaw Camp 10', 200, 1, 0, 0, 0, 0, 12, 1),
(2518, 0, 0, 0, 'Outlaw Camp 11', 200, 1, 0, 0, 0, 0, 16, 1),
(2519, 0, 0, 0, 'Outlaw Camp 12', 280, 1, 0, 0, 0, 0, 10, 0),
(2520, 0, 0, 0, 'Outlaw Camp 13', 280, 1, 0, 0, 0, 0, 13, 0),
(2521, 0, 0, 0, 'Outlaw Camp 14', 680, 1, 0, 0, 0, 0, 16, 0),
(2522, 0, 0, 0, 'Open-Air Theatre', 2700, 2, 0, 0, 0, 0, 110, 1),
(2523, 0, 0, 0, 'The Lair', 7625, 1, 0, 0, 0, 0, 146, 1),
(2524, 0, 0, 0, 'Upper Barracks 02', 210, 3, 0, 0, 0, 0, 15, 1),
(2526, 0, 0, 0, 'Upper Barracks 03', 210, 3, 0, 0, 0, 0, 12, 1),
(2527, 0, 0, 0, 'Upper Barracks 04', 0, 3, 0, 0, 0, 0, 17, 1),
(2528, 0, 0, 0, 'Upper Barracks 05', 210, 3, 0, 0, 0, 0, 12, 1),
(2529, 0, 0, 0, 'Upper Barracks 06', 210, 3, 0, 0, 0, 0, 12, 1),
(2530, 0, 0, 0, 'Upper Barracks 07', 210, 3, 0, 0, 0, 0, 12, 1),
(2531, 0, 0, 0, 'Upper Barracks 08', 210, 3, 0, 0, 0, 0, 15, 1),
(2532, 0, 0, 0, 'Upper Barracks 09', 210, 3, 0, 0, 0, 0, 15, 1),
(2533, 0, 0, 0, 'Upper Barracks 10', 210, 3, 0, 0, 0, 0, 15, 1),
(2534, 0, 0, 0, 'Upper Barracks 11', 0, 3, 0, 0, 0, 0, 20, 1),
(2535, 0, 0, 0, 'Upper Barracks 12', 210, 3, 0, 0, 0, 0, 20, 1),
(2536, 0, 0, 0, 'Low Waters Observatory', 17165, 9, 0, 0, 0, 0, 759, 5),
(2537, 0, 0, 0, 'Eastern House of Tranquility', 11120, 8, 0, 0, 0, 0, 452, 5),
(2538, 0, 0, 0, 'Mammoth House', 9300, 12, 0, 0, 0, 0, 314, 6),
(2539, 0, 0, 0, 'Lower Barracks 01', 300, 3, 0, 0, 0, 0, 20, 1),
(2540, 0, 0, 0, 'Lower Barracks 02', 300, 3, 0, 0, 0, 0, 20, 1),
(2541, 0, 0, 0, 'Lower Barracks 03', 300, 3, 0, 0, 0, 0, 20, 1),
(2542, 0, 0, 0, 'Lower Barracks 04', 300, 3, 0, 0, 0, 0, 24, 1),
(2543, 0, 0, 0, 'Lower Barracks 05', 300, 3, 0, 0, 0, 0, 23, 1),
(2544, 0, 0, 0, 'Lower Barracks 06', 300, 3, 0, 0, 0, 0, 25, 1),
(2545, 0, 0, 0, 'Lower Barracks 07', 300, 3, 0, 0, 0, 0, 25, 1),
(2546, 0, 0, 0, 'Lower Barracks 08', 300, 3, 0, 0, 0, 0, 25, 1),
(2547, 0, 0, 0, 'Lower Barracks 09', 300, 3, 0, 0, 0, 0, 25, 1),
(2548, 0, 0, 0, 'Lower Barracks 10', 300, 3, 0, 0, 0, 0, 25, 1),
(2549, 0, 0, 0, 'Lower Barracks 11', 300, 3, 0, 0, 0, 0, 25, 1),
(2550, 0, 0, 0, 'Lower Barracks 12', 300, 3, 0, 0, 0, 0, 25, 1),
(2551, 0, 0, 0, 'Lower Barracks 13', 300, 3, 0, 0, 0, 0, 16, 1),
(2552, 0, 0, 0, 'Lower Barracks 14', 300, 3, 0, 0, 0, 0, 20, 1),
(2553, 0, 0, 0, 'Lower Barracks 15', 300, 3, 0, 0, 0, 0, 16, 1),
(2554, 0, 0, 0, 'Lower Barracks 16', 300, 3, 0, 0, 0, 0, 20, 1),
(2555, 0, 0, 0, 'Lower Barracks 17', 300, 3, 0, 0, 0, 0, 16, 1),
(2556, 0, 0, 0, 'Lower Barracks 18', 300, 3, 0, 0, 0, 0, 20, 1),
(2557, 0, 0, 0, 'Lower Barracks 19', 300, 3, 0, 0, 0, 0, 20, 1),
(2558, 0, 0, 0, 'Lower Barracks 20', 300, 3, 0, 0, 0, 0, 16, 1),
(2559, 0, 0, 0, 'Lower Barracks 21', 300, 3, 0, 0, 0, 0, 20, 1),
(2560, 0, 0, 0, 'Lower Barracks 22', 300, 3, 0, 0, 0, 0, 20, 1),
(2561, 0, 0, 0, 'Lower Barracks 23', 300, 3, 0, 0, 0, 0, 20, 1),
(2562, 0, 0, 0, 'Lower Barracks 24', 300, 3, 0, 0, 0, 0, 16, 1),
(2563, 0, 0, 0, 'The Farms 4', 1530, 3, 0, 0, 0, 0, 49, 2),
(2564, 0, 0, 0, 'Tunnel Gardens 1', 2000, 3, 0, 0, 0, 0, 48, 3),
(2565, 0, 0, 0, 'Tunnel Gardens 2', 2000, 3, 0, 0, 0, 0, 48, 3),
(2566, 0, 0, 0, 'The Yeah Beach Project', 6525, 7, 0, 0, 0, 0, 119, 0),
(2567, 0, 0, 0, 'Hare\'s Den', 7500, 1, 0, 0, 0, 0, 192, 2),
(2568, 0, 0, 0, 'Lost Cavern', 14730, 3, 0, 0, 0, 0, 1192, 7),
(2569, 0, 0, 0, 'Caveman Shelter', 3780, 14, 0, 0, 0, 0, 171, 4),
(2570, 0, 0, 0, 'Old Sanctuary of God King Qjell', 21940, 28, 0, 0, 0, 0, 912, 6),
(2571, 0, 0, 0, 'Wallside Lane 1', 7590, 33, 0, 0, 0, 0, 289, 4),
(2572, 0, 0, 0, 'Wallside Residence', 6680, 33, 0, 0, 0, 0, 163, 1),
(2573, 0, 0, 0, 'Wallside Lane 2', 8445, 33, 0, 0, 0, 0, 318, 4),
(2574, 0, 0, 0, 'Antimony Lane 3', 3665, 33, 0, 0, 0, 0, 140, 3),
(2575, 0, 0, 0, 'Antimony Lane 2', 4745, 33, 0, 0, 0, 0, 145, 0),
(2576, 0, 0, 0, 'Vanward Flats B', 7410, 33, 0, 0, 0, 0, 241, 4),
(2577, 0, 0, 0, 'Vanward Flats A', 7410, 33, 0, 0, 0, 0, 276, 4),
(2578, 0, 0, 0, 'Bronze Brothers Bastion', 32205, 33, 0, 0, 0, 0, 1267, 15),
(2579, 0, 0, 0, 'Antimony Lane 1', 7105, 33, 0, 0, 0, 0, 265, 5),
(2580, 0, 0, 0, 'Rathleton Hills Estate', 20685, 33, 0, 0, 0, 0, 716, 13),
(2581, 0, 0, 0, 'Rathleton Hills Residence', 7085, 33, 0, 0, 0, 0, 256, 3),
(2582, 0, 0, 0, 'Rathleton Plaza 1', 2890, 33, 0, 0, 0, 0, 120, 2),
(2583, 0, 0, 0, 'Rathleton Plaza 2', 2620, 33, 0, 0, 0, 0, 112, 2),
(2584, 0, 0, 0, 'Antimony Lane 4', 5150, 33, 0, 0, 0, 0, 140, 3),
(2585, 0, 0, 0, 'Old Heritage Estate', 12075, 33, 0, 0, 0, 0, 437, 7),
(2586, 0, 0, 0, 'Cistern Ave', 3745, 33, 0, 0, 0, 0, 168, 2),
(2587, 0, 0, 0, 'Rathleton Plaza 4', 5005, 33, 0, 0, 0, 0, 210, 2),
(2588, 0, 0, 0, 'Rathleton Plaza 3', 5735, 33, 0, 0, 0, 0, 227, 3),
(2590, 0, 0, 0, 'Thrarhor V e (Shop)', 3000, 9, 0, 0, 0, 0, 36, 1),
(2592, 0, 0, 0, 'Isle of Solitude House', 3000, 31, 0, 0, 0, 0, 663, 14),
(2593, 0, 0, 0, 'Tunnel Gardens 9', 0, 3, 0, 0, 0, 0, 23, 2),
(2594, 0, 0, 0, 'Tunnel Gardens 10', 0, 3, 0, 0, 0, 0, 24, 2),
(2595, 0, 0, 0, 'Tunnel Gardens 11', 0, 3, 0, 0, 0, 0, 26, 2),
(2596, 0, 0, 0, 'Tunnel Gardens 12', 0, 3, 0, 0, 0, 0, 24, 2),
(2597, 0, 0, 0, 'Caretaker\'s Residence', 6000, 4, 0, 0, 0, 0, 359, 0),
(2598, 0, 0, 0, 'Prima Arbor', 4000, 4, 0, 0, 0, 0, 288, 3),
(2599, 0, 0, 0, 'Avenue Tower', 3000, 4, 0, 0, 0, 0, 134, 0),
(2600, 0, 0, 0, 'Pirate Shipwreck 1', 8000, 4, 0, 0, 0, 0, 204, 0),
(2601, 0, 0, 0, 'Pirate Shipwreck 2', 8000, 4, 0, 0, 0, 0, 274, 0),
(2602, 0, 0, 0, 'Castle, Residence', 6000, 4, 0, 0, 0, 0, 153, 0),
(2603, 0, 0, 0, 'Stronghold', 8000, 4, 0, 0, 0, 0, 275, 0),
(2604, 0, 0, 0, 'Harbour Promenade 1', 8000, 4, 0, 0, 0, 0, 193, 0),
(2605, 0, 0, 0, 'Aureate Court 5', 6000, 4, 0, 0, 0, 0, 195, 0),
(2606, 0, 0, 0, 'Luminous Arc 5', 8000, 4, 0, 0, 0, 0, 210, 0),
(2607, 0, 0, 0, 'Mad Scientist\'s Lab', 6000, 4, 0, 0, 0, 0, 116, 0),
(2608, 0, 0, 0, 'Smugglers Den', 4000, 4, 0, 0, 0, 0, 298, 0),
(2609, 0, 0, 0, 'Haggler\'s Hangout 7', 4000, 4, 0, 0, 0, 0, 240, 0),
(2610, 0, 0, 0, 'Big Game Hunters Lodge', 6000, 4, 0, 0, 0, 0, 257, 0),
(2611, 0, 0, 0, 'Ivory Mansion', 8000, 4, 0, 0, 0, 0, 412, 0),
(2612, 0, 0, 0, 'Lakeside Mansion', 3000, 4, 0, 0, 0, 0, 222, 0),
(2613, 0, 0, 0, 'Mystic Lane 3 (Tower)', 8000, 1, 0, 0, 0, 0, 252, 0),
(2614, 0, 0, 0, 'Lucky Lane 2 (Tower)', 6000, 1, 0, 0, 0, 0, 252, 2),
(2615, 0, 0, 0, 'Lucky Lane 3 (Tower)', 6000, 1, 0, 0, 0, 0, 252, 2),
(2616, 0, 0, 0, 'Iron Alley Watch, Upper', 6000, 1, 0, 0, 0, 0, 246, 3),
(2617, 0, 0, 0, 'Iron Alley Watch, Lower', 6000, 1, 0, 0, 0, 0, 252, 2),
(2618, 0, 0, 0, 'Dwarven Magnates Estate', 3000, 1, 0, 0, 0, 0, 210, 0),
(2619, 0, 0, 0, 'Forge Masters Quarters', 3000, 1, 0, 0, 0, 0, 117, 0),
(2620, 0, 1604950460, 0, 'Harbour Place 3', 8000, 1, 0, 0, 0, 0, 132, 0),
(2621, 0, 0, 0, 'Marketplace 2', 4000, 4, 0, 0, 0, 0, 143, 2),
(2622, 0, 0, 0, 'Palace Vicinity', 2000, 4, 0, 0, 0, 0, 155, 4),
(2623, 0, 0, 0, '  Quay 1', 2000, 4, 0, 0, 0, 0, 135, 4),
(2624, 0, 0, 0, '  Quay 2', 2000, 4, 0, 0, 0, 0, 121, 2),
(2625, 0, 0, 0, 'Wave Tower', 4000, 4, 0, 0, 0, 0, 273, 4),
(2626, 0, 0, 0, 'Marketplace 1', 4000, 4, 0, 0, 0, 0, 147, 1),
(2627, 0, 0, 0, 'Quay 3', 2000, 4, 0, 0, 0, 0, 490, 11),
(2628, 0, 0, 0, 'Castle of the Winds', 500000, 5, 0, 0, 0, 0, 863, 18),
(2629, 0, 0, 0, 'Ab\'Dendriel Clanhall', 250000, 5, 0, 0, 0, 0, 456, 10),
(2630, 0, 0, 0, 'Underwood 9', 50000, 5, 0, 0, 0, 0, 29, 1),
(2631, 0, 0, 0, 'Treetop 13', 100000, 5, 0, 0, 0, 0, 45, 2),
(2632, 0, 0, 0, 'Underwood 8', 50000, 5, 0, 0, 0, 0, 33, 2),
(2633, 0, 0, 0, 'Treetop 11', 50000, 5, 0, 0, 0, 0, 34, 2),
(2634, 0, 0, 0, 'Great Willow 4b', 50000, 5, 0, 0, 0, 0, 30, 1),
(2635, 0, 0, 0, 'Great Willow 1b', 50000, 5, 0, 0, 0, 0, 18, 1),
(2636, 0, 0, 0, 'Great Willow 2b', 80000, 5, 0, 0, 0, 0, 24, 1),
(2637, 0, 0, 0, 'Great Willow 3b', 25000, 5, 0, 0, 0, 0, 24, 1),
(2638, 0, 0, 0, 'Great Willow Western Wing', 100000, 5, 0, 0, 0, 0, 25, 1),
(2639, 0, 0, 0, 'Great Willow 2a', 50000, 5, 0, 0, 0, 0, 22, 1),
(2640, 0, 0, 0, 'Great Willow 1a', 100000, 5, 0, 0, 0, 0, 25, 1),
(2641, 0, 0, 0, 'Great Willow 4c', 25000, 5, 0, 0, 0, 0, 30, 1),
(2642, 0, 0, 0, 'Great Willow 1c', 25000, 5, 0, 0, 0, 0, 18, 1),
(2643, 0, 0, 0, 'Great Willow 2c', 25000, 5, 0, 0, 0, 0, 24, 1),
(2644, 0, 0, 0, 'Great Willow 3c', 25000, 5, 0, 0, 0, 0, 24, 1),
(2645, 0, 0, 0, 'Great Willow 2d', 50000, 5, 0, 0, 0, 0, 28, 2),
(2646, 0, 0, 0, 'Great Willow 1d', 50000, 5, 0, 0, 0, 0, 35, 2),
(2647, 0, 0, 0, 'Great Willow 4d', 50000, 5, 0, 0, 0, 0, 36, 1),
(2648, 0, 0, 0, 'Great Willow 3d', 50000, 5, 0, 0, 0, 0, 31, 2),
(2649, 0, 0, 0, 'Underwood 6', 100000, 5, 0, 0, 0, 0, 55, 3),
(2650, 0, 0, 0, 'Underwood 3', 100000, 5, 0, 0, 0, 0, 56, 3),
(2651, 0, 0, 0, 'Underwood 5', 80000, 5, 0, 0, 0, 0, 47, 3),
(2652, 0, 0, 0, 'Underwood 2', 100000, 5, 0, 0, 0, 0, 53, 2),
(2653, 0, 0, 0, 'Underwood 1', 100000, 5, 0, 0, 0, 0, 54, 2),
(2654, 0, 0, 0, 'Prima Arbor', 400000, 5, 0, 0, 0, 0, 316, 3),
(2655, 0, 0, 0, 'Underwood 7', 200000, 5, 0, 0, 0, 0, 52, 2),
(2656, 0, 0, 0, 'Underwood 10', 25000, 5, 0, 0, 0, 0, 30, 1),
(2657, 0, 0, 0, 'Underwood 4', 100000, 5, 0, 0, 0, 0, 72, 4),
(2658, 0, 0, 0, 'Treetop 9', 50000, 5, 0, 0, 0, 0, 35, 2),
(2659, 0, 0, 0, 'Treetop 10', 80000, 5, 0, 0, 0, 0, 42, 2),
(2660, 0, 0, 0, 'Treetop 8', 25000, 5, 0, 0, 0, 0, 35, 1),
(2661, 0, 0, 0, 'Treetop 7', 50000, 5, 0, 0, 0, 0, 28, 1),
(2662, 0, 0, 0, 'Treetop 6', 25000, 5, 0, 0, 0, 0, 24, 1),
(2663, 0, 0, 0, 'Treetop 5 (Shop)', 80000, 5, 0, 0, 0, 0, 54, 1),
(2664, 0, 0, 0, 'Treetop 12 (Shop)', 100000, 5, 0, 0, 0, 0, 56, 1),
(2665, 0, 0, 0, 'Treetop 4 (Shop)', 80000, 5, 0, 0, 0, 0, 48, 1),
(2666, 0, 0, 0, 'Treetop 3 (Shop)', 80000, 5, 0, 0, 0, 0, 60, 1),
(2667, 0, 0, 0, 'Shadow Caves 1', 100000, 5, 0, 0, 0, 0, 20, 1),
(2668, 0, 0, 0, 'Shadow Caves 2', 100000, 5, 0, 0, 0, 0, 25, 1),
(2669, 0, 0, 0, 'Shadow Caves 3', 100000, 5, 0, 0, 0, 0, 20, 1),
(2670, 0, 0, 0, 'Shadow Caves 4', 100000, 5, 0, 0, 0, 0, 25, 1),
(2671, 0, 0, 0, 'Shadow Caves 5', 0, 5, 0, 0, 0, 0, 20, 1),
(2672, 0, 0, 0, 'Shadow Caves 6', 0, 5, 0, 0, 0, 0, 20, 1),
(2673, 0, 0, 0, 'Shadow Caves 7', 0, 5, 0, 0, 0, 0, 20, 1),
(2674, 0, 0, 0, 'Shadow Caves 8', 100000, 5, 0, 0, 0, 0, 25, 1),
(2675, 0, 0, 0, 'Shadow Caves 9', 0, 5, 0, 0, 0, 0, 20, 1),
(2676, 0, 0, 0, 'Shadow Caves 10', 0, 5, 0, 0, 0, 0, 20, 1),
(2677, 0, 0, 0, 'Shadow Caves 11', 0, 5, 0, 0, 0, 0, 20, 1),
(2678, 0, 0, 0, 'Shadow Caves 12', 0, 5, 0, 0, 0, 0, 20, 1),
(2679, 0, 0, 0, 'Shadow Caves 13', 0, 5, 0, 0, 0, 0, 20, 1),
(2680, 0, 0, 0, 'Shadow Caves 14', 0, 5, 0, 0, 0, 0, 20, 1),
(2681, 0, 0, 0, 'Shadow Caves 15', 0, 5, 0, 0, 0, 0, 20, 1),
(2682, 0, 0, 0, 'Shadow Caves 16', 0, 5, 0, 0, 0, 0, 20, 1),
(2683, 0, 0, 0, 'Shadow Caves 17', 0, 5, 0, 0, 0, 0, 20, 1),
(2684, 0, 0, 0, 'Shadow Caves 18', 0, 5, 0, 0, 0, 0, 20, 1),
(2685, 0, 0, 0, 'Shadow Caves 19', 0, 5, 0, 0, 0, 0, 20, 1),
(2686, 0, 0, 0, 'Shadow Caves 20', 0, 5, 0, 0, 0, 0, 20, 1),
(2687, 0, 0, 0, 'Northern Street 1a', 100000, 6, 0, 0, 0, 0, 42, 2),
(2688, 0, 0, 0, 'Park Lane 3a', 100000, 6, 0, 0, 0, 0, 48, 2),
(2689, 0, 0, 0, 'Park Lane 1a', 150000, 6, 0, 0, 0, 0, 53, 2),
(2690, 0, 0, 0, 'Park Lane 4', 150000, 6, 0, 0, 0, 0, 42, 2),
(2691, 0, 0, 0, 'Park Lane 2', 150000, 6, 0, 0, 0, 0, 42, 2),
(2692, 0, 0, 0, 'Theater Avenue 7, Flat 04', 25000, 6, 0, 0, 0, 0, 20, 1),
(2693, 0, 0, 0, 'Theater Avenue 7, Flat 03', 25000, 6, 0, 0, 0, 0, 19, 1),
(2694, 0, 0, 0, 'Theater Avenue 7, Flat 05', 25000, 6, 0, 0, 0, 0, 20, 1),
(2695, 0, 0, 0, 'Theater Avenue 7, Flat 06', 25000, 6, 0, 0, 0, 0, 20, 1),
(2696, 0, 0, 0, 'Theater Avenue 7, Flat 02', 25000, 6, 0, 0, 0, 0, 20, 1),
(2697, 0, 0, 0, 'Theater Avenue 7, Flat 01', 25000, 6, 0, 0, 0, 0, 20, 1),
(2698, 0, 0, 0, 'Northern Street 5', 200000, 6, 0, 0, 0, 0, 68, 2),
(2699, 0, 0, 0, 'Northern Street 7', 150000, 6, 0, 0, 0, 0, 59, 2),
(2700, 0, 0, 0, 'Theater Avenue 6e', 80000, 6, 0, 0, 0, 0, 31, 2),
(2701, 0, 0, 0, 'Theater Avenue 6c', 25000, 6, 0, 0, 0, 0, 12, 1),
(2702, 0, 0, 0, 'Theater Avenue 6a', 80000, 6, 0, 0, 0, 0, 35, 2),
(2703, 0, 0, 0, 'Theater Avenue, Tower', 300000, 6, 0, 0, 0, 0, 125, 0),
(2705, 0, 0, 0, 'East Lane 2', 300000, 6, 0, 0, 0, 0, 111, 2),
(2706, 0, 0, 0, 'Harbour Lane 2a (Shop)', 80000, 6, 0, 0, 0, 0, 32, 0),
(2707, 0, 0, 0, 'Harbour Lane 2b (Shop)', 80000, 6, 0, 0, 0, 0, 40, 0),
(2708, 0, 0, 0, 'Harbour Lane 3', 400000, 6, 0, 0, 0, 0, 113, 3),
(2709, 0, 0, 0, 'Magician\'s Alley 8', 150000, 6, 0, 0, 0, 0, 49, 2),
(2710, 0, 0, 0, 'Lonely Sea Side Hostel', 400000, 6, 0, 0, 0, 0, 397, 8),
(2711, 0, 0, 0, 'Suntower', 500000, 6, 0, 0, 0, 0, 451, 7),
(2712, 0, 0, 0, 'House of Recreation', 500000, 6, 0, 0, 0, 0, 687, 16),
(2713, 0, 0, 0, 'Carlin Clanhall', 250000, 6, 0, 0, 0, 0, 374, 10),
(2714, 0, 0, 0, 'Magician\'s Alley 4', 200000, 6, 0, 0, 0, 0, 96, 4),
(2715, 0, 0, 0, 'Theater Avenue 14 (Shop)', 200000, 6, 0, 0, 0, 0, 83, 1),
(2716, 0, 0, 0, 'Theater Avenue 12', 80000, 6, 0, 0, 0, 0, 28, 2),
(2717, 0, 0, 0, 'Magician\'s Alley 1', 100000, 6, 0, 0, 0, 0, 35, 2),
(2718, 0, 0, 0, 'Theater Avenue 10', 100000, 6, 0, 0, 0, 0, 45, 2),
(2719, 0, 0, 0, 'Magician\'s Alley 1b', 25000, 6, 0, 0, 0, 0, 24, 2),
(2720, 0, 0, 0, 'Magician\'s Alley 1a', 25000, 6, 0, 0, 0, 0, 28, 2),
(2721, 0, 0, 0, 'Magician\'s Alley 1c', 25000, 6, 0, 0, 0, 0, 20, 1),
(2722, 0, 0, 0, 'Magician\'s Alley 1d', 25000, 6, 0, 0, 0, 0, 24, 1),
(2723, 0, 0, 0, 'Magician\'s Alley 5c', 100000, 6, 0, 0, 0, 0, 35, 2),
(2724, 0, 0, 0, 'Magician\'s Alley 5f', 80000, 6, 0, 0, 0, 0, 42, 2),
(2725, 0, 0, 0, 'Magician\'s Alley 5b', 50000, 6, 0, 0, 0, 0, 40, 2),
(2727, 0, 0, 0, 'Magician\'s Alley 5a', 50000, 6, 0, 0, 0, 0, 45, 2),
(2729, 0, 0, 0, 'Central Plaza 3 (Shop)', 50000, 6, 0, 0, 0, 0, 24, 0),
(2730, 0, 0, 0, 'Central Plaza 2 (Shop)', 50000, 6, 0, 0, 0, 0, 24, 0),
(2731, 0, 0, 0, 'Central Plaza 1 (Shop)', 50000, 6, 0, 0, 0, 0, 24, 0),
(2732, 0, 0, 0, 'Theater Avenue 8b', 100000, 6, 0, 0, 0, 0, 49, 2),
(2733, 0, 0, 0, 'Harbour Lane 1 (Shop)', 100000, 6, 0, 0, 0, 0, 54, 0),
(2734, 0, 0, 0, 'Theater Avenue 6f', 80000, 6, 0, 0, 0, 0, 31, 2),
(2735, 0, 0, 0, 'Theater Avenue 6d', 25000, 6, 0, 0, 0, 0, 12, 1),
(2736, 0, 0, 0, 'Theater Avenue 6b', 80000, 6, 0, 0, 0, 0, 35, 2),
(2737, 0, 0, 0, 'Northern Street 3a', 80000, 6, 0, 0, 0, 0, 34, 2),
(2738, 0, 0, 0, 'Northern Street 3b', 80000, 6, 0, 0, 0, 0, 36, 2),
(2739, 0, 0, 0, 'Northern Street 1b', 80000, 6, 0, 0, 0, 0, 37, 2),
(2740, 0, 0, 0, 'Northern Street 1c', 80000, 6, 0, 0, 0, 0, 35, 2),
(2741, 0, 0, 0, 'Theater Avenue 7, Flat 14', 25000, 6, 0, 0, 0, 0, 20, 1),
(2742, 0, 0, 0, 'Theater Avenue 7, Flat 13', 25000, 6, 0, 0, 0, 0, 20, 1),
(2743, 0, 0, 0, 'Theater Avenue 7, Flat 15', 25000, 6, 0, 0, 0, 0, 20, 1),
(2744, 0, 0, 0, 'Theater Avenue 7, Flat 12', 25000, 6, 0, 0, 0, 0, 20, 1),
(2745, 0, 0, 0, 'Theater Avenue 7, Flat 11', 25000, 6, 0, 0, 0, 0, 24, 1),
(2746, 0, 0, 0, 'Theater Avenue 7, Flat 16', 25000, 6, 0, 0, 0, 0, 24, 1),
(2747, 0, 0, 0, 'Theater Avenue 5', 200000, 6, 0, 0, 0, 0, 165, 3),
(2751, 0, 0, 0, 'Harbour Flats, Flat 11', 25000, 6, 0, 0, 0, 0, 24, 1),
(2752, 0, 0, 0, 'Harbour Flats, Flat 13', 25000, 6, 0, 0, 0, 0, 24, 1),
(2753, 0, 0, 0, 'Harbour Flats, Flat 15', 50000, 6, 0, 0, 0, 0, 38, 2),
(2755, 0, 0, 0, 'Harbour Flats, Flat 12', 50000, 6, 0, 0, 0, 0, 40, 2),
(2757, 0, 0, 0, 'Harbour Flats, Flat 16', 50000, 6, 0, 0, 0, 0, 45, 2),
(2759, 0, 0, 0, 'Harbour Flats, Flat 21', 50000, 6, 0, 0, 0, 0, 35, 2),
(2760, 0, 0, 0, 'Harbour Flats, Flat 22', 80000, 6, 0, 0, 0, 0, 45, 2),
(2761, 0, 0, 0, 'Harbour Flats, Flat 23', 25000, 6, 0, 0, 0, 0, 25, 1),
(2763, 0, 0, 0, 'Park Lane 1b', 200000, 6, 0, 0, 0, 0, 54, 2),
(2764, 0, 0, 0, 'Theater Avenue 8a', 100000, 6, 0, 0, 0, 0, 49, 3),
(2765, 0, 0, 0, 'Theater Avenue 11a', 100000, 6, 0, 0, 0, 0, 48, 2),
(2767, 0, 0, 0, 'Theater Avenue 11b', 100000, 6, 0, 0, 0, 0, 54, 2),
(2768, 0, 0, 0, 'Caretaker\'s Residence', 600000, 6, 0, 0, 0, 0, 423, 0),
(2769, 0, 0, 0, 'Moonkeep', 250000, 6, 0, 0, 0, 0, 518, 16),
(2770, 0, 0, 0, 'Mangrove 1', 80000, 5, 0, 0, 0, 0, 56, 3),
(2771, 0, 0, 0, 'Coastwood 2', 50000, 5, 0, 0, 0, 0, 28, 2),
(2772, 0, 0, 0, 'Coastwood 1', 50000, 5, 0, 0, 0, 0, 35, 2),
(2773, 0, 0, 0, 'Coastwood 3', 50000, 5, 0, 0, 0, 0, 37, 2),
(2774, 0, 0, 0, 'Coastwood 4', 50000, 5, 0, 0, 0, 0, 42, 2),
(2775, 0, 0, 0, 'Mangrove 4', 50000, 5, 0, 0, 0, 0, 36, 2),
(2776, 0, 0, 0, 'Coastwood 10', 80000, 5, 0, 0, 0, 0, 49, 3),
(2777, 0, 0, 0, 'Coastwood 5', 50000, 5, 0, 0, 0, 0, 49, 2),
(2778, 0, 0, 0, 'Coastwood 6 (Shop)', 80000, 5, 0, 0, 0, 0, 48, 1),
(2779, 0, 0, 0, 'Coastwood 7', 25000, 5, 0, 0, 0, 0, 29, 1),
(2780, 0, 0, 0, 'Coastwood 8', 50000, 5, 0, 0, 0, 0, 42, 2),
(2781, 0, 0, 0, 'Coastwood 9', 50000, 5, 0, 0, 0, 0, 36, 1),
(2782, 0, 0, 0, 'Treetop 2', 25000, 5, 0, 0, 0, 0, 24, 1),
(2783, 0, 0, 0, 'Treetop 1', 25000, 5, 0, 0, 0, 0, 30, 1),
(2784, 0, 0, 0, 'Mangrove 3', 80000, 5, 0, 0, 0, 0, 42, 2),
(2785, 0, 0, 0, 'Mangrove 2', 50000, 5, 0, 0, 0, 0, 48, 2),
(2786, 0, 0, 0, 'The Hideout', 250000, 5, 0, 0, 0, 0, 584, 20),
(2787, 0, 0, 0, 'Shadow Towers', 250000, 5, 0, 0, 0, 0, 708, 18),
(2788, 0, 0, 0, 'Druids Retreat A', 50000, 6, 0, 0, 0, 0, 60, 2),
(2789, 0, 0, 0, 'Druids Retreat C', 50000, 6, 0, 0, 0, 0, 45, 2),
(2790, 0, 0, 0, 'Druids Retreat B', 50000, 6, 0, 0, 0, 0, 56, 2),
(2791, 0, 0, 0, 'Druids Retreat D', 80000, 6, 0, 0, 0, 0, 51, 2),
(2792, 0, 0, 0, 'East Lane 1b', 150000, 6, 0, 0, 0, 0, 53, 2),
(2793, 0, 0, 0, 'East Lane 1a', 200000, 6, 0, 0, 0, 0, 87, 2),
(2794, 0, 0, 0, 'Senja Village 11', 80000, 6, 0, 0, 0, 0, 92, 2),
(2795, 0, 0, 0, 'Senja Village 10', 50000, 6, 0, 0, 0, 0, 72, 1),
(2796, 0, 0, 0, 'Senja Village 9', 80000, 6, 0, 0, 0, 0, 112, 2),
(2797, 0, 0, 0, 'Senja Village 8', 50000, 6, 0, 0, 0, 0, 72, 2),
(2798, 0, 0, 0, 'Senja Village 7', 25000, 6, 0, 0, 0, 0, 36, 2),
(2799, 0, 0, 0, 'Senja Village 6b', 25000, 6, 0, 0, 0, 0, 30, 1),
(2800, 0, 0, 0, 'Senja Village 6a', 50000, 6, 0, 0, 0, 0, 30, 1),
(2801, 0, 0, 0, 'Senja Village 5', 50000, 6, 0, 0, 0, 0, 48, 2),
(2802, 0, 0, 0, 'Senja Village 4', 50000, 6, 0, 0, 0, 0, 66, 2),
(2803, 0, 0, 0, 'Senja Village 3', 50000, 6, 0, 0, 0, 0, 72, 2),
(2804, 0, 0, 0, 'Senja Village 1b', 50000, 6, 0, 0, 0, 0, 66, 2),
(2805, 0, 0, 0, 'Senja Village 1a', 25000, 6, 0, 0, 0, 0, 36, 1),
(2806, 0, 0, 0, 'Rosebud C', 100000, 6, 0, 0, 0, 0, 70, 0),
(2807, 0, 0, 0, 'Rosebud B', 80000, 6, 0, 0, 0, 0, 60, 1),
(2808, 0, 0, 0, 'Rosebud A', 50000, 6, 0, 0, 0, 0, 60, 1),
(2809, 0, 0, 0, 'Park Lane 3b', 100000, 6, 0, 0, 0, 0, 48, 2),
(2810, 0, 0, 0, 'Northport Village 6', 80000, 6, 0, 0, 0, 0, 64, 2),
(2811, 0, 0, 0, 'Northport Village 5', 80000, 6, 0, 0, 0, 0, 56, 2),
(2812, 0, 0, 0, 'Northport Village 4', 100000, 6, 0, 0, 0, 0, 92, 2),
(2813, 0, 0, 0, 'Northport Village 3', 150000, 6, 0, 0, 0, 0, 119, 2),
(2814, 0, 0, 0, 'Northport Village 2', 50000, 6, 0, 0, 0, 0, 40, 2),
(2815, 0, 0, 0, 'Northport Village 1', 50000, 6, 0, 0, 0, 0, 48, 2),
(2816, 0, 0, 0, 'Nautic Observer', 200000, 6, 0, 0, 0, 0, 226, 4),
(2817, 0, 0, 0, 'Nordic Stronghold', 250000, 6, 0, 0, 0, 0, 809, 21),
(2818, 0, 0, 0, 'Senja Clanhall', 250000, 6, 0, 0, 0, 0, 396, 9),
(2819, 0, 0, 0, 'Seawatch', 250000, 6, 0, 0, 0, 0, 749, 19),
(2820, 0, 0, 0, 'Dwarven Magnate\'s Estate', 300000, 7, 0, 0, 0, 0, 395, 0),
(2821, 0, 0, 0, 'Forge Master\'s Quarters', 300000, 7, 0, 0, 0, 0, 117, 0),
(2822, 0, 0, 0, 'Upper Barracks 13', 25000, 7, 0, 0, 0, 0, 24, 2),
(2823, 0, 0, 0, 'Upper Barracks 5', 80000, 7, 0, 0, 0, 0, 50, 3),
(2824, 0, 0, 0, 'Upper Barracks 3', 80000, 7, 0, 0, 0, 0, 24, 2),
(2825, 0, 0, 0, 'Upper Barracks 4', 50000, 7, 0, 0, 0, 0, 35, 2),
(2826, 0, 0, 0, 'Upper Barracks 2', 80000, 7, 0, 0, 0, 0, 50, 3),
(2827, 0, 0, 0, 'Upper Barracks 1', 50000, 7, 0, 0, 0, 0, 35, 2),
(2828, 0, 0, 0, 'Tunnel Gardens 9', 150000, 7, 0, 0, 0, 0, 145, 7),
(2829, 0, 0, 0, 'Tunnel Gardens 8', 25000, 7, 0, 0, 0, 0, 42, 2),
(2830, 0, 0, 0, 'Tunnel Gardens 7', 50000, 7, 0, 0, 0, 0, 35, 2),
(2831, 0, 0, 0, 'Tunnel Gardens 6', 25000, 7, 0, 0, 0, 0, 42, 2),
(2832, 0, 0, 0, 'Tunnel Gardens 5', 25000, 7, 0, 0, 0, 0, 35, 2),
(2835, 0, 0, 0, 'Tunnel Gardens 4', 80000, 7, 0, 0, 0, 0, 58, 3),
(2836, 0, 0, 0, 'Tunnel Gardens 2', 80000, 7, 0, 0, 0, 0, 54, 3),
(2837, 0, 0, 0, 'Tunnel Gardens 1', 80000, 7, 0, 0, 0, 0, 47, 3),
(2838, 0, 0, 0, 'Tunnel Gardens 3', 80000, 7, 0, 0, 0, 0, 65, 3),
(2839, 0, 0, 0, 'The Market 4 (Shop)', 80000, 7, 0, 0, 0, 0, 63, 1),
(2840, 0, 0, 0, 'The Market 3 (Shop)', 80000, 7, 0, 0, 0, 0, 54, 1),
(2841, 0, 0, 0, 'The Market 2 (Shop)', 50000, 7, 0, 0, 0, 0, 45, 1),
(2842, 0, 0, 0, 'The Market 1 (Shop)', 25000, 7, 0, 0, 0, 0, 25, 1),
(2843, 0, 0, 0, 'The Farms 6, Fishing Hut', 50000, 7, 0, 0, 0, 0, 42, 2),
(2844, 0, 0, 0, 'The Farms 5', 50000, 7, 0, 0, 0, 0, 49, 2),
(2845, 0, 0, 0, 'The Farms 4', 25000, 7, 0, 0, 0, 0, 49, 2),
(2846, 0, 0, 0, 'The Farms 3', 80000, 7, 0, 0, 0, 0, 49, 2),
(2847, 0, 0, 0, 'The Farms 2', 50000, 7, 0, 0, 0, 0, 49, 2),
(2849, 0, 0, 0, 'The Farms 1', 80000, 7, 0, 0, 0, 0, 78, 3),
(2850, 0, 0, 0, 'Outlaw Camp 14 (Shop)', 25000, 7, 0, 0, 0, 0, 35, 0),
(2852, 0, 0, 0, 'Outlaw Camp 13 (Shop)', 50000, 7, 0, 0, 0, 0, 40, 0),
(2853, 0, 0, 0, 'Outlaw Camp 9', 80000, 7, 0, 0, 0, 0, 40, 2),
(2854, 0, 0, 0, 'Outlaw Camp 7', 25000, 7, 0, 0, 0, 0, 38, 2),
(2855, 0, 0, 0, 'Outlaw Camp 4', 50000, 7, 0, 0, 0, 0, 40, 1),
(2856, 0, 0, 0, 'Outlaw Camp 2', 50000, 7, 0, 0, 0, 0, 40, 1),
(2857, 0, 0, 0, 'Outlaw Camp 3', 50000, 7, 0, 0, 0, 0, 35, 2),
(2858, 0, 0, 0, 'Outlaw Camp 1', 80000, 7, 0, 0, 0, 0, 54, 2),
(2859, 0, 0, 0, 'Nobility Quarter 5', 100000, 7, 0, 0, 0, 0, 143, 4),
(2860, 0, 0, 0, 'Nobility Quarter 4', 50000, 7, 0, 0, 0, 0, 66, 2),
(2861, 0, 0, 0, 'Nobility Quarter 3', 80000, 7, 0, 0, 0, 0, 56, 3),
(2862, 0, 0, 0, 'Nobility Quarter 2', 50000, 7, 0, 0, 0, 0, 61, 3),
(2863, 0, 0, 0, 'Nobility Quarter 1', 80000, 7, 0, 0, 0, 0, 64, 3),
(2864, 0, 0, 0, 'Lower Barracks 10', 80000, 7, 0, 0, 0, 0, 50, 2),
(2865, 0, 0, 0, 'Lower Barracks 9', 80000, 7, 0, 0, 0, 0, 50, 2),
(2866, 0, 0, 0, 'Lower Barracks 8', 80000, 7, 0, 0, 0, 0, 50, 2),
(2867, 0, 0, 0, 'Lower Barracks 1', 80000, 7, 0, 0, 0, 0, 50, 2),
(2868, 0, 0, 0, 'Lower Barracks 2', 80000, 7, 0, 0, 0, 0, 50, 2),
(2869, 0, 0, 0, 'Lower Barracks 3', 80000, 7, 0, 0, 0, 0, 50, 2),
(2870, 0, 0, 0, 'Lower Barracks 4', 80000, 7, 0, 0, 0, 0, 50, 1),
(2871, 0, 0, 0, 'Lower Barracks 5', 80000, 7, 0, 0, 0, 0, 100, 1),
(2872, 0, 0, 0, 'Lower Barracks 6', 80000, 7, 0, 0, 0, 0, 100, 2),
(2873, 0, 0, 0, 'Lower Barracks 7', 80000, 7, 0, 0, 0, 0, 50, 1),
(2874, 0, 0, 0, 'Wolftower', 500000, 7, 0, 0, 0, 0, 680, 23),
(2875, 0, 0, 0, 'Riverspring', 250000, 7, 0, 0, 0, 0, 632, 18),
(2876, 0, 0, 0, 'Outlaw Castle', 250000, 7, 0, 0, 0, 0, 356, 9),
(2877, 0, 0, 0, 'Marble Guildhall', 250000, 7, 0, 0, 0, 0, 425, 11),
(2878, 0, 0, 0, 'Iron Guildhall', 250000, 7, 0, 0, 0, 0, 534, 17),
(2879, 0, 0, 0, 'Hill Hideout', 250000, 7, 0, 0, 0, 0, 395, 15),
(2880, 0, 0, 0, 'Granite Guildhall', 250000, 7, 0, 0, 0, 0, 627, 17),
(2881, 0, 0, 0, 'Alai Flats, Flat 01', 50000, 8, 0, 0, 0, 0, 25, 1),
(2882, 0, 0, 0, 'Alai Flats, Flat 02', 50000, 8, 0, 0, 0, 0, 35, 1),
(2883, 0, 0, 0, 'Alai Flats, Flat 03', 50000, 8, 0, 0, 0, 0, 36, 1),
(2884, 0, 0, 0, 'Alai Flats, Flat 04', 80000, 8, 0, 0, 0, 0, 30, 1),
(2885, 0, 0, 0, 'Alai Flats, Flat 05', 100000, 8, 0, 0, 0, 0, 42, 2),
(2886, 0, 0, 0, 'Alai Flats, Flat 06', 100000, 8, 0, 0, 0, 0, 42, 2),
(2887, 0, 0, 0, 'Alai Flats, Flat 07', 25000, 8, 0, 0, 0, 0, 30, 1),
(2888, 0, 0, 0, 'Alai Flats, Flat 08', 50000, 8, 0, 0, 0, 0, 36, 1),
(2889, 0, 0, 0, 'Alai Flats, Flat 11', 80000, 8, 0, 0, 0, 0, 30, 1),
(2890, 0, 0, 0, 'Alai Flats, Flat 12', 25000, 8, 0, 0, 0, 0, 30, 1),
(2891, 0, 0, 0, 'Alai Flats, Flat 13', 50000, 8, 0, 0, 0, 0, 36, 1),
(2892, 0, 0, 0, 'Alai Flats, Flat 14', 80000, 8, 0, 0, 0, 0, 32, 1),
(2893, 0, 0, 0, 'Alai Flats, Flat 15', 100000, 8, 0, 0, 0, 0, 46, 2),
(2894, 0, 0, 0, 'Alai Flats, Flat 16', 100000, 8, 0, 0, 0, 0, 46, 2),
(2895, 0, 0, 0, 'Alai Flats, Flat 17', 80000, 8, 0, 0, 0, 0, 32, 1),
(2896, 0, 0, 0, 'Alai Flats, Flat 18', 50000, 8, 0, 0, 0, 0, 38, 1),
(2897, 0, 0, 0, 'Alai Flats, Flat 21', 50000, 8, 0, 0, 0, 0, 30, 1),
(2898, 0, 0, 0, 'Alai Flats, Flat 22', 50000, 8, 0, 0, 0, 0, 30, 1),
(2899, 0, 0, 0, 'Alai Flats, Flat 23', 25000, 8, 0, 0, 0, 0, 36, 1),
(2900, 0, 0, 0, 'Alai Flats, Flat 28', 80000, 8, 0, 0, 0, 0, 32, 1),
(2901, 0, 0, 0, 'Alai Flats, Flat 27', 80000, 8, 0, 0, 0, 0, 32, 1),
(2902, 0, 0, 0, 'Alai Flats, Flat 26', 100000, 8, 0, 0, 0, 0, 46, 2),
(2903, 0, 0, 0, 'Alai Flats, Flat 25', 100000, 8, 0, 0, 0, 0, 46, 2),
(2904, 0, 0, 0, 'Alai Flats, Flat 24', 80000, 8, 0, 0, 0, 0, 39, 1),
(2905, 0, 0, 0, 'Beach Home Apartments, Flat 01', 50000, 8, 0, 0, 0, 0, 25, 1),
(2906, 0, 0, 0, 'Beach Home Apartments, Flat 02', 80000, 8, 0, 0, 0, 0, 30, 1),
(2907, 0, 0, 0, 'Beach Home Apartments, Flat 03', 80000, 8, 0, 0, 0, 0, 24, 1),
(2908, 0, 0, 0, 'Beach Home Apartments, Flat 04', 50000, 8, 0, 0, 0, 0, 24, 1),
(2909, 0, 0, 0, 'Beach Home Apartments, Flat 05', 80000, 8, 0, 0, 0, 0, 30, 1),
(2910, 0, 0, 0, 'Beach Home Apartments, Flat 06', 100000, 8, 0, 0, 0, 0, 40, 2),
(2911, 0, 0, 0, 'Beach Home Apartments, Flat 11', 25000, 8, 0, 0, 0, 0, 25, 1),
(2912, 0, 0, 0, 'Beach Home Apartments, Flat 12', 50000, 8, 0, 0, 0, 0, 30, 1),
(2913, 0, 0, 0, 'Beach Home Apartments, Flat 13', 80000, 8, 0, 0, 0, 0, 30, 1),
(2914, 0, 0, 0, 'Beach Home Apartments, Flat 14', 25000, 8, 0, 0, 0, 0, 15, 1),
(2915, 0, 0, 0, 'Beach Home Apartments, Flat 15', 25000, 8, 0, 0, 0, 0, 20, 1),
(2916, 0, 0, 0, 'Beach Home Apartments, Flat 16', 80000, 8, 0, 0, 0, 0, 40, 2),
(2917, 0, 0, 0, 'Demon Tower', 100000, 8, 0, 0, 0, 0, 150, 2),
(2918, 0, 0, 0, 'Farm Lane, 1st floor (Shop)', 80000, 8, 0, 0, 0, 0, 36, 0),
(2919, 0, 0, 0, 'Farm Lane, 2nd Floor (Shop)', 50000, 8, 0, 0, 0, 0, 36, 0),
(2920, 0, 0, 0, 'Farm Lane, Basement (Shop)', 50000, 8, 0, 0, 0, 0, 42, 0),
(2921, 0, 0, 0, 'Fibula Village 1', 25000, 8, 0, 0, 0, 0, 30, 1),
(2922, 0, 0, 0, 'Fibula Village 2', 25000, 8, 0, 0, 0, 0, 30, 1),
(2923, 0, 0, 0, 'Fibula Village 4', 25000, 8, 0, 0, 0, 0, 42, 2),
(2924, 0, 0, 0, 'Fibula Village 5', 50000, 8, 0, 0, 0, 0, 49, 2),
(2925, 0, 0, 0, 'Fibula Village 3', 80000, 8, 0, 0, 0, 0, 110, 4),
(2926, 0, 0, 0, 'Fibula Village, Tower Flat', 100000, 8, 0, 0, 0, 0, 156, 2),
(2927, 0, 0, 0, 'Guildhall of the Red Rose', 250000, 8, 0, 0, 0, 0, 597, 15),
(2928, 0, 0, 0, 'Fibula Village, Bar (Shop)', 100000, 8, 0, 0, 0, 0, 127, 2),
(2929, 0, 0, 0, 'Fibula Village, Villa', 200000, 8, 0, 0, 0, 0, 397, 5),
(2930, 0, 0, 0, 'Greenshore Village 1', 80000, 8, 0, 0, 0, 0, 64, 3),
(2931, 0, 0, 0, 'Greenshore Clanhall', 250000, 8, 0, 0, 0, 0, 312, 10),
(2932, 0, 0, 0, 'Castle of Greenshore', 250000, 8, 0, 0, 0, 0, 474, 12),
(2933, 0, 0, 0, 'Greenshore Village, Shop', 80000, 8, 0, 0, 0, 0, 64, 1),
(2934, 0, 0, 0, 'Greenshore Village, Villa', 300000, 8, 0, 0, 0, 0, 262, 4),
(2935, 0, 0, 0, 'Greenshore Village 7', 25000, 8, 0, 0, 0, 0, 42, 1),
(2936, 0, 0, 0, 'Greenshore Village 3', 50000, 8, 0, 0, 0, 0, 55, 2),
(2939, 0, 0, 0, 'Greenshore Village 2', 50000, 8, 0, 0, 0, 0, 55, 2),
(2940, 0, 0, 0, 'Greenshore Village 6', 150000, 8, 0, 0, 0, 0, 112, 2),
(2941, 0, 0, 0, 'Harbour Place 1 (Shop)', 800000, 8, 0, 0, 0, 0, 48, 1),
(2942, 0, 0, 0, 'Harbour Place 2 (Shop)', 600000, 8, 0, 0, 0, 0, 54, 1),
(2943, 0, 0, 0, 'Harbour Place 3', 800000, 8, 0, 0, 0, 0, 138, 0),
(2944, 0, 0, 0, 'Harbour Place 4', 80000, 8, 0, 0, 0, 0, 36, 1),
(2945, 0, 0, 0, 'Lower Swamp Lane 1', 400000, 8, 0, 0, 0, 0, 156, 4),
(2946, 0, 0, 0, 'Lower Swamp Lane 3', 400000, 8, 0, 0, 0, 0, 156, 4),
(2947, 0, 0, 0, 'Main Street 9, 1st floor (Shop)', 200000, 8, 0, 0, 0, 0, 63, 0),
(2948, 0, 0, 0, 'Main Street 9a, 2nd floor (Shop)', 100000, 8, 0, 0, 0, 0, 30, 0),
(2949, 0, 0, 0, 'Main Street 9b, 2nd floor (Shop)', 150000, 8, 0, 0, 0, 0, 57, 0),
(2950, 0, 0, 0, 'Mill Avenue 1 (Shop)', 200000, 8, 0, 0, 0, 0, 54, 1),
(2951, 0, 0, 0, 'Mill Avenue 2 (Shop)', 200000, 8, 0, 0, 0, 0, 100, 2),
(2952, 0, 0, 0, 'Mill Avenue 3', 100000, 8, 0, 0, 0, 0, 49, 2),
(2953, 0, 0, 0, 'Mill Avenue 4', 100000, 8, 0, 0, 0, 0, 49, 2),
(2954, 0, 0, 0, 'Mill Avenue 5', 300000, 8, 0, 0, 0, 0, 116, 4),
(2955, 0, 0, 0, 'Open-Air Theatre', 150000, 8, 0, 0, 0, 0, 111, 1),
(2956, 0, 0, 0, 'Smuggler\'s Den', 400000, 8, 0, 0, 0, 0, 298, 0),
(2957, 0, 0, 0, 'Sorcerer\'s Avenue 1a', 100000, 8, 0, 0, 0, 0, 42, 2),
(2958, 0, 0, 0, 'Sorcerer\'s Avenue 5 (Shop)', 150000, 8, 0, 0, 0, 0, 96, 1),
(2959, 0, 0, 0, 'Sorcerer\'s Avenue 1b', 80000, 8, 0, 0, 0, 0, 30, 2),
(2960, 0, 0, 0, 'Sorcerer\'s Avenue 1c', 50000, 8, 0, 0, 0, 0, 42, 2),
(2961, 0, 0, 0, 'Sorcerer\'s Avenue Labs 2a', 50000, 8, 0, 0, 0, 0, 54, 2),
(2962, 0, 0, 0, 'Sorcerer\'s Avenue Labs 2c', 50000, 8, 0, 0, 0, 0, 48, 2),
(2963, 0, 0, 0, 'Sorcerer\'s Avenue Labs 2b', 50000, 8, 0, 0, 0, 0, 54, 2),
(2964, 0, 0, 0, 'Sunset Homes, Flat 01', 100000, 8, 0, 0, 0, 0, 25, 1),
(2965, 0, 0, 0, 'Sunset Homes, Flat 02', 80000, 8, 0, 0, 0, 0, 30, 1),
(2966, 0, 0, 0, 'Sunset Homes, Flat 03', 80000, 8, 0, 0, 0, 0, 30, 1),
(2967, 0, 0, 0, 'Sunset Homes, Flat 11', 80000, 8, 0, 0, 0, 0, 25, 1),
(2968, 0, 0, 0, 'Sunset Homes, Flat 12', 50000, 8, 0, 0, 0, 0, 26, 1),
(2969, 0, 0, 0, 'Sunset Homes, Flat 13', 100000, 8, 0, 0, 0, 0, 35, 2),
(2970, 0, 0, 0, 'Sunset Homes, Flat 14', 50000, 8, 0, 0, 0, 0, 30, 1),
(2971, 0, 0, 0, 'Sunset Homes, Flat 21', 50000, 8, 0, 0, 0, 0, 25, 1),
(2972, 0, 0, 0, 'Sunset Homes, Flat 22', 50000, 8, 0, 0, 0, 0, 26, 1),
(2973, 0, 0, 0, 'Sunset Homes, Flat 23', 80000, 8, 0, 0, 0, 0, 35, 2),
(2974, 0, 0, 0, 'Sunset Homes, Flat 24', 50000, 8, 0, 0, 0, 0, 30, 1),
(2975, 0, 0, 0, 'Thais Hostel', 200000, 8, 0, 0, 0, 0, 171, 24),
(2976, 0, 0, 0, 'The City Wall 1a', 150000, 8, 0, 0, 0, 0, 49, 2),
(2977, 0, 0, 0, 'The City Wall 1b', 100000, 8, 0, 0, 0, 0, 49, 2),
(2978, 0, 0, 0, 'The City Wall 3a', 100000, 8, 0, 0, 0, 0, 35, 2);
INSERT INTO `houses` (`id`, `owner`, `paid`, `warnings`, `name`, `rent`, `town_id`, `bid`, `bid_end`, `last_bid`, `highest_bidder`, `size`, `beds`) VALUES
(2979, 0, 0, 0, 'The City Wall 3b', 100000, 8, 0, 0, 0, 0, 35, 2),
(2980, 0, 0, 0, 'The City Wall 3c', 100000, 8, 0, 0, 0, 0, 42, 2),
(2981, 0, 0, 0, 'The City Wall 3d', 100000, 8, 0, 0, 0, 0, 35, 2),
(2982, 0, 0, 0, 'The City Wall 3e', 100000, 8, 0, 0, 0, 0, 35, 2),
(2983, 0, 0, 0, 'The City Wall 3f', 100000, 8, 0, 0, 0, 0, 42, 2),
(2984, 0, 0, 0, 'Upper Swamp Lane 12', 300000, 8, 0, 0, 0, 0, 124, 3),
(2985, 0, 0, 0, 'Upper Swamp Lane 10', 150000, 8, 0, 0, 0, 0, 70, 3),
(2986, 0, 0, 0, 'Upper Swamp Lane 8', 600000, 8, 0, 0, 0, 0, 206, 3),
(2987, 0, 0, 0, 'Upper Swamp Lane 4', 600000, 8, 0, 0, 0, 0, 176, 4),
(2988, 0, 0, 0, 'Upper Swamp Lane 2', 600000, 8, 0, 0, 0, 0, 176, 4),
(2989, 0, 0, 0, 'The City Wall 9', 80000, 8, 0, 0, 0, 0, 50, 2),
(2990, 0, 0, 0, 'The City Wall 7h', 50000, 8, 0, 0, 0, 0, 30, 1),
(2991, 0, 0, 0, 'The City Wall 7b', 25000, 8, 0, 0, 0, 0, 30, 1),
(2992, 0, 0, 0, 'The City Wall 7d', 50000, 8, 0, 0, 0, 0, 36, 2),
(2993, 0, 0, 0, 'The City Wall 7f', 80000, 8, 0, 0, 0, 0, 36, 2),
(2994, 0, 0, 0, 'The City Wall 7c', 80000, 8, 0, 0, 0, 0, 36, 2),
(2995, 0, 0, 0, 'The City Wall 7a', 80000, 8, 0, 0, 0, 0, 30, 1),
(2996, 0, 0, 0, 'The City Wall 7g', 50000, 8, 0, 0, 0, 0, 30, 1),
(2997, 0, 0, 0, 'The City Wall 7e', 80000, 8, 0, 0, 0, 0, 36, 2),
(2998, 0, 0, 0, 'The City Wall 5b', 50000, 8, 0, 0, 0, 0, 24, 1),
(2999, 0, 0, 0, 'The City Wall 5d', 50000, 8, 0, 0, 0, 0, 24, 1),
(3000, 0, 0, 0, 'The City Wall 5f', 25000, 8, 0, 0, 0, 0, 30, 1),
(3001, 0, 0, 0, 'The City Wall 5a', 50000, 8, 0, 0, 0, 0, 24, 1),
(3002, 0, 0, 0, 'The City Wall 5c', 50000, 8, 0, 0, 0, 0, 24, 1),
(3003, 0, 0, 0, 'The City Wall 5e', 50000, 8, 0, 0, 0, 0, 30, 1),
(3004, 0, 0, 0, 'Warriors\' Guildhall', 5000000, 8, 0, 0, 0, 0, 535, 11),
(3005, 0, 0, 0, 'The Tibianic', 500000, 8, 0, 0, 0, 0, 824, 22),
(3006, 0, 0, 0, 'Bloodhall', 500000, 8, 0, 0, 0, 0, 539, 15),
(3007, 0, 0, 0, 'Fibula Clanhall', 250000, 8, 0, 0, 0, 0, 305, 10),
(3008, 0, 0, 0, 'Dark Mansion', 1000000, 8, 0, 0, 0, 0, 590, 17),
(3009, 0, 0, 0, 'Halls of the Adventurers', 250000, 8, 0, 0, 0, 0, 512, 18),
(3010, 0, 0, 0, 'Mercenary Tower', 250000, 8, 0, 0, 0, 0, 982, 26),
(3011, 0, 0, 0, 'Snake Tower', 500000, 8, 0, 0, 0, 0, 1041, 21),
(3012, 0, 0, 0, 'Southern Thais Guildhall', 1000000, 8, 0, 0, 0, 0, 635, 16),
(3013, 0, 0, 0, 'Spiritkeep', 500000, 8, 0, 0, 0, 0, 564, 13),
(3014, 0, 0, 0, 'Thais Clanhall', 500000, 8, 0, 0, 0, 0, 380, 10),
(3015, 0, 0, 0, 'The Lair', 200000, 9, 0, 0, 0, 0, 335, 3),
(3016, 0, 0, 0, 'Silver Street 4', 300000, 9, 0, 0, 0, 0, 153, 2),
(3017, 0, 0, 0, 'Dream Street 1 (Shop)', 600000, 9, 0, 0, 0, 0, 178, 2),
(3018, 0, 0, 0, 'Dagger Alley 1', 200000, 9, 0, 0, 0, 0, 126, 2),
(3019, 0, 0, 0, 'Dream Street 2', 400000, 9, 0, 0, 0, 0, 138, 2),
(3020, 0, 0, 0, 'Dream Street 3', 300000, 9, 0, 0, 0, 0, 126, 2),
(3021, 0, 0, 0, 'Elm Street 1', 300000, 9, 0, 0, 0, 0, 114, 2),
(3022, 0, 0, 0, 'Elm Street 3', 300000, 9, 0, 0, 0, 0, 120, 3),
(3023, 0, 0, 0, 'Elm Street 2', 300000, 9, 0, 0, 0, 0, 120, 2),
(3024, 0, 0, 0, 'Elm Street 4', 300000, 9, 0, 0, 0, 0, 126, 2),
(3025, 0, 0, 0, 'Seagull Walk 1', 800000, 9, 0, 0, 0, 0, 202, 2),
(3026, 0, 0, 0, 'Seagull Walk 2', 300000, 9, 0, 0, 0, 0, 132, 3),
(3027, 0, 0, 0, 'Dream Street 4', 400000, 9, 0, 0, 0, 0, 168, 4),
(3028, 0, 0, 0, 'Old Lighthouse', 200000, 9, 0, 0, 0, 0, 177, 2),
(3029, 0, 0, 0, 'Market Street 1', 600000, 9, 0, 0, 0, 0, 258, 3),
(3030, 0, 0, 0, 'Market Street 3', 600000, 9, 0, 0, 0, 0, 150, 2),
(3031, 0, 0, 0, 'Market Street 4 (Shop)', 800000, 9, 0, 0, 0, 0, 209, 3),
(3032, 0, 0, 0, 'Market Street 5 (Shop)', 800000, 9, 0, 0, 0, 0, 243, 4),
(3033, 0, 0, 0, 'Market Street 2', 600000, 9, 0, 0, 0, 0, 200, 3),
(3034, 0, 0, 0, 'Loot Lane 1 (Shop)', 600000, 9, 0, 0, 0, 0, 198, 3),
(3035, 0, 0, 0, 'Mystic Lane 1', 300000, 9, 0, 0, 0, 0, 110, 3),
(3036, 0, 0, 0, 'Mystic Lane 2', 200000, 9, 0, 0, 0, 0, 139, 2),
(3037, 0, 0, 0, 'Lucky Lane 2 (Tower)', 600000, 9, 0, 0, 0, 0, 240, 2),
(3038, 0, 0, 0, 'Lucky Lane 3 (Tower)', 600000, 9, 0, 0, 0, 0, 240, 2),
(3039, 0, 0, 0, 'Iron Alley 1', 300000, 9, 0, 0, 0, 0, 120, 4),
(3040, 0, 0, 0, 'Iron Alley 2', 300000, 9, 0, 0, 0, 0, 144, 4),
(3041, 0, 0, 0, 'Swamp Watch', 500000, 9, 0, 0, 0, 0, 420, 12),
(3042, 0, 0, 0, 'Golden Axe Guildhall', 500000, 9, 0, 0, 0, 0, 390, 10),
(3043, 0, 0, 0, 'Silver Street 1', 200000, 9, 0, 0, 0, 0, 125, 1),
(3044, 0, 0, 0, 'Valorous Venore', 500000, 9, 0, 0, 0, 0, 507, 9),
(3045, 0, 0, 0, 'Salvation Street 2', 300000, 9, 0, 0, 0, 0, 135, 2),
(3046, 0, 0, 0, 'Salvation Street 3', 300000, 9, 0, 0, 0, 0, 162, 2),
(3047, 0, 0, 0, 'Silver Street 2', 200000, 9, 0, 0, 0, 0, 84, 1),
(3048, 0, 0, 0, 'Silver Street 3', 200000, 9, 0, 0, 0, 0, 105, 1),
(3049, 0, 0, 0, 'Mystic Lane 3 (Tower)', 800000, 9, 0, 0, 0, 0, 245, 0),
(3050, 0, 0, 0, 'Market Street 7', 200000, 9, 0, 0, 0, 0, 114, 2),
(3051, 0, 0, 0, 'Market Street 6', 600000, 9, 0, 0, 0, 0, 216, 5),
(3052, 0, 0, 0, 'Iron Alley Watch, Upper', 600000, 9, 0, 0, 0, 0, 252, 3),
(3053, 0, 0, 0, 'Iron Alley Watch, Lower', 600000, 9, 0, 0, 0, 0, 240, 2),
(3054, 0, 0, 0, 'Blessed Shield Guildhall', 500000, 9, 0, 0, 0, 0, 289, 9),
(3055, 0, 0, 0, 'Steel Home', 500000, 9, 0, 0, 0, 0, 441, 13),
(3056, 0, 0, 0, 'Salvation Street 1 (Shop)', 600000, 9, 0, 0, 0, 0, 249, 4),
(3057, 0, 0, 0, 'Lucky Lane 1 (Shop)', 800000, 9, 0, 0, 0, 0, 253, 4),
(3058, 0, 0, 0, 'Paupers Palace, Flat 34', 100000, 9, 0, 0, 0, 0, 60, 2),
(3059, 0, 0, 0, 'Paupers Palace, Flat 33', 50000, 9, 0, 0, 0, 0, 35, 1),
(3060, 0, 0, 0, 'Paupers Palace, Flat 32', 100000, 9, 0, 0, 0, 0, 50, 2),
(3061, 0, 0, 0, 'Paupers Palace, Flat 31', 80000, 9, 0, 0, 0, 0, 40, 1),
(3062, 0, 0, 0, 'Paupers Palace, Flat 28', 25000, 9, 0, 0, 0, 0, 15, 1),
(3063, 0, 0, 0, 'Paupers Palace, Flat 26', 25000, 9, 0, 0, 0, 0, 20, 1),
(3064, 0, 0, 0, 'Paupers Palace, Flat 24', 25000, 9, 0, 0, 0, 0, 20, 1),
(3065, 0, 0, 0, 'Paupers Palace, Flat 22', 25000, 9, 0, 0, 0, 0, 20, 1),
(3066, 0, 0, 0, 'Paupers Palace, Flat 21', 25000, 9, 0, 0, 0, 0, 20, 1),
(3067, 0, 0, 0, 'Paupers Palace, Flat 27', 50000, 9, 0, 0, 0, 0, 25, 2),
(3068, 0, 0, 0, 'Paupers Palace, Flat 25', 50000, 9, 0, 0, 0, 0, 25, 1),
(3069, 0, 0, 0, 'Paupers Palace, Flat 23', 50000, 9, 0, 0, 0, 0, 30, 1),
(3070, 0, 0, 0, 'Paupers Palace, Flat 11', 25000, 9, 0, 0, 0, 0, 15, 1),
(3071, 0, 0, 0, 'Paupers Palace, Flat 13', 50000, 9, 0, 0, 0, 0, 20, 1),
(3072, 0, 0, 0, 'Paupers Palace, Flat 15', 50000, 9, 0, 0, 0, 0, 20, 1),
(3073, 0, 0, 0, 'Paupers Palace, Flat 17', 25000, 9, 0, 0, 0, 0, 20, 1),
(3074, 0, 0, 0, 'Paupers Palace, Flat 18', 25000, 9, 0, 0, 0, 0, 20, 1),
(3075, 0, 0, 0, 'Paupers Palace, Flat 12', 50000, 9, 0, 0, 0, 0, 25, 2),
(3076, 0, 0, 0, 'Paupers Palace, Flat 14', 50000, 9, 0, 0, 0, 0, 25, 1),
(3077, 0, 0, 0, 'Paupers Palace, Flat 16', 50000, 9, 0, 0, 0, 0, 30, 1),
(3078, 0, 0, 0, 'Paupers Palace, Flat 06', 25000, 9, 0, 0, 0, 0, 20, 1),
(3079, 0, 0, 0, 'Paupers Palace, Flat 05', 25000, 9, 0, 0, 0, 0, 15, 1),
(3080, 0, 0, 0, 'Paupers Palace, Flat 04', 25000, 9, 0, 0, 0, 0, 25, 1),
(3081, 0, 0, 0, 'Paupers Palace, Flat 07', 50000, 9, 0, 0, 0, 0, 23, 2),
(3082, 0, 0, 0, 'Paupers Palace, Flat 03', 25000, 9, 0, 0, 0, 0, 20, 1),
(3083, 0, 0, 0, 'Paupers Palace, Flat 02', 25000, 9, 0, 0, 0, 0, 25, 1),
(3084, 0, 0, 0, 'Paupers Palace, Flat 01', 25000, 9, 0, 0, 0, 0, 24, 1),
(3085, 0, 0, 0, 'Castle, Residence', 600000, 11, 0, 0, 0, 0, 182, 0),
(3086, 0, 0, 0, 'Castle, 3rd Floor, Flat 07', 80000, 11, 0, 0, 0, 0, 30, 1),
(3087, 0, 0, 0, 'Castle, 3rd Floor, Flat 04', 25000, 11, 0, 0, 0, 0, 25, 1),
(3088, 0, 0, 0, 'Castle, 3rd Floor, Flat 03', 50000, 11, 0, 0, 0, 0, 30, 1),
(3089, 0, 0, 0, 'Castle, 3rd Floor, Flat 06', 100000, 11, 0, 0, 0, 0, 36, 2),
(3090, 0, 0, 0, 'Castle, 3rd Floor, Flat 05', 80000, 11, 0, 0, 0, 0, 30, 1),
(3091, 0, 0, 0, 'Castle, 3rd Floor, Flat 02', 80000, 11, 0, 0, 0, 0, 30, 1),
(3092, 0, 0, 0, 'Castle, 3rd Floor, Flat 01', 50000, 11, 0, 0, 0, 0, 30, 1),
(3093, 0, 0, 0, 'Castle, 4th Floor, Flat 09', 50000, 11, 0, 0, 0, 0, 28, 1),
(3094, 0, 0, 0, 'Castle, 4th Floor, Flat 08', 80000, 11, 0, 0, 0, 0, 42, 1),
(3095, 0, 0, 0, 'Castle, 4th Floor, Flat 07', 80000, 11, 0, 0, 0, 0, 30, 1),
(3096, 0, 0, 0, 'Castle, 4th Floor, Flat 04', 50000, 11, 0, 0, 0, 0, 25, 1),
(3097, 0, 0, 0, 'Castle, 4th Floor, Flat 03', 50000, 11, 0, 0, 0, 0, 30, 1),
(3098, 0, 0, 0, 'Castle, 4th Floor, Flat 06', 100000, 11, 0, 0, 0, 0, 36, 1),
(3099, 0, 0, 0, 'Castle, 4th Floor, Flat 05', 80000, 11, 0, 0, 0, 0, 30, 1),
(3100, 0, 0, 0, 'Castle, 4th Floor, Flat 02', 80000, 11, 0, 0, 0, 0, 30, 1),
(3101, 0, 0, 0, 'Castle, 4th Floor, Flat 01', 50000, 11, 0, 0, 0, 0, 30, 1),
(3102, 0, 0, 0, 'Castle Street 2', 150000, 11, 0, 0, 0, 0, 56, 2),
(3103, 0, 0, 0, 'Castle Street 3', 150000, 11, 0, 0, 0, 0, 64, 2),
(3104, 0, 0, 0, 'Castle Street 4', 150000, 11, 0, 0, 0, 0, 61, 2),
(3105, 0, 0, 0, 'Castle Street 5', 150000, 11, 0, 0, 0, 0, 64, 2),
(3106, 0, 0, 0, 'Castle Street 1', 300000, 11, 0, 0, 0, 0, 112, 3),
(3107, 0, 0, 0, 'Edron Flats, Flat 08', 25000, 11, 0, 0, 0, 0, 20, 1),
(3108, 0, 0, 0, 'Edron Flats, Flat 05', 25000, 11, 0, 0, 0, 0, 20, 1),
(3109, 0, 0, 0, 'Edron Flats, Flat 04', 25000, 11, 0, 0, 0, 0, 25, 1),
(3110, 0, 0, 0, 'Edron Flats, Flat 01', 50000, 11, 0, 0, 0, 0, 25, 1),
(3111, 0, 0, 0, 'Edron Flats, Flat 07', 25000, 11, 0, 0, 0, 0, 20, 1),
(3112, 0, 0, 0, 'Edron Flats, Flat 06', 25000, 11, 0, 0, 0, 0, 20, 1),
(3113, 0, 0, 0, 'Edron Flats, Flat 03', 25000, 11, 0, 0, 0, 0, 20, 1),
(3114, 0, 0, 0, 'Edron Flats, Flat 02', 100000, 11, 0, 0, 0, 0, 40, 2),
(3115, 0, 0, 0, 'Edron Flats, Basement Flat 2', 100000, 11, 0, 0, 0, 0, 54, 2),
(3116, 0, 0, 0, 'Edron Flats, Basement Flat 1', 100000, 11, 0, 0, 0, 0, 63, 2),
(3119, 0, 0, 0, 'Edron Flats, Flat 13', 80000, 11, 0, 0, 0, 0, 45, 2),
(3121, 0, 0, 0, 'Edron Flats, Flat 14', 100000, 11, 0, 0, 0, 0, 50, 2),
(3123, 0, 0, 0, 'Edron Flats, Flat 12', 80000, 11, 0, 0, 0, 0, 45, 2),
(3124, 0, 0, 0, 'Edron Flats, Flat 11', 100000, 11, 0, 0, 0, 0, 60, 2),
(3125, 0, 0, 0, 'Edron Flats, Flat 25', 80000, 11, 0, 0, 0, 0, 60, 2),
(3127, 0, 0, 0, 'Edron Flats, Flat 24', 80000, 11, 0, 0, 0, 0, 35, 2),
(3128, 0, 0, 0, 'Edron Flats, Flat 21', 80000, 11, 0, 0, 0, 0, 40, 2),
(3131, 0, 0, 0, 'Edron Flats, Flat 23', 80000, 11, 0, 0, 0, 0, 40, 2),
(3133, 0, 0, 0, 'Castle Shop 1', 400000, 11, 0, 0, 0, 0, 70, 1),
(3134, 0, 0, 0, 'Castle Shop 2', 400000, 11, 0, 0, 0, 0, 70, 1),
(3135, 0, 0, 0, 'Castle Shop 3', 300000, 11, 0, 0, 0, 0, 80, 1),
(3136, 0, 0, 0, 'Central Circle 1', 800000, 11, 0, 0, 0, 0, 98, 2),
(3137, 0, 0, 0, 'Central Circle 2', 800000, 11, 0, 0, 0, 0, 120, 2),
(3138, 0, 0, 0, 'Central Circle 3', 800000, 11, 0, 0, 0, 0, 147, 5),
(3139, 0, 0, 0, 'Central Circle 4', 800000, 11, 0, 0, 0, 0, 147, 5),
(3140, 0, 0, 0, 'Central Circle 5', 800000, 11, 0, 0, 0, 0, 168, 5),
(3141, 0, 0, 0, 'Central Circle 8 (Shop)', 400000, 11, 0, 0, 0, 0, 168, 2),
(3142, 0, 0, 0, 'Central Circle 7 (Shop)', 400000, 11, 0, 0, 0, 0, 168, 2),
(3143, 0, 0, 0, 'Central Circle 6 (Shop)', 400000, 11, 0, 0, 0, 0, 192, 2),
(3144, 0, 0, 0, 'Central Circle 9a', 150000, 11, 0, 0, 0, 0, 42, 2),
(3145, 0, 0, 0, 'Central Circle 9b', 150000, 11, 0, 0, 0, 0, 42, 2),
(3146, 0, 0, 0, 'Sky Lane, Guild 1', 1000000, 11, 0, 0, 0, 0, 663, 23),
(3147, 0, 0, 0, 'Sky Lane, Sea Tower', 150000, 11, 0, 0, 0, 0, 196, 6),
(3148, 0, 0, 0, 'Sky Lane, Guild 3', 1000000, 11, 0, 0, 0, 0, 507, 18),
(3149, 0, 0, 0, 'Sky Lane, Guild 2', 1000000, 11, 0, 0, 0, 0, 653, 14),
(3150, 0, 0, 0, 'Wood Avenue 11', 600000, 11, 0, 0, 0, 0, 245, 6),
(3151, 0, 0, 0, 'Wood Avenue 8', 800000, 11, 0, 0, 0, 0, 218, 3),
(3152, 0, 0, 0, 'Wood Avenue 7', 800000, 11, 0, 0, 0, 0, 232, 3),
(3153, 0, 0, 0, 'Wood Avenue 10a', 200000, 11, 0, 0, 0, 0, 56, 2),
(3154, 0, 0, 0, 'Wood Avenue 9a', 200000, 11, 0, 0, 0, 0, 56, 2),
(3155, 0, 0, 0, 'Wood Avenue 6a', 300000, 11, 0, 0, 0, 0, 64, 2),
(3156, 0, 0, 0, 'Wood Avenue 6b', 200000, 11, 0, 0, 0, 0, 56, 2),
(3157, 0, 0, 0, 'Wood Avenue 9b', 200000, 11, 0, 0, 0, 0, 56, 2),
(3158, 0, 0, 0, 'Wood Avenue 10b', 200000, 11, 0, 0, 0, 0, 64, 3),
(3159, 0, 0, 0, 'Stronghold', 800000, 11, 0, 0, 0, 0, 285, 0),
(3160, 0, 0, 0, 'Wood Avenue 5', 300000, 11, 0, 0, 0, 0, 64, 2),
(3161, 0, 0, 0, 'Wood Avenue 3', 200000, 11, 0, 0, 0, 0, 52, 2),
(3162, 0, 0, 0, 'Wood Avenue 4', 200000, 11, 0, 0, 0, 0, 60, 2),
(3163, 0, 0, 0, 'Wood Avenue 2', 200000, 11, 0, 0, 0, 0, 64, 2),
(3164, 0, 0, 0, 'Wood Avenue 1', 200000, 11, 0, 0, 0, 0, 64, 2),
(3165, 0, 0, 0, 'Wood Avenue 4c', 200000, 11, 0, 0, 0, 0, 57, 2),
(3166, 0, 0, 0, 'Wood Avenue 4a', 150000, 11, 0, 0, 0, 0, 56, 2),
(3167, 0, 0, 0, 'Wood Avenue 4b', 150000, 11, 0, 0, 0, 0, 56, 2),
(3168, 0, 0, 0, 'Stonehome Village 1', 150000, 11, 0, 0, 0, 0, 77, 2),
(3169, 0, 0, 0, 'Stonehome Flats, Flat 04', 80000, 11, 0, 0, 0, 0, 45, 2),
(3171, 0, 0, 0, 'Stonehome Flats, Flat 03', 80000, 11, 0, 0, 0, 0, 45, 2),
(3173, 0, 0, 0, 'Stonehome Flats, Flat 02', 25000, 11, 0, 0, 0, 0, 30, 2),
(3174, 0, 0, 0, 'Stonehome Flats, Flat 01', 25000, 11, 0, 0, 0, 0, 25, 1),
(3175, 0, 0, 0, 'Stonehome Flats, Flat 13', 80000, 11, 0, 0, 0, 0, 45, 2),
(3177, 0, 0, 0, 'Stonehome Flats, Flat 11', 50000, 11, 0, 0, 0, 0, 30, 2),
(3178, 0, 0, 0, 'Stonehome Flats, Flat 14', 80000, 11, 0, 0, 0, 0, 45, 2),
(3180, 0, 0, 0, 'Stonehome Flats, Flat 12', 50000, 11, 0, 0, 0, 0, 30, 2),
(3181, 0, 0, 0, 'Stonehome Village 2', 50000, 11, 0, 0, 0, 0, 35, 1),
(3182, 0, 0, 0, 'Stonehome Village 3', 50000, 11, 0, 0, 0, 0, 36, 1),
(3183, 0, 0, 0, 'Stonehome Village 4', 80000, 11, 0, 0, 0, 0, 42, 2),
(3184, 0, 0, 0, 'Stonehome Village 6', 100000, 11, 0, 0, 0, 0, 55, 2),
(3185, 0, 0, 0, 'Stonehome Village 5', 80000, 11, 0, 0, 0, 0, 49, 2),
(3186, 0, 0, 0, 'Stonehome Village 7', 100000, 11, 0, 0, 0, 0, 49, 2),
(3187, 0, 0, 0, 'Stonehome Village 8', 25000, 11, 0, 0, 0, 0, 36, 1),
(3188, 0, 0, 0, 'Stonehome Village 9', 50000, 11, 0, 0, 0, 0, 36, 1),
(3189, 0, 0, 0, 'Stonehome Clanhall', 250000, 11, 0, 0, 0, 0, 364, 9),
(3190, 0, 0, 0, 'Mad Scientist\'s Lab', 600000, 17, 0, 0, 0, 0, 115, 0),
(3191, 0, 0, 0, 'Radiant Plaza 4', 800000, 17, 0, 0, 0, 0, 361, 3),
(3192, 0, 0, 0, 'Radiant Plaza 3', 800000, 17, 0, 0, 0, 0, 245, 2),
(3193, 0, 0, 0, 'Radiant Plaza 2', 600000, 17, 0, 0, 0, 0, 153, 2),
(3194, 0, 0, 0, 'Radiant Plaza 1', 800000, 17, 0, 0, 0, 0, 257, 4),
(3195, 0, 0, 0, 'Aureate Court 3', 400000, 17, 0, 0, 0, 0, 226, 2),
(3196, 0, 0, 0, 'Aureate Court 4', 400000, 17, 0, 0, 0, 0, 185, 4),
(3197, 0, 0, 0, 'Aureate Court 5', 600000, 17, 0, 0, 0, 0, 201, 0),
(3198, 0, 0, 0, 'Aureate Court 2', 400000, 17, 0, 0, 0, 0, 176, 2),
(3199, 0, 0, 0, 'Aureate Court 1', 600000, 17, 0, 0, 0, 0, 264, 3),
(3205, 0, 0, 0, 'Halls of Serenity', 5000000, 17, 0, 0, 0, 0, 1026, 33),
(3206, 0, 0, 0, 'Fortune Wing 3', 600000, 17, 0, 0, 0, 0, 235, 2),
(3207, 0, 0, 0, 'Fortune Wing 4', 600000, 17, 0, 0, 0, 0, 252, 4),
(3208, 0, 0, 0, 'Fortune Wing 2', 600000, 17, 0, 0, 0, 0, 260, 2),
(3209, 0, 0, 0, 'Fortune Wing 1', 800000, 17, 0, 0, 0, 0, 400, 4),
(3211, 0, 0, 0, 'Cascade Towers', 5000000, 17, 0, 0, 0, 0, 739, 33),
(3212, 0, 0, 0, 'Luminous Arc 5', 800000, 17, 0, 0, 0, 0, 196, 0),
(3213, 0, 0, 0, 'Luminous Arc 2', 600000, 17, 0, 0, 0, 0, 298, 4),
(3214, 0, 0, 0, 'Luminous Arc 1', 800000, 17, 0, 0, 0, 0, 341, 2),
(3215, 0, 0, 0, 'Luminous Arc 3', 600000, 17, 0, 0, 0, 0, 228, 3),
(3216, 0, 0, 0, 'Luminous Arc 4', 800000, 17, 0, 0, 0, 0, 326, 5),
(3217, 0, 0, 0, 'Harbour Promenade 1', 800000, 17, 0, 0, 0, 0, 205, 0),
(3218, 0, 0, 0, 'Sun Palace', 5000000, 17, 0, 0, 0, 0, 926, 27),
(3219, 0, 0, 0, 'Haggler\'s Hangout 3', 300000, 15, 0, 0, 0, 0, 241, 4),
(3220, 0, 0, 0, 'Haggler\'s Hangout 7', 400000, 15, 0, 0, 0, 0, 240, 0),
(3221, 0, 0, 0, 'Big Game Hunter\'s Lodge', 600000, 15, 0, 0, 0, 0, 257, 0),
(3222, 0, 0, 0, 'Haggler\'s Hangout 6', 400000, 15, 0, 0, 0, 0, 188, 4),
(3223, 0, 0, 0, 'Haggler\'s Hangout 5 (Shop)', 200000, 15, 0, 0, 0, 0, 56, 1),
(3224, 0, 0, 0, 'Haggler\'s Hangout 4b (Shop)', 150000, 15, 0, 0, 0, 0, 48, 1),
(3225, 0, 0, 0, 'Haggler\'s Hangout 4a (Shop)', 200000, 15, 0, 0, 0, 0, 64, 1),
(3226, 0, 0, 0, 'Haggler\'s Hangout 2', 100000, 15, 0, 0, 0, 0, 49, 1),
(3227, 0, 0, 0, 'Haggler\'s Hangout 1', 100000, 15, 0, 0, 0, 0, 49, 2),
(3228, 0, 0, 0, 'Bamboo Garden 3', 150000, 15, 0, 0, 0, 0, 63, 2),
(3229, 0, 0, 0, 'Unnamed House #3229', 0, 15, 0, 0, 0, 0, 762, 20),
(3230, 0, 0, 0, 'Bamboo Garden 2', 80000, 15, 0, 0, 0, 0, 42, 2),
(3231, 0, 0, 0, 'Bamboo Garden 1', 100000, 15, 0, 0, 0, 0, 63, 3),
(3232, 0, 0, 0, 'Banana Bay 4', 25000, 15, 0, 0, 0, 0, 25, 1),
(3233, 0, 0, 0, 'Banana Bay 2', 50000, 15, 0, 0, 0, 0, 36, 1),
(3234, 0, 0, 0, 'Banana Bay 3', 50000, 15, 0, 0, 0, 0, 25, 1),
(3235, 0, 0, 0, 'Banana Bay 1', 25000, 15, 0, 0, 0, 0, 25, 1),
(3236, 0, 0, 0, 'Crocodile Bridge 1', 80000, 15, 0, 0, 0, 0, 42, 2),
(3237, 0, 0, 0, 'Crocodile Bridge 2', 80000, 15, 0, 0, 0, 0, 36, 2),
(3238, 0, 0, 0, 'Crocodile Bridge 3', 100000, 15, 0, 0, 0, 0, 49, 2),
(3239, 0, 0, 0, 'Crocodile Bridge 4', 300000, 15, 0, 0, 0, 0, 158, 4),
(3240, 0, 0, 0, 'Crocodile Bridge 5', 200000, 15, 0, 0, 0, 0, 137, 2),
(3241, 0, 0, 0, 'Woodway 1', 80000, 15, 0, 0, 0, 0, 25, 1),
(3242, 0, 0, 0, 'Woodway 2', 50000, 15, 0, 0, 0, 0, 20, 1),
(3243, 0, 0, 0, 'Woodway 3', 150000, 15, 0, 0, 0, 0, 65, 2),
(3244, 0, 0, 0, 'Woodway 4', 25000, 15, 0, 0, 0, 0, 24, 1),
(3245, 0, 0, 0, 'Flamingo Flats 5', 150000, 15, 0, 0, 0, 0, 72, 1),
(3246, 0, 0, 0, 'Flamingo Flats 4', 80000, 15, 0, 0, 0, 0, 36, 2),
(3247, 0, 0, 0, 'Flamingo Flats 1', 50000, 15, 0, 0, 0, 0, 30, 2),
(3248, 0, 0, 0, 'Flamingo Flats 2', 80000, 15, 0, 0, 0, 0, 42, 2),
(3249, 0, 0, 0, 'Flamingo Flats 3', 50000, 15, 0, 0, 0, 0, 30, 2),
(3250, 0, 0, 0, 'Jungle Edge 1', 200000, 15, 0, 0, 0, 0, 85, 3),
(3251, 0, 0, 0, 'Jungle Edge 2', 200000, 15, 0, 0, 0, 0, 128, 3),
(3252, 0, 0, 0, 'Jungle Edge 4', 80000, 15, 0, 0, 0, 0, 36, 2),
(3253, 0, 0, 0, 'Jungle Edge 5', 80000, 15, 0, 0, 0, 0, 36, 2),
(3254, 0, 0, 0, 'Jungle Edge 6', 25000, 15, 0, 0, 0, 0, 25, 1),
(3255, 0, 0, 0, 'Jungle Edge 3', 80000, 15, 0, 0, 0, 0, 36, 2),
(3256, 0, 0, 0, 'River Homes 3', 200000, 15, 0, 0, 0, 0, 140, 7),
(3257, 0, 0, 0, 'River Homes 2b', 150000, 15, 0, 0, 0, 0, 49, 3),
(3258, 0, 0, 0, 'River Homes 2a', 100000, 15, 0, 0, 0, 0, 49, 2),
(3259, 0, 0, 0, 'River Homes 1', 300000, 15, 0, 0, 0, 0, 128, 3),
(3260, 0, 0, 0, 'Coconut Quay 4', 150000, 15, 0, 0, 0, 0, 72, 3),
(3261, 0, 0, 0, 'Coconut Quay 3', 200000, 15, 0, 0, 0, 0, 70, 4),
(3262, 0, 0, 0, 'Coconut Quay 2', 100000, 15, 0, 0, 0, 0, 42, 2),
(3263, 0, 0, 0, 'Coconut Quay 1', 150000, 15, 0, 0, 0, 0, 64, 2),
(3264, 0, 0, 0, 'Unnamed House #3264', 0, 15, 0, 0, 0, 0, 240, 15),
(3265, 0, 0, 0, 'Glacier Side 2', 300000, 16, 0, 0, 0, 0, 154, 3),
(3266, 0, 0, 0, 'Glacier Side 1', 150000, 16, 0, 0, 0, 0, 65, 2),
(3267, 0, 0, 0, 'Glacier Side 3', 150000, 16, 0, 0, 0, 0, 75, 2),
(3268, 0, 0, 0, 'Glacier Side 4', 150000, 16, 0, 0, 0, 0, 70, 1),
(3269, 0, 0, 0, 'Shelf Site', 300000, 16, 0, 0, 0, 0, 145, 3),
(3270, 0, 0, 0, 'Spirit Homes 5', 150000, 16, 0, 0, 0, 0, 56, 2),
(3271, 0, 0, 0, 'Spirit Homes 4', 80000, 16, 0, 0, 0, 0, 49, 1),
(3272, 0, 0, 0, 'Spirit Homes 1', 150000, 16, 0, 0, 0, 0, 56, 2),
(3273, 0, 0, 0, 'Spirit Homes 2', 150000, 16, 0, 0, 0, 0, 72, 2),
(3274, 0, 0, 0, 'Spirit Homes 3', 300000, 16, 0, 0, 0, 0, 128, 3),
(3275, 0, 0, 0, 'Arena Walk 3', 300000, 16, 0, 0, 0, 0, 126, 3),
(3276, 0, 0, 0, 'Arena Walk 2', 150000, 16, 0, 0, 0, 0, 54, 2),
(3277, 0, 0, 0, 'Arena Walk 1', 300000, 16, 0, 0, 0, 0, 128, 3),
(3278, 0, 0, 0, 'Bears Paw 2', 300000, 16, 0, 0, 0, 0, 98, 2),
(3279, 0, 0, 0, 'Bears Paw 1', 200000, 16, 0, 0, 0, 0, 72, 2),
(3280, 0, 0, 0, 'Crystal Glance', 1000000, 16, 0, 0, 0, 0, 550, 24),
(3281, 0, 0, 0, 'Shady Rocks 2', 200000, 16, 0, 0, 0, 0, 77, 4),
(3282, 0, 0, 0, 'Shady Rocks 1', 300000, 16, 0, 0, 0, 0, 116, 4),
(3283, 0, 0, 0, 'Shady Rocks 3', 300000, 16, 0, 0, 0, 0, 137, 3),
(3284, 0, 0, 0, 'Shady Rocks 4 (Shop)', 200000, 16, 0, 0, 0, 0, 95, 2),
(3285, 0, 0, 0, 'Shady Rocks 5', 300000, 16, 0, 0, 0, 0, 110, 2),
(3286, 0, 0, 0, 'Tusk Flats 2', 80000, 16, 0, 0, 0, 0, 42, 2),
(3287, 0, 0, 0, 'Tusk Flats 1', 80000, 16, 0, 0, 0, 0, 40, 2),
(3288, 0, 0, 0, 'Tusk Flats 3', 80000, 16, 0, 0, 0, 0, 35, 2),
(3289, 0, 0, 0, 'Tusk Flats 4', 25000, 16, 0, 0, 0, 0, 24, 1),
(3290, 0, 0, 0, 'Tusk Flats 6', 50000, 16, 0, 0, 0, 0, 35, 2),
(3291, 0, 0, 0, 'Tusk Flats 5', 25000, 16, 0, 0, 0, 0, 30, 1),
(3292, 0, 0, 0, 'Corner Shop (Shop)', 200000, 16, 0, 0, 0, 0, 88, 2),
(3293, 0, 0, 0, 'Bears Paw 5', 200000, 16, 0, 0, 0, 0, 81, 3),
(3294, 0, 0, 0, 'Bears Paw 4', 400000, 16, 0, 0, 0, 0, 185, 4),
(3295, 0, 0, 0, 'Trout Plaza 2', 150000, 16, 0, 0, 0, 0, 64, 2),
(3296, 0, 0, 0, 'Trout Plaza 1', 200000, 16, 0, 0, 0, 0, 112, 2),
(3297, 0, 0, 0, 'Trout Plaza 5 (Shop)', 300000, 16, 0, 0, 0, 0, 135, 2),
(3298, 0, 0, 0, 'Trout Plaza 3', 80000, 16, 0, 0, 0, 0, 36, 1),
(3299, 0, 0, 0, 'Trout Plaza 4', 80000, 16, 0, 0, 0, 0, 45, 1),
(3300, 0, 0, 0, 'Skiffs End 2', 80000, 16, 0, 0, 0, 0, 42, 2),
(3301, 0, 0, 0, 'Skiffs End 1', 100000, 16, 0, 0, 0, 0, 70, 2),
(3302, 0, 0, 0, 'Furrier Quarter 3', 100000, 16, 0, 0, 0, 0, 54, 2),
(3303, 0, 0, 0, 'Fimbul Shelf 4', 100000, 16, 0, 0, 0, 0, 56, 2),
(3304, 0, 0, 0, 'Fimbul Shelf 3', 100000, 16, 0, 0, 0, 0, 66, 2),
(3305, 0, 0, 0, 'Furrier Quarter 2', 80000, 16, 0, 0, 0, 0, 56, 2),
(3306, 0, 0, 0, 'Furrier Quarter 1', 150000, 16, 0, 0, 0, 0, 84, 3),
(3307, 0, 0, 0, 'Fimbul Shelf 2', 100000, 16, 0, 0, 0, 0, 56, 2),
(3308, 0, 0, 0, 'Fimbul Shelf 1', 80000, 16, 0, 0, 0, 0, 48, 2),
(3309, 0, 0, 0, 'Bears Paw 3', 200000, 16, 0, 0, 0, 0, 82, 3),
(3310, 0, 0, 0, 'Raven Corner 2', 150000, 16, 0, 0, 0, 0, 60, 3),
(3311, 0, 0, 0, 'Raven Corner 1', 80000, 16, 0, 0, 0, 0, 45, 1),
(3312, 0, 0, 0, 'Raven Corner 3', 100000, 16, 0, 0, 0, 0, 45, 1),
(3313, 0, 0, 0, 'Mammoth Belly', 1000000, 16, 0, 0, 0, 0, 634, 30),
(3314, 0, 0, 0, 'Darashia 3, Flat 01', 150000, 13, 0, 0, 0, 0, 42, 2),
(3315, 0, 0, 0, 'Darashia 3, Flat 05', 150000, 13, 0, 0, 0, 0, 42, 1),
(3316, 0, 0, 0, 'Darashia 3, Flat 02', 200000, 13, 0, 0, 0, 0, 66, 2),
(3317, 0, 0, 0, 'Darashia 3, Flat 04', 150000, 13, 0, 0, 0, 0, 66, 2),
(3318, 0, 0, 0, 'Darashia 3, Flat 03', 150000, 13, 0, 0, 0, 0, 48, 2),
(3319, 0, 0, 0, 'Darashia 3, Flat 12', 200000, 13, 0, 0, 0, 0, 90, 5),
(3320, 0, 0, 0, 'Darashia 3, Flat 11', 100000, 13, 0, 0, 0, 0, 42, 1),
(3321, 0, 0, 0, 'Darashia 3, Flat 14', 200000, 13, 0, 0, 0, 0, 96, 3),
(3322, 0, 0, 0, 'Darashia 3, Flat 13', 100000, 13, 0, 0, 0, 0, 48, 2),
(3323, 0, 0, 0, 'Darashia 8, Flat 01', 300000, 13, 0, 0, 0, 0, 82, 2),
(3325, 0, 0, 0, 'Darashia 8, Flat 05', 300000, 13, 0, 0, 0, 0, 92, 2),
(3326, 0, 0, 0, 'Darashia 8, Flat 04', 200000, 13, 0, 0, 0, 0, 90, 2),
(3327, 0, 0, 0, 'Darashia 8, Flat 03', 300000, 13, 0, 0, 0, 0, 171, 3),
(3328, 0, 0, 0, 'Darashia 8, Flat 12', 150000, 13, 0, 0, 0, 0, 60, 2),
(3329, 0, 0, 0, 'Darashia 8, Flat 11', 200000, 13, 0, 0, 0, 0, 72, 2),
(3330, 0, 0, 0, 'Darashia 8, Flat 14', 150000, 13, 0, 0, 0, 0, 66, 2),
(3331, 0, 0, 0, 'Darashia 8, Flat 13', 150000, 13, 0, 0, 0, 0, 78, 2),
(3332, 0, 0, 0, 'Darashia, Villa', 800000, 13, 0, 0, 0, 0, 233, 4),
(3333, 0, 0, 0, 'Darashia, Eastern Guildhall', 1000000, 13, 0, 0, 0, 0, 456, 16),
(3334, 0, 0, 0, 'Darashia, Western Guildhall', 500000, 13, 0, 0, 0, 0, 376, 14),
(3335, 0, 0, 0, 'Darashia 2, Flat 03', 100000, 13, 0, 0, 0, 0, 42, 1),
(3336, 0, 0, 0, 'Darashia 2, Flat 02', 100000, 13, 0, 0, 0, 0, 42, 1),
(3337, 0, 0, 0, 'Darashia 2, Flat 01', 150000, 13, 0, 0, 0, 0, 48, 1),
(3338, 0, 0, 0, 'Darashia 2, Flat 04', 80000, 13, 0, 0, 0, 0, 24, 1),
(3339, 0, 0, 0, 'Darashia 2, Flat 05', 150000, 13, 0, 0, 0, 0, 48, 2),
(3340, 0, 0, 0, 'Darashia 2, Flat 06', 80000, 13, 0, 0, 0, 0, 24, 1),
(3341, 0, 0, 0, 'Darashia 2, Flat 07', 150000, 13, 0, 0, 0, 0, 48, 1),
(3342, 0, 0, 0, 'Darashia 2, Flat 13', 100000, 13, 0, 0, 0, 0, 42, 1),
(3343, 0, 0, 0, 'Darashia 2, Flat 14', 50000, 13, 0, 0, 0, 0, 24, 1),
(3344, 0, 0, 0, 'Darashia 2, Flat 15', 100000, 13, 0, 0, 0, 0, 48, 2),
(3345, 0, 0, 0, 'Darashia 2, Flat 16', 80000, 13, 0, 0, 0, 0, 30, 1),
(3346, 0, 0, 0, 'Darashia 2, Flat 17', 100000, 13, 0, 0, 0, 0, 42, 1),
(3347, 0, 0, 0, 'Darashia 2, Flat 18', 100000, 13, 0, 0, 0, 0, 30, 1),
(3348, 0, 0, 0, 'Darashia 2, Flat 11', 100000, 13, 0, 0, 0, 0, 42, 1),
(3349, 0, 0, 0, 'Darashia 2, Flat 12', 80000, 13, 0, 0, 0, 0, 30, 1),
(3350, 0, 0, 0, 'Darashia 1, Flat 03', 300000, 13, 0, 0, 0, 0, 96, 4),
(3351, 0, 0, 0, 'Darashia 1, Flat 04', 100000, 13, 0, 0, 0, 0, 42, 1),
(3352, 0, 0, 0, 'Darashia 1, Flat 02', 100000, 13, 0, 0, 0, 0, 42, 1),
(3353, 0, 0, 0, 'Darashia 1, Flat 01', 100000, 13, 0, 0, 0, 0, 48, 2),
(3354, 0, 0, 0, 'Darashia 1, Flat 05', 100000, 13, 0, 0, 0, 0, 48, 2),
(3355, 0, 0, 0, 'Darashia 1, Flat 12', 150000, 13, 0, 0, 0, 0, 66, 2),
(3356, 0, 0, 0, 'Darashia 1, Flat 13', 150000, 13, 0, 0, 0, 0, 72, 2),
(3357, 0, 0, 0, 'Darashia 1, Flat 14', 200000, 13, 0, 0, 0, 0, 102, 5),
(3358, 0, 0, 0, 'Darashia 1, Flat 11', 100000, 13, 0, 0, 0, 0, 48, 2),
(3359, 0, 0, 0, 'Darashia 5, Flat 02', 150000, 13, 0, 0, 0, 0, 60, 2),
(3360, 0, 0, 0, 'Darashia 5, Flat 01', 150000, 13, 0, 0, 0, 0, 48, 1),
(3361, 0, 0, 0, 'Darashia 5, Flat 05', 100000, 13, 0, 0, 0, 0, 42, 1),
(3362, 0, 0, 0, 'Darashia 5, Flat 04', 150000, 13, 0, 0, 0, 0, 66, 2),
(3363, 0, 0, 0, 'Darashia 5, Flat 03', 150000, 13, 0, 0, 0, 0, 48, 1),
(3364, 0, 0, 0, 'Darashia 5, Flat 11', 150000, 13, 0, 0, 0, 0, 66, 2),
(3365, 0, 0, 0, 'Darashia 5, Flat 12', 150000, 13, 0, 0, 0, 0, 66, 2),
(3366, 0, 0, 0, 'Darashia 5, Flat 13', 150000, 13, 0, 0, 0, 0, 72, 2),
(3367, 0, 0, 0, 'Darashia 5, Flat 14', 150000, 13, 0, 0, 0, 0, 72, 2),
(3368, 0, 0, 0, 'Darashia 6a', 300000, 13, 0, 0, 0, 0, 117, 2),
(3369, 0, 0, 0, 'Darashia 6b', 300000, 13, 0, 0, 0, 0, 139, 2),
(3370, 0, 0, 0, 'Darashia 4, Flat 02', 200000, 13, 0, 0, 0, 0, 66, 2),
(3371, 0, 0, 0, 'Darashia 4, Flat 03', 150000, 13, 0, 0, 0, 0, 42, 1),
(3372, 0, 0, 0, 'Darashia 4, Flat 04', 200000, 13, 0, 0, 0, 0, 72, 2),
(3373, 0, 0, 0, 'Darashia 4, Flat 05', 150000, 13, 0, 0, 0, 0, 48, 2),
(3374, 0, 0, 0, 'Darashia 4, Flat 01', 100000, 13, 0, 0, 0, 0, 48, 1),
(3375, 0, 0, 0, 'Darashia 4, Flat 12', 200000, 13, 0, 0, 0, 0, 96, 3),
(3376, 0, 0, 0, 'Darashia 4, Flat 11', 100000, 13, 0, 0, 0, 0, 42, 1),
(3377, 0, 0, 0, 'Darashia 4, Flat 13', 200000, 13, 0, 0, 0, 0, 72, 2),
(3378, 0, 0, 0, 'Darashia 4, Flat 14', 150000, 13, 0, 0, 0, 0, 78, 2),
(3379, 0, 0, 0, 'Darashia 7, Flat 01', 100000, 13, 0, 0, 0, 0, 42, 1),
(3380, 0, 0, 0, 'Darashia 7, Flat 02', 100000, 13, 0, 0, 0, 0, 42, 1),
(3381, 0, 0, 0, 'Darashia 7, Flat 03', 200000, 13, 0, 0, 0, 0, 102, 4),
(3382, 0, 0, 0, 'Darashia 7, Flat 05', 150000, 13, 0, 0, 0, 0, 42, 2),
(3383, 0, 0, 0, 'Darashia 7, Flat 04', 150000, 13, 0, 0, 0, 0, 48, 1),
(3384, 0, 0, 0, 'Darashia 7, Flat 12', 200000, 13, 0, 0, 0, 0, 96, 4),
(3385, 0, 0, 0, 'Darashia 7, Flat 11', 100000, 13, 0, 0, 0, 0, 42, 1),
(3386, 0, 0, 0, 'Darashia 7, Flat 14', 200000, 13, 0, 0, 0, 0, 102, 4),
(3387, 0, 0, 0, 'Darashia 7, Flat 13', 100000, 13, 0, 0, 0, 0, 48, 1),
(3388, 0, 0, 0, 'Pirate Shipwreck 1', 800000, 13, 0, 0, 0, 0, 205, 0),
(3389, 0, 0, 0, 'Pirate Shipwreck 2', 800000, 13, 0, 0, 0, 0, 294, 0),
(3390, 0, 0, 0, 'The Shelter', 250000, 14, 0, 0, 0, 0, 560, 31),
(3391, 0, 0, 0, 'Litter Promenade 1', 25000, 14, 0, 0, 0, 0, 25, 2),
(3392, 0, 0, 0, 'Litter Promenade 2', 50000, 14, 0, 0, 0, 0, 25, 1),
(3394, 0, 0, 0, 'Litter Promenade 3', 25000, 14, 0, 0, 0, 0, 36, 1),
(3395, 0, 0, 0, 'Litter Promenade 4', 25000, 14, 0, 0, 0, 0, 30, 1),
(3396, 0, 0, 0, 'Rum Alley 3', 25000, 14, 0, 0, 0, 0, 28, 1),
(3397, 0, 0, 0, 'Straycat\'s Corner 5', 80000, 14, 0, 0, 0, 0, 48, 2),
(3398, 0, 0, 0, 'Straycat\'s Corner 6', 25000, 14, 0, 0, 0, 0, 25, 1),
(3399, 0, 0, 0, 'Litter Promenade 5', 25000, 14, 0, 0, 0, 0, 35, 2),
(3401, 0, 0, 0, 'Straycat\'s Corner 4', 50000, 14, 0, 0, 0, 0, 40, 2),
(3402, 0, 0, 0, 'Straycat\'s Corner 2', 50000, 14, 0, 0, 0, 0, 49, 1),
(3403, 0, 0, 0, 'Straycat\'s Corner 1', 25000, 14, 0, 0, 0, 0, 25, 1),
(3404, 0, 0, 0, 'Rum Alley 2', 25000, 14, 0, 0, 0, 0, 25, 1),
(3405, 0, 0, 0, 'Rum Alley 1', 25000, 14, 0, 0, 0, 0, 36, 1),
(3406, 0, 0, 0, 'Smuggler Backyard 3', 50000, 14, 0, 0, 0, 0, 40, 2),
(3407, 0, 0, 0, 'Shady Trail 3', 25000, 14, 0, 0, 0, 0, 25, 1),
(3408, 0, 0, 0, 'Shady Trail 1', 100000, 14, 0, 0, 0, 0, 48, 5),
(3409, 0, 0, 0, 'Shady Trail 2', 25000, 14, 0, 0, 0, 0, 30, 2),
(3410, 0, 0, 0, 'Smuggler Backyard 4', 25000, 14, 0, 0, 0, 0, 30, 1),
(3411, 0, 0, 0, 'Smuggler Backyard 2', 25000, 14, 0, 0, 0, 0, 40, 2),
(3412, 0, 0, 0, 'Smuggler Backyard 1', 25000, 14, 0, 0, 0, 0, 40, 2),
(3413, 0, 0, 0, 'Smuggler Backyard 5', 25000, 14, 0, 0, 0, 0, 35, 2),
(3414, 0, 0, 0, 'Sugar Street 1', 200000, 14, 0, 0, 0, 0, 84, 3),
(3415, 0, 0, 0, 'Sugar Street 2', 150000, 14, 0, 0, 0, 0, 84, 3),
(3416, 0, 0, 0, 'Sugar Street 3a', 100000, 14, 0, 0, 0, 0, 48, 3),
(3417, 0, 0, 0, 'Sugar Street 3b', 150000, 14, 0, 0, 0, 0, 66, 3),
(3418, 0, 0, 0, 'Sugar Street 4d', 50000, 14, 0, 0, 0, 0, 24, 2),
(3419, 0, 0, 0, 'Sugar Street 4c', 25000, 14, 0, 0, 0, 0, 24, 1),
(3420, 0, 0, 0, 'Sugar Street 4b', 100000, 14, 0, 0, 0, 0, 30, 2),
(3421, 0, 0, 0, 'Sugar Street 4a', 80000, 14, 0, 0, 0, 0, 36, 2),
(3422, 0, 0, 0, 'Harvester\'s Haven, Flat 01', 50000, 14, 0, 0, 0, 0, 30, 2),
(3423, 0, 0, 0, 'Harvester\'s Haven, Flat 03', 50000, 14, 0, 0, 0, 0, 30, 2),
(3424, 0, 0, 0, 'Harvester\'s Haven, Flat 05', 50000, 14, 0, 0, 0, 0, 36, 2),
(3425, 0, 0, 0, 'Harvester\'s Haven, Flat 06', 50000, 14, 0, 0, 0, 0, 30, 2),
(3426, 0, 0, 0, 'Harvester\'s Haven, Flat 04', 50000, 14, 0, 0, 0, 0, 30, 2),
(3427, 0, 0, 0, 'Harvester\'s Haven, Flat 02', 50000, 14, 0, 0, 0, 0, 36, 2),
(3428, 0, 0, 0, 'Harvester\'s Haven, Flat 07', 80000, 14, 0, 0, 0, 0, 30, 2),
(3429, 0, 0, 0, 'Harvester\'s Haven, Flat 09', 80000, 14, 0, 0, 0, 0, 30, 2),
(3430, 0, 0, 0, 'Harvester\'s Haven, Flat 11', 25000, 14, 0, 0, 0, 0, 36, 2),
(3431, 0, 0, 0, 'Harvester\'s Haven, Flat 08', 80000, 14, 0, 0, 0, 0, 30, 2),
(3432, 0, 0, 0, 'Harvester\'s Haven, Flat 10', 80000, 14, 0, 0, 0, 0, 30, 2),
(3433, 0, 0, 0, 'Harvester\'s Haven, Flat 12', 25000, 14, 0, 0, 0, 0, 36, 2),
(3434, 0, 0, 0, 'Marble Lane 3', 600000, 14, 0, 0, 0, 0, 240, 4),
(3435, 0, 0, 0, 'Marble Lane 2', 400000, 14, 0, 0, 0, 0, 200, 3),
(3436, 0, 0, 0, 'Marble Lane 4', 400000, 14, 0, 0, 0, 0, 192, 4),
(3437, 0, 0, 0, 'Admiral\'s Avenue 1', 400000, 14, 0, 0, 0, 0, 176, 2),
(3438, 0, 0, 0, 'Admiral\'s Avenue 2', 400000, 14, 0, 0, 0, 0, 183, 4),
(3439, 0, 0, 0, 'Admiral\'s Avenue 3', 300000, 14, 0, 0, 0, 0, 144, 2),
(3440, 0, 0, 0, 'Ivory Circle 1', 400000, 14, 0, 0, 0, 0, 160, 2),
(3441, 0, 0, 0, 'Sugar Street 5', 150000, 14, 0, 0, 0, 0, 48, 2),
(3442, 0, 0, 0, 'Freedom Street 1', 200000, 14, 0, 0, 0, 0, 84, 2),
(3443, 0, 0, 0, 'Trader\'s Point 1', 200000, 14, 0, 0, 0, 0, 77, 2),
(3444, 0, 0, 0, 'Trader\'s Point 2 (Shop)', 600000, 14, 0, 0, 0, 0, 195, 2),
(3445, 0, 0, 0, 'Trader\'s Point 3 (Shop)', 600000, 14, 0, 0, 0, 0, 198, 2),
(3446, 0, 0, 0, 'Ivory Mansion', 800000, 14, 0, 0, 0, 0, 456, 0),
(3447, 0, 0, 0, 'Ivory Circle 2', 400000, 14, 0, 0, 0, 0, 196, 2),
(3448, 0, 0, 0, 'Ivy Cottage', 500000, 14, 0, 0, 0, 0, 876, 26),
(3449, 0, 0, 0, 'Marble Lane 1', 600000, 14, 0, 0, 0, 0, 320, 6),
(3450, 0, 0, 0, 'Freedom Street 2', 400000, 14, 0, 0, 0, 0, 208, 4),
(3452, 0, 0, 0, 'Meriana Beach', 150000, 14, 0, 0, 0, 0, 219, 3),
(3453, 0, 0, 0, 'The Tavern 1a', 150000, 14, 0, 0, 0, 0, 73, 4),
(3454, 0, 0, 0, 'The Tavern 1b', 100000, 14, 0, 0, 0, 0, 54, 2),
(3455, 0, 0, 0, 'The Tavern 1c', 200000, 14, 0, 0, 0, 0, 126, 3),
(3456, 0, 0, 0, 'The Tavern 1d', 100000, 14, 0, 0, 0, 0, 54, 2),
(3457, 0, 0, 0, 'The Tavern 2a', 300000, 14, 0, 0, 0, 0, 163, 5),
(3458, 0, 0, 0, 'The Tavern 2b', 100000, 14, 0, 0, 0, 0, 57, 2),
(3459, 0, 0, 0, 'The Tavern 2d', 100000, 14, 0, 0, 0, 0, 40, 2),
(3460, 0, 0, 0, 'The Tavern 2c', 50000, 14, 0, 0, 0, 0, 40, 1),
(3461, 0, 0, 0, 'The Yeah Beach Project', 150000, 14, 0, 0, 0, 0, 202, 3),
(3462, 0, 0, 0, 'Mountain Hideout', 500000, 14, 0, 0, 0, 0, 511, 17),
(3463, 0, 0, 0, 'Darashia 8, Flat 02', 300000, 13, 0, 0, 0, 0, 135, 2),
(3464, 0, 0, 0, 'Castle, Basement, Flat 01', 50000, 11, 0, 0, 0, 0, 30, 1),
(3465, 0, 0, 0, 'Castle, Basement, Flat 02', 50000, 11, 0, 0, 0, 0, 24, 1),
(3466, 0, 0, 0, 'Castle, Basement, Flat 03', 50000, 11, 0, 0, 0, 0, 24, 1),
(3467, 0, 0, 0, 'Castle, Basement, Flat 05', 50000, 11, 0, 0, 0, 0, 24, 1),
(3468, 0, 0, 0, 'Castle, Basement, Flat 04', 50000, 11, 0, 0, 0, 0, 24, 1),
(3469, 0, 0, 0, 'Castle, Basement, Flat 06', 50000, 11, 0, 0, 0, 0, 24, 1),
(3470, 0, 0, 0, 'Castle, Basement, Flat 07', 50000, 11, 0, 0, 0, 0, 24, 1),
(3471, 0, 0, 0, 'Castle, Basement, Flat 09', 25000, 11, 0, 0, 0, 0, 30, 1),
(3472, 0, 0, 0, 'Castle, Basement, Flat 08', 50000, 11, 0, 0, 0, 0, 30, 1),
(3473, 0, 0, 0, 'Cormaya 1', 150000, 11, 0, 0, 0, 0, 49, 2),
(3474, 0, 0, 0, 'Cormaya Flats, Flat 01', 25000, 11, 0, 0, 0, 0, 20, 1),
(3475, 0, 0, 0, 'Cormaya Flats, Flat 02', 25000, 11, 0, 0, 0, 0, 20, 1),
(3476, 0, 0, 0, 'Cormaya Flats, Flat 03', 50000, 11, 0, 0, 0, 0, 35, 2),
(3477, 0, 0, 0, 'Cormaya Flats, Flat 06', 25000, 11, 0, 0, 0, 0, 20, 1),
(3478, 0, 0, 0, 'Cormaya Flats, Flat 05', 25000, 11, 0, 0, 0, 0, 20, 1),
(3479, 0, 0, 0, 'Cormaya Flats, Flat 04', 50000, 11, 0, 0, 0, 0, 35, 2),
(3480, 0, 0, 0, 'Cormaya Flats, Flat 11', 100000, 11, 0, 0, 0, 0, 45, 2),
(3482, 0, 0, 0, 'Cormaya Flats, Flat 13', 25000, 11, 0, 0, 0, 0, 30, 2),
(3483, 0, 0, 0, 'Cormaya Flats, Flat 12', 100000, 11, 0, 0, 0, 0, 45, 2),
(3485, 0, 0, 0, 'Cormaya Flats, Flat 14', 25000, 11, 0, 0, 0, 0, 30, 2),
(3486, 0, 0, 0, 'Cormaya 2', 300000, 11, 0, 0, 0, 0, 144, 3),
(3487, 0, 0, 0, 'Cormaya 4', 150000, 11, 0, 0, 0, 0, 63, 2),
(3488, 0, 0, 0, 'Cormaya 3', 200000, 11, 0, 0, 0, 0, 72, 2),
(3489, 0, 0, 0, 'Cormaya 6', 200000, 11, 0, 0, 0, 0, 84, 2),
(3490, 0, 0, 0, 'Cormaya 7', 200000, 11, 0, 0, 0, 0, 84, 2),
(3491, 0, 0, 0, 'Cormaya 8', 200000, 11, 0, 0, 0, 0, 106, 2),
(3492, 0, 0, 0, 'Cormaya 5', 300000, 11, 0, 0, 0, 0, 165, 3),
(3493, 0, 0, 0, 'Castle of the White Dragon', 1000000, 11, 0, 0, 0, 0, 888, 19),
(3494, 0, 0, 0, 'Cormaya 9b', 150000, 11, 0, 0, 0, 0, 88, 2),
(3495, 0, 0, 0, 'Cormaya 9a', 80000, 11, 0, 0, 0, 0, 48, 2),
(3496, 0, 0, 0, 'Cormaya 9d', 150000, 11, 0, 0, 0, 0, 88, 2),
(3497, 0, 0, 0, 'Cormaya 9c', 80000, 11, 0, 0, 0, 0, 48, 2),
(3498, 0, 0, 0, 'Cormaya 10', 300000, 11, 0, 0, 0, 0, 144, 3),
(3499, 0, 0, 0, 'Cormaya 11', 150000, 11, 0, 0, 0, 0, 72, 2),
(3500, 0, 0, 0, 'Edron Flats, Flat 22', 50000, 11, 0, 0, 0, 0, 25, 1),
(3501, 0, 0, 0, 'Magic Academy, Shop', 150000, 11, 0, 0, 0, 0, 48, 1),
(3502, 0, 0, 0, 'Magic Academy, Flat 1', 100000, 11, 0, 0, 0, 0, 55, 3),
(3503, 0, 0, 0, 'Magic Academy, Guild', 500000, 11, 0, 0, 0, 0, 401, 14),
(3504, 0, 0, 0, 'Magic Academy, Flat 2', 80000, 11, 0, 0, 0, 0, 53, 2),
(3505, 0, 0, 0, 'Magic Academy, Flat 3', 100000, 11, 0, 0, 0, 0, 53, 1),
(3506, 0, 0, 0, 'Magic Academy, Flat 4', 100000, 11, 0, 0, 0, 0, 50, 2),
(3507, 0, 0, 0, 'Magic Academy, Flat 5', 80000, 11, 0, 0, 0, 0, 53, 1),
(3508, 0, 0, 0, 'Oskahl I f', 100000, 10, 0, 0, 0, 0, 35, 1),
(3509, 0, 0, 0, 'Oskahl I g', 100000, 10, 0, 0, 0, 0, 42, 2),
(3510, 0, 0, 0, 'Oskahl I h', 150000, 10, 0, 0, 0, 0, 74, 3),
(3511, 0, 0, 0, 'Oskahl I i', 80000, 10, 0, 0, 0, 0, 36, 1),
(3512, 0, 0, 0, 'Oskahl I j', 80000, 10, 0, 0, 0, 0, 36, 1),
(3513, 0, 0, 0, 'Oskahl I b', 80000, 10, 0, 0, 0, 0, 30, 1),
(3514, 0, 0, 0, 'Oskahl I d', 100000, 10, 0, 0, 0, 0, 42, 2),
(3515, 0, 0, 0, 'Oskahl I e', 80000, 10, 0, 0, 0, 0, 36, 1),
(3516, 0, 0, 0, 'Oskahl I c', 80000, 10, 0, 0, 0, 0, 36, 1),
(3517, 0, 0, 0, 'Chameken I', 100000, 10, 0, 0, 0, 0, 36, 1),
(3518, 0, 0, 0, 'Chameken II', 80000, 10, 0, 0, 0, 0, 36, 1),
(3519, 0, 0, 0, 'Charsirakh III', 50000, 10, 0, 0, 0, 0, 36, 1),
(3520, 0, 0, 0, 'Charsirakh II', 100000, 10, 0, 0, 0, 0, 49, 2),
(3521, 0, 0, 0, 'Mothrem I a', 80000, 10, 0, 0, 0, 0, 52, 2),
(3523, 0, 0, 0, 'Mothrem I c', 50000, 10, 0, 0, 0, 0, 20, 1),
(3524, 0, 0, 0, 'Mothrem I b', 50000, 10, 0, 0, 0, 0, 24, 1),
(3525, 0, 0, 0, 'Charsirakh I b', 150000, 10, 0, 0, 0, 0, 64, 2),
(3526, 0, 0, 0, 'Harrah I', 250000, 10, 0, 0, 0, 0, 232, 10),
(3527, 0, 0, 0, 'Thanah I d', 200000, 10, 0, 0, 0, 0, 84, 4),
(3528, 0, 0, 0, 'Thanah I c', 200000, 10, 0, 0, 0, 0, 112, 3),
(3529, 0, 0, 0, 'Thanah I b', 150000, 10, 0, 0, 0, 0, 100, 3),
(3530, 0, 0, 0, 'Thanah I a', 25000, 10, 0, 0, 0, 0, 36, 1),
(3531, 0, 0, 0, 'Othehothep I c', 150000, 10, 0, 0, 0, 0, 60, 3),
(3532, 0, 0, 0, 'Othehothep I d', 150000, 10, 0, 0, 0, 0, 84, 4),
(3533, 0, 0, 0, 'Othehothep I b', 100000, 10, 0, 0, 0, 0, 64, 2),
(3534, 0, 0, 0, 'Othehothep II c', 80000, 10, 0, 0, 0, 0, 30, 1),
(3535, 0, 0, 0, 'Othehothep II d', 80000, 10, 0, 0, 0, 0, 35, 1),
(3536, 0, 0, 0, 'Othehothep II e', 150000, 10, 0, 0, 0, 0, 48, 2),
(3537, 0, 0, 0, 'Othehothep II f', 100000, 10, 0, 0, 0, 0, 56, 2),
(3538, 0, 0, 0, 'Othehothep II b', 150000, 10, 0, 0, 0, 0, 81, 3),
(3539, 0, 0, 0, 'Othehothep II a', 25000, 10, 0, 0, 0, 0, 25, 1),
(3540, 0, 0, 0, 'Mothrem I', 80000, 10, 0, 0, 0, 0, 49, 2),
(3541, 0, 0, 0, 'Arakmehn I', 100000, 10, 0, 0, 0, 0, 56, 3),
(3542, 0, 0, 0, 'Arakmehn II', 80000, 10, 0, 0, 0, 0, 49, 1),
(3543, 0, 0, 0, 'Arakmehn III', 100000, 10, 0, 0, 0, 0, 49, 2),
(3544, 0, 0, 0, 'Arakmehn IV', 100000, 10, 0, 0, 0, 0, 56, 2),
(3545, 0, 0, 0, 'Unklath II b', 50000, 10, 0, 0, 0, 0, 25, 1),
(3546, 0, 0, 0, 'Unklath II c', 50000, 10, 0, 0, 0, 0, 30, 1),
(3547, 0, 0, 0, 'Unklath II d', 100000, 10, 0, 0, 0, 0, 66, 2),
(3548, 0, 0, 0, 'Unklath II a', 50000, 10, 0, 0, 0, 0, 49, 1),
(3549, 0, 0, 0, 'Rathal I b', 50000, 10, 0, 0, 0, 0, 25, 1),
(3550, 0, 0, 0, 'Rathal I c', 25000, 10, 0, 0, 0, 0, 30, 1),
(3551, 0, 0, 0, 'Rathal I d', 50000, 10, 0, 0, 0, 0, 30, 2),
(3552, 0, 0, 0, 'Rathal I e', 50000, 10, 0, 0, 0, 0, 36, 2),
(3553, 0, 0, 0, 'Rathal I a', 80000, 10, 0, 0, 0, 0, 49, 2),
(3554, 0, 0, 0, 'Rathal II b', 50000, 10, 0, 0, 0, 0, 25, 1),
(3555, 0, 0, 0, 'Rathal II c', 50000, 10, 0, 0, 0, 0, 30, 1),
(3556, 0, 0, 0, 'Rathal II d', 100000, 10, 0, 0, 0, 0, 66, 2),
(3557, 0, 0, 0, 'Rathal II a', 80000, 10, 0, 0, 0, 0, 49, 1),
(3558, 0, 0, 0, 'Esuph I', 50000, 10, 0, 0, 0, 0, 36, 1),
(3559, 0, 0, 0, 'Esuph II b', 100000, 10, 0, 0, 0, 0, 64, 2),
(3560, 0, 0, 0, 'Esuph II a', 25000, 10, 0, 0, 0, 0, 20, 1),
(3561, 0, 0, 0, 'Esuph III b', 100000, 10, 0, 0, 0, 0, 64, 2),
(3562, 0, 0, 0, 'Esuph III a', 25000, 10, 0, 0, 0, 0, 20, 1),
(3564, 0, 0, 0, 'Esuph IV c', 80000, 10, 0, 0, 0, 0, 43, 2),
(3565, 0, 0, 0, 'Esuph IV d', 25000, 10, 0, 0, 0, 0, 38, 1),
(3566, 0, 0, 0, 'Esuph IV a', 25000, 10, 0, 0, 0, 0, 25, 1),
(3567, 0, 0, 0, 'Horakhal', 250000, 10, 0, 0, 0, 0, 332, 14),
(3568, 0, 0, 0, 'Botham II d', 100000, 10, 0, 0, 0, 0, 49, 2),
(3569, 0, 0, 0, 'Botham II e', 100000, 10, 0, 0, 0, 0, 49, 2),
(3570, 0, 0, 0, 'Botham II f', 80000, 10, 0, 0, 0, 0, 49, 2),
(3571, 0, 0, 0, 'Botham II g', 80000, 10, 0, 0, 0, 0, 49, 2),
(3572, 0, 0, 0, 'Botham II c', 100000, 10, 0, 0, 0, 0, 40, 2),
(3573, 0, 0, 0, 'Botham II b', 100000, 10, 0, 0, 0, 0, 60, 2),
(3574, 0, 0, 0, 'Botham II a', 25000, 10, 0, 0, 0, 0, 36, 1),
(3575, 0, 0, 0, 'Botham III f', 150000, 10, 0, 0, 0, 0, 56, 3),
(3576, 0, 0, 0, 'Botham III h', 200000, 10, 0, 0, 0, 0, 113, 3),
(3577, 0, 0, 0, 'Botham III g', 100000, 10, 0, 0, 0, 0, 56, 2),
(3578, 0, 0, 0, 'Botham III b', 50000, 10, 0, 0, 0, 0, 25, 2),
(3579, 0, 0, 0, 'Botham III c', 25000, 10, 0, 0, 0, 0, 30, 1),
(3581, 0, 0, 0, 'Botham III e', 100000, 10, 0, 0, 0, 0, 66, 2),
(3582, 0, 0, 0, 'Botham III a', 80000, 10, 0, 0, 0, 0, 49, 2),
(3583, 0, 0, 0, 'Botham IV f', 100000, 10, 0, 0, 0, 0, 49, 2),
(3584, 0, 0, 0, 'Botham IV h', 100000, 10, 0, 0, 0, 0, 56, 1),
(3585, 0, 0, 0, 'Botham IV i', 150000, 10, 0, 0, 0, 0, 56, 3),
(3586, 0, 0, 0, 'Botham IV g', 100000, 10, 0, 0, 0, 0, 64, 2),
(3587, 0, 0, 0, 'Botham IV e', 100000, 10, 0, 0, 0, 0, 121, 4),
(3591, 0, 0, 0, 'Botham IV a', 100000, 10, 0, 0, 0, 0, 49, 2),
(3592, 0, 0, 0, 'Ramen Tah', 250000, 10, 0, 0, 0, 0, 227, 16),
(3593, 0, 0, 0, 'Botham I c', 150000, 10, 0, 0, 0, 0, 49, 2),
(3594, 0, 0, 0, 'Botham I e', 80000, 10, 0, 0, 0, 0, 49, 2),
(3595, 0, 0, 0, 'Botham I d', 150000, 10, 0, 0, 0, 0, 98, 3),
(3596, 0, 0, 0, 'Botham I b', 150000, 10, 0, 0, 0, 0, 100, 3),
(3597, 0, 0, 0, 'Botham I a', 50000, 10, 0, 0, 0, 0, 40, 1),
(3598, 0, 0, 0, 'Charsirakh I a', 25000, 10, 0, 0, 0, 0, 20, 1),
(3599, 0, 0, 0, 'Low Waters Observatory', 400000, 10, 0, 0, 0, 0, 743, 5),
(3600, 0, 0, 0, 'Oskahl I a', 150000, 10, 0, 0, 0, 0, 64, 2),
(3601, 0, 0, 0, 'Othehothep I a', 25000, 10, 0, 0, 0, 0, 20, 1),
(3602, 0, 0, 0, 'Othehothep III a', 25000, 10, 0, 0, 0, 0, 20, 1),
(3603, 0, 0, 0, 'Othehothep III b', 80000, 10, 0, 0, 0, 0, 64, 2),
(3604, 0, 0, 0, 'Othehothep III c', 80000, 10, 0, 0, 0, 0, 30, 2),
(3605, 0, 0, 0, 'Othehothep III d', 80000, 10, 0, 0, 0, 0, 42, 1),
(3606, 0, 0, 0, 'Othehothep III e', 50000, 10, 0, 0, 0, 0, 35, 1),
(3607, 0, 0, 0, 'Othehothep III f', 50000, 10, 0, 0, 0, 0, 37, 1),
(3608, 0, 0, 0, 'Unklath I f', 100000, 10, 0, 0, 0, 0, 49, 2),
(3609, 0, 0, 0, 'Unklath I g', 100000, 10, 0, 0, 0, 0, 56, 1),
(3610, 0, 0, 0, 'Unklath I d', 150000, 10, 0, 0, 0, 0, 56, 3),
(3611, 0, 0, 0, 'Unklath I e', 150000, 10, 0, 0, 0, 0, 64, 2),
(3612, 0, 0, 0, 'Unklath I b', 100000, 10, 0, 0, 0, 0, 55, 2),
(3613, 0, 0, 0, 'Unklath I c', 100000, 10, 0, 0, 0, 0, 66, 2),
(3614, 0, 0, 0, 'Unklath I a', 100000, 10, 0, 0, 0, 0, 49, 2),
(3615, 0, 0, 0, 'Thanah II a', 25000, 10, 0, 0, 0, 0, 36, 1),
(3616, 0, 0, 0, 'Thanah II b', 50000, 10, 0, 0, 0, 0, 20, 1),
(3617, 0, 0, 0, 'Thanah II d', 50000, 10, 0, 0, 0, 0, 20, 1),
(3618, 0, 0, 0, 'Thanah II e', 25000, 10, 0, 0, 0, 0, 16, 1),
(3619, 0, 0, 0, 'Thanah II c', 25000, 10, 0, 0, 0, 0, 24, 1),
(3620, 0, 0, 0, 'Thanah II f', 150000, 10, 0, 0, 0, 0, 86, 3),
(3621, 0, 0, 0, 'Thanah II g', 100000, 10, 0, 0, 0, 0, 51, 2),
(3622, 0, 0, 0, 'Thanah II h', 100000, 10, 0, 0, 0, 0, 55, 2),
(3623, 0, 0, 0, 'Thrarhor I a (Shop)', 50000, 10, 0, 0, 0, 0, 32, 1),
(3624, 0, 0, 0, 'Thrarhor I c (Shop)', 50000, 10, 0, 0, 0, 0, 32, 1),
(3625, 0, 0, 0, 'Thrarhor I d (Shop)', 80000, 10, 0, 0, 0, 0, 32, 1),
(3626, 0, 0, 0, 'Thrarhor I b (Shop)', 50000, 10, 0, 0, 0, 0, 28, 1),
(3627, 0, 0, 0, 'Uthemath I a', 25000, 10, 0, 0, 0, 0, 20, 1),
(3628, 0, 0, 0, 'Uthemath I b', 50000, 10, 0, 0, 0, 0, 36, 1),
(3629, 0, 0, 0, 'Uthemath I c', 80000, 10, 0, 0, 0, 0, 45, 2),
(3630, 0, 0, 0, 'Uthemath I d', 80000, 10, 0, 0, 0, 0, 30, 1),
(3631, 0, 0, 0, 'Uthemath I e', 80000, 10, 0, 0, 0, 0, 35, 2),
(3632, 0, 0, 0, 'Uthemath I f', 150000, 10, 0, 0, 0, 0, 104, 3),
(3633, 0, 0, 0, 'Uthemath II', 250000, 10, 0, 0, 0, 0, 170, 8),
(3634, 0, 0, 0, 'Marketplace 1', 400000, 22, 0, 0, 0, 0, 136, 1),
(3635, 0, 0, 0, 'Marketplace 2', 400000, 22, 0, 0, 0, 0, 148, 2),
(3636, 0, 0, 0, 'Quay 1', 200000, 22, 0, 0, 0, 0, 218, 4),
(3637, 0, 0, 0, 'Quay 2', 200000, 22, 0, 0, 0, 0, 156, 2),
(3638, 0, 0, 0, 'Halls of Sun and Sea', 1000000, 22, 0, 0, 0, 0, 657, 11),
(3639, 0, 0, 0, 'Palace Vicinity', 200000, 22, 0, 0, 0, 0, 203, 4),
(3640, 0, 0, 0, 'Wave Tower', 400000, 22, 0, 0, 0, 0, 340, 4),
(3641, 0, 0, 0, 'Old Sanctuary of God King Qjell', 300000, 18, 0, 0, 0, 0, 701, 6),
(3642, 0, 0, 0, 'Old Heritage Estate', 600000, 20, 0, 0, 0, 0, 435, 7),
(3643, 0, 0, 0, 'Rathleton Plaza 4', 400000, 20, 0, 0, 0, 0, 200, 2),
(3644, 0, 0, 0, 'Rathleton Plaza 3', 400000, 20, 0, 0, 0, 0, 224, 3),
(3645, 0, 0, 0, 'Rathleton Plaza 2', 400000, 20, 0, 0, 0, 0, 112, 2),
(3646, 0, 0, 0, 'Rathleton Plaza 1', 300000, 20, 0, 0, 0, 0, 120, 2),
(3647, 0, 0, 0, 'Antimony Lane 2', 400000, 20, 0, 0, 0, 0, 196, 3),
(3648, 0, 0, 0, 'Antimony Lane 1', 400000, 20, 0, 0, 0, 0, 265, 5),
(3649, 0, 0, 0, 'Wallside Residence', 400000, 20, 0, 0, 0, 0, 264, 4),
(3650, 0, 0, 0, 'Wallside Lane 1', 800000, 20, 0, 0, 0, 0, 286, 4),
(3651, 0, 0, 0, 'Wallside Lane 2', 600000, 20, 0, 0, 0, 0, 312, 4),
(3652, 0, 0, 0, 'Vanward Flats B', 400000, 20, 0, 0, 0, 0, 243, 4),
(3653, 0, 0, 0, 'Vanward Flats A', 400000, 20, 0, 0, 0, 0, 276, 4),
(3654, 0, 0, 0, 'Bronze Brothers Bastion', 5000000, 20, 0, 0, 0, 0, 1231, 15),
(3655, 0, 0, 0, 'Cistern Ave', 300000, 20, 0, 0, 0, 0, 156, 2),
(3656, 0, 0, 0, 'Antimony Lane 4', 400000, 20, 0, 0, 0, 0, 218, 3),
(3657, 0, 0, 0, 'Antimony Lane 3', 400000, 20, 0, 0, 0, 0, 140, 3),
(3658, 0, 0, 0, 'Rathleton Hills Residence', 400000, 20, 0, 0, 0, 0, 252, 3),
(3659, 0, 0, 0, 'Rathleton Hills Estate', 1000000, 20, 0, 0, 0, 0, 710, 13);

-- --------------------------------------------------------

--
-- Table structure for table `house_lists`
--

CREATE TABLE `house_lists` (
  `house_id` int(11) NOT NULL,
  `listid` int(11) NOT NULL,
  `list` text NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

-- --------------------------------------------------------

--
-- Table structure for table `ip_bans`
--

CREATE TABLE `ip_bans` (
  `ip` int(10) UNSIGNED NOT NULL,
  `reason` varchar(255) NOT NULL,
  `banned_at` bigint(20) NOT NULL,
  `expires_at` bigint(20) NOT NULL,
  `banned_by` int(11) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

-- --------------------------------------------------------

--
-- Table structure for table `live_casts`
--

CREATE TABLE `live_casts` (
  `player_id` int(11) NOT NULL,
  `cast_name` varchar(255) NOT NULL,
  `password` tinyint(1) NOT NULL DEFAULT 0,
  `description` varchar(255) DEFAULT NULL,
  `spectators` smallint(1) DEFAULT 0
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

-- --------------------------------------------------------

--
-- Table structure for table `market_history`
--

CREATE TABLE `market_history` (
  `id` int(10) UNSIGNED NOT NULL,
  `player_id` int(11) NOT NULL,
  `sale` tinyint(1) NOT NULL DEFAULT 0,
  `itemtype` int(10) UNSIGNED NOT NULL,
  `amount` smallint(5) UNSIGNED NOT NULL,
  `price` int(10) UNSIGNED NOT NULL DEFAULT 0,
  `expires_at` bigint(20) UNSIGNED NOT NULL,
  `inserted` bigint(20) UNSIGNED NOT NULL,
  `state` tinyint(1) UNSIGNED NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

-- --------------------------------------------------------

--
-- Table structure for table `market_offers`
--

CREATE TABLE `market_offers` (
  `id` int(10) UNSIGNED NOT NULL,
  `player_id` int(11) NOT NULL,
  `sale` tinyint(1) NOT NULL DEFAULT 0,
  `itemtype` int(10) UNSIGNED NOT NULL,
  `amount` smallint(5) UNSIGNED NOT NULL,
  `created` bigint(20) UNSIGNED NOT NULL,
  `anonymous` tinyint(1) NOT NULL DEFAULT 0,
  `price` int(10) UNSIGNED NOT NULL DEFAULT 0
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

-- --------------------------------------------------------

--
-- Table structure for table `myaac_account_actions`
--

CREATE TABLE `myaac_account_actions` (
  `account_id` int(11) NOT NULL,
  `ip` varchar(16) NOT NULL DEFAULT '0.0.0.0',
  `ipv6` binary(16) NOT NULL DEFAULT '0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0',
  `date` int(11) NOT NULL DEFAULT 0,
  `action` varchar(255) NOT NULL DEFAULT ''
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- --------------------------------------------------------

--
-- Table structure for table `myaac_admin_menu`
--

CREATE TABLE `myaac_admin_menu` (
  `id` int(11) NOT NULL,
  `name` varchar(255) NOT NULL DEFAULT '',
  `page` varchar(255) NOT NULL DEFAULT '',
  `ordering` int(11) NOT NULL DEFAULT 0,
  `flags` int(11) NOT NULL DEFAULT 0,
  `enabled` int(1) NOT NULL DEFAULT 1
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- --------------------------------------------------------

--
-- Table structure for table `myaac_bugtracker`
--

CREATE TABLE `myaac_bugtracker` (
  `account` varchar(255) NOT NULL,
  `type` int(11) NOT NULL DEFAULT 0,
  `status` int(11) NOT NULL DEFAULT 0,
  `text` text NOT NULL,
  `id` int(11) NOT NULL DEFAULT 0,
  `subject` varchar(255) NOT NULL DEFAULT '',
  `reply` int(11) NOT NULL DEFAULT 0,
  `who` int(11) NOT NULL DEFAULT 0,
  `uid` int(11) NOT NULL,
  `tag` int(11) NOT NULL DEFAULT 0
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- --------------------------------------------------------

--
-- Table structure for table `myaac_changelog`
--

CREATE TABLE `myaac_changelog` (
  `id` int(11) NOT NULL,
  `body` varchar(500) NOT NULL DEFAULT '',
  `type` tinyint(1) NOT NULL DEFAULT 0 COMMENT '1 - added, 2 - removed, 3 - changed, 4 - fixed',
  `where` tinyint(1) NOT NULL DEFAULT 0 COMMENT '1 - server, 2 - site',
  `date` int(11) NOT NULL DEFAULT 0,
  `player_id` int(11) NOT NULL DEFAULT 0,
  `hidden` tinyint(1) NOT NULL DEFAULT 0
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

--
-- Dumping data for table `myaac_changelog`
--

INSERT INTO `myaac_changelog` (`id`, `body`, `type`, `where`, `date`, `player_id`, `hidden`) VALUES
(1, 'MyAAC installed. (:', 3, 2, 1688079610, 0, 0);

-- --------------------------------------------------------

--
-- Table structure for table `myaac_charbazaar`
--

CREATE TABLE `myaac_charbazaar` (
  `id` int(11) NOT NULL,
  `account_old` int(11) NOT NULL,
  `account_new` int(11) NOT NULL,
  `player_id` int(11) NOT NULL,
  `price` int(11) NOT NULL,
  `date_end` datetime NOT NULL,
  `date_start` datetime NOT NULL,
  `bid_account` int(11) NOT NULL,
  `bid_price` int(11) NOT NULL,
  `status` int(11) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- --------------------------------------------------------

--
-- Table structure for table `myaac_charbazaar_bid`
--

CREATE TABLE `myaac_charbazaar_bid` (
  `id` int(11) NOT NULL,
  `account_id` int(11) NOT NULL,
  `auction_id` int(11) NOT NULL,
  `bid` int(11) NOT NULL,
  `date` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- --------------------------------------------------------

--
-- Table structure for table `myaac_config`
--

CREATE TABLE `myaac_config` (
  `id` int(11) NOT NULL,
  `name` varchar(30) NOT NULL,
  `value` varchar(1000) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

--
-- Dumping data for table `myaac_config`
--

INSERT INTO `myaac_config` (`id`, `name`, `value`) VALUES
(1, 'database_version', '34'),
(2, 'status_online', '1'),
(3, 'status_players', '1'),
(4, 'status_playersMax', '2000'),
(5, 'status_lastCheck', '1688080855'),
(6, 'status_uptime', '164'),
(7, 'status_monsters', '74792'),
(8, 'status_uptimeReadable', '0h 2m'),
(9, 'status_motd', 'Welcome to The Tibia!'),
(10, 'status_mapAuthor', 'Tibia-global'),
(11, 'status_mapName', 'realmap'),
(12, 'status_mapWidth', '34143'),
(13, 'status_mapHeight', '33812'),
(14, 'status_server', 'Solera-Global Server'),
(15, 'status_serverVersion', '1.3'),
(16, 'status_clientVersion', '8.60'),
(17, 'last_usage_report', '1686092488');

-- --------------------------------------------------------

--
-- Table structure for table `myaac_faq`
--

CREATE TABLE `myaac_faq` (
  `id` int(11) NOT NULL,
  `question` varchar(255) NOT NULL DEFAULT '',
  `answer` varchar(1020) NOT NULL DEFAULT '',
  `ordering` int(11) NOT NULL DEFAULT 0,
  `hidden` tinyint(1) NOT NULL DEFAULT 0
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- --------------------------------------------------------

--
-- Table structure for table `myaac_forum`
--

CREATE TABLE `myaac_forum` (
  `id` int(11) NOT NULL,
  `first_post` int(11) NOT NULL DEFAULT 0,
  `last_post` int(11) NOT NULL DEFAULT 0,
  `section` int(3) NOT NULL DEFAULT 0,
  `replies` int(20) NOT NULL DEFAULT 0,
  `views` int(20) NOT NULL DEFAULT 0,
  `author_aid` int(20) NOT NULL DEFAULT 0,
  `author_guid` int(20) NOT NULL DEFAULT 0,
  `post_text` text NOT NULL,
  `post_topic` varchar(255) NOT NULL DEFAULT '',
  `post_smile` tinyint(1) NOT NULL DEFAULT 0,
  `post_html` tinyint(1) NOT NULL DEFAULT 0,
  `post_date` int(20) NOT NULL DEFAULT 0,
  `last_edit_aid` int(20) NOT NULL DEFAULT 0,
  `edit_date` int(20) NOT NULL DEFAULT 0,
  `post_ip` varchar(32) NOT NULL DEFAULT '0.0.0.0',
  `sticked` tinyint(1) NOT NULL DEFAULT 0,
  `closed` tinyint(1) NOT NULL DEFAULT 0
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- --------------------------------------------------------

--
-- Table structure for table `myaac_forum_boards`
--

CREATE TABLE `myaac_forum_boards` (
  `id` int(11) NOT NULL,
  `name` varchar(32) NOT NULL,
  `description` varchar(255) NOT NULL DEFAULT '',
  `ordering` int(11) NOT NULL DEFAULT 0,
  `guild` int(11) NOT NULL DEFAULT 0,
  `access` int(11) NOT NULL DEFAULT 0,
  `closed` tinyint(1) NOT NULL DEFAULT 0,
  `hidden` tinyint(1) NOT NULL DEFAULT 0
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

--
-- Dumping data for table `myaac_forum_boards`
--

INSERT INTO `myaac_forum_boards` (`id`, `name`, `description`, `ordering`, `guild`, `access`, `closed`, `hidden`) VALUES
(1, 'News', 'News commenting', 0, 0, 0, 1, 0),
(2, 'Trade', 'Trade offers.', 1, 0, 0, 0, 0),
(3, 'Quests', 'Quest making.', 2, 0, 0, 0, 0),
(4, 'Pictures', 'Your pictures.', 3, 0, 0, 0, 0),
(5, 'Bug Report', 'Report bugs there.', 4, 0, 0, 0, 0);

-- --------------------------------------------------------

--
-- Table structure for table `myaac_gallery`
--

CREATE TABLE `myaac_gallery` (
  `id` int(11) NOT NULL,
  `comment` varchar(255) NOT NULL DEFAULT '',
  `image` varchar(255) NOT NULL,
  `thumb` varchar(255) NOT NULL,
  `author` varchar(50) NOT NULL DEFAULT '',
  `ordering` int(11) NOT NULL DEFAULT 0,
  `hidden` tinyint(1) NOT NULL DEFAULT 0
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

--
-- Dumping data for table `myaac_gallery`
--

INSERT INTO `myaac_gallery` (`id`, `comment`, `image`, `thumb`, `author`, `ordering`, `hidden`) VALUES
(1, 'Demon', 'images/gallery/demon.jpg', 'images/gallery/demon_thumb.gif', 'MyAAC', 1, 0);

-- --------------------------------------------------------

--
-- Table structure for table `myaac_menu`
--

CREATE TABLE `myaac_menu` (
  `id` int(11) NOT NULL,
  `template` varchar(255) NOT NULL,
  `name` varchar(255) NOT NULL,
  `link` varchar(255) NOT NULL,
  `blank` tinyint(1) NOT NULL DEFAULT 0,
  `color` varchar(6) NOT NULL DEFAULT '',
  `category` int(11) NOT NULL DEFAULT 1,
  `ordering` int(11) NOT NULL DEFAULT 0,
  `enabled` int(1) NOT NULL DEFAULT 1
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

--
-- Dumping data for table `myaac_menu`
--

INSERT INTO `myaac_menu` (`id`, `template`, `name`, `link`, `blank`, `color`, `category`, `ordering`, `enabled`) VALUES
(1, 'tibiacom', 'Latest News', 'news', 0, '', 1, 0, 1),
(2, 'tibiacom', 'News Archive', 'news/archive', 0, '', 1, 1, 1),
(3, 'tibiacom', 'Event Schedule', 'eventcalendar', 0, '', 1, 2, 1),
(4, 'tibiacom', 'Account Management', 'account/manage', 0, '', 2, 0, 1),
(5, 'tibiacom', 'Create Account', 'account/create', 0, '', 2, 1, 1),
(6, 'tibiacom', 'Lost Account?', 'account/lost', 0, '', 2, 2, 1),
(7, 'tibiacom', 'Server Rules', 'rules', 0, '', 2, 3, 1),
(8, 'tibiacom', 'Downloads', 'downloadclient', 0, '', 2, 4, 1),
(9, 'tibiacom', 'Report Bug', 'bugtracker', 0, '', 2, 5, 1),
(10, 'tibiacom', 'Characters', 'characters', 0, '', 3, 0, 1),
(11, 'tibiacom', 'Who Is Online?', 'online', 0, '', 3, 1, 1),
(12, 'tibiacom', 'Highscores', 'highscores', 0, '', 3, 2, 1),
(13, 'tibiacom', 'Last Kills', 'lastkills', 0, '', 3, 3, 1),
(14, 'tibiacom', 'Houses', 'houses', 0, '', 3, 4, 1),
(15, 'tibiacom', 'Guilds', 'guilds', 0, '', 3, 5, 1),
(16, 'tibiacom', 'Polls', 'polls', 0, '', 3, 6, 1),
(17, 'tibiacom', 'Bans', 'bans', 0, '', 3, 7, 1),
(18, 'tibiacom', 'Support List', 'team', 0, '', 3, 8, 1),
(19, 'tibiacom', 'Forum', 'forum', 0, '', 4, 0, 1),
(20, 'tibiacom', 'Creatures', 'creatures', 0, '', 5, 0, 1),
(21, 'tibiacom', 'Spells', 'spells', 0, '', 5, 1, 1),
(22, 'tibiacom', 'Commands', 'commands', 0, '', 5, 2, 1),
(23, 'tibiacom', 'Gallery', 'gallery', 0, '', 5, 3, 1),
(24, 'tibiacom', 'Server Info', 'serverInfo', 0, '', 5, 4, 1),
(25, 'tibiacom', 'Experience Table', 'experienceTable', 0, '', 5, 5, 1),
(26, 'tibiacom', 'Current Auctions', 'currentcharactertrades', 0, '', 7, 0, 1),
(27, 'tibiacom', 'Auction History', 'pastcharactertrades', 0, '', 7, 1, 1),
(28, 'tibiacom', 'My Bids', 'ownbids', 0, '', 7, 2, 1),
(29, 'tibiacom', 'My Auctions', 'owncharactertrades', 0, '', 7, 3, 1),
(30, 'tibiacom', 'Create Auction', 'createcharacterauction', 0, '', 7, 4, 1),
(31, 'tibiacom', 'Buy Points', 'points', 0, '', 6, 0, 1),
(32, 'tibiacom', 'Shop Offer', 'gifts', 0, '', 6, 1, 1),
(33, 'tibiacom', 'Shop History', 'gifts/history', 0, '', 6, 2, 1);

-- --------------------------------------------------------

--
-- Table structure for table `myaac_monsters`
--

CREATE TABLE `myaac_monsters` (
  `id` int(11) NOT NULL,
  `hidden` tinyint(1) NOT NULL DEFAULT 0,
  `name` varchar(255) NOT NULL,
  `mana` int(11) NOT NULL DEFAULT 0,
  `exp` int(11) NOT NULL,
  `health` int(11) NOT NULL,
  `speed_lvl` int(11) NOT NULL DEFAULT 1,
  `use_haste` tinyint(1) NOT NULL,
  `voices` text NOT NULL,
  `immunities` varchar(255) NOT NULL,
  `elements` text NOT NULL,
  `summonable` tinyint(1) NOT NULL,
  `convinceable` tinyint(1) NOT NULL,
  `pushable` tinyint(1) NOT NULL DEFAULT 0,
  `canpushitems` tinyint(1) NOT NULL DEFAULT 0,
  `canwalkonenergy` tinyint(1) NOT NULL DEFAULT 0,
  `canwalkonpoison` tinyint(1) NOT NULL DEFAULT 0,
  `canwalkonfire` tinyint(1) NOT NULL DEFAULT 0,
  `runonhealth` tinyint(1) NOT NULL DEFAULT 0,
  `hostile` tinyint(1) NOT NULL DEFAULT 0,
  `attackable` tinyint(1) NOT NULL DEFAULT 0,
  `rewardboss` tinyint(1) NOT NULL DEFAULT 0,
  `defense` int(11) NOT NULL DEFAULT 0,
  `armor` int(11) NOT NULL DEFAULT 0,
  `canpushcreatures` tinyint(1) NOT NULL DEFAULT 0,
  `race` varchar(255) NOT NULL,
  `loot` text NOT NULL,
  `summons` text NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- --------------------------------------------------------

--
-- Table structure for table `myaac_news`
--

CREATE TABLE `myaac_news` (
  `id` int(11) NOT NULL,
  `title` varchar(100) NOT NULL,
  `body` text NOT NULL,
  `type` tinyint(1) NOT NULL DEFAULT 0 COMMENT '1 - news, 2 - ticker, 3 - article',
  `date` int(11) NOT NULL DEFAULT 0,
  `category` tinyint(1) NOT NULL DEFAULT 0,
  `player_id` int(11) NOT NULL DEFAULT 0,
  `last_modified_by` int(11) NOT NULL DEFAULT 0,
  `last_modified_date` int(11) NOT NULL DEFAULT 0,
  `comments` varchar(50) NOT NULL DEFAULT '',
  `article_text` varchar(300) NOT NULL DEFAULT '',
  `article_image` varchar(100) NOT NULL DEFAULT '',
  `hidden` tinyint(1) NOT NULL DEFAULT 0
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

--
-- Dumping data for table `myaac_news`
--

INSERT INTO `myaac_news` (`id`, `title`, `body`, `type`, `date`, `category`, `player_id`, `last_modified_by`, `last_modified_date`, `comments`, `article_text`, `article_image`, `hidden`) VALUES
(1, 'Hello!', 'MyAAC is just READY to use!', 1, 1688079679, 2, 203, 0, 0, 'https://my-aac.org', '', '', 0),
(2, 'Hello tickets!', 'https://my-aac.org', 2, 1688079679, 4, 203, 0, 0, '', '', '', 0);

-- --------------------------------------------------------

--
-- Table structure for table `myaac_news_categories`
--

CREATE TABLE `myaac_news_categories` (
  `id` int(11) NOT NULL,
  `name` varchar(50) NOT NULL DEFAULT '',
  `description` varchar(50) NOT NULL DEFAULT '',
  `icon_id` int(2) NOT NULL DEFAULT 0,
  `hidden` tinyint(1) NOT NULL DEFAULT 0
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

--
-- Dumping data for table `myaac_news_categories`
--

INSERT INTO `myaac_news_categories` (`id`, `name`, `description`, `icon_id`, `hidden`) VALUES
(1, '', '', 0, 0),
(2, '', '', 1, 0),
(3, '', '', 2, 0),
(4, '', '', 3, 0),
(5, '', '', 4, 0);

-- --------------------------------------------------------

--
-- Table structure for table `myaac_notepad`
--

CREATE TABLE `myaac_notepad` (
  `id` int(11) NOT NULL,
  `account_id` int(11) NOT NULL,
  `content` text NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- --------------------------------------------------------

--
-- Table structure for table `myaac_pages`
--

CREATE TABLE `myaac_pages` (
  `id` int(11) NOT NULL,
  `name` varchar(30) NOT NULL,
  `title` varchar(30) NOT NULL,
  `body` text NOT NULL,
  `date` int(11) NOT NULL DEFAULT 0,
  `player_id` int(11) NOT NULL DEFAULT 0,
  `php` tinyint(1) NOT NULL DEFAULT 0 COMMENT '0 - plain html, 1 - php',
  `enable_tinymce` tinyint(1) NOT NULL DEFAULT 1 COMMENT '1 - enabled, 0 - disabled',
  `access` tinyint(2) NOT NULL DEFAULT 0,
  `hidden` tinyint(1) NOT NULL DEFAULT 0
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

--
-- Dumping data for table `myaac_pages`
--

INSERT INTO `myaac_pages` (`id`, `name`, `title`, `body`, `date`, `player_id`, `php`, `enable_tinymce`, `access`, `hidden`) VALUES
(1, 'downloads', 'Downloads', '<p>&nbsp;</p>\n<p>&nbsp;</p>\n<div style=\"text-align: center;\">We\'re using official Tibia Client <strong>{{ config.client / 100 }}</strong><br />\n<p>Download Tibia Client <strong>{{ config.client / 100 }}</strong>&nbsp;for Windows <a href=\"https://drive.google.com/drive/folders/0B2-sMQkWYzhGSFhGVlY2WGk5czQ\" target=\"_blank\" rel=\"noopener\">HERE</a>.</p>\n<h2>IP Changer:</h2>\n<a href=\"https://static.otland.net/ipchanger.exe\" target=\"_blank\" rel=\"noopener\">HERE</a></div>', 0, 1, 0, 1, 1, 0),
(2, 'commands', 'Commands', '<table style=\"border-collapse: collapse; width: 87.8471%; height: 57px;\" border=\"1\">\n<tbody>\n<tr style=\"height: 18px;\">\n<td style=\"width: 33.3333%; background-color: #505050; height: 18px;\"><span style=\"color: #ffffff;\"><strong>Words</strong></span></td>\n<td style=\"width: 33.3333%; background-color: #505050; height: 18px;\"><span style=\"color: #ffffff;\"><strong>Description</strong></span></td>\n</tr>\n<tr style=\"height: 18px; background-color: #f1e0c6;\">\n<td style=\"width: 33.3333%; height: 18px;\"><em>!example</em></td>\n<td style=\"width: 33.3333%; height: 18px;\">This is just an example</td>\n</tr>\n<tr style=\"height: 18px; background-color: #d4c0a1;\">\n<td style=\"width: 33.3333%; height: 18px;\"><em>!buyhouse</em></td>\n<td style=\"width: 33.3333%; height: 18px;\">Buy house you are looking at</td>\n</tr>\n<tr style=\"height: 18px; background-color: #f1e0c6;\">\n<td style=\"width: 33.3333%; height: 18px;\"><em>!aol</em></td>\n<td style=\"width: 33.3333%; height: 18px;\">Buy AoL</td>\n</tr>\n</tbody>\n</table>', 0, 1, 0, 1, 1, 0),
(3, 'rules_on_the_page', 'Rules', '1. Names\na) Names which contain insulting (e.g. \"Bastard\"), racist (e.g. \"Nigger\"), extremely right-wing (e.g. \"Hitler\"), sexist (e.g. \"Bitch\") or offensive (e.g. \"Copkiller\") language.\nb) Names containing parts of sentences (e.g. \"Mike returns\"), nonsensical combinations of letters (e.g. \"Fgfshdsfg\") or invalid formattings (e.g. \"Thegreatknight\").\nc) Names that obviously do not describe a person (e.g. \"Christmastree\", \"Matrix\"), names of real life celebrities (e.g. \"Britney Spears\"), names that refer to real countries (e.g. \"Swedish Druid\"), names which were created to fake other players\' identities (e.g. \"Arieswer\" instead of \"Arieswar\") or official positions (e.g. \"System Admin\").\n\n2. Cheating\na) Exploiting obvious errors of the game (\"bugs\"), for instance to duplicate items. If you find an error you must report it to CipSoft immediately.\nb) Intentional abuse of weaknesses in the gameplay, for example arranging objects or players in a way that other players cannot move them.\nc) Using tools to automatically perform or repeat certain actions without any interaction by the player (\"macros\").\nd) Manipulating the client program or using additional software to play the game.\ne) Trying to steal other players\' account data (\"hacking\").\nf) Playing on more than one account at the same time (\"multi-clienting\").\ng) Offering account data to other players or accepting other players\' account data (\"account-trading/sharing\").\n\n3. Gamemasters\na) Threatening a gamemaster because of his or her actions or position as a gamemaster.\nb) Pretending to be a gamemaster or to have influence on the decisions of a gamemaster.\nc) Intentionally giving wrong or misleading information to a gamemaster concerning his or her investigations or making false reports about rule violations.\n\n4. Player Killing\na) Excessive killing of characters who are not marked with a \"skull\" on worlds which are not PvP-enforced. Please note that killing marked characters is not a reason for a banishment.\n\nA violation of the Tibia Rules may lead to temporary banishment of characters and accounts. In severe cases removal or modification of character skills, attributes and belongings, as well as the permanent removal of accounts without any compensation may be considered. The sanction is based on the seriousness of the rule violation and the previous record of the player. It is determined by the gamemaster imposing the banishment.\n\nThese rules may be changed at any time. All changes will be announced on the official website.', 0, 1, 0, 0, 1, 0);

-- --------------------------------------------------------

--
-- Table structure for table `myaac_polls`
--

CREATE TABLE `myaac_polls` (
  `id` int(11) NOT NULL,
  `question` varchar(255) NOT NULL,
  `description` varchar(255) NOT NULL,
  `end` int(11) NOT NULL,
  `start` int(11) NOT NULL,
  `answers` int(11) NOT NULL,
  `votes_all` int(11) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- --------------------------------------------------------

--
-- Table structure for table `myaac_polls_answers`
--

CREATE TABLE `myaac_polls_answers` (
  `poll_id` int(11) NOT NULL,
  `answer_id` int(11) NOT NULL,
  `answer` varchar(255) NOT NULL,
  `votes` int(11) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- --------------------------------------------------------

--
-- Table structure for table `myaac_spells`
--

CREATE TABLE `myaac_spells` (
  `id` int(11) NOT NULL,
  `spell` varchar(255) NOT NULL DEFAULT '',
  `name` varchar(255) NOT NULL,
  `words` varchar(255) NOT NULL DEFAULT '',
  `category` tinyint(1) NOT NULL DEFAULT 0 COMMENT '1 - attack, 2 - healing, 3 - summon, 4 - supply, 5 - support',
  `type` tinyint(1) NOT NULL DEFAULT 0 COMMENT '1 - instant, 2 - conjure, 3 - rune',
  `level` int(11) NOT NULL DEFAULT 0,
  `maglevel` int(11) NOT NULL DEFAULT 0,
  `mana` int(11) NOT NULL DEFAULT 0,
  `soul` tinyint(3) NOT NULL DEFAULT 0,
  `conjure_id` int(11) NOT NULL DEFAULT 0,
  `conjure_count` tinyint(3) NOT NULL DEFAULT 0,
  `reagent` int(11) NOT NULL DEFAULT 0,
  `item_id` int(11) NOT NULL DEFAULT 0,
  `premium` tinyint(1) NOT NULL DEFAULT 0,
  `vocations` varchar(100) NOT NULL DEFAULT '',
  `hidden` tinyint(1) NOT NULL DEFAULT 0
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- --------------------------------------------------------

--
-- Table structure for table `myaac_videos`
--

CREATE TABLE `myaac_videos` (
  `id` int(11) NOT NULL,
  `title` varchar(100) NOT NULL DEFAULT '',
  `youtube_id` varchar(20) NOT NULL,
  `author` varchar(50) NOT NULL DEFAULT '',
  `ordering` int(11) NOT NULL DEFAULT 0,
  `hidden` tinyint(1) NOT NULL DEFAULT 0
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- --------------------------------------------------------

--
-- Table structure for table `myaac_visitors`
--

CREATE TABLE `myaac_visitors` (
  `ip` varchar(45) NOT NULL,
  `lastvisit` int(11) NOT NULL DEFAULT 0,
  `page` varchar(2048) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- --------------------------------------------------------

--
-- Table structure for table `myaac_weapons`
--

CREATE TABLE `myaac_weapons` (
  `id` int(11) NOT NULL,
  `level` int(11) NOT NULL DEFAULT 0,
  `maglevel` int(11) NOT NULL DEFAULT 0,
  `vocations` varchar(100) NOT NULL DEFAULT ''
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- --------------------------------------------------------

--
-- Table structure for table `newsticker`
--

CREATE TABLE `newsticker` (
  `id` int(10) UNSIGNED NOT NULL,
  `date` int(11) NOT NULL,
  `text` varchar(255) NOT NULL,
  `icon` varchar(50) NOT NULL
) ENGINE=MyISAM DEFAULT CHARSET=latin1;

--
-- Dumping data for table `newsticker`
--

INSERT INTO `newsticker` (`id`, `date`, `text`, `icon`) VALUES
(2, 1559090424, 'Bem Vindos! Em breve estaremos inaugurando nosso servidor', 'newsicon_cipsoft'),
(4, 1559229069, 'OBS: Baixem nosso client para nÃ£o ocorrer BUGS dentro do Jogo', 'newsicon_community'),
(5, 1560349266, 'Bom dia! segue o nosso instagram para tÃ¡ por dentro de tudo https://www.instagram.com/orderglobal/', 'newsicon_community'),
(6, 1560349305, 'Caso de bugs, reportem no OPEN TICKES!', 'newsicon_cipsoft'),
(7, 1564571895, 'Caso queira falar cmg entrem em contato pelo instagram -> orderglobal', 'newsicon_cipsoft'),
(8, 1588303390, 'VERSÃƒO BETA ABERTA NOVAMENTE', 'newsicon_community'),
(10, 1588361765, 'CLIENT CORRIGIDO, BAIXEM O NOVO CLIENTE', 'newsicon_cipsoft');

-- --------------------------------------------------------

--
-- Table structure for table `pagseguro`
--

CREATE TABLE `pagseguro` (
  `date` datetime NOT NULL,
  `code` varchar(50) NOT NULL,
  `reference` varchar(200) NOT NULL,
  `type` int(11) NOT NULL,
  `status` int(11) NOT NULL,
  `lastEventDate` datetime NOT NULL
) ENGINE=MyISAM DEFAULT CHARSET=latin1;

-- --------------------------------------------------------

--
-- Table structure for table `pagsegurotransacoes`
--

CREATE TABLE `pagsegurotransacoes` (
  `TransacaoID` varchar(36) NOT NULL,
  `VendedorEmail` varchar(200) NOT NULL,
  `Referencia` varchar(200) DEFAULT NULL,
  `TipoFrete` char(2) DEFAULT NULL,
  `ValorFrete` decimal(10,2) DEFAULT NULL,
  `Extras` decimal(10,2) DEFAULT NULL,
  `Anotacao` text DEFAULT NULL,
  `TipoPagamento` varchar(50) NOT NULL,
  `StatusTransacao` varchar(50) NOT NULL,
  `CliNome` varchar(200) NOT NULL,
  `CliEmail` varchar(200) NOT NULL,
  `CliEndereco` varchar(200) NOT NULL,
  `CliNumero` varchar(10) DEFAULT NULL,
  `CliComplemento` varchar(100) DEFAULT NULL,
  `CliBairro` varchar(100) NOT NULL,
  `CliCidade` varchar(100) NOT NULL,
  `CliEstado` char(2) NOT NULL,
  `CliCEP` varchar(9) NOT NULL,
  `CliTelefone` varchar(14) DEFAULT NULL,
  `NumItens` int(11) NOT NULL,
  `Data` datetime NOT NULL,
  `ProdQuantidade_x` int(5) NOT NULL,
  `status` tinyint(1) UNSIGNED NOT NULL DEFAULT 0
) ENGINE=MyISAM DEFAULT CHARSET=latin1;

-- --------------------------------------------------------

--
-- Table structure for table `pagseguro_transactions`
--

CREATE TABLE `pagseguro_transactions` (
  `transaction_code` varchar(36) NOT NULL,
  `name` varchar(200) DEFAULT NULL,
  `payment_method` varchar(50) NOT NULL,
  `status` varchar(50) NOT NULL,
  `item_count` int(11) NOT NULL,
  `data` datetime NOT NULL,
  `payment_amount` float DEFAULT 0
) ENGINE=MyISAM DEFAULT CHARSET=latin1;

-- --------------------------------------------------------

--
-- Table structure for table `paypal`
--

CREATE TABLE `paypal` (
  `id` int(11) NOT NULL,
  `account` varchar(255) COLLATE utf8_unicode_ci NOT NULL,
  `valor` double(9,2) NOT NULL,
  `code` varchar(255) COLLATE utf8_unicode_ci NOT NULL,
  `status` varchar(255) COLLATE utf8_unicode_ci NOT NULL DEFAULT 'Waiting',
  `date` timestamp NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `paypal_transactions`
--

CREATE TABLE `paypal_transactions` (
  `id` int(11) NOT NULL,
  `payment_status` varchar(70) NOT NULL DEFAULT '',
  `date` datetime NOT NULL,
  `payer_email` varchar(255) NOT NULL DEFAULT '',
  `payer_id` varchar(255) NOT NULL DEFAULT '',
  `item_number1` varchar(255) NOT NULL DEFAULT '',
  `mc_gross` float NOT NULL,
  `mc_currency` varchar(5) NOT NULL DEFAULT '',
  `txn_id` varchar(255) NOT NULL DEFAULT ''
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- --------------------------------------------------------

--
-- Table structure for table `picpay`
--

CREATE TABLE `picpay` (
  `id` int(11) NOT NULL,
  `ref` varchar(255) NOT NULL,
  `valor` double(9,2) NOT NULL,
  `pontos` int(11) NOT NULL,
  `status` varchar(50) NOT NULL,
  `account_name` varchar(100) NOT NULL,
  `link` varchar(7000) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

-- --------------------------------------------------------

--
-- Table structure for table `players`
--

CREATE TABLE `players` (
  `id` int(11) NOT NULL,
  `name` varchar(255) NOT NULL,
  `group_id` int(11) NOT NULL DEFAULT 1,
  `account_id` int(11) NOT NULL DEFAULT 0,
  `level` int(11) NOT NULL DEFAULT 1,
  `vocation` int(11) NOT NULL DEFAULT 0,
  `health` int(11) NOT NULL DEFAULT 150,
  `healthmax` int(11) NOT NULL DEFAULT 150,
  `experience` bigint(20) NOT NULL DEFAULT 0,
  `lookbody` int(11) NOT NULL DEFAULT 0,
  `lookfeet` int(11) NOT NULL DEFAULT 0,
  `lookhead` int(11) NOT NULL DEFAULT 0,
  `looklegs` int(11) NOT NULL DEFAULT 0,
  `looktype` int(11) NOT NULL DEFAULT 136,
  `lookaddons` int(11) NOT NULL DEFAULT 0,
  `maglevel` int(11) NOT NULL DEFAULT 0,
  `mana` int(11) NOT NULL DEFAULT 0,
  `manamax` int(11) NOT NULL DEFAULT 0,
  `manaspent` int(11) UNSIGNED NOT NULL DEFAULT 0,
  `soul` int(10) UNSIGNED NOT NULL DEFAULT 0,
  `town_id` int(11) NOT NULL DEFAULT 0,
  `posx` int(11) NOT NULL DEFAULT 0,
  `posy` int(11) NOT NULL DEFAULT 0,
  `posz` int(11) NOT NULL DEFAULT 0,
  `conditions` blob NOT NULL,
  `cap` int(11) NOT NULL DEFAULT 0,
  `sex` int(11) NOT NULL DEFAULT 0,
  `lastlogin` bigint(20) UNSIGNED NOT NULL DEFAULT 0,
  `lastip` int(10) UNSIGNED NOT NULL DEFAULT 0,
  `save` tinyint(1) NOT NULL DEFAULT 1,
  `skull` tinyint(1) NOT NULL DEFAULT 0,
  `skulltime` int(11) NOT NULL DEFAULT 0,
  `lastlogout` bigint(20) UNSIGNED NOT NULL DEFAULT 0,
  `blessings` tinyint(2) NOT NULL DEFAULT 0,
  `blessings1` tinyint(4) NOT NULL DEFAULT 0,
  `blessings2` tinyint(4) NOT NULL DEFAULT 0,
  `blessings3` tinyint(4) NOT NULL DEFAULT 0,
  `blessings4` tinyint(4) NOT NULL DEFAULT 0,
  `blessings5` tinyint(4) NOT NULL DEFAULT 0,
  `blessings6` tinyint(4) NOT NULL DEFAULT 0,
  `blessings7` tinyint(4) NOT NULL DEFAULT 0,
  `blessings8` tinyint(4) NOT NULL DEFAULT 0,
  `onlinetime` int(11) NOT NULL DEFAULT 0,
  `deletion` bigint(15) NOT NULL DEFAULT 0,
  `balance` bigint(20) UNSIGNED NOT NULL DEFAULT 0,
  `offlinetraining_time` smallint(5) UNSIGNED NOT NULL DEFAULT 43200,
  `offlinetraining_skill` int(11) NOT NULL DEFAULT -1,
  `stamina` bigint(20) NOT NULL DEFAULT 151200000 COMMENT 'stored in miliseconds',
  `skill_fist` int(10) UNSIGNED NOT NULL DEFAULT 10,
  `skill_fist_tries` bigint(20) UNSIGNED NOT NULL DEFAULT 0,
  `skill_club` int(10) UNSIGNED NOT NULL DEFAULT 10,
  `skill_club_tries` bigint(20) UNSIGNED NOT NULL DEFAULT 0,
  `skill_sword` int(10) UNSIGNED NOT NULL DEFAULT 10,
  `skill_sword_tries` bigint(20) UNSIGNED NOT NULL DEFAULT 0,
  `skill_axe` int(10) UNSIGNED NOT NULL DEFAULT 10,
  `skill_axe_tries` bigint(20) UNSIGNED NOT NULL DEFAULT 0,
  `skill_dist` int(10) UNSIGNED NOT NULL DEFAULT 10,
  `skill_dist_tries` bigint(20) UNSIGNED NOT NULL DEFAULT 0,
  `skill_shielding` int(10) UNSIGNED NOT NULL DEFAULT 10,
  `skill_shielding_tries` bigint(20) UNSIGNED NOT NULL DEFAULT 0,
  `skill_fishing` int(10) UNSIGNED NOT NULL DEFAULT 10,
  `skill_fishing_tries` bigint(20) UNSIGNED NOT NULL DEFAULT 0,
  `deleted` tinyint(1) NOT NULL DEFAULT 0,
  `description` varchar(255) NOT NULL DEFAULT '',
  `comment` text NOT NULL,
  `create_ip` int(11) NOT NULL DEFAULT 0,
  `create_date` int(11) NOT NULL DEFAULT 0,
  `hidden` tinyint(1) NOT NULL DEFAULT 0,
  `cast` tinyint(1) NOT NULL DEFAULT 0,
  `skill_critical_hit_chance` int(10) UNSIGNED NOT NULL DEFAULT 0,
  `skill_critical_hit_chance_tries` bigint(20) UNSIGNED NOT NULL DEFAULT 0,
  `skill_critical_hit_damage` int(10) UNSIGNED NOT NULL DEFAULT 0,
  `skill_critical_hit_damage_tries` bigint(20) UNSIGNED NOT NULL DEFAULT 0,
  `skill_life_leech_chance` int(10) UNSIGNED NOT NULL DEFAULT 0,
  `skill_life_leech_chance_tries` bigint(20) UNSIGNED NOT NULL DEFAULT 0,
  `skill_life_leech_amount` int(10) UNSIGNED NOT NULL DEFAULT 0,
  `skill_life_leech_amount_tries` bigint(20) UNSIGNED NOT NULL DEFAULT 0,
  `skill_mana_leech_chance` int(10) UNSIGNED NOT NULL DEFAULT 0,
  `skill_mana_leech_chance_tries` bigint(20) UNSIGNED NOT NULL DEFAULT 0,
  `skill_mana_leech_amount` int(10) UNSIGNED NOT NULL DEFAULT 0,
  `skill_mana_leech_amount_tries` bigint(20) UNSIGNED NOT NULL DEFAULT 0,
  `skill_criticalhit_chance` bigint(20) UNSIGNED NOT NULL DEFAULT 0,
  `skill_criticalhit_damage` bigint(20) UNSIGNED NOT NULL DEFAULT 0,
  `skill_lifeleech_chance` bigint(20) UNSIGNED NOT NULL DEFAULT 0,
  `skill_lifeleech_amount` bigint(20) UNSIGNED NOT NULL DEFAULT 0,
  `skill_manaleech_chance` bigint(20) UNSIGNED NOT NULL DEFAULT 0,
  `skill_manaleech_amount` bigint(20) UNSIGNED NOT NULL DEFAULT 0,
  `prey_stamina_1` int(11) DEFAULT NULL,
  `prey_stamina_2` int(11) DEFAULT NULL,
  `prey_stamina_3` int(11) DEFAULT NULL,
  `prey_column` smallint(6) NOT NULL DEFAULT 1,
  `bonus_reroll` int(11) NOT NULL DEFAULT 0,
  `xpboost_stamina` smallint(5) DEFAULT NULL,
  `xpboost_value` tinyint(4) DEFAULT NULL,
  `marriage_status` bigint(20) UNSIGNED NOT NULL DEFAULT 0,
  `hide_skills` int(11) DEFAULT NULL,
  `hide_set` int(11) DEFAULT NULL,
  `former` varchar(255) NOT NULL DEFAULT '-',
  `signature` varchar(255) NOT NULL,
  `marriage_spouse` int(11) NOT NULL DEFAULT -1,
  `loyalty_ranking` tinyint(1) NOT NULL DEFAULT 0,
  `auction_balance` int(11) NOT NULL DEFAULT 0,
  `hide_char1` int(11) NOT NULL DEFAULT 0,
  `broadcasting` tinyint(4) NOT NULL DEFAULT 0,
  `viewers` int(1) NOT NULL DEFAULT 0,
  `frags_all` smallint(5) UNSIGNED DEFAULT 0,
  `direction` int(1) UNSIGNED NOT NULL DEFAULT 2,
  `frags` int(11) NOT NULL DEFAULT 0,
  `lookmount` int(11) NOT NULL DEFAULT 0,
  `version` int(11) NOT NULL,
  `created` int(11) NOT NULL DEFAULT 0
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

--
-- Dumping data for table `players`
--

INSERT INTO `players` (`id`, `name`, `group_id`, `account_id`, `level`, `vocation`, `health`, `healthmax`, `experience`, `lookbody`, `lookfeet`, `lookhead`, `looklegs`, `looktype`, `lookaddons`, `maglevel`, `mana`, `manamax`, `manaspent`, `soul`, `town_id`, `posx`, `posy`, `posz`, `conditions`, `cap`, `sex`, `lastlogin`, `lastip`, `save`, `skull`, `skulltime`, `lastlogout`, `blessings`, `blessings1`, `blessings2`, `blessings3`, `blessings4`, `blessings5`, `blessings6`, `blessings7`, `blessings8`, `onlinetime`, `deletion`, `balance`, `offlinetraining_time`, `offlinetraining_skill`, `stamina`, `skill_fist`, `skill_fist_tries`, `skill_club`, `skill_club_tries`, `skill_sword`, `skill_sword_tries`, `skill_axe`, `skill_axe_tries`, `skill_dist`, `skill_dist_tries`, `skill_shielding`, `skill_shielding_tries`, `skill_fishing`, `skill_fishing_tries`, `deleted`, `description`, `comment`, `create_ip`, `create_date`, `hidden`, `cast`, `skill_critical_hit_chance`, `skill_critical_hit_chance_tries`, `skill_critical_hit_damage`, `skill_critical_hit_damage_tries`, `skill_life_leech_chance`, `skill_life_leech_chance_tries`, `skill_life_leech_amount`, `skill_life_leech_amount_tries`, `skill_mana_leech_chance`, `skill_mana_leech_chance_tries`, `skill_mana_leech_amount`, `skill_mana_leech_amount_tries`, `skill_criticalhit_chance`, `skill_criticalhit_damage`, `skill_lifeleech_chance`, `skill_lifeleech_amount`, `skill_manaleech_chance`, `skill_manaleech_amount`, `prey_stamina_1`, `prey_stamina_2`, `prey_stamina_3`, `prey_column`, `bonus_reroll`, `xpboost_stamina`, `xpboost_value`, `marriage_status`, `hide_skills`, `hide_set`, `former`, `signature`, `marriage_spouse`, `loyalty_ranking`, `auction_balance`, `hide_char1`, `broadcasting`, `viewers`, `frags_all`, `direction`, `frags`, `lookmount`, `version`, `created`) VALUES
(2, 'Sorcerer Sample', 1, 1, 8, 1, 185, 185, 4200, 106, 95, 78, 116, 128, 0, 0, 40, 40, 0, 0, 2, 0, 0, 0, '', 470, 1, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 43200, -1, 2520, 10, 0, 10, 0, 10, 0, 10, 0, 10, 0, 10, 0, 10, 0, 0, '', '', 0, 1507158878, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, NULL, 1, 0, NULL, NULL, 0, NULL, NULL, '-', '', -1, 0, 0, 0, 0, 0, 0, 2, 0, 0, 0, 0),
(3, 'Druid Sample', 1, 1, 8, 2, 185, 185, 4200, 106, 95, 78, 116, 128, 0, 0, 40, 40, 0, 0, 2, 0, 0, 0, '', 470, 1, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 43200, -1, 2520, 10, 0, 10, 0, 10, 0, 10, 0, 10, 0, 10, 0, 10, 0, 0, '', '', 0, 1507158900, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, NULL, 1, 0, NULL, NULL, 0, NULL, NULL, '-', '', -1, 0, 0, 0, 0, 0, 0, 2, 0, 0, 0, 0),
(4, 'Paladin Sample', 1, 1, 8, 3, 185, 185, 4200, 106, 95, 78, 116, 128, 0, 0, 40, 40, 0, 0, 2, 0, 0, 0, '', 470, 1, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 43200, -1, 2520, 10, 0, 10, 0, 10, 0, 10, 0, 10, 0, 10, 0, 10, 0, 0, '', '', 0, 1507158919, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, NULL, 1, 0, NULL, NULL, 0, NULL, NULL, '-', '', -1, 0, 0, 0, 0, 0, 0, 2, 0, 0, 0, 0),
(5, 'Knight Sample', 1, 1, 8, 4, 185, 185, 4200, 106, 95, 78, 116, 128, 0, 0, 40, 40, 0, 0, 2, 0, 0, 0, '', 470, 1, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 43200, -1, 2520, 10, 0, 10, 0, 10, 0, 10, 0, 10, 0, 10, 0, 10, 0, 0, '', '', 0, 1507158938, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, NULL, 1, 0, NULL, NULL, 0, NULL, NULL, '-', '', -1, 0, 0, 0, 0, 0, 0, 2, 0, 0, 0, 0),
(6, 'ADM', 6, 2, 8, 4, 185, 185, 4200, 106, 95, 78, 116, 128, 0, 0, 40, 40, 0, 0, 2, 32369, 32240, 7, '', 470, 1, 1688080753, 16777343, 1, 0, 0, 1688080895, 127, 0, 0, 0, 0, 0, 0, 0, 0, 165, 0, 0, 43200, -1, 2520, 10, 0, 10, 0, 10, 0, 10, 0, 10, 0, 10, 0, 10, 0, 0, '', '', 0, 1507158938, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, NULL, 1, 0, NULL, NULL, 0, NULL, NULL, '-', '', -1, 0, 0, 0, 0, 0, 0, 2, 0, 0, 0, 0),
(7, 'Testerman', 1, 2, 8, 4, 185, 185, 4200, 106, 95, 78, 116, 128, 0, 0, 40, 40, 0, 0, 3, 0, 0, 0, '', 470, 1, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 43200, -1, 2520, 10, 0, 10, 0, 10, 0, 10, 0, 10, 0, 10, 0, 10, 0, 0, '', '', 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, NULL, 1, 0, NULL, NULL, 0, NULL, NULL, '-', '', -1, 0, 0, 0, 0, 0, 0, 2, 0, 0, 0, 1688080884);

-- --------------------------------------------------------

--
-- Table structure for table `players_online`
--

CREATE TABLE `players_online` (
  `player_id` int(11) NOT NULL
) ENGINE=MEMORY DEFAULT CHARSET=latin1;

-- --------------------------------------------------------

--
-- Table structure for table `player_deaths`
--

CREATE TABLE `player_deaths` (
  `player_id` int(11) NOT NULL,
  `time` bigint(20) UNSIGNED NOT NULL DEFAULT 0,
  `level` int(11) NOT NULL DEFAULT 1,
  `killed_by` varchar(255) NOT NULL,
  `is_player` tinyint(1) NOT NULL DEFAULT 1,
  `mostdamage_by` varchar(100) NOT NULL,
  `mostdamage_is_player` tinyint(1) NOT NULL DEFAULT 0,
  `unjustified` tinyint(1) NOT NULL DEFAULT 0,
  `mostdamage_unjustified` tinyint(1) NOT NULL DEFAULT 0
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

-- --------------------------------------------------------

--
-- Table structure for table `player_depotitems`
--

CREATE TABLE `player_depotitems` (
  `player_id` int(11) NOT NULL,
  `sid` int(11) NOT NULL COMMENT 'any given range eg 0-100 will be reserved for depot lockers and all > 100 will be then normal items inside depots',
  `pid` int(11) NOT NULL DEFAULT 0,
  `itemtype` int(11) NOT NULL,
  `count` smallint(5) NOT NULL DEFAULT 0,
  `attributes` blob NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

-- --------------------------------------------------------

--
-- Table structure for table `player_former_names`
--

CREATE TABLE `player_former_names` (
  `id` int(11) NOT NULL,
  `player_id` int(11) NOT NULL,
  `former_name` varchar(35) NOT NULL,
  `date` int(11) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

-- --------------------------------------------------------

--
-- Table structure for table `player_inboxitems`
--

CREATE TABLE `player_inboxitems` (
  `player_id` int(11) NOT NULL,
  `sid` int(11) NOT NULL,
  `pid` int(11) NOT NULL DEFAULT 0,
  `itemtype` int(11) NOT NULL,
  `count` smallint(5) NOT NULL DEFAULT 0,
  `attributes` blob NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

-- --------------------------------------------------------

--
-- Table structure for table `player_items`
--

CREATE TABLE `player_items` (
  `player_id` int(11) NOT NULL DEFAULT 0,
  `pid` int(11) NOT NULL DEFAULT 0,
  `sid` int(11) NOT NULL DEFAULT 0,
  `itemtype` int(11) NOT NULL DEFAULT 0,
  `count` int(11) NOT NULL DEFAULT 0,
  `attributes` blob NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

-- --------------------------------------------------------

--
-- Table structure for table `player_kills`
--

CREATE TABLE `player_kills` (
  `player_id` int(11) NOT NULL,
  `time` bigint(20) UNSIGNED NOT NULL DEFAULT 0,
  `target` int(11) NOT NULL,
  `unavenged` tinyint(1) NOT NULL DEFAULT 0
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

-- --------------------------------------------------------

--
-- Table structure for table `player_misc`
--

CREATE TABLE `player_misc` (
  `player_id` int(11) NOT NULL,
  `info` blob NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

-- --------------------------------------------------------

--
-- Table structure for table `player_namelocks`
--

CREATE TABLE `player_namelocks` (
  `player_id` int(11) NOT NULL,
  `reason` varchar(255) NOT NULL,
  `namelocked_at` bigint(20) NOT NULL,
  `namelocked_by` int(11) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

-- --------------------------------------------------------

--
-- Table structure for table `player_prey`
--

CREATE TABLE `player_prey` (
  `player_id` int(11) NOT NULL,
  `name` varchar(50) NOT NULL,
  `mindex` smallint(6) NOT NULL,
  `mcolumn` int(11) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

-- --------------------------------------------------------

--
-- Table structure for table `player_preytimes`
--

CREATE TABLE `player_preytimes` (
  `player_id` int(11) NOT NULL,
  `bonus_type1` int(11) NOT NULL,
  `bonus_value1` int(11) NOT NULL,
  `bonus_name1` varchar(50) NOT NULL,
  `bonus_type2` int(11) NOT NULL,
  `bonus_value2` int(11) NOT NULL,
  `bonus_name2` varchar(50) NOT NULL,
  `bonus_type3` int(11) NOT NULL,
  `bonus_value3` int(11) NOT NULL,
  `bonus_name3` varchar(50) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

-- --------------------------------------------------------

--
-- Table structure for table `player_rewardchest`
--

CREATE TABLE `player_rewardchest` (
  `id` int(11) NOT NULL,
  `player_id` int(11) NOT NULL,
  `reward` text NOT NULL,
  `date` bigint(20) UNSIGNED NOT NULL DEFAULT 0
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

-- --------------------------------------------------------

--
-- Table structure for table `player_rewards`
--

CREATE TABLE `player_rewards` (
  `player_id` int(11) NOT NULL,
  `sid` int(11) NOT NULL,
  `pid` int(11) NOT NULL DEFAULT 0,
  `itemtype` int(11) NOT NULL,
  `count` smallint(5) NOT NULL DEFAULT 0,
  `attributes` blob NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

-- --------------------------------------------------------

--
-- Table structure for table `player_spells`
--

CREATE TABLE `player_spells` (
  `player_id` int(11) NOT NULL,
  `name` varchar(255) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

-- --------------------------------------------------------

--
-- Table structure for table `player_storage`
--

CREATE TABLE `player_storage` (
  `player_id` int(11) NOT NULL DEFAULT 0,
  `key` int(10) UNSIGNED NOT NULL DEFAULT 0,
  `value` int(11) NOT NULL DEFAULT 0
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

-- --------------------------------------------------------

--
-- Table structure for table `sellchar`
--

CREATE TABLE `sellchar` (
  `id` int(11) NOT NULL,
  `name` varchar(40) NOT NULL,
  `vocation` int(11) NOT NULL,
  `price` int(11) NOT NULL,
  `status` varchar(40) NOT NULL,
  `oldid` varchar(40) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

-- --------------------------------------------------------

--
-- Table structure for table `server_config`
--

CREATE TABLE `server_config` (
  `config` varchar(50) NOT NULL,
  `value` varchar(256) NOT NULL DEFAULT '',
  `timestamp` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

--
-- Dumping data for table `server_config`
--

INSERT INTO `server_config` (`config`, `value`, `timestamp`) VALUES
('boost_monster', '0', '2023-06-29 23:00:11'),
('boost_monster_name', '', '2023-06-29 23:00:11'),
('boost_monster_url', 'http://localhost:8090/images/monsters/GazHaragoth.gif', '2023-06-29 23:00:11'),
('db_version', '24', '2023-06-29 23:00:11'),
('double', 'desactived', '2023-06-29 23:00:11'),
('motd_hash', '3fc17b037e7c363034b1405269abd3eb0f45ea64', '2023-06-29 23:00:11'),
('motd_num', '15', '2023-06-29 23:00:11'),
('players_record', '0', '2023-06-29 23:32:23');

-- --------------------------------------------------------

--
-- Table structure for table `shop_orders`
--

CREATE TABLE `shop_orders` (
  `id` int(11) NOT NULL,
  `account_id` int(11) NOT NULL,
  `type` int(11) NOT NULL,
  `itemid` int(11) NOT NULL,
  `count` int(11) NOT NULL,
  `time` int(11) NOT NULL DEFAULT 0
) ENGINE=MyISAM DEFAULT CHARSET=utf8;

-- --------------------------------------------------------

--
-- Table structure for table `store_history`
--

CREATE TABLE `store_history` (
  `account_id` int(11) NOT NULL,
  `mode` smallint(2) NOT NULL DEFAULT 0,
  `description` varchar(3500) NOT NULL,
  `coin_amount` int(12) NOT NULL,
  `time` bigint(20) UNSIGNED NOT NULL,
  `timestamp` int(11) NOT NULL DEFAULT 0,
  `id` int(11) NOT NULL,
  `coins` int(11) NOT NULL DEFAULT 0
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

-- --------------------------------------------------------

--
-- Table structure for table `s_attributes`
--

CREATE TABLE `s_attributes` (
  `item_id` int(11) NOT NULL,
  `attack` varchar(11) DEFAULT NULL,
  `armor` varchar(11) DEFAULT NULL,
  `defense` varchar(11) DEFAULT NULL,
  `extraDef` varchar(4) DEFAULT NULL,
  `range` varchar(11) DEFAULT NULL,
  `speed` varchar(4) DEFAULT NULL,
  `elementFire` varchar(11) DEFAULT NULL,
  `elementIce` varchar(11) DEFAULT NULL,
  `elementEarth` varchar(11) DEFAULT NULL,
  `elementEnergy` varchar(11) DEFAULT NULL,
  `skillShield` varchar(4) DEFAULT NULL,
  `skillDist` varchar(4) DEFAULT NULL,
  `skillFist` varchar(4) DEFAULT NULL,
  `skillClub` varchar(4) DEFAULT NULL,
  `skillAxe` varchar(4) DEFAULT NULL,
  `skillSword` varchar(4) DEFAULT NULL,
  `magicLevelPoints` varchar(4) DEFAULT NULL,
  `absorbPercentAll` varchar(3) DEFAULT NULL,
  `absorbPercentFire` varchar(3) DEFAULT NULL,
  `absorbPercentEarth` varchar(3) DEFAULT NULL,
  `absorbPercentEnergy` varchar(3) DEFAULT NULL,
  `absorbPercentIce` varchar(3) DEFAULT NULL,
  `absorbPercentDeath` varchar(3) DEFAULT NULL,
  `absorbPercentHoly` varchar(3) DEFAULT NULL,
  `absorbPercentPhysical` varchar(3) DEFAULT NULL,
  `absorbPercentManaDrain` varchar(3) DEFAULT NULL,
  `absorbPercentLifeDrain` varchar(3) DEFAULT NULL,
  `charges` varchar(11) DEFAULT NULL,
  `duration` varchar(11) DEFAULT NULL,
  `preventDrop` varchar(11) DEFAULT NULL,
  `containerSize` varchar(11) DEFAULT NULL,
  `hitChance` varchar(11) DEFAULT NULL,
  `shootType` varchar(12) DEFAULT NULL
) ENGINE=MyISAM DEFAULT CHARSET=latin1;

-- --------------------------------------------------------

--
-- Table structure for table `s_items`
--

CREATE TABLE `s_items` (
  `id` int(11) NOT NULL,
  `name` text NOT NULL,
  `descr` text DEFAULT NULL,
  `weight` int(11) NOT NULL,
  `itemid` int(11) NOT NULL
) ENGINE=MyISAM DEFAULT CHARSET=latin1;

-- --------------------------------------------------------

--
-- Table structure for table `tickets`
--

CREATE TABLE `tickets` (
  `ticket_id` int(11) NOT NULL,
  `ticket_subject` varchar(45) NOT NULL,
  `ticket_author` varchar(255) NOT NULL,
  `ticket_author_acc_id` int(11) NOT NULL,
  `ticket_last_reply` varchar(45) NOT NULL,
  `ticket_admin_reply` int(11) NOT NULL,
  `ticket_date` datetime NOT NULL,
  `ticket_ended` varchar(45) NOT NULL,
  `ticket_status` varchar(45) NOT NULL,
  `ticket_category` varchar(45) NOT NULL,
  `ticket_description` text NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8 ROW_FORMAT=COMPACT;

-- --------------------------------------------------------

--
-- Table structure for table `tickets_reply`
--

CREATE TABLE `tickets_reply` (
  `ticket_replyid` int(11) NOT NULL,
  `ticket_id` int(11) NOT NULL,
  `reply_author` varchar(255) DEFAULT NULL,
  `reply_message` text DEFAULT NULL,
  `reply_date` datetime DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- --------------------------------------------------------

--
-- Table structure for table `tile_store`
--

CREATE TABLE `tile_store` (
  `house_id` int(11) NOT NULL,
  `data` longblob NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

-- --------------------------------------------------------

--
-- Table structure for table `trade_off_container_items`
--

CREATE TABLE `trade_off_container_items` (
  `offer_id` int(11) NOT NULL,
  `item_id` int(11) DEFAULT NULL,
  `item_charges` int(11) DEFAULT NULL,
  `item_duration` int(11) DEFAULT NULL,
  `count` int(11) DEFAULT 1
) ENGINE=MyISAM DEFAULT CHARSET=latin1;

-- --------------------------------------------------------

--
-- Table structure for table `trade_off_offers`
--

CREATE TABLE `trade_off_offers` (
  `id` int(11) NOT NULL,
  `player_id` int(11) NOT NULL,
  `type` int(1) NOT NULL DEFAULT 0,
  `item_id` int(11) DEFAULT NULL,
  `item_count` int(11) NOT NULL DEFAULT 1,
  `item_charges` int(11) DEFAULT NULL,
  `item_duration` int(11) DEFAULT NULL,
  `item_name` varchar(255) DEFAULT NULL,
  `item_trade` tinyint(1) NOT NULL DEFAULT 0,
  `cost` bigint(20) UNSIGNED NOT NULL,
  `cost_count` int(11) NOT NULL DEFAULT 1,
  `date` bigint(20) DEFAULT NULL
) ENGINE=MyISAM DEFAULT CHARSET=latin1;

-- --------------------------------------------------------

--
-- Table structure for table `war_arena`
--

CREATE TABLE `war_arena` (
  `name` varchar(40) NOT NULL DEFAULT 'Default Arena Name',
  `inuse` int(11) NOT NULL DEFAULT 0,
  `type` int(11) NOT NULL DEFAULT 0,
  `guild1` int(11) DEFAULT NULL,
  `guild2` int(11) DEFAULT NULL,
  `start` bigint(15) NOT NULL,
  `end` bigint(15) NOT NULL,
  `team_a_posx` int(11) NOT NULL,
  `team_a_posy` int(11) NOT NULL,
  `team_a_posz` int(11) NOT NULL,
  `team_b_posx` int(11) NOT NULL,
  `team_b_posy` int(11) NOT NULL,
  `team_b_posz` int(11) NOT NULL,
  `maxplayers` int(11) DEFAULT NULL,
  `pending` int(11) NOT NULL,
  `duration` int(11) NOT NULL,
  `challenger` int(11) NOT NULL,
  `arena_team_a_pos` int(1) NOT NULL DEFAULT 0,
  `playersOnTeamA` int(1) DEFAULT 0,
  `playersOnTeamB` int(1) NOT NULL DEFAULT 0,
  `exaust_ssa` int(1) NOT NULL DEFAULT 0,
  `disablepotions` int(1) NOT NULL DEFAULT 0
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

-- --------------------------------------------------------

--
-- Table structure for table `z_featured_article`
--

CREATE TABLE `z_featured_article` (
  `id` int(11) NOT NULL,
  `title` varchar(50) NOT NULL,
  `text` varchar(255) NOT NULL,
  `date` varchar(30) NOT NULL,
  `author` varchar(50) NOT NULL,
  `read_more` varchar(100) NOT NULL
) ENGINE=MyISAM DEFAULT CHARSET=latin1;

-- --------------------------------------------------------

--
-- Table structure for table `z_forum`
--

CREATE TABLE `z_forum` (
  `id` int(11) NOT NULL,
  `first_post` int(11) NOT NULL DEFAULT 0,
  `last_post` int(11) NOT NULL DEFAULT 0,
  `section` int(3) NOT NULL DEFAULT 0,
  `replies` int(20) NOT NULL DEFAULT 0,
  `views` int(20) NOT NULL DEFAULT 0,
  `author_aid` int(20) NOT NULL DEFAULT 0,
  `author_guid` int(20) NOT NULL DEFAULT 0,
  `post_text` text NOT NULL,
  `post_topic` varchar(255) NOT NULL,
  `post_smile` tinyint(1) NOT NULL DEFAULT 0,
  `post_html` tinyint(1) NOT NULL DEFAULT 0,
  `post_date` int(20) NOT NULL DEFAULT 0,
  `last_edit_aid` int(20) NOT NULL DEFAULT 0,
  `edit_date` int(20) NOT NULL DEFAULT 0,
  `post_ip` varchar(15) NOT NULL DEFAULT '0.0.0.0',
  `icon_id` int(11) NOT NULL,
  `news_icon` varchar(50) NOT NULL,
  `sticked` tinyint(1) NOT NULL DEFAULT 0,
  `closed` tinyint(1) NOT NULL DEFAULT 0
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

-- --------------------------------------------------------

--
-- Table structure for table `z_network_box`
--

CREATE TABLE `z_network_box` (
  `id` int(11) NOT NULL,
  `network_name` varchar(10) NOT NULL,
  `network_link` varchar(50) NOT NULL
) ENGINE=MyISAM DEFAULT CHARSET=latin1;

-- --------------------------------------------------------

--
-- Table structure for table `z_news_tickers`
--

CREATE TABLE `z_news_tickers` (
  `date` int(11) NOT NULL DEFAULT 1,
  `author` int(11) NOT NULL,
  `image_id` int(3) NOT NULL DEFAULT 0,
  `text` text NOT NULL,
  `hide_ticker` tinyint(1) NOT NULL
) ENGINE=MyISAM DEFAULT CHARSET=latin1;

-- --------------------------------------------------------

--
-- Table structure for table `z_ots_comunication`
--

CREATE TABLE `z_ots_comunication` (
  `id` int(11) NOT NULL,
  `name` varchar(255) NOT NULL,
  `type` varchar(255) NOT NULL,
  `action` varchar(255) NOT NULL,
  `param1` varchar(255) NOT NULL,
  `param2` varchar(255) NOT NULL,
  `param3` varchar(255) NOT NULL,
  `param4` varchar(255) NOT NULL,
  `param5` varchar(255) NOT NULL,
  `param6` varchar(255) NOT NULL,
  `param7` varchar(255) NOT NULL,
  `delete_it` int(2) NOT NULL DEFAULT 1
) ENGINE=MyISAM DEFAULT CHARSET=latin1;

-- --------------------------------------------------------

--
-- Table structure for table `z_ots_guildcomunication`
--

CREATE TABLE `z_ots_guildcomunication` (
  `id` int(11) NOT NULL,
  `name` varchar(255) NOT NULL,
  `type` varchar(255) NOT NULL,
  `action` varchar(255) NOT NULL,
  `param1` varchar(255) NOT NULL,
  `param2` varchar(255) NOT NULL,
  `param3` varchar(255) NOT NULL,
  `param4` varchar(255) NOT NULL,
  `param5` varchar(255) NOT NULL,
  `param6` varchar(255) NOT NULL,
  `param7` varchar(255) NOT NULL,
  `delete_it` int(2) NOT NULL DEFAULT 1
) ENGINE=MyISAM DEFAULT CHARSET=latin1;

-- --------------------------------------------------------

--
-- Table structure for table `z_polls`
--

CREATE TABLE `z_polls` (
  `id` int(11) NOT NULL,
  `question` varchar(255) NOT NULL,
  `end` int(11) NOT NULL,
  `start` int(11) NOT NULL,
  `answers` int(11) NOT NULL,
  `votes_all` int(11) NOT NULL
) ENGINE=MyISAM DEFAULT CHARSET=latin1;

-- --------------------------------------------------------

--
-- Table structure for table `z_polls_answers`
--

CREATE TABLE `z_polls_answers` (
  `poll_id` int(11) NOT NULL,
  `answer_id` int(11) NOT NULL,
  `answer` varchar(255) NOT NULL,
  `votes` int(11) NOT NULL
) ENGINE=MyISAM DEFAULT CHARSET=latin1;

-- --------------------------------------------------------

--
-- Table structure for table `z_shopguild_history_item`
--

CREATE TABLE `z_shopguild_history_item` (
  `id` int(11) NOT NULL,
  `to_name` varchar(255) NOT NULL DEFAULT '0',
  `to_account` int(11) NOT NULL DEFAULT 0,
  `from_nick` varchar(255) NOT NULL,
  `from_account` int(11) NOT NULL DEFAULT 0,
  `price` int(11) NOT NULL DEFAULT 0,
  `offer_id` varchar(255) NOT NULL DEFAULT '',
  `offer_desc` varchar(255) DEFAULT NULL,
  `trans_state` varchar(255) NOT NULL,
  `trans_start` int(11) NOT NULL DEFAULT 0,
  `trans_real` int(11) NOT NULL DEFAULT 0
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

-- --------------------------------------------------------

--
-- Table structure for table `z_shopguild_history_pacc`
--

CREATE TABLE `z_shopguild_history_pacc` (
  `id` int(11) NOT NULL,
  `to_name` varchar(255) NOT NULL DEFAULT '0',
  `to_account` int(11) NOT NULL DEFAULT 0,
  `from_nick` varchar(255) NOT NULL,
  `from_account` int(11) NOT NULL DEFAULT 0,
  `price` int(11) NOT NULL DEFAULT 0,
  `pacc_days` int(11) NOT NULL DEFAULT 0,
  `trans_state` varchar(255) NOT NULL,
  `trans_start` int(11) NOT NULL DEFAULT 0,
  `trans_real` int(11) NOT NULL DEFAULT 0
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

-- --------------------------------------------------------

--
-- Table structure for table `z_shopguild_offer`
--

CREATE TABLE `z_shopguild_offer` (
  `id` int(11) NOT NULL,
  `points` int(11) NOT NULL DEFAULT 0,
  `itemid1` int(11) NOT NULL DEFAULT 0,
  `count1` int(11) NOT NULL DEFAULT 0,
  `itemid2` int(11) NOT NULL DEFAULT 0,
  `count2` int(11) NOT NULL DEFAULT 0,
  `offer_type` varchar(255) DEFAULT NULL,
  `offer_description` text NOT NULL,
  `offer_name` varchar(255) NOT NULL,
  `pid` int(11) NOT NULL DEFAULT 0,
  `looktype` int(3) NOT NULL DEFAULT 0
) ENGINE=MyISAM DEFAULT CHARSET=latin1;

-- --------------------------------------------------------

--
-- Table structure for table `z_shop_category`
--

CREATE TABLE `z_shop_category` (
  `id` int(11) NOT NULL,
  `name` varchar(50) NOT NULL,
  `desc` varchar(255) NOT NULL,
  `button` varchar(50) NOT NULL,
  `hide` int(11) NOT NULL DEFAULT 0
) ENGINE=MyISAM DEFAULT CHARSET=latin1;

-- --------------------------------------------------------

--
-- Table structure for table `z_shop_donates`
--

CREATE TABLE `z_shop_donates` (
  `id` int(11) NOT NULL,
  `date` bigint(20) NOT NULL,
  `reference` varchar(50) NOT NULL,
  `account_name` varchar(50) NOT NULL,
  `method` varchar(50) NOT NULL,
  `price` varchar(20) NOT NULL,
  `coins` int(11) NOT NULL,
  `status` varchar(20) NOT NULL
) ENGINE=MyISAM DEFAULT CHARSET=latin1;

-- --------------------------------------------------------

--
-- Table structure for table `z_shop_donate_confirm`
--

CREATE TABLE `z_shop_donate_confirm` (
  `id` int(11) NOT NULL,
  `date` int(11) NOT NULL,
  `account_name` varchar(50) NOT NULL,
  `donate_id` int(11) NOT NULL,
  `msg` text NOT NULL
) ENGINE=MyISAM DEFAULT CHARSET=latin1;

-- --------------------------------------------------------

--
-- Table structure for table `z_shop_history_item`
--

CREATE TABLE `z_shop_history_item` (
  `id` int(11) NOT NULL,
  `to_name` varchar(255) NOT NULL DEFAULT '0',
  `to_account` int(11) NOT NULL DEFAULT 0,
  `from_nick` varchar(255) NOT NULL,
  `from_account` int(11) NOT NULL DEFAULT 0,
  `price` int(11) NOT NULL DEFAULT 0,
  `offer_id` int(11) NOT NULL DEFAULT 0,
  `trans_state` varchar(255) NOT NULL,
  `trans_start` int(11) NOT NULL DEFAULT 0,
  `trans_real` int(11) NOT NULL DEFAULT 0
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

-- --------------------------------------------------------

--
-- Table structure for table `z_shop_history_pacc`
--

CREATE TABLE `z_shop_history_pacc` (
  `id` int(11) NOT NULL,
  `to_name` varchar(255) NOT NULL DEFAULT '0',
  `to_account` int(11) NOT NULL DEFAULT 0,
  `from_nick` varchar(255) NOT NULL,
  `from_account` int(11) NOT NULL DEFAULT 0,
  `price` int(11) NOT NULL DEFAULT 0,
  `pacc_days` int(11) NOT NULL DEFAULT 0,
  `trans_state` varchar(255) NOT NULL,
  `trans_start` int(11) NOT NULL DEFAULT 0,
  `trans_real` int(11) NOT NULL DEFAULT 0
) ENGINE=MyISAM DEFAULT CHARSET=latin1;

-- --------------------------------------------------------

--
-- Table structure for table `z_shop_offer`
--

CREATE TABLE `z_shop_offer` (
  `id` int(11) NOT NULL,
  `category` int(3) NOT NULL,
  `coins` int(11) NOT NULL DEFAULT 0,
  `price` varchar(50) NOT NULL,
  `itemid` int(11) NOT NULL DEFAULT 0,
  `mount_id` varchar(100) NOT NULL,
  `addon_name` varchar(100) NOT NULL,
  `count` int(11) NOT NULL DEFAULT 0,
  `offer_type` varchar(255) DEFAULT NULL,
  `offer_description` text NOT NULL,
  `offer_name` varchar(255) NOT NULL,
  `offer_date` int(11) NOT NULL,
  `default_image` varchar(50) NOT NULL,
  `hide` int(11) NOT NULL DEFAULT 0
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

-- --------------------------------------------------------

--
-- Table structure for table `z_shop_payment`
--

CREATE TABLE `z_shop_payment` (
  `id` int(11) NOT NULL,
  `ref` varchar(10) NOT NULL,
  `account_name` varchar(50) NOT NULL,
  `service_id` int(11) NOT NULL,
  `service_category_id` int(11) NOT NULL,
  `payment_method_id` int(11) NOT NULL,
  `price` varchar(50) NOT NULL,
  `coins` int(11) UNSIGNED NOT NULL,
  `status` varchar(50) NOT NULL DEFAULT 'waiting',
  `date` int(11) NOT NULL,
  `gift` int(11) NOT NULL DEFAULT 0
) ENGINE=MyISAM DEFAULT CHARSET=latin1;

--
-- Indexes for dumped tables
--

--
-- Indexes for table `accounts`
--
ALTER TABLE `accounts`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `name` (`name`),
  ADD UNIQUE KEY `name_2` (`name`),
  ADD UNIQUE KEY `name_3` (`name`);

--
-- Indexes for table `account_bans`
--
ALTER TABLE `account_bans`
  ADD PRIMARY KEY (`account_id`),
  ADD KEY `banned_by` (`banned_by`);

--
-- Indexes for table `account_ban_history`
--
ALTER TABLE `account_ban_history`
  ADD PRIMARY KEY (`id`),
  ADD KEY `account_id` (`account_id`),
  ADD KEY `banned_by` (`banned_by`),
  ADD KEY `account_id_2` (`account_id`),
  ADD KEY `account_id_3` (`account_id`),
  ADD KEY `account_id_4` (`account_id`),
  ADD KEY `account_id_5` (`account_id`);

--
-- Indexes for table `account_viplist`
--
ALTER TABLE `account_viplist`
  ADD UNIQUE KEY `account_player_index` (`account_id`,`player_id`),
  ADD KEY `account_id` (`account_id`),
  ADD KEY `player_id` (`player_id`);

--
-- Indexes for table `auction_system`
--
ALTER TABLE `auction_system`
  ADD PRIMARY KEY (`id`),
  ADD KEY `player_id` (`player_id`);

--
-- Indexes for table `bounty_hunter_system`
--
ALTER TABLE `bounty_hunter_system`
  ADD PRIMARY KEY (`id`);

--
-- Indexes for table `castle_info`
--
ALTER TABLE `castle_info`
  ADD PRIMARY KEY (`id`),
  ADD KEY `guild_id` (`guild_id`);

--
-- Indexes for table `global_storage`
--
ALTER TABLE `global_storage`
  ADD UNIQUE KEY `key` (`key`);

--
-- Indexes for table `guilds`
--
ALTER TABLE `guilds`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `name` (`name`),
  ADD UNIQUE KEY `ownerid` (`ownerid`);

--
-- Indexes for table `guildwar_arenas`
--
ALTER TABLE `guildwar_arenas`
  ADD PRIMARY KEY (`name`),
  ADD UNIQUE KEY `name` (`name`);

--
-- Indexes for table `guildwar_kills`
--
ALTER TABLE `guildwar_kills`
  ADD PRIMARY KEY (`id`),
  ADD KEY `warid` (`warid`);

--
-- Indexes for table `guild_invites`
--
ALTER TABLE `guild_invites`
  ADD PRIMARY KEY (`player_id`,`guild_id`),
  ADD KEY `guild_id` (`guild_id`);

--
-- Indexes for table `guild_kills`
--
ALTER TABLE `guild_kills`
  ADD PRIMARY KEY (`id`);

--
-- Indexes for table `guild_membership`
--
ALTER TABLE `guild_membership`
  ADD PRIMARY KEY (`player_id`),
  ADD KEY `guild_id` (`guild_id`),
  ADD KEY `rank_id` (`rank_id`);

--
-- Indexes for table `guild_ranks`
--
ALTER TABLE `guild_ranks`
  ADD PRIMARY KEY (`id`),
  ADD KEY `guild_id` (`guild_id`);

--
-- Indexes for table `guild_wars`
--
ALTER TABLE `guild_wars`
  ADD PRIMARY KEY (`id`),
  ADD KEY `guild1` (`guild1`),
  ADD KEY `guild2` (`guild2`);

--
-- Indexes for table `houses`
--
ALTER TABLE `houses`
  ADD PRIMARY KEY (`id`),
  ADD KEY `owner` (`owner`),
  ADD KEY `town_id` (`town_id`);

--
-- Indexes for table `house_lists`
--
ALTER TABLE `house_lists`
  ADD KEY `house_id` (`house_id`);

--
-- Indexes for table `ip_bans`
--
ALTER TABLE `ip_bans`
  ADD PRIMARY KEY (`ip`),
  ADD KEY `banned_by` (`banned_by`);

--
-- Indexes for table `live_casts`
--
ALTER TABLE `live_casts`
  ADD UNIQUE KEY `player_id_2` (`player_id`);

--
-- Indexes for table `market_history`
--
ALTER TABLE `market_history`
  ADD PRIMARY KEY (`id`),
  ADD KEY `player_id` (`player_id`,`sale`);

--
-- Indexes for table `market_offers`
--
ALTER TABLE `market_offers`
  ADD PRIMARY KEY (`id`),
  ADD KEY `sale` (`sale`,`itemtype`),
  ADD KEY `created` (`created`),
  ADD KEY `player_id` (`player_id`);

--
-- Indexes for table `myaac_account_actions`
--
ALTER TABLE `myaac_account_actions`
  ADD KEY `account_id` (`account_id`);

--
-- Indexes for table `myaac_admin_menu`
--
ALTER TABLE `myaac_admin_menu`
  ADD PRIMARY KEY (`id`);

--
-- Indexes for table `myaac_bugtracker`
--
ALTER TABLE `myaac_bugtracker`
  ADD PRIMARY KEY (`uid`);

--
-- Indexes for table `myaac_changelog`
--
ALTER TABLE `myaac_changelog`
  ADD PRIMARY KEY (`id`);

--
-- Indexes for table `myaac_charbazaar`
--
ALTER TABLE `myaac_charbazaar`
  ADD PRIMARY KEY (`id`);

--
-- Indexes for table `myaac_charbazaar_bid`
--
ALTER TABLE `myaac_charbazaar_bid`
  ADD PRIMARY KEY (`id`);

--
-- Indexes for table `myaac_config`
--
ALTER TABLE `myaac_config`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `name` (`name`);

--
-- Indexes for table `myaac_faq`
--
ALTER TABLE `myaac_faq`
  ADD PRIMARY KEY (`id`);

--
-- Indexes for table `myaac_forum`
--
ALTER TABLE `myaac_forum`
  ADD PRIMARY KEY (`id`),
  ADD KEY `section` (`section`);

--
-- Indexes for table `myaac_forum_boards`
--
ALTER TABLE `myaac_forum_boards`
  ADD PRIMARY KEY (`id`);

--
-- Indexes for table `myaac_gallery`
--
ALTER TABLE `myaac_gallery`
  ADD PRIMARY KEY (`id`);

--
-- Indexes for table `myaac_menu`
--
ALTER TABLE `myaac_menu`
  ADD PRIMARY KEY (`id`);

--
-- Indexes for table `myaac_monsters`
--
ALTER TABLE `myaac_monsters`
  ADD PRIMARY KEY (`id`);

--
-- Indexes for table `myaac_news`
--
ALTER TABLE `myaac_news`
  ADD PRIMARY KEY (`id`);

--
-- Indexes for table `myaac_news_categories`
--
ALTER TABLE `myaac_news_categories`
  ADD PRIMARY KEY (`id`);

--
-- Indexes for table `myaac_notepad`
--
ALTER TABLE `myaac_notepad`
  ADD PRIMARY KEY (`id`);

--
-- Indexes for table `myaac_pages`
--
ALTER TABLE `myaac_pages`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `name` (`name`);

--
-- Indexes for table `myaac_polls`
--
ALTER TABLE `myaac_polls`
  ADD PRIMARY KEY (`id`);

--
-- Indexes for table `myaac_spells`
--
ALTER TABLE `myaac_spells`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `name` (`name`);

--
-- Indexes for table `myaac_videos`
--
ALTER TABLE `myaac_videos`
  ADD PRIMARY KEY (`id`);

--
-- Indexes for table `myaac_visitors`
--
ALTER TABLE `myaac_visitors`
  ADD UNIQUE KEY `ip` (`ip`);

--
-- Indexes for table `myaac_weapons`
--
ALTER TABLE `myaac_weapons`
  ADD PRIMARY KEY (`id`);

--
-- Indexes for table `newsticker`
--
ALTER TABLE `newsticker`
  ADD PRIMARY KEY (`id`);

--
-- Indexes for table `pagsegurotransacoes`
--
ALTER TABLE `pagsegurotransacoes`
  ADD UNIQUE KEY `TransacaoID` (`TransacaoID`,`StatusTransacao`),
  ADD KEY `Referencia` (`Referencia`),
  ADD KEY `status` (`status`);

--
-- Indexes for table `pagseguro_transactions`
--
ALTER TABLE `pagseguro_transactions`
  ADD UNIQUE KEY `transaction_code` (`transaction_code`,`status`),
  ADD KEY `name` (`name`),
  ADD KEY `status` (`status`);

--
-- Indexes for table `players`
--
ALTER TABLE `players`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `name` (`name`),
  ADD KEY `account_id` (`account_id`),
  ADD KEY `vocation` (`vocation`);

--
-- Indexes for table `players_online`
--
ALTER TABLE `players_online`
  ADD PRIMARY KEY (`player_id`);

--
-- Indexes for table `player_depotitems`
--
ALTER TABLE `player_depotitems`
  ADD UNIQUE KEY `player_id_2` (`player_id`,`sid`);

--
-- Indexes for table `player_former_names`
--
ALTER TABLE `player_former_names`
  ADD PRIMARY KEY (`id`),
  ADD KEY `player_id` (`player_id`);

--
-- Indexes for table `player_inboxitems`
--
ALTER TABLE `player_inboxitems`
  ADD UNIQUE KEY `player_id_2` (`player_id`,`sid`);

--
-- Indexes for table `player_items`
--
ALTER TABLE `player_items`
  ADD KEY `player_id` (`player_id`),
  ADD KEY `sid` (`sid`);

--
-- Indexes for table `player_namelocks`
--
ALTER TABLE `player_namelocks`
  ADD PRIMARY KEY (`player_id`),
  ADD KEY `namelocked_by` (`namelocked_by`);

--
-- Indexes for table `player_rewardchest`
--
ALTER TABLE `player_rewardchest`
  ADD PRIMARY KEY (`id`),
  ADD KEY `player_id` (`player_id`);

--
-- Indexes for table `player_rewards`
--
ALTER TABLE `player_rewards`
  ADD UNIQUE KEY `player_id_2` (`player_id`,`sid`);

--
-- Indexes for table `player_spells`
--
ALTER TABLE `player_spells`
  ADD KEY `player_id` (`player_id`);

--
-- Indexes for table `player_storage`
--
ALTER TABLE `player_storage`
  ADD PRIMARY KEY (`player_id`,`key`);

--
-- Indexes for table `sellchar`
--
ALTER TABLE `sellchar`
  ADD PRIMARY KEY (`id`);

--
-- Indexes for table `server_config`
--
ALTER TABLE `server_config`
  ADD PRIMARY KEY (`config`);

--
-- Indexes for table `store_history`
--
ALTER TABLE `store_history`
  ADD KEY `account_id` (`account_id`);

--
-- Indexes for table `s_attributes`
--
ALTER TABLE `s_attributes`
  ADD PRIMARY KEY (`item_id`);

--
-- Indexes for table `s_items`
--
ALTER TABLE `s_items`
  ADD PRIMARY KEY (`id`);

--
-- Indexes for table `tile_store`
--
ALTER TABLE `tile_store`
  ADD KEY `house_id` (`house_id`);

--
-- Indexes for table `trade_off_container_items`
--
ALTER TABLE `trade_off_container_items`
  ADD KEY `offer_id` (`offer_id`);

--
-- Indexes for table `trade_off_offers`
--
ALTER TABLE `trade_off_offers`
  ADD PRIMARY KEY (`id`);

--
-- Indexes for table `war_arena`
--
ALTER TABLE `war_arena`
  ADD PRIMARY KEY (`name`),
  ADD UNIQUE KEY `name` (`name`);

--
-- Indexes for table `z_featured_article`
--
ALTER TABLE `z_featured_article`
  ADD PRIMARY KEY (`id`);

--
-- Indexes for table `z_forum`
--
ALTER TABLE `z_forum`
  ADD PRIMARY KEY (`id`),
  ADD KEY `section` (`section`);

--
-- Indexes for table `z_ots_comunication`
--
ALTER TABLE `z_ots_comunication`
  ADD PRIMARY KEY (`id`);

--
-- Indexes for table `z_ots_guildcomunication`
--
ALTER TABLE `z_ots_guildcomunication`
  ADD PRIMARY KEY (`id`);

--
-- Indexes for table `z_shopguild_history_item`
--
ALTER TABLE `z_shopguild_history_item`
  ADD PRIMARY KEY (`id`);

--
-- Indexes for table `z_shopguild_history_pacc`
--
ALTER TABLE `z_shopguild_history_pacc`
  ADD PRIMARY KEY (`id`);

--
-- Indexes for table `z_shopguild_offer`
--
ALTER TABLE `z_shopguild_offer`
  ADD PRIMARY KEY (`id`);

--
-- Indexes for table `z_shop_category`
--
ALTER TABLE `z_shop_category`
  ADD PRIMARY KEY (`id`);

--
-- Indexes for table `z_shop_donates`
--
ALTER TABLE `z_shop_donates`
  ADD PRIMARY KEY (`id`);

--
-- Indexes for table `z_shop_donate_confirm`
--
ALTER TABLE `z_shop_donate_confirm`
  ADD PRIMARY KEY (`id`);

--
-- Indexes for table `z_shop_history_item`
--
ALTER TABLE `z_shop_history_item`
  ADD PRIMARY KEY (`id`);

--
-- Indexes for table `z_shop_history_pacc`
--
ALTER TABLE `z_shop_history_pacc`
  ADD PRIMARY KEY (`id`);

--
-- Indexes for table `z_shop_offer`
--
ALTER TABLE `z_shop_offer`
  ADD PRIMARY KEY (`id`);

--
-- Indexes for table `z_shop_payment`
--
ALTER TABLE `z_shop_payment`
  ADD PRIMARY KEY (`id`);

--
-- AUTO_INCREMENT for dumped tables
--

--
-- AUTO_INCREMENT for table `accounts`
--
ALTER TABLE `accounts`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=59;

--
-- AUTO_INCREMENT for table `account_ban_history`
--
ALTER TABLE `account_ban_history`
  MODIFY `id` int(10) UNSIGNED NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `auction_system`
--
ALTER TABLE `auction_system`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=62;

--
-- AUTO_INCREMENT for table `bounty_hunter_system`
--
ALTER TABLE `bounty_hunter_system`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `castle_info`
--
ALTER TABLE `castle_info`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `guilds`
--
ALTER TABLE `guilds`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=9;

--
-- AUTO_INCREMENT for table `guildwar_kills`
--
ALTER TABLE `guildwar_kills`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=3;

--
-- AUTO_INCREMENT for table `guild_kills`
--
ALTER TABLE `guild_kills`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `guild_ranks`
--
ALTER TABLE `guild_ranks`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=25;

--
-- AUTO_INCREMENT for table `guild_wars`
--
ALTER TABLE `guild_wars`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=8;

--
-- AUTO_INCREMENT for table `houses`
--
ALTER TABLE `houses`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=3660;

--
-- AUTO_INCREMENT for table `market_history`
--
ALTER TABLE `market_history`
  MODIFY `id` int(10) UNSIGNED NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `market_offers`
--
ALTER TABLE `market_offers`
  MODIFY `id` int(10) UNSIGNED NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `myaac_admin_menu`
--
ALTER TABLE `myaac_admin_menu`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `myaac_bugtracker`
--
ALTER TABLE `myaac_bugtracker`
  MODIFY `uid` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `myaac_changelog`
--
ALTER TABLE `myaac_changelog`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=2;

--
-- AUTO_INCREMENT for table `myaac_charbazaar`
--
ALTER TABLE `myaac_charbazaar`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `myaac_charbazaar_bid`
--
ALTER TABLE `myaac_charbazaar_bid`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `myaac_config`
--
ALTER TABLE `myaac_config`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=18;

--
-- AUTO_INCREMENT for table `myaac_faq`
--
ALTER TABLE `myaac_faq`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `myaac_forum`
--
ALTER TABLE `myaac_forum`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `myaac_forum_boards`
--
ALTER TABLE `myaac_forum_boards`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=6;

--
-- AUTO_INCREMENT for table `myaac_gallery`
--
ALTER TABLE `myaac_gallery`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=2;

--
-- AUTO_INCREMENT for table `myaac_menu`
--
ALTER TABLE `myaac_menu`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=34;

--
-- AUTO_INCREMENT for table `myaac_monsters`
--
ALTER TABLE `myaac_monsters`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `myaac_news`
--
ALTER TABLE `myaac_news`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=3;

--
-- AUTO_INCREMENT for table `myaac_news_categories`
--
ALTER TABLE `myaac_news_categories`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=6;

--
-- AUTO_INCREMENT for table `myaac_notepad`
--
ALTER TABLE `myaac_notepad`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `myaac_pages`
--
ALTER TABLE `myaac_pages`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=4;

--
-- AUTO_INCREMENT for table `myaac_spells`
--
ALTER TABLE `myaac_spells`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `myaac_videos`
--
ALTER TABLE `myaac_videos`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `newsticker`
--
ALTER TABLE `newsticker`
  MODIFY `id` int(10) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=11;

--
-- AUTO_INCREMENT for table `players`
--
ALTER TABLE `players`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=8;

--
-- AUTO_INCREMENT for table `player_former_names`
--
ALTER TABLE `player_former_names`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `player_rewardchest`
--
ALTER TABLE `player_rewardchest`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `sellchar`
--
ALTER TABLE `sellchar`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `s_items`
--
ALTER TABLE `s_items`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `trade_off_offers`
--
ALTER TABLE `trade_off_offers`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `z_featured_article`
--
ALTER TABLE `z_featured_article`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `z_forum`
--
ALTER TABLE `z_forum`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `z_ots_comunication`
--
ALTER TABLE `z_ots_comunication`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=320;

--
-- AUTO_INCREMENT for table `z_ots_guildcomunication`
--
ALTER TABLE `z_ots_guildcomunication`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=13382;

--
-- AUTO_INCREMENT for table `z_shopguild_history_item`
--
ALTER TABLE `z_shopguild_history_item`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `z_shopguild_history_pacc`
--
ALTER TABLE `z_shopguild_history_pacc`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `z_shopguild_offer`
--
ALTER TABLE `z_shopguild_offer`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `z_shop_category`
--
ALTER TABLE `z_shop_category`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `z_shop_donates`
--
ALTER TABLE `z_shop_donates`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `z_shop_donate_confirm`
--
ALTER TABLE `z_shop_donate_confirm`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `z_shop_history_item`
--
ALTER TABLE `z_shop_history_item`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `z_shop_history_pacc`
--
ALTER TABLE `z_shop_history_pacc`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `z_shop_offer`
--
ALTER TABLE `z_shop_offer`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `z_shop_payment`
--
ALTER TABLE `z_shop_payment`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT;

--
-- Constraints for dumped tables
--

--
-- Constraints for table `account_bans`
--
ALTER TABLE `account_bans`
  ADD CONSTRAINT `account_bans_ibfk_1` FOREIGN KEY (`account_id`) REFERENCES `accounts` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  ADD CONSTRAINT `account_bans_ibfk_2` FOREIGN KEY (`banned_by`) REFERENCES `players` (`id`) ON DELETE CASCADE ON UPDATE CASCADE;

--
-- Constraints for table `account_ban_history`
--
ALTER TABLE `account_ban_history`
  ADD CONSTRAINT `account_ban_history_ibfk_2` FOREIGN KEY (`banned_by`) REFERENCES `players` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  ADD CONSTRAINT `account_ban_history_ibfk_3` FOREIGN KEY (`account_id`) REFERENCES `accounts` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  ADD CONSTRAINT `account_ban_history_ibfk_4` FOREIGN KEY (`account_id`) REFERENCES `accounts` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  ADD CONSTRAINT `account_ban_history_ibfk_5` FOREIGN KEY (`account_id`) REFERENCES `accounts` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  ADD CONSTRAINT `account_ban_history_ibfk_6` FOREIGN KEY (`account_id`) REFERENCES `accounts` (`id`) ON DELETE CASCADE ON UPDATE CASCADE;

--
-- Constraints for table `account_viplist`
--
ALTER TABLE `account_viplist`
  ADD CONSTRAINT `account_viplist_ibfk_1` FOREIGN KEY (`account_id`) REFERENCES `accounts` (`id`) ON DELETE CASCADE,
  ADD CONSTRAINT `account_viplist_ibfk_2` FOREIGN KEY (`player_id`) REFERENCES `players` (`id`) ON DELETE CASCADE;

--
-- Constraints for table `auction_system`
--
ALTER TABLE `auction_system`
  ADD CONSTRAINT `auction_system_ibfk_1` FOREIGN KEY (`player_id`) REFERENCES `players` (`id`) ON DELETE CASCADE;

--
-- Constraints for table `guilds`
--
ALTER TABLE `guilds`
  ADD CONSTRAINT `guilds_ibfk_1` FOREIGN KEY (`ownerid`) REFERENCES `players` (`id`) ON DELETE CASCADE;

--
-- Constraints for table `guildwar_kills`
--
ALTER TABLE `guildwar_kills`
  ADD CONSTRAINT `guildwar_kills_ibfk_1` FOREIGN KEY (`warid`) REFERENCES `guild_wars` (`id`) ON DELETE CASCADE;

--
-- Constraints for table `guild_invites`
--
ALTER TABLE `guild_invites`
  ADD CONSTRAINT `guild_invites_ibfk_1` FOREIGN KEY (`player_id`) REFERENCES `players` (`id`) ON DELETE CASCADE,
  ADD CONSTRAINT `guild_invites_ibfk_2` FOREIGN KEY (`guild_id`) REFERENCES `guilds` (`id`) ON DELETE CASCADE;

--
-- Constraints for table `guild_membership`
--
ALTER TABLE `guild_membership`
  ADD CONSTRAINT `guild_membership_ibfk_1` FOREIGN KEY (`player_id`) REFERENCES `players` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  ADD CONSTRAINT `guild_membership_ibfk_2` FOREIGN KEY (`guild_id`) REFERENCES `guilds` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  ADD CONSTRAINT `guild_membership_ibfk_3` FOREIGN KEY (`rank_id`) REFERENCES `guild_ranks` (`id`) ON DELETE CASCADE ON UPDATE CASCADE;

--
-- Constraints for table `guild_ranks`
--
ALTER TABLE `guild_ranks`
  ADD CONSTRAINT `guild_ranks_ibfk_1` FOREIGN KEY (`guild_id`) REFERENCES `guilds` (`id`) ON DELETE CASCADE;

--
-- Constraints for table `house_lists`
--
ALTER TABLE `house_lists`
  ADD CONSTRAINT `house_lists_ibfk_1` FOREIGN KEY (`house_id`) REFERENCES `houses` (`id`) ON DELETE CASCADE;

--
-- Constraints for table `ip_bans`
--
ALTER TABLE `ip_bans`
  ADD CONSTRAINT `ip_bans_ibfk_1` FOREIGN KEY (`banned_by`) REFERENCES `players` (`id`) ON DELETE CASCADE ON UPDATE CASCADE;

--
-- Constraints for table `live_casts`
--
ALTER TABLE `live_casts`
  ADD CONSTRAINT `live_casts_ibfk_1` FOREIGN KEY (`player_id`) REFERENCES `players` (`id`) ON DELETE CASCADE;

--
-- Constraints for table `market_history`
--
ALTER TABLE `market_history`
  ADD CONSTRAINT `market_history_ibfk_1` FOREIGN KEY (`player_id`) REFERENCES `players` (`id`) ON DELETE CASCADE;

--
-- Constraints for table `market_offers`
--
ALTER TABLE `market_offers`
  ADD CONSTRAINT `market_offers_ibfk_1` FOREIGN KEY (`player_id`) REFERENCES `players` (`id`) ON DELETE CASCADE;

--
-- Constraints for table `players`
--
ALTER TABLE `players`
  ADD CONSTRAINT `players_ibfk_1` FOREIGN KEY (`account_id`) REFERENCES `accounts` (`id`) ON DELETE CASCADE;

--
-- Constraints for table `player_depotitems`
--
ALTER TABLE `player_depotitems`
  ADD CONSTRAINT `player_depotitems_ibfk_1` FOREIGN KEY (`player_id`) REFERENCES `players` (`id`) ON DELETE CASCADE;

--
-- Constraints for table `player_inboxitems`
--
ALTER TABLE `player_inboxitems`
  ADD CONSTRAINT `player_inboxitems_ibfk_1` FOREIGN KEY (`player_id`) REFERENCES `players` (`id`) ON DELETE CASCADE;

--
-- Constraints for table `player_items`
--
ALTER TABLE `player_items`
  ADD CONSTRAINT `player_items_ibfk_1` FOREIGN KEY (`player_id`) REFERENCES `players` (`id`) ON DELETE CASCADE;

--
-- Constraints for table `player_namelocks`
--
ALTER TABLE `player_namelocks`
  ADD CONSTRAINT `player_namelocks_ibfk_1` FOREIGN KEY (`player_id`) REFERENCES `players` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  ADD CONSTRAINT `player_namelocks_ibfk_2` FOREIGN KEY (`namelocked_by`) REFERENCES `players` (`id`) ON DELETE CASCADE ON UPDATE CASCADE;

--
-- Constraints for table `player_rewardchest`
--
ALTER TABLE `player_rewardchest`
  ADD CONSTRAINT `player_rewardchest_ibfk_1` FOREIGN KEY (`player_id`) REFERENCES `players` (`id`) ON DELETE CASCADE ON UPDATE CASCADE;

--
-- Constraints for table `player_rewards`
--
ALTER TABLE `player_rewards`
  ADD CONSTRAINT `player_rewards_ibfk_1` FOREIGN KEY (`player_id`) REFERENCES `players` (`id`) ON DELETE CASCADE;

--
-- Constraints for table `player_spells`
--
ALTER TABLE `player_spells`
  ADD CONSTRAINT `player_spells_ibfk_1` FOREIGN KEY (`player_id`) REFERENCES `players` (`id`) ON DELETE CASCADE;

--
-- Constraints for table `player_storage`
--
ALTER TABLE `player_storage`
  ADD CONSTRAINT `player_storage_ibfk_1` FOREIGN KEY (`player_id`) REFERENCES `players` (`id`) ON DELETE CASCADE;

--
-- Constraints for table `store_history`
--
ALTER TABLE `store_history`
  ADD CONSTRAINT `store_history_ibfk_1` FOREIGN KEY (`account_id`) REFERENCES `accounts` (`id`) ON DELETE CASCADE;

--
-- Constraints for table `tile_store`
--
ALTER TABLE `tile_store`
  ADD CONSTRAINT `tile_store_ibfk_1` FOREIGN KEY (`house_id`) REFERENCES `houses` (`id`) ON DELETE CASCADE;
COMMIT;

/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
