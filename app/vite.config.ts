import { vitePlugin as remix } from "@remix-run/dev";
import { installGlobals } from "@remix-run/node";
import { defineConfig } from "vite";
import tsconfigPaths from "vite-tsconfig-paths";

installGlobals();
// Edit code for testing
export default defineConfig({
	plugins: [remix(), tsconfigPaths()],
});
