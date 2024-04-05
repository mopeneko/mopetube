import { serve } from "@hono/node-server";
import { serveStatic } from "@hono/node-server/serve-static";
import { createRequestHandler } from "@remix-run/server-runtime";
import pino from "pino";
import * as build from "../build/server";
import app from "./route";

const logger = pino();

app.use("*", serveStatic({ root: "./build/client" }));

app.all("*", async (c) => {
	try {
		return await createRequestHandler(build, process.env.NODE_ENV)(c.req.raw, {
			logger,
		});
	} catch (error) {
		c.status(500);
		c.text("Internal Server Error");
		logger.error(error);
	}
});

const port = 3000;
console.log(`Server is running on port ${port}`);

serve({
	fetch: app.fetch,
	port,
});
