import { serve } from "@hono/node-server";
import { serveStatic } from "@hono/node-server/serve-static";
import {
	type ServerBuild,
	createRequestHandler,
} from "@remix-run/server-runtime";
import { logger } from "./logger.js";
import app from "./route.js";

app.use("*", serveStatic({ root: "./build/client" }));

const viteDevServer =
	process.env.NODE_ENV === "development"
		? await (await import("vite")).createServer({
				server: { middlewareMode: true },
				appType: "custom",
			})
		: undefined;

app.use("*", async (c) => {
	try {
		const build =
			process.env.NODE_ENV === "production"
				? await import("../build/server/index.js")
				: ((await viteDevServer?.ssrLoadModule(
						"virtual:remix/server-build",
					)) as ServerBuild);
		return await createRequestHandler(build, process.env.NODE_ENV)(c.req.raw, {
			logger,
		});
	} catch (error) {
		c.status(500);
		c.text("Internal Server Error");
		logger.error(error);
	}
});

if (process.env.NODE_ENV === "production") {
	const port = Number.parseInt(process.env.PORT ?? "3000");
	console.log(`Server is running on port ${port}`);

	serve({
		fetch: app.fetch,
		port,
	});
}

export default app;
