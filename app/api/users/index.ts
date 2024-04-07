import { zValidator } from "@hono/zod-validator";
import { logger } from "api/logger.js";
import { userService } from "api/services/index.js";
import { Hono } from "hono";
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
		(result, c) => {
			if (!result.success) {
				return c.json({ message: "Bad Request" }, 400);
			}
		},
	),
	async (c) => {
		try {
			if (!(await userService.isFirstUser())) {
				return c.json({ message: "first user has already been created" }, 409);
			}

			const { username, password } = c.req.valid("json");

			const user = await userService.createUser(username, password);
			return c.json({ id: user.id, username: user.username });
		} catch (error) {
			logger.error(error);
			return c.json({ message: "Internal Server Error" }, 500);
		}
	},
);

export default app;
