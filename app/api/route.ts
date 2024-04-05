import { Hono } from "hono";
import health from "./health/index.js";

const app = new Hono();

const api = app.route("/api");

api.route("/health", health);

export default app;
