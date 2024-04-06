import { zValidator } from "@hono/zod-validator";
import { db } from "api/db/connection.js";
import { users } from "api/db/schema.js";
import { logger } from "api/logger.js";
import argon2 from "argon2";
import { count } from "drizzle-orm";
import { Hono } from "hono";
import { ulid } from "ulid";
import { z } from "zod";

const app = new Hono();

app.post(
	"/first-user",
	zValidator(
		"json",
		z.object({
			username: z.string().min(1).max(32),
			password: z.string().min(1),
		}),
	),
	async (c) => {
		const cnt = await db.select({ value: count() }).from(users);

		if (cnt.length !== 1) {
			return c.json({ message: "Internal Server Error" }, 500);
		}

		if (cnt[0].value !== 0) {
			return c.json({ message: "first user has already been created" });
		}

		const { username, password } = c.req.valid("json");

		const pepper = process.env.PEPPER;
		if (!pepper) {
			logger.error("PEPPER is not set");
			return c.json({ message: "Internal Server Error" }, 500);
		}

		const hash = await argon2.hash(password, { secret: Buffer.from(pepper) });

		const id = ulid();

		await db.insert(users).values({
			id,
			username,
			hash,
		});

		logger.info(`User ${username} created`);
		return c.json({ id, username });
	},
);

export default app;
