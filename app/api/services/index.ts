import "reflect-metadata";
import { container } from "./container.js";
import { UserService } from "./user.js";

export const userService = container.resolve(UserService);
