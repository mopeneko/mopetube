import { migrate } from "drizzle-orm/mysql2/migrator";
import { db, connection } from "./connection.js";

await migrate(db, { migrationsFolder: "./drizzle" });

await connection.end();
