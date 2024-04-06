import { Hono } from "hono";
import health from "./health/index.js";
import users from "./users/index.js";

const app = new Hono();

const api = app.route("/api");

api.route("/health", health);
api.route("/users", users);

export default app;
