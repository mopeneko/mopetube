import { mysqlTable, varchar } from "drizzle-orm/mysql-core";

export const users = mysqlTable("users", {
	id: varchar("id", { length: 26 }).primaryKey(),
	username: varchar("username", { length: 32 }).unique().notNull(),
	hash: varchar("hash", { length: 255 }).notNull(),
});

export type User = typeof users.$inferSelect;
export type NewUser = typeof users.$inferInsert;
