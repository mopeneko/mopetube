import commonjs from "@rollup/plugin-commonjs";
import typescript from "@rollup/plugin-typescript";

export default {
	input: "api/index.ts",
	output: {
		dir: "build/api",
		format: "esm",
	},
	plugins: [typescript(), commonjs()],
};
