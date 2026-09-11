const secretPath = process.env.MONGODB_SECRET_PATH;

if (!secretPath) {
  throw new Error("MONGODB_SECRET_PATH is required");
}

const username = fs
  .readFileSync(`${secretPath}/username`, "utf8")
  .trim();

const password = fs
  .readFileSync(`${secretPath}/password`, "utf8")
  .trim();