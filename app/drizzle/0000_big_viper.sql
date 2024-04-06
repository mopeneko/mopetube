CREATE TABLE `users` (
	`id` varchar(26) NOT NULL,
	`username` varchar(32) NOT NULL,
	`password` varchar(255) NOT NULL,
	`salt` varchar(32) NOT NULL,
	CONSTRAINT `users_id` PRIMARY KEY(`id`),
	CONSTRAINT `users_username_unique` UNIQUE(`username`)
);
