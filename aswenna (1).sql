-- phpMyAdmin SQL Dump
-- version 5.2.1
-- https://www.phpmyadmin.net/
--
-- Host: 127.0.0.1
-- Generation Time: Jul 01, 2026 at 07:18 AM
-- Server version: 10.4.32-MariaDB
-- PHP Version: 8.2.12

SET SQL_MODE = "NO_AUTO_VALUE_ON_ZERO";
START TRANSACTION;
SET time_zone = "+00:00";


/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!40101 SET NAMES utf8mb4 */;

--
-- Database: `aswenna`
--

-- --------------------------------------------------------

--
-- Table structure for table `buyer_farmer_reviews`
--

CREATE TABLE `buyer_farmer_reviews` (
  `id` bigint(20) UNSIGNED NOT NULL,
  `buyer_id` bigint(20) UNSIGNED NOT NULL,
  `farmer_id` bigint(20) UNSIGNED NOT NULL,
  `confirmed_bid_id` bigint(20) UNSIGNED NOT NULL,
  `feedback` text NOT NULL,
  `ratings` tinyint(3) UNSIGNED NOT NULL,
  `reviewed_by` bigint(20) UNSIGNED NOT NULL,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `buyer_farmer_reviews`
--

INSERT INTO `buyer_farmer_reviews` (`id`, `buyer_id`, `farmer_id`, `confirmed_bid_id`, `feedback`, `ratings`, `reviewed_by`, `created_at`, `updated_at`) VALUES
(1, 3, 2, 1, 'Red potatoes were exceptional, perfectly cleaned and weighed. Recommended seller!', 5, 3, '2026-06-14 10:57:29', '2026-06-14 10:57:29');

-- --------------------------------------------------------

--
-- Table structure for table `cache`
--

CREATE TABLE `cache` (
  `key` varchar(255) NOT NULL,
  `value` mediumtext NOT NULL,
  `expiration` int(11) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `cache`
--

INSERT INTO `cache` (`key`, `value`, `expiration`) VALUES
('aswenna-marketplace-cache-356a192b7913b04c54574d18c28d46e6395428ab', 'i:1;', 1782719316),
('aswenna-marketplace-cache-356a192b7913b04c54574d18c28d46e6395428ab:timer', 'i:1782719316;', 1782719316),
('aswenna-marketplace-cache-otp_rookantha@gmail.com', 'i:526550;', 1782831591);

-- --------------------------------------------------------

--
-- Table structure for table `cache_locks`
--

CREATE TABLE `cache_locks` (
  `key` varchar(255) NOT NULL,
  `owner` varchar(255) NOT NULL,
  `expiration` int(11) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `chatbot_sessions`
--

CREATE TABLE `chatbot_sessions` (
  `id` bigint(20) UNSIGNED NOT NULL,
  `user_id` bigint(20) UNSIGNED DEFAULT NULL,
  `session_id` varchar(255) NOT NULL,
  `message` longtext DEFAULT NULL,
  `image_path` varchar(255) DEFAULT NULL,
  `response` longtext DEFAULT NULL,
  `role` enum('user','assistant') NOT NULL,
  `metadata` longtext CHARACTER SET utf8mb4 COLLATE utf8mb4_bin DEFAULT NULL CHECK (json_valid(`metadata`)),
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `chatbot_sessions`
--

INSERT INTO `chatbot_sessions` (`id`, `user_id`, `session_id`, `message`, `image_path`, `response`, `role`, `metadata`, `created_at`, `updated_at`) VALUES
(1, 2, 'SES-3BlBTBm8jp', 'How can I prevent potato late blight?', NULL, 'To prevent late blight, use certified seed tubers, avoid overhead irrigation, and apply organic neem oil.', 'user', NULL, '2026-06-14 10:57:29', '2026-06-14 10:57:29'),
(2, 7, '1aX6ThetPEKg', 'hi', NULL, NULL, 'user', NULL, '2026-06-20 05:30:12', '2026-06-20 05:30:12'),
(3, 7, '1aX6ThetPEKg', NULL, NULL, 'I\'m having trouble connecting to my agricultural knowledge base right now. Please verify your connection or try again shortly!', 'assistant', NULL, '2026-06-20 05:30:14', '2026-06-20 05:30:14'),
(4, 7, '1aX6ThetPEKg', 'this is good', NULL, NULL, 'user', NULL, '2026-06-20 05:40:39', '2026-06-20 05:40:39'),
(5, 7, '1aX6ThetPEKg', NULL, NULL, 'I\'m having trouble connecting to my agricultural knowledge base right now. Please verify your connection or try again shortly!', 'assistant', NULL, '2026-06-20 05:40:41', '2026-06-20 05:40:41'),
(6, 7, '1aX6ThetPEKg', 'this harvest is good grade?', 'chatbot/8ZwqrW5j72aVMu1HboKSbA6EQG9qgOdrAYWzHfTw.jpg', NULL, 'user', NULL, '2026-06-20 05:50:34', '2026-06-20 05:50:34'),
(7, 7, '1aX6ThetPEKg', NULL, NULL, '### Agricultural Advisory Services\n\nThank you for your question. While I don\'t have a specific guide for this exact question in my localized database, here are general agricultural recommendations:\n\n- Ensure proper soil testing before applying fertilizers.\n- Maintain consistent watering schedules tailored to your crop\'s current stage of growth.\n- Regularly monitor leaves for early symptoms of fungal diseases or pest infestations.\n\nFeel free to ask more specific questions about **rice cultivation**, **soil quality**, **pest control**, or **market prices**!', 'assistant', NULL, '2026-06-20 05:50:34', '2026-06-20 05:50:34');

-- --------------------------------------------------------

--
-- Table structure for table `chats`
--

CREATE TABLE `chats` (
  `id` bigint(20) UNSIGNED NOT NULL,
  `sender_id` bigint(20) UNSIGNED NOT NULL,
  `receiver_id` bigint(20) UNSIGNED NOT NULL,
  `type` enum('text','image','video','voice','file') NOT NULL DEFAULT 'text',
  `message_text` text DEFAULT NULL,
  `media_path` varchar(255) DEFAULT NULL,
  `sent_at` timestamp NOT NULL DEFAULT current_timestamp(),
  `is_read` tinyint(1) NOT NULL DEFAULT 0,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `chats`
--

INSERT INTO `chats` (`id`, `sender_id`, `receiver_id`, `type`, `message_text`, `media_path`, `sent_at`, `is_read`, `created_at`, `updated_at`) VALUES
(1, 3, 2, 'text', 'Hello Saman, I submitted a bid for your Potato listing. Can you please review it?', NULL, '2026-06-14 08:57:29', 1, '2026-06-14 08:57:29', '2026-06-14 08:57:29'),
(2, 2, 3, 'text', 'Hi Keeri Mills, yes, I saw the bid. LKR 215 is acceptable. I will accept it now.', NULL, '2026-06-14 09:57:29', 1, '2026-06-14 09:57:29', '2026-06-14 09:57:29'),
(3, 3, 2, 'text', 'hi', NULL, '2026-06-22 15:20:41', 0, '2026-06-22 15:20:41', '2026-06-22 15:20:41'),
(4, 3, 2, 'image', NULL, 'chat_media/pMpuLxSrrv2nrrCn1KlW822LGmZGA4sXdFh4vLPY.jpg', '2026-06-22 15:21:39', 0, '2026-06-22 15:21:39', '2026-06-22 15:21:39'),
(5, 3, 2, 'text', 'hi', NULL, '2026-06-22 15:21:42', 0, '2026-06-22 15:21:42', '2026-06-22 15:21:42'),
(6, 3, 6, 'text', 'hi', NULL, '2026-06-22 17:01:49', 1, '2026-06-22 17:01:49', '2026-06-25 05:37:17'),
(7, 6, 4, 'text', 'hi', NULL, '2026-06-25 05:37:14', 0, '2026-06-25 05:37:14', '2026-06-25 05:37:14'),
(8, 6, 3, 'text', 'hi', NULL, '2026-06-25 05:37:22', 0, '2026-06-25 05:37:22', '2026-06-25 05:37:22');

-- --------------------------------------------------------

--
-- Table structure for table `confirmed_bids`
--

CREATE TABLE `confirmed_bids` (
  `id` bigint(20) UNSIGNED NOT NULL,
  `buyer_id` bigint(20) UNSIGNED NOT NULL,
  `harvest_listing_id` bigint(20) UNSIGNED NOT NULL,
  `farmer_id` bigint(20) UNSIGNED NOT NULL,
  `bid_id` bigint(20) UNSIGNED NOT NULL,
  `notes` text DEFAULT NULL,
  `total_amount` decimal(10,2) NOT NULL,
  `payment_status` enum('paid','unpaid') NOT NULL DEFAULT 'unpaid',
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `confirmed_bids`
--

INSERT INTO `confirmed_bids` (`id`, `buyer_id`, `harvest_listing_id`, `farmer_id`, `bid_id`, `notes`, `total_amount`, `payment_status`, `created_at`, `updated_at`) VALUES
(1, 3, 1, 2, 1, 'Potato purchase deal completed successfully.', 430000.00, 'paid', '2026-06-14 10:57:29', '2026-06-14 10:57:29');

-- --------------------------------------------------------

--
-- Table structure for table `confirmed_bids_payments`
--

CREATE TABLE `confirmed_bids_payments` (
  `id` bigint(20) UNSIGNED NOT NULL,
  `buyer_id` bigint(20) UNSIGNED NOT NULL,
  `farmer_id` bigint(20) UNSIGNED NOT NULL,
  `confirmed_bid_id` bigint(20) UNSIGNED NOT NULL,
  `total_amount` decimal(10,2) NOT NULL,
  `system_commission` decimal(10,2) NOT NULL,
  `farmer_amount` decimal(10,2) NOT NULL,
  `payment_id` varchar(255) DEFAULT NULL,
  `date_and_time` datetime NOT NULL,
  `payment_status` enum('paid','unpaid') NOT NULL DEFAULT 'unpaid',
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `confirmed_bids_payments`
--

INSERT INTO `confirmed_bids_payments` (`id`, `buyer_id`, `farmer_id`, `confirmed_bid_id`, `total_amount`, `system_commission`, `farmer_amount`, `payment_id`, `date_and_time`, `payment_status`, `created_at`, `updated_at`) VALUES
(1, 3, 2, 1, 438600.00, 8600.00, 430000.00, 'PAYHERE-CONFIRMED-8849', '2026-06-14 16:27:29', 'paid', '2026-06-14 10:57:29', '2026-06-14 10:57:29');

-- --------------------------------------------------------

--
-- Table structure for table `crops`
--

CREATE TABLE `crops` (
  `id` bigint(20) UNSIGNED NOT NULL,
  `cropname` varchar(255) NOT NULL,
  `image_path` varchar(255) DEFAULT NULL,
  `status` enum('pending','rejected','approved') NOT NULL DEFAULT 'pending',
  `added_by` bigint(20) UNSIGNED DEFAULT NULL,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `crops`
--

INSERT INTO `crops` (`id`, `cropname`, `image_path`, `status`, `added_by`, `created_at`, `updated_at`) VALUES
(1, 'Paddy', 'storage/crop-varieties/egRx7q4GrQUjRDOY5GQemQvQ3RaRDAXmsDqDco1R.jpg', 'approved', 1, '2026-06-14 10:57:29', '2026-06-29 07:34:50'),
(2, 'Carrot', 'storage/crop-varieties/Njk0iCKtNLlHqzdXZO17cxMWYEkVeM9tPaiNLVlD.jpg', 'approved', 1, '2026-06-14 10:57:29', '2026-06-29 07:34:59'),
(3, 'Potato', 'storage/crop-varieties/7fVq5tqEFt43V8EzhuhMqxbEwG0o9kstKNFWYUSh.jpg', 'approved', 1, '2026-06-14 10:57:29', '2026-06-29 07:35:09'),
(7, 'Maize', 'storage/crop-varieties/YGYPtRbd3QYhWwS8K19ULEustaVLfKKkUHP8vYpl.jpg', 'approved', 1, '2026-06-29 04:58:54', '2026-06-29 05:02:13'),
(8, 'Big Onion', 'storage/crop-varieties/3djwHZaYjr28n1aXUaHcn3yY7sIbrLGyObTKMMy3.jpg', 'approved', 1, '2026-06-29 04:58:54', '2026-06-29 05:02:54'),
(9, 'Red Onion', 'storage/crop-varieties/Q7yJ7eHhFO0nIvovyYm0DKy2RHVG815ypG02AIFl.jpg', 'approved', 1, '2026-06-29 04:58:54', '2026-06-29 05:03:32'),
(10, 'Tomato', 'storage/crop-varieties/wq4WExqh3n5r8XpcFW7Jna9X3zJsigiKQJhXOzp2.jpg', 'approved', 1, '2026-06-29 04:58:54', '2026-06-29 05:04:00'),
(11, 'Brinjal', 'storage/crop-varieties/vDzJZJ9SSMbkwMv3ZU1S2Y0wXDtKHs4DQYFatU6G.jpg', 'approved', 1, '2026-06-29 04:58:54', '2026-06-29 05:04:45'),
(12, 'Capsicum', 'storage/crop-varieties/Bnn96ckZNKlvyyy8p72OfFSP4DNZb5pFrh2tK8Gq.jpg', 'approved', 1, '2026-06-29 04:58:54', '2026-06-29 05:05:18'),
(13, 'Green Chilli', 'storage/crop-varieties/vzsgSDTutfGVKaH9wgWjFz2UTuCZLkLUaxzvxwPS.jpg', 'approved', 1, '2026-06-29 04:58:54', '2026-06-29 05:06:00'),
(14, 'Pumpkin', 'storage/crop-varieties/1qY7UFKgImtBBBeqTYR6XVIgqEAqO2VY4GUzJS0c.jpg', 'approved', 1, '2026-06-29 04:58:54', '2026-06-29 05:06:38'),
(15, 'Cucumber', 'storage/crop-varieties/Z6DQ00Mx70jbKMU1V1Fdnz64Kz5rbqvEQQKWCVrG.jpg', 'approved', 1, '2026-06-29 04:58:54', '2026-06-29 05:07:02'),
(16, 'Bitter Gourd', 'storage/crop-varieties/mvv2BphFNgkY01OelSPnYmA60QUXvceZDRRGuLD2.jpg', 'approved', 1, '2026-06-29 04:58:54', '2026-06-29 05:07:26'),
(17, 'Snake Gourd', 'storage/crop-varieties/yzyj7WPr3STOskLu4bDP4quzlfn0IfpaOAFkEktV.jpg', 'approved', 1, '2026-06-29 04:58:54', '2026-06-29 05:11:06'),
(18, 'Ridge Gourd', 'storage/crop-varieties/4hwZGB1JBnwgUCqRVcHzMBQqflJROQZfjqkX33AV.jpg', 'approved', 1, '2026-06-29 04:58:54', '2026-06-29 05:11:17'),
(19, 'Luffa', 'storage/crop-varieties/w5dN04iec5Bl1vAyCHBZpCxNThBoarFmlUjc0UE8.jpg', 'approved', 1, '2026-06-29 04:58:54', '2026-06-29 05:11:26'),
(20, 'Ash Plantain', 'storage/crop-varieties/qTJFA7JMDsYgwqCRKJ5Sj4OcHqodJtzV9PSzQfJ1.jpg', 'approved', 1, '2026-06-29 04:58:54', '2026-06-29 05:12:22'),
(21, 'Ladies Finger', 'storage/crop-varieties/AP7GV38418NT1ew8iQE5wE2n8ShAlGpi1yYTRZhs.jpg', 'approved', 1, '2026-06-29 04:58:54', '2026-06-29 05:12:33'),
(22, 'Winged Bean', 'storage/crop-varieties/Z5w6PWMToNvnlYQffWSqAYSwXshYrRJDhnqOBeW9.jpg', 'approved', 1, '2026-06-29 04:58:54', '2026-06-29 05:13:34'),
(23, 'Long Bean', 'storage/crop-varieties/vf95H7dFS4EhH4JSeNiuM2atQosFsgNbZECGqeej.jpg', 'approved', 1, '2026-06-29 04:58:54', '2026-06-29 05:13:43'),
(24, 'Beans', 'storage/crop-varieties/cKZUryRr4hp0XvVizOlZCGf0fgt3REzPL23RPwlT.jpg', 'approved', 1, '2026-06-29 04:58:54', '2026-06-29 05:13:52'),
(25, 'Cabbage', 'storage/crop-varieties/0cH1wQ9Psoq1QPc9cAOqSIMPfMAN7ObF4KGgB8Km.jpg', 'approved', 1, '2026-06-29 04:58:54', '2026-06-29 05:14:35'),
(26, 'Cauliflower', 'storage/crop-varieties/SdTmRBrAjZDmN2HHTPjWhp1CnjbJLecj3dx8fyN1.jpg', 'approved', 1, '2026-06-29 04:58:54', '2026-06-29 05:14:48'),
(27, 'Leeks', 'storage/crop-varieties/KNBAIK2NymjOI14NCyTqEhO8UvoYGWxgdssP982d.jpg', 'approved', 1, '2026-06-29 04:58:54', '2026-06-29 05:56:51'),
(28, 'Beetroot', 'storage/crop-varieties/HFrvT76MZ8UoOmK0KKxSPnokiT94kFaDBDGh4jMe.jpg', 'approved', 1, '2026-06-29 04:58:54', '2026-06-29 05:57:01'),
(29, 'Radish', 'storage/crop-varieties/3WNcfjM2qkOZCHC6PRRnjNNlXSgPk6i5mPGGHn8q.jpg', 'approved', 1, '2026-06-29 04:58:54', '2026-06-29 05:57:14'),
(30, 'Turnip', 'storage/crop-varieties/g0gMhZfjsBiLxDbKRSizbSl5ZYTjH9R8bhPnP4AA.jpg', 'approved', 1, '2026-06-29 04:58:54', '2026-06-29 05:58:38'),
(31, 'Gotukola', 'storage/crop-varieties/LZJkBwF92nvN4PqeRODXI8QJqhcbeUGxW4sc7JbL.jpg', 'approved', 1, '2026-06-29 04:58:54', '2026-06-29 05:58:47'),
(36, 'Manioc', 'storage/crop-varieties/lj9x0KU8aFfIaDUTTLzstcPz6fyleyGKGIfRFO4r.jpg', 'approved', 1, '2026-06-29 04:58:54', '2026-06-29 06:00:08'),
(37, 'Sweet Potato', 'storage/crop-varieties/xqzTJxIuQVuK7A2D8e8BU28SwgOqzyEdce4FLNsc.jpg', 'approved', 1, '2026-06-29 04:58:54', '2026-06-29 06:00:39'),
(38, 'Yam', 'storage/crop-varieties/MW2J8jm51e6l0aviON7ckTvgHM8oeZbufDwzdCXU.jpg', 'approved', 1, '2026-06-29 04:58:54', '2026-06-29 06:02:21'),
(39, 'Taro', 'storage/crop-varieties/RZ5erUVsz5DyrwYKS7UKYTZ6v5qlWRpjVeraGREg.jpg', 'approved', 1, '2026-06-29 04:58:54', '2026-06-29 06:02:57'),
(40, 'Banana', 'storage/crop-varieties/gjCp42Sl4X87cSENr9Y618He9KdjpN4YyZjiQtqh.jpg', 'approved', 1, '2026-06-29 04:58:54', '2026-06-29 06:03:08'),
(41, 'Papaya', 'storage/crop-varieties/4yelqRCs5dycpVE41v8ldMxAaChJ1IV4SaGqhNNf.jpg', 'approved', 1, '2026-06-29 04:58:54', '2026-06-29 06:04:29'),
(42, 'Mango', 'storage/crop-varieties/Sa4cXcN6pnmLzxwTfe5xwLuA4KPtnqcVFZnbzKAx.jpg', 'approved', 1, '2026-06-29 04:58:54', '2026-06-29 06:04:40'),
(43, 'Pineapple', 'storage/crop-varieties/d80vOC6Bxdk166irMHGKcpcvrvQQxJV5GZxdZWek.jpg', 'approved', 1, '2026-06-29 04:58:54', '2026-06-29 06:04:51'),
(44, 'Avocado', 'storage/crop-varieties/7AYtDGs8LGJmyl29oFVCNkOnBhZs3L880I4qfmfk.jpg', 'approved', 1, '2026-06-29 04:58:54', '2026-06-29 06:05:51'),
(45, 'Guava', 'storage/crop-varieties/LfMOz3FJFUOlJEurBIngDfw2RoLVFEiht0axTSIr.jpg', 'approved', 1, '2026-06-29 04:58:54', '2026-06-29 06:06:00'),
(46, 'Wood Apple', 'storage/crop-varieties/hQDfGgrae3kkBdjyn4a9z8EH8QP2qMJj0WbnRxz7.jpg', 'approved', 1, '2026-06-29 04:58:54', '2026-06-29 06:06:08'),
(47, 'Orange', 'storage/crop-varieties/0LpuSFcJ4WJhyqXN4OGs0eI37tjflcqgeA4SPqhR.jpg', 'approved', 1, '2026-06-29 04:58:54', '2026-06-29 06:07:16'),
(48, 'Lime', 'storage/crop-varieties/xHOpU8INCs6nkRqS8UFgaw7XWNPszpVJVMCWgdC2.jpg', 'approved', 1, '2026-06-29 04:58:54', '2026-06-29 06:07:25'),
(49, 'Lemon', 'storage/crop-varieties/2gbtkdTMBdVpocpJwrNY1EbN21vP0lYnIkiTOQqQ.jpg', 'approved', 1, '2026-06-29 04:58:54', '2026-06-29 06:07:33'),
(50, 'Passion Fruit', 'storage/crop-varieties/8vLUwsSyPWmYmLiZ2GSj6JN0a2B6v65NXT3mkpfJ.jpg', 'approved', 1, '2026-06-29 04:58:54', '2026-06-29 06:07:42'),
(51, 'Rambutan', 'storage/crop-varieties/U4b38T9hyw4EblxgshwcIS2Tu5aHyeRPTbwJeFWv.jpg', 'approved', 1, '2026-06-29 04:58:54', '2026-06-29 06:14:49'),
(52, 'Mangosteen', 'storage/crop-varieties/ZDxu895Umqti3I8j4C8OXvMugjtBQBsD5ajIb4H9.jpg', 'approved', 1, '2026-06-29 04:58:54', '2026-06-29 06:15:00'),
(53, 'Durian', 'storage/crop-varieties/337cbQkYQlfxljsi2dLd0gs7hwUA9UyVVWLDR266.jpg', 'approved', 1, '2026-06-29 04:58:54', '2026-06-29 06:15:11'),
(54, 'Jackfruit', 'storage/crop-varieties/EWHtRLbRfKbw7T97Ogg9sEyL4JOxN68gzb6XwHZN.jpg', 'approved', 1, '2026-06-29 04:58:54', '2026-06-29 06:15:21'),
(55, 'Breadfruit', 'storage/crop-varieties/1uUCwMbywf4psAgIleUzoqeMtuC607IBlg3EL9EC.jpg', 'approved', 1, '2026-06-29 04:58:54', '2026-06-29 06:15:31'),
(56, 'Coconut', 'storage/crop-varieties/qgDq8SFWjiPmjp7NRikI6pbxVFBSZHmzBYKiQCVO.jpg', 'approved', 1, '2026-06-29 04:58:54', '2026-06-29 06:15:40'),
(57, 'Arecanut', 'storage/crop-varieties/NDq5zmesH0iuzMgV4vHvBDAAeU0LHa6nth4PmKxX.jpg', 'approved', 1, '2026-06-29 04:58:54', '2026-06-29 06:17:07'),
(58, 'Cashew', 'storage/crop-varieties/vlsd6MTscTkDXS5iiW30izybx5j75yo0vMPa3kc2.jpg', 'approved', 1, '2026-06-29 04:58:54', '2026-06-29 06:17:16'),
(59, 'Coffee', 'storage/crop-varieties/BpgqzZVNbg1EfstZS0kujoEsBmRU1g0RuDX4SWSu.jpg', 'approved', 1, '2026-06-29 04:58:54', '2026-06-29 06:17:24'),
(60, 'Tea', 'storage/crop-varieties/lELeblrMu4iILzYxu7YpDwKZP5ikW5G4mv7Ql3vq.jpg', 'approved', 1, '2026-06-29 04:58:54', '2026-06-29 06:17:32'),
(62, 'Pepper', 'storage/crop-varieties/jwannJNJbtZI2gldgntM3cLQWeTBVRYgt1LQUcMY.jpg', 'approved', 1, '2026-06-29 04:58:54', '2026-06-29 06:19:38'),
(63, 'Cinnamon', 'storage/crop-varieties/SHjaQqQfZ70bUA7AynwbCBTTyY9DX7OoUFG9ej5h.jpg', 'approved', 1, '2026-06-29 04:58:54', '2026-06-29 06:19:51'),
(64, 'Cardamom', 'storage/crop-varieties/sjGUEjcbKbD8906dScn1yskEzmOmSJd51DP2iMyl.jpg', 'approved', 1, '2026-06-29 04:58:54', '2026-06-29 06:20:01'),
(65, 'Clove', 'storage/crop-varieties/XOONzQQEw1Y6FnionWBeZyUIFWEy6dOsKWO9tZZL.jpg', 'approved', 1, '2026-06-29 04:58:54', '2026-06-29 06:20:10'),
(66, 'Nutmeg', 'storage/crop-varieties/dN0hUGwW5ToXL70prggZOTWBP4SFNVf82Nqa1NEe.jpg', 'approved', 1, '2026-06-29 04:58:54', '2026-06-29 06:20:20'),
(67, 'Turmeric', 'storage/crop-varieties/chq4NG52FR6wprB5Q9Wr22ZyYoIvNqnyaN50EA6O.jpg', 'approved', 1, '2026-06-29 04:58:54', '2026-06-29 06:21:43'),
(68, 'Ginger', 'storage/crop-varieties/pPkJZqK9DbSFaOLEkJeDTlLOeL0dW6334DTvZYRT.jpg', 'approved', 1, '2026-06-29 04:58:54', '2026-06-29 06:21:52'),
(69, 'Betel', 'storage/crop-varieties/WCybcbemKc8dG3qbWrYrAO1n0KoSUP4IbSEecjva.jpg', 'approved', 1, '2026-06-29 04:58:54', '2026-06-29 06:22:01'),
(70, 'Sesame', 'storage/crop-varieties/4NEAKGXWVu9nTdSz20IHoQq3xRaheEPHPMmyJenS.jpg', 'approved', 1, '2026-06-29 04:58:54', '2026-06-29 06:22:12'),
(71, 'Groundnut', 'storage/crop-varieties/ytcOnTMKjOIVurlKNPgXhH2H9hsf9ejfEMOrHjF4.jpg', 'approved', 1, '2026-06-29 04:58:54', '2026-06-29 06:22:21'),
(72, 'Soybean', 'storage/crop-varieties/35lrND16Izgjz2xRgHIIajMfBK6YLlrepZfBscs8.jpg', 'approved', 1, '2026-06-29 04:58:54', '2026-06-29 06:37:24'),
(73, 'Black Gram', 'storage/crop-varieties/MMoGhV941aEZzAiIGJUwQz8mUDMGyQXikqNVfEZk.jpg', 'approved', 1, '2026-06-29 04:58:54', '2026-06-29 06:37:36'),
(74, 'Green Gram', 'storage/crop-varieties/WGXx2r3tqcCavk4YvQGbJwXNk8gvLClSaxa1WHlt.jpg', 'approved', 1, '2026-06-29 04:58:54', '2026-06-29 06:37:48'),
(75, 'Cowpea', 'storage/crop-varieties/mSbRPgMHFhzDeQD4RlvDBGly3GkR0BsWVWc6UKt5.jpg', 'approved', 1, '2026-06-29 04:58:54', '2026-06-29 06:38:00'),
(76, 'Finger Millet', 'storage/crop-varieties/V0r4T7uWaXDdNqYWEUtaFJOxfWopd0D3D0zWzcHf.jpg', 'approved', 1, '2026-06-29 04:58:54', '2026-06-29 06:38:11'),
(77, 'Sorghum', 'storage/crop-varieties/h7i4hVfIa5JruZiOxv6HsBAzPL2maznFZqoBfx2X.jpg', 'approved', 1, '2026-06-29 04:58:54', '2026-06-29 06:39:22'),
(78, 'Kurakkan', 'storage/crop-varieties/0WqxVl3cccr8VKekjoeK0CATqVPvmzcN9bHgDBho.jpg', 'approved', 1, '2026-06-29 04:58:54', '2026-06-29 06:39:35'),
(79, 'Mustard', 'storage/crop-varieties/CaGNcVWSFA35X3fNhkZxomomyX6O7tqJtbpQVg1D.jpg', 'approved', 1, '2026-06-29 04:58:54', '2026-06-29 06:44:36'),
(82, 'Murunga', 'storage/crop-varieties/AAWJckC1SpUsUgWlX8TogOYFzFBQIsx4HynhaF9d.jpg', 'approved', 1, '2026-06-29 04:58:54', '2026-06-29 06:45:44'),
(83, 'Thibbatu', 'storage/crop-varieties/eUYuNSKpsiUc2oW4YDfOkmu2RcrE6BInneDC9z5T.jpg', 'approved', 1, '2026-06-29 04:58:54', '2026-06-29 06:46:00'),
(84, 'Kekiri', 'storage/crop-varieties/irjoAMljzrh5WQzbK0MlhEUyaSDvTQPAnD2qfLzb.jpg', 'approved', 1, '2026-06-29 04:58:54', '2026-06-29 06:49:04'),
(85, 'Pathola', 'storage/crop-varieties/haPzUvmNGT2SZA8KKU8Q4Evr5QE2RJ8748H867qs.jpg', 'approved', 1, '2026-06-29 04:58:54', '2026-06-29 06:49:16'),
(87, 'Bandakka', 'storage/crop-varieties/nFtJg6IWYcjJLMS7OccHERpoAuf5Fe2OGDJiO6MH.jpg', 'approved', 1, '2026-06-29 04:58:54', '2026-06-29 06:49:25'),
(91, 'Dragon Fruit', 'storage/crop-varieties/M7RTR6CmfOEbTE9jRh3afd0WW7GpxUdjHKF1Wf8m.jpg', 'approved', 1, '2026-06-29 04:58:54', '2026-06-29 06:50:37'),
(92, 'Watermelon', 'storage/crop-varieties/ev0ODFwguaHfOmmF8z6AfyFbjYjtvjTer1GCpN4S.jpg', 'approved', 1, '2026-06-29 04:58:54', '2026-06-29 06:51:07'),
(93, 'Muskmelon', 'storage/crop-varieties/wNtHhoFertEDUp3RORZDOe17tNou1y3mNUYN0eEx.jpg', 'approved', 1, '2026-06-29 04:58:54', '2026-06-29 06:59:47'),
(94, 'Strawberry', 'storage/crop-varieties/WfjI3hbKLVxELc4Wypn3SgvjQgj7uv712ezXBeTI.jpg', 'approved', 1, '2026-06-29 04:58:54', '2026-06-29 06:59:56'),
(95, 'Star Fruit', 'storage/crop-varieties/8DP38VE3nU9YFGOB4UpsvlOcOcB6aofOya8YcaC3.jpg', 'approved', 1, '2026-06-29 04:58:54', '2026-06-29 07:00:06'),
(96, 'Rose Apple', 'storage/crop-varieties/e6F8xxOkN0EmkwHVpWxsmRWz7hxy6PF5OY8AUctX.jpg', 'approved', 1, '2026-06-29 04:58:54', '2026-06-29 07:00:15'),
(97, 'Velvet Tamarind', 'storage/crop-varieties/GSKdQo20nA56vg8zSHt7nZm67h0oC1FuXDRY0NWr.jpg', 'approved', 1, '2026-06-29 04:58:54', '2026-06-29 07:00:28'),
(98, 'Tamarind', 'storage/crop-varieties/vYwWkyq3qWRcwohpR6jwk9dZQgg5sKezNAFQTKwO.jpg', 'approved', 1, '2026-06-29 04:58:54', '2026-06-29 07:32:55'),
(99, 'Soursop', 'storage/crop-varieties/H0Oqbx30f1QhXJ2B0d67mw0InZFLsnCLBKKP0UKM.jpg', 'approved', 1, '2026-06-29 04:58:54', '2026-06-29 07:33:06'),
(100, 'Bilimbi', 'storage/crop-varieties/rSQ2Qqb4VKaMXeL8A9d75C8MWY2fRb4SGVBOUcQL.jpg', 'approved', 1, '2026-06-29 04:58:54', '2026-06-29 07:33:16'),
(101, 'Ambarella', 'storage/crop-varieties/I2qSwlCbJ9x0Q0xApJMz4ftFn5bJdWrNjFBclqbH.jpg', 'approved', 1, '2026-06-29 04:58:54', '2026-06-29 07:33:27'),
(102, 'Jambu', 'storage/crop-varieties/fzrsvHkPHeZ1bQyaLN3zf9FTmtmiM6NCmbwJmZSz.jpg', 'approved', 1, '2026-06-29 04:58:54', '2026-06-29 07:33:37'),
(103, 'Pomelo', 'storage/crop-varieties/Up9JZCpSfw7jU3w41gHZM96D9vZywJZFMBUO01fS.jpg', 'approved', 1, '2026-06-29 04:58:54', '2026-06-29 07:34:39'),
(104, 'Aloe Vera', 'storage/crop-varieties/BZzBltyf6dskc3NAQPxH3JCC9qyRYERMcIjZFOpG.jpg', 'approved', 1, '2026-06-29 07:36:09', '2026-06-29 07:38:08'),
(105, 'Roselle', 'storage/crop-varieties/jBr2xtM3xS9yW0cN0REvSApIrGUaaA1EzzEsZyzD.jpg', 'approved', 1, '2026-06-29 07:36:09', '2026-06-29 07:38:18'),
(106, 'Curry Leaf', 'storage/crop-varieties/l5gaLZhNc0Busxp8g5h9jZ4NZRpRZsqHhL93dDtY.jpg', 'approved', 1, '2026-06-29 07:36:09', '2026-06-29 07:38:28'),
(107, 'Pandan', 'storage/crop-varieties/r0l57kRgcIgJ0eN0t8BAZLc28hEHIPBhgZpoNEgt.jpg', 'approved', 1, '2026-06-29 07:36:09', '2026-06-29 07:38:38'),
(108, 'Mint', 'storage/crop-varieties/mic6fQbHQrSw2y3ri2VxXs7xikptn68Xp477OBJa.jpg', 'approved', 1, '2026-06-29 07:36:09', '2026-06-29 07:38:48'),
(109, 'Basil', 'storage/crop-varieties/JJBAwLJRmm74PPR2HB5EVRIOj41LHO8FDAugQNqo.jpg', 'approved', 1, '2026-06-29 07:36:09', '2026-06-29 07:39:46'),
(110, 'Lemongrass', 'storage/crop-varieties/0SoBU6EapCKJ3uQc5dJuTZJD0rro3USZbqOVY6z4.jpg', 'approved', 1, '2026-06-29 07:36:09', '2026-06-29 07:39:56'),
(127, 'Ceylon Spinach Red', 'storage/crop-varieties/1lluY1tULvRdXPB0wjM8rjb1ttOUHkwoIAPdSuZR.jpg', 'approved', 1, '2026-06-29 07:44:27', '2026-06-29 07:47:39'),
(130, 'Chayote', 'storage/crop-varieties/w1IAvjqI9tGtamJcnaTg5KWwO90C7UyY6TDnRg2B.jpg', 'approved', 1, '2026-06-29 07:44:27', '2026-06-29 07:46:24'),
(131, 'Winged Yam', 'storage/crop-varieties/83lB7rwAXZwdPtkzuuhO5ThT17Zre4Uyv2EEme1z.jpg', 'approved', 1, '2026-06-29 07:44:27', '2026-06-29 07:45:57'),
(133, 'Date', 'storage/crop-varieties/YxbI1Qz4rz2nU72J5Tnfc8ypqbpgh7OaJMdlLG76.jpg', 'approved', 1, '2026-06-29 07:44:27', '2026-06-29 07:45:13');

-- --------------------------------------------------------

--
-- Table structure for table `crop_growth_stages`
--

CREATE TABLE `crop_growth_stages` (
  `id` bigint(20) UNSIGNED NOT NULL,
  `name` varchar(255) NOT NULL,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `crop_growth_stages`
--

INSERT INTO `crop_growth_stages` (`id`, `name`, `created_at`, `updated_at`) VALUES
(1, 'land_preparation', '2026-06-14 10:57:29', '2026-06-14 10:57:29'),
(2, 'sowing_planting', '2026-06-14 10:57:29', '2026-06-14 10:57:29'),
(3, 'germination', '2026-06-14 10:57:29', '2026-06-14 10:57:29'),
(4, 'seedling', '2026-06-14 10:57:29', '2026-06-14 10:57:29'),
(5, 'vegetative_early', '2026-06-14 10:57:29', '2026-06-14 10:57:29'),
(6, 'vegetative_mid', '2026-06-14 10:57:29', '2026-06-14 10:57:29'),
(7, 'vegetative_late', '2026-06-14 10:57:29', '2026-06-14 10:57:29'),
(8, 'flowering_bud_formation', '2026-06-14 10:57:29', '2026-06-14 10:57:29'),
(9, 'flowering_full_bloom', '2026-06-14 10:57:29', '2026-06-14 10:57:29'),
(10, 'fruit_set', '2026-06-14 10:57:29', '2026-06-14 10:57:29'),
(11, 'fruit_development', '2026-06-14 10:57:29', '2026-06-14 10:57:29'),
(12, 'maturation_ripening', '2026-06-14 10:57:29', '2026-06-14 10:57:29'),
(13, 'harvest_ongoing', '2026-06-14 10:57:29', '2026-06-14 10:57:29'),
(14, 'harvest_complete', '2026-06-14 10:57:29', '2026-06-14 10:57:29'),
(15, 'fallow', '2026-06-14 10:57:29', '2026-06-14 10:57:29');

-- --------------------------------------------------------

--
-- Table structure for table `crop_rates`
--

CREATE TABLE `crop_rates` (
  `id` bigint(20) UNSIGNED NOT NULL,
  `buyer_id` bigint(20) UNSIGNED NOT NULL,
  `crop_id` bigint(20) UNSIGNED NOT NULL,
  `date_and_time` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp(),
  `rate_per_kg_grade_a` decimal(10,2) DEFAULT NULL,
  `rate_per_kg_grade_b` decimal(10,2) DEFAULT NULL,
  `rate_per_kg_grade_c` decimal(10,2) DEFAULT NULL,
  `min_qty_required` decimal(10,2) DEFAULT NULL,
  `accepted_grade` varchar(255) DEFAULT NULL,
  `max_qty_required` decimal(10,2) DEFAULT NULL,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `crop_rates`
--

INSERT INTO `crop_rates` (`id`, `buyer_id`, `crop_id`, `date_and_time`, `rate_per_kg_grade_a`, `rate_per_kg_grade_b`, `rate_per_kg_grade_c`, `min_qty_required`, `accepted_grade`, `max_qty_required`, `created_at`, `updated_at`) VALUES
(1, 3, 1, '2026-06-13 10:57:29', 125.00, 110.00, 95.00, 500.00, 'All', 5000.00, '2026-06-14 10:57:29', '2026-06-14 10:57:29'),
(2, 3, 2, '2026-06-13 10:57:29', 320.00, 280.00, 240.00, 100.00, 'A', 1000.00, '2026-06-14 10:57:29', '2026-06-14 10:57:29'),
(3, 3, 2, '2026-06-22 11:57:52', 100.00, 95.00, 90.00, 100.00, 'All', 200.00, '2026-06-22 11:57:52', '2026-06-22 11:57:52'),
(4, 3, 1, '2026-06-22 11:58:51', 200.00, 160.00, 120.00, 50.00, 'All', 100.00, '2026-06-22 11:58:51', '2026-06-22 11:58:51'),
(5, 3, 3, '2026-06-22 11:59:25', 150.00, 130.00, 110.00, 190.00, 'A', 290.00, '2026-06-22 11:59:25', '2026-06-22 11:59:25');

-- --------------------------------------------------------

--
-- Table structure for table `customer_orders`
--

CREATE TABLE `customer_orders` (
  `id` bigint(20) UNSIGNED NOT NULL,
  `order_number` varchar(255) NOT NULL,
  `customer_id` bigint(20) UNSIGNED NOT NULL,
  `delivery_partner_id` bigint(20) UNSIGNED DEFAULT NULL,
  `delivery_address` varchar(255) NOT NULL,
  `delivery_latitude` decimal(10,8) DEFAULT NULL,
  `delivery_longitude` decimal(11,8) DEFAULT NULL,
  `customer_note` text DEFAULT NULL,
  `retail_seller_note` text DEFAULT NULL,
  `subtotal_amount` decimal(10,2) NOT NULL,
  `discount_amount` decimal(10,2) NOT NULL DEFAULT 0.00,
  `delivery_fee` decimal(10,2) NOT NULL DEFAULT 0.00,
  `system_commission_amount` decimal(10,2) NOT NULL DEFAULT 0.00,
  `tax_amount` decimal(10,2) NOT NULL DEFAULT 0.00,
  `total_amount` decimal(10,2) NOT NULL,
  `payment_status` enum('pending','paid','failed','refunded') NOT NULL DEFAULT 'pending',
  `payment_id` varchar(255) DEFAULT NULL,
  `order_status` enum('pending','confirmed','processing','ready_for_pickup','delivery_requested','delivery_partner_assigned','picked_up','on_the_way','delivered','completed','cancelled','refund_requested','refunded') NOT NULL DEFAULT 'pending',
  `placed_at` timestamp NOT NULL DEFAULT current_timestamp(),
  `confirmed_at` timestamp NULL DEFAULT NULL,
  `picked_up_at` timestamp NULL DEFAULT NULL,
  `delivered_at` timestamp NULL DEFAULT NULL,
  `cancelled_at` timestamp NULL DEFAULT NULL,
  `cancellation_reason` text DEFAULT NULL,
  `expected_date_and_time` datetime DEFAULT NULL,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `customer_orders`
--

INSERT INTO `customer_orders` (`id`, `order_number`, `customer_id`, `delivery_partner_id`, `delivery_address`, `delivery_latitude`, `delivery_longitude`, `customer_note`, `retail_seller_note`, `subtotal_amount`, `discount_amount`, `delivery_fee`, `system_commission_amount`, `tax_amount`, `total_amount`, `payment_status`, `payment_id`, `order_status`, `placed_at`, `confirmed_at`, `picked_up_at`, `delivered_at`, `cancelled_at`, `cancellation_reason`, `expected_date_and_time`, `created_at`, `updated_at`) VALUES
(1, 'ORD-RETAIL-4482-17182918', 6, 5, '99/A, Galle Road, Colombo 03', 6.91420000, 79.85170000, 'Deliver before 5 PM please.', 'kklklkl', 930.00, 30.00, 380.00, 46.50, 0.00, 1310.00, 'paid', 'PAYHERE-REF-3392182', 'delivered', '2026-06-13 10:57:30', '2026-06-13 11:12:30', '2026-06-13 11:57:30', '2026-06-13 12:57:30', '2026-06-12 03:48:16', 'nm,nmnmn', '2026-06-26 09:18:35', '2026-06-13 10:57:30', '2026-06-13 10:57:30'),
(2, 'ORD-RETAIL-1DIH-1782364868', 6, 5, '99/A, Galle Road', 6.91420000, 79.85170000, NULL, NULL, 660.00, 36.00, 1106.22, 88.31, 0.00, 1766.22, 'paid', '320032622399', 'picked_up', '2026-06-25 05:21:08', '2026-06-25 05:26:05', '2026-06-26 15:53:38', NULL, NULL, NULL, NULL, '2026-06-25 05:21:08', '2026-06-26 15:53:38');

-- --------------------------------------------------------

--
-- Table structure for table `daily_cultivation_logs`
--

CREATE TABLE `daily_cultivation_logs` (
  `id` bigint(20) UNSIGNED NOT NULL,
  `farmer_id` bigint(20) UNSIGNED NOT NULL,
  `land_id` bigint(20) UNSIGNED NOT NULL,
  `log_date` date NOT NULL,
  `growth_stage_id` bigint(20) UNSIGNED NOT NULL,
  `leaf_appearance` text DEFAULT NULL,
  `disease_detected` tinyint(1) NOT NULL DEFAULT 0,
  `pest_detected` tinyint(1) NOT NULL DEFAULT 0,
  `disease_name_and_damage` text DEFAULT NULL,
  `pest_name_and_damage` text DEFAULT NULL,
  `pesticide_applied` tinyint(1) NOT NULL DEFAULT 0,
  `pesticide_name` varchar(255) DEFAULT NULL,
  `pesticide_type` varchar(255) DEFAULT NULL,
  `notes` text DEFAULT NULL,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `daily_cultivation_logs`
--

INSERT INTO `daily_cultivation_logs` (`id`, `farmer_id`, `land_id`, `log_date`, `growth_stage_id`, `leaf_appearance`, `disease_detected`, `pest_detected`, `disease_name_and_damage`, `pest_name_and_damage`, `pesticide_applied`, `pesticide_name`, `pesticide_type`, `notes`, `created_at`, `updated_at`) VALUES
(1, 2, 1, '2026-06-12', 7, 'Healthy green leaves', 0, 0, NULL, NULL, 0, NULL, NULL, 'Potato plants looking healthy. Watering kept at optimum stream intake.', '2026-06-14 10:57:29', '2026-06-14 10:57:29'),
(2, 7, 2, '2026-06-20', 1, 'hgg', 1, 0, '{\"name\":\"s\",\"damage\":\"d\"}', NULL, 0, NULL, NULL, 'j', '2026-06-20 04:38:06', '2026-06-20 04:38:06'),
(3, 7, 2, '2026-06-20', 1, 'leaf got yellow color', 0, 0, NULL, NULL, 0, NULL, NULL, 'leaf got yellow and small white insect can see', '2026-06-20 04:45:23', '2026-06-20 04:45:23');

-- --------------------------------------------------------

--
-- Table structure for table `delivery_partner_verification_data`
--

CREATE TABLE `delivery_partner_verification_data` (
  `id` bigint(20) UNSIGNED NOT NULL,
  `user_id` bigint(20) UNSIGNED NOT NULL,
  `driving_license_expiry_date` date DEFAULT NULL,
  `vehicle_type` varchar(255) DEFAULT NULL,
  `vehicle_make` varchar(255) DEFAULT NULL,
  `model` varchar(255) DEFAULT NULL,
  `year` int(11) DEFAULT NULL,
  `color` varchar(255) DEFAULT NULL,
  `registration_number` varchar(255) DEFAULT NULL,
  `insurance_image_path` varchar(255) DEFAULT NULL,
  `revenue_license_image_path` varchar(255) DEFAULT NULL,
  `insurance_expiry` date DEFAULT NULL,
  `revenue_license_expiry` date DEFAULT NULL,
  `vehicle_front_image` varchar(255) DEFAULT NULL,
  `vehicle_back_image` varchar(255) DEFAULT NULL,
  `vehicle_other_images` longtext CHARACTER SET utf8mb4 COLLATE utf8mb4_bin DEFAULT NULL CHECK (json_valid(`vehicle_other_images`)),
  `max_weight` decimal(10,2) DEFAULT NULL,
  `status` varchar(255) NOT NULL DEFAULT 'pending',
  `rejected_reason` text DEFAULT NULL,
  `notes` text DEFAULT NULL,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `delivery_partner_verification_data`
--

INSERT INTO `delivery_partner_verification_data` (`id`, `user_id`, `driving_license_expiry_date`, `vehicle_type`, `vehicle_make`, `model`, `year`, `color`, `registration_number`, `insurance_image_path`, `revenue_license_image_path`, `insurance_expiry`, `revenue_license_expiry`, `vehicle_front_image`, `vehicle_back_image`, `vehicle_other_images`, `max_weight`, `status`, `rejected_reason`, `notes`, `created_at`, `updated_at`) VALUES
(1, 5, '2029-06-14', 'motorcycle', 'Honda', 'Super Cub', 2022, 'Red', 'SP-BCC-8849', 'delivery-partner-verifications/5/W3JOCxFYaibTTUgRzuYbzYwjrtwOm2vlzyc4jbjq.jpg', 'delivery-partner-verifications/5/nMl5FkVL4T46GAspAtkDp2ub56PJPoCfGP1wuP0H.jpg', '2027-06-14', '2027-06-14', 'delivery-partner-vehicles/5/9pUUDYZzaQ2e2ufI2EmuAQSBcPrFquZMVZo867zR.jpg', 'delivery-partner-vehicles/5/Lwvg7PXpt80callWJGMavlzkLFh4RRJ00DwSY8Tj.jpg', NULL, 25.00, 'verified', NULL, 'sdfsdfff', '2026-06-14 10:57:29', '2026-07-01 05:10:20'),
(2, 13, '2027-07-31', 'motorcycle', 'Honda', 'Dio', 2011, 'Blue', 'SP-BFX-7878', 'delivery-partner-verifications/13/LQxD16hcgzNwFe5pGTGEiGl0GtxFa6jDUVBI1RCW.jpg', 'delivery-partner-verifications/13/hgoOwQgyY03etNDxq4QvLJFmpGnwaVSYoj3etv5v.jpg', '2027-07-31', '2027-07-31', 'delivery-partner-vehicles/13/sG7u9SWY43ZcpncWRPFpoPhnaoX034xcS9SkFH9Y.jpg', 'delivery-partner-vehicles/13/t5vLgYxkgpehgqq9SQZcMUmWdsx2WShmu7ironPx.jpg', '[]', 25.00, 'verified', NULL, NULL, '2026-07-01 05:05:52', '2026-07-01 05:09:59'),
(3, 14, '2027-07-31', 'motorcycle', 'Honda', 'Dio', 2016, 'Blue', 'SP-BDG-7872', 'delivery-partner-verifications/14/eAfsCkEjp4z6gF9vFYXEzFOuQ0Vcu6WXONbYCdYh.jpg', 'delivery-partner-verifications/14/fuuZ3V53CWb5dwwR2A32Krrp4QSIVKrXawv5U4Uy.jpg', '2027-07-31', '2027-07-31', 'delivery-partner-vehicles/14/Qs2jRgjCDDA1fBTjiDlfc9dyAbAKKXYgLWfU5za3.jpg', 'delivery-partner-vehicles/14/onQbN3guWBDWTDG8QkbawrlksiXeEdXb4Zpp9bu3.jpg', '[]', 25.00, 'verified', NULL, NULL, '2026-07-01 05:11:35', '2026-07-01 05:17:40');

-- --------------------------------------------------------

--
-- Table structure for table `failed_jobs`
--

CREATE TABLE `failed_jobs` (
  `id` bigint(20) UNSIGNED NOT NULL,
  `uuid` varchar(255) NOT NULL,
  `connection` text NOT NULL,
  `queue` text NOT NULL,
  `payload` longtext NOT NULL,
  `exception` longtext NOT NULL,
  `failed_at` timestamp NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `farmer_verification_data`
--

CREATE TABLE `farmer_verification_data` (
  `id` bigint(20) UNSIGNED NOT NULL,
  `user_id` bigint(20) UNSIGNED NOT NULL,
  `farming_license_number` varchar(255) DEFAULT NULL,
  `farming_license_path` varchar(255) DEFAULT NULL,
  `organic_certificate_number` varchar(255) DEFAULT NULL,
  `organic_certificate_path` varchar(255) DEFAULT NULL,
  `organic_certificate_expiry` date DEFAULT NULL,
  `gap_certificate_number` varchar(255) DEFAULT NULL,
  `gap_certificate_path` varchar(255) DEFAULT NULL,
  `gap_certificate_expiry` date DEFAULT NULL,
  `other_certificates_titles_and_paths` longtext CHARACTER SET utf8mb4 COLLATE utf8mb4_bin DEFAULT NULL CHECK (json_valid(`other_certificates_titles_and_paths`)),
  `total_lands` int(11) NOT NULL DEFAULT 0,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `farmer_verification_data`
--

INSERT INTO `farmer_verification_data` (`id`, `user_id`, `farming_license_number`, `farming_license_path`, `organic_certificate_number`, `organic_certificate_path`, `organic_certificate_expiry`, `gap_certificate_number`, `gap_certificate_path`, `gap_certificate_expiry`, `other_certificates_titles_and_paths`, `total_lands`, `created_at`, `updated_at`) VALUES
(1, 2, 'FL-99388', 'verifications/farming_license.pdf', 'ORG-4482', 'verifications/organic_cert.pdf', '2027-06-14', 'GAP-2281', 'verifications/gap_cert.pdf', '2027-06-14', NULL, 1, '2026-07-01 02:57:31', '2026-07-01 02:57:31'),
(2, 7, 'FRM-1122', 'farmer-verifications/7/tlU5TIvbTIcqvNrNHwUsm1GGWLjWiAzzC6Akxr7i.pdf', 'ORG-2235', 'farmer-verifications/7/sMrO7A2wEK3pwXg9DzeHV4M7Fb104jVClE9IItPN.pdf', '2027-06-17', 'GAP-4789', 'farmer-verifications/7/dTU0Y2R9ssZ01f0KRxmLN3CuYXjC0d3UDxdxPbO8.pdf', '2027-06-17', NULL, 4, '2026-06-30 16:01:10', '2026-06-30 16:01:10'),
(3, 10, 'FRM-7867', NULL, 'ORG-7895', NULL, '2027-07-31', 'GRP-6689', NULL, '2027-07-24', NULL, 1, '2026-07-01 03:09:07', '2026-07-01 03:09:07');

-- --------------------------------------------------------

--
-- Table structure for table `harvest_bids`
--

CREATE TABLE `harvest_bids` (
  `id` bigint(20) UNSIGNED NOT NULL,
  `buyer_id` bigint(20) UNSIGNED NOT NULL,
  `harvest_listing_id` bigint(20) UNSIGNED NOT NULL,
  `bid_amount_per_unit` decimal(10,2) NOT NULL,
  `bid_quantity_unit` decimal(10,2) NOT NULL,
  `notes` text DEFAULT NULL,
  `status` enum('pending','accepted','rejected','expired') NOT NULL DEFAULT 'pending',
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `harvest_bids`
--

INSERT INTO `harvest_bids` (`id`, `buyer_id`, `harvest_listing_id`, `bid_amount_per_unit`, `bid_quantity_unit`, `notes`, `status`, `created_at`, `updated_at`) VALUES
(1, 3, 1, 215.00, 2000.00, 'We will pick it up using our small truck tomorrow morning.', 'accepted', '2026-06-14 10:57:29', '2026-06-14 10:57:29'),
(2, 3, 2, 115.00, 20.00, 'dssdf', 'pending', '2026-06-20 06:29:20', '2026-06-20 06:29:20');

-- --------------------------------------------------------

--
-- Table structure for table `harvest_listings`
--

CREATE TABLE `harvest_listings` (
  `id` bigint(20) UNSIGNED NOT NULL,
  `farmer_id` bigint(20) UNSIGNED NOT NULL,
  `crop_id` bigint(20) UNSIGNED NOT NULL,
  `date_and_time` datetime NOT NULL,
  `notes` text DEFAULT NULL,
  `grade` enum('A','B','C') NOT NULL,
  `available_quantity` decimal(10,2) NOT NULL,
  `unit` enum('kg','g','ton','piece','bunch','dozen','liter') NOT NULL,
  `minimum_order_quantity` decimal(10,2) NOT NULL,
  `maximum_order_quantity` decimal(10,2) NOT NULL,
  `price_per_unit` decimal(10,2) NOT NULL,
  `min_bid_price_per_unit` decimal(10,2) DEFAULT NULL,
  `harvest_date` date NOT NULL,
  `harvest_condition` varchar(255) NOT NULL,
  `storage_method` varchar(255) DEFAULT NULL,
  `pickup_latitude` decimal(10,8) DEFAULT NULL,
  `pickup_longitude` decimal(11,8) DEFAULT NULL,
  `delivery_available` tinyint(1) NOT NULL DEFAULT 0,
  `delivery_fee_per_km` decimal(10,2) DEFAULT NULL,
  `max_delivery_distance` decimal(8,2) DEFAULT NULL,
  `available_from_date` date NOT NULL,
  `available_to_date` date NOT NULL,
  `bidding_start_date_and_time` datetime DEFAULT NULL,
  `bidding_end_date_and_time` datetime DEFAULT NULL,
  `image_1` varchar(255) DEFAULT NULL,
  `image_2` varchar(255) DEFAULT NULL,
  `image_3` varchar(255) DEFAULT NULL,
  `image_4` varchar(255) DEFAULT NULL,
  `status` enum('draft','pending_approval','active','bidding_active','bidding_ended','sold_out','expired','cancelled','suspended','rejected') NOT NULL DEFAULT 'draft',
  `reject_reason` text DEFAULT NULL,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `harvest_listings`
--

INSERT INTO `harvest_listings` (`id`, `farmer_id`, `crop_id`, `date_and_time`, `notes`, `grade`, `available_quantity`, `unit`, `minimum_order_quantity`, `maximum_order_quantity`, `price_per_unit`, `min_bid_price_per_unit`, `harvest_date`, `harvest_condition`, `storage_method`, `pickup_latitude`, `pickup_longitude`, `delivery_available`, `delivery_fee_per_km`, `max_delivery_distance`, `available_from_date`, `available_to_date`, `bidding_start_date_and_time`, `bidding_end_date_and_time`, `image_1`, `image_2`, `image_3`, `image_4`, `status`, `reject_reason`, `created_at`, `updated_at`) VALUES
(1, 2, 3, '2026-06-14 16:27:29', 'Superb grade A red potatoes harvested organically in Nuwara Eliya. Cleaned and packed in 50kg sacks.', 'A', 2000.00, 'kg', 100.00, 2000.00, 220.00, 210.00, '2026-06-09', 'fresh', 'room_temp', 6.94900000, 80.78950000, 1, 50.00, 30.00, '2026-06-09', '2026-06-24', NULL, NULL, NULL, NULL, NULL, NULL, 'active', NULL, '2026-06-14 10:57:29', '2026-06-14 10:57:29'),
(2, 7, 1, '2026-06-20 09:59:50', 'good harvest', 'A', 40.00, 'kg', 20.00, 30.00, 100.00, 110.00, '2026-06-20', 'Fresh', 'Cold Storage', 7.10958915, 81.23636417, 1, 100.00, 100.00, '2026-06-20', '2026-06-27', '2026-06-20 00:00:00', '2026-06-27 23:59:59', 'harvest-listings/7/NuKAp7yM6WPR0begfVnOOAtUnHDgiqPbSwZj9AgG.jpg', NULL, NULL, NULL, 'active', NULL, '2026-06-20 04:29:50', '2026-06-20 04:32:06');

-- --------------------------------------------------------

--
-- Table structure for table `jobs`
--

CREATE TABLE `jobs` (
  `id` bigint(20) UNSIGNED NOT NULL,
  `queue` varchar(255) NOT NULL,
  `payload` longtext NOT NULL,
  `attempts` tinyint(3) UNSIGNED NOT NULL,
  `reserved_at` int(10) UNSIGNED DEFAULT NULL,
  `available_at` int(10) UNSIGNED NOT NULL,
  `created_at` int(10) UNSIGNED NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `job_batches`
--

CREATE TABLE `job_batches` (
  `id` varchar(255) NOT NULL,
  `name` varchar(255) NOT NULL,
  `total_jobs` int(11) NOT NULL,
  `pending_jobs` int(11) NOT NULL,
  `failed_jobs` int(11) NOT NULL,
  `failed_job_ids` longtext NOT NULL,
  `options` mediumtext DEFAULT NULL,
  `cancelled_at` int(11) DEFAULT NULL,
  `created_at` int(11) NOT NULL,
  `finished_at` int(11) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `lands`
--

CREATE TABLE `lands` (
  `id` bigint(20) UNSIGNED NOT NULL,
  `size` decimal(10,2) NOT NULL,
  `farmer_id` bigint(20) UNSIGNED NOT NULL,
  `ownership_type` varchar(255) NOT NULL,
  `registration_number` varchar(255) DEFAULT NULL,
  `land_documents_paths_and_document_titles` longtext CHARACTER SET utf8mb4 COLLATE utf8mb4_bin DEFAULT NULL CHECK (json_valid(`land_documents_paths_and_document_titles`)),
  `latitude` decimal(10,8) DEFAULT NULL,
  `longitude` decimal(11,8) DEFAULT NULL,
  `land_images` longtext CHARACTER SET utf8mb4 COLLATE utf8mb4_bin DEFAULT NULL CHECK (json_valid(`land_images`)),
  `status` varchar(255) NOT NULL DEFAULT 'pending',
  `rejected_reason` text DEFAULT NULL,
  `notes` text DEFAULT NULL,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `lands`
--

INSERT INTO `lands` (`id`, `size`, `farmer_id`, `ownership_type`, `registration_number`, `land_documents_paths_and_document_titles`, `latitude`, `longitude`, `land_images`, `status`, `rejected_reason`, `notes`, `created_at`, `updated_at`) VALUES
(1, 2.50, 2, 'owned', 'REG-99238', NULL, 6.94900000, 80.78950000, NULL, 'verified', NULL, 'Potato Valley fertile farm land.', '2026-06-14 10:57:29', '2026-06-14 10:57:29'),
(2, 25.00, 7, 'license', '234', '[{\"title\":\"dfgfdg\",\"path\":\"land-documents\\/7\\/2p0kxhXgPq3TsNme3QUXKBXal7HGYIigAgvytM5f.pdf\"}]', 6.23890590, 80.05414660, '[\"land-images\\/7\\/NUGNirVjRMGxVwjxEmkubsEiw5pADpCEtJCbgWQ1.jpg\"]', 'verified', NULL, 'sdfgfsg sdfsdf asdf', '2026-06-17 16:16:10', '2026-06-20 03:25:49');

-- --------------------------------------------------------

--
-- Table structure for table `land_crops`
--

CREATE TABLE `land_crops` (
  `id` bigint(20) UNSIGNED NOT NULL,
  `land_id` bigint(20) UNSIGNED NOT NULL,
  `crop_id` bigint(20) UNSIGNED NOT NULL,
  `text` text DEFAULT NULL,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `land_crops`
--

INSERT INTO `land_crops` (`id`, `land_id`, `crop_id`, `text`, `created_at`, `updated_at`) VALUES
(1, 1, 3, 'Red Lasoda variety, extent 1.5 acres, expected yield 3000kg.', '2026-06-14 10:57:29', '2026-06-14 10:57:29'),
(5, 2, 2, NULL, '2026-06-17 16:34:58', '2026-06-17 16:34:58'),
(6, 2, 1, NULL, '2026-06-17 16:34:58', '2026-06-17 16:34:58'),
(7, 2, 3, NULL, '2026-06-17 16:34:58', '2026-06-17 16:34:58');

-- --------------------------------------------------------

--
-- Table structure for table `migrations`
--

CREATE TABLE `migrations` (
  `id` int(10) UNSIGNED NOT NULL,
  `migration` varchar(255) NOT NULL,
  `batch` int(11) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `migrations`
--

INSERT INTO `migrations` (`id`, `migration`, `batch`) VALUES
(1, '0001_01_01_000000_create_users_table', 1),
(2, '0001_01_01_000001_create_cache_table', 1),
(3, '0001_01_01_000002_create_jobs_table', 1),
(4, '2026_05_18_000003_create_user_verification_documents_table', 1),
(5, '2026_05_18_000004_create_farmer_verification_data_table', 1),
(6, '2026_05_18_000005_create_lands_table', 1),
(7, '2026_05_18_000006_create_crops_table', 1),
(8, '2026_05_18_000007_create_land_crops_table', 1),
(9, '2026_05_18_000008_create_retail_seller_verification_data_table', 1),
(10, '2026_05_18_000009_create_delivery_partner_verification_data_table', 1),
(11, '2026_05_18_000010_create_crop_growth_stages_table', 1),
(12, '2026_05_18_000011_create_daily_cultivation_logs_table', 1),
(13, '2026_05_18_000012_create_chatbot_sessions_table', 1),
(14, '2026_05_18_000013_create_crop_rates_table', 1),
(15, '2026_05_18_043649_create_personal_access_tokens_table', 1),
(16, '2026_05_19_031237_create_harvest_listings_table', 1),
(17, '2026_05_19_031248_create_harvest_bids_table', 1),
(18, '2026_05_19_031255_create_confirmed_bids_table', 1),
(19, '2026_05_19_031300_create_confirmed_bids_payments_table', 1),
(20, '2026_05_19_031304_create_buyer_farmer_reviews_table', 1),
(21, '2026_05_19_031308_create_chats_table', 1),
(22, '2026_05_19_034234_create_user_wallets_table', 1),
(23, '2026_05_19_034234_create_wallet_transactions_table', 1),
(24, '2026_05_19_034235_create_offer_goals_table', 1),
(25, '2026_05_19_034235_create_withdraw_requests_table', 1),
(26, '2026_05_19_034236_create_offer_campaigns_table', 1),
(27, '2026_05_19_034236_create_user_offer_progress_table', 1),
(28, '2026_05_19_060017_create_retailer_products_table', 1),
(29, '2026_05_19_060018_create_customer_orders_table', 1),
(30, '2026_05_19_060019_create_order_items_table', 1),
(31, '2026_05_19_060019_create_retailer_customer_delivery_partner_reviews_table', 1),
(32, '2026_05_19_060020_create_order_delivery_requests_table', 1),
(33, '2026_05_19_060021_create_order_delivery_requests_assigned_partners_table', 1),
(34, '2026_05_19_060623_create_order_delivery_tracking_table', 1),
(35, '2026_05_19_060624_create_order_payments_table', 1),
(36, '2026_05_19_060624_create_order_status_histories_table', 1),
(37, '2026_05_22_000001_add_approval_fields_to_crops_table', 1),
(38, '2026_06_03_204146_update_orders_and_order_items_retailer', 1),
(39, '2026_06_05_000001_add_phone_number_2_verified_at_to_users_table', 1),
(40, '2026_06_20_102543_add_fcm_token_to_users_table', 2),
(41, '2026_06_20_102543_create_notifications_table', 2),
(42, '2026_06_20_111318_add_image_path_to_chatbot_sessions_table', 3);

-- --------------------------------------------------------

--
-- Table structure for table `notifications`
--

CREATE TABLE `notifications` (
  `id` bigint(20) UNSIGNED NOT NULL,
  `user_id` bigint(20) UNSIGNED NOT NULL,
  `title` varchar(255) NOT NULL,
  `message` text NOT NULL,
  `type` varchar(255) NOT NULL DEFAULT 'general',
  `read_at` timestamp NULL DEFAULT NULL,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `notifications`
--

INSERT INTO `notifications` (`id`, `user_id`, `title`, `message`, `type`, `read_at`, `created_at`, `updated_at`) VALUES
(1, 7, 'New Bid Received!', 'Amal Perera has placed a bid of LKR 115.00 per unit on your Paddy listing.', 'bid', '2026-06-30 15:36:57', '2026-06-30 15:36:37', '2026-06-30 15:36:57'),
(2, 2, 'New Bid Received!', 'Amal Perera has placed a bid of LKR 215.00 per unit on your Potato listing.', 'bid', '2026-07-01 02:57:54', '2026-07-01 02:38:22', '2026-07-01 02:57:54');

-- --------------------------------------------------------

--
-- Table structure for table `offer_campaigns`
--

CREATE TABLE `offer_campaigns` (
  `id` bigint(20) UNSIGNED NOT NULL,
  `offer_goal_id` bigint(20) UNSIGNED NOT NULL,
  `title` varchar(255) NOT NULL,
  `code` varchar(255) NOT NULL,
  `description` text DEFAULT NULL,
  `type` enum('percentage','fixed_amount','free_shipping') NOT NULL,
  `discount_percentage` decimal(5,2) DEFAULT NULL,
  `discount_amount` decimal(10,2) DEFAULT NULL,
  `max_discount_amount` decimal(10,2) DEFAULT NULL,
  `minimum_completion_count` int(11) NOT NULL DEFAULT 1,
  `valid_from` datetime NOT NULL,
  `valid_until` datetime NOT NULL,
  `usage_limit_per_user` int(11) DEFAULT NULL,
  `total_usage_limit` int(11) DEFAULT NULL,
  `is_active` tinyint(1) NOT NULL DEFAULT 1,
  `applied_user_role` enum('farmer','buyer','retail_seller','customer','delivery_partner') NOT NULL,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `offer_campaigns`
--

INSERT INTO `offer_campaigns` (`id`, `offer_goal_id`, `title`, `code`, `description`, `type`, `discount_percentage`, `discount_amount`, `max_discount_amount`, `minimum_completion_count`, `valid_from`, `valid_until`, `usage_limit_per_user`, `total_usage_limit`, `is_active`, `applied_user_role`, `created_at`, `updated_at`) VALUES
(1, 1, 'Fresh Start Seller Boost', 'FRESHSTART1000', 'Register and list 5 products to earn LKR 1000 cashback.', 'fixed_amount', NULL, 1000.00, NULL, 1, '2026-06-09 16:27:30', '2026-07-14 16:27:30', NULL, NULL, 1, 'retail_seller', '2026-06-14 10:57:30', '2026-06-14 10:57:30'),
(3, 4, 'fghhfgh', '345yfng', 'dhgdfhghd', 'fixed_amount', NULL, 54.00, NULL, 5, '2026-06-16 22:25:00', '2026-07-04 22:29:00', 5, 55, 1, 'buyer', '2026-06-15 16:55:23', '2026-06-15 16:55:23'),
(4, 5, 'ewarfgfgdfg', 'fdgfd34t443', 'dghddfgh', 'percentage', 12.00, NULL, 44.00, 14, '2026-06-15 22:27:00', '2026-07-04 22:27:00', 44, 44, 1, 'retail_seller', '2026-06-15 16:57:40', '2026-06-15 16:57:40');

-- --------------------------------------------------------

--
-- Table structure for table `offer_goals`
--

CREATE TABLE `offer_goals` (
  `id` bigint(20) UNSIGNED NOT NULL,
  `name` varchar(255) NOT NULL,
  `description` text DEFAULT NULL,
  `goal_type` enum('total_orders','total_spending','product_purchase_count','first_order','purchase_count','total_sales','total_earnings','total_products','rating_average','delivery_completed_orders','festival_campaign','seasonal_purchase','special_event_goal','total_referrals') NOT NULL,
  `target_value` decimal(12,2) NOT NULL,
  `is_active` tinyint(1) NOT NULL DEFAULT 1,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `offer_goals`
--

INSERT INTO `offer_goals` (`id`, `name`, `description`, `goal_type`, `target_value`, `is_active`, `created_at`, `updated_at`) VALUES
(1, 'List 5 retail products', 'List 5 retail products to fulfill the requirements', 'total_products', 5.00, 0, '2026-06-14 10:57:30', '2026-06-15 16:54:41'),
(3, 'High Value Buyer Milestone', '', 'total_spending', 50000.00, 1, '2026-06-15 16:35:51', '2026-06-15 16:35:51'),
(4, 'fdhgjgtf', 'fghgfhgfh', 'seasonal_purchase', 5.00, 1, '2026-06-15 16:54:36', '2026-06-15 16:54:36'),
(5, 'sedtrawebf', 'fdgdfgdfgdfgfd', 'rating_average', 44.00, 1, '2026-06-15 16:57:02', '2026-06-15 16:57:02');

-- --------------------------------------------------------

--
-- Table structure for table `order_delivery_requests`
--

CREATE TABLE `order_delivery_requests` (
  `id` bigint(20) UNSIGNED NOT NULL,
  `order_id` bigint(20) UNSIGNED NOT NULL,
  `request_status` enum('open','assigned','expired','cancelled','completed') NOT NULL DEFAULT 'open',
  `pickup_address` varchar(255) NOT NULL,
  `pickup_latitude` decimal(10,8) DEFAULT NULL,
  `pickup_longitude` decimal(11,8) DEFAULT NULL,
  `delivery_address` varchar(255) NOT NULL,
  `delivery_latitude` decimal(10,8) DEFAULT NULL,
  `delivery_longitude` decimal(11,8) DEFAULT NULL,
  `delivery_fee` decimal(10,2) NOT NULL,
  `system_commission` decimal(10,2) NOT NULL DEFAULT 0.00,
  `estimated_distance_km` decimal(8,2) DEFAULT NULL,
  `estimated_distance_minutes` int(11) DEFAULT NULL,
  `expires_at` timestamp NULL DEFAULT NULL,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `order_delivery_requests`
--

INSERT INTO `order_delivery_requests` (`id`, `order_id`, `request_status`, `pickup_address`, `pickup_latitude`, `pickup_longitude`, `delivery_address`, `delivery_latitude`, `delivery_longitude`, `delivery_fee`, `system_commission`, `estimated_distance_km`, `estimated_distance_minutes`, `expires_at`, `created_at`, `updated_at`) VALUES
(1, 1, 'completed', '78, High Level Road, Maharagama', 6.84800000, 79.92650000, '99/A, Galle Road, Colombo 03', 6.91420000, 79.85170000, 300.00, 30.00, 12.50, 35, '2026-06-19 15:03:08', '2026-06-13 10:57:30', '2026-06-13 10:57:30'),
(2, 2, 'assigned', '78, High Level Road', 6.84800000, 79.92650000, '99/A, Galle Road', 6.91420000, 79.85170000, 1106.22, 55.31, NULL, NULL, '2026-06-26 06:03:23', '2026-06-25 05:26:05', '2026-06-26 05:16:44');

-- --------------------------------------------------------

--
-- Table structure for table `order_delivery_requests_assigned_partners`
--

CREATE TABLE `order_delivery_requests_assigned_partners` (
  `id` bigint(20) UNSIGNED NOT NULL,
  `delivery_request_id` bigint(20) UNSIGNED NOT NULL,
  `delivery_partner_id` bigint(20) UNSIGNED NOT NULL,
  `status` enum('requested','accepted','rejected','cancelled','completed') NOT NULL DEFAULT 'requested',
  `requested_at` datetime NOT NULL DEFAULT current_timestamp(),
  `accepted_at` datetime DEFAULT NULL,
  `rejected_at` datetime DEFAULT NULL,
  `rejection_reason` text DEFAULT NULL,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `order_delivery_requests_assigned_partners`
--

INSERT INTO `order_delivery_requests_assigned_partners` (`id`, `delivery_request_id`, `delivery_partner_id`, `status`, `requested_at`, `accepted_at`, `rejected_at`, `rejection_reason`, `created_at`, `updated_at`) VALUES
(1, 1, 5, 'accepted', '2026-06-14 16:27:30', NULL, NULL, NULL, '2026-06-13 10:57:30', '2026-06-13 10:57:30'),
(2, 2, 5, 'accepted', '2026-06-26 10:46:44', '2026-06-26 10:46:44', NULL, NULL, '2026-06-26 05:16:44', '2026-06-26 05:16:44');

-- --------------------------------------------------------

--
-- Table structure for table `order_delivery_tracking`
--

CREATE TABLE `order_delivery_tracking` (
  `id` bigint(20) UNSIGNED NOT NULL,
  `order_id` bigint(20) UNSIGNED NOT NULL,
  `delivery_partner_id` bigint(20) UNSIGNED NOT NULL,
  `status` enum('assigned','heading_to_pickup','arrived_pickup','picked_up','on_the_way','arrived_destination','delivered') NOT NULL,
  `current_latitude` decimal(10,8) NOT NULL,
  `current_longitude` decimal(11,8) NOT NULL,
  `tracking_note` text DEFAULT NULL,
  `tracked_at` timestamp NOT NULL DEFAULT current_timestamp(),
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `order_delivery_tracking`
--

INSERT INTO `order_delivery_tracking` (`id`, `order_id`, `delivery_partner_id`, `status`, `current_latitude`, `current_longitude`, `tracking_note`, `tracked_at`, `created_at`, `updated_at`) VALUES
(1, 1, 5, 'delivered', 6.91420000, 79.85170000, 'Parcel handed over to customer.', '2026-06-13 12:57:30', '2026-06-13 12:57:30', '2026-06-13 12:57:30'),
(2, 2, 5, 'assigned', 6.22907170, 80.06227330, 'Delivery partner assigned and heading to first pickup.', '2026-06-26 05:16:44', '2026-06-26 05:16:44', '2026-06-26 05:16:44'),
(3, 2, 5, 'heading_to_pickup', 6.22904170, 80.06226000, 'Delivery partner is heading to pickup location.', '2026-06-26 05:29:47', '2026-06-26 05:29:47', '2026-06-26 05:29:47'),
(4, 2, 5, 'picked_up', 6.22894500, 80.06214500, 'Order has been picked up.', '2026-06-26 15:53:38', '2026-06-26 15:53:38', '2026-06-26 15:53:38');

-- --------------------------------------------------------

--
-- Table structure for table `order_items`
--

CREATE TABLE `order_items` (
  `id` bigint(20) UNSIGNED NOT NULL,
  `order_id` bigint(20) UNSIGNED NOT NULL,
  `retailer_product_id` bigint(20) UNSIGNED NOT NULL,
  `retailer_id` bigint(20) UNSIGNED NOT NULL,
  `quantity` decimal(10,2) NOT NULL,
  `total_price` decimal(10,2) NOT NULL,
  `discount_amount` decimal(10,2) NOT NULL DEFAULT 0.00,
  `final_price` decimal(10,2) NOT NULL,
  `grade` enum('A','B','C') NOT NULL,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `order_items`
--

INSERT INTO `order_items` (`id`, `order_id`, `retailer_product_id`, `retailer_id`, `quantity`, `total_price`, `discount_amount`, `final_price`, `grade`, `created_at`, `updated_at`) VALUES
(1, 1, 1, 4, 2.00, 580.00, 30.00, 550.00, 'A', '2026-06-13 10:57:30', '2026-06-13 10:57:30'),
(2, 1, 2, 3, 1.00, 380.00, 0.00, 380.00, 'A', '2026-06-13 10:57:30', '2026-06-13 10:57:30'),
(3, 2, 1, 4, 2.40, 696.00, 36.00, 660.00, 'A', '2026-06-25 05:21:08', '2026-06-25 05:21:08');

-- --------------------------------------------------------

--
-- Table structure for table `order_payments`
--

CREATE TABLE `order_payments` (
  `id` bigint(20) UNSIGNED NOT NULL,
  `order_id` bigint(20) UNSIGNED NOT NULL,
  `customer_id` bigint(20) UNSIGNED NOT NULL,
  `transaction_reference` varchar(255) DEFAULT NULL,
  `paid_amount` decimal(10,2) NOT NULL,
  `payment_status` enum('pending','paid','failed','refunded') NOT NULL DEFAULT 'pending',
  `paid_at` timestamp NULL DEFAULT NULL,
  `refund_at` timestamp NULL DEFAULT NULL,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `order_payments`
--

INSERT INTO `order_payments` (`id`, `order_id`, `customer_id`, `transaction_reference`, `paid_amount`, `payment_status`, `paid_at`, `refund_at`, `created_at`, `updated_at`) VALUES
(1, 1, 6, 'PAYHERE-REF-3392182', 1310.00, 'refunded', '2026-06-13 10:57:30', '2026-06-18 06:08:21', '2026-06-13 10:57:30', '2026-06-13 10:57:30'),
(2, 2, 6, '320032622399', 1828.03, 'paid', '2026-06-25 05:26:05', NULL, '2026-06-25 05:26:05', '2026-06-25 05:26:05');

-- --------------------------------------------------------

--
-- Table structure for table `order_status_histories`
--

CREATE TABLE `order_status_histories` (
  `id` bigint(20) UNSIGNED NOT NULL,
  `order_id` bigint(20) UNSIGNED NOT NULL,
  `changed_by_user_id` bigint(20) UNSIGNED NOT NULL,
  `old_status` varchar(255) DEFAULT NULL,
  `new_status` varchar(255) NOT NULL,
  `status_note` text DEFAULT NULL,
  `changed_at` timestamp NOT NULL DEFAULT current_timestamp(),
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `order_status_histories`
--

INSERT INTO `order_status_histories` (`id`, `order_id`, `changed_by_user_id`, `old_status`, `new_status`, `status_note`, `changed_at`, `created_at`, `updated_at`) VALUES
(1, 1, 6, NULL, 'pending', 'Order created by customer.', '2026-06-13 10:57:30', '2026-06-13 10:57:30', '2026-06-13 10:57:30'),
(2, 1, 5, 'picked_up', 'delivered', 'Delivered successfully.', '2026-06-13 12:57:30', '2026-06-13 12:57:30', '2026-06-13 12:57:30'),
(3, 2, 5, 'confirmed', 'delivery_partner_assigned', 'Delivery partner Nuwara Courier Express accepted the delivery.', '2026-06-26 05:16:44', '2026-06-26 05:16:44', '2026-06-26 05:16:44'),
(4, 2, 5, 'delivery_partner_assigned', 'delivery_partner_assigned', 'Delivery partner is heading to pickup location.', '2026-06-26 05:29:47', '2026-06-26 05:29:47', '2026-06-26 05:29:47'),
(5, 2, 5, 'delivery_partner_assigned', 'delivery_partner_assigned', 'Order has been picked up.', '2026-06-26 15:53:38', '2026-06-26 15:53:38', '2026-06-26 15:53:38');

-- --------------------------------------------------------

--
-- Table structure for table `password_reset_tokens`
--

CREATE TABLE `password_reset_tokens` (
  `email` varchar(255) NOT NULL,
  `token` varchar(255) NOT NULL,
  `created_at` timestamp NULL DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `personal_access_tokens`
--

CREATE TABLE `personal_access_tokens` (
  `id` bigint(20) UNSIGNED NOT NULL,
  `tokenable_type` varchar(255) NOT NULL,
  `tokenable_id` bigint(20) UNSIGNED NOT NULL,
  `name` text NOT NULL,
  `token` varchar(64) NOT NULL,
  `abilities` text DEFAULT NULL,
  `last_used_at` timestamp NULL DEFAULT NULL,
  `expires_at` timestamp NULL DEFAULT NULL,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `personal_access_tokens`
--

INSERT INTO `personal_access_tokens` (`id`, `tokenable_type`, `tokenable_id`, `name`, `token`, `abilities`, `last_used_at`, `expires_at`, `created_at`, `updated_at`) VALUES
(1, 'App\\Models\\User', 4, 'aswenna_auth_token', '042a094f2c6e14892484588d3c507e37ec1bb1a3ca2d8909cf3960c3cb566a06', '[\"*\"]', '2026-06-15 04:30:11', NULL, '2026-06-14 12:48:58', '2026-06-15 04:30:11'),
(2, 'App\\Models\\User', 6, 'aswenna_auth_token', '7dcddafab2945064c8e655a26a628562d24e96712401173e3613e05c8dff0332', '[\"*\"]', '2026-06-15 05:20:25', NULL, '2026-06-15 04:30:42', '2026-06-15 05:20:25'),
(3, 'App\\Models\\User', 4, 'aswenna_auth_token', 'a8c3f4a2ad0cb11b81a2dac336f13b0ee741afe415a984c95f850a255507f5c6', '[\"*\"]', '2026-06-15 05:28:12', NULL, '2026-06-15 05:21:02', '2026-06-15 05:28:12'),
(4, 'App\\Models\\User', 3, 'aswenna_auth_token', 'df3583d4db02578511e4abe2fbc0bd9b9f7be5e897514f241541f02485f87951', '[\"*\"]', '2026-06-16 15:31:26', NULL, '2026-06-16 15:31:23', '2026-06-16 15:31:26'),
(5, 'App\\Models\\User', 7, 'aswenna_auth_token', '8dcb53c85360337b1a55acf623c8b62c19ef7f43ecec3875ed588dfddb445ca4', '[\"*\"]', '2026-06-20 03:20:16', NULL, '2026-06-17 07:57:41', '2026-06-20 03:20:16'),
(6, 'App\\Models\\User', 7, 'aswenna_auth_token', '26e5f5d3ec3ef37a2dec4a3844368a2dbd65215a0f05127f1a33612bfabc03d9', '[\"*\"]', '2026-06-20 05:51:16', NULL, '2026-06-20 03:48:11', '2026-06-20 05:51:16'),
(7, 'App\\Models\\User', 3, 'aswenna_auth_token', 'c62936cde8aefb3cba8a7198ab13ce9780dfaf03da335e4460a40aa173f50806', '[\"*\"]', '2026-06-20 13:30:54', NULL, '2026-06-20 06:28:28', '2026-06-20 13:30:54'),
(8, 'App\\Models\\User', 4, 'aswenna_auth_token', '5d98894a0ca433bab22d2f60ba960622b4f36695aac911a6bb3b5f2c7ef7c2ac', '[\"*\"]', '2026-06-22 07:04:21', NULL, '2026-06-22 07:04:12', '2026-06-22 07:04:21'),
(9, 'App\\Models\\User', 3, 'aswenna_auth_token', 'ce0c12f47fb5c338136f42ee7125eed97a742b08ed3e3ce3a8cc2773d9a76f10', '[\"*\"]', '2026-06-23 03:05:01', NULL, '2026-06-22 07:37:21', '2026-06-23 03:05:01'),
(10, 'App\\Models\\User', 3, 'aswenna_auth_token', '3adecfd829be6f63b1cb3350fb2fa662ccebf4f429ef9e70988a6d005ac17494', '[\"*\"]', '2026-06-22 17:01:52', NULL, '2026-06-22 11:43:06', '2026-06-22 17:01:52'),
(11, 'App\\Models\\User', 6, 'aswenna_auth_token', 'f17635f33dc4eb68a92fec12e956822ab5dc0e629e4225ea9baf4e42d2a8b835', '[\"*\"]', '2026-06-24 03:08:57', NULL, '2026-06-23 03:11:53', '2026-06-24 03:08:57'),
(12, 'App\\Models\\User', 6, 'aswenna_auth_token', '30e1ffb23e0292d1f7972c69e8b5db75e025e99af03dc00cbebd6d2fa6ddf7ff', '[\"*\"]', '2026-06-24 03:56:01', NULL, '2026-06-24 03:20:24', '2026-06-24 03:56:01'),
(13, 'App\\Models\\User', 6, 'aswenna_auth_token', '5c3bc299987604bd0b73f0e3b5da728800a9697be1a32ebd5d57f1f0b7f2cb32', '[\"*\"]', '2026-06-24 04:46:08', NULL, '2026-06-24 04:09:47', '2026-06-24 04:46:08'),
(14, 'App\\Models\\User', 6, 'aswenna_auth_token', '2e8107d4977b56ff74e831dded1dcc626cb4fa47fe07282a4ef05c657019176b', '[\"*\"]', '2026-06-24 05:02:06', NULL, '2026-06-24 04:51:19', '2026-06-24 05:02:06'),
(15, 'App\\Models\\User', 6, 'aswenna_auth_token', '5d86bda3bde0eff7cb490fd2d95da3fd20e673dd1ad139f37bc1c2a3d11d50b8', '[\"*\"]', '2026-06-25 06:01:48', NULL, '2026-06-25 04:41:50', '2026-06-25 06:01:48'),
(16, 'App\\Models\\User', 5, 'aswenna_auth_token', 'd59431a7cbda602e37a24d81ea221e9401b7954e2cdbe53b586a53e5ea0c3938', '[\"*\"]', '2026-06-25 07:28:08', NULL, '2026-06-25 06:02:40', '2026-06-25 07:28:08'),
(17, 'App\\Models\\User', 5, 'aswenna_auth_token', 'c108e6922463785e4004b3370c9df975f123bde9950a7f02458069e67412ca2d', '[\"*\"]', '2026-06-26 16:07:13', NULL, '2026-06-26 03:41:37', '2026-06-26 16:07:13'),
(18, 'App\\Models\\User', 8, 'aswenna_auth_token', '6c832cad7e16eb34d8cafd9e6f0db0732249969012a7b6683daa2fbcbd7ba21f', '[\"*\"]', NULL, NULL, '2026-06-30 13:41:32', '2026-06-30 13:41:32'),
(19, 'App\\Models\\User', 8, 'aswenna_auth_token', '6b818fa7518c3167c0d5021eec7e70a29c2c1856cbbb3e31cfe13b9e5199d0c5', '[\"*\"]', '2026-06-30 14:37:05', NULL, '2026-06-30 13:42:05', '2026-06-30 14:37:05'),
(20, 'App\\Models\\User', 3, 'aswenna_auth_token', 'f96ab3f6963fce23e2833fd7421502d7622ac29f160c64f410652d5148f1da76', '[\"*\"]', '2026-06-30 14:46:03', NULL, '2026-06-30 14:38:55', '2026-06-30 14:46:03'),
(21, 'App\\Models\\User', 9, 'aswenna_auth_token', '03485ffd060ab0ea9ceda02d1af6f5bf0c76229252f46086950a32e46d5ed32c', '[\"*\"]', NULL, NULL, '2026-06-30 15:02:29', '2026-06-30 15:02:29'),
(22, 'App\\Models\\User', 9, 'aswenna_auth_token', 'ce1d23e23de96b05c759bd0d3f202d2dda921d875f3c2f7c6dea654d560f8f49', '[\"*\"]', '2026-06-30 15:31:05', NULL, '2026-06-30 15:02:57', '2026-06-30 15:31:05'),
(23, 'App\\Models\\User', 7, 'aswenna_auth_token', '8f742fd712932d3bae4bc4d45ae5f60ebae555147aa14929aff40566663dcccd', '[\"*\"]', '2026-06-30 16:01:10', NULL, '2026-06-30 15:36:33', '2026-06-30 16:01:10'),
(24, 'App\\Models\\User', 7, 'aswenna_auth_token', '44cd677d11eceb77f59d709ffcd9712b910228029613ed16afe21fc3b5574b90', '[\"*\"]', '2026-07-01 02:35:08', NULL, '2026-07-01 02:23:18', '2026-07-01 02:35:08'),
(25, 'App\\Models\\User', 2, 'aswenna_auth_token', '9d8c131fe7b6735dde2ed040dd4fe4fdf015b9a063aa66d26473a5e2e96524a9', '[\"*\"]', '2026-07-01 02:58:03', NULL, '2026-07-01 02:38:19', '2026-07-01 02:58:03'),
(26, 'App\\Models\\User', 10, 'aswenna_auth_token', 'ba007a2ee1d1eee583c43b00cb3377a7cd6491c80b77fa7cd352e2c301638e5d', '[\"*\"]', NULL, NULL, '2026-07-01 02:59:59', '2026-07-01 02:59:59'),
(27, 'App\\Models\\User', 10, 'aswenna_auth_token', 'cbaba037db749ff68c23899097018afef18f1c9ca6cb3e32b6d52f8e6f900b37', '[\"*\"]', '2026-07-01 03:10:00', NULL, '2026-07-01 03:04:52', '2026-07-01 03:10:00'),
(28, 'App\\Models\\User', 4, 'aswenna_auth_token', '8d3411ca61e07e148f114b5d041aee3aa0159bbcef7c71c0a127537ef70a4d89', '[\"*\"]', '2026-07-01 03:45:50', NULL, '2026-07-01 03:11:50', '2026-07-01 03:45:50'),
(29, 'App\\Models\\User', 9, 'aswenna_auth_token', 'b826ee3f6c60c756f788b68a79b717a4238426829362e6b429c5cd0bebadfabe', '[\"*\"]', '2026-07-01 03:52:53', NULL, '2026-07-01 03:50:54', '2026-07-01 03:52:53'),
(30, 'App\\Models\\User', 8, 'aswenna_auth_token', '94e8b33611dccd1b9d65ae7e2acd54ebee659878c77bb2b22fb5f182b4d00faa', '[\"*\"]', '2026-07-01 03:58:14', NULL, '2026-07-01 03:54:13', '2026-07-01 03:58:14'),
(31, 'App\\Models\\User', 6, 'aswenna_auth_token', '603e2b3f0f1a4125c6273a656f2930f97226810967129e31715885a876b25772', '[\"*\"]', '2026-07-01 04:02:12', NULL, '2026-07-01 03:59:20', '2026-07-01 04:02:12'),
(32, 'App\\Models\\User', 11, 'aswenna_auth_token', '38d590c1c2f52a72435322dc3534876fe3bc43b2b7acda20131e6bb2da8a7856', '[\"*\"]', NULL, NULL, '2026-07-01 04:03:53', '2026-07-01 04:03:53'),
(33, 'App\\Models\\User', 11, 'aswenna_auth_token', '1dc22c41f65bf4afebcc9d28182fae365bd560fc580b6028fb01f64b9e656463', '[\"*\"]', '2026-07-01 04:10:42', NULL, '2026-07-01 04:04:22', '2026-07-01 04:10:42'),
(34, 'App\\Models\\User', 6, 'aswenna_auth_token', '75261fd8bc61b8085a295f2fc15c1ea0c6aa422a359dc003c5b471eb37c75899', '[\"*\"]', '2026-07-01 04:12:15', NULL, '2026-07-01 04:11:59', '2026-07-01 04:12:15'),
(35, 'App\\Models\\User', 12, 'aswenna_auth_token', '10e0e2d4a5e0194d481b8c8ac8e28097527438771e91574d4a7e5b66c9efb87d', '[\"*\"]', NULL, NULL, '2026-07-01 04:13:22', '2026-07-01 04:13:22'),
(36, 'App\\Models\\User', 12, 'aswenna_auth_token', '7c1b57a5ccfeb3046fd6e896bb32bf8d351e029f6f5ac19e7631a9754f63f849', '[\"*\"]', '2026-07-01 04:17:37', NULL, '2026-07-01 04:13:46', '2026-07-01 04:17:37'),
(37, 'App\\Models\\User', 5, 'aswenna_auth_token', 'bf4a3b93f935624f4e4bcbf94f4081553361607e50229e9f89edd34f6cceca28', '[\"*\"]', '2026-07-01 04:57:05', NULL, '2026-07-01 04:18:59', '2026-07-01 04:57:05'),
(38, 'App\\Models\\User', 13, 'aswenna_auth_token', 'e65cd0e5db13b5aa5e4f5a5655b5d6b74892be5e2480c61e7092148bce611db2', '[\"*\"]', NULL, NULL, '2026-07-01 05:05:52', '2026-07-01 05:05:52'),
(39, 'App\\Models\\User', 13, 'aswenna_auth_token', 'af110b0f9adee84de00fef3c6ed853b6d9e09aa1845e61aec3b73626a7ae960e', '[\"*\"]', '2026-07-01 05:10:45', NULL, '2026-07-01 05:06:18', '2026-07-01 05:10:45'),
(40, 'App\\Models\\User', 14, 'aswenna_auth_token', 'abe05c2e27028acc84b8ecece7c50a60717715064d5e8f0fb982c444f8a015fe', '[\"*\"]', NULL, NULL, '2026-07-01 05:11:35', '2026-07-01 05:11:35'),
(41, 'App\\Models\\User', 14, 'aswenna_auth_token', '75b346d8279e2862db8fc1faa4c108c1c843ce096239bd2d752b4c09fa6f0483', '[\"*\"]', '2026-07-01 05:17:15', NULL, '2026-07-01 05:12:00', '2026-07-01 05:17:15');

-- --------------------------------------------------------

--
-- Table structure for table `retailer_customer_delivery_partner_reviews`
--

CREATE TABLE `retailer_customer_delivery_partner_reviews` (
  `id` bigint(20) UNSIGNED NOT NULL,
  `reviewed_to` bigint(20) UNSIGNED NOT NULL,
  `reviewed_by` bigint(20) UNSIGNED NOT NULL,
  `order_id` bigint(20) UNSIGNED NOT NULL,
  `feedback` text NOT NULL,
  `ratings` tinyint(3) UNSIGNED NOT NULL,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `retailer_customer_delivery_partner_reviews`
--

INSERT INTO `retailer_customer_delivery_partner_reviews` (`id`, `reviewed_to`, `reviewed_by`, `order_id`, `feedback`, `ratings`, `created_at`, `updated_at`) VALUES
(1, 4, 6, 1, 'Good packaging, fast processing!', 5, '2026-06-14 10:57:30', '2026-06-14 10:57:30'),
(2, 3, 6, 1, 'good', 4, '2026-06-15 05:20:03', '2026-06-15 05:20:03'),
(3, 5, 6, 1, 'good', 4, '2026-06-15 05:20:12', '2026-06-15 05:20:12'),
(4, 5, 4, 1, 'excellent', 4, '2026-06-15 05:28:11', '2026-06-15 05:28:11'),
(5, 5, 3, 1, 'ghgfh', 3, '2026-06-22 16:44:13', '2026-06-22 16:44:13');

-- --------------------------------------------------------

--
-- Table structure for table `retailer_products`
--

CREATE TABLE `retailer_products` (
  `id` bigint(20) UNSIGNED NOT NULL,
  `seller_id` bigint(20) UNSIGNED NOT NULL,
  `crop_id` bigint(20) UNSIGNED NOT NULL,
  `description` text DEFAULT NULL,
  `thumbnail_path` varchar(255) DEFAULT NULL,
  `product_name` varchar(255) NOT NULL,
  `price_per_unit` decimal(10,2) NOT NULL,
  `discount_price_per_unit` decimal(10,2) DEFAULT NULL,
  `stock_quantity` decimal(10,2) NOT NULL,
  `unit_type` enum('kg','g','liter','ml') NOT NULL,
  `grade` enum('A','B','C') NOT NULL,
  `status` enum('active','inactive','out_of_stock') NOT NULL DEFAULT 'active',
  `image_paths` longtext CHARACTER SET utf8mb4 COLLATE utf8mb4_bin DEFAULT NULL CHECK (json_valid(`image_paths`)),
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `retailer_products`
--

INSERT INTO `retailer_products` (`id`, `seller_id`, `crop_id`, `description`, `thumbnail_path`, `product_name`, `price_per_unit`, `discount_price_per_unit`, `stock_quantity`, `unit_type`, `grade`, `status`, `image_paths`, `created_at`, `updated_at`) VALUES
(1, 4, 3, 'Fresh premium Nuwara Eliya potatoes packed from local harvests.', 'retailer-products/4/XyK1qNh8NEsjZJoWD9qKSHK4AJ36Rc0OVEpe1hSZ.jpg', 'Nuwara Eliya Red Potatoes', 290.00, 275.00, 447.60, 'kg', 'A', 'active', '[\"retailer-products\\/4\\/8iWnPxxw8x6htuzm0U4RMFMQrTiHKvcLwRgKAN1q.jpg\"]', '2026-06-14 10:57:30', '2026-06-25 05:21:08'),
(2, 4, 2, 'Sweet crisp local carrots, perfect for culinary uses.', 'retailer-products/4/zNpnx32mInhp8Dg6BjomKAhybo5JHAAgXkdFSwFz.jpg', 'Nuwara Eliya Crisp Carrots', 380.00, NULL, 250.00, 'kg', 'A', 'active', '[\"retailer-products\\/4\\/BgpuSX9VFP2cN1XNIvuiYvfkWi3nhhU91HnVdeCa.jpg\"]', '2026-06-14 10:57:30', '2026-06-14 12:51:40'),
(3, 3, 1, 'dffhfghfgff fghfghfghfghfgh fhhfgj', 'retailer-products/3/9aItSGvW20YIYI1hrFZPDsdBcAO9ETjXDfHnP0ar.jpg', 'Fresh Paddy', 260.00, NULL, 60.00, 'kg', 'A', 'active', '[\"retailer-products\\/3\\/3ETJTjwLfqJbwKEqcIxDzrUTad81eGkgSpoCiYFz.jpg\"]', '2026-06-22 16:24:31', '2026-06-22 16:57:48');

-- --------------------------------------------------------

--
-- Table structure for table `retail_seller_verification_data`
--

CREATE TABLE `retail_seller_verification_data` (
  `id` bigint(20) UNSIGNED NOT NULL,
  `user_id` bigint(20) UNSIGNED NOT NULL,
  `br_number` varchar(255) DEFAULT NULL,
  `br_image_path` varchar(255) DEFAULT NULL,
  `br_issue_date` date DEFAULT NULL,
  `br_expiry_date` date DEFAULT NULL,
  `business_type` varchar(255) DEFAULT NULL,
  `shop_address` varchar(255) DEFAULT NULL,
  `shop_photos` longtext CHARACTER SET utf8mb4 COLLATE utf8mb4_bin DEFAULT NULL CHECK (json_valid(`shop_photos`)),
  `postal_code` varchar(255) DEFAULT NULL,
  `latitude` decimal(10,8) DEFAULT NULL,
  `longitude` decimal(11,8) DEFAULT NULL,
  `ownership_type` varchar(255) DEFAULT NULL,
  `status` varchar(255) NOT NULL DEFAULT 'pending',
  `rejected_reason` text DEFAULT NULL,
  `notes` text DEFAULT NULL,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `retail_seller_verification_data`
--

INSERT INTO `retail_seller_verification_data` (`id`, `user_id`, `br_number`, `br_image_path`, `br_issue_date`, `br_expiry_date`, `business_type`, `shop_address`, `shop_photos`, `postal_code`, `latitude`, `longitude`, `ownership_type`, `status`, `rejected_reason`, `notes`, `created_at`, `updated_at`) VALUES
(1, 4, 'BR-8849', 'retail-seller-verifications/4/JUzm7qkLIBX2hmW12SWyD7vyllFc0hSrH5mzULws.jpg', '2024-06-14', '2031-06-14', 'sole_proprietorship', '78, Weligatta, Weerawila', '[\"retail-seller-shops\\/4\\/8tYCecjHAZQ19ER4htiniatoyRc038KOgbTb5PZJ.jpg\",\"retail-seller-shops\\/4\\/FLBuP5qdEQOjNlj36GAphqMYr12dCBSdCPGnN09k.webp\",\"retail-seller-shops\\/4\\/x17Ns0dYc4L3OQcaLmzbA4N3gD01oUi4FAKxTI1e.jpg\"]', '80632', 6.24208190, 81.22982490, 'owned', 'verified', NULL, NULL, '2026-06-14 10:57:29', '2026-07-01 03:49:22'),
(3, 3, '212', 'retail-seller-verifications/3/bw6TMs7uox41Zooy2sR5Qj30cT6WWg8e31C2CDS1.jpg', '2026-06-01', '2028-06-22', 'partnership', 'sfddvf df', '[\"retail-seller-shops\\/3\\/zn54pacOJtTppNxqbt2EFbcMrkiYvNArRPREkKR9.jpg\"]', '3434', 6.22900560, 80.06233980, 'rental', 'verified', NULL, 'azdadadfafadfsdfdf', '2026-06-22 08:32:15', '2026-06-22 08:32:55'),
(4, 9, 'BR-89872', 'retail-seller-verifications/9/x3ly73XBBFUmJfgTFvgAfwZy3BPukcvU2KWhNYkp.jpg', '2026-07-01', '2027-07-01', 'sole_proprietorship', '283, Bundala, hambantota', '[\"retail-seller-shops\\/9\\/6xq1sF4E2egrkPlfXgirXCMZ72ROdyE5SFP0fvKc.jpg\",\"retail-seller-shops\\/9\\/F4FRCXAhrOYFpQHXD0DwmGi3QNHNa30VsqVTV6Gl.webp\"]', '87666', 6.19908630, 81.21049350, 'owned', 'verified', NULL, NULL, '2026-07-01 03:51:01', '2026-07-01 03:53:11'),
(5, 8, 'BR-66728', 'retail-seller-verifications/8/WaBVpM4ywuHC6CtwXhwpBsvDlCEDDe2m0XlqMtda.jpg', '2025-07-01', '2028-07-01', 'sole_proprietorship', '72/B, New Town, Hambantota', '[\"retail-seller-shops\\/8\\/YYYkiNemP0K5MstXvKxpAhzgX17z3b13IqwZSG1P.jpg\",\"retail-seller-shops\\/8\\/bJU9GV8ZMgkrVkIf2AXZwCyuuU1USRNw7uM8EsAg.jpg\"]', '87656', 6.12594140, 81.12477300, 'owned', 'verified', NULL, NULL, '2026-07-01 03:54:20', '2026-07-01 03:56:14');

-- --------------------------------------------------------

--
-- Table structure for table `sessions`
--

CREATE TABLE `sessions` (
  `id` varchar(255) NOT NULL,
  `user_id` bigint(20) UNSIGNED DEFAULT NULL,
  `ip_address` varchar(45) DEFAULT NULL,
  `user_agent` text DEFAULT NULL,
  `payload` longtext NOT NULL,
  `last_activity` int(11) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `sessions`
--

INSERT INTO `sessions` (`id`, `user_id`, `ip_address`, `user_agent`, `payload`, `last_activity`) VALUES
('a33jKNeSzVJKDPNqqBkMe8cwTrdyaadLWQSh6lv4', 1, '127.0.0.1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/149.0.0.0 Safari/537.36', 'YTo1OntzOjY6Il90b2tlbiI7czo0MDoick9hRmxUcUdHMXZrbVhrYXdST0xQTDhxYUpmcjRDaWdDV1dycTZJSyI7czo5OiJfcHJldmlvdXMiO2E6Mjp7czozOiJ1cmwiO3M6NDM6Imh0dHA6Ly8xMjcuMC4wLjE6ODAwMS9hZG1pbi9kYXNoYm9hcmQvc3RhdHMiO3M6NToicm91dGUiO3M6MjE6ImFkbWluLmRhc2hib2FyZC5zdGF0cyI7fXM6NjoiX2ZsYXNoIjthOjI6e3M6Mzoib2xkIjthOjA6e31zOjM6Im5ldyI7YTowOnt9fXM6NTA6ImxvZ2luX3dlYl81OWJhMzZhZGRjMmIyZjk0MDE1ODBmMDE0YzdmNThlYTRlMzA5ODlkIjtpOjE7czoxMzoiYWRtaW5fc2Vzc2lvbiI7YTo0OntzOjc6InVzZXJfaWQiO2k6MTtzOjg6InVzZXJuYW1lIjtzOjE5OiJTYXZpbmR1IEFiZXlzb29yaXlhIjtzOjU6ImVtYWlsIjtzOjIwOiJzYXZpbmR1MTQ3QGdtYWlsLmNvbSI7czoxMjoibG9nZ2VkX2luX2F0IjtPOjI1OiJJbGx1bWluYXRlXFN1cHBvcnRcQ2FyYm9uIjozOntzOjQ6ImRhdGUiO3M6MjY6IjIwMjYtMDctMDEgMDc6NTE6MDguMjE3NjcyIjtzOjEzOiJ0aW1lem9uZV90eXBlIjtpOjM7czo4OiJ0aW1lem9uZSI7czoxMjoiQXNpYS9Db2xvbWJvIjt9fX0=', 1782883110);

-- --------------------------------------------------------

--
-- Table structure for table `users`
--

CREATE TABLE `users` (
  `id` bigint(20) UNSIGNED NOT NULL,
  `full_name` varchar(255) NOT NULL,
  `email` varchar(255) DEFAULT NULL,
  `phone_number` varchar(255) NOT NULL,
  `phone_number_2` varchar(255) DEFAULT NULL,
  `password` varchar(255) NOT NULL,
  `profile_picture_path` varchar(255) DEFAULT NULL,
  `national_id` varchar(255) DEFAULT NULL,
  `address` varchar(255) DEFAULT NULL,
  `city` varchar(255) DEFAULT NULL,
  `district` varchar(255) DEFAULT NULL,
  `province` varchar(255) DEFAULT NULL,
  `latitude` decimal(10,8) DEFAULT NULL,
  `longitude` decimal(11,8) DEFAULT NULL,
  `role` longtext CHARACTER SET utf8mb4 COLLATE utf8mb4_bin DEFAULT NULL CHECK (json_valid(`role`)),
  `is_verified` tinyint(1) NOT NULL DEFAULT 0,
  `is_active` tinyint(1) NOT NULL DEFAULT 1,
  `email_verified_at` timestamp NULL DEFAULT NULL,
  `phone_verified_at` timestamp NULL DEFAULT NULL,
  `phone_number_2_verified_at` timestamp NULL DEFAULT NULL,
  `last_login_at` timestamp NULL DEFAULT NULL,
  `remember_token` varchar(100) DEFAULT NULL,
  `fcm_token` varchar(255) DEFAULT NULL,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `users`
--

INSERT INTO `users` (`id`, `full_name`, `email`, `phone_number`, `phone_number_2`, `password`, `profile_picture_path`, `national_id`, `address`, `city`, `district`, `province`, `latitude`, `longitude`, `role`, `is_verified`, `is_active`, `email_verified_at`, `phone_verified_at`, `phone_number_2_verified_at`, `last_login_at`, `remember_token`, `fcm_token`, `created_at`, `updated_at`) VALUES
(1, 'Savindu Abeysooriya', 'savindu147@gmail.com', '0772892789', '0703322806', '$2y$12$7tK9I39iytEF6BaOcR8gbOB/dsxmZIsBjmJnhp4baVqyoCsYLbCZC', 'profiles/1KYY1blOR3niFu4DGc11AxQ3vLgBGH7UePxoDvrs.jpg', '200311800738', '20/A, Karolis Weda Mawatha,Tuduwamulla,Ambalangoda', 'Ambalangoda', 'Galle', 'Southern', 6.23439200, 80.05485400, '[\"admin\"]', 1, 1, NULL, '2026-06-29 08:01:03', '2026-06-29 08:01:06', NULL, 'QpWWSWu3Rdf0MfKBqRN25N4yTyHhU1ChuKTIgyMbFgUYx7UlZVuglsN6gN7h', NULL, '2026-06-14 10:57:28', '2026-06-29 08:01:06'),
(2, 'Isuru Kawshalya', 'isuru@gmail.com', '0775678902', '0725789736', '$2y$12$7tK9I39iytEF6BaOcR8gbOB/dsxmZIsBjmJnhp4baVqyoCsYLbCZC', 'profile-pictures/2/GMrhZTa0jZ5Zitdd6m68y8r6yLlMiq99yjo1PxzE.jpg', '200067876518', '123, Weerawila', 'Tissamaharama', 'Hambantota', 'Southern', 6.24214940, 81.22920900, '[\"farmer\"]', 1, 1, NULL, NULL, NULL, '2026-07-01 02:38:19', NULL, 'efltRdRrTIyn20KyMZOHKX:APA91bEwzB_ZRHhbHMHzIrT98bFJZgMKbJUhEQmshoYTV__sYfqQzsePvIKwE2GH4gArrakiQfJ1mZXX4lVMCWWjp5x1EA8adNRIkMhVV2yRiCYPVyvDnG8', '2026-06-14 10:57:28', '2026-07-01 02:58:20'),
(3, 'Amal Perera', 'amal@gmail.com', '0777234567', '0776756789', '$2y$12$.jVYIjCCWEljThCw57ARw.BXaQfhhDTkjxCdhoKVZIV6Y8UYIcmnS', 'profile-pictures/3/Kt8a15Xl20khpBZaTTtPsxI8JusRUoR1HbGS8DY5.jpg', '196725678825', '20/A, Lunugamwehera', 'Tissamaharama', 'Hambantota', 'Southern', 6.45949900, 81.20781640, '[\"buyer\"]', 1, 1, NULL, '2026-06-22 08:32:58', '2026-06-22 08:33:01', '2026-06-30 14:38:55', NULL, NULL, '2026-06-14 10:57:28', '2026-06-30 14:45:31'),
(4, 'Maleesha Perera', 'maleesha@gmail.com', '0777345678', '0786654567', '$2y$12$tKv5kLo9TIpUuQUIBS793euGc31UfMPEwdaM3H/bwCZbf.zjvBgX6', 'profile-pictures/4/UEN9rsDh6Df7VJQjORh74srTXjjy7r1WyurHCYal.jpg', '199987876525v', '78, Weligatta, Weerawila', 'Weerawila', 'Hambantota', 'Southern', 6.24208190, 81.22982490, '[\"retail_seller\"]', 1, 1, NULL, '2026-06-16 11:59:26', NULL, '2026-07-01 03:11:50', NULL, NULL, '2026-06-14 10:57:29', '2026-07-01 03:49:22'),
(5, 'Priyantha Mahaulpathagama', 'priyantha@gmail.com', '0777456789', '0772456763', '$2y$12$aMjfvGeWmUh1PhfGaSDvCu78QPpRuYY3wKUsJka1P1r46cGpVUcRa', 'profile-pictures/5/5uCH38piwDkvQSAcbSUX7DuedH6BmdPvSrcT1MfV.jpg', '0723546465', '22, Dewramwehera, Mattala', 'Tissamaharama', 'Hambantota', 'Southern', 6.30515430, 81.11409120, '[\"delivery_partner\"]', 1, 1, NULL, '2026-06-25 06:33:10', '2026-06-25 06:33:12', '2026-07-01 04:18:59', NULL, NULL, '2026-06-14 10:57:29', '2026-07-01 05:10:20'),
(6, 'Kaweesha Mendis', 'kaweesha@gmail.com', '0777567890', '0776564536', '$2y$12$MM8lVBi4BcSHGFJKXEEw.uLleI.CrvvByzKQp6NoO2NcTR6u1qqaO', 'profile-pictures/6/LgOCHLehUtBbOtt6CkmtHXj5GG6uASf4B1BBKBKB.jpg', '20032299988887', '99/A, Sama Mawatha, Lunugamwehera', 'Tissamaharama', 'Hambantota', 'Southern', 6.24214940, 81.22920900, '[\"customer\"]', 1, 1, NULL, '2026-06-23 03:27:01', '2026-06-23 03:27:04', '2026-07-01 04:11:59', NULL, NULL, '2026-06-14 10:57:29', '2026-07-01 04:12:23'),
(7, 'Saranga Disasekara', 'saranga@gmail.com', '0703322806', '0772892789', '$2y$12$7tK9I39iytEF6BaOcR8gbOB/dsxmZIsBjmJnhp4baVqyoCsYLbCZC', 'profile-pictures/7/wkP0DoUKfV2btRcsWzpWcJfwB47EOrr8E0Nw5v1D.jpg', '198078987626', '20/A, Beralihela, Tissamaharama', 'Tissamaharama', 'Hambantota', 'Southern', 6.32422833, 81.30246084, '[\"farmer\"]', 1, 1, NULL, '2026-06-20 07:10:54', '2026-06-20 07:10:59', '2026-07-01 02:23:18', NULL, 'efltRdRrTIyn20KyMZOHKX:APA91bEwzB_ZRHhbHMHzIrT98bFJZgMKbJUhEQmshoYTV__sYfqQzsePvIKwE2GH4gArrakiQfJ1mZXX4lVMCWWjp5x1EA8adNRIkMhVV2yRiCYPVyvDnG8', '2026-06-17 07:57:41', '2026-07-01 02:37:05'),
(8, 'Sunil Perera', 'sunil@gmail.com', '0472272897', '0772727896', '$2y$12$7tK9I39iytEF6BaOcR8gbOB/dsxmZIsBjmJnhp4baVqyoCsYLbCZC', 'profile-pictures/8/SPCU9FdWTSLv7dZK9K8iDEdFHGiKt1cxwnRVUjZ7.jpg', '196056718815v', '281/1,Pannegamuwa', 'weerawila', 'Hambantota', 'Southern', 6.12594140, 81.12477300, '[\"buyer\",\"retail_seller\"]', 1, 1, NULL, '2026-06-30 14:34:40', '2026-06-30 14:34:43', '2026-07-01 03:54:13', NULL, NULL, '2026-06-30 13:41:32', '2026-07-01 03:56:14'),
(9, 'Rookantha Gunathilake', 'rookantha@gmail.com', '0776765678', '0756767890', '$2y$12$VRmH2YIb.mD1fmqoIIQXGeV0b26qtGEyMVrBaou6NFF2VmiIISXNe', 'profile-pictures/9/nTe5OTl5YcllBOeM69h9pXyI8pCQXrPsWwtJBHjx.jpg', '195678765673', '167/A, Mahasenpura', 'Tissamaharama', 'Moneragala', 'Uva', 6.19908630, 81.21049350, '[\"buyer\",\"retail_seller\"]', 1, 1, NULL, '2026-06-30 15:28:50', '2026-06-30 15:28:53', '2026-07-01 03:50:54', NULL, NULL, '2026-06-30 15:02:29', '2026-07-01 03:53:11'),
(10, 'Wimal Weerawansha', 'wimal@gmail.com', '0775656589', '075898952', '$2y$12$LxK/CdS5X818jAcep56DX.5xvICwSsVKqQtjaTDbxBPUZImLCJscm', 'profile-pictures/10/TPF36gSAnoYXl0x9BWEKAfag53NiNzkKKV4WqZqw.jpg', '195678987654v', '28/b, Mattala', 'Tissamaharama', 'Hambantota', 'Southern', 6.30515430, 81.11409120, '[\"farmer\"]', 1, 1, NULL, NULL, NULL, '2026-07-01 03:04:52', NULL, 'efltRdRrTIyn20KyMZOHKX:APA91bEwzB_ZRHhbHMHzIrT98bFJZgMKbJUhEQmshoYTV__sYfqQzsePvIKwE2GH4gArrakiQfJ1mZXX4lVMCWWjp5x1EA8adNRIkMhVV2yRiCYPVyvDnG8', '2026-07-01 02:59:59', '2026-07-01 03:10:10'),
(11, 'Thimila Kaweeshwara', 'thimila@gmail.com', '07734343456', '07767676534', '$2y$12$1LqGZW/.TKlWyoBHzNZGzO8yFuT1i6njZ3xeYttroHtxdlZ9Sm7UK', 'profile-pictures/11/g2haWiOuKrrtQEbKlNcS5dG43QQ5KNzxNLEKfwMc.jpg', '200322777898', '20/B, Mahindapura, Pannegamuwa', 'Tissamaharama', 'Hambantota', 'Southern', 8.34541200, 80.38922936, '[\"customer\"]', 1, 1, NULL, NULL, NULL, '2026-07-01 04:04:22', NULL, NULL, '2026-07-01 04:03:53', '2026-07-01 04:10:52'),
(12, 'Isira Widusha', 'isira@gmail.com', '0765676535', '0745653434', '$2y$12$Cbm7lUmB3PYB4nuvoFOONuVc595eeZMM0EezerNByf.rnBTDF9QAy', 'profile-pictures/12/utXobI7UuumK1lqASb1SzwFzXFY6w7IAqq610xQv.jpg', '200178722675', '111, Old Town, Thanamalwila', 'Tanamalwila', 'Moneragala', 'Uva', 6.43489970, 81.13085460, '[\"customer\"]', 1, 1, NULL, NULL, NULL, '2026-07-01 04:13:46', NULL, NULL, '2026-07-01 04:13:22', '2026-07-01 04:17:48'),
(13, 'Jehan Perera', 'jehan@gmail.com', '0773678767', '0723578947', '$2y$12$XZ57LbTwtB7ZlhonNuLzce/QjkHMBOBwb9wYtxQ0ny1e6v.WuUssS', 'profile-pictures/13/P99P7EAnjSF4CclthciR8CV3YFGOaiFaeLxdGGR3.jpg', '197782973626v', '43/B, Hospital road, Hambantota', 'Hambantota', 'Hambantota', 'Southern', 6.12594140, 81.12477300, '[\"delivery_partner\"]', 1, 1, NULL, NULL, NULL, '2026-07-01 05:06:18', NULL, NULL, '2026-07-01 05:05:52', '2026-07-01 05:09:59'),
(14, 'Namal Rajapakshe', 'namal@gmail.com', '0726677567', '0745665345', '$2y$12$oN3d8QX.bGguWpCUmYdwTe6zehc3RmsTE45LOrHGzS412Nt9yPdvq', 'profile-pictures/14/eeuBMBwOQY7anMFvPM3CDbmttc0jMyqPxeRMZIiZ.jpg', '197067867634', '20/D, Kalton Home, Tangalle', 'Tangalle', 'Hambantota', 'Southern', 6.02854880, 80.79465800, '[\"delivery_partner\"]', 1, 1, NULL, NULL, NULL, '2026-07-01 05:12:00', NULL, NULL, '2026-07-01 05:11:35', '2026-07-01 05:17:40');

-- --------------------------------------------------------

--
-- Table structure for table `user_offer_progress`
--

CREATE TABLE `user_offer_progress` (
  `id` bigint(20) UNSIGNED NOT NULL,
  `offer_campaign_id` bigint(20) UNSIGNED NOT NULL,
  `user_id` bigint(20) UNSIGNED NOT NULL,
  `is_completed` tinyint(1) NOT NULL DEFAULT 0,
  `completed_at` datetime DEFAULT NULL,
  `reward_claimed` tinyint(1) NOT NULL DEFAULT 0,
  `reward_claimed_at` datetime DEFAULT NULL,
  `reward_claimed_activity_type` varchar(255) DEFAULT NULL,
  `reward_claimed_activity_id` bigint(20) UNSIGNED DEFAULT NULL,
  `notes` text DEFAULT NULL,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `user_offer_progress`
--

INSERT INTO `user_offer_progress` (`id`, `offer_campaign_id`, `user_id`, `is_completed`, `completed_at`, `reward_claimed`, `reward_claimed_at`, `reward_claimed_activity_type`, `reward_claimed_activity_id`, `notes`, `created_at`, `updated_at`) VALUES
(1, 1, 4, 0, NULL, 0, NULL, NULL, NULL, 'Currently listed 3 products.', '2026-06-14 10:57:30', '2026-06-14 10:57:30');

-- --------------------------------------------------------

--
-- Table structure for table `user_verification_documents`
--

CREATE TABLE `user_verification_documents` (
  `id` bigint(20) UNSIGNED NOT NULL,
  `user_id` bigint(20) UNSIGNED NOT NULL,
  `document_type` varchar(255) NOT NULL,
  `front_image_path` varchar(255) NOT NULL,
  `back_image_path` varchar(255) DEFAULT NULL,
  `verification_status` varchar(255) NOT NULL DEFAULT 'pending',
  `rejection_reason` text DEFAULT NULL,
  `verified_at` timestamp NULL DEFAULT NULL,
  `verified_by` bigint(20) UNSIGNED DEFAULT NULL,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `user_verification_documents`
--

INSERT INTO `user_verification_documents` (`id`, `user_id`, `document_type`, `front_image_path`, `back_image_path`, `verification_status`, `rejection_reason`, `verified_at`, `verified_by`, `created_at`, `updated_at`) VALUES
(11, 1, 'national_id', 'verifications/e7bVTuwPT9KS7wjXU3SAiBVBfsihIzewfjhgUZch.jpg', 'verifications/MHkgjUOC5uxWn3bE40h2fJFzxoHblxq87ttIiLud.jpg', 'approved', NULL, '2026-06-29 08:01:09', 1, '2026-06-29 07:58:04', '2026-06-29 08:01:09'),
(12, 8, 'National ID', 'buyer-verifications/8/A5uMONikzZ3pgDVlX5OcKTuV2eJgIPguwzsj4Lcx.jpg', 'buyer-verifications/8/WKSUGPt6277SkA6zh5E9RNnE5KABhBdDamRPnW3T.jpg', 'approved', NULL, '2026-06-30 14:34:26', 1, '2026-06-30 14:34:15', '2026-06-30 14:34:26'),
(13, 3, 'National ID', 'buyer-verifications/3/sngUs2TBAEYapPA3t4msk96V9K408TQisq9rQj75.jpg', 'buyer-verifications/3/2WFYD2uoc9iSS6bYoeSiMuamI0fLNPWAkcSLTykl.jpg', 'approved', NULL, '2026-06-30 14:45:31', 1, '2026-06-30 14:45:17', '2026-06-30 14:45:31'),
(14, 9, 'National ID', 'buyer-verifications/9/VoULSKzlTw8ixfGvnYyvUZJX9vGUvekVFIQIX6Dx.jpg', 'buyer-verifications/9/b7VEUBbtsHTIqSxUGDWwAQSO1FSYyh9t6ljiAIOq.jpg', 'approved', NULL, '2026-06-30 15:28:39', 1, '2026-06-30 15:28:09', '2026-06-30 15:28:39'),
(15, 7, 'national_id', 'farmer-verifications/7/GlqDafPgZBRGS7lcUgXndhpxXF60RuGd2n4GY980.jpg', 'farmer-verifications/7/P2o6zaQvba5k1rgPeEb531rlUSJUV2rLXp4hIqZj.jpg', 'approved', NULL, '2026-07-01 02:37:05', 1, '2026-06-30 16:01:10', '2026-07-01 02:37:05'),
(16, 2, 'national_id', 'farmer-verifications/2/ef7nL3QT1vZQavzfBN3EG17gDpqf5TIJnkJDOTxF.jpg', 'farmer-verifications/2/tVpALWVXXj3wyLIkD6c0HM79juop5BCGizp9PTlZ.jpg', 'approved', NULL, '2026-07-01 02:58:20', 1, '2026-07-01 02:57:31', '2026-07-01 02:58:20'),
(17, 10, 'national_id', 'farmer-verifications/10/4efHeGG5qGmJzh8MV834Wu3US5h0O8cn2YlyCmKf.jpg', 'farmer-verifications/10/oNhE8ef7vNX128GHA9sHirDr2mCs42chrZDU8SwF.jpg', 'approved', NULL, '2026-07-01 03:10:10', 1, '2026-07-01 03:08:03', '2026-07-01 03:10:10'),
(18, 4, 'national_id', 'retail-seller-verifications/4/olpK4GGzbLrxBZ5qmhdMBgqeK3Cs9Z7vcaiIDeSv.jpg', 'retail-seller-verifications/4/iaoy6skV84uKx2LRh3h8qmxOUnievbAyJa4QBCLE.jpg', 'approved', NULL, '2026-07-01 03:49:22', 1, '2026-07-01 03:35:53', '2026-07-01 03:49:22'),
(19, 6, 'National ID', 'buyer-verifications/6/uu12Ir7tjUNtynRjo5K8gPBRUdJswrkBHySwKgbh.jpg', 'buyer-verifications/6/A5mCSDhWkoaHypw86eiitwA6RDGIUQDx7ytIYzrb.jpg', 'approved', NULL, '2026-07-01 04:02:47', 1, '2026-07-01 04:02:02', '2026-07-01 04:02:47'),
(20, 11, 'National ID', 'buyer-verifications/11/UUvg91vdrgrkKDhGXZc0Xmxf994EJ3ZeqadAjt3E.jpg', 'buyer-verifications/11/xCyQoOkTbB4fIZSCGhtkcopMVohJYYoYkXqBCvfu.jpg', 'approved', NULL, '2026-07-01 04:10:52', 1, '2026-07-01 04:10:20', '2026-07-01 04:10:52'),
(21, 12, 'National ID', 'buyer-verifications/12/QSpnlGW23ErT7Vswbl8WTVpSlemFFnj4JYAS3DbA.jpg', 'buyer-verifications/12/OonVSDUrkvLIO1zEUW6hwc8tPIO35wUwiUledpbU.jpg', 'approved', NULL, '2026-07-01 04:17:48', 1, '2026-07-01 04:17:38', '2026-07-01 04:17:48'),
(22, 5, 'driving_license', 'delivery-partner-license/5/AVDC4YATmAenJFklWQm2lEicBxIK92FvYUEAidFw.jpg', 'delivery-partner-license/5/3TUp1znuJYs66Mf6oOUdkuicSLsZXhQyHb0qi5x1.jpg', 'approved', NULL, '2026-07-01 05:10:20', 1, '2026-07-01 04:52:57', '2026-07-01 05:10:20'),
(23, 13, 'driving_license', 'delivery-partner-license/13/DSUvzqMqzV4lgl0zgg1DnJiwnvK5YcQw4CKcySbB.jpg', 'delivery-partner-license/13/XwgUpNA5MZKNP8dRwfI9jyHbVToPjtSVZQMcweAB.jpg', 'approved', NULL, '2026-07-01 05:09:59', 1, NULL, '2026-07-01 05:09:59'),
(24, 14, 'driving_license', 'delivery-partner-license/14/H9tHb1EyjCyUpkeOZZlxIx20sOysJUxf72INH9ln.jpg', 'delivery-partner-license/14/hixYUcTyoLJupHfpmM6EkM5CvkAwu4sT6xTzTzzh.jpg', 'approved', NULL, '2026-07-01 05:17:40', 1, NULL, '2026-07-01 05:17:40');

-- --------------------------------------------------------

--
-- Table structure for table `user_wallets`
--

CREATE TABLE `user_wallets` (
  `id` bigint(20) UNSIGNED NOT NULL,
  `user_id` bigint(20) UNSIGNED NOT NULL,
  `available_balance` decimal(12,2) NOT NULL DEFAULT 0.00,
  `pending_balance` decimal(12,2) NOT NULL DEFAULT 0.00,
  `total_earned` decimal(12,2) NOT NULL DEFAULT 0.00,
  `total_withdrawn` decimal(12,2) NOT NULL DEFAULT 0.00,
  `last_updated_at` timestamp NULL DEFAULT NULL,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `user_wallets`
--

INSERT INTO `user_wallets` (`id`, `user_id`, `available_balance`, `pending_balance`, `total_earned`, `total_withdrawn`, `last_updated_at`, `created_at`, `updated_at`) VALUES
(1, 2, 50000.00, 0.00, 50000.00, 0.00, NULL, '2026-06-14 10:57:29', '2026-06-14 10:57:29'),
(2, 3, 10000.00, 0.00, 10000.00, 0.00, NULL, '2026-06-14 10:57:29', '2026-06-14 10:57:29'),
(3, 4, 50627.00, 0.00, 50627.00, 0.00, '2026-06-25 05:26:05', '2026-06-14 10:57:29', '2026-06-25 05:26:05'),
(4, 5, 50000.00, 0.00, 50000.00, 0.00, NULL, '2026-06-14 10:57:29', '2026-06-14 10:57:29'),
(5, 6, 48171.97, 0.00, 50000.00, 0.00, '2026-06-25 05:26:05', '2026-06-14 10:57:30', '2026-06-25 05:26:05'),
(6, 7, 0.00, 0.00, 0.00, 0.00, '2026-06-17 07:57:41', '2026-06-17 07:57:41', '2026-06-17 07:57:41'),
(7, 8, 0.00, 0.00, 0.00, 0.00, '2026-06-30 13:41:32', '2026-06-30 13:41:32', '2026-06-30 13:41:32'),
(8, 9, 0.00, 0.00, 0.00, 0.00, '2026-06-30 15:02:29', '2026-06-30 15:02:29', '2026-06-30 15:02:29'),
(9, 10, 0.00, 0.00, 0.00, 0.00, '2026-07-01 02:59:59', '2026-07-01 02:59:59', '2026-07-01 02:59:59'),
(10, 11, 0.00, 0.00, 0.00, 0.00, '2026-07-01 04:03:53', '2026-07-01 04:03:53', '2026-07-01 04:03:53'),
(11, 12, 0.00, 0.00, 0.00, 0.00, '2026-07-01 04:13:22', '2026-07-01 04:13:22', '2026-07-01 04:13:22'),
(12, 13, 0.00, 0.00, 0.00, 0.00, '2026-07-01 05:05:52', '2026-07-01 05:05:52', '2026-07-01 05:05:52'),
(13, 14, 0.00, 0.00, 0.00, 0.00, '2026-07-01 05:11:35', '2026-07-01 05:11:35', '2026-07-01 05:11:35');

-- --------------------------------------------------------

--
-- Table structure for table `wallet_transactions`
--

CREATE TABLE `wallet_transactions` (
  `id` bigint(20) UNSIGNED NOT NULL,
  `user_id` bigint(20) UNSIGNED NOT NULL,
  `amount` decimal(12,2) NOT NULL,
  `balance_before` decimal(12,2) NOT NULL,
  `balance_after` decimal(12,2) NOT NULL,
  `transaction_type` enum('withdrawal','refund','commission','other') NOT NULL,
  `description` varchar(255) NOT NULL,
  `status` enum('pending','completed','failed') NOT NULL DEFAULT 'pending',
  `record_created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `wallet_transactions`
--

INSERT INTO `wallet_transactions` (`id`, `user_id`, `amount`, `balance_before`, `balance_after`, `transaction_type`, `description`, `status`, `record_created_at`, `created_at`, `updated_at`) VALUES
(1, 2, 500.00, 0.00, 500.00, 'other', 'Account setup welcome deposit', 'completed', '2026-06-14 10:57:29', '2026-06-14 10:57:29', '2026-06-14 10:57:29'),
(2, 3, 500.00, 0.00, 500.00, 'other', 'Account setup welcome deposit', 'completed', '2026-06-14 10:57:29', '2026-06-14 10:57:29', '2026-06-14 10:57:29'),
(3, 4, 500.00, 0.00, 500.00, 'other', 'Account setup welcome deposit', 'completed', '2026-06-14 10:57:29', '2026-06-14 10:57:29', '2026-06-14 10:57:29'),
(4, 5, 500.00, 0.00, 500.00, 'other', 'Account setup welcome deposit', 'completed', '2026-06-14 10:57:30', '2026-06-14 10:57:30', '2026-06-14 10:57:30'),
(5, 6, 500.00, 0.00, 500.00, 'other', 'Account setup welcome deposit', 'completed', '2026-06-14 10:57:30', '2026-06-14 10:57:30', '2026-06-14 10:57:30'),
(6, 4, 627.00, 50000.00, 50627.00, 'other', 'Earnings for Retail Order #ORD-RETAIL-1DIH-1782364868 (Base: LKR 660, 5% System Commission: -LKR 33 deducted)', 'completed', '2026-06-25 05:26:05', '2026-06-25 05:26:05', '2026-06-25 05:26:05'),
(7, 6, -1828.03, 50000.00, 48171.97, 'other', 'Payment for Retail Order #ORD-RETAIL-1DIH-1782364868 (Subtotal: LKR 660.00, Delivery Fee: LKR 1106.22, Service Charge (2%): LKR 35.32, Tax (1.5%): LKR 26.49)', 'completed', '2026-06-25 05:26:05', '2026-06-25 05:26:05', '2026-06-25 05:26:05');

-- --------------------------------------------------------

--
-- Table structure for table `withdraw_requests`
--

CREATE TABLE `withdraw_requests` (
  `id` bigint(20) UNSIGNED NOT NULL,
  `user_id` bigint(20) UNSIGNED NOT NULL,
  `request_amount` decimal(12,2) NOT NULL,
  `bank_name` varchar(255) NOT NULL,
  `bank_branch` varchar(255) NOT NULL,
  `bank_account_holder_name` varchar(255) NOT NULL,
  `bank_account_number` varchar(255) NOT NULL,
  `status` enum('pending','approved','rejected','processing','paid','cancelled') NOT NULL DEFAULT 'pending',
  `reviewed_admin_id` bigint(20) UNSIGNED DEFAULT NULL,
  `admin_note` text DEFAULT NULL,
  `rejection_reason` text DEFAULT NULL,
  `reviewed_at` timestamp NULL DEFAULT NULL,
  `paid_at` timestamp NULL DEFAULT NULL,
  `transaction_reference` varchar(255) DEFAULT NULL,
  `requested_ip` varchar(255) DEFAULT NULL,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `withdraw_requests`
--

INSERT INTO `withdraw_requests` (`id`, `user_id`, `request_amount`, `bank_name`, `bank_branch`, `bank_account_holder_name`, `bank_account_number`, `status`, `reviewed_admin_id`, `admin_note`, `rejection_reason`, `reviewed_at`, `paid_at`, `transaction_reference`, `requested_ip`, `created_at`, `updated_at`) VALUES
(1, 2, 20000.00, 'Bank of Ceylon', 'Nuwara Eliya', 'S. Kumara', '10293847', 'pending', NULL, NULL, NULL, NULL, NULL, NULL, NULL, '2026-06-14 10:57:30', '2026-06-14 10:57:30');

--
-- Indexes for dumped tables
--

--
-- Indexes for table `buyer_farmer_reviews`
--
ALTER TABLE `buyer_farmer_reviews`
  ADD PRIMARY KEY (`id`),
  ADD KEY `buyer_farmer_reviews_buyer_id_foreign` (`buyer_id`),
  ADD KEY `buyer_farmer_reviews_farmer_id_foreign` (`farmer_id`),
  ADD KEY `buyer_farmer_reviews_confirmed_bid_id_foreign` (`confirmed_bid_id`),
  ADD KEY `buyer_farmer_reviews_reviewed_by_foreign` (`reviewed_by`);

--
-- Indexes for table `cache`
--
ALTER TABLE `cache`
  ADD PRIMARY KEY (`key`),
  ADD KEY `cache_expiration_index` (`expiration`);

--
-- Indexes for table `cache_locks`
--
ALTER TABLE `cache_locks`
  ADD PRIMARY KEY (`key`),
  ADD KEY `cache_locks_expiration_index` (`expiration`);

--
-- Indexes for table `chatbot_sessions`
--
ALTER TABLE `chatbot_sessions`
  ADD PRIMARY KEY (`id`),
  ADD KEY `chatbot_sessions_user_id_foreign` (`user_id`),
  ADD KEY `chatbot_sessions_session_id_index` (`session_id`);

--
-- Indexes for table `chats`
--
ALTER TABLE `chats`
  ADD PRIMARY KEY (`id`),
  ADD KEY `chats_sender_id_foreign` (`sender_id`),
  ADD KEY `chats_receiver_id_foreign` (`receiver_id`);

--
-- Indexes for table `confirmed_bids`
--
ALTER TABLE `confirmed_bids`
  ADD PRIMARY KEY (`id`),
  ADD KEY `confirmed_bids_buyer_id_foreign` (`buyer_id`),
  ADD KEY `confirmed_bids_harvest_listing_id_foreign` (`harvest_listing_id`),
  ADD KEY `confirmed_bids_farmer_id_foreign` (`farmer_id`),
  ADD KEY `confirmed_bids_bid_id_foreign` (`bid_id`);

--
-- Indexes for table `confirmed_bids_payments`
--
ALTER TABLE `confirmed_bids_payments`
  ADD PRIMARY KEY (`id`),
  ADD KEY `confirmed_bids_payments_buyer_id_foreign` (`buyer_id`),
  ADD KEY `confirmed_bids_payments_farmer_id_foreign` (`farmer_id`),
  ADD KEY `confirmed_bids_payments_confirmed_bid_id_foreign` (`confirmed_bid_id`);

--
-- Indexes for table `crops`
--
ALTER TABLE `crops`
  ADD PRIMARY KEY (`id`),
  ADD KEY `crops_added_by_foreign` (`added_by`),
  ADD KEY `crops_status_index` (`status`);

--
-- Indexes for table `crop_growth_stages`
--
ALTER TABLE `crop_growth_stages`
  ADD PRIMARY KEY (`id`);

--
-- Indexes for table `crop_rates`
--
ALTER TABLE `crop_rates`
  ADD PRIMARY KEY (`id`),
  ADD KEY `crop_rates_buyer_id_foreign` (`buyer_id`),
  ADD KEY `crop_rates_crop_id_foreign` (`crop_id`);

--
-- Indexes for table `customer_orders`
--
ALTER TABLE `customer_orders`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `customer_orders_order_number_unique` (`order_number`),
  ADD KEY `customer_orders_customer_id_foreign` (`customer_id`),
  ADD KEY `customer_orders_delivery_partner_id_foreign` (`delivery_partner_id`);

--
-- Indexes for table `daily_cultivation_logs`
--
ALTER TABLE `daily_cultivation_logs`
  ADD PRIMARY KEY (`id`),
  ADD KEY `daily_cultivation_logs_farmer_id_foreign` (`farmer_id`),
  ADD KEY `daily_cultivation_logs_land_id_foreign` (`land_id`),
  ADD KEY `daily_cultivation_logs_growth_stage_id_foreign` (`growth_stage_id`);

--
-- Indexes for table `delivery_partner_verification_data`
--
ALTER TABLE `delivery_partner_verification_data`
  ADD PRIMARY KEY (`id`),
  ADD KEY `delivery_partner_verification_data_user_id_foreign` (`user_id`);

--
-- Indexes for table `failed_jobs`
--
ALTER TABLE `failed_jobs`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `failed_jobs_uuid_unique` (`uuid`);

--
-- Indexes for table `farmer_verification_data`
--
ALTER TABLE `farmer_verification_data`
  ADD PRIMARY KEY (`id`),
  ADD KEY `farmer_verification_data_user_id_foreign` (`user_id`);

--
-- Indexes for table `harvest_bids`
--
ALTER TABLE `harvest_bids`
  ADD PRIMARY KEY (`id`),
  ADD KEY `harvest_bids_buyer_id_foreign` (`buyer_id`),
  ADD KEY `harvest_bids_harvest_listing_id_foreign` (`harvest_listing_id`);

--
-- Indexes for table `harvest_listings`
--
ALTER TABLE `harvest_listings`
  ADD PRIMARY KEY (`id`),
  ADD KEY `harvest_listings_farmer_id_foreign` (`farmer_id`),
  ADD KEY `harvest_listings_crop_id_foreign` (`crop_id`);

--
-- Indexes for table `jobs`
--
ALTER TABLE `jobs`
  ADD PRIMARY KEY (`id`),
  ADD KEY `jobs_queue_index` (`queue`);

--
-- Indexes for table `job_batches`
--
ALTER TABLE `job_batches`
  ADD PRIMARY KEY (`id`);

--
-- Indexes for table `lands`
--
ALTER TABLE `lands`
  ADD PRIMARY KEY (`id`),
  ADD KEY `lands_farmer_id_foreign` (`farmer_id`);

--
-- Indexes for table `land_crops`
--
ALTER TABLE `land_crops`
  ADD PRIMARY KEY (`id`),
  ADD KEY `land_crops_land_id_foreign` (`land_id`),
  ADD KEY `land_crops_crop_id_foreign` (`crop_id`);

--
-- Indexes for table `migrations`
--
ALTER TABLE `migrations`
  ADD PRIMARY KEY (`id`);

--
-- Indexes for table `notifications`
--
ALTER TABLE `notifications`
  ADD PRIMARY KEY (`id`),
  ADD KEY `notifications_user_id_foreign` (`user_id`);

--
-- Indexes for table `offer_campaigns`
--
ALTER TABLE `offer_campaigns`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `offer_campaigns_code_unique` (`code`),
  ADD KEY `offer_campaigns_offer_goal_id_foreign` (`offer_goal_id`);

--
-- Indexes for table `offer_goals`
--
ALTER TABLE `offer_goals`
  ADD PRIMARY KEY (`id`);

--
-- Indexes for table `order_delivery_requests`
--
ALTER TABLE `order_delivery_requests`
  ADD PRIMARY KEY (`id`),
  ADD KEY `order_delivery_requests_order_id_foreign` (`order_id`);

--
-- Indexes for table `order_delivery_requests_assigned_partners`
--
ALTER TABLE `order_delivery_requests_assigned_partners`
  ADD PRIMARY KEY (`id`),
  ADD KEY `odrap_req_id_fk` (`delivery_request_id`),
  ADD KEY `odrap_part_id_fk` (`delivery_partner_id`);

--
-- Indexes for table `order_delivery_tracking`
--
ALTER TABLE `order_delivery_tracking`
  ADD PRIMARY KEY (`id`),
  ADD KEY `order_delivery_tracking_order_id_foreign` (`order_id`),
  ADD KEY `order_delivery_tracking_delivery_partner_id_foreign` (`delivery_partner_id`);

--
-- Indexes for table `order_items`
--
ALTER TABLE `order_items`
  ADD PRIMARY KEY (`id`),
  ADD KEY `order_items_order_id_foreign` (`order_id`),
  ADD KEY `order_items_retailer_product_id_foreign` (`retailer_product_id`),
  ADD KEY `order_items_retailer_id_foreign` (`retailer_id`);

--
-- Indexes for table `order_payments`
--
ALTER TABLE `order_payments`
  ADD PRIMARY KEY (`id`),
  ADD KEY `order_payments_order_id_foreign` (`order_id`),
  ADD KEY `order_payments_customer_id_foreign` (`customer_id`);

--
-- Indexes for table `order_status_histories`
--
ALTER TABLE `order_status_histories`
  ADD PRIMARY KEY (`id`),
  ADD KEY `order_status_histories_order_id_foreign` (`order_id`),
  ADD KEY `order_status_histories_changed_by_user_id_foreign` (`changed_by_user_id`);

--
-- Indexes for table `password_reset_tokens`
--
ALTER TABLE `password_reset_tokens`
  ADD PRIMARY KEY (`email`);

--
-- Indexes for table `personal_access_tokens`
--
ALTER TABLE `personal_access_tokens`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `personal_access_tokens_token_unique` (`token`),
  ADD KEY `personal_access_tokens_tokenable_type_tokenable_id_index` (`tokenable_type`,`tokenable_id`),
  ADD KEY `personal_access_tokens_expires_at_index` (`expires_at`);

--
-- Indexes for table `retailer_customer_delivery_partner_reviews`
--
ALTER TABLE `retailer_customer_delivery_partner_reviews`
  ADD PRIMARY KEY (`id`),
  ADD KEY `retailer_customer_delivery_partner_reviews_reviewed_to_foreign` (`reviewed_to`),
  ADD KEY `retailer_customer_delivery_partner_reviews_reviewed_by_foreign` (`reviewed_by`),
  ADD KEY `retailer_customer_delivery_partner_reviews_order_id_foreign` (`order_id`);

--
-- Indexes for table `retailer_products`
--
ALTER TABLE `retailer_products`
  ADD PRIMARY KEY (`id`),
  ADD KEY `retailer_products_seller_id_foreign` (`seller_id`),
  ADD KEY `retailer_products_crop_id_foreign` (`crop_id`);

--
-- Indexes for table `retail_seller_verification_data`
--
ALTER TABLE `retail_seller_verification_data`
  ADD PRIMARY KEY (`id`),
  ADD KEY `retail_seller_verification_data_user_id_foreign` (`user_id`);

--
-- Indexes for table `sessions`
--
ALTER TABLE `sessions`
  ADD PRIMARY KEY (`id`),
  ADD KEY `sessions_user_id_index` (`user_id`),
  ADD KEY `sessions_last_activity_index` (`last_activity`);

--
-- Indexes for table `users`
--
ALTER TABLE `users`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `users_phone_number_unique` (`phone_number`),
  ADD UNIQUE KEY `users_email_unique` (`email`),
  ADD UNIQUE KEY `users_national_id_unique` (`national_id`);

--
-- Indexes for table `user_offer_progress`
--
ALTER TABLE `user_offer_progress`
  ADD PRIMARY KEY (`id`),
  ADD KEY `user_offer_progress_offer_campaign_id_foreign` (`offer_campaign_id`),
  ADD KEY `user_offer_progress_user_id_foreign` (`user_id`),
  ADD KEY `reward_activity` (`reward_claimed_activity_type`,`reward_claimed_activity_id`);

--
-- Indexes for table `user_verification_documents`
--
ALTER TABLE `user_verification_documents`
  ADD PRIMARY KEY (`id`),
  ADD KEY `user_verification_documents_user_id_foreign` (`user_id`),
  ADD KEY `user_verification_documents_verified_by_foreign` (`verified_by`);

--
-- Indexes for table `user_wallets`
--
ALTER TABLE `user_wallets`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `user_wallets_user_id_unique` (`user_id`);

--
-- Indexes for table `wallet_transactions`
--
ALTER TABLE `wallet_transactions`
  ADD PRIMARY KEY (`id`),
  ADD KEY `wallet_transactions_user_id_foreign` (`user_id`);

--
-- Indexes for table `withdraw_requests`
--
ALTER TABLE `withdraw_requests`
  ADD PRIMARY KEY (`id`),
  ADD KEY `withdraw_requests_user_id_foreign` (`user_id`),
  ADD KEY `withdraw_requests_reviewed_admin_id_foreign` (`reviewed_admin_id`);

--
-- AUTO_INCREMENT for dumped tables
--

--
-- AUTO_INCREMENT for table `buyer_farmer_reviews`
--
ALTER TABLE `buyer_farmer_reviews`
  MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=2;

--
-- AUTO_INCREMENT for table `chatbot_sessions`
--
ALTER TABLE `chatbot_sessions`
  MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=8;

--
-- AUTO_INCREMENT for table `chats`
--
ALTER TABLE `chats`
  MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=9;

--
-- AUTO_INCREMENT for table `confirmed_bids`
--
ALTER TABLE `confirmed_bids`
  MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=2;

--
-- AUTO_INCREMENT for table `confirmed_bids_payments`
--
ALTER TABLE `confirmed_bids_payments`
  MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=2;

--
-- AUTO_INCREMENT for table `crops`
--
ALTER TABLE `crops`
  MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=134;

--
-- AUTO_INCREMENT for table `crop_growth_stages`
--
ALTER TABLE `crop_growth_stages`
  MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=16;

--
-- AUTO_INCREMENT for table `crop_rates`
--
ALTER TABLE `crop_rates`
  MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=6;

--
-- AUTO_INCREMENT for table `customer_orders`
--
ALTER TABLE `customer_orders`
  MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=3;

--
-- AUTO_INCREMENT for table `daily_cultivation_logs`
--
ALTER TABLE `daily_cultivation_logs`
  MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=4;

--
-- AUTO_INCREMENT for table `delivery_partner_verification_data`
--
ALTER TABLE `delivery_partner_verification_data`
  MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=4;

--
-- AUTO_INCREMENT for table `failed_jobs`
--
ALTER TABLE `failed_jobs`
  MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `farmer_verification_data`
--
ALTER TABLE `farmer_verification_data`
  MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=4;

--
-- AUTO_INCREMENT for table `harvest_bids`
--
ALTER TABLE `harvest_bids`
  MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=3;

--
-- AUTO_INCREMENT for table `harvest_listings`
--
ALTER TABLE `harvest_listings`
  MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=3;

--
-- AUTO_INCREMENT for table `jobs`
--
ALTER TABLE `jobs`
  MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `lands`
--
ALTER TABLE `lands`
  MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=3;

--
-- AUTO_INCREMENT for table `land_crops`
--
ALTER TABLE `land_crops`
  MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=8;

--
-- AUTO_INCREMENT for table `migrations`
--
ALTER TABLE `migrations`
  MODIFY `id` int(10) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=43;

--
-- AUTO_INCREMENT for table `notifications`
--
ALTER TABLE `notifications`
  MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=3;

--
-- AUTO_INCREMENT for table `offer_campaigns`
--
ALTER TABLE `offer_campaigns`
  MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=5;

--
-- AUTO_INCREMENT for table `offer_goals`
--
ALTER TABLE `offer_goals`
  MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=6;

--
-- AUTO_INCREMENT for table `order_delivery_requests`
--
ALTER TABLE `order_delivery_requests`
  MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=3;

--
-- AUTO_INCREMENT for table `order_delivery_requests_assigned_partners`
--
ALTER TABLE `order_delivery_requests_assigned_partners`
  MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=3;

--
-- AUTO_INCREMENT for table `order_delivery_tracking`
--
ALTER TABLE `order_delivery_tracking`
  MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=5;

--
-- AUTO_INCREMENT for table `order_items`
--
ALTER TABLE `order_items`
  MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=4;

--
-- AUTO_INCREMENT for table `order_payments`
--
ALTER TABLE `order_payments`
  MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=3;

--
-- AUTO_INCREMENT for table `order_status_histories`
--
ALTER TABLE `order_status_histories`
  MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=6;

--
-- AUTO_INCREMENT for table `personal_access_tokens`
--
ALTER TABLE `personal_access_tokens`
  MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=42;

--
-- AUTO_INCREMENT for table `retailer_customer_delivery_partner_reviews`
--
ALTER TABLE `retailer_customer_delivery_partner_reviews`
  MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=6;

--
-- AUTO_INCREMENT for table `retailer_products`
--
ALTER TABLE `retailer_products`
  MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=4;

--
-- AUTO_INCREMENT for table `retail_seller_verification_data`
--
ALTER TABLE `retail_seller_verification_data`
  MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=6;

--
-- AUTO_INCREMENT for table `users`
--
ALTER TABLE `users`
  MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=15;

--
-- AUTO_INCREMENT for table `user_offer_progress`
--
ALTER TABLE `user_offer_progress`
  MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=2;

--
-- AUTO_INCREMENT for table `user_verification_documents`
--
ALTER TABLE `user_verification_documents`
  MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=25;

--
-- AUTO_INCREMENT for table `user_wallets`
--
ALTER TABLE `user_wallets`
  MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=14;

--
-- AUTO_INCREMENT for table `wallet_transactions`
--
ALTER TABLE `wallet_transactions`
  MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=8;

--
-- AUTO_INCREMENT for table `withdraw_requests`
--
ALTER TABLE `withdraw_requests`
  MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=2;

--
-- Constraints for dumped tables
--

--
-- Constraints for table `buyer_farmer_reviews`
--
ALTER TABLE `buyer_farmer_reviews`
  ADD CONSTRAINT `buyer_farmer_reviews_buyer_id_foreign` FOREIGN KEY (`buyer_id`) REFERENCES `users` (`id`) ON DELETE CASCADE,
  ADD CONSTRAINT `buyer_farmer_reviews_confirmed_bid_id_foreign` FOREIGN KEY (`confirmed_bid_id`) REFERENCES `confirmed_bids` (`id`) ON DELETE CASCADE,
  ADD CONSTRAINT `buyer_farmer_reviews_farmer_id_foreign` FOREIGN KEY (`farmer_id`) REFERENCES `users` (`id`) ON DELETE CASCADE,
  ADD CONSTRAINT `buyer_farmer_reviews_reviewed_by_foreign` FOREIGN KEY (`reviewed_by`) REFERENCES `users` (`id`) ON DELETE CASCADE;

--
-- Constraints for table `chatbot_sessions`
--
ALTER TABLE `chatbot_sessions`
  ADD CONSTRAINT `chatbot_sessions_user_id_foreign` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE SET NULL;

--
-- Constraints for table `chats`
--
ALTER TABLE `chats`
  ADD CONSTRAINT `chats_receiver_id_foreign` FOREIGN KEY (`receiver_id`) REFERENCES `users` (`id`) ON DELETE CASCADE,
  ADD CONSTRAINT `chats_sender_id_foreign` FOREIGN KEY (`sender_id`) REFERENCES `users` (`id`) ON DELETE CASCADE;

--
-- Constraints for table `confirmed_bids`
--
ALTER TABLE `confirmed_bids`
  ADD CONSTRAINT `confirmed_bids_bid_id_foreign` FOREIGN KEY (`bid_id`) REFERENCES `harvest_bids` (`id`) ON DELETE CASCADE,
  ADD CONSTRAINT `confirmed_bids_buyer_id_foreign` FOREIGN KEY (`buyer_id`) REFERENCES `users` (`id`) ON DELETE CASCADE,
  ADD CONSTRAINT `confirmed_bids_farmer_id_foreign` FOREIGN KEY (`farmer_id`) REFERENCES `users` (`id`) ON DELETE CASCADE,
  ADD CONSTRAINT `confirmed_bids_harvest_listing_id_foreign` FOREIGN KEY (`harvest_listing_id`) REFERENCES `harvest_listings` (`id`) ON DELETE CASCADE;

--
-- Constraints for table `confirmed_bids_payments`
--
ALTER TABLE `confirmed_bids_payments`
  ADD CONSTRAINT `confirmed_bids_payments_buyer_id_foreign` FOREIGN KEY (`buyer_id`) REFERENCES `users` (`id`) ON DELETE CASCADE,
  ADD CONSTRAINT `confirmed_bids_payments_confirmed_bid_id_foreign` FOREIGN KEY (`confirmed_bid_id`) REFERENCES `confirmed_bids` (`id`) ON DELETE CASCADE,
  ADD CONSTRAINT `confirmed_bids_payments_farmer_id_foreign` FOREIGN KEY (`farmer_id`) REFERENCES `users` (`id`) ON DELETE CASCADE;

--
-- Constraints for table `crops`
--
ALTER TABLE `crops`
  ADD CONSTRAINT `crops_added_by_foreign` FOREIGN KEY (`added_by`) REFERENCES `users` (`id`) ON DELETE SET NULL;

--
-- Constraints for table `crop_rates`
--
ALTER TABLE `crop_rates`
  ADD CONSTRAINT `crop_rates_buyer_id_foreign` FOREIGN KEY (`buyer_id`) REFERENCES `users` (`id`) ON DELETE CASCADE,
  ADD CONSTRAINT `crop_rates_crop_id_foreign` FOREIGN KEY (`crop_id`) REFERENCES `crops` (`id`) ON DELETE CASCADE;

--
-- Constraints for table `customer_orders`
--
ALTER TABLE `customer_orders`
  ADD CONSTRAINT `customer_orders_customer_id_foreign` FOREIGN KEY (`customer_id`) REFERENCES `users` (`id`) ON DELETE CASCADE,
  ADD CONSTRAINT `customer_orders_delivery_partner_id_foreign` FOREIGN KEY (`delivery_partner_id`) REFERENCES `users` (`id`) ON DELETE SET NULL;

--
-- Constraints for table `daily_cultivation_logs`
--
ALTER TABLE `daily_cultivation_logs`
  ADD CONSTRAINT `daily_cultivation_logs_farmer_id_foreign` FOREIGN KEY (`farmer_id`) REFERENCES `users` (`id`) ON DELETE CASCADE,
  ADD CONSTRAINT `daily_cultivation_logs_growth_stage_id_foreign` FOREIGN KEY (`growth_stage_id`) REFERENCES `crop_growth_stages` (`id`) ON DELETE CASCADE,
  ADD CONSTRAINT `daily_cultivation_logs_land_id_foreign` FOREIGN KEY (`land_id`) REFERENCES `lands` (`id`) ON DELETE CASCADE;

--
-- Constraints for table `delivery_partner_verification_data`
--
ALTER TABLE `delivery_partner_verification_data`
  ADD CONSTRAINT `delivery_partner_verification_data_user_id_foreign` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE;

--
-- Constraints for table `farmer_verification_data`
--
ALTER TABLE `farmer_verification_data`
  ADD CONSTRAINT `farmer_verification_data_user_id_foreign` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE;

--
-- Constraints for table `harvest_bids`
--
ALTER TABLE `harvest_bids`
  ADD CONSTRAINT `harvest_bids_buyer_id_foreign` FOREIGN KEY (`buyer_id`) REFERENCES `users` (`id`) ON DELETE CASCADE,
  ADD CONSTRAINT `harvest_bids_harvest_listing_id_foreign` FOREIGN KEY (`harvest_listing_id`) REFERENCES `harvest_listings` (`id`) ON DELETE CASCADE;

--
-- Constraints for table `harvest_listings`
--
ALTER TABLE `harvest_listings`
  ADD CONSTRAINT `harvest_listings_crop_id_foreign` FOREIGN KEY (`crop_id`) REFERENCES `crops` (`id`) ON DELETE CASCADE,
  ADD CONSTRAINT `harvest_listings_farmer_id_foreign` FOREIGN KEY (`farmer_id`) REFERENCES `users` (`id`) ON DELETE CASCADE;

--
-- Constraints for table `lands`
--
ALTER TABLE `lands`
  ADD CONSTRAINT `lands_farmer_id_foreign` FOREIGN KEY (`farmer_id`) REFERENCES `users` (`id`) ON DELETE CASCADE;

--
-- Constraints for table `land_crops`
--
ALTER TABLE `land_crops`
  ADD CONSTRAINT `land_crops_crop_id_foreign` FOREIGN KEY (`crop_id`) REFERENCES `crops` (`id`) ON DELETE CASCADE,
  ADD CONSTRAINT `land_crops_land_id_foreign` FOREIGN KEY (`land_id`) REFERENCES `lands` (`id`) ON DELETE CASCADE;

--
-- Constraints for table `notifications`
--
ALTER TABLE `notifications`
  ADD CONSTRAINT `notifications_user_id_foreign` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE;

--
-- Constraints for table `offer_campaigns`
--
ALTER TABLE `offer_campaigns`
  ADD CONSTRAINT `offer_campaigns_offer_goal_id_foreign` FOREIGN KEY (`offer_goal_id`) REFERENCES `offer_goals` (`id`) ON DELETE CASCADE;

--
-- Constraints for table `order_delivery_requests`
--
ALTER TABLE `order_delivery_requests`
  ADD CONSTRAINT `order_delivery_requests_order_id_foreign` FOREIGN KEY (`order_id`) REFERENCES `customer_orders` (`id`) ON DELETE CASCADE;

--
-- Constraints for table `order_delivery_requests_assigned_partners`
--
ALTER TABLE `order_delivery_requests_assigned_partners`
  ADD CONSTRAINT `odrap_part_id_fk` FOREIGN KEY (`delivery_partner_id`) REFERENCES `users` (`id`) ON DELETE CASCADE,
  ADD CONSTRAINT `odrap_req_id_fk` FOREIGN KEY (`delivery_request_id`) REFERENCES `order_delivery_requests` (`id`) ON DELETE CASCADE;

--
-- Constraints for table `order_delivery_tracking`
--
ALTER TABLE `order_delivery_tracking`
  ADD CONSTRAINT `order_delivery_tracking_delivery_partner_id_foreign` FOREIGN KEY (`delivery_partner_id`) REFERENCES `users` (`id`) ON DELETE CASCADE,
  ADD CONSTRAINT `order_delivery_tracking_order_id_foreign` FOREIGN KEY (`order_id`) REFERENCES `customer_orders` (`id`) ON DELETE CASCADE;

--
-- Constraints for table `order_items`
--
ALTER TABLE `order_items`
  ADD CONSTRAINT `order_items_order_id_foreign` FOREIGN KEY (`order_id`) REFERENCES `customer_orders` (`id`) ON DELETE CASCADE,
  ADD CONSTRAINT `order_items_retailer_id_foreign` FOREIGN KEY (`retailer_id`) REFERENCES `users` (`id`) ON DELETE CASCADE,
  ADD CONSTRAINT `order_items_retailer_product_id_foreign` FOREIGN KEY (`retailer_product_id`) REFERENCES `retailer_products` (`id`) ON DELETE CASCADE;

--
-- Constraints for table `order_payments`
--
ALTER TABLE `order_payments`
  ADD CONSTRAINT `order_payments_customer_id_foreign` FOREIGN KEY (`customer_id`) REFERENCES `users` (`id`) ON DELETE CASCADE,
  ADD CONSTRAINT `order_payments_order_id_foreign` FOREIGN KEY (`order_id`) REFERENCES `customer_orders` (`id`) ON DELETE CASCADE;

--
-- Constraints for table `order_status_histories`
--
ALTER TABLE `order_status_histories`
  ADD CONSTRAINT `order_status_histories_changed_by_user_id_foreign` FOREIGN KEY (`changed_by_user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE,
  ADD CONSTRAINT `order_status_histories_order_id_foreign` FOREIGN KEY (`order_id`) REFERENCES `customer_orders` (`id`) ON DELETE CASCADE;

--
-- Constraints for table `retailer_customer_delivery_partner_reviews`
--
ALTER TABLE `retailer_customer_delivery_partner_reviews`
  ADD CONSTRAINT `retailer_customer_delivery_partner_reviews_order_id_foreign` FOREIGN KEY (`order_id`) REFERENCES `customer_orders` (`id`) ON DELETE CASCADE,
  ADD CONSTRAINT `retailer_customer_delivery_partner_reviews_reviewed_by_foreign` FOREIGN KEY (`reviewed_by`) REFERENCES `users` (`id`) ON DELETE CASCADE,
  ADD CONSTRAINT `retailer_customer_delivery_partner_reviews_reviewed_to_foreign` FOREIGN KEY (`reviewed_to`) REFERENCES `users` (`id`) ON DELETE CASCADE;

--
-- Constraints for table `retailer_products`
--
ALTER TABLE `retailer_products`
  ADD CONSTRAINT `retailer_products_crop_id_foreign` FOREIGN KEY (`crop_id`) REFERENCES `crops` (`id`) ON DELETE CASCADE,
  ADD CONSTRAINT `retailer_products_seller_id_foreign` FOREIGN KEY (`seller_id`) REFERENCES `users` (`id`) ON DELETE CASCADE;

--
-- Constraints for table `retail_seller_verification_data`
--
ALTER TABLE `retail_seller_verification_data`
  ADD CONSTRAINT `retail_seller_verification_data_user_id_foreign` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE;

--
-- Constraints for table `user_offer_progress`
--
ALTER TABLE `user_offer_progress`
  ADD CONSTRAINT `user_offer_progress_offer_campaign_id_foreign` FOREIGN KEY (`offer_campaign_id`) REFERENCES `offer_campaigns` (`id`) ON DELETE CASCADE,
  ADD CONSTRAINT `user_offer_progress_user_id_foreign` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE;

--
-- Constraints for table `user_verification_documents`
--
ALTER TABLE `user_verification_documents`
  ADD CONSTRAINT `user_verification_documents_user_id_foreign` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE,
  ADD CONSTRAINT `user_verification_documents_verified_by_foreign` FOREIGN KEY (`verified_by`) REFERENCES `users` (`id`) ON DELETE SET NULL;

--
-- Constraints for table `user_wallets`
--
ALTER TABLE `user_wallets`
  ADD CONSTRAINT `user_wallets_user_id_foreign` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE;

--
-- Constraints for table `wallet_transactions`
--
ALTER TABLE `wallet_transactions`
  ADD CONSTRAINT `wallet_transactions_user_id_foreign` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE;

--
-- Constraints for table `withdraw_requests`
--
ALTER TABLE `withdraw_requests`
  ADD CONSTRAINT `withdraw_requests_reviewed_admin_id_foreign` FOREIGN KEY (`reviewed_admin_id`) REFERENCES `users` (`id`) ON DELETE SET NULL,
  ADD CONSTRAINT `withdraw_requests_user_id_foreign` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE;
COMMIT;

/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
