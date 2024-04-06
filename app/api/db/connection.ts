import fs from "node:fs";
import { drizzle } from "drizzle-orm/mysql2";
import mysql from "mysql2/promise";

export const connection = await mysql.createConnection({
	host: process.env.DB_HOST,
	port: process.env.DB_PORT
		? Number.parseInt(process.env.DB_PORT, 10)
		: undefined,
	user: process.env.DB_USER,
	password: process.env.DB_PASS,
	database: process.env.DB_NAME,
	ssl: {
		ca: process.env.CA_PATH ? fs.readFileSync(process.env.CA_PATH) : undefined,
	},
});

export const db = drizzle(connection);
