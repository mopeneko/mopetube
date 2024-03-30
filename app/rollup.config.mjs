import commonjs from "@rollup/plugin-commonjs";
import typescript from "@rollup/plugin-typescript";

export default {
	input: "api/index.ts",
	output: {
		file: "build/api.js",
		format: "esm",
		sourcemap: true,
	},
	plugins: [typescript(), commonjs()],
};
