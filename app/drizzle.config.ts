import type { Config } from "drizzle-kit";

export default {
	schema: "./api/db/schema.ts",
	out: "./drizzle",
	driver: "mysql2",
	dbCredentials: {
		host: process.env.DB_HOST ?? "",
		port: process.env.DB_PORT
			? Number.parseInt(process.env.DB_PORT, 10)
			: undefined,
		user: process.env.DB_USER,
		password: process.env.DB_PASS,
		database: process.env.DB_NAME ?? "",
	},
} satisfies Config;
