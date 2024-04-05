import devServer from "@hono/vite-dev-server";
import { vitePlugin as remix } from "@remix-run/dev";
import { defineConfig } from "vite";
import tsconfigPaths from "vite-tsconfig-paths";

export default defineConfig({
	plugins: [
		devServer({
			entry: "api/index.ts",
			injectClientScript: false,
			exclude: [/^\/(app)\/.+/, /^\/@.+$/, /^\/node_modules\/.*/],
		}),
		remix(),
		tsconfigPaths(),
	],
});
