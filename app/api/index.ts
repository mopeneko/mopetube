import { serve } from "@hono/node-server";
import { serveStatic } from "@hono/node-server/serve-static";
import { remix } from "remix-hono/handler";
import * as build from "../build/server";
import app from "./route";

app.use(
	"*",
	serveStatic({ root: "./build/client" }),
	remix({
		build,
		mode: process.env.NODE_ENV as "development" | "production",
	}),
);

const port = 3000;
console.log(`Server is running on port ${port}`);

serve({
	fetch: app.fetch,
	port,
});
