import { container } from "tsyringe";
import { db } from "../db/connection.js";
import { logger } from "../logger.js";

container.register("DB", {
	useValue: db,
});

container.register("Logger", {
	useValue: logger,
});

export { container };
