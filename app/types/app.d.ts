import "@remix-run/server-runtime";
import type { BaseLogger } from "pino";

declare module "@remix-run/server-runtime" {
	export interface AppLoadContext {
		logger: BaseLogger;
	}
}
