import { APIError } from "api/api_error.js";
import type { DB } from "api/db/connection.js";
import { users, type NewUser } from "api/db/schema.js";
import type { Logger } from "pino";
import * as argon2 from "argon2";
import { ulid } from "ulid";
import { count } from "drizzle-orm";
import { inject, injectable } from "tsyringe";

@injectable()
export class UserService {
	constructor(
		@inject("DB") private db: DB,
		@inject("Logger") private logger: Logger,
	) {}

	async createUser(username: string, password: string): Promise<NewUser> {
		const pepper = process.env.PEPPER;
		if (!pepper) {
			throw new APIError("PEPPER is not set", 500);
		}

		const hash = await argon2.hash(password, { secret: Buffer.from(pepper) });

		const id = ulid();

		const user = {
			id,
			username,
			hash,
		};

		await this.db.insert(users).values(user);

		this.logger.info(`User ${user.id} created`);

		return user;
	}

	async isFirstUser(): Promise<boolean> {
		const cnt = await this.db.select({ value: count() }).from(users);

		if (cnt.length !== 1) {
			throw new APIError("Invalid rows count", 500);
		}

		return cnt[0].value === 0;
	}
}
