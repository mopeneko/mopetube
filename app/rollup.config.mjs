import typescript from "@rollup/plugin-typescript";
import commonjs from "@rollup/plugin-commonjs";

export default {
    input: "api/index.ts",
    output: {
        file: "build/api.js",
        format: "esm",
        sourcemap: true
    },
    plugins: [
        typescript(),
        commonjs(),
    ]
}
