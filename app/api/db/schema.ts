import { mysqlTable, varchar } from "drizzle-orm/mysql-core";

export const users = mysqlTable("users", {
	id: varchar("id", { length: 26 }).primaryKey(),
	username: varchar("username", { length: 32 }).unique().notNull(),
	password: varchar("password", { length: 255 }).notNull(),
	salt: varchar("salt", { length: 32 }).notNull(),
});
