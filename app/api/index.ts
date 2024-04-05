import { serve } from "@hono/node-server";
import { serveStatic } from "@hono/node-server/serve-static";
import { createRequestHandler } from "@remix-run/server-runtime";
import pino from "pino";
import app from "./route";

const logger = pino();

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
				? await import("../build/server")
				: await viteDevServer?.ssrLoadModule("virtual:remix/server-build");
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
